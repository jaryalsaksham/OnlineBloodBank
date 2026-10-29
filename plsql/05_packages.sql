-- =============================================================================
-- Project Title: Blood Bank Management System (PL/SQL Project)
-- Component:     05_packages.sql (Enterprise PL/SQL Packages)
-- Target DBMS:   Oracle 11g / 12c / 18c / 19c / 21c / 23c / Oracle Live SQL
-- Description:   Package Specifications and Bodies encapsulating:
--                1. Custom Types, Ref Cursors, and Application Constants
--                2. User-Defined Exceptions and Error Mapping Pragmas
--                3. High-level unified API for Donors, Inventory, and Requests
--                4. Bulk collect and batch reconciliation processing
-- =============================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED;

PROMPT =========================================================================;
PROMPT  CREATING PL/SQL PACKAGES (SPECIFICATION & BODY)...;
PROMPT =========================================================================;

-- =============================================================================
-- 1. PACKAGE SPECIFICATION: pkg_blood_bank_types
-- =============================================================================
CREATE OR REPLACE PACKAGE pkg_blood_bank_types AS
    -- Global Application Constants
    c_min_donor_age     CONSTANT NUMBER := 18;
    c_max_donor_age     CONSTANT NUMBER := 65;
    c_min_donor_weight  CONSTANT NUMBER := 45.0;
    c_cooldown_days     CONSTANT NUMBER := 90;
    c_critical_units    CONSTANT NUMBER := 5;

    -- Custom Exception Declarations
    e_underage_donor    EXCEPTION;
    e_cooldown_active   EXCEPTION;
    e_stock_depleted    EXCEPTION;
    e_request_closed    EXCEPTION;

    PRAGMA EXCEPTION_INIT(e_underage_donor,  -20011);
    PRAGMA EXCEPTION_INIT(e_cooldown_active, -20012);
    PRAGMA EXCEPTION_INIT(e_stock_depleted,  -20013);
    PRAGMA EXCEPTION_INIT(e_request_closed,  -20014);

    -- Ref Cursor Type for Dynamic Web/Application Integration
    TYPE t_ref_cursor IS REF CURSOR;

    -- Record structure for Blood Group Stock Status
    TYPE t_stock_card IS RECORD (
        blood_group       VARCHAR2(3),
        units_available   NUMBER,
        units_reserved    NUMBER,
        status_label      VARCHAR2(20),
        compatible_units  NUMBER
    );

    -- Associative Array (Index-by table) of Stock Cards
    TYPE t_stock_table IS TABLE OF t_stock_card INDEX BY BINARY_INTEGER;

END pkg_blood_bank_types;
/

