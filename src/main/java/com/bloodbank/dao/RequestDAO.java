package com.bloodbank.dao;

import com.bloodbank.model.BloodRequest;
import com.bloodbank.util.DBConnection;
import com.bloodbank.util.DataAccessException;
import com.bloodbank.util.Validator;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public class RequestDAO {

    /** Inserts a new PENDING request and returns its id. */
    public int create(BloodRequest r) {
        String sql = "INSERT INTO blood_requests (requester_name, phone, email, hospital, blood_group, "
                + "units_required, city, urgency, reason) VALUES (?,?,?,?,?,?,?,?,?)";
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setString(1, r.getRequesterName());
            ps.setString(2, r.getPhone());
            ps.setString(3, Validator.isBlank(r.getEmail()) ? null : r.getEmail());
            ps.setString(4, r.getHospital());
            ps.setString(5, r.getBloodGroup());
            ps.setInt(6, r.getUnitsRequired());
            ps.setString(7, r.getCity());
            ps.setString(8, r.getUrgency());
            ps.setString(9, Validator.isBlank(r.getReason()) ? null : r.getReason());
            ps.executeUpdate();
            try (ResultSet keys = ps.getGeneratedKeys()) {
                return keys.next() ? keys.getInt(1) : 0;
            }
        } catch (SQLException e) {
            throw new DataAccessException(e);
        }
    }

    /** Public status lookup: the request id must be paired with the phone number used to submit it. */
    public BloodRequest findByIdAndPhone(int id, String phone) {
        String sql = "SELECT * FROM blood_requests WHERE request_id = ? AND phone = ?";
        try (Connection c = DBConnection.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, id);
            ps.setString(2, phone);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? mapRow(rs) : null;
            }
        } catch (SQLException e) {
            throw new DataAccessException(e);
        }
    }

    /** status = null or blank returns every request. Urgent ones come first. */
    public List<BloodRequest> findAll(String status) {
        boolean filtered = !Validator.isBlank(status);
        String sql = "SELECT * FROM blood_requests" + (filtered ? " WHERE status = ?" : "")
                + " ORDER BY FIELD(status,'PENDING','APPROVED','FULFILLED','REJECTED'),"
                + " FIELD(urgency,'CRITICAL','URGENT','NORMAL'), requested_on DESC";
        List<BloodRequest> list = new ArrayList<>();
        try (Connection c = DBConnection.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            if (filtered) {
                ps.setString(1, status);
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(mapRow(rs));
                }
            }
            return list;
        } catch (SQLException e) {
            throw new DataAccessException(e);
        }
    }

    /** Count of requests per status (always contains all four keys). */
    public Map<String, Integer> countByStatus() {
        Map<String, Integer> map = new LinkedHashMap<>();
        map.put("PENDING", 0);
        map.put("APPROVED", 0);
        map.put("FULFILLED", 0);
        map.put("REJECTED", 0);
        try (Connection c = DBConnection.getConnection();
             Statement st = c.createStatement();
             ResultSet rs = st.executeQuery("SELECT status, COUNT(*) FROM blood_requests GROUP BY status")) {
            while (rs.next()) {
                map.put(rs.getString(1), rs.getInt(2));
            }
            return map;
        } catch (SQLException e) {
            throw new DataAccessException(e);
        }
    }

    /**
     * Approves a pending request and deducts the units from stock in one transaction.
     * @return null on success, otherwise a message explaining why it failed
     */
    public String approve(int id, String remarks) {
        try (Connection c = DBConnection.getConnection()) {
            c.setAutoCommit(false);
            try {
                String group;
                int units;
                try (PreparedStatement ps = c.prepareStatement(
                        "SELECT blood_group, units_required, status FROM blood_requests "
                        + "WHERE request_id = ? FOR UPDATE")) {
                    ps.setInt(1, id);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) {
                            c.rollback();
                            return "Request not found.";
                        }
                        if (!"PENDING".equals(rs.getString("status"))) {
                            c.rollback();
                            return "Only pending requests can be approved.";
                        }
                        group = rs.getString("blood_group");
                        units = rs.getInt("units_required");
                    }
                }
                int available = StockDAO.lockUnits(c, group);
                if (available < units) {
                    c.rollback();
                    return "Not enough stock: only " + available + " unit(s) of " + group + " available.";
                }
                StockDAO.adjust(c, group, -units);
                updateStatus(c, id, "APPROVED", remarks);
                c.commit();
                return null;
            } catch (SQLException e) {
                c.rollback();
                throw e;
            }
        } catch (SQLException e) {
            throw new DataAccessException(e);
        }
    }

    /** Rejects a pending request (no stock change). Returns null on success. */
    public String reject(int id, String remarks) {
        return transition(id, "PENDING", "REJECTED", remarks, "Only pending requests can be rejected.");
    }

    /** Marks an approved request as handed over. Returns null on success. */
    public String fulfill(int id, String remarks) {
        return transition(id, "APPROVED", "FULFILLED", remarks, "Only approved requests can be marked fulfilled.");
    }

    // ------------------------------------------------------------------

    private String transition(int id, String from, String to, String remarks, String wrongStateMessage) {
        String sql = "UPDATE blood_requests SET status = ?, admin_remarks = ?, processed_on = NOW() "
                + "WHERE request_id = ? AND status = ?";
        try (Connection c = DBConnection.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, to);
            ps.setString(2, Validator.isBlank(remarks) ? null : remarks);
            ps.setInt(3, id);
            ps.setString(4, from);
            return ps.executeUpdate() == 1 ? null : wrongStateMessage;
        } catch (SQLException e) {
            throw new DataAccessException(e);
        }
    }

    private static void updateStatus(Connection c, int id, String status, String remarks) throws SQLException {
        try (PreparedStatement ps = c.prepareStatement(
                "UPDATE blood_requests SET status = ?, admin_remarks = ?, processed_on = NOW() WHERE request_id = ?")) {
            ps.setString(1, status);
            ps.setString(2, Validator.isBlank(remarks) ? null : remarks);
            ps.setInt(3, id);
            ps.executeUpdate();
        }
    }

    private static BloodRequest mapRow(ResultSet rs) throws SQLException {
        BloodRequest r = new BloodRequest();
        r.setId(rs.getInt("request_id"));
        r.setRequesterName(rs.getString("requester_name"));
        r.setPhone(rs.getString("phone"));
        r.setEmail(rs.getString("email"));
        r.setHospital(rs.getString("hospital"));
        r.setBloodGroup(rs.getString("blood_group"));
        r.setUnitsRequired(rs.getInt("units_required"));
        r.setCity(rs.getString("city"));
        r.setUrgency(rs.getString("urgency"));
        r.setReason(rs.getString("reason"));
        r.setStatus(rs.getString("status"));
        r.setAdminRemarks(rs.getString("admin_remarks"));
        r.setRequestedOn(rs.getTimestamp("requested_on"));
        r.setProcessedOn(rs.getTimestamp("processed_on"));
        return r;
    }
}
