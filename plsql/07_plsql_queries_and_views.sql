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
