/*==============================================================*
  TIENDAONLINE - DATOS DE SEMILLA (SEED)
  Motor : Microsoft SQL Server
  Objetivo: Población inicial para pruebas y demostraciones.
 *==============================================================*/

USE tiendaonline;
GO

---------------------------------------------------------------
-- 1. ROLES DE APLICACIÓN
---------------------------------------------------------------
INSERT INTO dbo.roles (name, description)
VALUES
    (N'OWNER',            N'Propietario de la tienda – acceso total en la aplicación'),
    (N'GESTORINVENTARIO', N'Gestión de inventario, proveedores y alertas'),
    (N'VENDEDOR',         N'Ventas y consultas de catálogo'),
    (N'CLIENTE',          N'Cliente final que compra desde la web');
GO

---------------------------------------------------------------
-- 2. USUARIOS DE APLICACIÓN
--    Nota: password_hash se usa como texto plano solo con fines
--    académicos. En producción debe almacenarse un hash seguro.
---------------------------------------------------------------
INSERT INTO dbo.users (email, password_hash)
VALUES
    (N'owner@tienda.local',     N'Owner123!'),
    (N'inventario@tienda.local',N'Gestor123!'),
    (N'ventas@tienda.local',    N'Vendedor123!'),
    (N'cliente@tienda.local',   N'Cliente123!');
GO

---------------------------------------------------------------
-- 3. ASIGNACIÓN DE ROLES A USUARIOS
---------------------------------------------------------------
DECLARE
  @r_OWNER  INT = (SELECT id FROM dbo.roles WHERE name=N'OWNER'),
  @r_GEST   INT = (SELECT id FROM dbo.roles WHERE name=N'GESTORINVENTARIO'),
  @r_VEND   INT = (SELECT id FROM dbo.roles WHERE name=N'VENDEDOR'),
  @r_CLI    INT = (SELECT id FROM dbo.roles WHERE name=N'CLIENTE');

DECLARE
  @u_OWNER  INT = (SELECT id FROM dbo.users WHERE email=N'owner@tienda.local'),
  @u_GEST   INT = (SELECT id FROM dbo.users WHERE email=N'inventario@tienda.local'),
  @u_VEND   INT = (SELECT id FROM dbo.users WHERE email=N'ventas@tienda.local'),
  @u_CLI    INT = (SELECT id FROM dbo.users WHERE email=N'cliente@tienda.local');

IF NOT EXISTS (SELECT 1 FROM dbo.user_roles WHERE user_id=@u_OWNER AND role_id=@r_OWNER)
  INSERT INTO dbo.user_roles(user_id, role_id) VALUES(@u_OWNER, @r_OWNER);
IF NOT EXISTS (SELECT 1 FROM dbo.user_roles WHERE user_id=@u_GEST AND role_id=@r_GEST)
  INSERT INTO dbo.user_roles(user_id, role_id) VALUES(@u_GEST, @r_GEST);
IF NOT EXISTS (SELECT 1 FROM dbo.user_roles WHERE user_id=@u_VEND AND role_id=@r_VEND)
  INSERT INTO dbo.user_roles(user_id, role_id) VALUES(@u_VEND, @r_VEND);
IF NOT EXISTS (SELECT 1 FROM dbo.user_roles WHERE user_id=@u_CLI AND role_id=@r_CLI)
  INSERT INTO dbo.user_roles(user_id, role_id) VALUES(@u_CLI, @r_CLI);
GO

---------------------------------------------------------------
-- 4. PROVEEDORES
---------------------------------------------------------------
INSERT INTO dbo.proveedores (nombre, ubicacion, email, telefono)
VALUES
    (N'Fashion CR Imports', N'San José, Costa Rica', N'contacto@fashioncr.com', N'+506 2222-0001'),
    (N'Boutique Europa',    N'Barcelona, España',    N'sales@boutique-europa.es', N'+34 93 000 000'),
    (N'Asia Trends',        N'Seúl, Corea del Sur',  N'info@asiatrends.kr', N'+82 2-000-0000');
GO

