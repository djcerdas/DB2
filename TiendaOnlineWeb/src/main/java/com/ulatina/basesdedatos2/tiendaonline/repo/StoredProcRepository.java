package com.ulatina.basesdedatos2.tiendaonline.repo;

import com.ulatina.basesdedatos2.tiendaonline.config.Db;

import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.Date;
import java.sql.Types;
import java.time.LocalDate;

/**
 * Encapsula llamadas a procedimientos almacenados:
 * - sp_RegistrarProducto
 * - sp_RegistrarEntradaInventario
 * - sp_RegistrarVentaSimple
 * - sp_RevisarInventarioEnvejecido
 */
public class StoredProcRepository {

    public int registrarProducto(String nombre,
                                 String talla,
                                 String color,
                                 String estilo,
                                 double precioVenta,
                                 String imagenUrl,
                                 int cantidadInicial,
                                 LocalDate fechaIngreso,
                                 String ubicacionBodega) {

        String sql = "{call dbo.sp_RegistrarProducto(?, ?, ?, ?, ?, ?, ?, ?, ?, ?)}";

        try (Connection conn = Db.getConnection();
             CallableStatement cs = conn.prepareCall(sql)) {

            cs.setString(1, nombre);
            cs.setString(2, talla);
            cs.setString(3, color);
            cs.setString(4, estilo);
            cs.setBigDecimal(5, java.math.BigDecimal.valueOf(precioVenta));

            if (imagenUrl == null || imagenUrl.isBlank()) {
                cs.setNull(6, Types.NVARCHAR);
            } else {
                cs.setString(6, imagenUrl);
            }

            cs.setInt(7, cantidadInicial);
            cs.setDate(8, Date.valueOf(fechaIngreso));

            if (ubicacionBodega == null || ubicacionBodega.isBlank()) {
                cs.setNull(9, Types.NVARCHAR);
            } else {
                cs.setString(9, ubicacionBodega);
            }

            cs.registerOutParameter(10, Types.INTEGER);

            cs.execute();
            return cs.getInt(10);
        } catch (Exception e) {
            throw new RuntimeException("Error en sp_RegistrarProducto: " + e.getMessage(), e);
        }
    }

    public void registrarEntradaInventario(int codigoProducto,
                                           int cantidad,
                                           LocalDate fechaIngreso,
                                           String ubicacionBodega) {

        String sql = "{call dbo.sp_RegistrarEntradaInventario(?, ?, ?, ?)}";
        try (Connection conn = Db.getConnection();
             CallableStatement cs = conn.prepareCall(sql)) {

            cs.setInt(1, codigoProducto);
            cs.setInt(2, cantidad);
            cs.setDate(3, Date.valueOf(fechaIngreso));

            if (ubicacionBodega == null || ubicacionBodega.isBlank()) {
                cs.setNull(4, Types.NVARCHAR);
            } else {
                cs.setString(4, ubicacionBodega);
            }

            cs.execute();
        } catch (Exception e) {
            throw new RuntimeException("Error en sp_RegistrarEntradaInventario: " + e.getMessage(), e);
        }
    }

    public void registrarVentaSimple(Integer idUsuarioCliente,
                                     String canal,
                                     String metodoPago,
                                     int codigoProducto,
                                     int cantidad) {

        String sql = "{call dbo.sp_RegistrarVentaSimple(?, ?, ?, ?, ?)}";
        try (Connection conn = Db.getConnection();
             CallableStatement cs = conn.prepareCall(sql)) {

            if (idUsuarioCliente == null) {
                cs.setNull(1, Types.INTEGER);
            } else {
                cs.setInt(1, idUsuarioCliente);
            }
            cs.setString(2, canal);
            cs.setString(3, metodoPago);
            cs.setInt(4, codigoProducto);
            cs.setInt(5, cantidad);

            cs.execute();
        } catch (Exception e) {
            throw new RuntimeException("Error en sp_RegistrarVentaSimple: " + e.getMessage(), e);
        }
    }

    public void revisarInventarioEnvejecido(double descuentoPorDefecto,
                                            int diasEnBodega) {

        String sql = "{call dbo.sp_RevisarInventarioEnvejecido(?, ?)}";
        try (Connection conn = Db.getConnection();
             CallableStatement cs = conn.prepareCall(sql)) {

            cs.setBigDecimal(1, java.math.BigDecimal.valueOf(descuentoPorDefecto));
            cs.setInt(2, diasEnBodega);

            cs.execute();
        } catch (Exception e) {
            throw new RuntimeException("Error en sp_RevisarInventarioEnvejecido: " + e.getMessage(), e);
        }
    }
}
