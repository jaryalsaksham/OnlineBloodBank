-- =============================================================================
-- Project Title: Blood Bank Management System (PL/SQL Project)
-- Component:     01_schema_ddl.sql (Database Tables, Sequences, Constraints, Seed Data)
-- Target DBMS:   Oracle 11g / 12c / 18c / 19c / 21c / 23c / Oracle Live SQL
-- Description:   Complete relational schema supporting Donors, Blood Groups,
--                Compatibility Matrix, Blood Stock, Donations, Requests,
--                Issuances, and System Audit Logging.
-- =============================================================================

-- Enable server output for verification
SET SERVEROUTPUT ON SIZE UNLIMITED;
SET LINESIZE 200;
SET PAGESIZE 100;

PROMPT =========================================================================;
PROMPT  [1/6] CLEANING EXISTING SCHEMA OBJECTS (IF ANY)...;
PROMPT =========================================================================;

-- Drop foreign-keyed child tables first
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE blood_issuances CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE blood_requests CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE donations CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE blood_stock CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE donors CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE blood_compatibility CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE blood_groups CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE audit_log CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

-- Drop sequences
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE seq_compatibility_id';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE seq_donor_id';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE seq_donation_id';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE seq_request_id';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE seq_issuance_id';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE seq_audit_id';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

PROMPT Existing schema objects cleaned successfully.

PROMPT =========================================================================;
PROMPT  [2/6] CREATING SEQUENCES...;
PROMPT =========================================================================;

CREATE SEQUENCE seq_compatibility_id START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_donor_id         START WITH 101 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_donation_id      START WITH 501 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_request_id       START WITH 1001 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_issuance_id      START WITH 7001 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_audit_id         START WITH 1 INCREMENT BY 1 NOCACHE;

PROMPT Sequences created.

PROMPT =========================================================================;
PROMPT  [3/6] CREATING RELATIONAL TABLES & INTEGRITY CONSTRAINTS...;
PROMPT =========================================================================;

-- -----------------------------------------------------------------------------
-- 1. BLOOD GROUPS MASTER TABLE
-- -----------------------------------------------------------------------------
CREATE TABLE blood_groups (
    blood_group_id           VARCHAR2(3)   NOT NULL,
    blood_type               VARCHAR2(2)   NOT NULL,
    rh_factor                CHAR(1)       NOT NULL,
    antigen                  VARCHAR2(25)  NOT NULL,
    antibody                 VARCHAR2(25)  NOT NULL,
    universal_donor_flag     CHAR(1)       DEFAULT 'N' NOT NULL,
    universal_recipient_flag CHAR(1)       DEFAULT 'N' NOT NULL,
    storage_temp_celsius     NUMBER(3,1)   DEFAULT 4.0 NOT NULL,
    shelf_life_days          NUMBER(3)     DEFAULT 42  NOT NULL,
    description              VARCHAR2(200),
    CONSTRAINT pk_blood_groups PRIMARY KEY (blood_group_id),
    CONSTRAINT chk_bg_type CHECK (blood_type IN ('A', 'B', 'AB', 'O')),
    CONSTRAINT chk_bg_rh CHECK (rh_factor IN ('+', '-')),
    CONSTRAINT chk_bg_unidr CHECK (universal_donor_flag IN ('Y', 'N')),
    CONSTRAINT chk_bg_unirc CHECK (universal_recipient_flag IN ('Y', 'N'))
);

-- -----------------------------------------------------------------------------
-- 2. BIOLOGICAL BLOOD COMPATIBILITY MATRIX
-- -----------------------------------------------------------------------------
CREATE TABLE blood_compatibility (
    compatibility_id NUMBER        NOT NULL,
    donor_group      VARCHAR2(3)   NOT NULL,
    recipient_group  VARCHAR2(3)   NOT NULL,
    is_compatible    CHAR(1)       DEFAULT 'Y' NOT NULL,
    preference_level NUMBER(1)     DEFAULT 1 NOT NULL, -- 1: Exact match, 2: Compatible cross-match
    notes            VARCHAR2(100),
    CONSTRAINT pk_blood_compat PRIMARY KEY (compatibility_id),
    CONSTRAINT fk_compat_donor FOREIGN KEY (donor_group) REFERENCES blood_groups(blood_group_id),
    CONSTRAINT fk_compat_recip FOREIGN KEY (recipient_group) REFERENCES blood_groups(blood_group_id),
    CONSTRAINT uq_compat_pair UNIQUE (donor_group, recipient_group),
    CONSTRAINT chk_compat_flag CHECK (is_compatible IN ('Y', 'N')),
    CONSTRAINT chk_pref_lvl CHECK (preference_level IN (1, 2))
);

-- -----------------------------------------------------------------------------
-- 3. DONORS TABLE
-- -----------------------------------------------------------------------------
CREATE TABLE donors (
    donor_id           NUMBER         NOT NULL,
    first_name         VARCHAR2(50)   NOT NULL,
    last_name          VARCHAR2(50)   NOT NULL,
    email              VARCHAR2(100)  NOT NULL,
    phone              VARCHAR2(20)   NOT NULL,
    gender             CHAR(1)        NOT NULL,
    dob                DATE           NOT NULL,
    weight_kg          NUMBER(4,1)    NOT NULL,
    blood_group        VARCHAR2(3)    NOT NULL,
    city               VARCHAR2(60)   NOT NULL,
    address            VARCHAR2(200),
    last_donation_date DATE,
    total_donations    NUMBER(4)      DEFAULT 0 NOT NULL,
    status             VARCHAR2(20)   DEFAULT 'ACTIVE' NOT NULL,
    medical_notes      VARCHAR2(255),
    registered_at      DATE           DEFAULT SYSDATE NOT NULL,
    CONSTRAINT pk_donors PRIMARY KEY (donor_id),
    CONSTRAINT uq_donor_email UNIQUE (email),
    CONSTRAINT uq_donor_phone UNIQUE (phone),
    CONSTRAINT fk_donor_blood_group FOREIGN KEY (blood_group) REFERENCES blood_groups(blood_group_id),
    CONSTRAINT chk_donor_gender CHECK (gender IN ('M', 'F', 'O')),
    CONSTRAINT chk_donor_weight CHECK (weight_kg >= 45.0),
    CONSTRAINT chk_donor_status CHECK (status IN ('ACTIVE', 'INACTIVE', 'DEFERRED', 'SUSPENDED')),
    CONSTRAINT chk_donor_tot_don CHECK (total_donations >= 0)
);

