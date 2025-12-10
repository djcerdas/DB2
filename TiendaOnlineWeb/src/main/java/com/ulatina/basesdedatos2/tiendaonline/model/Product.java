package com.ulatina.basesdedatos2.tiendaonline.model;

import java.math.BigDecimal;

/**
 * Modelo de producto alineado con la vista SQL v_CatalogoProductos.
 */
public class Product {

    private int codigoProducto;
    private String nombre;
    private String talla;
    private String color;
    private String estilo;

    private BigDecimal precioVenta;
    private BigDecimal descuentoPctActivo;
    private BigDecimal precioConDescuento;

    private int stockTotal;
    private String imagenUrl;

    // Constructor vacío
    public Product() {
    }

    // Constructor completo
    public Product(int codigoProducto,
                   String nombre,
                   String talla,
                   String color,
                   String estilo,
                   BigDecimal precioVenta,
                   BigDecimal descuentoPctActivo,
                   BigDecimal precioConDescuento,
                   int stockTotal,
                   String imagenUrl) {

        this.codigoProducto = codigoProducto;
        this.nombre = nombre;
        this.talla = talla;
        this.color = color;
        this.estilo = estilo;
        this.precioVenta = precioVenta;
        this.descuentoPctActivo = descuentoPctActivo;
        this.precioConDescuento = precioConDescuento;
        this.stockTotal = stockTotal;
        this.imagenUrl = imagenUrl;
    }

    // Constructor de compatibilidad (usado por repositorio)
    public Product(int codigoProducto,
                   String nombre,
                   String talla,
                   String color,
                   String estilo,
                   BigDecimal precioVenta,
                   BigDecimal descuentoPctActivo,
                   int stockTotal,
                   String imagenUrl) {

        this(
            codigoProducto,
            nombre,
            talla,
            color,
            estilo,
            precioVenta,
            descuentoPctActivo,
            precioVenta,   // precio con descuento por defecto
            stockTotal,
            imagenUrl
        );
    }

    // Getters y Setters

    public int getCodigoProducto() {
        return codigoProducto;
    }

    public void setCodigoProducto(int codigoProducto) {
        this.codigoProducto = codigoProducto;
    }

    public String getNombre() {
        return nombre;
    }

    public void setNombre(String nombre) {
        this.nombre = nombre;
    }

    public String getTalla() {
        return talla;
    }

    public void setTalla(String talla) {
        this.talla = talla;
    }

    public String getColor() {
        return color;
    }

    public void setColor(String color) {
        this.color = color;
    }

    public String getEstilo() {
        return estilo;
    }

    public void setEstilo(String estilo) {
        this.estilo = estilo;
    }

    public BigDecimal getPrecioVenta() {
        return precioVenta;
    }

    public void setPrecioVenta(BigDecimal precioVenta) {
        this.precioVenta = precioVenta;
    }

    public BigDecimal getDescuentoPctActivo() {
        return descuentoPctActivo;
    }

    public void setDescuentoPctActivo(BigDecimal descuentoPctActivo) {
        this.descuentoPctActivo = descuentoPctActivo;
    }

    public BigDecimal getPrecioConDescuento() {
        return precioConDescuento;
    }

    public void setPrecioConDescuento(BigDecimal precioConDescuento) {
        this.precioConDescuento = precioConDescuento;
    }

    public int getStockTotal() {
        return stockTotal;
    }

    public void setStockTotal(int stockTotal) {
        this.stockTotal = stockTotal;
    }

    public String getImagenUrl() {
        return imagenUrl;
    }

    public void setImagenUrl(String imagenUrl) {
        this.imagenUrl = imagenUrl;
    }
}