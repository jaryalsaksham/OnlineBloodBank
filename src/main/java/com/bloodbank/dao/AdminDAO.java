package com.bloodbank.dao;

import com.bloodbank.model.Admin;
import com.bloodbank.util.DBConnection;
import com.bloodbank.util.DataAccessException;
import com.bloodbank.util.PasswordUtil;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

public class AdminDAO {

    /** Returns the admin when the credentials are valid, otherwise null. */
    public Admin authenticate(String username, String password) {
        String sql = "SELECT admin_id, username, full_name, password_hash FROM admins WHERE username = ?";
        try (Connection c = DBConnection.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, username);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next() && PasswordUtil.verify(password, rs.getString("password_hash"))) {
                    Admin a = new Admin();
                    a.setId(rs.getInt("admin_id"));
                    a.setUsername(rs.getString("username"));
                    a.setFullName(rs.getString("full_name"));
                    return a;
                }
                return null;
            }
        } catch (SQLException e) {
            throw new DataAccessException(e);
        }
    }
}
