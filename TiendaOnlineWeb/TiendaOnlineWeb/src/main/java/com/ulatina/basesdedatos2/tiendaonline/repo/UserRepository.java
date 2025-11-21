package com.ulatina.basesdedatos2.tiendaonline.repo;

import com.ulatina.basesdedatos2.tiendaonline.config.Db;
import com.ulatina.basesdedatos2.tiendaonline.model.User;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Optional;

/**
 * Repository for application users and their roles.
 *
 * This repository is intentionally simple and authenticates by email
 * and plain text password (ONLY for academic purposes).
 *
 * It is aligned with the seed data in 02_tiendaonline_seed.sql.
 */
public class UserRepository {

    /**
     * Finds a user by email and password, returning its role as well.
     * Password is stored in password_hash column.
     */
    public Optional<User> findByEmailAndPassword(String email, String password) {

        String sql = "SELECT TOP(1) u.id, u.email, r.name AS role_name " +
                     "FROM dbo.users u " +
                     "JOIN dbo.user_roles ur ON ur.user_id = u.id " +
                     "JOIN dbo.roles r ON r.id = ur.role_id " +
                     "WHERE u.email = ? AND u.password_hash = ? AND u.estado = 1";

        try (Connection conn = Db.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, email);
            ps.setString(2, password);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    User user = new User(
                            rs.getInt("id"),
                            rs.getString("email"),
                            rs.getString("role_name")
                    );
                    return Optional.of(user);
                }
            }

        } catch (SQLException ex) {
            ex.printStackTrace();
        }

        return Optional.empty();
    }
}
