# Online Blood Bank Management System
### Final Semester Project — Advanced Internet Programming (AIP)

**Technologies:** Java Servlets · JSP · JSTL · JDBC · MySQL · Apache Tomcat · NetBeans IDE

---

## 1. Abstract

Blood banks often rely on registers and phone calls to track donors, stock and patient requests. This is slow,
error-prone and makes it hard to find the right blood group in an emergency. The **Online Blood Bank Management
System** is a web application that digitises these tasks. Donors register online, patients and hospitals raise
blood requests, and the blood bank administrator records donations, maintains live stock and approves requests.
The system enforces donation-eligibility rules (age and 90-day gap) and keeps stock consistent by updating it
inside database transactions.

## 2. Objectives

1. Provide a single online platform for donors, patients/hospitals and blood bank staff.
2. Maintain accurate, real-time blood stock for all eight blood groups.
3. Let anyone search for donors by blood group and city.
4. Automate donor-eligibility checking (age 18–65 and at least 90 days since last donation).
5. Offer secure authentication, role-based access and protection against common web attacks.

## 3. Scope

**In scope:** donor registration and profile, donor search, blood request and tracking, donation recording,
stock management, request approval workflow, admin dashboard.
**Out of scope:** online payment, SMS/e-mail gateways, medical screening records, multi-branch blood banks.

## 4. System requirements

| Type | Requirement |
|------|-------------|
| Hardware | Any PC with 4 GB RAM, 500 MB free disk |
| Operating system | Windows / Linux / macOS |
| Software | JDK 8+, Apache NetBeans 12+, Apache Tomcat 9, MySQL 5.7/8, a modern web browser |
| Languages | Java, JSP, HTML5, CSS3, SQL |

## 5. Users and modules

### 5.1 Visitor (no login)
* View live blood availability and statistics on the home page.
* Search donors by blood group, city, and "can donate now" (phone numbers are masked).
* Submit a blood request and track it with *request ID + phone number*.

### 5.2 Donor
* Register with name, e-mail, phone, gender, date of birth, blood group, city and password.
* Log in, view dashboard (eligibility status, last donation, next eligible date, donation history).
* Update profile and change password.

