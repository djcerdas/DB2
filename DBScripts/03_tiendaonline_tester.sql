/*==============================================================*
  TIENDAONLINE - SCRIPT DE PRUEBAS DE CONCEPTOS
  Motor : Microsoft SQL Server
  Objetivo:
    Validar cada uno de los conceptos solicitados:
    - Roles de aplicación
    - Control de acceso (roles de BD)
    - Procedimientos almacenados
    - Triggers
    - Control de concurrencia
    - Vistas
    - Indexación para búsquedas
 *==============================================================*/

USE tiendaonline;
GO

---------------------------------------------------------------
-- 1. PRUEBA DE ROLES (TABLAS roles / users / user_roles)
---------------------------------------------------------------
PRINT '--- 1) ROLES, USUARIOS Y ASIGNACIONES ---';
SELECT * FROM dbo.roles;
SELECT * FROM dbo.users;
SELECT * FROM dbo.user_roles;
GO

---------------------------------------------------------------
-- 2. PRUEBA DE VISTAS (LECTURA DEL CATÁLOGO)
---------------------------------------------------------------
PRINT '--- 2) VISTAS (v_CatalogoProductos, v_StockBajo, v_VentasPorDia) ---';
SELECT TOP 10 * FROM dbo.v_CatalogoProductos;
SELECT * FROM dbo.v_StockBajo;
SELECT TOP 10 * FROM dbo.v_VentasPorDia;
GO

---------------------------------------------------------------
-- 3. PRUEBA DE PROCEDIMIENTOS ALMACENADOS
---------------------------------------------------------------
PRINT '--- 3) PROCEDIMIENTOS ALMACENADOS ---';

DECLARE @nuevoCodigo INT;
DECLARE @today DATE = CONVERT(date, GETDATE());

-- 3.1. Registrar un nuevo producto con existencia inicial
EXEC dbo.sp_RegistrarProducto
    @nombre              = N'Blazer Ejecutiva Azul',
    @talla               = N'M',
    @color               = N'Azul Marino',
    @estilo              = N'Formal',
    @precio_venta        = 45990,
    @imagen_url          = N'/images/blazer_ejecutiva_azul.jpg',
    @cantidad_inicial    = 12,
    @fecha_ingreso       = @today,
    @ubicacion_bodega    = N'Bodega Central',
    @codigo_producto_out = @nuevoCodigo OUTPUT;

PRINT 'Nuevo producto creado (sp_RegistrarProducto ejecutado).';

-- Verificar existencia real
SELECT * FROM dbo.productos   WHERE codigo_producto = @nuevoCodigo;
SELECT * FROM dbo.existencias WHERE codigo_producto = @nuevoCodigo;

-- 3.2. Registrar entrada de inventario en un producto existente
DECLARE @codigoExistente INT;
SET @codigoExistente = (SELECT TOP(1) codigo_producto FROM dbo.productos ORDER BY codigo_producto);

EXEC dbo.sp_RegistrarEntradaInventario
    @codigo_producto  = @codigoExistente,
    @cantidad         = 5,
    @fecha_ingreso    = @today,
    @ubicacion_bodega = N'Bodega Central - Estante A';

PRINT 'Entrada de inventario registrada (sp_RegistrarEntradaInventario ejecutado).';

SELECT * FROM dbo.existencias WHERE codigo_producto = @codigoExistente;
GO
GO   -- Separador de lote para evitar conflictos de declaraciones previas

---------------------------------------------------------------
-- 4. PRUEBA DE CONTROL DE CONCURRENCIA (sp_RegistrarVentaSimple)
--    NOTA: La prueba es secuencial pero valida:
--          * validación de stock
--          * inserción en facturas/ventas
--          * manejo de errores y transacciones
---------------------------------------------------------------
PRINT '--- 4) CONTROL DE CONCURRENCIA EN VENTAS ---';

DECLARE @productoVenta INT;
DECLARE @clienteId     INT;

-- Elegir un producto y un cliente conocidos
SELECT TOP(1) @productoVenta = codigo_producto
FROM dbo.productos
ORDER BY codigo_producto;

SELECT @clienteId = id
FROM dbo.users
WHERE email = N'cliente@tienda.local';