-- =============================================================================
-- 2. PACKAGE SPECIFICATION: pkg_blood_bank_service
-- =============================================================================
CREATE OR REPLACE PACKAGE pkg_blood_bank_service AS
    -- Public Procedures
    PROCEDURE register_donor_secure(
        p_first_name    IN  VARCHAR2,
        p_last_name     IN  VARCHAR2,
        p_email         IN  VARCHAR2,
        p_phone         IN  VARCHAR2,
        p_gender        IN  CHAR,
        p_dob           IN  DATE,
        p_weight_kg     IN  NUMBER,
        p_blood_group   IN  VARCHAR2,
        p_city          IN  VARCHAR2,
        p_address       IN  VARCHAR2,
        p_notes         IN  VARCHAR2,
        o_donor_id      OUT NUMBER,
        o_msg           OUT VARCHAR2
    );

    PROCEDURE record_donation_session(
        p_donor_id           IN  NUMBER,
        p_units              IN  NUMBER,
        p_hb                 IN  NUMBER,
        p_camp               IN  VARCHAR2,
        p_doctor             IN  VARCHAR2,
        p_remarks            IN  VARCHAR2,
        o_donation_id        OUT NUMBER,
        o_msg                OUT VARCHAR2
    );

    PROCEDURE fulfill_patient_request(
        p_request_id IN  NUMBER,
        p_admin_user IN  VARCHAR2,
        p_remarks    IN  VARCHAR2,
        o_code       OUT VARCHAR2,
        o_msg        OUT VARCHAR2
    );

    -- Public Functions
    FUNCTION get_compatible_groups_csv(
        p_recipient_group IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_blood_bank_summary_json
    RETURN VARCHAR2;

    -- Dynamic Query Procedures returning Ref Cursors
    PROCEDURE get_inventory_cursor(
        o_cur OUT pkg_blood_bank_types.t_ref_cursor
    );

    PROCEDURE get_pending_requests_cursor(
        o_cur OUT pkg_blood_bank_types.t_ref_cursor
    );

    -- Batch Processing (Bulk Collect & Limit)
    PROCEDURE batch_identify_dormant_donors(
        p_inactive_months IN NUMBER DEFAULT 12
    );

END pkg_blood_bank_service;
/

-- =============================================================================
-- 3. PACKAGE BODY: pkg_blood_bank_service
-- =============================================================================
CREATE OR REPLACE PACKAGE BODY pkg_blood_bank_service AS

    -- -------------------------------------------------------------------------
    -- Procedure: register_donor_secure
    -- -------------------------------------------------------------------------
    PROCEDURE register_donor_secure(
        p_first_name    IN  VARCHAR2,
        p_last_name     IN  VARCHAR2,
        p_email         IN  VARCHAR2,
        p_phone         IN  VARCHAR2,
        p_gender        IN  CHAR,
        p_dob           IN  DATE,
        p_weight_kg     IN  NUMBER,
        p_blood_group   IN  VARCHAR2,
        p_city          IN  VARCHAR2,
        p_address       IN  VARCHAR2,
        p_notes         IN  VARCHAR2,
        o_donor_id      OUT NUMBER,
        o_msg           OUT VARCHAR2
    ) IS
    BEGIN
        sp_register_donor(
            p_first_name, p_last_name, p_email, p_phone,
            p_gender, p_dob, p_weight_kg, p_blood_group,
            p_city, p_address, p_notes, o_donor_id, o_msg
        );
    END register_donor_secure;

    -- -------------------------------------------------------------------------
    -- Procedure: record_donation_session
    -- -------------------------------------------------------------------------
    PROCEDURE record_donation_session(
        p_donor_id           IN  NUMBER,
        p_units              IN  NUMBER,
        p_hb                 IN  NUMBER,
        p_camp               IN  VARCHAR2,
        p_doctor             IN  VARCHAR2,
        p_remarks            IN  VARCHAR2,
        o_donation_id        OUT NUMBER,
        o_msg                OUT VARCHAR2
    ) IS
    BEGIN
        sp_record_donation(
            p_donor_id, NVL(p_units, 1), SYSDATE,
            p_hb, 120, 80, 72,
            p_camp, p_doctor, p_remarks,
            o_donation_id, o_msg
        );
    END record_donation_session;

    -- -------------------------------------------------------------------------
    -- Procedure: fulfill_patient_request
    -- -------------------------------------------------------------------------
    PROCEDURE fulfill_patient_request(
        p_request_id IN  NUMBER,
        p_admin_user IN  VARCHAR2,
        p_remarks    IN  VARCHAR2,
        o_code       OUT VARCHAR2,
        o_msg        OUT VARCHAR2
    ) IS
    BEGIN
        sp_process_blood_request(
            p_request_id, 'FULFILL', p_admin_user, p_remarks, o_code, o_msg
        );
    END fulfill_patient_request;

    -- -------------------------------------------------------------------------
    -- Function: get_compatible_groups_csv
    -- Returns comma-separated list of compatible donor groups for a recipient
    -- -------------------------------------------------------------------------
    FUNCTION get_compatible_groups_csv(
        p_recipient_group IN VARCHAR2
    ) RETURN VARCHAR2
    IS
        v_csv VARCHAR2(200) := '';
    BEGIN
        FOR rec IN (
            SELECT donor_group
              FROM blood_compatibility
             WHERE recipient_group = UPPER(TRIM(p_recipient_group))
               AND is_compatible = 'Y'
             ORDER BY preference_level ASC, donor_group ASC
        ) LOOP
            IF v_csv IS NULL OR LENGTH(v_csv) = 0 THEN
                v_csv := rec.donor_group;
            ELSE
                v_csv := v_csv || ', ' || rec.donor_group;
            END IF;
        END LOOP;

        RETURN NVL(v_csv, 'None');
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 'Error';
    END get_compatible_groups_csv;

    -- -------------------------------------------------------------------------
    -- Function: get_blood_bank_summary_json
    -- Formats key system metrics in standard JSON format
    -- -------------------------------------------------------------------------
    FUNCTION get_blood_bank_summary_json
    RETURN VARCHAR2
    IS
        v_total_stock    NUMBER;
        v_total_donors   NUMBER;
        v_total_reqs     NUMBER;
        v_pending_reqs   NUMBER;
        v_json           VARCHAR2(1000);
    BEGIN
        SELECT NVL(SUM(units_available), 0) INTO v_total_stock FROM blood_stock;
        SELECT COUNT(*) INTO v_total_donors FROM donors WHERE status = 'ACTIVE';
        SELECT COUNT(*) INTO v_total_reqs FROM blood_requests;
        SELECT COUNT(*) INTO v_pending_reqs FROM blood_requests WHERE status = 'PENDING';

        v_json := '{"status":"ONLINE",' ||
                  '"total_units_available":' || v_total_stock || ',' ||
                  '"active_donors":' || v_total_donors || ',' ||
                  '"total_requests":' || v_total_reqs || ',' ||
                  '"pending_requests":' || v_pending_reqs || '}';

        RETURN v_json;
    END get_blood_bank_summary_json;

    -- -------------------------------------------------------------------------
    -- Procedure: get_inventory_cursor
    -- Opens Ref Cursor for caller (Java/Node/C#/Python/APEX)
    -- -------------------------------------------------------------------------
    PROCEDURE get_inventory_cursor(
        o_cur OUT pkg_blood_bank_types.t_ref_cursor
    ) IS
    BEGIN
        OPEN o_cur FOR
            SELECT s.blood_group,
                   s.units_available,
                   s.units_reserved,
                   s.critical_threshold,
                   fn_get_stock_status(s.blood_group) AS status_label,
                   fn_get_compatible_stock(s.blood_group) AS total_compat_stock,
                   s.last_updated
              FROM blood_stock s
             ORDER BY s.blood_group;
    END get_inventory_cursor;

    -- -------------------------------------------------------------------------
    -- Procedure: get_pending_requests_cursor
    -- -------------------------------------------------------------------------
    PROCEDURE get_pending_requests_cursor(
        o_cur OUT pkg_blood_bank_types.t_ref_cursor
    ) IS
    BEGIN
        OPEN o_cur FOR
            SELECT request_id, patient_name, hospital_name,
                   blood_group, units_required, urgency_level,
                   required_by_date, status, requested_at
              FROM blood_requests
             WHERE status IN ('PENDING', 'APPROVED')
             ORDER BY CASE urgency_level
                          WHEN 'CRITICAL' THEN 1
                          WHEN 'URGENT' THEN 2
                          ELSE 3
                      END, required_by_date ASC;
    END get_pending_requests_cursor;

    -- -------------------------------------------------------------------------
    -- Procedure: batch_identify_dormant_donors (BULK COLLECT & CURSOR DEMO)
    -- Demonstrates Bulk Processing of donors inactive for specified months
    -- -------------------------------------------------------------------------
    PROCEDURE batch_identify_dormant_donors(
        p_inactive_months IN NUMBER DEFAULT 12
    ) IS
        TYPE t_donor_list IS TABLE OF donors%ROWTYPE;
        v_dormant_donors t_donor_list;
        v_threshold_date DATE;
    BEGIN
        v_threshold_date := ADD_MONTHS(SYSDATE, -p_inactive_months);

        -- BULK COLLECT with LIMIT concept
        SELECT *
          BULK COLLECT INTO v_dormant_donors
          FROM donors
         WHERE status = 'ACTIVE'
           AND (last_donation_date IS NULL OR last_donation_date < v_threshold_date);

        DBMS_OUTPUT.PUT_LINE('----------------------------------------------------------------------------------------');
        DBMS_OUTPUT.PUT_LINE('BATCH ANALYSIS: Donors dormant for > ' || p_inactive_months || ' months (Eligible for Recall Drive):');
        DBMS_OUTPUT.PUT_LINE('Total dormant donors identified: ' || v_dormant_donors.COUNT);
        DBMS_OUTPUT.PUT_LINE('----------------------------------------------------------------------------------------');

        IF v_dormant_donors.COUNT > 0 THEN
            FOR i IN 1..v_dormant_donors.COUNT LOOP
                DBMS_OUTPUT.PUT_LINE(
                    'Donor #' || v_dormant_donors(i).donor_id || ': ' ||
                    RPAD(v_dormant_donors(i).first_name || ' ' || v_dormant_donors(i).last_name, 22) ||
                    ' [' || v_dormant_donors(i).blood_group || '] Phone: ' ||
                    v_dormant_donors(i).phone || ' (Last Donated: ' ||
                    NVL(TO_CHAR(v_dormant_donors(i).last_donation_date, 'YYYY-MM-DD'), 'Never') || ')'
                );
            END LOOP;
        END IF;
    END batch_identify_dormant_donors;

END pkg_blood_bank_service;
/

PROMPT PL/SQL Packages created successfully.
