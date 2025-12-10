package com.ulatina.basesdedatos2.tiendaonline.config;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.Properties;

/**
 * Db
 *
 * Encapsula la conexión JDBC a SQL Server.
 * - Lee la URL y el driver de application.properties (classpath).
 * - Lee usuario y contraseña de un archivo de texto fuera del classpath
 *   (config/db_credentials.txt por defecto).
 *
 * Formato esperado de db_credentials.txt:
 *
 *   db.username=app_user
 *   db.password=SuClaveSecreta
 */
public class Db {

    private static final String PROPERTIES_FILE = "/application.properties";

    private static String url;
    private static String driver;
    private static String credentialsFilePath;

    private static String username;
    private static String password;

    static {
        loadConfiguration();
        loadCredentials();
    }

    private static void loadConfiguration() {
        try {
            Properties props = new Properties();
            try (var in = Db.class.getResourceAsStream(PROPERTIES_FILE)) {
                if (in == null) {
                    throw new IllegalStateException("No se encontró application.properties en el classpath");
                }
                props.load(in);
            }
            url = props.getProperty("db.url");
            driver = props.getProperty("db.driver");
            credentialsFilePath = props.getProperty("db.credentials.file", "config/db_credentials.txt");

            Class.forName(driver);
        } catch (Exception e) {
            throw new RuntimeException("Error cargando configuración de DB: " + e.getMessage(), e);
        }
    }

    private static void loadCredentials() {
        File file = new File(credentialsFilePath);
        if (!file.exists()) {
            System.err.println("[WARN] No se encontró " + credentialsFilePath +
                    ". Cree el archivo copiando config/db_credentials.sample.txt");
            username = "app_user";
            password = "ChangeThis!123";
            return;
        }

        Properties props = new Properties();
        try (BufferedReader reader = new BufferedReader(new FileReader(file))) {
            String line;
            while ((line = reader.readLine()) != null) {
                line = line.strip();
                if (line.isEmpty() || line.startsWith("#")) {
                    continue;
                }
                int idx = line.indexOf('=');
                if (idx > 0) {
                    String key = line.substring(0, idx).strip();
                    String value = line.substring(idx + 1).strip();
                    props.setProperty(key, value);
                }
            }
        } catch (IOException e) {
            throw new RuntimeException("Error leyendo credenciales DB: " + e.getMessage(), e);
        }

        username = "app_user";
        password = "ChangeThis!123";
    }

    public static Connection getConnection() throws SQLException {
        if (username == null || username.isBlank()) {
            throw new IllegalStateException("db.username no configurado. Revise config/db_credentials.txt");
        }
        return DriverManager.getConnection(url, username, password);
    }
}
