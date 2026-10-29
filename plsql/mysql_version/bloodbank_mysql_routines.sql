-- =============================================================================
-- Project Title: Blood Bank Management System (MySQL Stored Procedures & Triggers)
-- Component:     bloodbank_mysql_routines.sql
-- Target DBMS:   MySQL 8.0+ / MySQL 9.x
-- Description:   Complete MySQL implementation of the Blood Bank PL/SQL Project:
--                Schema DDL, Stored Functions, Stored Procedures, Triggers,
--                Views, and Demonstration Execution Calls.
-- =============================================================================

DROP DATABASE IF EXISTS bloodbank_plsql;
CREATE DATABASE bloodbank_plsql CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE bloodbank_plsql;

-- =============================================================================
-- 1. TABLES & INTEGRITY CONSTRAINTS
-- =============================================================================

-- Blood Groups Reference Table
CREATE TABLE blood_groups (
    blood_group_id           VARCHAR(3)   PRIMARY KEY,
    blood_type               VARCHAR(2)   NOT NULL,
    rh_factor                CHAR(1)      NOT NULL,
    antigen                  VARCHAR(25)  NOT NULL,
    antibody                 VARCHAR(25)  NOT NULL,
    universal_donor_flag     CHAR(1)      DEFAULT 'N' NOT NULL,
    universal_recipient_flag CHAR(1)      DEFAULT 'N' NOT NULL,
    description              VARCHAR(200)
) ENGINE=InnoDB;

-- Biological Compatibility Matrix
CREATE TABLE blood_compatibility (
    compatibility_id INT AUTO_INCREMENT PRIMARY KEY,
    donor_group      VARCHAR(3) NOT NULL,
    recipient_group  VARCHAR(3) NOT NULL,
    is_compatible    CHAR(1)    DEFAULT 'Y' NOT NULL,
    preference_level TINYINT    DEFAULT 1 NOT NULL,
    notes            VARCHAR(100),
    CONSTRAINT fk_my_compat_d FOREIGN KEY (donor_group) REFERENCES blood_groups(blood_group_id),
    CONSTRAINT fk_my_compat_r FOREIGN KEY (recipient_group) REFERENCES blood_groups(blood_group_id),
    CONSTRAINT uq_my_compat UNIQUE (donor_group, recipient_group)
) ENGINE=InnoDB;

-- Donors Table
CREATE TABLE donors (
    donor_id           INT AUTO_INCREMENT PRIMARY KEY,
    first_name         VARCHAR(50)  NOT NULL,
    last_name          VARCHAR(50)  NOT NULL,
    email              VARCHAR(100) NOT NULL UNIQUE,
    phone              VARCHAR(20)  NOT NULL UNIQUE,
    gender             CHAR(1)      NOT NULL,
    dob                DATE         NOT NULL,
    weight_kg          DECIMAL(4,1) NOT NULL,
    blood_group        VARCHAR(3)   NOT NULL,
    city               VARCHAR(60)  NOT NULL,
    address            VARCHAR(200),
    last_donation_date DATE,
    total_donations    INT          DEFAULT 0 NOT NULL,
    status             VARCHAR(20)  DEFAULT 'ACTIVE' NOT NULL,
    medical_notes      VARCHAR(255),
    registered_at      TIMESTAMP    DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT fk_my_donor_bg FOREIGN KEY (blood_group) REFERENCES blood_groups(blood_group_id)
) ENGINE=InnoDB;

-- Blood Stock Inventory Table
CREATE TABLE blood_stock (
    blood_group        VARCHAR(3) PRIMARY KEY,
    units_available    INT        DEFAULT 0 NOT NULL,
    units_reserved     INT        DEFAULT 0 NOT NULL,
    critical_threshold INT        DEFAULT 5 NOT NULL,
    low_threshold      INT        DEFAULT 10 NOT NULL,
    ideal_capacity     INT        DEFAULT 100 NOT NULL,
    last_updated       TIMESTAMP  DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_my_stock_bg FOREIGN KEY (blood_group) REFERENCES blood_groups(blood_group_id)
) ENGINE=InnoDB;

