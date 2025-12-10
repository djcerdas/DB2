package com.ulatina.basesdedatos2.tiendaonline.model;

import java.math.BigDecimal;

public class CartItem {

    private int codigoProducto;
    private String nombre;
    private String talla;
    private String color;
    private int cantidad;
    private BigDecimal precioUnitario;

    // --- Constructors ---

    // Default constructor (used in App.java with setters)
    public CartItem() {
    }

    // Full constructor (used in CartService.addItem)
    public CartItem(int codigoProducto,
                    String nombre,
                    String talla,
                    String color,
                    int cantidad,
                    BigDecimal precioUnitario) {

        this.codigoProducto = codigoProducto;
        this.nombre = nombre;
        this.talla = talla;
        this.color = color;
        this.cantidad = cantidad;
        this.precioUnitario = precioUnitario;
    }

    // --- Getters ---

    public int getCodigoProducto() {
        return codigoProducto;
    }

    public String getNombre() {
        return nombre;
    }

    public String getTalla() {
        return talla;
    }

    public String getColor() {
        return color;
    }

    public int getCantidad() {
        return cantidad;
    }

    public BigDecimal getPrecioUnitario() {
        return precioUnitario;
    }

    public BigDecimal getSubtotal() {
        return precioUnitario != null
                ? precioUnitario.multiply(BigDecimal.valueOf(cantidad))
                : BigDecimal.ZERO;
    }

    // --- Setters (for compatibility with existing code) ---

    public void setCodigoProducto(int codigoProducto) {
        this.codigoProducto = codigoProducto;
    }

    public void setNombre(String nombre) {
        this.nombre = nombre;
    }

    public void setTalla(String talla) {
        this.talla = talla;
    }

    public void setColor(String color) {
        this.color = color;
    }

    public void setCantidad(int cantidad) {
        this.cantidad = cantidad;
    }

    public void setPrecioUnitario(BigDecimal precioUnitario) {
        this.precioUnitario = precioUnitario;
    }

    // --- Extra cart logic ---

    public void incrementarCantidad(int delta) {
        if (delta > 0) {
            this.cantidad += delta;
        }
    }
}
