package com.bloodbank.controller;

import com.bloodbank.dao.DonationDAO;
import com.bloodbank.dao.DonorDAO;
import com.bloodbank.dao.RequestDAO;
import com.bloodbank.dao.StockDAO;
import com.bloodbank.model.BloodRequest;
import com.bloodbank.model.Donor;
import com.bloodbank.util.Validator;
import com.bloodbank.util.Web;
import java.io.IOException;
import java.sql.Date;
import java.time.LocalDate;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

/** Administrative console: donor listing, requests, donations, stock. */
@WebServlet(name = "AdminServlet", urlPatterns = {
    "/admin",
    "/admin/dashboard",
    "/admin/donors",
    "/admin/requests",
    "/admin/donations",
    "/admin/stock"
})
public class AdminServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;
    private static final List<String> STATUSES = Arrays.asList("PENDING", "APPROVED", "REJECTED", "FULFILLED");

    private final DonorDAO donorDAO = new DonorDAO();
    private final RequestDAO requestDAO = new RequestDAO();
    private final DonationDAO donationDAO = new DonationDAO();
    private final StockDAO stockDAO = new StockDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        switch (page(req)) {
            case "/dashboard":
                dashboard(req, resp);
                break;
            case "/donors":
                String group = Validator.clean(req.getParameter("bloodGroup"));
                if (!Validator.isBloodGroup(group)) {
                    group = "";
                }
                req.setAttribute("filterGroup", group);
                req.setAttribute("donors", donorDAO.findAll(group));
                Web.forward(req, resp, "admin/donors");
                break;
            case "/requests":
                String status = Validator.clean(req.getParameter("status"));
                if (!STATUSES.contains(status)) {
                    status = "";
                }
                req.setAttribute("filterStatus", status);
                req.setAttribute("requests", requestDAO.findAll(status));
                Web.forward(req, resp, "admin/requests");
                break;
            case "/donations":
                req.setAttribute("donations", donationDAO.findAll());
                req.setAttribute("donors", donorDAO.search("", "", false));
                req.setAttribute("today", LocalDate.now().toString());
                Web.forward(req, resp, "admin/donations");
                break;
            case "/stock":
                req.setAttribute("stock", stockDAO.findAll());
                Web.forward(req, resp, "admin/stock");
                break;
            default:
                Web.redirect(req, resp, "/admin/dashboard");
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        switch (page(req)) {
            case "/donors":
                donorAction(req, resp);
                break;
            case "/requests":
                requestAction(req, resp);
                break;
            case "/donations":
                recordDonation(req, resp);
                break;
            case "/stock":
                updateStock(req, resp);
                break;
            default:
                resp.sendError(HttpServletResponse.SC_METHOD_NOT_ALLOWED);
        }
    }

    private static String page(HttpServletRequest req) {
        String sp = req.getServletPath();
        if (sp != null && sp.startsWith("/admin/")) {
            return sp.substring("/admin".length());
        }
        if (req.getPathInfo() != null && !req.getPathInfo().isEmpty()) {
            return req.getPathInfo();
        }
        return "/dashboard";
    }

    private void dashboard(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        Map<String, Integer> counts = requestDAO.countByStatus();
        List<BloodRequest> pending = requestDAO.findAll("PENDING");
        req.setAttribute("totalDonors", donorDAO.countActive());
        req.setAttribute("eligibleDonors", donorDAO.countEligible());
        req.setAttribute("totalUnits", stockDAO.totalUnits());
        req.setAttribute("donationCount", donationDAO.count());
        req.setAttribute("requestCounts", counts);
        req.setAttribute("stock", stockDAO.findAll());
        req.setAttribute("pending", pending.subList(0, Math.min(5, pending.size())));
        Web.forward(req, resp, "admin/dashboard");
    }

    private void donorAction(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        int id = Validator.parseInt(req.getParameter("id"), -1);
        String action = Validator.clean(req.getParameter("action"));
        Donor d = donorDAO.findById(id);
        if (d == null) {
            Web.flash(req, "error", "Donor not found.");
        } else if ("toggle".equals(action)) {
            donorDAO.setActive(id, !d.isActive());
            Web.flash(req, "success", d.getFullName() + (d.isActive() ? " was deactivated." : " was activated."));
        } else if ("delete".equals(action)) {
            donorDAO.delete(id);
            Web.flash(req, "success", d.getFullName() + " was deleted together with their donation history.");
        } else {
            Web.flash(req, "error", "Unknown action.");
        }
        Web.redirect(req, resp, "/admin/donors");
    }

    private void requestAction(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        int id = Validator.parseInt(req.getParameter("id"), -1);
        String action = Validator.clean(req.getParameter("action"));
        String remarks = Validator.clean(req.getParameter("remarks"));
        String filter = Validator.clean(req.getParameter("status"));

        String error;
        String done;
        if (remarks.length() > 255) {
            error = "Remarks can be at most 255 characters.";
            done = null;
        } else if ("approve".equals(action)) {
            error = requestDAO.approve(id, remarks);
            done = "Request #" + id + " approved and stock updated.";
        } else if ("reject".equals(action)) {
            error = requestDAO.reject(id, remarks);
            done = "Request #" + id + " rejected.";
        } else if ("fulfill".equals(action)) {
            error = requestDAO.fulfill(id, remarks);
            done = "Request #" + id + " marked as fulfilled.";
        } else {
            error = "Unknown action.";
            done = null;
        }
        if (error == null) {
            Web.flash(req, "success", done);
        } else {
            Web.flash(req, "error", error);
        }
        Web.redirect(req, resp, "/admin/requests" + (STATUSES.contains(filter) ? "?status=" + filter : ""));
    }

    private void recordDonation(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        int donorId = Validator.parseInt(req.getParameter("donorId"), -1);
        int units = Validator.parseInt(req.getParameter("units"), 0);
        Date date = Validator.parseDate(req.getParameter("donationDate"));
        String notes = Validator.clean(req.getParameter("notes"));

        Donor donor = donorDAO.findById(donorId);
        String error = null;
        if (donor == null) {
            error = "Select a donor.";
        } else if (units < 1 || units > 5) {
            error = "Units must be between 1 and 5.";
        } else if (date == null || date.toLocalDate().isAfter(LocalDate.now())) {
            error = "Enter a valid donation date (not in the future).";
        } else if (notes.length() > 255) {
            error = "Notes can be at most 255 characters.";
        } else if (!donor.isEligibleOn(date.toLocalDate())) {
            error = donor.getFullName() + " is not eligible to donate on that date"
                    + (donor.getNextEligibleDate() == null ? "." : " (next eligible: " + donor.getNextEligibleDate() + ").");
        } else {
            error = donationDAO.record(donorId, units, date, notes);
        }

        if (error == null) {
            Web.flash(req, "success", "Donation recorded: " + units + " unit(s) of " + donor.getBloodGroup()
                    + " added to stock.");
        } else {
            Web.flash(req, "error", error);
        }
        Web.redirect(req, resp, "/admin/donations");
    }

    private void updateStock(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String group = Validator.clean(req.getParameter("bloodGroup"));
        int units = Validator.parseInt(req.getParameter("units"), -1);
        if (!Validator.isBloodGroup(group) || units < 0 || units > 9999) {
            Web.flash(req, "error", "Choose a blood group and enter units between 0 and 9999.");
        } else {
            stockDAO.setUnits(group, units);
            Web.flash(req, "success", "Stock for " + group + " set to " + units + " unit(s).");
        }
        Web.redirect(req, resp, "/admin/stock");
    }
}