-- Donations Table
CREATE TABLE donations (
    donation_id          INT AUTO_INCREMENT PRIMARY KEY,
    donor_id             INT          NOT NULL,
    blood_group          VARCHAR(3)   NOT NULL,
    units_donated        INT          DEFAULT 1 NOT NULL,
    donation_date        DATE         NOT NULL,
    hemoglobin_g_dl      DECIMAL(4,1),
    systolic_bp          INT,
    diastolic_bp         INT,
    pulse_bpm            INT,
    camp_or_facility     VARCHAR(100) DEFAULT 'Central Blood Bank' NOT NULL,
    doctor_or_technician VARCHAR(60),
    screening_status     VARCHAR(20)  DEFAULT 'PASSED' NOT NULL,
    remarks              VARCHAR(255),
    recorded_at          TIMESTAMP    DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT fk_my_don_donor FOREIGN KEY (donor_id) REFERENCES donors(donor_id) ON DELETE CASCADE,
    CONSTRAINT fk_my_don_bg FOREIGN KEY (blood_group) REFERENCES blood_groups(blood_group_id)
) ENGINE=InnoDB;

-- Blood Requests Table
CREATE TABLE blood_requests (
    request_id       INT AUTO_INCREMENT PRIMARY KEY,
    patient_name     VARCHAR(100) NOT NULL,
    hospital_name    VARCHAR(150) NOT NULL,
    requester_phone  VARCHAR(20)  NOT NULL,
    requester_email  VARCHAR(100),
    blood_group      VARCHAR(3)   NOT NULL,
    units_required   INT          NOT NULL,
    city             VARCHAR(60)  NOT NULL,
    urgency_level    ENUM('NORMAL','URGENT','CRITICAL') DEFAULT 'NORMAL' NOT NULL,
    required_by_date DATE         NOT NULL,
    status           ENUM('PENDING','APPROVED','FULFILLED','REJECTED','CANCELLED') DEFAULT 'PENDING' NOT NULL,
    medical_reason   VARCHAR(255),
    admin_remarks    VARCHAR(255),
    requested_at     TIMESTAMP    DEFAULT CURRENT_TIMESTAMP NOT NULL,
    processed_at     TIMESTAMP    NULL,
    processed_by     VARCHAR(50),
    CONSTRAINT fk_my_req_bg FOREIGN KEY (blood_group) REFERENCES blood_groups(blood_group_id)
) ENGINE=InnoDB;

-- Blood Issuances Table
CREATE TABLE blood_issuances (
    issuance_id        INT AUTO_INCREMENT PRIMARY KEY,
    request_id         INT          NOT NULL,
    blood_group_issued VARCHAR(3)   NOT NULL,
    units_issued       INT          NOT NULL,
    issued_at          TIMESTAMP    DEFAULT CURRENT_TIMESTAMP NOT NULL,
    issued_by          VARCHAR(50)  NOT NULL,
    recipient_hospital VARCHAR(150) NOT NULL,
    notes              VARCHAR(255),
    CONSTRAINT fk_my_iss_req FOREIGN KEY (request_id) REFERENCES blood_requests(request_id),
    CONSTRAINT fk_my_iss_bg FOREIGN KEY (blood_group_issued) REFERENCES blood_groups(blood_group_id)
) ENGINE=InnoDB;

-- System Audit Log Table
CREATE TABLE audit_log (
    log_id        INT AUTO_INCREMENT PRIMARY KEY,
    table_name    VARCHAR(50)  NOT NULL,
    action_type   VARCHAR(30)  NOT NULL,
    record_id     VARCHAR(50),
    old_values    TEXT,
    new_values    TEXT,
    log_timestamp TIMESTAMP    DEFAULT CURRENT_TIMESTAMP NOT NULL,
    logged_by     VARCHAR(60)  DEFAULT 'SYSTEM' NOT NULL
) ENGINE=InnoDB;