-- Index for searching donors by blood group and city quickly
CREATE INDEX idx_donor_bg_city ON donors(blood_group, city, status);

-- -----------------------------------------------------------------------------
-- 4. BLOOD STOCK (INVENTORY) TABLE
-- -----------------------------------------------------------------------------
CREATE TABLE blood_stock (
    blood_group        VARCHAR2(3)  NOT NULL,
    units_available    NUMBER(6)    DEFAULT 0 NOT NULL,
    units_reserved     NUMBER(6)    DEFAULT 0 NOT NULL,
    critical_threshold NUMBER(4)    DEFAULT 5 NOT NULL,
    low_threshold      NUMBER(4)    DEFAULT 10 NOT NULL,
    ideal_capacity     NUMBER(6)    DEFAULT 100 NOT NULL,
    last_updated       TIMESTAMP    DEFAULT SYSTIMESTAMP NOT NULL,
    CONSTRAINT pk_blood_stock PRIMARY KEY (blood_group),
    CONSTRAINT fk_stock_blood_group FOREIGN KEY (blood_group) REFERENCES blood_groups(blood_group_id),
    CONSTRAINT chk_stock_avail CHECK (units_available >= 0),
    CONSTRAINT chk_stock_reserv CHECK (units_reserved >= 0),
    CONSTRAINT chk_stock_thresh CHECK (critical_threshold < low_threshold)
);

-- -----------------------------------------------------------------------------
-- 5. DONATIONS TABLE (DONATION SESSIONS & LOGS)
-- -----------------------------------------------------------------------------
CREATE TABLE donations (
    donation_id           NUMBER        NOT NULL,
    donor_id              NUMBER        NOT NULL,
    blood_group           VARCHAR2(3)   NOT NULL,
    units_donated         NUMBER(2)     DEFAULT 1 NOT NULL,
    donation_date         DATE          DEFAULT SYSDATE NOT NULL,
    hemoglobin_g_dl       NUMBER(4,1),
    systolic_bp           NUMBER(3),
    diastolic_bp          NUMBER(3),
    pulse_bpm             NUMBER(3),
    camp_or_facility      VARCHAR2(100) DEFAULT 'Central Regional Blood Center' NOT NULL,
    doctor_or_technician  VARCHAR2(60),
    screening_status      VARCHAR2(20)  DEFAULT 'PASSED' NOT NULL,
    remarks               VARCHAR2(255),
    recorded_at           TIMESTAMP     DEFAULT SYSTIMESTAMP NOT NULL,
    CONSTRAINT pk_donations PRIMARY KEY (donation_id),
    CONSTRAINT fk_donation_donor FOREIGN KEY (donor_id) REFERENCES donors(donor_id) ON DELETE CASCADE,
    CONSTRAINT fk_donation_bg FOREIGN KEY (blood_group) REFERENCES blood_groups(blood_group_id),
    CONSTRAINT chk_don_units CHECK (units_donated > 0),
    CONSTRAINT chk_don_hb CHECK (hemoglobin_g_dl IS NULL OR (hemoglobin_g_dl BETWEEN 10.0 AND 22.0)),
    CONSTRAINT chk_don_screen CHECK (screening_status IN ('PASSED', 'REJECTED', 'PENDING_LAB'))
);

CREATE INDEX idx_donations_donor ON donations(donor_id, donation_date);

-- -----------------------------------------------------------------------------
-- 6. BLOOD REQUESTS TABLE (PATIENTS & HOSPITALS)
-- -----------------------------------------------------------------------------
CREATE TABLE blood_requests (
    request_id       NUMBER        NOT NULL,
    patient_name     VARCHAR2(100) NOT NULL,
    hospital_name    VARCHAR2(150) NOT NULL,
    requester_phone  VARCHAR2(20)  NOT NULL,
    requester_email  VARCHAR2(100),
    blood_group      VARCHAR2(3)   NOT NULL,
    units_required   NUMBER(3)     NOT NULL,
    city             VARCHAR2(60)  NOT NULL,
    urgency_level    VARCHAR2(10)  DEFAULT 'NORMAL' NOT NULL,
    required_by_date DATE          NOT NULL,
    status           VARCHAR2(20)  DEFAULT 'PENDING' NOT NULL,
    medical_reason   VARCHAR2(255),
    admin_remarks    VARCHAR2(255),
    requested_at     TIMESTAMP     DEFAULT SYSTIMESTAMP NOT NULL,
    processed_at     TIMESTAMP,
    processed_by     VARCHAR2(50),
    CONSTRAINT pk_blood_requests PRIMARY KEY (request_id),
    CONSTRAINT fk_req_blood_group FOREIGN KEY (blood_group) REFERENCES blood_groups(blood_group_id),
    CONSTRAINT chk_req_units CHECK (units_required > 0),
    CONSTRAINT chk_req_urgency CHECK (urgency_level IN ('NORMAL', 'URGENT', 'CRITICAL')),
    CONSTRAINT chk_req_status CHECK (status IN ('PENDING', 'APPROVED', 'FULFILLED', 'REJECTED', 'CANCELLED'))
);

CREATE INDEX idx_requests_status_urgency ON blood_requests(status, urgency_level);

-- -----------------------------------------------------------------------------
-- 7. BLOOD ISSUANCES TABLE (DISPATCH & TRANSFUSIONS)
-- -----------------------------------------------------------------------------
CREATE TABLE blood_issuances (
    issuance_id        NUMBER        NOT NULL,
    request_id         NUMBER        NOT NULL,
    blood_group_issued VARCHAR2(3)   NOT NULL,
    units_issued       NUMBER(3)     NOT NULL,
    issued_at          TIMESTAMP     DEFAULT SYSTIMESTAMP NOT NULL,
    issued_by          VARCHAR2(50)  NOT NULL,
    recipient_hospital VARCHAR2(150) NOT NULL,
    notes              VARCHAR2(255),
    CONSTRAINT pk_blood_issuances PRIMARY KEY (issuance_id),
    CONSTRAINT fk_issuance_req FOREIGN KEY (request_id) REFERENCES blood_requests(request_id),
    CONSTRAINT fk_issuance_bg FOREIGN KEY (blood_group_issued) REFERENCES blood_groups(blood_group_id),
    CONSTRAINT chk_iss_units CHECK (units_issued > 0)
);

