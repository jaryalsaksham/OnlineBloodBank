package com.bloodbank.dao;

import com.bloodbank.model.BloodStock;
import com.bloodbank.util.DBConnection;
import com.bloodbank.util.DataAccessException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;

public class StockDAO {

    public List<BloodStock> findAll() {
        String sql = "SELECT blood_group, units, updated_on FROM blood_stock ORDER BY FIELD(blood_group,"
                + "'A+','A-','B+','B-','AB+','AB-','O+','O-')";
        List<BloodStock> list = new ArrayList<>();
        try (Connection c = DBConnection.getConnection();
             Statement st = c.createStatement();
             ResultSet rs = st.executeQuery(sql)) {
            while (rs.next()) {
                BloodStock s = new BloodStock();
                s.setBloodGroup(rs.getString("blood_group"));
                s.setUnits(rs.getInt("units"));
                s.setUpdatedOn(rs.getTimestamp("updated_on"));
                list.add(s);
            }
            return list;
        } catch (SQLException e) {
            throw new DataAccessException(e);
        }
    }

    public int totalUnits() {
        try (Connection c = DBConnection.getConnection();
             Statement st = c.createStatement();
             ResultSet rs = st.executeQuery("SELECT COALESCE(SUM(units),0) FROM blood_stock")) {
            return rs.next() ? rs.getInt(1) : 0;
        } catch (SQLException e) {
            throw new DataAccessException(e);
        }
    }

    /** Admin correction: sets the exact number of units for one blood group. */
    public boolean setUnits(String bloodGroup, int units) {
        String sql = "UPDATE blood_stock SET units = ? WHERE blood_group = ?";
        try (Connection c = DBConnection.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, units);
            ps.setString(2, bloodGroup);
            return ps.executeUpdate() == 1;
        } catch (SQLException e) {
            throw new DataAccessException(e);
        }
    }

    // ---- helpers used inside other DAOs' transactions ----

    /** Reads the units of a group and locks the row until the transaction ends. */
    static int lockUnits(Connection c, String bloodGroup) throws SQLException {
        try (PreparedStatement ps = c.prepareStatement(
                "SELECT units FROM blood_stock WHERE blood_group = ? FOR UPDATE")) {
            ps.setString(1, bloodGroup);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt(1) : 0;
            }
        }
    }

    static void adjust(Connection c, String bloodGroup, int delta) throws SQLException {
        try (PreparedStatement ps = c.prepareStatement(
                "UPDATE blood_stock SET units = units + ? WHERE blood_group = ?")) {
            ps.setInt(1, delta);
            ps.setString(2, bloodGroup);
            ps.executeUpdate();
        }
    }
}
