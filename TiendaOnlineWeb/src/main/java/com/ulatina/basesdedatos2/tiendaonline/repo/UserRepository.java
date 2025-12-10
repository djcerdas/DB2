package com.ulatina.basesdedatos2.tiendaonline.repo;

import com.ulatina.basesdedatos2.tiendaonline.config.Db;
import com.ulatina.basesdedatos2.tiendaonline.model.User;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

/**
 * UserRepository
 *
 * Autenticación simple:
 * - Busca por email y password_hash en tabla dbo.users
 * - Obtiene el primer rol asignado en dbo.user_roles + dbo.roles
 */
public class UserRepository {

    private static final String SQL_LOGIN = """
        SELECT TOP (1)
            u.id,
            u.email,
            r.name AS role_name
        FROM dbo.users u
        JOIN dbo.user_roles ur ON ur.user_id = u.id
        JOIN dbo.roles r       ON r.id = ur.role_id
        WHERE u.email = ? AND u.password_hash = ? AND u.estado = 1
        ORDER BY r.name
        """;

    public UserRepository() {
        // Constructor vacío para ser usado desde App.java
    }

    /**
     * Autentica un usuario por email y contraseña en texto plano.
     * La contraseña se compara contra la columna password_hash (académico).
     */
    public User findByEmailAndPassword(String email, String passwordPlain) {
        try (Connection conn = Db.getConnection();
             PreparedStatement ps = conn.prepareStatement(SQL_LOGIN)) {

            ps.setString(1, email);
            ps.setString(2, passwordPlain);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    int id          = rs.getInt("id");
                    String em       = rs.getString("email");
                    String roleDb   = rs.getString("role_name");

                    // Normalizamos el rol para que coincida con tu switch en Routes
                    String appRole;
                    if ("OWNER".equalsIgnoreCase(roleDb)) {
                        appRole = "OWNER";
                    } else if ("GESTORINVENTARIO".equalsIgnoreCase(roleDb)) {
                        appRole = "GestorInventario";
                    } else if ("VENDEDOR".equalsIgnoreCase(roleDb)) {
                        appRole = "Vendedor";
                    } else if ("CLIENTE".equalsIgnoreCase(roleDb)) {
                        appRole = "Cliente";
                    } else if ("PROVEEDOR".equalsIgnoreCase(roleDb)) {
                        appRole = "Proveedor";
                    } else if ("MARKETING".equalsIgnoreCase(roleDb)) {
                        appRole = "Marketing";
                    } else {
                        // fallback por si se define algún rol nuevo
                        appRole = roleDb;
                    }

                    // Asumo que tu User tiene este constructor:
                    // User(int id, String email, String appRole)
                    return new User(id, em, appRole);
                }
            }
        } catch (Exception e) {
            // Aquí SÍ verías stacktrace si algo falla en login
            e.printStackTrace();
            throw new RuntimeException("Error en login: " + e.getMessage(), e);
        }
        return null;
    }
}
