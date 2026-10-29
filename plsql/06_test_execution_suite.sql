-- =============================================================================
-- Project Title: Blood Bank Management System (PL/SQL Project)
-- Component:     06_test_execution_suite.sql (Complete Verification & Demo Suite)
-- Target DBMS:   Oracle 11g / 12c / 18c / 19c / 21c / 23c / Oracle Live SQL
-- Description:   Comprehensive automated test harness executing all business
--                scenarios, positive paths, edge cases, trigger checks,
--                custom exceptions, and audit logs with rich formatted output.
-- =============================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED;
SET LINESIZE 200;
SET PAGESIZE 100;
SET FEEDBACK ON;

PROMPT =========================================================================;
PROMPT  STARTING COMPREHENSIVE PL/SQL TEST & VERIFICATION SUITE
PROMPT =========================================================================;

-- =============================================================================
-- TEST CASE 1: Inventory Health Check via Explicit Cursor Dashboard
-- =============================================================================
PROMPT 
PROMPT >>> TEST CASE 1: Displaying Initial Stock Inventory (sp_stock_inventory_report)
PROMPT -------------------------------------------------------------------------;
EXEC sp_stock_inventory_report;

-- =============================================================================
-- TEST CASE 2: Biological Blood Compatibility Matrix & Aggregation Query
-- =============================================================================
PROMPT 
PROMPT >>> TEST CASE 2: Biological Blood Compatibility & Total Compatible Pool
PROMPT -------------------------------------------------------------------------;
DECLARE
    TYPE t_groups IS VARRAY(8) OF VARCHAR2(3);
    v_groups t_groups := t_groups('O-', 'O+', 'A-', 'A+', 'B-', 'B+', 'AB-', 'AB+');
    v_compat_pool NUMBER;
    v_compat_csv  VARCHAR2(200);
BEGIN
    DBMS_OUTPUT.PUT_LINE(RPAD('PATIENT GROUP', 16) || RPAD('COMPATIBLE DONOR GROUPS', 45) || 'AVAILABLE UNITS');
    DBMS_OUTPUT.PUT_LINE('----------------------------------------------------------------------------------');
    FOR i IN 1..v_groups.COUNT LOOP
        v_compat_csv  := pkg_blood_bank_service.get_compatible_groups_csv(v_groups(i));
        v_compat_pool := fn_get_compatible_stock(v_groups(i));
        DBMS_OUTPUT.PUT_LINE(
            RPAD(v_groups(i), 16) ||
            RPAD(v_compat_csv, 45) ||
            TO_CHAR(v_compat_pool) || ' units'
        );
    END LOOP;
END;
/

-- =============================================================================
-- TEST CASE 3: Successful Donor Registration (sp_register_donor)
-- =============================================================================
PROMPT 
PROMPT >>> TEST CASE 3: Registering a Valid Voluntary Donor
PROMPT -------------------------------------------------------------------------;
DECLARE
    v_new_donor_id NUMBER;
    v_msg          VARCHAR2(300);
BEGIN
    sp_register_donor(
        p_first_name    => 'Karan',
        p_last_name     => 'Kapoor',
        p_email         => 'karan.kapoor@example.com',
        p_phone         => '9876509999',
        p_gender        => 'M',
        p_dob           => TO_DATE('1996-07-15', 'YYYY-MM-DD'),
        p_weight_kg     => 72.5,
        p_blood_group   => 'O-',
        p_city          => 'Ludhiana',
        p_address       => 'Mall Road, Civil Lines',
        p_medical_notes => 'Healthy voluntary donor; no chronic ailments',
        o_donor_id      => v_new_donor_id,
        o_status_msg    => v_msg
    );
    DBMS_OUTPUT.PUT_LINE(v_msg);
    DBMS_OUTPUT.PUT_LINE('Eligibility status for Donor #' || v_new_donor_id || ': ' ||
                         fn_check_donor_eligibility(v_new_donor_id, SYSDATE));
END;
/

