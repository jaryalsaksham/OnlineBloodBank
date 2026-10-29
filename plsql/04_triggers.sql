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
