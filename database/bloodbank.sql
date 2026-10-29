-- =====================================================================
--  Online Blood Bank Management System  -  MySQL 5.7 / 8.x schema
--  Run:  mysql -u root -p < bloodbank.sql     (or import in MySQL Workbench)
-- =====================================================================
DROP DATABASE IF EXISTS bloodbank;
CREATE DATABASE bloodbank CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE bloodbank;

-- ---------- Administrators ----------
CREATE TABLE admins (
    admin_id      INT AUTO_INCREMENT PRIMARY KEY,
    username      VARCHAR(40)  NOT NULL UNIQUE,
    password_hash VARCHAR(200) NOT NULL,
    full_name     VARCHAR(80)  NOT NULL
) ENGINE=InnoDB;

-- ---------- Donors ----------
CREATE TABLE donors (
    donor_id           INT AUTO_INCREMENT PRIMARY KEY,
    full_name          VARCHAR(80)  NOT NULL,
    email              VARCHAR(100) NOT NULL UNIQUE,
    password_hash      VARCHAR(200) NOT NULL,
    phone              VARCHAR(15)  NOT NULL,
    gender             CHAR(1)      NOT NULL,              -- M / F / O
    dob                DATE         NOT NULL,
    blood_group        VARCHAR(3)   NOT NULL,
    city               VARCHAR(60)  NOT NULL,
    last_donation_date DATE         NULL,
    registered_on      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_active          TINYINT(1)   NOT NULL DEFAULT 1,
    INDEX idx_donor_group_city (blood_group, city)
) ENGINE=InnoDB;

-- ---------- Blood stock (one row per blood group) ----------
CREATE TABLE blood_stock (
    blood_group VARCHAR(3) PRIMARY KEY,
    units       INT        NOT NULL DEFAULT 0,
    updated_on  TIMESTAMP  NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ---------- Blood requests (made by patients / hospitals) ----------
CREATE TABLE blood_requests (
    request_id     INT AUTO_INCREMENT PRIMARY KEY,
    requester_name VARCHAR(80)  NOT NULL,
    phone          VARCHAR(15)  NOT NULL,
    email          VARCHAR(100) NULL,
    hospital       VARCHAR(120) NOT NULL,
    blood_group    VARCHAR(3)   NOT NULL,
    units_required INT          NOT NULL,
    city           VARCHAR(60)  NOT NULL,
    urgency        ENUM('NORMAL','URGENT','CRITICAL') NOT NULL DEFAULT 'NORMAL',
    reason         VARCHAR(255) NULL,
    status         ENUM('PENDING','APPROVED','REJECTED','FULFILLED') NOT NULL DEFAULT 'PENDING',
    admin_remarks  VARCHAR(255) NULL,
    requested_on   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    processed_on   TIMESTAMP    NULL DEFAULT NULL,
    INDEX idx_req_status (status)
) ENGINE=InnoDB;

-- ---------- Donations (recorded by admin at the blood bank / camp) ----------
CREATE TABLE donations (
    donation_id   INT AUTO_INCREMENT PRIMARY KEY,
    donor_id      INT          NOT NULL,
    blood_group   VARCHAR(3)   NOT NULL,
    units         INT          NOT NULL,
    donation_date DATE         NOT NULL,
    notes         VARCHAR(255) NULL,
    recorded_on   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_donation_donor FOREIGN KEY (donor_id) REFERENCES donors(donor_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- =====================================================================
--  Seed data
-- =====================================================================
-- Admin login  ->  username: admin      password: admin123
INSERT INTO admins (username, password_hash, full_name) VALUES
('admin', '65536:LFaLLW7YKKC2EMYkDxThOQ==:6/dZo0wTbfmnS34uFyyIOANtaDCg9dI74rx8UUuWOf0=', 'System Administrator');

INSERT INTO blood_stock (blood_group, units) VALUES
('A+', 24), ('A-', 6), ('B+', 31), ('B-', 4), ('AB+', 12), ('AB-', 2), ('O+', 40), ('O-', 8);

-- Demo donors  ->  password for every demo donor: donor123
INSERT INTO donors (full_name, email, password_hash, phone, gender, dob, blood_group, city, last_donation_date) VALUES
('Aman Sharma',   'aman@example.com',   '65536:ZwOgQceJTfDUBv42UjM2Dw==:6nfFBmZr7yTlTOC2YLeJ/9mkwzqWev70+N7hQ7K2A1c=', '9876500001', 'M', '1999-03-14', 'O+',  'Ludhiana',   '2026-03-10'),
('Simran Kaur',   'simran@example.com', '65536:ZwOgQceJTfDUBv42UjM2Dw==:6nfFBmZr7yTlTOC2YLeJ/9mkwzqWev70+N7hQ7K2A1c=', '9876500002', 'F', '2000-07-22', 'B+',  'Ludhiana',   NULL),
('Rahul Verma',   'rahul@example.com',  '65536:ZwOgQceJTfDUBv42UjM2Dw==:6nfFBmZr7yTlTOC2YLeJ/9mkwzqWev70+N7hQ7K2A1c=', '9876500003', 'M', '1995-11-02', 'A+',  'Chandigarh', '2026-09-25'),
('Neha Gupta',    'neha@example.com',   '65536:ZwOgQceJTfDUBv42UjM2Dw==:6nfFBmZr7yTlTOC2YLeJ/9mkwzqWev70+N7hQ7K2A1c=', '9876500004', 'F', '1998-01-30', 'O-',  'Jalandhar',  '2026-01-15'),
('Gurpreet Singh','gurpreet@example.com','65536:ZwOgQceJTfDUBv42UjM2Dw==:6nfFBmZr7yTlTOC2YLeJ/9mkwzqWev70+N7hQ7K2A1c=','9876500005', 'M', '1992-05-18', 'AB+', 'Amritsar',   NULL);

INSERT INTO donations (donor_id, blood_group, units, donation_date, notes) VALUES
(1, 'O+', 1, '2026-03-10', 'Annual blood donation camp'),
(3, 'A+', 1, '2026-09-25', 'Walk-in donation'),
(4, 'O-', 1, '2026-01-15', 'Walk-in donation');

INSERT INTO blood_requests (requester_name, phone, email, hospital, blood_group, units_required, city, urgency, reason) VALUES
('Manpreet Kaur', '9812300001', 'manpreet@example.com', 'Civil Hospital', 'B+', 2, 'Ludhiana', 'URGENT',   'Surgery scheduled tomorrow'),
('Vikas Mehta',   '9812300002', NULL,                   'DMC Hospital',   'O-', 1, 'Ludhiana', 'CRITICAL', 'Accident case, emergency');
