package com.bloodbank.model;

import java.sql.Date;
import java.sql.Timestamp;
import java.time.LocalDate;
import java.time.Period;

public class Donor {

    /** Minimum gap between two whole-blood donations, in days. */
    public static final int GAP_DAYS = 90;

    private int id;
    private String fullName;
    private String email;
    private String phone;
    private String gender;
    private Date dob;
    private String bloodGroup;
    private String city;
    private Date lastDonationDate;
    private Timestamp registeredOn;
    private boolean active;

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }
    public String getFullName() { return fullName; }
    public void setFullName(String fullName) { this.fullName = fullName; }
    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }
    public String getPhone() { return phone; }
    public void setPhone(String phone) { this.phone = phone; }
    public String getGender() { return gender; }
    public void setGender(String gender) { this.gender = gender; }
    public Date getDob() { return dob; }
    public void setDob(Date dob) { this.dob = dob; }
    public String getBloodGroup() { return bloodGroup; }
    public void setBloodGroup(String bloodGroup) { this.bloodGroup = bloodGroup; }
    public String getCity() { return city; }
    public void setCity(String city) { this.city = city; }
    public Date getLastDonationDate() { return lastDonationDate; }
    public void setLastDonationDate(Date lastDonationDate) { this.lastDonationDate = lastDonationDate; }
    public Timestamp getRegisteredOn() { return registeredOn; }
    public void setRegisteredOn(Timestamp registeredOn) { this.registeredOn = registeredOn; }
    public boolean isActive() { return active; }
    public void setActive(boolean active) { this.active = active; }

    // ---- derived values (used directly from JSP via EL) ----

    public int getAge() {
        return dob == null ? 0 : Period.between(dob.toLocalDate(), LocalDate.now()).getYears();
    }

    public String getGenderLabel() {
        if ("M".equals(gender)) return "Male";
        if ("F".equals(gender)) return "Female";
        return "Other";
    }

    /** Date from which the donor may donate again (null if never donated). */
    public Date getNextEligibleDate() {
        return lastDonationDate == null ? null : Date.valueOf(lastDonationDate.toLocalDate().plusDays(GAP_DAYS));
    }

    public boolean isEligibleOn(LocalDate day) {
        int ageOnDay = dob == null ? 0 : Period.between(dob.toLocalDate(), day).getYears();
        boolean ageOk = ageOnDay >= 18 && ageOnDay <= 65;
        boolean gapOk = lastDonationDate == null
                || !day.isBefore(lastDonationDate.toLocalDate().plusDays(GAP_DAYS));
        return ageOk && gapOk;
    }

    public boolean isEligible() {
        return isEligibleOn(LocalDate.now());
    }

    /** e.g. 98XXXXXX01 - shown to visitors who are not logged in. */
    public String getMaskedPhone() {
        if (phone == null || phone.length() < 4) return "XXXXXXXXXX";
        return phone.substring(0, 2) + "XXXXXX" + phone.substring(phone.length() - 2);
    }
}
