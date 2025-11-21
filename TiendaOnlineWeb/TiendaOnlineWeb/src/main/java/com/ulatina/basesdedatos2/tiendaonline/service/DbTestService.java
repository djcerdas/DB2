package com.ulatina.basesdedatos2.tiendaonline.service;

import com.ulatina.basesdedatos2.tiendaonline.config.Db;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

/**
 * Service dedicated to executing database-level tests from the web UI.
 *
 * Each public method corresponds to one "test button" that a role
 * (OWNER, GESTORINVENTARIO, VENDEDOR) can trigger.
 *
 * The goal is to demonstrate, from the web interface, concepts such as:
 * - Stored procedures
 * - Concurrency control
 * - Triggers and alerts
 * - Views and reporting
 */
public class DbTestService {

    /**
     * Runs a demo "register product" using sp_RegistrarProducto.
     */
    public String runDemoRegisterProduct() {
        String sql = "EXEC dbo.sp_RegistrarProducto " +
                     "@nombre=?, @talla=?, @color=?, @estilo=?, " +
                     "@precio_venta=?, @imagen_url=?, @cantidad_inicial=?, " +
                     "@fecha_ingreso=?, @ubicacion_bodega=?, @codigo_producto_out=?";

        try (Connection conn = Db.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, "Blazer Demo Web");
            ps.setString(2, "M");
            ps.setString(3, "Negro");
            ps.setString(4, "Formal");
            ps.setDouble(5, 45990.0);
            ps.setString(6, "/images/blazer_demo_web.jpg");
            ps.setInt(7, 5);
            ps.setDate(8, new java.sql.Date(System.currentTimeMillis()));
            ps.setString(9, "Bodega Central - WebTest");
            ps.setInt(10, 0); // parámetro OUTPUT se ignora desde aquí

            ps.execute();
            return "sp_RegistrarProducto ejecutado correctamente desde la web.";
        } catch (SQLException ex) {
            return "Error al ejecutar sp_RegistrarProducto: " + ex.getMessage();
        }
    }

    /**
     * Runs a demo inventory entry using sp_RegistrarEntradaInventario.
     * It selects the first product and increases its stock.
     */
    public String runDemoInventoryEntry() {
        String selectSql = "SELECT TOP(1) codigo_producto FROM dbo.productos ORDER BY codigo_producto";

        try (Connection conn = Db.getConnection();
             PreparedStatement select = conn.prepareStatement(selectSql);
             ResultSet rs = select.executeQuery()) {

            if (!rs.next()) {
                return "No hay productos para probar la entrada de inventario.";
            }

            int codigoProducto = rs.getInt(1);

            String execSql = "EXEC dbo.sp_RegistrarEntradaInventario " +
                             "@codigo_producto=?, @cantidad=?, @fecha_ingreso=?, @ubicacion_bodega=?";
            try (PreparedStatement ps = conn.prepareStatement(execSql)) {
                ps.setInt(1, codigoProducto);
                ps.setInt(2, 3);
                ps.setDate(3, new java.sql.Date(System.currentTimeMillis()));
                ps.setString(4, "Bodega Central - WebTest");
                ps.execute();
            }

            return "sp_RegistrarEntradaInventario ejecutado correctamente para producto " + codigoProducto + ".";
        } catch (SQLException ex) {
            return "Error al ejecutar sp_RegistrarEntradaInventario: " + ex.getMessage();
        }
    }

    /**
     * Runs a demo sale using sp_RegistrarVentaSimple to show
     * concurrency control and stock validation.
     */
    public String runDemoSale(int clienteId) {
        String selectSql = "SELECT TOP(1) codigo_producto FROM dbo.productos ORDER BY codigo_producto";

        try (Connection conn = Db.getConnection();
             PreparedStatement select = conn.prepareStatement(selectSql);
             ResultSet rs = select.executeQuery()) {

            if (!rs.next()) {
                return "No hay productos para probar la venta.";
            }

            int codigoProducto = rs.getInt(1);

            String execSql = "EXEC dbo.sp_RegistrarVentaSimple " +
                             "@id_usuario_cliente=?, @canal=?, @metodo_pago=?, " +
                             "@codigo_producto=?, @cantidad=?";
            try (PreparedStatement ps = conn.prepareStatement(execSql)) {
                ps.setInt(1, clienteId);
                ps.setString(2, "web");
                ps.setString(3, "Tarjeta");
                ps.setInt(4, codigoProducto);
                ps.setInt(5, 1);
                ps.execute();
            }

            return "sp_RegistrarVentaSimple ejecutado correctamente para producto " + codigoProducto + ".";
        } catch (SQLException ex) {
            return "Error al ejecutar sp_RegistrarVentaSimple: " + ex.getMessage();
        }
    }

    /**
     * Runs the stored procedure that reviews old inventory and creates offers.
     */
    public String runDemoAgingReview() {
        String sql = "EXEC dbo.sp_RevisarInventarioEnvejecido @descuento_por_defecto=?, @dias_en_bodega=?";

        try (Connection conn = Db.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setDouble(1, 20.0);
            ps.setInt(2, 60);
            ps.execute();

            return "sp_RevisarInventarioEnvejecido ejecutado correctamente.";
        } catch (SQLException ex) {
            return "Error al ejecutar sp_RevisarInventarioEnvejecido: " + ex.getMessage();
        }
    }
}
