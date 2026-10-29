-- =============================================================================
-- Project Title: Blood Bank Management System (PL/SQL Project)
-- Component:     03_procedures.sql (PL/SQL Stored Procedures)
-- Target DBMS:   Oracle 11g / 12c / 18c / 19c / 21c / 23c / Oracle Live SQL
-- Description:   Complete transactional business logic implementing:
--                1. Donor Registration with biometrics verification
--                2. Donation Recording with cooldown checking & stock increment
--                3. Blood Request Submission & Emergency Triage
--                4. Request Fulfillment with row locking & stock decrement
--                5. Manual Stock Adjustments & Administrative Auditing
--                6. Explicit Cursor Dashboards & Parameterized Reporting
-- =============================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED;

PROMPT =========================================================================;
PROMPT  CREATING PL/SQL STORED PROCEDURES...;
PROMPT =========================================================================;

-- -----------------------------------------------------------------------------
-- 1. PROCEDURE: sp_register_donor
-- Description: Registers a new voluntary blood donor with medical prerequisites.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_register_donor(
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
    p_medical_notes IN  VARCHAR2,
    o_donor_id      OUT NUMBER,
    o_status_msg    OUT VARCHAR2
)
IS
    v_age           NUMBER;
    v_bg_count      NUMBER;
    v_new_id        NUMBER;
    e_invalid_age   EXCEPTION;
    e_invalid_wt    EXCEPTION;
    e_invalid_bg    EXCEPTION;
BEGIN
    -- 1. Validate Blood Group existence
    SELECT COUNT(*)
      INTO v_bg_count
      FROM blood_groups
     WHERE blood_group_id = UPPER(TRIM(p_blood_group));

    IF v_bg_count = 0 THEN
        RAISE e_invalid_bg;
    END IF;

    -- 2. Validate Age Criteria (18-65)
    v_age := fn_calculate_age(p_dob);
    IF v_age < 18 OR v_age > 65 THEN
        RAISE e_invalid_age;
    END IF;

    -- 3. Validate Weight Criteria (>= 45kg)
    IF p_weight_kg < 45.0 THEN
        RAISE e_invalid_wt;
    END IF;

    -- 4. Generate ID and Insert
    v_new_id := seq_donor_id.NEXTVAL;

    INSERT INTO donors (
        donor_id, first_name, last_name, email, phone, gender,
        dob, weight_kg, blood_group, city, address,
        last_donation_date, total_donations, status, medical_notes, registered_at
    ) VALUES (
        v_new_id, INITCAP(TRIM(p_first_name)), INITCAP(TRIM(p_last_name)),
        LOWER(TRIM(p_email)), TRIM(p_phone), UPPER(TRIM(p_gender)),
        TRUNC(p_dob), p_weight_kg, UPPER(TRIM(p_blood_group)),
        INITCAP(TRIM(p_city)), p_address,
        NULL, 0, 'ACTIVE', p_medical_notes, SYSDATE
    );

    -- 5. Audit Log
    INSERT INTO audit_log (log_id, table_name, action_type, record_id, new_values, logged_by)
    VALUES (
        seq_audit_id.NEXTVAL, 'DONORS', 'INSERT', TO_CHAR(v_new_id),
        'Name=' || p_first_name || ' ' || p_last_name || '; Group=' || p_blood_group || '; City=' || p_city,
        USER
    );

    o_donor_id   := v_new_id;
    o_status_msg := 'SUCCESS: Donor registered successfully with ID: ' || v_new_id;

EXCEPTION
    WHEN e_invalid_bg THEN
        o_donor_id   := NULL;
        o_status_msg := 'FAILED: Invalid blood group specified (' || p_blood_group || ').';
    WHEN e_invalid_age THEN
        o_donor_id   := NULL;
        o_status_msg := 'FAILED: Donor age (' || v_age || ' yrs) is outside permitted range (18 to 65).';
    WHEN e_invalid_wt THEN
        o_donor_id   := NULL;
        o_status_msg := 'FAILED: Donor weight (' || p_weight_kg || ' kg) must be at least 45.0 kg.';
    WHEN DUP_VAL_ON_INDEX THEN
        o_donor_id   := NULL;
        o_status_msg := 'FAILED: Donor with email (' || p_email || ') or phone (' || p_phone || ') already registered.';
    WHEN OTHERS THEN
        o_donor_id   := NULL;
        o_status_msg := 'ERROR: Registration failed: ' || SQLERRM;
