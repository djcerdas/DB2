package com.ulatina.basesdedatos2.tiendaonline.repo;

import com.ulatina.basesdedatos2.tiendaonline.config.Db;
import com.ulatina.basesdedatos2.tiendaonline.model.Product;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

/**
 * SQL Server implementation of ProductRepository.
 *
 * This class uses the view v_CatalogoProductos to obtain a product
 * catalog ready for display in the web page.
 */
public class SqlServerProductRepository implements ProductRepository {

    @Override
    public List<Product> findCatalog() {
        List<Product> result = new ArrayList<>();

        String sql = "SELECT codigo_producto, nombre, talla, color, estilo, " +
                     "precio_venta, imagen_url, stock_total, descuento_pct_activo, precio_con_descuento " +
                     "FROM dbo.v_CatalogoProductos";

        try (Connection conn = Db.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                Product p = new Product();
                p.setId(rs.getInt("codigo_producto"));
                p.setName(rs.getString("nombre"));
                p.setSize(rs.getString("talla"));
                p.setColor(rs.getString("color"));
                p.setStyle(rs.getString("estilo"));
                p.setPrice(rs.getDouble("precio_venta"));
                p.setImageUrl(rs.getString("imagen_url"));
                p.setStock(rs.getInt("stock_total"));
                p.setActiveDiscountPercent(rs.getDouble("descuento_pct_activo"));
                p.setFinalPrice(rs.getDouble("precio_con_descuento"));

                result.add(p);
            }

        } catch (SQLException ex) {
            // For academic purposes we simply print the stacktrace.
            // In a real project, we would log properly.
            ex.printStackTrace();
        }

        return result;
    }

    @Override
    public Optional<Product> findById(int id) {
        String sql = "SELECT codigo_producto, nombre, talla, color, estilo, " +
                     "precio_venta, imagen_url, stock_total, descuento_pct_activo, precio_con_descuento " +
                     "FROM dbo.v_CatalogoProductos WHERE codigo_producto = ?";

        try (Connection conn = Db.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, id);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    Product p = new Product();
                    p.setId(rs.getInt("codigo_producto"));
                    p.setName(rs.getString("nombre"));
                    p.setSize(rs.getString("talla"));
                    p.setColor(rs.getString("color"));
                    p.setStyle(rs.getString("estilo"));
                    p.setPrice(rs.getDouble("precio_venta"));
                    p.setImageUrl(rs.getString("imagen_url"));
                    p.setStock(rs.getInt("stock_total"));
                    p.setActiveDiscountPercent(rs.getDouble("descuento_pct_activo"));
                    p.setFinalPrice(rs.getDouble("precio_con_descuento"));
                    return Optional.of(p);
                }
            }

        } catch (SQLException ex) {
            ex.printStackTrace();
        }

        return Optional.empty();
    }
}
