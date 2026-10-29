package com.bloodbank.controller;

import com.bloodbank.dao.AdminDAO;
import com.bloodbank.dao.DonorDAO;
import com.bloodbank.model.Admin;
import com.bloodbank.model.Donor;
import com.bloodbank.util.DataAccessException;
import com.bloodbank.util.Validator;
import com.bloodbank.util.Web;
import java.io.IOException;
import java.sql.Date;
import java.sql.SQLIntegrityConstraintViolationException;
import java.time.LocalDate;
import java.time.Period;
import java.util.ArrayList;
import java.util.List;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

/** Donor registration / login, administrator login and logout. */
@WebServlet(name = "AuthServlet", urlPatterns = {"/login", "/register", "/admin-login", "/logout"})
public class AuthServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    private final DonorDAO donorDAO = new DonorDAO();
    private final AdminDAO adminDAO = new AdminDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        switch (req.getServletPath()) {
            case "/login":
                Web.forward(req, resp, "login");
                break;
            case "/register":
                Web.forward(req, resp, "register");
                break;
            case "/admin-login":
                Web.forward(req, resp, "admin-login");
                break;
            default:
                Web.redirect(req, resp, "/home");
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        switch (req.getServletPath()) {
            case "/login":
                login(req, resp);
                break;
            case "/register":
                register(req, resp);
                break;
            case "/admin-login":
                adminLogin(req, resp);
                break;
            case "/logout":
                logout(req, resp);
                break;
            default:
                resp.sendError(HttpServletResponse.SC_METHOD_NOT_ALLOWED);
        }
    }

    private void register(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String name = Validator.clean(req.getParameter("fullName"));
        String email = Validator.clean(req.getParameter("email")).toLowerCase();
        String phone = Validator.clean(req.getParameter("phone"));
        String gender = Validator.clean(req.getParameter("gender"));
        String dobText = Validator.clean(req.getParameter("dob"));
        String group = Validator.clean(req.getParameter("bloodGroup"));
        String city = Validator.clean(req.getParameter("city"));
        String password = req.getParameter("password");
        String confirm = req.getParameter("confirmPassword");

        List<String> errors = new ArrayList<>();
        if (!Validator.lengthBetween(name, 2, 80)) {
            errors.add("Full name must be 2 to 80 characters long.");
        }
        if (!Validator.isEmail(email)) {
            errors.add("Enter a valid email address.");
        } else if (donorDAO.emailExists(email)) {
            errors.add("This email address is already registered.");
        }
        if (!Validator.isPhone(phone)) {
            errors.add("Phone number must be exactly 10 digits.");
        }
        if (!Validator.isGender(gender)) {
            errors.add("Select your gender.");
        }
        Date dob = Validator.parseDate(dobText);
        if (dob == null) {
            errors.add("Enter a valid date of birth.");
        } else {
            int age = Period.between(dob.toLocalDate(), LocalDate.now()).getYears();
            if (age < 18 || age > 65) {
                errors.add("Donors must be between 18 and 65 years old.");
            }
        }
        if (!Validator.isBloodGroup(group)) {
            errors.add("Select a valid blood group.");
        }
        if (!Validator.lengthBetween(city, 2, 60)) {
            errors.add("City must be 2 to 60 characters long.");
        }
        if (password == null || password.length() < 8) {
            errors.add("Password must be at least 8 characters long.");
        } else if (!password.equals(confirm)) {
            errors.add("Password and confirm password do not match.");
        }
        if (req.getParameter("consent") == null) {
            errors.add("Please confirm that you are healthy and willing to donate blood.");
        }

        if (errors.isEmpty()) {
            Donor d = new Donor();
            d.setFullName(name);
            d.setEmail(email);
            d.setPhone(phone);
            d.setGender(gender);
            d.setDob(dob);
            d.setBloodGroup(group);
            d.setCity(city);
            try {
                donorDAO.create(d, password);
            } catch (DataAccessException e) {
                if (e.getCause() instanceof SQLIntegrityConstraintViolationException) {
                    errors.add("This email address is already registered.");
                } else {
                    throw e;
                }
            }
        }

        if (!errors.isEmpty()) {
            req.setAttribute("errors", errors);
            Web.forward(req, resp, "register");
            return;
        }
        Web.flash(req, "success", "Registration successful! You can now log in.");
        Web.redirect(req, resp, "/login");
    }

    private void login(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String email = Validator.clean(req.getParameter("email"));
        String password = req.getParameter("password");
        Donor donor = Validator.isBlank(email) || password == null ? null : donorDAO.authenticate(email, password);
        if (donor == null) {
            req.setAttribute("error", "Invalid email or password.");
            Web.forward(req, resp, "login");
            return;
        }
        req.changeSessionId(); // prevents session fixation
        req.getSession().setAttribute("donor", donor);
        Web.redirect(req, resp, "/donor/dashboard");
    }

    private void adminLogin(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String username = Validator.clean(req.getParameter("username"));
        String password = req.getParameter("password");
        Admin admin = Validator.isBlank(username) || password == null ? null : adminDAO.authenticate(username, password);
        if (admin == null) {
            req.setAttribute("error", "Invalid username or password.");
            Web.forward(req, resp, "admin-login");
            return;
        }
        req.changeSessionId();
        req.getSession().setAttribute("admin", admin);
        Web.redirect(req, resp, "/admin/dashboard");
    }

    private void logout(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        HttpSession session = req.getSession(false);
        if (session != null) {
            session.invalidate();
        }
        Web.flash(req, "info", "You have been logged out.");
        Web.redirect(req, resp, "/home");
    }
}
