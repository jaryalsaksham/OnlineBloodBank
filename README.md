# Online Blood Bank Management System (AIP Project)

A complete, production-grade Java Web Application built for **Advanced Internet Programming (AIP)** using **Jakarta EE 10 (Servlets 6.0, JSP 3.1, JSTL 3.0), JDBC, and MySQL 9.x/8.x**, packaged as a standard Maven Web Project tailored specifically for **Apache NetBeans** and **Apache Tomcat 10.1**.

---

## 🌟 Key Features

| Module | Features |
|---|---|
| **Public Portal** | • Live Blood Stock inventory counters (A+, A-, B+, B-, AB+, AB-, O+, O-)<br>• Search registered blood donors by blood group & city (with eligibility filters)<br>• Emergency Blood Request form with contact & hospital details<br>• Real-time Request Tracking by Request ID & Phone Number |
| **Donor Portal** | • Secure registration with age validation (18–65 years)<br>• Donor Login & Personalized Dashboard<br>• Donation eligibility calculator (enforcing 90-day donation cooldown)<br>• Donation history log & Next eligible donation date<br>• Profile & Password management |
| **Admin Portal** | • Metric cards: Active Donors, Units in Stock, Pending & Fulfilled Requests<br>• Blood Request Management (Approve, Reject, or Fulfill with remarks)<br>• Automated Inventory Adjustment (approving requests automatically deducts stock inside a DB transaction; recording donations automatically increments stock)<br>• Manual Stock Adjustments<br>• Donor Management (Search, Activate / Deactivate, Delete) |
| **Security & Robustness** | • PBKDF2 Password Hashing with Salt<br>• PreparedStatements across all DAOs (SQL Injection immune)<br>• CSRF Token Protection on all POST submissions<br>• Session-fixation protection on login<br>• Centralized `SecurityFilter` for route protection (`/admin/*` and `/donor/*`)<br>• Secure JSPs isolated under `/WEB-INF/views/` |

---

## 🛠️ Technology Stack

- **Platform**: Jakarta EE 10 (Servlet 6.0, JSP 3.1, JSTL 3.0)
- **Runtime Server**: Apache Tomcat 10.1 (Configured at `C:\Servers\apache-tomcat-10.1.57-windows-x64\apache-tomcat-10.1.57`)
- **IDE**: Apache NetBeans
- **Database**: MySQL Server 9.6 / 8.x (`com.mysql.cj.jdbc.Driver`)
- **Build Tool**: Apache Maven (bundled with NetBeans)
- **Java Version**: JDK 17 / 21 LTS

---

## 🚀 How to Open and Run in Apache NetBeans

1. Open **Apache NetBeans**.
2. Go to **File** ➔ **Open Project...** (`Ctrl + Shift + O`).
3. Navigate to:
   ```
   C:\Users\saksham jaryal\OneDrive\Pictures\Documents\NetBeansProjects\OnlineBloodBank
   ```
   *(or `C:\Users\saksham jaryal\.gemini\antigravity-ide\scratch\OnlineBloodBank`)*
4. Click **Open Project**.
5. In the **Projects** panel on the left, right-click **Online Blood Bank Management System** and click **Run** (or press **F6**).
6. NetBeans will automatically compile, package, and launch the application in your browser:
   ```
   http://localhost:8080/OnlineBloodBank/
   ```

---

## 🗄️ Database Setup & Credentials

The MySQL database `bloodbank` has already been configured and initialized:

- **Database Name**: `bloodbank`
- **Host / Port**: `localhost:3306`
- **Username**: `root`
- **Password**: `Tidu@2005` (configured in `src/main/resources/db.properties`)

### Demo Accounts for Testing:

#### 1. Administrator Account:
- **URL**: `http://localhost:8080/OnlineBloodBank/admin-login`
- **Username**: `admin`
- **Password**: `admin123`

#### 2. Donor Accounts:
- **URL**: `http://localhost:8080/OnlineBloodBank/login`
- **Email**: `aman@example.com` | **Password**: `donor123`
- **Email**: `simran@example.com` | **Password**: `donor123`
- **Email**: `rahul@example.com` | **Password**: `donor123`
- **User Account**: `sakshamjaryal2@gmail.com`

---

## 📂 Project Architecture

```
OnlineBloodBank/
├── pom.xml                               # Maven Project Descriptor (Jakarta EE 10)
├── nb-configuration.xml                  # NetBeans IDE Server & Web hints
├── database/
│   └── bloodbank.sql                     # Full MySQL DDL schema + Seed Data
├── src/main/
│   ├── java/com/bloodbank/
│   │   ├── controller/                   # Servlets (PublicServlet, AuthServlet, AdminServlet, DonorServlet)
│   │   ├── dao/                          # Data Access Objects (AdminDAO, DonorDAO, StockDAO, RequestDAO, DonationDAO)
│   │   ├── filter/                       # SecurityFilter (CSRF, Auth check, Headers)
│   │   ├── model/                        # Entity POJOs (Admin, Donor, BloodStock, BloodRequest, Donation)
│   │   └── util/                         # DBConnection, PasswordUtil, Validator, Web helpers
│   ├── resources/
│   │   └── db.properties                 # JDBC connection parameters
│   └── webapp/
│       ├── assets/                       # CSS stylesheets & branding
│       ├── WEB-INF/
│       │   ├── web.xml                   # Servlet 6.0 deployment descriptor
│       │   └── views/                    # JSPs (home, search, donor dashboard, admin dashboard, etc.)
│       └── index.jsp                     # Entrypoint redirecting to /home
```
