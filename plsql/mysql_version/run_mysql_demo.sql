-- =============================================================================
-- MySQL Demo Execution Script
-- Runs sample procedure calls and prints outputs
-- =============================================================================
USE bloodbank_plsql;

SELECT '>>> 1. INITIAL INVENTORY DASHBOARD REPORT' AS Step;
CALL sp_stock_inventory_report();

SELECT '>>> 2. EMERGENCY REQUESTS QUEUE' AS Step;
CALL sp_emergency_requests_queue();

SELECT '>>> 3. REGISTERING A NEW DONOR (Procedure Call)' AS Step;
CALL sp_register_donor('Vikas', 'Mehra', 'vikas.mehra@example.com', '9876543210', 'M', '1997-04-10', 70.0, 'O+', 'Ludhiana', 'Civil Lines', @new_donor_id, @reg_status);
SELECT @new_donor_id AS NewDonorID, @reg_status AS StatusMessage;

SELECT '>>> 4. RECORDING A DONATION (Procedure Call)' AS Step;
CALL sp_record_donation(1, 1, CURDATE(), 14.5, 'Ludhiana Rotary Camp', @don_id, @don_status);
SELECT @don_id AS DonationID, @don_status AS ResultMessage;

SELECT '>>> 5. PROCESSING & FULFILLING BLOOD REQUEST #1 (Procedure Call)' AS Step;
CALL sp_process_blood_request(1, 'FULFILL', 'admin_doc', 'Dispensed to Civil Hospital for surgery', @code, @msg);
SELECT @code AS StatusCode, @msg AS FulfillmentMessage;

SELECT '>>> 6. ATTEMPTING REQUEST WITH INSUFFICIENT STOCK' AS Step;
-- Harpreet Singh request #2 requires 1 unit of O- (let's test with a simulated huge request)
CALL sp_process_blood_request(2, 'FULFILL', 'admin_doc', 'Dispensed for emergency trauma', @code2, @msg2);
SELECT @code2 AS StatusCode, @msg2 AS FulfillmentMessage;

SELECT '>>> 7. AUDIT LOG VERIFICATION' AS Step;
SELECT log_id, table_name, action_type, record_id, SUBSTRING(new_values, 1, 50) AS details, log_timestamp, logged_by
  FROM audit_log
 ORDER BY log_id DESC
 LIMIT 8;
