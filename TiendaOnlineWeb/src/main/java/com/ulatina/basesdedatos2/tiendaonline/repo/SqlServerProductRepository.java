package com.ulatina.basesdedatos2.tiendaonline.repo;

import com.ulatina.basesdedatos2.tiendaonline.config.Db;
import com.ulatina.basesdedatos2.tiendaonline.model.Product;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

public class SqlServerProductRepository {

    // ❗ IMPORTANTE: NO DEBE EXISTIR ESTO:
    // private final Db db;

    // ✅ Constructor vacío requerido por App.java
    public SqlServerProductRepository() {
    }

    public List<Product> findCatalog() {
        String sql = """
            SELECT
                codigo_producto,
                nombre,
                talla,
                color,
                estilo,
                precio_venta,
                descuento_pct_activo,
                precio_con_descuento,
                stock_total,
                imagen_url
            FROM dbo.v_CatalogoProductos
            """;

        List<Product> result = new ArrayList<>();

        try (Connection conn = Db.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                int codigo = rs.getInt("codigo_producto");
                String nombre = rs.getString("nombre");
                String talla = rs.getString("talla");
                String color = rs.getString("color");
                String estilo = rs.getString("estilo");

                BigDecimal precioVenta = rs.getBigDecimal("precio_venta");
                BigDecimal descuentoPct = rs.getBigDecimal("descuento_pct_activo");
                BigDecimal precioConDesc = rs.getBigDecimal("precio_con_descuento");
                int stockTotal = rs.getInt("stock_total");
                String imagenUrl = rs.getString("imagen_url");

                if (precioVenta == null) precioVenta = BigDecimal.ZERO;
                if (descuentoPct == null) descuentoPct = BigDecimal.ZERO;
                if (precioConDesc == null) precioConDesc = precioVenta;

                Product product = new Product(
                        codigo,
                        nombre,
                        talla,
                        color,
                        estilo,
                        precioVenta,
                        descuentoPct,
                        precioConDesc,
                        stockTotal,
                        imagenUrl
                );

                result.add(product);
            }

        } catch (SQLException ex) {
            ex.printStackTrace();
        }

        return result;
    }
}