END sp_register_donor;
/

-- -----------------------------------------------------------------------------
-- 2. PROCEDURE: sp_record_donation
-- Description: Records a successful blood donation, validates 90-day cooldown,
--              updates donor stats, increments blood stock, and creates an audit entry.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_record_donation(
    p_donor_id           IN  NUMBER,
    p_units              IN  NUMBER,
    p_donation_date      IN  DATE,
    p_hemoglobin_g_dl    IN  NUMBER,
    p_systolic_bp        IN  NUMBER,
    p_diastolic_bp       IN  NUMBER,
    p_pulse_bpm          IN  NUMBER,
    p_camp_or_facility   IN  VARCHAR2,
    p_doctor             IN  VARCHAR2,
    p_remarks            IN  VARCHAR2,
    o_donation_id        OUT NUMBER,
    o_result_msg         OUT VARCHAR2
)
IS
    v_eligibility   VARCHAR2(255);
    v_blood_group   donors.blood_group%TYPE;
    v_donation_id   NUMBER;
    v_don_date      DATE;
    e_not_eligible  EXCEPTION;
BEGIN
    v_don_date := NVL(TRUNC(p_donation_date), TRUNC(SYSDATE));

    -- 1. Check eligibility via function
    v_eligibility := fn_check_donor_eligibility(p_donor_id, v_don_date);
    IF v_eligibility != 'ELIGIBLE' THEN
        RAISE e_not_eligible;
    END IF;

    -- 2. Retrieve donor blood group
    SELECT blood_group
      INTO v_blood_group
      FROM donors
     WHERE donor_id = p_donor_id;

    -- 3. Create Donation record
    v_donation_id := seq_donation_id.NEXTVAL;

    INSERT INTO donations (
        donation_id, donor_id, blood_group, units_donated, donation_date,
        hemoglobin_g_dl, systolic_bp, diastolic_bp, pulse_bpm,
        camp_or_facility, doctor_or_technician, screening_status, remarks, recorded_at
    ) VALUES (
        v_donation_id, p_donor_id, v_blood_group, NVL(p_units, 1), v_don_date,
        p_hemoglobin_g_dl, p_systolic_bp, p_diastolic_bp, p_pulse_bpm,
        NVL(p_camp_or_facility, 'Central Blood Bank'), p_doctor, 'PASSED', p_remarks, SYSTIMESTAMP
    );

    -- 4. Update Donor Profile (last donation date & total donations count)
    UPDATE donors
       SET last_donation_date = v_don_date,
           total_donations    = total_donations + NVL(p_units, 1)
     WHERE donor_id = p_donor_id;

    -- 5. Automatically Increment Blood Stock
    UPDATE blood_stock
       SET units_available = units_available + NVL(p_units, 1),
           last_updated    = SYSTIMESTAMP
     WHERE blood_group = v_blood_group;

    -- 6. Log Audit Trail
    INSERT INTO audit_log (log_id, table_name, action_type, record_id, new_values, logged_by)
    VALUES (
        seq_audit_id.NEXTVAL, 'DONATIONS', 'INSERT', TO_CHAR(v_donation_id),
        'DonorID=' || p_donor_id || '; Units=' || p_units || '; Group=' || v_blood_group,
        USER
    );

    o_donation_id := v_donation_id;
    o_result_msg  := 'SUCCESS: Donation recorded (ID: ' || v_donation_id || '). Stock for ' ||
                     v_blood_group || ' incremented by ' || NVL(p_units, 1) || ' unit(s).';

EXCEPTION
    WHEN e_not_eligible THEN
        o_donation_id := NULL;
        o_result_msg  := 'REJECTED: ' || v_eligibility;
    WHEN NO_DATA_FOUND THEN
        o_donation_id := NULL;
        o_result_msg  := 'FAILED: Donor ID ' || p_donor_id || ' not found.';
    WHEN OTHERS THEN
        o_donation_id := NULL;
        o_result_msg  := 'ERROR: Failed to record donation: ' || SQLERRM;