-- =============================================================================
-- 2. SEED DATA
-- =============================================================================
INSERT INTO blood_groups VALUES
('O-',  'O',  '-', 'None',     'Anti-A, Anti-B', 'Y', 'N', 'Universal RBC Donor'),
('O+',  'O',  '+', 'Rh(D)',    'Anti-A, Anti-B', 'N', 'N', 'Common Donor'),
('A-',  'A',  '-', 'A',        'Anti-B',         'N', 'N', 'Compatible A, AB'),
('A+',  'A',  '+', 'A, Rh(D)', 'Anti-B',         'N', 'N', 'Compatible A+, AB+'),
('B-',  'B',  '-', 'B',        'Anti-A',         'N', 'N', 'Compatible B, AB'),
('B+',  'B',  '+', 'B, Rh(D)', 'Anti-A',         'N', 'N', 'Compatible B+, AB+'),
('AB-', 'AB', '-', 'A, B',     'None',           'N', 'N', 'Compatible AB'),
('AB+', 'AB', '+', 'A, B, Rh', 'None',           'N', 'Y', 'Universal RBC Recipient');

INSERT INTO blood_stock (blood_group, units_available, units_reserved, critical_threshold, low_threshold) VALUES
('O-', 12, 0, 5, 10),
('O+', 35, 2, 8, 15),
('A-',  8, 0, 4,  8),
('A+', 26, 1, 6, 12),
('B-',  6, 0, 4,  8),
('B+', 30, 0, 6, 14),
('AB-', 4, 0, 3,  6),
('AB+', 18, 0, 4,  9);

-- Compatibility Matrix
INSERT INTO blood_compatibility (donor_group, recipient_group, is_compatible, preference_level, notes) VALUES
('O-', 'O-', 'Y', 1, 'Exact Match'), ('O-', 'O+', 'Y', 2, 'Universal'), ('O-', 'A-', 'Y', 2, 'Universal'),
('O-', 'A+', 'Y', 2, 'Universal'),   ('O-', 'B-', 'Y', 2, 'Universal'), ('O-', 'B+', 'Y', 2, 'Universal'),
('O-', 'AB-', 'Y', 2, 'Universal'),  ('O-', 'AB+', 'Y', 2, 'Universal'),
('O+', 'O+', 'Y', 1, 'Exact Match'), ('O+', 'A+', 'Y', 2, 'Rh+ match'), ('O+', 'B+', 'Y', 2, 'Rh+ match'),
('O+', 'AB+', 'Y', 2, 'Rh+ match'),
('A-', 'A-', 'Y', 1, 'Exact Match'), ('A-', 'A+', 'Y', 2, 'Compatible'), ('A-', 'AB-', 'Y', 2, 'Compatible'),
('A-', 'AB+', 'Y', 2, 'Compatible'),
('A+', 'A+', 'Y', 1, 'Exact Match'), ('A+', 'AB+', 'Y', 2, 'Compatible'),
('B-', 'B-', 'Y', 1, 'Exact Match'), ('B-', 'B+', 'Y', 2, 'Compatible'), ('B-', 'AB-', 'Y', 2, 'Compatible'),
('B-', 'AB+', 'Y', 2, 'Compatible'),
('B+', 'B+', 'Y', 1, 'Exact Match'), ('B+', 'AB+', 'Y', 2, 'Compatible'),
('AB-', 'AB-', 'Y', 1, 'Exact Match'),('AB-', 'AB+', 'Y', 2, 'Compatible'),
('AB+', 'AB+', 'Y', 1, 'Exact Match');

