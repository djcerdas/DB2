package com.ulatina.basesdedatos2.tiendaonline.model;

/**
 * Represents an application user that logs into the web system.
 *
 * Business mapping examples:
 *  - OWNER           -> Dueño de negocio
 *  - GESTORINVENTARIO-> Gestor de inventario
 *  - VENDEDOR        -> Empleado de ventas
 *  - CLIENTE         -> Cliente final
 */
public class User {

    private int id;
    private String email;
    private String roleName;

    public User() {
    }

    public User(int id, String email, String roleName) {
        this.id = id;
        this.email = email;
        this.roleName = roleName;
    }

    public int getId() {
        return id;
    }

    public String getEmail() {
        return email;
    }

    public String getRoleName() {
        return roleName;
    }
}
