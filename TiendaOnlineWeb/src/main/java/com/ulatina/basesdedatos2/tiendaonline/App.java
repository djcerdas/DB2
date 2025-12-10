package com.ulatina.basesdedatos2.tiendaonline;

import com.google.gson.Gson;
import com.ulatina.basesdedatos2.tiendaonline.repo.SqlServerProductRepository;
import com.ulatina.basesdedatos2.tiendaonline.repo.UserRepository;
import com.ulatina.basesdedatos2.tiendaonline.service.AuthService;
import com.ulatina.basesdedatos2.tiendaonline.service.InventoryService;
import com.ulatina.basesdedatos2.tiendaonline.web.Routes;

import static spark.Spark.*;

public class App {

    public static void main(String[] args) {

        // Puerto y estáticos
        port(8080);
        staticFiles.location("/public");

        // Handler global de excepciones (cualquier 500 debe imprimir stacktrace)
        exception(Exception.class, (e, req, res) -> {
            System.out.println("!!! GLOBAL EXCEPTION handler");
            e.printStackTrace();
            res.status(500);
            res.body("Internal Server Error: " + e.getMessage());
        });

        // Filtro global de log para ver TODO lo que entra
        before((req, res) -> {
            System.out.println(">>> [GLOBAL BEFORE] " + req.requestMethod() + " " + req.pathInfo());
        });

        // Repositorios
        UserRepository userRepository = new UserRepository();
        SqlServerProductRepository productRepository = new SqlServerProductRepository();

        // Servicios
        AuthService authService = new AuthService(userRepository);
        InventoryService inventoryService = new InventoryService(productRepository);

        // Rutas HTTP
        Routes routes = new Routes(new Gson(), authService, inventoryService);
        routes.register();

        // Health-check
        get("/health", (req, res) -> "OK");
    }
}
