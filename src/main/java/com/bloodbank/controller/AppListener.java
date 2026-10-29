package com.bloodbank.controller;

import com.bloodbank.util.Validator;
import jakarta.servlet.ServletContextEvent;
import jakarta.servlet.ServletContextListener;
import jakarta.servlet.annotation.WebListener;

/** Publishes lists used by many JSP dropdowns (application scope). */
@WebListener
public class AppListener implements ServletContextListener {

    @Override
    public void contextInitialized(ServletContextEvent sce) {
        sce.getServletContext().setAttribute("bloodGroups", Validator.BLOOD_GROUPS);
        sce.getServletContext().setAttribute("urgencyLevels", Validator.URGENCY_LEVELS);
    }

    @Override
    public void contextDestroyed(ServletContextEvent sce) {
        // nothing to clean up
    }
}