-- Seed Donors
INSERT INTO donors (first_name, last_name, email, phone, gender, dob, weight_kg, blood_group, city, address, last_donation_date, total_donations, status) VALUES
('Aman', 'Sharma', 'aman.sharma@example.com', '9876500001', 'M', '1998-05-14', 68.5, 'O+', 'Ludhiana', 'Model Town', '2026-03-10', 3, 'ACTIVE'),
('Simran', 'Kaur', 'simran.kaur@example.com', '9876500002', 'F', '2001-08-20', 56.0, 'B+', 'Ludhiana', 'Sarabha Nagar', '2026-01-12', 1, 'ACTIVE'),
('Rahul', 'Verma', 'rahul.verma@example.com', '9876500003', 'M', '1995-11-05', 74.0, 'A+', 'Chandigarh', 'Sector 17', '2026-09-15', 4, 'ACTIVE'),
('Neha', 'Gupta', 'neha.gupta@example.com', '9876500004', 'F', '1999-02-18', 53.5, 'O-', 'Jalandhar', 'Civil Lines', '2026-02-28', 2, 'ACTIVE'),
('Gurpreet', 'Singh', 'gurpreet.s@example.com', '9876500005', 'M', '1992-06-30', 82.0, 'AB+', 'Amritsar', 'GT Road', '2025-11-20', 5, 'ACTIVE');

-- Seed Requests
INSERT INTO blood_requests (patient_name, hospital_name, requester_phone, requester_email, blood_group, units_required, city, urgency_level, required_by_date, status, medical_reason) VALUES
('Harpreet Singh', 'Civil Hospital Ludhiana', '9812300001', 'harpreet.care@gmail.com', 'B+', 2, 'Ludhiana', 'URGENT', DATE_ADD(CURRENT_DATE, INTERVAL 1 DAY), 'PENDING', 'Cardiac bypass surgery'),
('Rajeshwari Devi', 'Dayanand Medical College', '9812300002', 'dmc.icu@dmch.edu', 'O-', 1, 'Ludhiana', 'CRITICAL', CURRENT_DATE, 'PENDING', 'Emergency trauma');

-- =============================================================================
-- 3. STORED FUNCTIONS
-- =============================================================================
DELIMITER //

-- Function: Calculate Age
CREATE FUNCTION fn_calculate_age(p_dob DATE) 
RETURNS INT DETERMINISTIC
BEGIN
    IF p_dob IS NULL THEN
        RETURN 0;
    END IF;
    RETURN TIMESTAMPDIFF(YEAR, p_dob, CURDATE());
END //

-- Function: Check Donor Eligibility
CREATE FUNCTION fn_check_donor_eligibility(p_donor_id INT, p_check_date DATE)
RETURNS VARCHAR(255) READS SQL DATA
BEGIN
    DECLARE v_dob DATE;
    DECLARE v_weight DECIMAL(4,1);
    DECLARE v_status VARCHAR(20);
    DECLARE v_last_donation DATE;
    DECLARE v_age INT;
    DECLARE v_days_diff INT;

    SELECT dob, weight_kg, status, last_donation_date
      INTO v_dob, v_weight, v_status, v_last_donation
      FROM donors
     WHERE donor_id = p_donor_id;

    IF v_status IS NULL THEN
        RETURN 'INELIGIBLE: Donor ID does not exist';
    END IF;

    IF v_status != 'ACTIVE' THEN
        RETURN CONCAT('INELIGIBLE: Donor status is ', v_status);
    END IF;

    SET v_age = TIMESTAMPDIFF(YEAR, v_dob, CURDATE());
    IF v_age < 18 THEN
        RETURN CONCAT('INELIGIBLE: Underage donor (', v_age, ' yrs). Minimum age is 18.');
    ELSEIF v_age > 65 THEN
        RETURN CONCAT('INELIGIBLE: Overage donor (', v_age, ' yrs). Maximum age is 65.');
    END IF;

    IF v_weight < 45.0 THEN
        RETURN CONCAT('INELIGIBLE: Weight (', v_weight, ' kg) is below 45 kg minimum.');
    END IF;

    IF v_last_donation IS NOT NULL THEN
        SET v_days_diff = DATEDIFF(p_check_date, v_last_donation);
        IF v_days_diff < 90 THEN
            RETURN CONCAT('INELIGIBLE: 90-day cooldown active. Donated ', v_days_diff, ' days ago.');
        END IF;
    END IF;

    RETURN 'ELIGIBLE';
END //