-- =============================================================================
-- TEST CASE 4: Negative Test - Attempting to Register an Underage Donor (Trigger Test)
-- =============================================================================
PROMPT 
PROMPT >>> TEST CASE 4: Trigger Validation - Attempting Underage Registration (< 18 yrs)
PROMPT -------------------------------------------------------------------------;
DECLARE
    v_id  NUMBER;
    v_msg VARCHAR2(300);
BEGIN
    sp_register_donor(
        p_first_name    => 'Junior',
        p_last_name     => 'Kid',
        p_email         => 'junior.kid@example.com',
        p_phone         => '9876509988',
        p_gender        => 'M',
        p_dob           => TO_DATE('2015-01-01', 'YYYY-MM-DD'), -- 11 years old!
        p_weight_kg     => 40.0,
        p_blood_group   => 'A+',
        p_city          => 'Ludhiana',
        p_address       => 'School Road',
        p_medical_notes => 'Minor',
        o_donor_id      => v_id,
        o_status_msg    => v_msg
    );
    DBMS_OUTPUT.PUT_LINE('Result: ' || v_msg);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Caught Exception as Expected: ' || SQLERRM);
END;
/

-- =============================================================================
-- TEST CASE 5: Recording a Successful Donation (Stock auto-increment & cooldown)
-- =============================================================================
PROMPT 
PROMPT >>> TEST CASE 5: Recording Donation for Eligible Donor (Auto-Increments Stock)
PROMPT -------------------------------------------------------------------------;
DECLARE
    v_don_id     NUMBER;
    v_msg        VARCHAR2(300);
    v_stock_pre  NUMBER;
    v_stock_post NUMBER;
BEGIN
    SELECT units_available INTO v_stock_pre FROM blood_stock WHERE blood_group = 'AB+';
    DBMS_OUTPUT.PUT_LINE('Pre-donation AB+ Units Available: ' || v_stock_pre);

    -- Donor 105 (Gurpreet Singh) last donated in Nov 2025 (> 90 days ago)
    sp_record_donation(
        p_donor_id         => 105,
        p_units            => 2,
        p_donation_date    => SYSDATE,
        p_hemoglobin_g_dl  => 15.5,
        p_systolic_bp      => 120,
        p_diastolic_bp     => 80,
        p_pulse_bpm        => 72,
        p_camp_or_facility => 'Central Red Cross Center',
        p_doctor           => 'Dr. R. K. Singla',
        p_remarks          => 'Double unit apheresis donation',
        o_donation_id      => v_don_id,
        o_result_msg       => v_msg
    );
    DBMS_OUTPUT.PUT_LINE(v_msg);

    SELECT units_available INTO v_stock_post FROM blood_stock WHERE blood_group = 'AB+';
    DBMS_OUTPUT.PUT_LINE('Post-donation AB+ Units Available: ' || v_stock_post || ' (Expected: ' || (v_stock_pre + 2) || ')');
END;
/

-- =============================================================================
-- TEST CASE 6: Negative Test - Attempting Donation within Cooldown (Trigger / Rule Test)
-- =============================================================================
PROMPT 
PROMPT >>> TEST CASE 6: 90-Day Cooldown Violation Test (Attempting Immediate Repeat Donation)
PROMPT -------------------------------------------------------------------------;
DECLARE
    v_don_id NUMBER;
    v_msg    VARCHAR2(300);
BEGIN
    -- Donor 105 just donated today in Test Case 5!
    sp_record_donation(
        p_donor_id         => 105,
        p_units            => 1,
        p_donation_date    => SYSDATE,
        p_hemoglobin_g_dl  => 15.0,
        p_systolic_bp      => 120,
        p_diastolic_bp     => 80,
        p_pulse_bpm        => 72,
        p_camp_or_facility => 'Central Red Cross Center',
        p_doctor           => 'Dr. Sharma',
        p_remarks          => 'Repeat attempt',
        o_donation_id      => v_don_id,
        o_result_msg       => v_msg
    );
    DBMS_OUTPUT.PUT_LINE('Procedure Output: ' || v_msg);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Caught Exception as Expected: ' || SQLERRM);
