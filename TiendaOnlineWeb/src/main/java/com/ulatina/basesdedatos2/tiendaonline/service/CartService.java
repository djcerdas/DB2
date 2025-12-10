package com.ulatina.basesdedatos2.tiendaonline.service;

import com.ulatina.basesdedatos2.tiendaonline.model.CartItem;

import java.math.BigDecimal;
import java.util.Collection;
import java.util.LinkedHashMap;
import java.util.Map;

public class CartService {

    private final Map<String, CartItem> items = new LinkedHashMap<>();

    /**
     * Key is codigoProducto + "|" + talla + "|" + color
     */
    private String buildKey(int codigoProducto, String talla, String color) {
        return codigoProducto + "|" + (talla == null ? "" : talla) + "|" + (color == null ? "" : color);
    }

    public void addItem(int codigoProducto, String nombre, String talla, String color, int cantidad, BigDecimal precioUnitario) {
        String key = buildKey(codigoProducto, talla, color);
        CartItem existing = items.get(key);
        if (existing == null) {
            items.put(key, new CartItem(codigoProducto, nombre, talla, color, cantidad, precioUnitario));
        } else {
            existing.incrementarCantidad(cantidad);
        }
    }

    public void removeItem(int codigoProducto, String talla, String color) {
        String key = buildKey(codigoProducto, talla, color);
        items.remove(key);
    }

    public Collection<CartItem> getItems() {
        return items.values();
    }

    public BigDecimal getTotal() {
        return items.values().stream()
                .map(CartItem::getSubtotal)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
    }

    public void clear() {
        items.clear();
    }
}