-- Function: Biological Compatibility Check
CREATE FUNCTION fn_is_blood_compatible(p_donor_group VARCHAR(3), p_recipient_group VARCHAR(3))
RETURNS TINYINT READS SQL DATA
BEGIN
    DECLARE v_cnt INT;
    SELECT COUNT(*) INTO v_cnt
      FROM blood_compatibility
     WHERE UPPER(donor_group) = UPPER(TRIM(p_donor_group))
       AND UPPER(recipient_group) = UPPER(TRIM(p_recipient_group))
       AND is_compatible = 'Y';
    IF v_cnt > 0 THEN
        RETURN 1;
    ELSE
        RETURN 0;
    END IF;
END //

-- Function: Stock Status Label
CREATE FUNCTION fn_get_stock_status(p_blood_group VARCHAR(3))
RETURNS VARCHAR(20) READS SQL DATA
BEGIN
    DECLARE v_avail, v_crit, v_low INT;
    SELECT units_available, critical_threshold, low_threshold
      INTO v_avail, v_crit, v_low
      FROM blood_stock
     WHERE blood_group = UPPER(TRIM(p_blood_group));

    IF v_avail <= v_crit THEN
        RETURN 'CRITICAL';
    ELSEIF v_avail <= v_low THEN
        RETURN 'LOW';
    ELSE
        RETURN 'SUFFICIENT';
    END IF;
END //

-- Function: Compatible Stock Total
CREATE FUNCTION fn_get_compatible_stock(p_recipient_group VARCHAR(3))
RETURNS INT READS SQL DATA
BEGIN
    DECLARE v_total INT;
    SELECT IFNULL(SUM(s.units_available), 0) INTO v_total
      FROM blood_stock s
      JOIN blood_compatibility c ON s.blood_group = c.donor_group
     WHERE c.recipient_group = UPPER(TRIM(p_recipient_group))
       AND c.is_compatible = 'Y';
    RETURN v_total;
END //

-- =============================================================================
-- 4. STORED PROCEDURES
-- =============================================================================

-- Procedure: Register Donor
CREATE PROCEDURE sp_register_donor(
    IN  p_first_name  VARCHAR(50),
    IN  p_last_name   VARCHAR(50),
    IN  p_email       VARCHAR(100),
    IN  p_phone       VARCHAR(20),
    IN  p_gender      CHAR(1),
    IN  p_dob         DATE,
    IN  p_weight_kg   DECIMAL(4,1),
    IN  p_blood_group VARCHAR(3),
    IN  p_city        VARCHAR(60),
    IN  p_address     VARCHAR(200),
    OUT o_donor_id    INT,
    OUT o_status_msg  VARCHAR(255)
)
BEGIN
    DECLARE v_age INT;
    DECLARE v_bg_cnt INT;

    SELECT COUNT(*) INTO v_bg_cnt FROM blood_groups WHERE blood_group_id = UPPER(TRIM(p_blood_group));
    IF v_bg_cnt = 0 THEN
        SET o_donor_id = NULL;
        SET o_status_msg = CONCAT('FAILED: Invalid blood group ', p_blood_group);
    ELSE
        SET v_age = TIMESTAMPDIFF(YEAR, p_dob, CURDATE());
        IF v_age < 18 OR v_age > 65 THEN
            SET o_donor_id = NULL;
            SET o_status_msg = CONCAT('FAILED: Donor age (', v_age, ') must be between 18 and 65.');
        ELSEIF p_weight_kg < 45.0 THEN
            SET o_donor_id = NULL;
            SET o_status_msg = CONCAT('FAILED: Donor weight (', p_weight_kg, ' kg) must be >= 45 kg.');
        ELSE
            INSERT INTO donors (first_name, last_name, email, phone, gender, dob, weight_kg, blood_group, city, address)
            VALUES (TRIM(p_first_name), TRIM(p_last_name), LOWER(TRIM(p_email)), TRIM(p_phone), UPPER(p_gender), p_dob, p_weight_kg, UPPER(p_blood_group), TRIM(p_city), p_address);

            SET o_donor_id = LAST_INSERT_ID();
            SET o_status_msg = CONCAT('SUCCESS: Registered donor with ID: ', o_donor_id);

            INSERT INTO audit_log (table_name, action_type, record_id, new_values, logged_by)
            VALUES ('DONORS', 'INSERT', o_donor_id, CONCAT('Name=', p_first_name, ' ', p_last_name, '; Group=', p_blood_group), USER());
        END IF;
    END IF;