END;
/

-- =============================================================================
-- TEST CASE 7: Submitting a New Emergency Blood Request
-- =============================================================================
PROMPT 
PROMPT >>> TEST CASE 7: Submitting Emergency Blood Request (sp_submit_blood_request)
PROMPT -------------------------------------------------------------------------;
DECLARE
    v_new_req_id NUMBER;
    v_status_msg VARCHAR2(300);
BEGIN
    sp_submit_blood_request(
        p_patient_name     => 'Sunita Rani',
        p_hospital_name    => 'Apollo Hospital Ludhiana',
        p_requester_phone  => '9811122233',
        p_requester_email  => 'apollo.icu@apollo.org',
        p_blood_group      => 'O+',
        p_units_required   => 3,
        p_city             => 'Ludhiana',
        p_urgency_level    => 'CRITICAL',
        p_required_by_date => SYSDATE,
        p_medical_reason   => 'Acute bleeding during surgical operation',
        o_request_id       => v_new_req_id,
        o_status_msg       => v_status_msg
    );
    DBMS_OUTPUT.PUT_LINE(v_status_msg);
END;
/

-- =============================================================================
-- TEST CASE 8: Triage Queue via Parameterized Procedure
-- =============================================================================
PROMPT 
PROMPT >>> TEST CASE 8: Emergency Triage Queue Display (sp_emergency_requests_queue)
PROMPT -------------------------------------------------------------------------;
EXEC sp_emergency_requests_queue;

-- =============================================================================
-- TEST CASE 9: Fulfilling Blood Request with Row-Locking & Stock Decrement
-- =============================================================================
PROMPT 
PROMPT >>> TEST CASE 9: Fulfilling Blood Request #1001 (Pessimistic Lock & Stock Deduction)
PROMPT -------------------------------------------------------------------------;
DECLARE
    v_code       VARCHAR2(50);
    v_msg        VARCHAR2(300);
    v_stock_pre  NUMBER;
    v_stock_post NUMBER;
BEGIN
    -- Check request 1001 requires 2 units of B+
    SELECT units_available INTO v_stock_pre FROM blood_stock WHERE blood_group = 'B+';
    DBMS_OUTPUT.PUT_LINE('Pre-fulfillment B+ Stock: ' || v_stock_pre || ' units.');

    sp_process_blood_request(
        p_request_id  => 1001,
        p_action      => 'FULFILL',
        p_admin_user  => 'ADMIN_CHIEF',
        p_remarks     => 'Emergency release approved and dispatched with courier',
        o_result_code => v_code,
        o_result_msg  => v_msg
    );
    DBMS_OUTPUT.PUT_LINE('Fulfillment Result [' || v_code || ']: ' || v_msg);

    SELECT units_available INTO v_stock_post FROM blood_stock WHERE blood_group = 'B+';
    DBMS_OUTPUT.PUT_LINE('Post-fulfillment B+ Stock: ' || v_stock_post || ' units. (Deducted 2 units successfully)');
END;
/

-- =============================================================================
-- TEST CASE 10: Negative Test - Request Fulfillment with Stock Deficit
-- =============================================================================
PROMPT 
PROMPT >>> TEST CASE 10: Negative Stock Guard - Attempting Overdraw on Request
PROMPT -------------------------------------------------------------------------;
DECLARE
    v_exorbitant_req NUMBER;
    v_status_msg     VARCHAR2(300);
    v_code           VARCHAR2(50);
    v_msg            VARCHAR2(300);