END sp_record_donation;
/

-- -----------------------------------------------------------------------------
-- 3. PROCEDURE: sp_submit_blood_request
-- Description: Submits a new blood request on behalf of a patient or hospital.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_submit_blood_request(
    p_patient_name     IN  VARCHAR2,
    p_hospital_name    IN  VARCHAR2,
    p_requester_phone  IN  VARCHAR2,
    p_requester_email  IN  VARCHAR2,
    p_blood_group      IN  VARCHAR2,
    p_units_required   IN  NUMBER,
    p_city             IN  VARCHAR2,
    p_urgency_level    IN  VARCHAR2,
    p_required_by_date IN  DATE,
    p_medical_reason   IN  VARCHAR2,
    o_request_id       OUT NUMBER,
    o_status_msg       OUT VARCHAR2
)
IS
    v_req_id        NUMBER;
    v_bg_clean      VARCHAR2(3);
    v_urgency_clean VARCHAR2(10);
    v_avail_stock   NUMBER := 0;
    v_compat_stock  NUMBER := 0;
BEGIN
    v_bg_clean      := UPPER(TRIM(p_blood_group));
    v_urgency_clean := UPPER(NVL(TRIM(p_urgency_level), 'NORMAL'));

    IF p_units_required <= 0 THEN
        o_request_id := NULL;
        o_status_msg := 'FAILED: Units required must be greater than zero.';
        RETURN;
    END IF;

    IF v_urgency_clean NOT IN ('NORMAL', 'URGENT', 'CRITICAL') THEN
        o_request_id := NULL;
        o_status_msg := 'FAILED: Urgency level must be NORMAL, URGENT, or CRITICAL.';
        RETURN;
    END IF;

    v_req_id := seq_request_id.NEXTVAL;

    INSERT INTO blood_requests (
        request_id, patient_name, hospital_name, requester_phone,
        requester_email, blood_group, units_required, city,
        urgency_level, required_by_date, status, medical_reason,
        requested_at
    ) VALUES (
        v_req_id, INITCAP(TRIM(p_patient_name)), TRIM(p_hospital_name),
        TRIM(p_requester_phone), LOWER(TRIM(p_requester_email)),
        v_bg_clean, p_units_required, INITCAP(TRIM(p_city)),
        v_urgency_clean, NVL(p_required_by_date, SYSDATE + 1), 'PENDING',
        p_medical_reason, SYSTIMESTAMP
    );

    -- Check availability for instant advisory
    SELECT NVL(units_available, 0)
      INTO v_avail_stock
      FROM blood_stock
     WHERE blood_group = v_bg_clean;

    v_compat_stock := fn_get_compatible_stock(v_bg_clean);

    o_request_id := v_req_id;
    o_status_msg := 'SUCCESS: Request #' || v_req_id || ' lodged. [Direct ' || v_bg_clean ||
                    ' Stock: ' || v_avail_stock || ' units | Total Compatible: ' || v_compat_stock || ' units]';

EXCEPTION
    WHEN OTHERS THEN
        o_request_id := NULL;
        o_status_msg := 'ERROR: Blood request submission failed: ' || SQLERRM;
END sp_submit_blood_request;
/

-- -----------------------------------------------------------------------------
-- 4. PROCEDURE: sp_process_blood_request
-- Description: Core transactional fulfillment engine.
--              Implements pessimistic locking (FOR UPDATE) to prevent race conditions.
--              If fulfilling, checks stock, decrements inventory, creates issuance,
--              and updates request status.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_process_blood_request(
    p_request_id   IN  NUMBER,
    p_action       IN  VARCHAR2,   -- 'APPROVE', 'FULFILL', 'REJECT'
    p_admin_user   IN  VARCHAR2,
    p_remarks      IN  VARCHAR2,
    o_result_code  OUT VARCHAR2,   -- 'SUCCESS' / 'INSUFFICIENT_STOCK' / 'INVALID_STATE' / 'ERROR'
    o_result_msg   OUT VARCHAR2
)
IS
    v_req            blood_requests%ROWTYPE;
    v_stock_avail    NUMBER;
    v_stock_resvd    NUMBER;
    v_issuance_id    NUMBER;
    e_low_stock      EXCEPTION;
    e_already_done   EXCEPTION;
    e_invalid_action EXCEPTION;
