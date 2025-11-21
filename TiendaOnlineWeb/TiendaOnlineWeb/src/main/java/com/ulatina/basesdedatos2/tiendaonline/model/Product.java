package com.ulatina.basesdedatos2.tiendaonline.model;

/**
 * Represents a product in the online store catalog.
 *
 * This model is aligned with the view v_CatalogoProductos on SQL Server.
 */
public class Product {

    private int id;
    private String name;
    private String size;
    private String color;
    private String style;
    private double price;
    private String imageUrl;
    private int stock;
    private double activeDiscountPercent;
    private double finalPrice;

    public Product() {
    }

    // Getters and setters (self-explanatory names)

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }


    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getSize() {
        return size;
    }

    public void setSize(String size) {
        this.size = size;
    }


    public String getColor() {
        return color;
    }

    public void setColor(String color) {
        this.color = color;
    }


    public String getStyle() {
        return style;
    }

    public void setStyle(String style) {
        this.style = style;
    }


    public double getPrice() {
        return price;
    }

    public void setPrice(double price) {
        this.price = price;
    }


    public String getImageUrl() {
        return imageUrl;
    }

    public void setImageUrl(String imageUrl) {
        this.imageUrl = imageUrl;
    }


    public int getStock() {
        return stock;
    }

    public void setStock(int stock) {
        this.stock = stock;
    }


    public double getActiveDiscountPercent() {
        return activeDiscountPercent;
    }

    public void setActiveDiscountPercent(double activeDiscountPercent) {
        this.activeDiscountPercent = activeDiscountPercent;
    }


    public double getFinalPrice() {
        return finalPrice;
    }

    public void setFinalPrice(double finalPrice) {
        this.finalPrice = finalPrice;
    }
}
