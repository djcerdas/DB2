package com.ulatina.basesdedatos2.tiendaonline.repo;

import com.ulatina.basesdedatos2.tiendaonline.config.Db;
import com.ulatina.basesdedatos2.tiendaonline.model.Product;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;

public class CatalogRepository {

    private static final String SQL_CATALOGO = """
        SELECT
            codigo_producto,
            nombre,
            talla,
            color,
            estilo,
            precio_venta,
            imagen_url,
            stock_total,
            descuento_pct_activo,
            precio_con_descuento
        FROM dbo.v_CatalogoProductos
        ORDER BY nombre ASC
        """;

    public List<Product> findCatalog() {
        List<Product> list = new ArrayList<>();
        try (Connection conn = Db.getConnection();
             PreparedStatement ps = conn.prepareStatement(SQL_CATALOGO);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                Product p = new Product();
                p.setCodigoProducto(rs.getInt("codigo_producto"));
                p.setNombre(rs.getString("nombre"));
                p.setTalla(rs.getString("talla"));
                p.setColor(rs.getString("color"));
                p.setEstilo(rs.getString("estilo"));
                p.setPrecioVenta(rs.getBigDecimal("precio_venta"));
                p.setImagenUrl(rs.getString("imagen_url"));
                p.setStockTotal(rs.getInt("stock_total"));
                p.setDescuentoPctActivo(rs.getBigDecimal("descuento_pct_activo"));
                p.setPrecioConDescuento(rs.getBigDecimal("precio_con_descuento"));
                list.add(p);
            }
        } catch (Exception e) {
            throw new RuntimeException("Error consultando v_CatalogoProductos: " + e.getMessage(), e);
        }
        return list;
    }
}
