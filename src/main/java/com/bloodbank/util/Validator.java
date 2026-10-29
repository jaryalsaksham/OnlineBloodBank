package com.bloodbank.util;

import java.sql.Date;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.regex.Pattern;

/** Small collection of server-side validation helpers. */
public final class Validator {

    public static final List<String> BLOOD_GROUPS = Collections.unmodifiableList(
            Arrays.asList("A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"));

    public static final List<String> URGENCY_LEVELS = Collections.unmodifiableList(
            Arrays.asList("NORMAL", "URGENT", "CRITICAL"));

    private static final Pattern EMAIL = Pattern.compile("^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$");
    private static final Pattern PHONE = Pattern.compile("^[0-9]{10}$");

    private Validator() {
    }

    /** Null-safe trim; returns an empty string for null. */
    public static String clean(String s) {
        return s == null ? "" : s.trim();
    }

    public static boolean isBlank(String s) {
        return s == null || s.trim().isEmpty();
    }

    public static boolean isEmail(String s) {
        return s != null && s.length() <= 100 && EMAIL.matcher(s).matches();
    }

    public static boolean isPhone(String s) {
        return s != null && PHONE.matcher(s).matches();
    }

    public static boolean isBloodGroup(String s) {
        return BLOOD_GROUPS.contains(s);
    }

    public static boolean isGender(String s) {
        return "M".equals(s) || "F".equals(s) || "O".equals(s);
    }

    public static boolean lengthBetween(String s, int min, int max) {
        return s != null && s.length() >= min && s.length() <= max;
    }

    /** Parses yyyy-MM-dd; returns null when invalid. */
    public static Date parseDate(String s) {
        try {
            return isBlank(s) ? null : Date.valueOf(LocalDate.parse(s.trim()));
        } catch (DateTimeParseException e) {
            return null;
        }
    }

    public static int parseInt(String s, int fallback) {
        try {
            return Integer.parseInt(s.trim());
        } catch (NumberFormatException | NullPointerException e) {
            return fallback;
        }
    }
}
