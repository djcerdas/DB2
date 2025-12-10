package com.ulatina.basesdedatos2.tiendaonline.web;

import com.google.gson.Gson;
import com.ulatina.basesdedatos2.tiendaonline.config.Db;
import com.ulatina.basesdedatos2.tiendaonline.model.Product;
import com.ulatina.basesdedatos2.tiendaonline.model.User;
import com.ulatina.basesdedatos2.tiendaonline.service.AuthService;
import com.ulatina.basesdedatos2.tiendaonline.service.CartService;
import com.ulatina.basesdedatos2.tiendaonline.service.InventoryService;
import spark.Request;
import spark.Response;
import spark.Session;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static spark.Spark.*;

public class Routes {

    private final Gson gson;
    private final AuthService authService;
    private final InventoryService inventoryService;

    public Routes(Gson gson, AuthService authService, InventoryService inventoryService) {
        this.gson = gson;
        this.authService = authService;
        this.inventoryService = inventoryService;
    }

    public void register() {

        // --- LOG GLOBAL ---
        before((req, res) -> {
            System.out.println(">>> REQUEST " + req.requestMethod() + " " + req.pathInfo());
        });

        // --- AUTH FILTER ---
        before((req, res) -> {
            String path = req.pathInfo();

            if (path.startsWith("/public") ||
                path.endsWith(".html") ||
                path.startsWith("/css") ||
                path.startsWith("/js") ||
                path.equals("/login") ||
                path.equals("/health")) {
                return;
            }

            if (path.startsWith("/api")) {
                User u = getCurrentUser(req);
                if (u == null) {
                    System.out.println(">>> NO SESSION USER for " + path + " -> 401");
                    halt(401, "Unauthorized");
                }
            }
        });

        // --- LOGOUT ---
        get("/logout", (request, response) -> {
            System.out.println(">>> LOGOUT performed");
            Session session = request.session(false);
            if (session != null) {
                session.invalidate();
            }
            response.redirect("/login.html");
            return null;
        });

        // --- LOGIN ---
        post("/login", (req, res) -> {
            System.out.println(">>> /login handler reached");
            try {
                String email = req.queryParams("email");
                String password = req.queryParams("password");

                System.out.println("    email   = " + email);
                System.out.println("    pass    = " + password);

                User user = authService.login(email, password);
                System.out.println("    user    = " + user);

                if (user == null) {
                    res.redirect("/login.html?error=1");
                    return null;
                }

                Session session = req.session(true);
                session.attribute("user", user);

                System.out.println("    login OK, role = " + user.getAppRole());

                switch (user.getAppRole()) {
                    case "OWNER":            res.redirect("/owner.html");    break;
                    case "GestorInventario": res.redirect("/gestor.html");   break;
                    case "Vendedor":         res.redirect("/vendedor.html"); break;
                    case "Cliente":          res.redirect("/cliente.html");  break;
                    case "Proveedor":        res.redirect("/proveedor.html");break;
                    case "Marketing":        res.redirect("/marketing.html");break;
                    default:                 res.redirect("/cliente.html");
                }
                return null;

            } catch (Exception e) {
                e.printStackTrace();
                res.status(500);
                return "Error in /login: " + e.getMessage();
            }
        });

        // --- API: CURRENT USER ---
        get("/api/me", (req, res) -> {
            User u = getCurrentUser(req);
            res.type("application/json");
            if (u == null) return "{}";

            Map<String, Object> map = new HashMap<>();
            map.put("email", u.getEmail());
            map.put("role", u.getAppRole());
            return gson.toJson(map);
        });

        // --- API: CATÁLOGO ---
        get("/api/catalogo", (req, res) -> {
            User u = getCurrentUser(req);
            if (u == null) {
                res.status(401);
                return "Unauthorized";
            }

            List<Product> catalog = inventoryService.getCatalog();
            res.type("application/json");
            return gson.toJson(catalog);
        });

        // --- API: CART ADD ---
        post("/api/cart/add", (req, res) -> {
            User u = getCurrentUser(req);
            if (u == null) return unauthorized(res);

            CartService cart = getOrCreateCart(req);

            int codigo = Integer.parseInt(req.queryParams("codigoProducto"));
            String nombre = req.queryParams("nombre");
            String talla  = req.queryParams("talla");
            String color  = req.queryParams("color");
            int cantidad  = Integer.parseInt(req.queryParams("cantidad"));
            BigDecimal precio = new BigDecimal(req.queryParams("precioUnitario"));

            cart.addItem(codigo, nombre, talla, color, cantidad, precio);

            Map<String, Object> resp = new HashMap<>();
            resp.put("ok", true);
            resp.put("total", cart.getTotal().toPlainString());

            res.type("application/json");
            return gson.toJson(resp);
        });

        // --- API: CART REMOVE ---
        post("/api/cart/remove", (req, res) -> {
            User u = getCurrentUser(req);
            if (u == null) return unauthorized(res);

            CartService cart = getOrCreateCart(req);

            int codigo = Integer.parseInt(req.queryParams("codigoProducto"));
            String talla = req.queryParams("talla");
            String color = req.queryParams("color");

            cart.removeItem(codigo, talla, color);

            Map<String, Object> resp = new HashMap<>();
            resp.put("ok", true);
            resp.put("total", cart.getTotal().toPlainString());

            res.type("application/json");
            return gson.toJson(resp);
        });

        // --- API: CART GET ---
        get("/api/cart", (req, res) -> {
            User u = getCurrentUser(req);
            if (u == null) return unauthorized(res);

            CartService cart = getOrCreateCart(req);
            res.type("application/json");
            return gson.toJson(cart.getItems());
        });

        // --- OWNER DASHBOARD ---
        get("/api/owner/dashboard", (req, res) -> {
            User u = getCurrentUser(req);
            if (u == null || !"OWNER".equals(u.getAppRole())) {
                res.status(403);
                return "Forbidden";
            }
            Map<String, Object> data = new HashMap<>();
            data.put("mensaje", "Owner dashboard metrics will be implemented here.");
            res.type("application/json");
            return gson.toJson(data);
        });

        // --- MARKETING DASHBOARD ---
        get("/api/marketing/dashboard", (req, res) -> {
            User u = getCurrentUser(req);
            if (u == null || !"Marketing".equals(u.getAppRole())) {
                res.status(403);
                return "Forbidden";
            }
            Map<String, Object> data = new HashMap<>();
            data.put("mensaje", "Marketing dashboard metrics...");
            res.type("application/json");
            return gson.toJson(data);
        });

        // --- VENDEDOR: VENTAS RECIENTES ---
        get("/api/vendedor/ventas-recientes", (req, res) -> {
            User u = getCurrentUser(req);

            if (u == null || !"Vendedor".equals(u.getAppRole())) {
                res.status(403);
                return "Forbidden";
            }

            System.out.println(">>> VENDEDOR: consultando ventas recientes...");

            String sql = """
                SELECT TOP (20)
                    f.numero_factura,
                    CAST(f.fecha_venta AS DATE) AS fecha,
                    f.canal,
                    f.metodo_pago,
                    f.total_sin_iva,
                    v.codigo_producto,
                    v.cantidad,
                    v.precio_unit_sin_IVA
                FROM dbo.facturas f
                JOIN dbo.ventas v 
                    ON v.numero_factura = f.numero_factura
                ORDER BY f.fecha_venta DESC;
                """;

            try (Connection conn = Db.getConnection();
                 PreparedStatement ps = conn.prepareStatement(sql);
                 ResultSet rs = ps.executeQuery()) {

                var lista = new java.util.ArrayList<Map<String, Object>>();

                while (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    row.put("numero_factura", rs.getLong("numero_factura"));
                    row.put("fecha", rs.getString("fecha"));
                    row.put("canal", rs.getString("canal"));
                    row.put("metodo_pago", rs.getString("metodo_pago"));
                    row.put("total_sin_iva", rs.getBigDecimal("total_sin_iva"));
                    row.put("codigo_producto", rs.getInt("codigo_producto"));
                    row.put("cantidad", rs.getInt("cantidad"));
                    row.put("precio_unit_sin_IVA", rs.getBigDecimal("precio_unit_sin_IVA"));
                    lista.add(row);
                }

                res.type("application/json");
                return gson.toJson(lista);

            } catch (Exception e) {
                e.printStackTrace();
                res.status(500);
                return "Error consultando ventas recientes: " + e.getMessage();
            }
        });
    }

    private static String unauthorized(Response res) {
        res.status(401);
        return "Unauthorized";
    }

    private static User getCurrentUser(Request req) {
        Session session = req.session(false);
        return session == null ? null : session.attribute("user");
    }

    private static CartService getOrCreateCart(Request req) {
        Session session = req.session(true);
        CartService cart = session.attribute("cart");
        if (cart == null) {
            cart = new CartService();
            session.attribute("cart", cart);
        }
        return cart;
    }
}