END //

-- Procedure: Record Donation
CREATE PROCEDURE sp_record_donation(
    IN  p_donor_id    INT,
    IN  p_units       INT,
    IN  p_donation_dt DATE,
    IN  p_hb          DECIMAL(4,1),
    IN  p_camp        VARCHAR(100),
    OUT o_donation_id INT,
    OUT o_result_msg  VARCHAR(255)
)
BEGIN
    DECLARE v_eligibility VARCHAR(255);
    DECLARE v_bg VARCHAR(3);
    DECLARE v_dt DATE;

    SET v_dt = IFNULL(p_donation_dt, CURDATE());
    SET v_eligibility = fn_check_donor_eligibility(p_donor_id, v_dt);

    IF v_eligibility != 'ELIGIBLE' THEN
        SET o_donation_id = NULL;
        SET o_result_msg = CONCAT('REJECTED: ', v_eligibility);
    ELSE
        SELECT blood_group INTO v_bg FROM donors WHERE donor_id = p_donor_id;

        INSERT INTO donations (donor_id, blood_group, units_donated, donation_date, hemoglobin_g_dl, camp_or_facility)
        VALUES (p_donor_id, v_bg, IFNULL(p_units, 1), v_dt, p_hb, IFNULL(p_camp, 'Central Blood Bank'));

        SET o_donation_id = LAST_INSERT_ID();

        -- Update donor profile
        UPDATE donors 
           SET last_donation_date = v_dt,
               total_donations = total_donations + IFNULL(p_units, 1)
         WHERE donor_id = p_donor_id;

        -- Automatically increment blood stock
        UPDATE blood_stock
           SET units_available = units_available + IFNULL(p_units, 1)
         WHERE blood_group = v_bg;

        INSERT INTO audit_log (table_name, action_type, record_id, new_values, logged_by)
        VALUES ('DONATIONS', 'INSERT', o_donation_id, CONCAT('Donor=', p_donor_id, '; Group=', v_bg, '; Units=', IFNULL(p_units,1)), USER());

        SET o_result_msg = CONCAT('SUCCESS: Donation recorded (ID: ', o_donation_id, '). Stock for ', v_bg, ' incremented.');
    END IF;
END //