-- Stock antes de la venta
PRINT 'Stock antes de las ventas (producto elegido):';
SELECT codigo_producto, SUM(cantidad) AS stock_actual
FROM dbo.existencias
WHERE codigo_producto = @productoVenta
GROUP BY codigo_producto;

-- 4.1 Venta válida
BEGIN TRY
    EXEC dbo.sp_RegistrarVentaSimple
        @id_usuario_cliente = @clienteId,
        @canal              = N'web',
        @metodo_pago        = N'Tarjeta',
        @codigo_producto    = @productoVenta,
        @cantidad           = 2;
    PRINT 'Venta válida registrada correctamente (sp_RegistrarVentaSimple).';
END TRY
BEGIN CATCH
    PRINT 'Se produjo un error durante la venta válida (sp_RegistrarVentaSimple).';
END CATCH;

-- Stock después de la venta válida
PRINT 'Stock después de la venta válida:';
SELECT codigo_producto, SUM(cantidad) AS stock_despues_venta_valida
FROM dbo.existencias
WHERE codigo_producto = @productoVenta
GROUP BY codigo_producto;

-- 4.2 Venta inválida (stock insuficiente)
BEGIN TRY
    EXEC dbo.sp_RegistrarVentaSimple
        @id_usuario_cliente = @clienteId,
        @canal              = N'web',
        @metodo_pago        = N'Tarjeta',
        @codigo_producto    = @productoVenta,
        @cantidad           = 9999;  -- fuerza error de stock insuficiente
    PRINT 'ERROR: La venta inválida no debería completarse.';
END TRY
BEGIN CATCH
    PRINT 'Venta inválida por stock insuficiente correctamente detectada por el procedimiento.';
END CATCH;

-- Stock final tras ambas ventas
PRINT 'Stock final después de las pruebas de venta:';
SELECT codigo_producto, SUM(cantidad) AS stock_final
FROM dbo.existencias
WHERE codigo_producto = @productoVenta
GROUP BY codigo_producto;
GO
GO  -- Separador de lote antes de probar triggers

---------------------------------------------------------------
-- 5. PRUEBA DE TRIGGERS (alertas y auditoría)
---------------------------------------------------------------
PRINT '--- 5) TRIGGERS (alertas de stock bajo y auditoría) ---';

DECLARE @prodStockBajo INT;
SET @prodStockBajo = (SELECT TOP(1) codigo_producto FROM dbo.productos ORDER BY codigo_producto);

-- Forzar stock bajo para activar trigger
UPDATE dbo.existencias
SET cantidad = 3
WHERE codigo_producto = @prodStockBajo;

-- Alertas generadas por el trigger
PRINT 'Alertas generadas (stock_bajo):';
SELECT TOP(10) * FROM dbo.alertas ORDER BY id_alerta DESC;

-- Auditoría (solo en caso de errores en triggers)
PRINT 'Últimos registros en audit_log (si existieran errores de trigger):';
SELECT TOP(20) * FROM dbo.audit_log ORDER BY id_audit DESC;
GO

---------------------------------------------------------------
-- 6. PRUEBA DE INDEXACIÓN (consultas utilizando índices)
---------------------------------------------------------------
PRINT '--- 6) PRUEBA DE INDEXACIÓN (consultas típicas) ---';

-- Índice IX_productos_busqueda
PRINT 'Consulta típica por estilo/talla/color (usa IX_productos_busqueda):';
SELECT *
FROM dbo.productos
WHERE estilo = N'Formal'
  AND talla  = N'M'
  AND color  = N'Azul Marino';

-- Índice IX_existencias_producto
PRINT 'Stock por producto (usa IX_existencias_producto):';
SELECT e.codigo_producto, SUM(e.cantidad) AS stock_total
FROM dbo.existencias e
GROUP BY e.codigo_producto;

-- Índice IX_ventas_producto_fecha
PRINT 'Ventas recientes (usa IX_ventas_producto_fecha):';
SELECT TOP(10) v.codigo_producto, v.fecha_venta, v.cantidad, v.subtotal
FROM dbo.ventas v
ORDER BY v.fecha_venta DESC;
GO

PRINT 'Pruebas de conceptos completadas.';
GO