BEGIN
    -- 1. Fetch Request with Lock
    BEGIN
        SELECT *
          INTO v_req
          FROM blood_requests
         WHERE request_id = p_request_id
           FOR UPDATE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            o_result_code := 'NOT_FOUND';
            o_result_msg  := 'Request #' || p_request_id || ' does not exist.';
            RETURN;
    END;

    -- 2. Verify state
    IF v_req.status IN ('FULFILLED', 'REJECTED', 'CANCELLED') THEN
        RAISE e_already_done;
    END IF;

    -- 3. Execute Decision
    IF UPPER(p_action) = 'REJECT' THEN
        UPDATE blood_requests
           SET status        = 'REJECTED',
               admin_remarks = p_remarks,
               processed_at  = SYSTIMESTAMP,
               processed_by  = NVL(p_admin_user, USER)
         WHERE request_id = p_request_id;

        o_result_code := 'SUCCESS';
        o_result_msg  := 'Request #' || p_request_id || ' marked REJECTED.';

    ELSIF UPPER(p_action) = 'APPROVE' THEN
        -- Mark APPROVED (reservation stage)
        UPDATE blood_requests
           SET status        = 'APPROVED',
               admin_remarks = p_remarks,
               processed_at  = SYSTIMESTAMP,
               processed_by  = NVL(p_admin_user, USER)
         WHERE request_id = p_request_id;

        o_result_code := 'SUCCESS';
        o_result_msg  := 'Request #' || p_request_id || ' APPROVED for release.';

    ELSIF UPPER(p_action) = 'FULFILL' THEN
        -- 3a. Lock Stock Row
        SELECT units_available, units_reserved
          INTO v_stock_avail, v_stock_resvd
          FROM blood_stock
         WHERE blood_group = v_req.blood_group
           FOR UPDATE;

        -- 3b. Verify Stock Availability
        IF v_stock_avail < v_req.units_required THEN
            RAISE e_low_stock;
        END IF;

        -- 3c. Decrement Stock
        UPDATE blood_stock
           SET units_available = units_available - v_req.units_required,
               last_updated    = SYSTIMESTAMP
         WHERE blood_group = v_req.blood_group;

        -- 3d. Record Issuance
        v_issuance_id := seq_issuance_id.NEXTVAL;
        INSERT INTO blood_issuances (
            issuance_id, request_id, blood_group_issued, units_issued,
            issued_at, issued_by, recipient_hospital, notes
        ) VALUES (
            v_issuance_id, v_req.request_id, v_req.blood_group, v_req.units_required,
            SYSTIMESTAMP, NVL(p_admin_user, USER), v_req.hospital_name,
            NVL(p_remarks, 'Fulfilled via automated workflow')
        );

        -- 3e. Update Request Status
        UPDATE blood_requests
           SET status        = 'FULFILLED',
               admin_remarks = NVL(p_remarks, 'Units dispensed'),
               processed_at  = SYSTIMESTAMP,
               processed_by  = NVL(p_admin_user, USER)
         WHERE request_id = p_request_id;

        -- 3f. Audit Log
        INSERT INTO audit_log (log_id, table_name, action_type, record_id, new_values, logged_by)
        VALUES (
            seq_audit_id.NEXTVAL, 'BLOOD_REQUESTS', 'FULFILL', TO_CHAR(p_request_id),
            'UnitsDispensed=' || v_req.units_required || '; Group=' || v_req.blood_group ||
            '; RemainingStock=' || (v_stock_avail - v_req.units_required),
            NVL(p_admin_user, USER)
        );

        o_result_code := 'SUCCESS';
        o_result_msg  := 'Request #' || p_request_id || ' FULFILLED. Dispensed ' ||
                         v_req.units_required || ' unit(s) of ' || v_req.blood_group ||
                         ' to ' || v_req.hospital_name || ' (Issuance #' || v_issuance_id || ').';

    ELSE
        RAISE e_invalid_action;
    END IF;