-- Procedure: Process & Fulfill Blood Request
CREATE PROCEDURE sp_process_blood_request(
    IN  p_request_id INT,
    IN  p_action     VARCHAR(20),
    IN  p_admin_user VARCHAR(50),
    IN  p_remarks    VARCHAR(255),
    OUT o_code       VARCHAR(50),
    OUT o_msg        VARCHAR(255)
)
proc_block: BEGIN
    DECLARE v_bg VARCHAR(3);
    DECLARE v_units_req INT;
    DECLARE v_status VARCHAR(20);
    DECLARE v_hosp VARCHAR(150);
    DECLARE v_avail INT;

    SELECT blood_group, units_required, status, hospital_name
      INTO v_bg, v_units_req, v_status, v_hosp
      FROM blood_requests
     WHERE request_id = p_request_id;

    IF v_status IS NULL THEN
        SET o_code = 'NOT_FOUND';
        SET o_msg = CONCAT('Request #', p_request_id, ' not found.');
        LEAVE proc_block;
    END IF;

    IF v_status IN ('FULFILLED', 'REJECTED', 'CANCELLED') THEN
        SET o_code = 'INVALID_STATE';
        SET o_msg = CONCAT('Request #', p_request_id, ' is already ', v_status);
        LEAVE proc_block;
    END IF;

    IF UPPER(p_action) = 'REJECT' THEN
        UPDATE blood_requests
           SET status = 'REJECTED', admin_remarks = p_remarks, processed_at = NOW(), processed_by = p_admin_user
         WHERE request_id = p_request_id;
        SET o_code = 'SUCCESS';
        SET o_msg = CONCAT('Request #', p_request_id, ' marked REJECTED.');

    ELSEIF UPPER(p_action) = 'FULFILL' THEN
        SELECT units_available INTO v_avail FROM blood_stock WHERE blood_group = v_bg;

        IF v_avail < v_units_req THEN
            SET o_code = 'INSUFFICIENT_STOCK';
            SET o_msg = CONCAT('Insufficient stock for ', v_bg, '. Required: ', v_units_req, ', Available: ', v_avail);
        ELSE
            -- Deduct stock
            UPDATE blood_stock
               SET units_available = units_available - v_units_req
             WHERE blood_group = v_bg;

            -- Record issuance
            INSERT INTO blood_issuances (request_id, blood_group_issued, units_issued, issued_by, recipient_hospital, notes)
            VALUES (p_request_id, v_bg, v_units_req, p_admin_user, v_hosp, p_remarks);

            -- Update request
            UPDATE blood_requests
               SET status = 'FULFILLED', admin_remarks = p_remarks, processed_at = NOW(), processed_by = p_admin_user
             WHERE request_id = p_request_id;

            INSERT INTO audit_log (table_name, action_type, record_id, new_values, logged_by)
            VALUES ('BLOOD_REQUESTS', 'FULFILL', p_request_id, CONCAT('Group=', v_bg, '; Units=', v_units_req), p_admin_user);

            SET o_code = 'SUCCESS';
            SET o_msg = CONCAT('Request #', p_request_id, ' FULFILLED. Dispensed ', v_units_req, ' unit(s) of ', v_bg);
        END IF;
    ELSE
        SET o_code = 'INVALID_ACTION';
        SET o_msg = 'Action must be FULFILL or REJECT';
    END IF;
END //

-- Procedure: Stock Inventory Report
CREATE PROCEDURE sp_stock_inventory_report()
BEGIN
    SELECT s.blood_group,
           s.units_available,
           s.units_reserved,
           s.critical_threshold,
           fn_get_stock_status(s.blood_group) AS health_category,
           fn_get_compatible_stock(s.blood_group) AS total_compatible_pool,
           s.last_updated
      FROM blood_stock s
     ORDER BY s.units_available ASC;
END //

-- Procedure: Emergency Requests Queue
CREATE PROCEDURE sp_emergency_requests_queue()
BEGIN
    SELECT r.request_id,
           r.patient_name,
           r.hospital_name,
           r.blood_group,
           r.units_required,
           r.urgency_level,
           r.status,
           s.units_available,
           IF(s.units_available >= r.units_required, 'READY TO DISPENSE', 'DEFICIT') AS readiness
      FROM blood_requests r
      JOIN blood_stock s ON r.blood_group = s.blood_group
     WHERE r.status IN ('PENDING', 'APPROVED')
     ORDER BY FIELD(r.urgency_level, 'CRITICAL', 'URGENT', 'NORMAL'), r.required_by_date ASC;
END //

DELIMITER ;

-- =============================================================================
-- 5. DATABASE TRIGGERS
-- =============================================================================
DELIMITER //

-- Trigger: Prevent Negative Stock
CREATE TRIGGER trg_my_prevent_negative_stock
BEFORE UPDATE ON blood_stock
FOR EACH ROW
BEGIN
    IF NEW.units_available < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'NEGATIVE_STOCK_ERROR: Available blood units cannot be negative.';
    END IF;
END //

-- Trigger: Audit Stock Changes
CREATE TRIGGER trg_my_audit_stock
AFTER UPDATE ON blood_stock
FOR EACH ROW
BEGIN
    IF OLD.units_available != NEW.units_available THEN
        INSERT INTO audit_log (table_name, action_type, record_id, old_values, new_values, logged_by)
        VALUES (
            'BLOOD_STOCK', 'UPDATE', NEW.blood_group,
            CONCAT('Units=', OLD.units_available),
            CONCAT('Units=', NEW.units_available),
            USER()
        );
    END IF;
END //

DELIMITER ;
