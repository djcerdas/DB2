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

-- 3.1. Registrar un nuevo producto con existencia inicial
DECLARE @nuevoCodigo INT;
EXEC dbo.sp_RegistrarProducto
    @nombre           = N'Blazer Ejecutiva Azul',
    @talla            = N'M',
    @color            = N'Azul Marino',
    @estilo           = N'Formal',
    @precio_venta     = 45990,
    @imagen_url       = N'/images/blazer_ejecutiva_azul.jpg',
    @cantidad_inicial = 12,
    @fecha_ingreso    = CAST(GETDATE() AS DATE),
    @ubicacion_bodega = N'Bodega Central',
    @codigo_producto_out = @nuevoCodigo OUTPUT;

PRINT 'Nuevo producto creado con codigo_producto = ' + CAST(@nuevoCodigo AS NVARCHAR(20));

-- Verificar que exista en productos y existencias
SELECT * FROM dbo.productos   WHERE codigo_producto = @nuevoCodigo;
SELECT * FROM dbo.existencias WHERE codigo_producto = @nuevoCodigo;

-- 3.2. Registrar entrada de inventario para un producto existente
DECLARE @codigoExistente INT = (SELECT TOP(1) codigo_producto FROM dbo.productos ORDER BY codigo_producto);
EXEC dbo.sp_RegistrarEntradaInventario
    @codigo_producto  = @codigoExistente,
    @cantidad         = 5,
    @fecha_ingreso    = CAST(GETDATE() AS DATE),
    @ubicacion_bodega = N'Bodega Central - Estante A';

SELECT * FROM dbo.existencias WHERE codigo_producto = @codigoExistente;
GO

---------------------------------------------------------------
-- 4. PRUEBA DE CONTROL DE CONCURRENCIA (sp_RegistrarVentaSimple)
--    NOTA: esta prueba es secuencial, pero muestra:
--          - Validación de stock
--          - Actualización de facturas/ventas
--          - Uso de transacción y manejo de errores
---------------------------------------------------------------
PRINT '--- 4) CONTROL DE CONCURRENCIA EN VENTAS ---';

DECLARE @productoVenta INT = (SELECT TOP(1) codigo_producto FROM dbo.productos ORDER BY codigo_producto);
DECLARE @stockActual INT;

SELECT @stockActual = SUM(cantidad) FROM dbo.existencias WHERE codigo_producto = @productoVenta;
PRINT 'Stock actual antes de la venta = ' + CAST(ISNULL(@stockActual,0) AS NVARCHAR(20));

-- 4.1. Venta válida (cantidad menor o igual al stock)
BEGIN TRY
    EXEC dbo.sp_RegistrarVentaSimple
        @id_usuario_cliente = (SELECT id FROM dbo.users WHERE email=N'cliente@tienda.local'),
        @canal          = N'web',
        @metodo_pago    = N'Tarjeta',
        @codigo_producto= @productoVenta,
        @cantidad       = 2;
    PRINT 'Venta válida registrada correctamente.';
END TRY
BEGIN CATCH
    PRINT 'Error en venta válida: ' + ERROR_MESSAGE();
END CATCH;

-- 4.2. Venta inválida (fuerza stock insuficiente)
DECLARE @stockDespues INT;
SELECT @stockDespues = SUM(cantidad) FROM dbo.existencias WHERE codigo_producto = @productoVenta;
PRINT 'Stock después de venta válida = ' + CAST(ISNULL(@stockDespues,0) AS NVARCHAR(20));

BEGIN TRY
    EXEC dbo.sp_RegistrarVentaSimple
        @id_usuario_cliente = (SELECT id FROM dbo.users WHERE email=N'cliente@tienda.local'),
        @canal          = N'web',
        @metodo_pago    = N'Tarjeta',
        @codigo_producto= @productoVenta,
        @cantidad       = 9999; -- forzamos error de stock
    PRINT 'Venta inválida NO debería llegar a este mensaje.';
END TRY
BEGIN CATCH
    PRINT 'Venta inválida (stock insuficiente) protegida correctamente.';
    PRINT 'Mensaje: ' + ERROR_MESSAGE();
END CATCH;

SELECT @stockActual = SUM(cantidad) FROM dbo.existencias WHERE codigo_producto = @productoVenta;
PRINT 'Stock final después de intentos de venta = ' + CAST(ISNULL(@stockActual,0) AS NVARCHAR(20));
GO

---------------------------------------------------------------
-- 5. PRUEBA DE TRIGGERS (ALERTAS Y AUDITORÍA)
---------------------------------------------------------------
PRINT '--- 5) TRIGGERS (alertas de stock bajo y auditoría) ---';

-- 5.1. Forzar stock bajo para un producto
DECLARE @prodStockBajo INT = (SELECT TOP(1) codigo_producto FROM dbo.productos ORDER BY codigo_producto);

UPDATE dbo.existencias
SET cantidad = 3
WHERE codigo_producto = @prodStockBajo;

-- El trigger debe insertar una alerta de tipo 'stock_bajo'
SELECT TOP(10) * FROM dbo.alertas ORDER BY id_alerta DESC;

-- 5.2. Ver auditoría de productos (INSERT/UPDATE/DELETE)
UPDATE dbo.productos
SET precio_venta = precio_venta + 1000
WHERE codigo_producto = @prodStockBajo;

DELETE FROM dbo.productos
WHERE codigo_producto = @nuevoCodigo; -- producto creado en la prueba 3.1

SELECT TOP(20) * FROM dbo.audit_log ORDER BY id_audit DESC;
GO

---------------------------------------------------------------
-- 6. PRUEBA DE INDEXACIÓN (USO DE ÍNDICES)
--    No se puede "ver" el índice desde aquí, pero sí ejecutar
--    consultas típicas que se beneficiarían de ellos.
---------------------------------------------------------------
PRINT '--- 6) PRUEBA DE INDEXACIÓN (consultas típicas) ---';

-- Búsqueda por estilo/talla/color (usa IX_productos_busqueda)
SELECT *
FROM dbo.productos
WHERE estilo = N'Formal'
  AND talla  = N'M'
  AND color  = N'Azul Marino';

-- Consulta de stock por producto (usa IX_existencias_producto)
SELECT e.codigo_producto, SUM(e.cantidad) AS stock_total
FROM dbo.existencias e
GROUP BY e.codigo_producto;

-- Ventas por producto y fecha (usa IX_ventas_producto_fecha)
SELECT TOP(10) v.codigo_producto, v.fecha_venta, v.cantidad, v.subtotal
FROM dbo.ventas v
ORDER BY v.fecha_venta DESC;
GO

PRINT 'Pruebas de conceptos completadas.';
GO