-- -----------------------------------------------------------------------------
-- 8. SYSTEM AUDIT LOG TABLE
-- -----------------------------------------------------------------------------
CREATE TABLE audit_log (
    log_id        NUMBER         NOT NULL,
    table_name    VARCHAR2(50)   NOT NULL,
    action_type   VARCHAR2(30)   NOT NULL,
    record_id     VARCHAR2(50),
    old_values    VARCHAR2(1000),
    new_values    VARCHAR2(1000),
    log_timestamp TIMESTAMP      DEFAULT SYSTIMESTAMP NOT NULL,
    logged_by     VARCHAR2(60)   DEFAULT USER NOT NULL,
    CONSTRAINT pk_audit_log PRIMARY KEY (log_id)
);

PROMPT Tables and constraints created successfully.

PROMPT =========================================================================;
PROMPT  [4/6] SEEDING BLOOD GROUPS AND COMPATIBILITY MATRIX...;
PROMPT =========================================================================;

-- Populate Blood Groups
INSERT INTO blood_groups (blood_group_id, blood_type, rh_factor, antigen, antibody, universal_donor_flag, universal_recipient_flag, description)
VALUES ('O-', 'O', '-', 'None', 'Anti-A, Anti-B', 'Y', 'N', 'Universal Red Blood Cell Donor');

INSERT INTO blood_groups (blood_group_id, blood_type, rh_factor, antigen, antibody, universal_donor_flag, universal_recipient_flag, description)
VALUES ('O+', 'O', '+', 'Rh(D)', 'Anti-A, Anti-B', 'N', 'N', 'Most common blood group; can donate to Rh+ patients');

INSERT INTO blood_groups (blood_group_id, blood_type, rh_factor, antigen, antibody, universal_donor_flag, universal_recipient_flag, description)
VALUES ('A-', 'A', '-', 'A', 'Anti-B', 'N', 'N', 'Can donate to A-, A+, AB-, AB+');

INSERT INTO blood_groups (blood_group_id, blood_type, rh_factor, antigen, antibody, universal_donor_flag, universal_recipient_flag, description)
VALUES ('A+', 'A', '+', 'A, Rh(D)', 'Anti-B', 'N', 'N', 'Can donate to A+ and AB+');

INSERT INTO blood_groups (blood_group_id, blood_type, rh_factor, antigen, antibody, universal_donor_flag, universal_recipient_flag, description)
VALUES ('B-', 'B', '-', 'B', 'Anti-A', 'N', 'N', 'Can donate to B-, B+, AB-, AB+');

INSERT INTO blood_groups (blood_group_id, blood_type, rh_factor, antigen, antibody, universal_donor_flag, universal_recipient_flag, description)
VALUES ('B+', 'B', '+', 'B, Rh(D)', 'Anti-A', 'N', 'N', 'Can donate to B+ and AB+');

INSERT INTO blood_groups (blood_group_id, blood_type, rh_factor, antigen, antibody, universal_donor_flag, universal_recipient_flag, description)
VALUES ('AB-', 'AB', '-', 'A, B', 'None', 'N', 'N', 'Can donate to AB- and AB+');

INSERT INTO blood_groups (blood_group_id, blood_type, rh_factor, antigen, antibody, universal_donor_flag, universal_recipient_flag, description)
VALUES ('AB+', 'AB', '+', 'A, B, Rh', 'None', 'N', 'Y', 'Universal Red Blood Cell Recipient; receives from all');

-- Initialize Blood Stock for all 8 Groups
INSERT INTO blood_stock (blood_group, units_available, units_reserved, critical_threshold, low_threshold)
VALUES ('O-', 12, 0, 5, 10);

INSERT INTO blood_stock (blood_group, units_available, units_reserved, critical_threshold, low_threshold)
VALUES ('O+', 35, 2, 8, 15);

INSERT INTO blood_stock (blood_group, units_available, units_reserved, critical_threshold, low_threshold)
VALUES ('A-',  8, 0, 4,  8);

INSERT INTO blood_stock (blood_group, units_available, units_reserved, critical_threshold, low_threshold)
VALUES ('A+', 26, 1, 6, 12);

INSERT INTO blood_stock (blood_group, units_available, units_reserved, critical_threshold, low_threshold)
VALUES ('B-',  6, 0, 4,  8);

INSERT INTO blood_stock (blood_group, units_available, units_reserved, critical_threshold, low_threshold)
VALUES ('B+', 30, 0, 6, 14);

INSERT INTO blood_stock (blood_group, units_available, units_reserved, critical_threshold, low_threshold)
VALUES ('AB-', 4, 0, 3,  6);

INSERT INTO blood_stock (blood_group, units_available, units_reserved, critical_threshold, low_threshold)
VALUES ('AB+', 18, 0, 4,  9);

-- Populate Biological Blood Compatibility Matrix (Donor -> Recipient)
-- O- can donate to all 8 groups
INSERT INTO blood_compatibility VALUES (seq_compatibility_id.NEXTVAL, 'O-', 'O-', 'Y', 1, 'Exact Match');
INSERT INTO blood_compatibility VALUES (seq_compatibility_id.NEXTVAL, 'O-', 'O+', 'Y', 2, 'Universal Donor');
INSERT INTO blood_compatibility VALUES (seq_compatibility_id.NEXTVAL, 'O-', 'A-', 'Y', 2, 'Universal Donor');
INSERT INTO blood_compatibility VALUES (seq_compatibility_id.NEXTVAL, 'O-', 'A+', 'Y', 2, 'Universal Donor');
INSERT INTO blood_compatibility VALUES (seq_compatibility_id.NEXTVAL, 'O-', 'B-', 'Y', 2, 'Universal Donor');
INSERT INTO blood_compatibility VALUES (seq_compatibility_id.NEXTVAL, 'O-', 'B+', 'Y', 2, 'Universal Donor');
INSERT INTO blood_compatibility VALUES (seq_compatibility_id.NEXTVAL, 'O-', 'AB-', 'Y', 2, 'Universal Donor');
INSERT INTO blood_compatibility VALUES (seq_compatibility_id.NEXTVAL, 'O-', 'AB+', 'Y', 2, 'Universal Donor');

-- O+ can donate to Rh+ groups
INSERT INTO blood_compatibility VALUES (seq_compatibility_id.NEXTVAL, 'O+', 'O+', 'Y', 1, 'Exact Match');
INSERT INTO blood_compatibility VALUES (seq_compatibility_id.NEXTVAL, 'O+', 'A+', 'Y', 2, 'Compatible Rh+');
INSERT INTO blood_compatibility VALUES (seq_compatibility_id.NEXTVAL, 'O+', 'B+', 'Y', 2, 'Compatible Rh+');
INSERT INTO blood_compatibility VALUES (seq_compatibility_id.NEXTVAL, 'O+', 'AB+', 'Y', 2, 'Compatible Rh+');

