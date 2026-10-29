package com.bloodbank.dao;

import com.bloodbank.model.Donation;
import com.bloodbank.util.DBConnection;
import com.bloodbank.util.DataAccessException;
import com.bloodbank.util.Validator;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;

public class DonationDAO {

    private static final String SELECT_WITH_DONOR =
            "SELECT d.donation_id, d.donor_id, n.full_name, d.blood_group, d.units, d.donation_date, d.notes "
            + "FROM donations d JOIN donors n ON n.donor_id = d.donor_id ";

    /**
     * Records a donation: inserts the history row, adds the units to stock and updates the
     * donor's last-donation date, all in one transaction.
     * @return null on success, otherwise a message explaining why it failed
     */
    public String record(int donorId, int units, Date donationDate, String notes) {
        try (Connection c = DBConnection.getConnection()) {
            c.setAutoCommit(false);
            try {
                String group;
                try (PreparedStatement ps = c.prepareStatement(
                        "SELECT blood_group, is_active FROM donors WHERE donor_id = ? FOR UPDATE")) {
                    ps.setInt(1, donorId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) {
                            c.rollback();
                            return "Donor not found.";
                        }
                        if (!rs.getBoolean("is_active")) {
                            c.rollback();
                            return "This donor account is deactivated.";
                        }
                        group = rs.getString("blood_group");
                    }
                }
                try (PreparedStatement ps = c.prepareStatement(
                        "INSERT INTO donations (donor_id, blood_group, units, donation_date, notes) VALUES (?,?,?,?,?)")) {
                    ps.setInt(1, donorId);
                    ps.setString(2, group);
                    ps.setInt(3, units);
                    ps.setDate(4, donationDate);
                    ps.setString(5, Validator.isBlank(notes) ? null : notes);
                    ps.executeUpdate();
                }
                StockDAO.adjust(c, group, units);
                try (PreparedStatement ps = c.prepareStatement(
                        "UPDATE donors SET last_donation_date = CASE WHEN last_donation_date IS NULL "
                        + "OR last_donation_date < ? THEN ? ELSE last_donation_date END WHERE donor_id = ?")) {
                    ps.setDate(1, donationDate);
                    ps.setDate(2, donationDate);
                    ps.setInt(3, donorId);
                    ps.executeUpdate();
                }
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

    public List<Donation> findAll() {
        return query(SELECT_WITH_DONOR + "ORDER BY d.donation_date DESC, d.donation_id DESC", -1);
    }

    public List<Donation> findByDonor(int donorId) {
        return query(SELECT_WITH_DONOR + "WHERE d.donor_id = ? ORDER BY d.donation_date DESC", donorId);
    }

    public int count() {
        return scalar("SELECT COUNT(*) FROM donations");
    }

    public int totalUnits() {
        return scalar("SELECT COALESCE(SUM(units),0) FROM donations");
    }

    // ------------------------------------------------------------------

    private int scalar(String sql) {
        try (Connection c = DBConnection.getConnection();
             Statement st = c.createStatement();
             ResultSet rs = st.executeQuery(sql)) {
            return rs.next() ? rs.getInt(1) : 0;
        } catch (SQLException e) {
            throw new DataAccessException(e);
        }
    }

    private List<Donation> query(String sql, int donorId) {
        List<Donation> list = new ArrayList<>();
        try (Connection c = DBConnection.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            if (donorId >= 0) {
                ps.setInt(1, donorId);
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Donation d = new Donation();
                    d.setId(rs.getInt("donation_id"));
                    d.setDonorId(rs.getInt("donor_id"));
                    d.setDonorName(rs.getString("full_name"));
                    d.setBloodGroup(rs.getString("blood_group"));
                    d.setUnits(rs.getInt("units"));
                    d.setDonationDate(rs.getDate("donation_date"));
                    d.setNotes(rs.getString("notes"));
                    list.add(d);
                }
            }
            return list;
        } catch (SQLException e) {
            throw new DataAccessException(e);
        }
    }
}