### 5.3 Administrator
* Dashboard: active donors, eligible donors, units in stock, donations, requests by status, pending requests.
* Blood requests: approve (deducts stock), reject, mark fulfilled, add remarks.
* Donations: record a donation (adds stock, updates donor's last-donation date).
* Blood stock: view levels per group and correct counts after a physical check.
* Donors: filter by blood group, activate/deactivate, delete.

## 6. System design

### 6.1 Architecture (MVC)

```
 Browser ──► SecurityFilter ──► Servlet (Controller) ──► DAO ──► MySQL
                                     │                      ▲
                                     ▼                      │
                                JSP (View) ◄──── Model (Donor, BloodRequest, …)
```

| Layer | Classes |
|-------|---------|
| Controller | `AuthServlet`, `PublicServlet`, `DonorServlet`, `AdminServlet` |
| Filter | `SecurityFilter` (UTF-8, CSRF token, access control) |
| Model | `Donor`, `Admin`, `BloodStock`, `BloodRequest`, `Donation` |
| DAO | `DonorDAO`, `AdminDAO`, `StockDAO`, `RequestDAO`, `DonationDAO` |
| View | JSP pages under `WEB-INF/views`, styled by `assets/css/style.css` |
| Utility | `DBConnection`, `PasswordUtil`, `Validator`, `Web` |

### 6.2 Database design

**Tables**

| Table | Key columns |
|-------|-------------|
| `admins` | **admin_id**, username (unique), password_hash, full_name |
| `donors` | **donor_id**, full_name, email (unique), password_hash, phone, gender, dob, blood_group, city, last_donation_date, registered_on, is_active |
| `blood_stock` | **blood_group**, units, updated_on |
| `blood_requests` | **request_id**, requester_name, phone, email, hospital, blood_group, units_required, city, urgency, reason, status, admin_remarks, requested_on, processed_on |
| `donations` | **donation_id**, *donor_id → donors*, blood_group, units, donation_date, notes, recorded_on |

**ER relationships**

```
DONOR (1) ──────< (N) DONATION        a donor makes many donations
BLOOD_STOCK (1 per group) ◄── updated by DONATION (+) and approved BLOOD_REQUEST (−)
ADMIN  manages  DONOR, DONATION, BLOOD_REQUEST, BLOOD_STOCK
```

### 6.3 Data-flow diagrams (description)

**Level 0 (context):** Donor, Visitor/Patient and Administrator interact with the *Online Blood Bank System*.
Donors send registration/login data and receive profile and history. Visitors send search criteria and blood
requests and receive donor lists, stock and request status. The administrator sends donation records,
request decisions and stock updates and receives dashboard reports.

**Level 1 processes:**
1. *Manage accounts* — registration, login, profile (D1: donors)
2. *Search & view stock* — reads D1 donors and D3 blood_stock
3. *Handle blood requests* — create (D4 blood_requests), approve/reject/fulfil, deduct D3
4. *Record donations* — writes D5 donations, increases D3, updates D1.last_donation_date
5. *Administration & reports* — dashboard queries on D1–D5

### 6.4 Key business rules

| Rule | Where it is enforced |
|------|----------------------|
| Donor age must be 18–65 | `AuthServlet`, `DonorServlet`, `Donor.isEligibleOn()`, SQL search filter |
| 90 days between donations | `Donor.isEligibleOn()`, admin donation form, eligible-only search |
| Stock cannot become negative | `RequestDAO.approve()` — row-locked transaction (`SELECT … FOR UPDATE`) |
| A donation changes stock + donor + history together | `DonationDAO.record()` — single transaction with rollback |
| Request workflow `PENDING → APPROVED → FULFILLED` or `PENDING → REJECTED` | `RequestDAO` (state checked in the `UPDATE … WHERE status = ?`) |

### 6.5 Security measures

* Passwords stored as salted **PBKDF2-HMAC-SHA256** (65,536 iterations).
* All SQL through **PreparedStatement** — prevents SQL injection.
* **CSRF** token required for every POST (`SecurityFilter`).
* **Session fixation** prevented with `changeSessionId()` on login; 30-minute session timeout; HttpOnly cookie.
* **Role-based access**: `/admin/*` needs an admin session, `/donor/*` a donor session.
* **XSS** prevented by escaping all user data with `<c:out>`.
* JSPs placed in `WEB-INF` so they cannot be opened directly; error pages hide technical details.
* Donor phone numbers masked in public search; the public status lookup needs both request ID and phone.

## 7. Implementation notes

* Built as a Maven web application (`packaging = war`), opened directly in NetBeans.
* `DBConnection` reads `db.properties`; the MySQL driver and JSTL are packaged into `WEB-INF/lib`.
* JSP pages contain no Java scriptlets — only JSTL/EL — keeping view and logic separate.
* Flash messages (success/error) are stored in the session for one request (Post-Redirect-Get pattern).

## 8. Testing

| # | Test case | Expected result | Status |
|---|-----------|-----------------|--------|
| 1 | Register with valid data | Account created, redirected to login |  |
| 2 | Register with an existing e-mail | Error "already registered" |  |
| 3 | Register with age < 18 | Error message shown |  |
| 4 | Password shorter than 8 characters | Validation error |  |
| 5 | Donor login with wrong password | "Invalid email or password" |  |
| 6 | Open `/admin/dashboard` without login | Redirect to admin login |  |
| 7 | Submit a POST form without CSRF token | HTTP 403 page |  |
| 8 | Search donors by group + city | Matching donors listed, phone masked |  |
| 9 | Record a donation for a donor donated < 90 days ago | Rejected with next eligible date |  |
| 10 | Record a valid donation | Stock +units, donor last-donation date updated |  |
| 11 | Approve request with enough stock | Status APPROVED, stock decreased |  |
| 12 | Approve request larger than stock | Rejected with "Not enough stock" message |  |
| 13 | Track request with wrong phone number | "No request found" |  |
| 14 | Deactivate a donor | Donor can no longer log in or appear in search |  |

> Run each test case on your own machine and write Pass / Fail in the *Status* column before submitting.

Unit-level checks already verified during development: password hash/verify round-trip, demo-account hashes,
and the eligibility rule at the boundaries (89 days → not eligible, 90 days → eligible, age 17 → not eligible).

## 9. Limitations

* No e-mail/SMS notifications.
* One blood bank only; no expiry tracking per blood bag.
* Connections are created per request (no connection pool).

## 10. Future enhancements

1. SMS / e-mail alerts to matching donors when stock of a group is low.
2. Blood-bag level inventory with expiry dates and automatic expiry alerts.
3. Donation camp scheduling and online appointment booking.
4. Connection pooling (JNDI DataSource) and REST API for a mobile app.
5. Reports exportable to PDF / Excel.

## 11. Conclusion

The Online Blood Bank Management System shows how a servlet/JSP/JDBC application can replace a manual register
with a secure, role-based and transactional system. It reduces the time to locate eligible donors, keeps stock
accurate, and gives patients a transparent way to request and track blood.

## 12. References

* Oracle, *Java Servlet and JSP documentation*
* Apache Tomcat 9 documentation — https://tomcat.apache.org/tomcat-9.0-doc/
* MySQL 8.0 Reference Manual — https://dev.mysql.com/doc/
* OWASP Cheat Sheet Series (CSRF Prevention, Password Storage) — https://cheatsheetseries.owasp.org/