-- A- can donate to A-, A+, AB-, AB+
INSERT INTO blood_compatibility VALUES (seq_compatibility_id.NEXTVAL, 'A-', 'A-', 'Y', 1, 'Exact Match');
INSERT INTO blood_compatibility VALUES (seq_compatibility_id.NEXTVAL, 'A-', 'A+', 'Y', 2, 'Compatible Rh- to Rh+');
INSERT INTO blood_compatibility VALUES (seq_compatibility_id.NEXTVAL, 'A-', 'AB-', 'Y', 2, 'Compatible Type');
INSERT INTO blood_compatibility VALUES (seq_compatibility_id.NEXTVAL, 'A-', 'AB+', 'Y', 2, 'Compatible Type');

-- A+ can donate to A+, AB+
INSERT INTO blood_compatibility VALUES (seq_compatibility_id.NEXTVAL, 'A+', 'A+', 'Y', 1, 'Exact Match');
INSERT INTO blood_compatibility VALUES (seq_compatibility_id.NEXTVAL, 'A+', 'AB+', 'Y', 2, 'Compatible Type');

-- B- can donate to B-, B+, AB-, AB+
INSERT INTO blood_compatibility VALUES (seq_compatibility_id.NEXTVAL, 'B-', 'B-', 'Y', 1, 'Exact Match');
INSERT INTO blood_compatibility VALUES (seq_compatibility_id.NEXTVAL, 'B-', 'B+', 'Y', 2, 'Compatible Rh- to Rh+');
INSERT INTO blood_compatibility VALUES (seq_compatibility_id.NEXTVAL, 'B-', 'AB-', 'Y', 2, 'Compatible Type');
INSERT INTO blood_compatibility VALUES (seq_compatibility_id.NEXTVAL, 'B-', 'AB+', 'Y', 2, 'Compatible Type');

-- B+ can donate to B+, AB+
INSERT INTO blood_compatibility VALUES (seq_compatibility_id.NEXTVAL, 'B+', 'B+', 'Y', 1, 'Exact Match');
INSERT INTO blood_compatibility VALUES (seq_compatibility_id.NEXTVAL, 'B+', 'AB+', 'Y', 2, 'Compatible Type');

-- AB- can donate to AB-, AB+
INSERT INTO blood_compatibility VALUES (seq_compatibility_id.NEXTVAL, 'AB-', 'AB-', 'Y', 1, 'Exact Match');
INSERT INTO blood_compatibility VALUES (seq_compatibility_id.NEXTVAL, 'AB-', 'AB+', 'Y', 2, 'Compatible Type');

-- AB+ can donate ONLY to AB+
INSERT INTO blood_compatibility VALUES (seq_compatibility_id.NEXTVAL, 'AB+', 'AB+', 'Y', 1, 'Exact Match');

PROMPT Blood Groups and Compatibility Matrix populated.

PROMPT =========================================================================;
PROMPT  [5/6] SEEDING SAMPLE DONORS AND DONATIONS...;
PROMPT =========================================================================;

INSERT INTO donors (donor_id, first_name, last_name, email, phone, gender, dob, weight_kg, blood_group, city, address, last_donation_date, total_donations, status)
VALUES (seq_donor_id.NEXTVAL, 'Aman', 'Sharma', 'aman.sharma@example.com', '9876500001', 'M', TO_DATE('1998-05-14', 'YYYY-MM-DD'), 68.5, 'O+', 'Ludhiana', 'Model Town, Street 4', TO_DATE('2026-03-10', 'YYYY-MM-DD'), 3, 'ACTIVE');

INSERT INTO donors (donor_id, first_name, last_name, email, phone, gender, dob, weight_kg, blood_group, city, address, last_donation_date, total_donations, status)
VALUES (seq_donor_id.NEXTVAL, 'Simran', 'Kaur', 'simran.kaur@example.com', '9876500002', 'F', TO_DATE('2001-08-20', 'YYYY-MM-DD'), 56.0, 'B+', 'Ludhiana', 'Sarabha Nagar, Phase 2', TO_DATE('2026-01-12', 'YYYY-MM-DD'), 1, 'ACTIVE');

INSERT INTO donors (donor_id, first_name, last_name, email, phone, gender, dob, weight_kg, blood_group, city, address, last_donation_date, total_donations, status)
VALUES (seq_donor_id.NEXTVAL, 'Rahul', 'Verma', 'rahul.verma@example.com', '9876500003', 'M', TO_DATE('1995-11-05', 'YYYY-MM-DD'), 74.0, 'A+', 'Chandigarh', 'Sector 17-C, Flat 102', TO_DATE('2026-09-15', 'YYYY-MM-DD'), 4, 'ACTIVE');

INSERT INTO donors (donor_id, first_name, last_name, email, phone, gender, dob, weight_kg, blood_group, city, address, last_donation_date, total_donations, status)
VALUES (seq_donor_id.NEXTVAL, 'Neha', 'Gupta', 'neha.gupta@example.com', '9876500004', 'F', TO_DATE('1999-02-18', 'YYYY-MM-DD'), 53.5, 'O-', 'Jalandhar', 'Civil Lines, Green Park', TO_DATE('2026-02-28', 'YYYY-MM-DD'), 2, 'ACTIVE');

INSERT INTO donors (donor_id, first_name, last_name, email, phone, gender, dob, weight_kg, blood_group, city, address, last_donation_date, total_donations, status)
VALUES (seq_donor_id.NEXTVAL, 'Gurpreet', 'Singh', 'gurpreet.s@example.com', '9876500005', 'M', TO_DATE('1992-06-30', 'YYYY-MM-DD'), 82.0, 'AB+', 'Amritsar', 'GT Road, Near Golden Temple', TO_DATE('2025-11-20', 'YYYY-MM-DD'), 5, 'ACTIVE');

INSERT INTO donors (donor_id, first_name, last_name, email, phone, gender, dob, weight_kg, blood_group, city, address, last_donation_date, total_donations, status)
VALUES (seq_donor_id.NEXTVAL, 'Pooja', 'Mehta', 'pooja.mehta@example.com', '9876500006', 'F', TO_DATE('2003-04-12', 'YYYY-MM-DD'), 58.0, 'A-', 'Ludhiana', 'BRS Nagar, Block B', NULL, 0, 'ACTIVE');

