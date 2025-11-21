package com.ulatina.basesdedatos2.tiendaonline.config;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

/**
 * Simple DB connection factory using the Singleton pattern (static method).
 *
 * Nota importante (uso académico):
 * - En un sistema real estos valores deben ir en variables de entorno
 *   o archivos de configuración, nunca en el código fuente.
 */
public final class Db {

    // Ajustar estos valores a la instancia local de SQL Server
    private static final String URL =
            "jdbc:sqlserver://localhost:1433;databaseName=tiendaonline;encrypt=false";
    private static final String USER = "app_user";       // login SQL asociado a rol app_rw
    private static final String PASS = "ChangeThis!123"; // contraseña demo

    private Db() {
        // Evita instancias
    }

    /**
     * Crea una nueva conexión JDBC a la base de datos tiendaonline.
     * El llamador es responsable de cerrar la conexión.
     */
    public static Connection getConnection() throws SQLException {
        return DriverManager.getConnection(URL, USER, PASS);
    }
}