EXCEPTION
    WHEN e_already_done THEN
        o_result_code := 'INVALID_STATE';
        o_result_msg  := 'Request #' || p_request_id || ' has already been processed with status: ' || v_req.status;
    WHEN e_low_stock THEN
        o_result_code := 'INSUFFICIENT_STOCK';
        o_result_msg  := 'Cannot fulfill Request #' || p_request_id || '. Required: ' ||
                         v_req.units_required || ' units of ' || v_req.blood_group ||
                         ', but only ' || v_stock_avail || ' units currently in stock.';
    WHEN e_invalid_action THEN
        o_result_code := 'INVALID_ACTION';
        o_result_msg  := 'Invalid action "' || p_action || '". Permitted actions: APPROVE, FULFILL, REJECT.';
    WHEN OTHERS THEN
        o_result_code := 'ERROR';
        o_result_msg  := 'Failed to process request: ' || SQLERRM;
END sp_process_blood_request;
/

-- -----------------------------------------------------------------------------
-- 5. PROCEDURE: sp_manual_stock_adjustment
-- Description: Administrative inventory adjustment with full audit trail.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_manual_stock_adjustment(
    p_blood_group    IN  VARCHAR2,
    p_unit_change    IN  NUMBER,    -- Positive to add, negative to deduct
    p_reason         IN  VARCHAR2,
    p_admin_user     IN  VARCHAR2,
    o_new_stock      OUT NUMBER,
    o_status_msg     OUT VARCHAR2
)
IS
    v_old_stock NUMBER;
    v_new_stock NUMBER;
    v_bg        VARCHAR2(3);
BEGIN
    v_bg := UPPER(TRIM(p_blood_group));

    -- Lock stock row
    SELECT units_available
      INTO v_old_stock
      FROM blood_stock
     WHERE blood_group = v_bg
       FOR UPDATE;

    v_new_stock := v_old_stock + p_unit_change;

    IF v_new_stock < 0 THEN
        o_new_stock  := v_old_stock;
        o_status_msg := 'REJECTED: Adjustment would cause negative stock (' || v_new_stock || ').';
        RETURN;
    END IF;

    UPDATE blood_stock
       SET units_available = v_new_stock,
           last_updated    = SYSTIMESTAMP
     WHERE blood_group = v_bg;

    INSERT INTO audit_log (log_id, table_name, action_type, record_id, old_values, new_values, logged_by)
    VALUES (
        seq_audit_id.NEXTVAL, 'BLOOD_STOCK', 'MANUAL_ADJUSTMENT', v_bg,
        'Units=' || v_old_stock,
        'Units=' || v_new_stock || '; Reason=' || p_reason,
        NVL(p_admin_user, USER)
    );

    o_new_stock  := v_new_stock;
    o_status_msg := 'SUCCESS: Stock for ' || v_bg || ' updated from ' || v_old_stock ||
                    ' to ' || v_new_stock || ' units.';

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        o_new_stock  := NULL;
        o_status_msg := 'FAILED: Blood group ' || p_blood_group || ' not recognized.';
    WHEN OTHERS THEN
        o_new_stock  := NULL;
        o_status_msg := 'ERROR: ' || SQLERRM;
END sp_manual_stock_adjustment;
/

