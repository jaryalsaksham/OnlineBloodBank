package com.bloodbank.controller;

import com.bloodbank.dao.DonationDAO;
import com.bloodbank.dao.DonorDAO;
import com.bloodbank.dao.RequestDAO;
import com.bloodbank.dao.StockDAO;
import com.bloodbank.model.BloodRequest;
import com.bloodbank.util.Validator;
import com.bloodbank.util.Web;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

/** Pages anybody can open: home, donor search, blood request form, request status. */
@WebServlet(name = "PublicServlet", urlPatterns = {"/home", "/search", "/request-blood", "/request-status"})
public class PublicServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    private final StockDAO stockDAO = new StockDAO();
    private final DonorDAO donorDAO = new DonorDAO();
    private final DonationDAO donationDAO = new DonationDAO();
    private final RequestDAO requestDAO = new RequestDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        switch (req.getServletPath()) {
            case "/home":
                home(req, resp);
                break;
            case "/search":
                search(req, resp);
                break;
            case "/request-blood":
                Web.forward(req, resp, "request-form");
                break;
            case "/request-status":
                status(req, resp);
                break;
            default:
                resp.sendError(HttpServletResponse.SC_NOT_FOUND);
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        if ("/request-blood".equals(req.getServletPath())) {
            submitRequest(req, resp);
        } else {
            resp.sendError(HttpServletResponse.SC_METHOD_NOT_ALLOWED);
        }
    }

    private void home(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        req.setAttribute("stock", stockDAO.findAll());
        req.setAttribute("statDonors", donorDAO.countActive());
        req.setAttribute("statUnits", stockDAO.totalUnits());
        req.setAttribute("statDonations", donationDAO.count());
        req.setAttribute("statFulfilled", requestDAO.countByStatus().get("FULFILLED"));
        Web.forward(req, resp, "home");
    }

    private void search(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        if (req.getParameter("searched") != null) {
            String group = Validator.clean(req.getParameter("bloodGroup"));
            if (!Validator.isBloodGroup(group)) {
                group = "";
            }
            String city = Validator.clean(req.getParameter("city"));
            boolean onlyEligible = req.getParameter("eligible") != null;
            req.setAttribute("results", donorDAO.search(group, city, onlyEligible));
        }
        Web.forward(req, resp, "search");
    }

    private void submitRequest(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String name = Validator.clean(req.getParameter("requesterName"));
        String phone = Validator.clean(req.getParameter("phone"));
        String email = Validator.clean(req.getParameter("email"));
        String hospital = Validator.clean(req.getParameter("hospital"));
        String group = Validator.clean(req.getParameter("bloodGroup"));
        int units = Validator.parseInt(req.getParameter("units"), 0);
        String city = Validator.clean(req.getParameter("city"));
        String urgency = Validator.clean(req.getParameter("urgency"));
        String reason = Validator.clean(req.getParameter("reason"));

        List<String> errors = new ArrayList<>();
        if (!Validator.lengthBetween(name, 2, 80)) {
            errors.add("Name must be 2 to 80 characters long.");
        }
        if (!Validator.isPhone(phone)) {
            errors.add("Phone number must be exactly 10 digits.");
        }
        if (!email.isEmpty() && !Validator.isEmail(email)) {
            errors.add("Enter a valid email address or leave it blank.");
        }
        if (!Validator.lengthBetween(hospital, 2, 120)) {
            errors.add("Hospital name must be 2 to 120 characters long.");
        }
        if (!Validator.isBloodGroup(group)) {
            errors.add("Select the required blood group.");
        }
        if (units < 1 || units > 10) {
            errors.add("Units required must be between 1 and 10.");
        }
        if (!Validator.lengthBetween(city, 2, 60)) {
            errors.add("City must be 2 to 60 characters long.");
        }
        if (!Validator.URGENCY_LEVELS.contains(urgency)) {
            errors.add("Select an urgency level.");
        }
        if (reason.length() > 255) {
            errors.add("Reason can be at most 255 characters.");
        }

        if (!errors.isEmpty()) {
            req.setAttribute("errors", errors);
            Web.forward(req, resp, "request-form");
            return;
        }

        BloodRequest r = new BloodRequest();
        r.setRequesterName(name);
        r.setPhone(phone);
        r.setEmail(email);
        r.setHospital(hospital);
        r.setBloodGroup(group);
        r.setUnitsRequired(units);
        r.setCity(city);
        r.setUrgency(urgency);
        r.setReason(reason);
        int id = requestDAO.create(r);

        Web.flash(req, "success", "Request submitted. Your Request ID is #" + id
                + ". Keep it safe - you need it with your phone number to track the status.");
        Web.redirect(req, resp, "/request-status?id=" + id + "&phone=" + phone);
    }

    private void status(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        int id = Validator.parseInt(req.getParameter("id"), -1);
        String phone = Validator.clean(req.getParameter("phone"));
        if (id > 0 && Validator.isPhone(phone)) {
            req.setAttribute("lookupDone", true);
            req.setAttribute("bloodRequest", requestDAO.findByIdAndPhone(id, phone));
        } else if (req.getParameter("id") != null || req.getParameter("phone") != null) {
            req.setAttribute("error", "Enter a valid request ID and the 10-digit phone number used in the request.");
        }
        Web.forward(req, resp, "request-status");
    }
}
