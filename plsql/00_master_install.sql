-- =============================================================================
-- Project Title: Blood Bank Management System (PL/SQL Project)
-- Component:     00_master_install.sql (Master Installation Script)
-- Target DBMS:   Oracle 11g / 12c / 18c / 19c / 21c / 23c / Oracle SQL Developer
-- Usage:         Run via SQL*Plus or Oracle SQL Developer:
--                SQL> @00_master_install.sql
-- =============================================================================

SET ECHO ON;
SET FEEDBACK ON;
SET SERVEROUTPUT ON SIZE UNLIMITED;
SET LINESIZE 200;
SET PAGESIZE 100;

PROMPT *************************************************************************;
PROMPT *                                                                       *;
PROMPT *          BLOOD BANK MANAGEMENT SYSTEM - PL/SQL PROJECT                *;
PROMPT *     Manage Donors, Blood Groups, Blood Stock, and Blood Requests      *;
PROMPT *                                                                       *;
PROMPT *************************************************************************;

PROMPT 
PROMPT >>> STEP 1: Running Schema DDL, Tables, Sequences & Seed Data...
@01_schema_ddl.sql

PROMPT 
PROMPT >>> STEP 2: Compiling PL/SQL Functions...
@02_functions.sql

PROMPT 
PROMPT >>> STEP 3: Compiling PL/SQL Stored Procedures...
@03_procedures.sql

PROMPT 
PROMPT >>> STEP 4: Compiling PL/SQL Database Triggers...
@04_triggers.sql

PROMPT 
PROMPT >>> STEP 5: Compiling Enterprise Packages (Spec & Body)...
@05_packages.sql

PROMPT 
PROMPT >>> STEP 6: Creating Database Views and Analytical Reports...
@07_plsql_queries_and_views.sql

PROMPT 
PROMPT >>> STEP 7: Executing Automated Test & Verification Suite...
@06_test_execution_suite.sql

PROMPT 
PROMPT *************************************************************************;
PROMPT *                  FULL INSTALLATION COMPLETED!                         *;
PROMPT *************************************************************************;