---------------------------------------------------------------
-- 5. PRODUCTOS (CATÁLOGO BÁSICO)
---------------------------------------------------------------
INSERT INTO dbo.productos (nombre, talla, color, estilo, precio_venta, imagen_url)
VALUES
    (N'Blusa Seda Clásica',     N'S',  N'Blanco',   N'Formal',   24990, N'/images/blusa_seda_classic.jpg'),
    (N'Blusa Seda Clásica',     N'M',  N'Blanco',   N'Formal',   24990, N'/images/blusa_seda_classic.jpg'),
    (N'Camisa Lino Casual',     N'M',  N'Azul',     N'Casual',   19990, N'/images/camisa_lino_casual_azul.jpg'),
    (N'Camisa Lino Casual',     N'L',  N'Verde',    N'Casual',   19990, N'/images/camisa_lino_casual_verde.jpg'),
    (N'Pantalón Slim Fit',      N'32', N'Negro',    N'Formal',   29990, N'/images/pantalon_slimfit_negro.jpg'),
    (N'Pantalón Slim Fit',      N'34', N'Negro',    N'Formal',   29990, N'/images/pantalon_slimfit_negro.jpg'),
    (N'Vestido Cóctel Encaje',  N'M',  N'Rojo',     N'Fiesta',   39990, N'/images/vestido_cocktail_rojo.jpg'),
    (N'Chaqueta Casual Unisex', N'M',  N'Beige',    N'Casual',   34990, N'/images/chaqueta_casual_beige.jpg');
GO

---------------------------------------------------------------
-- 6. RELACIÓN PRODUCTOS-PROVEEDORES (COSTOS)
---------------------------------------------------------------
INSERT INTO dbo.productos_proveedores (codigo_producto, id_proveedor, costo_unitario)
SELECT p.codigo_producto, pr.id_proveedor,
       CASE
            WHEN p.estilo = N'Formal' THEN 15000
            WHEN p.estilo = N'Fiesta' THEN 20000
            ELSE 12000
       END AS costo_unitario
FROM dbo.productos p
CROSS JOIN (SELECT id_proveedor FROM dbo.proveedores) pr;
GO

---------------------------------------------------------------
-- 7. EXISTENCIAS INICIALES
---------------------------------------------------------------
INSERT INTO dbo.existencias (codigo_producto, fecha_ingreso, cantidad, ubicacion_bodega)
SELECT codigo_producto,
       CAST(GETDATE() AS DATE),
       CASE WHEN codigo_producto % 2 = 0 THEN 20 ELSE 8 END AS cantidad,
       N'Bodega Central'
FROM dbo.productos;
GO

---------------------------------------------------------------
-- 8. OFERTAS INICIALES
---------------------------------------------------------------
DECLARE @today DATE = CAST(GETDATE() AS DATE);

INSERT INTO dbo.ofertas (codigo_producto, descuento_pct, fecha_inicio, fecha_fin, motivo, creada_por)
SELECT TOP(3)
       codigo_producto,
       15,
       @today,
       DATEADD(DAY, 15, @today),
       N'Promoción de lanzamiento',
       (SELECT TOP(1) id FROM dbo.users WHERE email=N'owner@tienda.local')
FROM dbo.productos
ORDER BY codigo_producto;
GO

---------------------------------------------------------------
-- 9. USUARIOS FRECUENTES (CLIENTE DEMO)
---------------------------------------------------------------
DECLARE @clienteId INT = (SELECT id FROM dbo.users WHERE email=N'cliente@tienda.local');

IF NOT EXISTS (SELECT 1 FROM dbo.usuarios_frecuentes WHERE id_usuario=@clienteId)
BEGIN
    INSERT INTO dbo.usuarios_frecuentes
        (id_usuario, edad, genero, rango_edad, ciudad, provincia, fecha_registro,
         preferencias, ticket_prom, freq_mensual, ultima_compra)
    VALUES
        (@clienteId, 32, N'Femenino', N'30-39', N'Curridabat', N'San José',
         CAST(GETDATE() AS DATE),
         N'{"colores":["rojo","negro"],"estilos":["Formal","Fiesta"]}',
         35000, 3, NULL);
END
GO

PRINT 'Datos de semilla cargados correctamente.';
GO