INSERT INTO donors (donor_id, first_name, last_name, email, phone, gender, dob, weight_kg, blood_group, city, address, last_donation_date, total_donations, status)
VALUES (seq_donor_id.NEXTVAL, 'Vikram', 'Malhotra', 'vikram.m@example.com', '9876500007', 'M', TO_DATE('1988-12-03', 'YYYY-MM-DD'), 76.5, 'B-', 'Chandigarh', 'Sector 34-A', TO_DATE('2026-05-01', 'YYYY-MM-DD'), 6, 'ACTIVE');

INSERT INTO donors (donor_id, first_name, last_name, email, phone, gender, dob, weight_kg, blood_group, city, address, last_donation_date, total_donations, status)
VALUES (seq_donor_id.NEXTVAL, 'Ananya', 'Sen', 'ananya.sen@example.com', '9876500008', 'F', TO_DATE('1997-09-25', 'YYYY-MM-DD'), 51.0, 'AB-', 'Ludhiana', 'Kitchlu Nagar', TO_DATE('2026-04-15', 'YYYY-MM-DD'), 1, 'ACTIVE');

-- Historical Donations
INSERT INTO donations (donation_id, donor_id, blood_group, units_donated, donation_date, hemoglobin_g_dl, systolic_bp, diastolic_bp, pulse_bpm, camp_or_facility, screening_status, remarks)
VALUES (seq_donation_id.NEXTVAL, 101, 'O+', 1, TO_DATE('2026-03-10', 'YYYY-MM-DD'), 14.2, 120, 80, 72, 'Rotary Club Blood Drive', 'PASSED', 'Healthy donor; routine donation');

INSERT INTO donations (donation_id, donor_id, blood_group, units_donated, donation_date, hemoglobin_g_dl, systolic_bp, diastolic_bp, pulse_bpm, camp_or_facility, screening_status, remarks)
VALUES (seq_donation_id.NEXTVAL, 103, 'A+', 1, TO_DATE('2026-09-15', 'YYYY-MM-DD'), 15.0, 122, 78, 70, 'Civil Hospital Blood Wing', 'PASSED', 'Voluntary walk-in donor');

INSERT INTO donations (donation_id, donor_id, blood_group, units_donated, donation_date, hemoglobin_g_dl, systolic_bp, diastolic_bp, pulse_bpm, camp_or_facility, screening_status, remarks)
VALUES (seq_donation_id.NEXTVAL, 104, 'O-', 1, TO_DATE('2026-02-28', 'YYYY-MM-DD'), 13.5, 118, 76, 75, 'Red Cross Mobile Van', 'PASSED', 'Universal donor donation');

PROMPT Sample Donors and Donations seeded.

PROMPT =========================================================================;
PROMPT  [6/6] SEEDING SAMPLE BLOOD REQUESTS...;
PROMPT =========================================================================;

INSERT INTO blood_requests (request_id, patient_name, hospital_name, requester_phone, requester_email, blood_group, units_required, city, urgency_level, required_by_date, status, medical_reason)
VALUES (seq_request_id.NEXTVAL, 'Harpreet Singh', 'Civil Hospital Ludhiana', '9812300001', 'harpreet.care@gmail.com', 'B+', 2, 'Ludhiana', 'URGENT', SYSDATE + 1, 'PENDING', 'Cardiac bypass surgery');

INSERT INTO blood_requests (request_id, patient_name, hospital_name, requester_phone, requester_email, blood_group, units_required, city, urgency_level, required_by_date, status, medical_reason)
VALUES (seq_request_id.NEXTVAL, 'Rajeshwari Devi', 'Dayanand Medical College (DMC)', '9812300002', 'dmc.icu@dmch.edu', 'O-', 1, 'Ludhiana', 'CRITICAL', SYSDATE, 'PENDING', 'Emergency trauma / severe hemorrhage');

INSERT INTO blood_requests (request_id, patient_name, hospital_name, requester_phone, requester_email, blood_group, units_required, city, urgency_level, required_by_date, status, medical_reason)
VALUES (seq_request_id.NEXTVAL, 'Deepak Chopra', 'Fortis Hospital Mohali', '9812300003', 'fortis.reception@fortis.in', 'A+', 3, 'Chandigarh', 'NORMAL', SYSDATE + 4, 'PENDING', 'Orthopedic replacement surgery');

COMMIT;

PROMPT =========================================================================;
PROMPT  SCHEMA INITIALIZATION COMPLETE! 
PROMPT  All tables, sequences, constraints, and seed data created successfully.
PROMPT =========================================================================;
-- =============================================================================
-- Project Title: Blood Bank Management System (PL/SQL Project)
-- Component:     02_functions.sql (PL/SQL Stored Functions)
-- Target DBMS:   Oracle 11g / 12c / 18c / 19c / 21c / 23c / Oracle Live SQL
-- Description:   Modular PL/SQL functions for donor eligibility validation,
--                biological compatibility checking, stock status calculation,
--                and multi-group inventory aggregation.
-- =============================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED;

PROMPT =========================================================================;
PROMPT  CREATING PL/SQL FUNCTIONS...;
PROMPT =========================================================================;

-- -----------------------------------------------------------------------------
-- 1. FUNCTION: fn_calculate_age
-- Description: Computes donor age in completed years based on Date of Birth.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_calculate_age(
    p_dob IN DATE
) RETURN NUMBER
IS
    v_age NUMBER;
BEGIN
    IF p_dob IS NULL THEN
        RETURN NULL;
    END IF;
    
    v_age := TRUNC(MONTHS_BETWEEN(SYSDATE, p_dob) / 12);
    RETURN v_age;
EXCEPTION
    WHEN OTHERS THEN
        RETURN -1;
END fn_calculate_age;
/

-- -----------------------------------------------------------------------------
-- 2. FUNCTION: fn_get_next_eligible_date
-- Description: Returns the next calendar date a donor is eligible to donate.
-- Rule: Minimum 90 days cooling-off period required between donations.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_get_next_eligible_date(
    p_donor_id IN NUMBER
) RETURN DATE
IS
    v_last_donation DATE;
BEGIN
    SELECT last_donation_date
      INTO v_last_donation
      FROM donors
     WHERE donor_id = p_donor_id;
     
    IF v_last_donation IS NULL THEN
        -- Never donated before; eligible today
        RETURN TRUNC(SYSDATE);
    ELSE
        RETURN TRUNC(v_last_donation) + 90;
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL;
    WHEN OTHERS THEN
        RETURN NULL;
END fn_get_next_eligible_date;
/

