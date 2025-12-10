package com.ulatina.basesdedatos2.tiendaonline.repo;

import com.ulatina.basesdedatos2.tiendaonline.config.Db;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class ReportRepository {

    private static final String SQL_VENTAS_POR_DIA = """
        SELECT fecha, cantidad_facturas, total_sin_iva, total_con_iva
        FROM dbo.v_VentasPorDia
        ORDER BY fecha DESC
        """;

    private static final String SQL_STOCK_BAJO = """
        SELECT codigo_producto, nombre, stock_total
        FROM dbo.v_StockBajo
        ORDER BY stock_total ASC
        """;

    public List<Map<String, Object>> ventasPorDia() {
        List<Map<String, Object>> list = new ArrayList<>();
        try (Connection conn = Db.getConnection();
             PreparedStatement ps = conn.prepareStatement(SQL_VENTAS_POR_DIA);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                Map<String, Object> row = new HashMap<>();
                row.put("fecha", rs.getDate("fecha").toString());
                row.put("cantidad_facturas", rs.getInt("cantidad_facturas"));
                row.put("total_sin_iva", rs.getBigDecimal("total_sin_iva"));
                row.put("total_con_iva", rs.getBigDecimal("total_con_iva"));
                list.add(row);
            }
        } catch (Exception e) {
            throw new RuntimeException("Error consultando v_VentasPorDia: " + e.getMessage(), e);
        }
        return list;
    }

    public List<Map<String, Object>> stockBajo() {
        List<Map<String, Object>> list = new ArrayList<>();
        try (Connection conn = Db.getConnection();
             PreparedStatement ps = conn.prepareStatement(SQL_STOCK_BAJO);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                Map<String, Object> row = new HashMap<>();
                row.put("codigo_producto", rs.getInt("codigo_producto"));
                row.put("nombre", rs.getString("nombre"));
                row.put("stock_total", rs.getInt("stock_total"));
                list.add(row);
            }
        } catch (Exception e) {
            throw new RuntimeException("Error consultando v_StockBajo: " + e.getMessage(), e);
        }
        return list;
    }
}