-- -----------------------------------------------------------------------------
-- 6. PROCEDURE: sp_stock_inventory_report (CURSOR DEMONSTRATION)
-- Description: Generates a real-time ASCII dashboard of blood stock levels
--              using an explicit cursor with status categorization.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_stock_inventory_report
IS
    -- Explicit Cursor definition
    CURSOR cur_stock IS
        SELECT s.blood_group,
               g.blood_type,
               g.rh_factor,
               s.units_available,
               s.units_reserved,
               s.critical_threshold,
               s.low_threshold,
               s.ideal_capacity,
               fn_get_stock_status(s.blood_group) AS health_status,
               fn_get_compatible_stock(s.blood_group) AS total_compat_units
          FROM blood_stock s
          JOIN blood_groups g ON s.blood_group = g.blood_group_id
         ORDER BY s.units_available ASC;

    v_row cur_stock%ROWTYPE;
    v_total_available NUMBER := 0;
    v_total_reserved  NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('========================================================================================');
    DBMS_OUTPUT.PUT_LINE('                   BLOOD BANK CENTRAL INVENTORY DASHBOARD REPORT                        ');
    DBMS_OUTPUT.PUT_LINE('                   Generated on: ' || TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS')          );
    DBMS_OUTPUT.PUT_LINE('========================================================================================');
    DBMS_OUTPUT.PUT_LINE(RPAD('GROUP', 8) || RPAD('AVAILABLE', 12) || RPAD('RESERVED', 10) || 
                         RPAD('CRIT_TH', 10) || RPAD('STATUS', 14) || RPAD('COMPAT_POOL', 14) || 'GAUGE');
    DBMS_OUTPUT.PUT_LINE('----------------------------------------------------------------------------------------');

    OPEN cur_stock;
    LOOP
        FETCH cur_stock INTO v_row;
        EXIT WHEN cur_stock%NOTFOUND;

        v_total_available := v_total_available + v_row.units_available;
        v_total_reserved  := v_total_reserved + v_row.units_reserved;

        DBMS_OUTPUT.PUT(
            RPAD(v_row.blood_group, 8) ||
            RPAD(TO_CHAR(v_row.units_available) || ' units', 12) ||
            RPAD(TO_CHAR(v_row.units_reserved), 10) ||
            RPAD(TO_CHAR(v_row.critical_threshold), 10) ||
            RPAD('[' || v_row.health_status || ']', 14) ||
            RPAD(TO_CHAR(v_row.total_compat_units) || ' units', 14)
        );

        -- Print simple visual bar gauge
        IF v_row.health_status = 'CRITICAL' THEN
            DBMS_OUTPUT.PUT_LINE('[!! ALERT: CRITICAL LOW !!]');
        ELSIF v_row.health_status = 'LOW' THEN
            DBMS_OUTPUT.PUT_LINE('[! WARNING: REPLENISH !]');
        ELSE
            DBMS_OUTPUT.PUT_LINE('[OK - INVENTORY HEALTHY]');
        END IF;

    END LOOP;
    CLOSE cur_stock;

    DBMS_OUTPUT.PUT_LINE('----------------------------------------------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('TOTAL INVENTORY: ' || v_total_available || ' units available | ' ||
                         v_total_reserved || ' units reserved.');
    DBMS_OUTPUT.PUT_LINE('========================================================================================');
END sp_stock_inventory_report;
/

-- -----------------------------------------------------------------------------
-- 7. PROCEDURE: sp_list_eligible_donors (PARAMETERIZED CURSOR DEMO)
-- Description: Parameterized cursor procedure to find eligible donors for a
--              specific blood group and optional city.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_list_eligible_donors(
    p_blood_group IN VARCHAR2,
    p_city        IN VARCHAR2 DEFAULT NULL
)
IS
    -- Parameterized Cursor
    CURSOR cur_eligible_donors(cp_group VARCHAR2, cp_city VARCHAR2) IS
        SELECT d.donor_id,
               d.first_name || ' ' || d.last_name AS full_name,
               d.phone,
               d.email,
               d.blood_group,
               d.city,
               fn_calculate_age(d.dob) AS age,
               d.weight_kg,
               d.last_donation_date,
               fn_get_next_eligible_date(d.donor_id) AS next_eligible,
               fn_check_donor_eligibility(d.donor_id, SYSDATE) AS eligibility_status
          FROM donors d
         WHERE d.blood_group = UPPER(TRIM(cp_group))
           AND (cp_city IS NULL OR UPPER(d.city) = UPPER(TRIM(cp_city)))
           AND d.status = 'ACTIVE'
         ORDER BY d.last_donation_date ASC NULLS FIRST;

    v_count NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('========================================================================================');
    DBMS_OUTPUT.PUT_LINE('         VOLUNTEER DONOR CONTACT DIRECTORY FOR BLOOD GROUP: ' || UPPER(p_blood_group)    );
    IF p_city IS NOT NULL THEN
        DBMS_OUTPUT.PUT_LINE('         Filtered for City: ' || UPPER(p_city));
    END IF;
    DBMS_OUTPUT.PUT_LINE('========================================================================================');
    DBMS_OUTPUT.PUT_LINE(RPAD('ID', 6) || RPAD('DONOR NAME', 22) || RPAD('PHONE', 14) || 
                         RPAD('CITY', 14) || RPAD('LAST DONATED', 14) || 'ELIGIBILITY');
    DBMS_OUTPUT.PUT_LINE('----------------------------------------------------------------------------------------');

    FOR rec IN cur_eligible_donors(p_blood_group, p_city) LOOP
        v_count := v_count + 1;
        DBMS_OUTPUT.PUT_LINE(
            RPAD(TO_CHAR(rec.donor_id), 6) ||
            RPAD(SUBSTR(rec.full_name, 1, 20), 22) ||
            RPAD(rec.phone, 14) ||
            RPAD(rec.city, 14) ||
            RPAD(NVL(TO_CHAR(rec.last_donation_date, 'YYYY-MM-DD'), 'Never'), 14) ||
            rec.eligibility_status
        );
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('----------------------------------------------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('Total registered active donors matching criteria: ' || v_count);
    DBMS_OUTPUT.PUT_LINE('========================================================================================');
END sp_list_eligible_donors;
/

-- -----------------------------------------------------------------------------
-- 8. PROCEDURE: sp_emergency_requests_queue (CURSOR DEMO)
-- Description: Displays triage queue of open blood requests ordered by urgency.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_emergency_requests_queue
IS
    CURSOR cur_queue IS
        SELECT r.request_id,
               r.patient_name,
               r.hospital_name,
               r.blood_group,
               r.units_required,
               r.urgency_level,
               r.status,
               r.required_by_date,
               s.units_available,
               CASE 
                   WHEN s.units_available >= r.units_required THEN 'READY TO FULFILL'
                   ELSE 'INSUFFICIENT STOCK'
               END AS stock_readiness
          FROM blood_requests r
          JOIN blood_stock s ON r.blood_group = s.blood_group
         WHERE r.status IN ('PENDING', 'APPROVED')
         ORDER BY CASE r.urgency_level
                      WHEN 'CRITICAL' THEN 1
                      WHEN 'URGENT'   THEN 2
                      ELSE 3
                  END,
                  r.required_by_date ASC;

    v_rec cur_queue%ROWTYPE;
    v_count NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('========================================================================================');
    DBMS_OUTPUT.PUT_LINE('                     ACTIVE EMERGENCY BLOOD REQUEST TRIAGE QUEUE                        ');
    DBMS_OUTPUT.PUT_LINE('========================================================================================');
    DBMS_OUTPUT.PUT_LINE(RPAD('REQ#', 7) || RPAD('URGENCY', 10) || RPAD('PATIENT', 20) || 
                         RPAD('GROUP', 7) || RPAD('UNITS', 7) || RPAD('STOCK', 8) || 
                         RPAD('STATUS', 10) || 'READINESS');
    DBMS_OUTPUT.PUT_LINE('----------------------------------------------------------------------------------------');

    OPEN cur_queue;
    LOOP
        FETCH cur_queue INTO v_rec;
        EXIT WHEN cur_queue%NOTFOUND;
        v_count := v_count + 1;

        DBMS_OUTPUT.PUT_LINE(
            RPAD(TO_CHAR(v_rec.request_id), 7) ||
            RPAD('[' || v_rec.urgency_level || ']', 10) ||
            RPAD(SUBSTR(v_rec.patient_name, 1, 18), 20) ||
            RPAD(v_rec.blood_group, 7) ||
            RPAD(TO_CHAR(v_rec.units_required), 7) ||
            RPAD(TO_CHAR(v_rec.units_available), 8) ||
            RPAD(v_rec.status, 10) ||
            v_rec.stock_readiness
        );
    END LOOP;
    CLOSE cur_queue;

    DBMS_OUTPUT.PUT_LINE('----------------------------------------------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('Total pending/approved requests awaiting disposition: ' || v_count);
    DBMS_OUTPUT.PUT_LINE('========================================================================================');
END sp_emergency_requests_queue;
/

PROMPT PL/SQL Stored Procedures created successfully.