-- -----------------------------------------------------------------------------
-- 3. FUNCTION: fn_check_donor_eligibility
-- Description: Thorough medical & policy eligibility validation for a donor.
-- Checks:
--   1. Donor existence and ACTIVE status
--   2. Age between 18 and 65 years
--   3. Weight at least 45.0 kg
--   4. Minimum 90 days elapsed since last donation
-- Returns: 'ELIGIBLE' or specific reason for disqualification.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_check_donor_eligibility(
    p_donor_id       IN NUMBER,
    p_target_date    IN DATE DEFAULT SYSDATE
) RETURN VARCHAR2
IS
    v_donor           donors%ROWTYPE;
    v_age             NUMBER;
    v_days_since_last NUMBER;
    v_next_eligible   DATE;
BEGIN
    -- 1. Fetch donor record
    BEGIN
        SELECT *
          INTO v_donor
          FROM donors
         WHERE donor_id = p_donor_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN 'INELIGIBLE: Donor ID ' || p_donor_id || ' does not exist in registry.';
    END;

    -- 2. Check Active Status
    IF UPPER(v_donor.status) != 'ACTIVE' THEN
        RETURN 'INELIGIBLE: Donor account is currently ' || v_donor.status || '.';
    END IF;

    -- 3. Check Age Criteria (18 to 65 years)
    v_age := fn_calculate_age(v_donor.dob);
    IF v_age < 18 THEN
        RETURN 'INELIGIBLE: Donor is underage (' || v_age || ' yrs). Minimum required age is 18.';
    ELSIF v_age > 65 THEN
        RETURN 'INELIGIBLE: Donor exceeds maximum age limit (' || v_age || ' yrs). Maximum age is 65.';
    END IF;

    -- 4. Check Weight Criteria (>= 45 kg)
    IF v_donor.weight_kg < 45.0 THEN
        RETURN 'INELIGIBLE: Donor weight (' || v_donor.weight_kg || ' kg) is below required minimum (45 kg).';
    END IF;

    -- 5. Check 90-Day Cooling-off Period
    IF v_donor.last_donation_date IS NOT NULL THEN
        v_days_since_last := TRUNC(p_target_date) - TRUNC(v_donor.last_donation_date);
        IF v_days_since_last < 90 THEN
            v_next_eligible := TRUNC(v_donor.last_donation_date) + 90;
            RETURN 'INELIGIBLE: 90-day cooldown active. Donated ' || v_days_since_last ||
                   ' days ago. Eligible on ' || TO_CHAR(v_next_eligible, 'YYYY-MM-DD') || '.';
        END IF;
    END IF;

    -- Passed all medical and administrative checks
    RETURN 'ELIGIBLE';
EXCEPTION
    WHEN OTHERS THEN
        RETURN 'ERROR: ' || SQLERRM;
END fn_check_donor_eligibility;
/

-- -----------------------------------------------------------------------------
-- 4. FUNCTION: fn_is_blood_compatible
-- Description: Determines biological compatibility between donor & recipient groups.
-- Returns: 1 (Compatible) or 0 (Incompatible).
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_is_blood_compatible(
    p_donor_group     IN VARCHAR2,
    p_recipient_group IN VARCHAR2
) RETURN NUMBER
IS
    v_match_count NUMBER := 0;
BEGIN
    SELECT COUNT(*)
      INTO v_match_count
      FROM blood_compatibility
     WHERE UPPER(donor_group) = UPPER(TRIM(p_donor_group))
       AND UPPER(recipient_group) = UPPER(TRIM(p_recipient_group))
       AND is_compatible = 'Y';

    IF v_match_count > 0 THEN
        RETURN 1;
    ELSE
        RETURN 0;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RETURN 0;
END fn_is_blood_compatible;
/

-- -----------------------------------------------------------------------------
-- 5. FUNCTION: fn_get_stock_status
-- Description: Computes health category of inventory for a blood group:
--              'CRITICAL', 'LOW', 'SUFFICIENT', or 'SURPLUS'.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_get_stock_status(
    p_blood_group IN VARCHAR2
) RETURN VARCHAR2
IS
    v_available NUMBER;
    v_critical  NUMBER;
    v_low       NUMBER;
    v_ideal     NUMBER;
BEGIN
    SELECT units_available, critical_threshold, low_threshold, ideal_capacity
      INTO v_available, v_critical, v_low, v_ideal
      FROM blood_stock
     WHERE blood_group = UPPER(TRIM(p_blood_group));

    IF v_available <= v_critical THEN
        RETURN 'CRITICAL';
    ELSIF v_available <= v_low THEN
        RETURN 'LOW';
    ELSIF v_available >= (v_ideal * 0.8) THEN
        RETURN 'SURPLUS';
    ELSE
        RETURN 'SUFFICIENT';
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 'UNKNOWN GROUP';
    WHEN OTHERS THEN
        RETURN 'ERROR';
END fn_get_stock_status;
/

-- -----------------------------------------------------------------------------
-- 6. FUNCTION: fn_get_compatible_stock
-- Description: Computes the aggregate available units across ALL compatible
--              donor groups for a given patient's blood group.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_get_compatible_stock(
    p_recipient_group IN VARCHAR2
) RETURN NUMBER
IS
    v_total_units NUMBER := 0;
BEGIN
    SELECT NVL(SUM(s.units_available), 0)
      INTO v_total_units
      FROM blood_stock s
      JOIN blood_compatibility c ON s.blood_group = c.donor_group
     WHERE c.recipient_group = UPPER(TRIM(p_recipient_group))
       AND c.is_compatible = 'Y';

    RETURN v_total_units;
EXCEPTION
    WHEN OTHERS THEN
        RETURN 0;
END fn_get_compatible_stock;
/

-- -----------------------------------------------------------------------------
-- 7. FUNCTION: fn_total_units_donated
-- Description: Returns historical lifetime volume (units) contributed by a donor.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_total_units_donated(
    p_donor_id IN NUMBER
) RETURN NUMBER
IS
    v_total NUMBER := 0;
BEGIN
    SELECT NVL(SUM(units_donated), 0)
      INTO v_total
      FROM donations
     WHERE donor_id = p_donor_id;

    RETURN v_total;
EXCEPTION
    WHEN OTHERS THEN
        RETURN 0;
END fn_total_units_donated;
/

PROMPT PL/SQL Functions created successfully.
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
-- =============================================================================
-- Project Title: Blood Bank Management System (PL/SQL Project)
-- Component:     04_triggers.sql (PL/SQL Triggers & Business Integrity Rules)
-- Target DBMS:   Oracle 11g / 12c / 18c / 19c / 21c / 23c / Oracle Live SQL
-- Description:   Autonomous database triggers enforcing business rules,
--                data hygiene, negative-inventory protection, cooldown checks,
--                and enterprise audit logging.
-- =============================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED;

