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
