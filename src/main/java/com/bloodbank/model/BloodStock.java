package com.bloodbank.model;

import java.sql.Timestamp;

public class BloodStock {

    /** Below this many units a blood group is flagged as low. */
    public static final int LOW_LEVEL = 10;
    /** Used to scale the bars on the stock chart. */
    public static final int BAR_MAX = 50;

    private String bloodGroup;
    private int units;
    private Timestamp updatedOn;

    public String getBloodGroup() { return bloodGroup; }
    public void setBloodGroup(String bloodGroup) { this.bloodGroup = bloodGroup; }
    public int getUnits() { return units; }
    public void setUnits(int units) { this.units = units; }
    public Timestamp getUpdatedOn() { return updatedOn; }
    public void setUpdatedOn(Timestamp updatedOn) { this.updatedOn = updatedOn; }

    public boolean isLow() {
        return units < LOW_LEVEL;
    }

    /** Bar width in percent (0-100). */
    public int getPercent() {
        return Math.min(100, units * 100 / BAR_MAX);
    }

    public String getLevel() {
        if (units == 0) return "empty";
        return isLow() ? "low" : "ok";
    }
}
