package com.bloodbank.dao;

import com.bloodbank.model.Donor;
import com.bloodbank.util.DBConnection;
import com.bloodbank.util.DataAccessException;
import com.bloodbank.util.PasswordUtil;
import com.bloodbank.util.Validator;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;

public class DonorDAO {

    private static final String ELIGIBLE_CLAUSE =
            " AND (last_donation_date IS NULL OR last_donation_date <= DATE_SUB(CURDATE(), INTERVAL "
            + Donor.GAP_DAYS + " DAY))"
            + " AND TIMESTAMPDIFF(YEAR, dob, CURDATE()) BETWEEN 18 AND 65";

    public boolean emailExists(String email) {
        String sql = "SELECT 1 FROM donors WHERE email = ?";
        try (Connection c = DBConnection.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, email.toLowerCase());
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        } catch (SQLException e) {
            throw new DataAccessException(e);
        }
    }

    /** Inserts a new donor; returns the generated id. */
    public int create(Donor d, String plainPassword) {
        String sql = "INSERT INTO donors (full_name, email, password_hash, phone, gender, dob, blood_group, city) "
                + "VALUES (?,?,?,?,?,?,?,?)";
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setString(1, d.getFullName());
            ps.setString(2, d.getEmail().toLowerCase());
            ps.setString(3, PasswordUtil.hash(plainPassword));
            ps.setString(4, d.getPhone());
            ps.setString(5, d.getGender());
            ps.setDate(6, d.getDob());
            ps.setString(7, d.getBloodGroup());
            ps.setString(8, d.getCity());
            ps.executeUpdate();
            try (ResultSet keys = ps.getGeneratedKeys()) {
                return keys.next() ? keys.getInt(1) : 0;
            }
        } catch (SQLException e) {
            throw new DataAccessException(e);
        }
    }

    /** Returns the donor if email/password are right and the account is active, otherwise null. */
    public Donor authenticate(String email, String password) {
        String sql = "SELECT * FROM donors WHERE email = ? AND is_active = 1";
        try (Connection c = DBConnection.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, email.toLowerCase());
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next() && PasswordUtil.verify(password, rs.getString("password_hash"))) {
                    return mapRow(rs);
                }
                return null;
            }
        } catch (SQLException e) {
            throw new DataAccessException(e);
        }
    }

    public Donor findById(int id) {
        String sql = "SELECT * FROM donors WHERE donor_id = ?";
        try (Connection c = DBConnection.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? mapRow(rs) : null;
            }
        } catch (SQLException e) {
            throw new DataAccessException(e);
        }
    }

    /** Public donor search (active donors only). All filters are optional. */
    public List<Donor> search(String bloodGroup, String city, boolean onlyEligible) {
        StringBuilder sql = new StringBuilder("SELECT * FROM donors WHERE is_active = 1");
        List<Object> args = new ArrayList<>();
        if (!Validator.isBlank(bloodGroup)) {
            sql.append(" AND blood_group = ?");
            args.add(bloodGroup);
        }
        if (!Validator.isBlank(city)) {
            sql.append(" AND city LIKE ?");
            args.add("%" + city.trim() + "%");
        }
        if (onlyEligible) {
            sql.append(ELIGIBLE_CLAUSE);
        }
        sql.append(" ORDER BY full_name");
        return query(sql.toString(), args);
    }

    /** All donors for the admin screen, optionally filtered by blood group. */
    public List<Donor> findAll(String bloodGroup) {
        if (Validator.isBlank(bloodGroup)) {
            return query("SELECT * FROM donors ORDER BY registered_on DESC", new ArrayList<>());
        }
        List<Object> args = new ArrayList<>();
        args.add(bloodGroup);
        return query("SELECT * FROM donors WHERE blood_group = ? ORDER BY registered_on DESC", args);
    }

    /** Donor updates their own profile (email and blood group are fixed). */
    public boolean updateProfile(Donor d) {
        String sql = "UPDATE donors SET full_name = ?, phone = ?, gender = ?, dob = ?, city = ? WHERE donor_id = ?";
        try (Connection c = DBConnection.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, d.getFullName());
            ps.setString(2, d.getPhone());
            ps.setString(3, d.getGender());
            ps.setDate(4, d.getDob());
            ps.setString(5, d.getCity());
            ps.setInt(6, d.getId());
            return ps.executeUpdate() == 1;
        } catch (SQLException e) {
            throw new DataAccessException(e);
        }
    }

    /** Verifies the current password, then stores the new one. */
    public boolean changePassword(int donorId, String currentPassword, String newPassword) {
        String select = "SELECT password_hash FROM donors WHERE donor_id = ?";
        String update = "UPDATE donors SET password_hash = ? WHERE donor_id = ?";
        try (Connection c = DBConnection.getConnection()) {
            try (PreparedStatement ps = c.prepareStatement(select)) {
                ps.setInt(1, donorId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next() || !PasswordUtil.verify(currentPassword, rs.getString(1))) {
                        return false;
                    }
                }
            }
            try (PreparedStatement ps = c.prepareStatement(update)) {
                ps.setString(1, PasswordUtil.hash(newPassword));
                ps.setInt(2, donorId);
                return ps.executeUpdate() == 1;
            }
        } catch (SQLException e) {
            throw new DataAccessException(e);
        }
    }

    public boolean setActive(int donorId, boolean active) {
        String sql = "UPDATE donors SET is_active = ? WHERE donor_id = ?";
        try (Connection c = DBConnection.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setBoolean(1, active);
            ps.setInt(2, donorId);
            return ps.executeUpdate() == 1;
        } catch (SQLException e) {
            throw new DataAccessException(e);
        }
    }

    public boolean delete(int donorId) {
        String sql = "DELETE FROM donors WHERE donor_id = ?";
        try (Connection c = DBConnection.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, donorId);
            return ps.executeUpdate() == 1;
        } catch (SQLException e) {
            throw new DataAccessException(e);
        }
    }

    public int countActive() {
        return count("SELECT COUNT(*) FROM donors WHERE is_active = 1");
    }

    public int countEligible() {
        return count("SELECT COUNT(*) FROM donors WHERE is_active = 1" + ELIGIBLE_CLAUSE);
    }

    // ------------------------------------------------------------------

    private int count(String sql) {
        try (Connection c = DBConnection.getConnection();
             Statement st = c.createStatement();
             ResultSet rs = st.executeQuery(sql)) {
            return rs.next() ? rs.getInt(1) : 0;
        } catch (SQLException e) {
            throw new DataAccessException(e);
        }
    }

    private List<Donor> query(String sql, List<Object> args) {
        List<Donor> list = new ArrayList<>();
        try (Connection c = DBConnection.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            for (int i = 0; i < args.size(); i++) {
                ps.setObject(i + 1, args.get(i));
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

    private static Donor mapRow(ResultSet rs) throws SQLException {
        Donor d = new Donor();
        d.setId(rs.getInt("donor_id"));
        d.setFullName(rs.getString("full_name"));
        d.setEmail(rs.getString("email"));
        d.setPhone(rs.getString("phone"));
        d.setGender(rs.getString("gender"));
        d.setDob(rs.getDate("dob"));
        d.setBloodGroup(rs.getString("blood_group"));
        d.setCity(rs.getString("city"));
        d.setLastDonationDate(rs.getDate("last_donation_date"));
        d.setRegisteredOn(rs.getTimestamp("registered_on"));
        d.setActive(rs.getBoolean("is_active"));
        return d;
    }
}
