package com.bloodbank.controller;

import com.bloodbank.dao.DonationDAO;
import com.bloodbank.dao.DonorDAO;
import com.bloodbank.model.Donor;
import com.bloodbank.util.Validator;
import com.bloodbank.util.Web;
import java.io.IOException;
import java.sql.Date;
import java.time.LocalDate;
import java.time.Period;
import java.util.ArrayList;
import java.util.List;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

/** Pages for a logged-in donor (access is enforced by SecurityFilter). */
@WebServlet(name = "DonorServlet", urlPatterns = {"/donor/dashboard", "/donor/profile", "/donor/password"})
public class DonorServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    private final DonorDAO donorDAO = new DonorDAO();
    private final DonationDAO donationDAO = new DonationDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        Donor me = freshDonor(req, resp);
        if (me == null) {
            return;
        }
        req.setAttribute("me", me);
        switch (req.getServletPath()) {
            case "/donor/dashboard":
                req.setAttribute("donations", donationDAO.findByDonor(me.getId()));
                Web.forward(req, resp, "donor/dashboard");
                break;
            case "/donor/profile":
                Web.forward(req, resp, "donor/profile");
                break;
            default:
                Web.redirect(req, resp, "/donor/dashboard");
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        Donor me = freshDonor(req, resp);
        if (me == null) {
            return;
        }
        switch (req.getServletPath()) {
            case "/donor/profile":
                updateProfile(req, resp, me);
                break;
            case "/donor/password":
                changePassword(req, resp, me);
                break;
            default:
                resp.sendError(HttpServletResponse.SC_METHOD_NOT_ALLOWED);
        }
    }

    private void updateProfile(HttpServletRequest req, HttpServletResponse resp, Donor me)
            throws ServletException, IOException {
        String name = Validator.clean(req.getParameter("fullName"));
        String phone = Validator.clean(req.getParameter("phone"));
        String gender = Validator.clean(req.getParameter("gender"));
        String city = Validator.clean(req.getParameter("city"));
        Date dob = Validator.parseDate(req.getParameter("dob"));

        List<String> errors = new ArrayList<>();
        if (!Validator.lengthBetween(name, 2, 80)) {
            errors.add("Full name must be 2 to 80 characters long.");
        }
        if (!Validator.isPhone(phone)) {
            errors.add("Phone number must be exactly 10 digits.");
        }
        if (!Validator.isGender(gender)) {
            errors.add("Select your gender.");
        }
        if (dob == null) {
            errors.add("Enter a valid date of birth.");
        } else {
            int age = Period.between(dob.toLocalDate(), LocalDate.now()).getYears();
            if (age < 18 || age > 65) {
                errors.add("Donors must be between 18 and 65 years old.");
            }
        }
        if (!Validator.lengthBetween(city, 2, 60)) {
            errors.add("City must be 2 to 60 characters long.");
        }

        if (!errors.isEmpty()) {
            req.setAttribute("errors", errors);
            req.setAttribute("me", me);
            Web.forward(req, resp, "donor/profile");
            return;
        }
        me.setFullName(name);
        me.setPhone(phone);
        me.setGender(gender);
        me.setDob(dob);
        me.setCity(city);
        donorDAO.updateProfile(me);
        req.getSession().setAttribute("donor", me);
        Web.flash(req, "success", "Profile updated.");
        Web.redirect(req, resp, "/donor/profile");
    }

    private void changePassword(HttpServletRequest req, HttpServletResponse resp, Donor me) throws IOException {
        String current = req.getParameter("currentPassword");
        String next = req.getParameter("newPassword");
        String confirm = req.getParameter("confirmPassword");

        if (current == null || next == null || next.length() < 8) {
            Web.flash(req, "error", "New password must be at least 8 characters long.");
        } else if (!next.equals(confirm)) {
            Web.flash(req, "error", "New password and confirmation do not match.");
        } else if (!donorDAO.changePassword(me.getId(), current, next)) {
            Web.flash(req, "error", "Current password is incorrect.");
        } else {
            Web.flash(req, "success", "Password changed successfully.");
        }
        Web.redirect(req, resp, "/donor/profile");
    }

    /** Reloads the donor from the database; logs out if the account was removed or deactivated. */
    private Donor freshDonor(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        Donor sessionDonor = (Donor) req.getSession().getAttribute("donor");
        Donor fresh = donorDAO.findById(sessionDonor.getId());
        if (fresh == null || !fresh.isActive()) {
            req.getSession().invalidate();
            Web.flash(req, "error", "Your account is no longer active.");
            Web.redirect(req, resp, "/login");
            return null;
        }
        req.getSession().setAttribute("donor", fresh);
        return fresh;
    }
}
