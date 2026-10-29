package com.bloodbank.filter;

import com.bloodbank.util.Web;
import java.io.IOException;
import java.security.SecureRandom;
import jakarta.servlet.Filter;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletRequest;
import jakarta.servlet.ServletResponse;
import jakarta.servlet.annotation.WebFilter;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

/**
 * One filter for all cross-cutting concerns:
 *  1. UTF-8 request encoding and basic security headers
 *  2. CSRF protection (every POST must carry the session's "csrf" token)
 *  3. Access control for /admin/* (admin session) and /donor/* (donor session)
 */
@WebFilter(filterName = "SecurityFilter", urlPatterns = "/*")
public class SecurityFilter implements Filter {

    private static final SecureRandom RANDOM = new SecureRandom();

    @Override
    public void doFilter(ServletRequest servletReq, ServletResponse servletResp, FilterChain chain)
            throws IOException, ServletException {
        HttpServletRequest req = (HttpServletRequest) servletReq;
        HttpServletResponse resp = (HttpServletResponse) servletResp;

        req.setCharacterEncoding("UTF-8");
        String path = req.getRequestURI().substring(req.getContextPath().length());

        // Static files need no session, token or login.
        if (path.startsWith("/assets/")) {
            chain.doFilter(req, resp);
            return;
        }

        resp.setHeader("X-Content-Type-Options", "nosniff");
        resp.setHeader("X-Frame-Options", "DENY");
        resp.setHeader("Referrer-Policy", "same-origin");

        HttpSession session = req.getSession(true);
        if (session.getAttribute("csrf") == null) {
            session.setAttribute("csrf", newToken());
        }

        if ("POST".equalsIgnoreCase(req.getMethod())) {
            String sent = req.getParameter("csrf");
            if (sent == null || !sent.equals(session.getAttribute("csrf"))) {
                resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Invalid or missing security token");
                return;
            }
        }

        if (isUnder(path, "/admin") && session.getAttribute("admin") == null) {
            Web.flash(req, "error", "Please log in as administrator.");
            Web.redirect(req, resp, "/admin-login");
            return;
        }
        if (isUnder(path, "/donor") && session.getAttribute("donor") == null) {
            Web.flash(req, "error", "Please log in to continue.");
            Web.redirect(req, resp, "/login");
            return;
        }

        chain.doFilter(req, resp);
    }

    private static boolean isUnder(String path, String prefix) {
        return path.equals(prefix) || path.startsWith(prefix + "/");
    }

    private static String newToken() {
        byte[] bytes = new byte[24];
        RANDOM.nextBytes(bytes);
        StringBuilder sb = new StringBuilder();
        for (byte b : bytes) {
            sb.append(String.format("%02x", b));
        }
        return sb.toString();
    }
}