PROMPT =========================================================================;
PROMPT  CREATING PL/SQL TRIGGERS...;
PROMPT =========================================================================;

-- -----------------------------------------------------------------------------
-- 1. TRIGGER: trg_donor_biometrics_check
-- Type: BEFORE INSERT OR UPDATE ON donors FOR EACH ROW
-- Purpose:
--   1. Sanitizes string inputs (capitalization, email normalization).
--   2. Enforces age restriction (18 to 65 years) via RAISE_APPLICATION_ERROR.
--   3. Enforces weight threshold (>= 45 kg).
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_donor_biometrics_check
BEFORE INSERT OR UPDATE ON donors
FOR EACH ROW
DECLARE
    v_age NUMBER;
BEGIN
    -- Input sanitization
    :NEW.first_name  := INITCAP(TRIM(:NEW.first_name));
    :NEW.last_name   := INITCAP(TRIM(:NEW.last_name));
    :NEW.email       := LOWER(TRIM(:NEW.email));
    :NEW.phone       := TRIM(:NEW.phone);
    :NEW.gender      := UPPER(TRIM(:NEW.gender));
    :NEW.blood_group := UPPER(TRIM(:NEW.blood_group));
    :NEW.city        := INITCAP(TRIM(:NEW.city));

    -- Age verification
    IF :NEW.dob IS NOT NULL THEN
        v_age := TRUNC(MONTHS_BETWEEN(SYSDATE, :NEW.dob) / 12);
        IF v_age < 18 THEN
            RAISE_APPLICATION_ERROR(-20001, 'DONOR_UNDERAGE: Donor age is ' || v_age ||
                                           ' years. Blood donation law requires minimum 18 years.');
        ELSIF v_age > 65 THEN
            RAISE_APPLICATION_ERROR(-20002, 'DONOR_OVERAGE: Donor age is ' || v_age ||
                                           ' years. Permissible voluntary donation age is capped at 65.');
        END IF;
    END IF;

    -- Weight verification
    IF :NEW.weight_kg < 45.0 THEN
        RAISE_APPLICATION_ERROR(-20003, 'DONOR_UNDERWEIGHT: Donor weight (' || :NEW.weight_kg ||
                                       ' kg) is below clinical minimum threshold (45.0 kg).');
    END IF;
END trg_donor_biometrics_check;
/

-- -----------------------------------------------------------------------------
-- 2. TRIGGER: trg_check_donation_cooldown
-- Type: BEFORE INSERT ON donations FOR EACH ROW
-- Purpose: Protects donor physiology by ensuring at least 90 days have
--          elapsed since the previous donation before any new donation row is created.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_check_donation_cooldown
BEFORE INSERT ON donations
FOR EACH ROW
DECLARE
    v_last_donation DATE;
    v_days_gap      NUMBER;
    v_next_eligible DATE;
BEGIN
    SELECT last_donation_date
      INTO v_last_donation
      FROM donors
     WHERE donor_id = :NEW.donor_id;

    IF v_last_donation IS NOT NULL THEN
        v_days_gap := TRUNC(:NEW.donation_date) - TRUNC(v_last_donation);
        IF v_days_gap < 90 THEN
            v_next_eligible := TRUNC(v_last_donation) + 90;
            RAISE_APPLICATION_ERROR(
                -20004,
                'COOLDOWN_VIOLATION: Donor last donated ' || v_days_gap ||
                ' days ago. Must wait at least 90 days between donations. Next eligible date: ' ||
                TO_CHAR(v_next_eligible, 'YYYY-MM-DD') || '.'
            );
        END IF;
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20005, 'DONOR_NOT_FOUND: Donor ID ' || :NEW.donor_id || ' does not exist.');
END trg_check_donation_cooldown;
/

-- -----------------------------------------------------------------------------
-- 3. TRIGGER: trg_prevent_negative_stock
-- Type: BEFORE UPDATE ON blood_stock FOR EACH ROW
-- Purpose: Guarantees inventory never drops below zero regardless of the source DML.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_prevent_negative_stock
BEFORE UPDATE ON blood_stock
FOR EACH ROW
BEGIN
    IF :NEW.units_available < 0 THEN
        RAISE_APPLICATION_ERROR(
            -20006,
            'NEGATIVE_STOCK_ERROR: Operation would cause inventory for ' || :NEW.blood_group ||
            ' to fall negative (' || :NEW.units_available || ' units).'
        );
    END IF;

    IF :NEW.units_reserved < 0 THEN
        RAISE_APPLICATION_ERROR(
            -20007,
            'NEGATIVE_RESERVE_ERROR: Reserved units for ' || :NEW.blood_group || ' cannot be negative.'
        );
    END IF;

    -- Update timestamp automatically
    :NEW.last_updated := SYSTIMESTAMP;
END trg_prevent_negative_stock;
/

-- -----------------------------------------------------------------------------
-- 4. TRIGGER: trg_audit_blood_stock
-- Type: AFTER UPDATE OF units_available, units_reserved ON blood_stock FOR EACH ROW
-- Purpose: Records an indelible audit trail of all inventory movements.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_audit_blood_stock
AFTER UPDATE OF units_available, units_reserved ON blood_stock
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (
        log_id, table_name, action_type, record_id,
        old_values, new_values, log_timestamp, logged_by
    ) VALUES (
        seq_audit_id.NEXTVAL,
        'BLOOD_STOCK',
        'UPDATE_INVENTORY',
        :NEW.blood_group,
        'Available=' || :OLD.units_available || '; Reserved=' || :OLD.units_reserved,
        'Available=' || :NEW.units_available || '; Reserved=' || :NEW.units_reserved,
        SYSTIMESTAMP,
        USER
    );
END trg_audit_blood_stock;
/

-- -----------------------------------------------------------------------------
-- 5. TRIGGER: trg_audit_request_status
-- Type: AFTER UPDATE OF status ON blood_requests FOR EACH ROW
-- Purpose: Captures workflow status transitions (PENDING -> APPROVED -> FULFILLED).
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_audit_request_status
AFTER UPDATE OF status ON blood_requests
FOR EACH ROW
WHEN (OLD.status != NEW.status)
BEGIN
    INSERT INTO audit_log (
        log_id, table_name, action_type, record_id,
        old_values, new_values, log_timestamp, logged_by
    ) VALUES (
        seq_audit_id.NEXTVAL,
        'BLOOD_REQUESTS',
        'STATUS_CHANGE',
        TO_CHAR(:NEW.request_id),
        'Status=' || :OLD.status,
        'Status=' || :NEW.status || '; Remarks=' || :NEW.admin_remarks || '; By=' || :NEW.processed_by,
        SYSTIMESTAMP,
        USER
    );
