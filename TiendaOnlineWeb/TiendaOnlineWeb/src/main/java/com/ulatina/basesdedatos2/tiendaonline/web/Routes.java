package com.ulatina.basesdedatos2.tiendaonline.web;

import static spark.Spark.*;

import com.google.gson.Gson;
import com.ulatina.basesdedatos2.tiendaonline.model.User;
import com.ulatina.basesdedatos2.tiendaonline.repo.ProductRepository;
import com.ulatina.basesdedatos2.tiendaonline.repo.SqlServerProductRepository;
import com.ulatina.basesdedatos2.tiendaonline.repo.UserRepository;
import com.ulatina.basesdedatos2.tiendaonline.service.AuthService;
import com.ulatina.basesdedatos2.tiendaonline.service.DbTestService;
import com.ulatina.basesdedatos2.tiendaonline.service.InventoryService;

import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

/**
 * Defines HTTP routes using Spark Java.
 *
 * This class acts as the "Controller" in a simplified MVC:
 *  - Routes: controller
 *  - Services/Repositories: model/business logic
 *  - Static HTML pages: view
 *
 * It also exposes endpoints that allow each role to trigger
 * database tests (stored procedures, inventory aging, sales, etc.).
 */
public class Routes {

    private static final Gson gson = new Gson();

    public static void start() {
        port(8080);

        // Serve static files from src/main/resources/public
        staticFiles.location("/public");

        ProductRepository productRepo = new SqlServerProductRepository();
        InventoryService inventoryService = new InventoryService(productRepo);

        UserRepository userRepository = new UserRepository();
        AuthService authService = new AuthService(userRepository);

        DbTestService dbTestService = new DbTestService();

        // Home: redirect to login page
        get("/", (req, res) -> {
            res.redirect("/login.html");
            return null;
        });

        // API: login endpoint
        post("/login", (req, res) -> {
            String email = req.queryParams("email");
            String password = req.queryParams("password");

            Optional<User> userOpt = authService.login(email, password);

            if (userOpt.isEmpty()) {
                res.status(401);
                return "Credenciales inválidas";
            }

            User user = userOpt.get();
            // Store user info in the session
            req.session(true).attribute("user", user);

            switch (user.getRoleName()) {
                case "OWNER":
                    res.redirect("/owner.html");
                    break;
                case "GESTORINVENTARIO":
                    res.redirect("/gestor.html");
                    break;
                case "VENDEDOR":
                    res.redirect("/vendedor.html");
                    break;
                case "CLIENTE":
                    res.redirect("/cliente.html");
                    break;
                default:
                    res.redirect("/login.html");
            }
            return null;
        });

        // API: logout
        get("/logout", (req, res) -> {
            req.session().invalidate();
            res.redirect("/login.html");
            return null;
        });

        // API: catalog (JSON) – available to authenticated users
        get("/api/catalogo", "application/json", (req, res) -> {
            User user = req.session().attribute("user");
            if (user == null) {
                res.status(401);
                return "No autenticado";
            }
            res.type("application/json");
            return inventoryService.getCatalog();
        }, gson::toJson);

        // ---------------------------
        // API: TESTS POR ROL
        // ---------------------------

        post("/api/tests/owner/registrar-producto", "application/json", (req, res) -> {
            User user = req.session().attribute("user");
            if (!hasRole(user, "OWNER")) {
                res.status(403);
                return "Acceso denegado";
            }
            String msg = dbTestService.runDemoRegisterProduct();
            return buildMessage(msg);
        }, gson::toJson);

        post("/api/tests/owner/entrada-inventario", "application/json", (req, res) -> {
            User user = req.session().attribute("user");
            if (!hasRole(user, "OWNER")) {
                res.status(403);
                return "Acceso denegado";
            }
            String msg = dbTestService.runDemoInventoryEntry();
            return buildMessage(msg);
        }, gson::toJson);

        post("/api/tests/owner/revisar-envejecido", "application/json", (req, res) -> {
            User user = req.session().attribute("user");
            if (!hasRole(user, "OWNER")) {
                res.status(403);
                return "Acceso denegado";
            }
            String msg = dbTestService.runDemoAgingReview();
            return buildMessage(msg);
        }, gson::toJson);

        // Gestor de inventario puede probar entradas y envejecido
        post("/api/tests/gestor/entrada-inventario", "application/json", (req, res) -> {
            User user = req.session().attribute("user");
            if (!hasRole(user, "GESTORINVENTARIO") && !hasRole(user, "OWNER")) {
                res.status(403);
                return "Acceso denegado";
            }
            String msg = dbTestService.runDemoInventoryEntry();
            return buildMessage(msg);
        }, gson::toJson);

        post("/api/tests/gestor/revisar-envejecido", "application/json", (req, res) -> {
            User user = req.session().attribute("user");
            if (!hasRole(user, "GESTORINVENTARIO") && !hasRole(user, "OWNER")) {
                res.status(403);
                return "Acceso denegado";
            }
            String msg = dbTestService.runDemoAgingReview();
            return buildMessage(msg);
        }, gson::toJson);

        // Vendedor: solo probar venta (usa un cliente demo)
        post("/api/tests/vendedor/venta-demo", "application/json", (req, res) -> {
            User user = req.session().attribute("user");
            if (!hasRole(user, "VENDEDOR") && !hasRole(user, "OWNER")) {
                res.status(403);
                return "Acceso denegado";
            }

            int clienteId = 0;
            try {
                // Cliente demo creado en 02_tiendaonline_seed.sql
                clienteId = findClienteDemoId();
            } catch (Exception e) {
                String msg = "No se pudo localizar cliente demo: " + e.getMessage();
                return buildMessage(msg);
            }

            String msg = dbTestService.runDemoSale(clienteId);
            return buildMessage(msg);
        }, gson::toJson);
    }

    private static boolean hasRole(User user, String expectedRole) {
        return user != null && expectedRole.equalsIgnoreCase(user.getRoleName());
    }

    private static Map<String, String> buildMessage(String msg) {
        Map<String, String> map = new HashMap<>();
        map.put("message", msg);
        return map;
    }

    /**
     * Helper to find the demo client id (cliente@tienda.local)
     * using direct JDBC.
     */
    private static int findClienteDemoId() throws Exception {
        // To avoid circular dependency, a tiny inline query is used
        try (java.sql.Connection conn = com.ulatina.basesdedatos2.tiendaonline.config.Db.getConnection();
             java.sql.PreparedStatement ps = conn.prepareStatement(
                     "SELECT TOP(1) id FROM dbo.users WHERE email = N'cliente@tienda.local'")) {

            try (java.sql.ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt(1);
                }
            }
        }
        throw new IllegalStateException("Cliente demo cliente@tienda.local no encontrado.");
    }
}
