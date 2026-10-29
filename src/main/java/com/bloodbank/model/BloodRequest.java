package com.bloodbank.model;

import java.sql.Timestamp;

public class BloodRequest {

    private int id;
    private String requesterName;
    private String phone;
    private String email;
    private String hospital;
    private String bloodGroup;
    private int unitsRequired;
    private String city;
    private String urgency;
    private String reason;
    private String status;
    private String adminRemarks;
    private Timestamp requestedOn;
    private Timestamp processedOn;

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }
    public String getRequesterName() { return requesterName; }
    public void setRequesterName(String requesterName) { this.requesterName = requesterName; }
    public String getPhone() { return phone; }
    public void setPhone(String phone) { this.phone = phone; }
    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }
    public String getHospital() { return hospital; }
    public void setHospital(String hospital) { this.hospital = hospital; }
    public String getBloodGroup() { return bloodGroup; }
    public void setBloodGroup(String bloodGroup) { this.bloodGroup = bloodGroup; }
    public int getUnitsRequired() { return unitsRequired; }
    public void setUnitsRequired(int unitsRequired) { this.unitsRequired = unitsRequired; }
    public String getCity() { return city; }
    public void setCity(String city) { this.city = city; }
    public String getUrgency() { return urgency; }
    public void setUrgency(String urgency) { this.urgency = urgency; }
    public String getReason() { return reason; }
    public void setReason(String reason) { this.reason = reason; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public String getAdminRemarks() { return adminRemarks; }
    public void setAdminRemarks(String adminRemarks) { this.adminRemarks = adminRemarks; }
    public Timestamp getRequestedOn() { return requestedOn; }
    public void setRequestedOn(Timestamp requestedOn) { this.requestedOn = requestedOn; }
    public Timestamp getProcessedOn() { return processedOn; }
    public void setProcessedOn(Timestamp processedOn) { this.processedOn = processedOn; }
}