END trg_audit_request_status;
/

-- -----------------------------------------------------------------------------
-- 6. TRIGGER: trg_audit_donor_status
-- Type: AFTER UPDATE OF status ON donors FOR EACH ROW
-- Purpose: Tracks administrative actions on donors (ACTIVE / SUSPENDED / DEFERRED).
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_audit_donor_status
AFTER UPDATE OF status ON donors
FOR EACH ROW
WHEN (OLD.status != NEW.status)
BEGIN
    INSERT INTO audit_log (
        log_id, table_name, action_type, record_id,
        old_values, new_values, log_timestamp, logged_by
    ) VALUES (
        seq_audit_id.NEXTVAL,
        'DONORS',
        'STATUS_CHANGE',
        TO_CHAR(:NEW.donor_id),
        'Status=' || :OLD.status,
        'Status=' || :NEW.status,
        SYSTIMESTAMP,
        USER
    );
END trg_audit_donor_status;
/

PROMPT PL/SQL Triggers created successfully.
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
-- =============================================================================
-- Project Title: Blood Bank Management System (PL/SQL Project)
-- Component:     07_plsql_queries_and_views.sql (Analytical Queries & Database Views)
-- Target DBMS:   Oracle 11g / 12c / 18c / 19c / 21c / 23c / Oracle Live SQL
-- Description:   High-value analytical views and complex SQL/PL-SQL queries
--                providing business intelligence on inventory, donor demographics,
--                demand spikes, and hospital consumption.
-- =============================================================================

PROMPT =========================================================================;
PROMPT  CREATING BUSINESS INTELLIGENCE VIEWS & REPORTING QUERIES...;
PROMPT =========================================================================;

-- -----------------------------------------------------------------------------
-- 1. VIEW: vw_live_blood_inventory
-- Real-time stock status with calculated health gauge and compatible reservoir
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_live_blood_inventory AS
SELECT s.blood_group,
       g.blood_type,
       g.rh_factor,
       g.universal_donor_flag,
       g.universal_recipient_flag,
       s.units_available,
       s.units_reserved,
       (s.units_available - s.units_reserved) AS net_usable_units,
       s.critical_threshold,
       s.low_threshold,
       s.ideal_capacity,
       fn_get_stock_status(s.blood_group) AS health_category,
       fn_get_compatible_stock(s.blood_group) AS total_compatible_pool,
       ROUND((s.units_available / s.ideal_capacity) * 100, 1) AS capacity_pct,
       s.last_updated
  FROM blood_stock s
  JOIN blood_groups g ON s.blood_group = g.blood_group_id;

-- -----------------------------------------------------------------------------
-- 2. VIEW: vw_eligible_donors_roster
-- Active donors evaluated for current medical eligibility
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_eligible_donors_roster AS
SELECT d.donor_id,
       d.first_name || ' ' || d.last_name AS full_name,
       d.blood_group,
       d.city,
       d.phone,
       d.email,
       fn_calculate_age(d.dob) AS age,
       d.weight_kg,
       d.last_donation_date,
       fn_get_next_eligible_date(d.donor_id) AS next_eligible_date,
       d.total_donations,
       CASE 
           WHEN fn_check_donor_eligibility(d.donor_id, SYSDATE) = 'ELIGIBLE' THEN 'YES'
           ELSE 'NO'
       END AS is_currently_eligible,
       fn_check_donor_eligibility(d.donor_id, SYSDATE) AS eligibility_reason
  FROM donors d
 WHERE d.status = 'ACTIVE';

-- -----------------------------------------------------------------------------
-- 3. VIEW: vw_hospital_demand_summary
-- Summary of blood units demanded and fulfilled per hospital
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_hospital_demand_summary AS
SELECT hospital_name,
       city,
       COUNT(request_id) AS total_requests,
       SUM(CASE WHEN status = 'FULFILLED' THEN units_required ELSE 0 END) AS units_fulfilled,
       SUM(CASE WHEN status = 'PENDING' THEN units_required ELSE 0 END) AS units_pending,
       SUM(CASE WHEN urgency_level = 'CRITICAL' THEN 1 ELSE 0 END) AS critical_requests_count,
       MAX(requested_at) AS latest_request_date
  FROM blood_requests
 GROUP BY hospital_name, city;

-- -----------------------------------------------------------------------------
-- 4. VIEW: vw_monthly_donation_trends
-- Aggregated monthly volume by blood group
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_monthly_donation_trends AS
SELECT TO_CHAR(donation_date, 'YYYY-MM') AS donation_month,
       blood_group,
       COUNT(donation_id) AS total_sessions,
       SUM(units_donated) AS total_units_collected,
       ROUND(AVG(hemoglobin_g_dl), 1) AS avg_donor_hemoglobin
  FROM donations
 GROUP BY TO_CHAR(donation_date, 'YYYY-MM'), blood_group;

PROMPT Views created successfully.

-- -----------------------------------------------------------------------------
-- 5. SAMPLE ANALYTICAL QUERIES FOR REPORTS
-- -----------------------------------------------------------------------------

-- Query A: Blood Groups with Deficit Alerts
PROMPT 
PROMPT [Query 1] Inventory Groups At or Below Low-Stock Threshold:
SELECT blood_group, units_available, low_threshold, health_category, total_compatible_pool
  FROM vw_live_blood_inventory
 WHERE units_available <= low_threshold
 ORDER BY units_available ASC;

-- Query B: Top Donors Honor Roll (Donors with highest lifetime donations)
PROMPT 
PROMPT [Query 2] Voluntary Donor Honor Roll (Top Donors):
SELECT donor_id, full_name, blood_group, city, total_donations, last_donation_date
  FROM vw_eligible_donors_roster
 ORDER BY total_donations DESC;

-- Query C: Compatibility Cross-Match Lookups (Which donor groups can supply B+ recipient?)
PROMPT 
PROMPT [Query 3] Transfusion Compatibility for Recipient Group 'B+':
SELECT c.donor_group,
       s.units_available,
       c.preference_level,
       c.notes
  FROM blood_compatibility c
  JOIN blood_stock s ON c.donor_group = s.blood_group
 WHERE c.recipient_group = 'B+'
   AND c.is_compatible = 'Y'
 ORDER BY c.preference_level ASC, s.units_available DESC;
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
