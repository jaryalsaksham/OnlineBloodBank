package com.bloodbank.util;

import java.io.IOException;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

/** Helpers shared by the servlets: view forwarding, redirects and flash messages. */
public final class Web {

    private Web() {
    }

    /** Forwards to /WEB-INF/views/{view}.jsp */
    public static void forward(HttpServletRequest req, HttpServletResponse resp, String view)
            throws ServletException, IOException {
        req.getRequestDispatcher("/WEB-INF/views/" + view + ".jsp").forward(req, resp);
    }

    /** Redirects to an application-relative path such as "/login". */
    public static void redirect(HttpServletRequest req, HttpServletResponse resp, String path) throws IOException {
        resp.sendRedirect(req.getContextPath() + path);
    }

    /** Stores a one-time message shown by header.jsp on the next page. type: success | error | info */
    public static void flash(HttpServletRequest req, String type, String message) {
        req.getSession().setAttribute("flashType", type);
        req.getSession().setAttribute("flash", message);
    }
}
