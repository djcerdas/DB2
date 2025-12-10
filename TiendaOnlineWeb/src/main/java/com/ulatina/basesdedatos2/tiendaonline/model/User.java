package com.ulatina.basesdedatos2.tiendaonline.model;

public class User {
    private int id;
    private String email;
    private String roleName; // e.g., OWNER, GestorInventario, Vendedor, etc.

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

    /**
     * Alias method used by Routes.java
     * Ensures compatibility with the switch(user.getAppRole())
     */
    public String getAppRole() {
        return this.roleName;
    }
}
