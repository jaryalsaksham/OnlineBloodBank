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