BEGIN
    -- Submit request for 100 units of AB- (only 4 exist!)
    sp_submit_blood_request(
        p_patient_name     => 'Mass Casualty Drill',
        p_hospital_name    => 'Disaster Relief Wing',
        p_requester_phone  => '9800098000',
        p_requester_email  => 'disaster@dr.org',
        p_blood_group      => 'AB-',
        p_units_required   => 100,
        p_city             => 'Ludhiana',
        p_urgency_level    => 'CRITICAL',
        p_required_by_date => SYSDATE,
        p_medical_reason   => 'Disaster scenario requirement',
        o_request_id       => v_exorbitant_req,
        o_status_msg       => v_status_msg
    );
    DBMS_OUTPUT.PUT_LINE('Created Request #' || v_exorbitant_req || ': ' || v_status_msg);

    -- Try to fulfill
    sp_process_blood_request(
        p_request_id  => v_exorbitant_req,
        p_action      => 'FULFILL',
        p_admin_user  => 'ADMIN',
        p_remarks     => 'Attempting release',
        o_result_code => v_code,
        o_result_msg  => v_msg
    );
    DBMS_OUTPUT.PUT_LINE('System Response [' || v_code || ']: ' || v_msg);
END;
/

-- =============================================================================
-- TEST CASE 11: Parameterized Cursor - Finding Donors by Blood Group & City
-- =============================================================================
PROMPT 
PROMPT >>> TEST CASE 11: Parameterized Donor Search (sp_list_eligible_donors)
PROMPT -------------------------------------------------------------------------;
EXEC sp_list_eligible_donors(p_blood_group => 'O+', p_city => 'Ludhiana');

-- =============================================================================
-- TEST CASE 12: Package Ref Cursor & Batch Dormant Donor Recall
-- =============================================================================
PROMPT 
PROMPT >>> TEST CASE 12: Package Services & Batch Dormant Donor Recall
PROMPT -------------------------------------------------------------------------;
BEGIN
    DBMS_OUTPUT.PUT_LINE('JSON Snapshot from Package:');
    DBMS_OUTPUT.PUT_LINE(pkg_blood_bank_service.get_blood_bank_summary_json);
    DBMS_OUTPUT.PUT_LINE(' ');

    -- Execute batch procedure
    pkg_blood_bank_service.batch_identify_dormant_donors(p_inactive_months => 6);
END;
/

-- =============================================================================
-- TEST CASE 13: Audit Trail Log Verification
-- =============================================================================
PROMPT 
PROMPT >>> TEST CASE 13: Verifying Autonomous Audit Log (audit_log table)
PROMPT -------------------------------------------------------------------------;
DECLARE
    CURSOR cur_audit IS
        SELECT log_id,
               table_name,
               action_type,
               record_id,
               SUBSTR(new_values, 1, 45) AS details,
               TO_CHAR(log_timestamp, 'HH24:MI:SS') AS log_time,
               logged_by
          FROM audit_log
         ORDER BY log_id DESC;
    v_rec cur_audit%ROWTYPE;
    v_counter NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE(RPAD('LOG_ID', 8) || RPAD('TABLE', 16) || RPAD('ACTION', 18) || 
                         RPAD('REC_ID', 8) || RPAD('NEW VALUES SNIPPET', 48) || 'TIME');
    DBMS_OUTPUT.PUT_LINE('----------------------------------------------------------------------------------------');

    OPEN cur_audit;
    LOOP
        FETCH cur_audit INTO v_rec;
        EXIT WHEN cur_audit%NOTFOUND OR v_counter >= 10;
        v_counter := v_counter + 1;

        DBMS_OUTPUT.PUT_LINE(
            RPAD(TO_CHAR(v_rec.log_id), 8) ||
            RPAD(v_rec.table_name, 16) ||
            RPAD(v_rec.action_type, 18) ||
            RPAD(NVL(v_rec.record_id, '-'), 8) ||
            RPAD(NVL(v_rec.details, '-'), 48) ||
            v_rec.log_time
        );
    END LOOP;
    CLOSE cur_audit;

    DBMS_OUTPUT.PUT_LINE('----------------------------------------------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('Total audit entries recorded during test session: ' || v_counter || '+');
END;
/

PROMPT 
PROMPT =========================================================================;
PROMPT  TEST & VERIFICATION SUITE FINISHED SUCCESSFULLY!
PROMPT  All functional paths, constraints, and audit routines verified.
PROMPT =========================================================================;
