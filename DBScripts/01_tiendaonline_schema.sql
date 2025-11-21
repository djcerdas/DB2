/*==============================================================*
  TIENDAONLINE  - ESQUEMA DE BASE DE DATOS
  Motor : Microsoft SQL Server
  Teacher: Marlon Obando Cordero
  Autor : David Jesús Cerdas Pérez y Jerami Thomas Dudley Cerdas
  Nota  : Este script crea la base de datos, tablas, vistas,
          procedimientos almacenados, triggers, roles y permisos.
 *==============================================================*/

---------------------------------------------------------------
-- 0. CREACIÓN DE LA BASE DE DATOS
---------------------------------------------------------------
USE master;
IF DB_ID(N'tiendaonline') IS NULL
    CREATE DATABASE tiendaonline;
GO

USE tiendaonline;
GO

/*==============================================================*
  1. TABLAS DE SEGURIDAD (ROLES Y CONTROL DE ACCESO A NIVEL APP)
 *==============================================================*/

---------------------------------------------------------------
-- 1.1. Tabla de roles de aplicación
--      Implementa el concepto de ROLES en el dominio:
--      OWNER, GESTORINVENTARIO, VENDEDOR, CLIENTE, etc.
---------------------------------------------------------------
IF OBJECT_ID('dbo.roles','U') IS NOT NULL DROP TABLE dbo.roles;
CREATE TABLE dbo.roles (
    id          INT IDENTITY(1,1) CONSTRAINT PK_roles PRIMARY KEY,
    name        NVARCHAR(50)  NOT NULL UNIQUE,
    description NVARCHAR(255) NOT NULL
);

---------------------------------------------------------------
-- 1.2. Tabla de usuarios de aplicación
--      Representa las cuentas que se autenticará la página web.
---------------------------------------------------------------
IF OBJECT_ID('dbo.users','U') IS NOT NULL DROP TABLE dbo.users;
CREATE TABLE dbo.users (
    id            INT IDENTITY(1,1) CONSTRAINT PK_users PRIMARY KEY,
    email         NVARCHAR(255) NOT NULL UNIQUE,
    password_hash NVARCHAR(255) NOT NULL,        
    estado        BIT           NOT NULL DEFAULT 1,
    fecha_alta    DATETIME2     NOT NULL DEFAULT SYSUTCDATETIME()
);

---------------------------------------------------------------
-- 1.3. Define qué rol(es) tiene cada usuario.
---------------------------------------------------------------
IF OBJECT_ID('dbo.user_roles','U') IS NOT NULL DROP TABLE dbo.user_roles;
CREATE TABLE dbo.user_roles (
    user_id          INT NOT NULL,
    role_id          INT NOT NULL,
    fecha_asignacion DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_user_roles PRIMARY KEY (user_id, role_id),
    CONSTRAINT FK_user_roles_user FOREIGN KEY (user_id) REFERENCES dbo.users(id),
    CONSTRAINT FK_user_roles_role FOREIGN KEY (role_id) REFERENCES dbo.roles(id)
);

---------------------------------------------------------------
-- 1.4. Auditoría genérica (tabla de LOG)
--      Se usa desde triggers para registrar errores y eventos.
---------------------------------------------------------------
IF OBJECT_ID('dbo.audit_log','U') IS NOT NULL DROP TABLE dbo.audit_log;
CREATE TABLE dbo.audit_log (
    id_audit  BIGINT IDENTITY(1,1) PRIMARY KEY,
    tabla     NVARCHAR(128) NOT NULL,
    operacion NVARCHAR(20)  NOT NULL,          -- INSERT, UPDATE, DELETE, TRIGGER_ERROR
    llave     NVARCHAR(256) NOT NULL,          -- PK(s) afectados o contexto
    cambios   NVARCHAR(MAX) NULL,              -- detalle adicional o mensaje de error
    fecha     DATETIME2     NOT NULL DEFAULT SYSUTCDATETIME()
);

/*==============================================================*
  2. TABLAS DEL DOMINIO (NORMALIZADAS)
  Modelo lógico de la tienda:
  - Proveedores
  - Productos
  - Productos-Proveedores
  - Existencias
  - Ofertas
  - Facturas (encabezado)
  - Ventas (detalle)
  - Usuarios frecuentes (analítica)
  - Alertas
  - Notificaciones
 *==============================================================*/

---------------------------------------------------------------
-- 2.1. Catalogación de proveedores
---------------------------------------------------------------
IF OBJECT_ID('dbo.proveedores','U') IS NOT NULL DROP TABLE dbo.proveedores;
CREATE TABLE dbo.proveedores (
    id_proveedor    INT IDENTITY(1,1) CONSTRAINT PK_proveedores PRIMARY KEY,
    nombre          NVARCHAR(150) NOT NULL,
    ubicacion       NVARCHAR(255) NULL,
    email           NVARCHAR(255) NULL,
    telefono        NVARCHAR(50)  NULL
);

---------------------------------------------------------------
-- 2.2. Productos (catálogo principal)
---------------------------------------------------------------
IF OBJECT_ID('dbo.productos','U') IS NOT NULL DROP TABLE dbo.productos;
CREATE TABLE dbo.productos (
    codigo_producto INT IDENTITY(1,1) CONSTRAINT PK_productos PRIMARY KEY,
    nombre          NVARCHAR(150) NOT NULL,
    talla           NVARCHAR(10)  NOT NULL,
    color           NVARCHAR(30)  NOT NULL,
    estilo          NVARCHAR(50)  NULL,           -- casual, formal, deportivo, etc.
    precio_venta    DECIMAL(10,2) NOT NULL,
    estado          NVARCHAR(20)  NOT NULL DEFAULT 'ACTIVO', -- ACTIVO / INACTIVO
    imagen_url      NVARCHAR(500) NULL            -- URL / ruta de imagen
);

---------------------------------------------------------------
-- 2.3. Tabla intermedia Productos-Proveedores
--      Relación muchos a muchos con costo de compra.
---------------------------------------------------------------
IF OBJECT_ID('dbo.productos_proveedores','U') IS NOT NULL DROP TABLE dbo.productos_proveedores;
CREATE TABLE dbo.productos_proveedores (
    codigo_producto INT NOT NULL,
    id_proveedor    INT NOT NULL,
    costo_unitario  DECIMAL(10,2) NOT NULL,
    CONSTRAINT PK_productos_proveedores PRIMARY KEY (codigo_producto, id_proveedor),
    CONSTRAINT FK_pp_producto  FOREIGN KEY (codigo_producto) REFERENCES dbo.productos(codigo_producto),
    CONSTRAINT FK_pp_proveedor FOREIGN KEY (id_proveedor)    REFERENCES dbo.proveedores(id_proveedor)
);

---------------------------------------------------------------
-- 2.4. Existencias (bodega / inventario)
---------------------------------------------------------------
IF OBJECT_ID('dbo.existencias','U') IS NOT NULL DROP TABLE dbo.existencias;
CREATE TABLE dbo.existencias (
    id_existencia    INT IDENTITY(1,1) CONSTRAINT PK_existencias PRIMARY KEY,
    codigo_producto  INT NOT NULL,
    fecha_ingreso    DATE NOT NULL,
    cantidad         INT  NOT NULL CHECK (cantidad >= 0),
    ubicacion_bodega NVARCHAR(100) NULL,
    atractivo        BIT  NOT NULL DEFAULT 1,
    CONSTRAINT FK_existencias_producto FOREIGN KEY (codigo_producto)
        REFERENCES dbo.productos(codigo_producto)
);

---------------------------------------------------------------
-- 2.5. Ofertas comerciales
---------------------------------------------------------------
IF OBJECT_ID('dbo.ofertas','U') IS NOT NULL DROP TABLE dbo.ofertas;
CREATE TABLE dbo.ofertas (
    id_oferta       INT IDENTITY(1,1) CONSTRAINT PK_ofertas PRIMARY KEY,
    codigo_producto INT NOT NULL,
    descuento_pct   DECIMAL(5,2) NOT NULL CHECK (descuento_pct > 0 AND descuento_pct <= 90),
    fecha_inicio    DATE NOT NULL,
    fecha_fin       DATE NULL,
    estado          NVARCHAR(20) NOT NULL DEFAULT 'ACTIVA',  -- ACTIVA / INACTIVA
    motivo          NVARCHAR(255) NULL,
    CONSTRAINT FK_ofertas_producto FOREIGN KEY (codigo_producto) REFERENCES dbo.productos(codigo_producto)
);

---------------------------------------------------------------
-- 2.6. Facturas (encabezado de venta)
---------------------------------------------------------------
IF OBJECT_ID('dbo.facturas','U') IS NOT NULL DROP TABLE dbo.facturas;
CREATE TABLE dbo.facturas (
    numero_factura     BIGINT IDENTITY(1,1) CONSTRAINT PK_facturas PRIMARY KEY,
    fecha_venta        DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    id_usuario_cliente INT NULL,   -- FK a users.id con rol CLIENTE
    canal              NVARCHAR(20) NOT NULL,  -- tienda / web / redes
    metodo_pago        NVARCHAR(30) NOT NULL,
    tasa_iva           DECIMAL(5,2) NOT NULL DEFAULT 13.00,
    total_sin_iva      DECIMAL(12,2) NOT NULL DEFAULT 0,
    total_con_iva      AS (ROUND(total_sin_iva * (1 + tasa_iva/100.0), 2)) PERSISTED,
    CONSTRAINT FK_facturas_cliente FOREIGN KEY (id_usuario_cliente) REFERENCES dbo.users(id)
);

---------------------------------------------------------------
-- 2.7. Ventas (detalle de factura)
---------------------------------------------------------------
IF OBJECT_ID('dbo.ventas','U') IS NOT NULL DROP TABLE dbo.ventas;
CREATE TABLE dbo.ventas (
    id_venta            BIGINT IDENTITY(1,1) CONSTRAINT PK_ventas PRIMARY KEY,
    numero_factura      BIGINT NOT NULL,
    fecha_venta         DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    codigo_producto     INT NOT NULL,
    cantidad            INT NOT NULL CHECK (cantidad > 0),
    precio_unit_sin_IVA DECIMAL(10,2) NOT NULL,
    subtotal            AS (cantidad * precio_unit_sin_IVA) PERSISTED,
    CONSTRAINT FK_ventas_factura FOREIGN KEY (numero_factura) REFERENCES dbo.facturas(numero_factura),
    CONSTRAINT FK_ventas_producto FOREIGN KEY (codigo_producto) REFERENCES dbo.productos(codigo_producto)
);

---------------------------------------------------------------
-- 2.8. Usuarios frecuentes (analítica de clientes)
---------------------------------------------------------------
IF OBJECT_ID('dbo.usuarios_frecuentes','U') IS NOT NULL DROP TABLE dbo.usuarios_frecuentes;
CREATE TABLE dbo.usuarios_frecuentes (
    id_usuario     INT PRIMARY KEY,    -- FK a users.id
    edad           INT NULL,
    genero         NVARCHAR(20) NULL,
    rango_edad     NVARCHAR(20) NULL,
    ciudad         NVARCHAR(100) NULL,
    provincia      NVARCHAR(100) NULL,
    fecha_registro DATE NULL,
    preferencias   NVARCHAR(MAX) NULL,     -- JSON con gustos
    ticket_prom    DECIMAL(10,2) NULL,
    freq_mensual   DECIMAL(10,2) NULL,
    ultima_compra  DATETIME2 NULL,
    CONSTRAINT FK_uf_usuario FOREIGN KEY (id_usuario) REFERENCES dbo.users(id)
);

---------------------------------------------------------------
-- 2.9. Alertas internas (ej. stock bajo, inventario envejecido)
---------------------------------------------------------------
IF OBJECT_ID('dbo.alertas','U') IS NOT NULL DROP TABLE dbo.alertas;
CREATE TABLE dbo.alertas (
    id_alerta       BIGINT IDENTITY(1,1) CONSTRAINT PK_alertas PRIMARY KEY,
    tipo            NVARCHAR(30) NOT NULL,       -- stock_bajo / envejecido / otro
    codigo_producto INT NOT NULL,
    detalle         NVARCHAR(255) NOT NULL,
    fecha           DATETIME2     NOT NULL DEFAULT SYSUTCDATETIME(),
    leida           BIT           NOT NULL DEFAULT 0,
    CONSTRAINT FK_alertas_producto FOREIGN KEY (codigo_producto) REFERENCES dbo.productos(codigo_producto)
);

---------------------------------------------------------------
-- 2.10. Notificaciones hacia usuarios/administradores
---------------------------------------------------------------
IF OBJECT_ID('dbo.notificaciones','U') IS NOT NULL DROP TABLE dbo.notificaciones;
CREATE TABLE dbo.notificaciones (
    id_notif      BIGINT IDENTITY(1,1) CONSTRAINT PK_notificaciones PRIMARY KEY,
    canal         NVARCHAR(20)  NOT NULL,         -- in-app / email / sms
    destinatario  NVARCHAR(255) NOT NULL,
    asunto        NVARCHAR(150) NOT NULL,
    estado_envio  NVARCHAR(20)  NOT NULL DEFAULT 'PENDIENTE',
    fecha         DATETIME2     NOT NULL DEFAULT SYSUTCDATETIME()
);

/*==============================================================*
  3. ÍNDICES (INDEXACIÓN PARA BÚSQUEDAS RÁPIDAS)
 *==============================================================*/

---------------------------------------------------------------
-- 3.1. Índice compuesto para búsquedas por estilo/talla/color
---------------------------------------------------------------
CREATE INDEX IX_productos_busqueda
    ON dbo.productos (estilo, talla, color);

---------------------------------------------------------------
-- 3.2. Índice para stock por producto
---------------------------------------------------------------
CREATE INDEX IX_existencias_producto
    ON dbo.existencias (codigo_producto)
    INCLUDE (cantidad);

---------------------------------------------------------------
-- 3.3. Índice para facturas por fecha y canal
---------------------------------------------------------------
CREATE INDEX IX_facturas_fecha_canal
    ON dbo.facturas (fecha_venta, canal);

---------------------------------------------------------------
-- 3.4. Índice para ventas por producto y fecha
---------------------------------------------------------------
CREATE INDEX IX_ventas_producto_fecha
    ON dbo.ventas (codigo_producto, fecha_venta);

---------------------------------------------------------------
-- 3.5. Índice para alertas sin leer
---------------------------------------------------------------
CREATE INDEX IX_alertas_leida_fecha
    ON dbo.alertas (leida, fecha);

---------------------------------------------------------------
-- 3.6. Índice para segmentación de usuarios frecuentes
---------------------------------------------------------------
CREATE INDEX IX_uf_provincia_genero
    ON dbo.usuarios_frecuentes (provincia, genero);

/*==============================================================*
  4. VISTAS (CREATE VIEW)
 *==============================================================*/

---------------------------------------------------------------
-- 4.1. Catálogo de productos con stock y oferta vigente
---------------------------------------------------------------
IF OBJECT_ID('dbo.v_CatalogoProductos','V') IS NOT NULL DROP VIEW dbo.v_CatalogoProductos;
GO
CREATE VIEW dbo.v_CatalogoProductos
AS
SELECT
    p.codigo_producto,
    p.nombre,
    p.talla,
    p.color,
    p.estilo,
    p.precio_venta,
    p.imagen_url,
    ISNULL(SUM(e.cantidad), 0) AS stock_total,
    MAX(CASE WHEN o.estado = 'ACTIVA'
             THEN o.descuento_pct
             ELSE 0 END) AS descuento_pct_activo,
    CAST(
        p.precio_venta * (1 - (MAX(CASE WHEN o.estado='ACTIVA' THEN o.descuento_pct ELSE 0 END) / 100.0))
        AS DECIMAL(10,2)
    ) AS precio_con_descuento
FROM dbo.productos p
LEFT JOIN dbo.existencias e ON e.codigo_producto = p.codigo_producto
LEFT JOIN dbo.ofertas o     ON o.codigo_producto = p.codigo_producto
GROUP BY
    p.codigo_producto, p.nombre, p.talla, p.color, p.estilo, p.precio_venta, p.imagen_url;
GO

---------------------------------------------------------------
-- 4.2. Vista de productos con stock bajo
---------------------------------------------------------------
IF OBJECT_ID('dbo.v_StockBajo','V') IS NOT NULL DROP VIEW dbo.v_StockBajo;
GO
CREATE VIEW dbo.v_StockBajo
AS
SELECT
    p.codigo_producto,
    p.nombre,
    SUM(e.cantidad) AS stock_total
FROM dbo.productos p
JOIN dbo.existencias e ON e.codigo_producto = p.codigo_producto
GROUP BY p.codigo_producto, p.nombre
HAVING SUM(e.cantidad) < 10;
GO

---------------------------------------------------------------
-- 4.3. Vista resumen de ventas por día
---------------------------------------------------------------
IF OBJECT_ID('dbo.v_VentasPorDia','V') IS NOT NULL DROP VIEW dbo.v_VentasPorDia;
GO
CREATE VIEW dbo.v_VentasPorDia
AS
SELECT
    CAST(f.fecha_venta AS DATE) AS fecha,
    COUNT(DISTINCT f.numero_factura) AS cantidad_facturas,
    SUM(v.subtotal) AS total_sin_iva,
    SUM(f.total_con_iva) AS total_con_iva
FROM dbo.facturas f
JOIN dbo.ventas   v ON v.numero_factura = f.numero_factura
GROUP BY CAST(f.fecha_venta AS DATE);
GO

/*==============================================================*
  5. PROCEDIMIENTOS ALMACENADOS (BUSINESS LOGIC EN LA BD)
 *==============================================================*/

---------------------------------------------------------------
-- 5.1. Registrar un nuevo producto con existencia inicial
--      Implementa lógica de negocio + transacción + TRY/CATCH.
---------------------------------------------------------------
IF OBJECT_ID('dbo.sp_RegistrarProducto','P') IS NOT NULL DROP PROCEDURE dbo.sp_RegistrarProducto;
GO
CREATE PROCEDURE dbo.sp_RegistrarProducto
    @nombre              NVARCHAR(150),
    @talla               NVARCHAR(10),
    @color               NVARCHAR(30),
    @estilo              NVARCHAR(50),
    @precio_venta        DECIMAL(10,2),
    @imagen_url          NVARCHAR(500) = NULL,
    @cantidad_inicial    INT,
    @fecha_ingreso       DATE,
    @ubicacion_bodega    NVARCHAR(100) = NULL,
    @codigo_producto_out INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRAN;

        INSERT INTO dbo.productos(nombre, talla, color, estilo, precio_venta, imagen_url)
        VALUES(@nombre, @talla, @color, @estilo, @precio_venta, @imagen_url);

        SET @codigo_producto_out = SCOPE_IDENTITY();

        INSERT INTO dbo.existencias(codigo_producto, fecha_ingreso, cantidad, ubicacion_bodega)
        VALUES(@codigo_producto_out, @fecha_ingreso, @cantidad_inicial, @ubicacion_bodega);

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRAN;
        THROW;
    END CATCH
END;
GO

---------------------------------------------------------------
-- 5.2. Registrar una entrada de inventario (compra o ajuste)
---------------------------------------------------------------
IF OBJECT_ID('dbo.sp_RegistrarEntradaInventario','P') IS NOT NULL DROP PROCEDURE dbo.sp_RegistrarEntradaInventario;
GO
CREATE PROCEDURE dbo.sp_RegistrarEntradaInventario
    @codigo_producto  INT,
    @cantidad         INT,
    @fecha_ingreso    DATE,
    @ubicacion_bodega NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRAN;

        DECLARE @id_existencia INT;

        SELECT @id_existencia = id_existencia
        FROM dbo.existencias
        WHERE codigo_producto = @codigo_producto;

        IF @id_existencia IS NULL
        BEGIN
            INSERT INTO dbo.existencias (codigo_producto, fecha_ingreso, cantidad, ubicacion_bodega)
            VALUES (@codigo_producto, @fecha_ingreso, @cantidad, @ubicacion_bodega);
        END
        ELSE
        BEGIN
            UPDATE dbo.existencias
            SET cantidad      = cantidad + @cantidad,
                fecha_ingreso = CASE WHEN fecha_ingreso > @fecha_ingreso THEN @fecha_ingreso ELSE fecha_ingreso END
            WHERE id_existencia = @id_existencia;
        END

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRAN;
        THROW;
    END CATCH
END;
GO

---------------------------------------------------------------
-- 5.3. Registrar venta simple con control de concurrencia
--      Usa aislamiento SERIALIZABLE y bloqueos UPDLOCK/HOLDLOCK.
---------------------------------------------------------------
IF OBJECT_ID('dbo.sp_RegistrarVentaSimple','P') IS NOT NULL DROP PROCEDURE dbo.sp_RegistrarVentaSimple;
GO
CREATE PROCEDURE dbo.sp_RegistrarVentaSimple
    @id_usuario_cliente INT = NULL,
    @canal              NVARCHAR(20),
    @metodo_pago        NVARCHAR(30),
    @codigo_producto    INT,
    @cantidad           INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @precio_base    DECIMAL(10,2);
    DECLARE @descuento      DECIMAL(5,2);
    DECLARE @precio_final   DECIMAL(10,2);
    DECLARE @total_sin_iva  DECIMAL(12,2);
    DECLARE @numero_factura BIGINT;

    BEGIN TRY
        SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
        BEGIN TRAN;

        -- Precio base y descuento activo
        SELECT TOP(1)
            @precio_base = p.precio_venta,
            @descuento   = ISNULL(o.descuento_pct, 0)
        FROM dbo.productos p
        LEFT JOIN dbo.ofertas o
            ON o.codigo_producto = p.codigo_producto
           AND o.estado = 'ACTIVA'
           AND (o.fecha_fin IS NULL OR o.fecha_fin >= CAST(SYSUTCDATETIME() AS DATE))
        WHERE p.codigo_producto = @codigo_producto;

        IF @precio_base IS NULL
            RAISERROR('Producto no encontrado', 16, 1);

        -- Bloqueo sobre la fila de existencias para evitar sobreventa
        SELECT TOP(1) *
        FROM dbo.existencias WITH (UPDLOCK, HOLDLOCK)
        WHERE codigo_producto = @codigo_producto;

        DECLARE @stock INT;
        SELECT @stock = SUM(cantidad)
        FROM dbo.existencias
        WHERE codigo_producto = @codigo_producto;

        IF @stock IS NULL OR @stock < @cantidad
            RAISERROR('Stock insuficiente', 16, 1);

        SET @precio_final  = @precio_base * (1 - (@descuento / 100.0));
        SET @total_sin_iva = @precio_final * @cantidad;

        INSERT INTO dbo.facturas(id_usuario_cliente, canal, metodo_pago, total_sin_iva)
        VALUES(@id_usuario_cliente, @canal, @metodo_pago, @total_sin_iva);

        SET @numero_factura = SCOPE_IDENTITY();

        INSERT INTO dbo.ventas(numero_factura, codigo_producto, cantidad, precio_unit_sin_IVA)
        VALUES(@numero_factura, @codigo_producto, @cantidad, @precio_final);

        -- Descontar stock (ejemplo simplificado)
        UPDATE TOP(1) dbo.existencias
        SET cantidad = cantidad - @cantidad
        WHERE codigo_producto = @codigo_producto
          AND cantidad >= @cantidad;

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRAN;
        THROW;
    END CATCH
END;
GO

---------------------------------------------------------------
-- 5.4. Revisar inventario envejecido y proponer ofertas
---------------------------------------------------------------
IF OBJECT_ID('dbo.sp_RevisarInventarioEnvejecido','P') IS NOT NULL DROP PROCEDURE dbo.sp_RevisarInventarioEnvejecido;
GO
CREATE PROCEDURE dbo.sp_RevisarInventarioEnvejecido
    @descuento_por_defecto DECIMAL(5,2) = 20.0,
    @dias_en_bodega        INT          = 60
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @hoy DATE = CAST(SYSUTCDATETIME() AS DATE);

    BEGIN TRY
        BEGIN TRAN;

        -- Marcar existencias como no atractivas por antigüedad
        UPDATE dbo.existencias
        SET atractivo = 0
        WHERE DATEDIFF(DAY, fecha_ingreso, @hoy) >= @dias_en_bodega;

        -- Crear ofertas por envejecimiento si no existe una activa
        INSERT INTO dbo.ofertas(codigo_producto, descuento_pct, fecha_inicio, motivo)
        SELECT DISTINCT
            e.codigo_producto,
            @descuento_por_defecto,
            @hoy,
            N'Inventario envejecido (>= ' + CAST(@dias_en_bodega AS NVARCHAR(10)) + N' días en bodega)'
        FROM dbo.existencias e
        LEFT JOIN dbo.ofertas o
            ON o.codigo_producto = e.codigo_producto
           AND o.estado = 'ACTIVA'
        WHERE DATEDIFF(DAY, e.fecha_ingreso, @hoy) >= @dias_en_bodega
          AND o.id_oferta IS NULL;

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRAN;
        THROW;
    END CATCH
END;
GO

/*==============================================================*
  6. TRIGGER DE ALERTA (STOCK BAJO) CON TRY/CATCH
 *==============================================================*/

---------------------------------------------------------------
-- 6.1. Trigger: alerta por stock bajo en existencias
--      Implementa reactividad en la BD y se apoya en audit_log.
---------------------------------------------------------------
IF OBJECT_ID('dbo.trg_existencias_stock_bajo','TR') IS NOT NULL
    DROP TRIGGER dbo.trg_existencias_stock_bajo;
GO
CREATE TRIGGER dbo.trg_existencias_stock_bajo
ON dbo.existencias
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        ;WITH CTE AS (
            SELECT
                e.codigo_producto,
                SUM(e.cantidad) AS stock_total
            FROM dbo.existencias e
            JOIN inserted i ON i.codigo_producto = e.codigo_producto
            GROUP BY e.codigo_producto
        )
        INSERT INTO dbo.alertas(tipo, codigo_producto, detalle)
        SELECT
            'stock_bajo',
            c.codigo_producto,
            N'Stock bajo: ' + CAST(c.stock_total AS NVARCHAR(10)) + N' unidades.'
        FROM CTE c
        WHERE c.stock_total < 10;
    END TRY
    BEGIN CATCH
        INSERT INTO dbo.audit_log(tabla, operacion, llave, cambios)
        VALUES(
            N'existencias',
            N'TRIGGER_ERROR',
            N'INSERT/UPDATE',
            ERROR_MESSAGE()
        );
        -- No se relanza la excepción para no bloquear la transacción principal.
        -- Si se requiere un comportamiento más estricto, se puede usar: THROW;
    END CATCH
END;
GO

/*==============================================================*
  7. ROLES DE BASE DE DATOS Y PERMISOS (SEGURIDAD A NIVEL BD)
 *==============================================================*/

---------------------------------------------------------------
-- 7.1. CONTEXTO DE SEGURIDAD (COMENTARIOS)
--
--  Tipo_Usuario ; Rol      ; Responsabilidades
--  -------------------------------------------------------------
--  Administrador ; SysAdmin; Mantenimiento de la base de datos,
--                           ; copias de seguridad, gestión de permisos.
--
--  Dueño         ; OWNER   ; Consultar reportes, tomar decisiones
--                           ; estratégicas, aprobar ofertas.
--
--  Empleado      ; GestorInventario ; Gestionar productos, actualizar
--                                    ; inventario, controlar alertas.
--
--  Empleado      ; Vendedor; Registrar ventas, emitir facturas,
--                           ; aplicar ofertas activas.
--
--  Cliente       ; Cliente ; Ver catálogo, realizar compras, consultar
--                           ; sus propias facturas/pedidos.
--
--  Proveedor     ; Proveedor; Actualizar información de costos y
--                             ; disponibilidad de sus productos.
--
--  Empleado      ; Marketing; Analizar métricas, segmentar clientes,
--                             ; proponer campañas/ofertas.
--
--  Importante:
--  - El "SysAdmin" (Administrador) es el único que debe tener la
--    capacidad de modificar la estructura de la BD (tablas, vistas,
--    procedimientos, triggers, índices).
--  - El Dueño (OWNER) NO debe tener privilegios elevados a nivel de
--    base de datos; su interacción se hace únicamente a través de la
--    aplicación web y de vistas/consultas autorizadas.
---------------------------------------------------------------

---------------------------------------------------------------
-- 7.2. Roles de base de datos para la aplicación
--      app_sysadmin : administración de esquema (asociado a DBA)
--      app_owner    : lectura y ejecución de SPs aprobados
--      app_rw       : lectura / escritura (usuario técnico de app)
--      app_ro       : solo lectura (reportes / consultas)
---------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'app_sysadmin')
    CREATE ROLE app_sysadmin;

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'app_owner')
    CREATE ROLE app_owner;
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'app_rw')
    CREATE ROLE app_rw;
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'app_ro')
    CREATE ROLE app_ro;

---------------------------------------------------------------
-- 7.3. Permisos para roles de base de datos
---------------------------------------------------------------

-- app_sysadmin: CONTROL sobre el esquema dbo
-- (pensado para el Administrador / DBA, normalmente con rol
--  sysadmin a nivel de servidor).
GRANT CONTROL ON SCHEMA::dbo TO app_sysadmin;

-- app_owner: solo lectura y ejecución de SPs aprobados.
-- Se revoca explícitamente cualquier CONTROL previo sobre dbo.
REVOKE CONTROL ON SCHEMA::dbo FROM app_owner;

-- Lectura sobre vistas clave de negocio
GRANT SELECT ON dbo.v_CatalogoProductos TO app_owner;
GRANT SELECT ON dbo.v_StockBajo         TO app_owner;
GRANT SELECT ON dbo.v_VentasPorDia      TO app_owner;

-- Lectura sobre tablas principales (para reportes avanzados)
GRANT SELECT ON dbo.productos           TO app_owner;
GRANT SELECT ON dbo.existencias         TO app_owner;
GRANT SELECT ON dbo.ofertas             TO app_owner;
GRANT SELECT ON dbo.facturas            TO app_owner;
GRANT SELECT ON dbo.ventas              TO app_owner;
GRANT SELECT ON dbo.usuarios_frecuentes TO app_owner;
GRANT SELECT ON dbo.alertas             TO app_owner;
GRANT SELECT ON dbo.notificaciones      TO app_owner;

-- Ejecución de procedimientos que forman parte del flujo de negocio
GRANT EXECUTE ON dbo.sp_RegistrarProducto           TO app_owner;
GRANT EXECUTE ON dbo.sp_RegistrarEntradaInventario  TO app_owner;
GRANT EXECUTE ON dbo.sp_RegistrarVentaSimple        TO app_owner;
GRANT EXECUTE ON dbo.sp_RevisarInventarioEnvejecido TO app_owner;

-- app_rw: permisos CRUD y ejecución de SP (para cuenta técnica app_user)
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.productos           TO app_rw;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.existencias         TO app_rw;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.ofertas             TO app_rw;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.facturas            TO app_rw;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.ventas              TO app_rw;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.proveedores         TO app_rw;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.usuarios_frecuentes TO app_rw;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.alertas             TO app_rw;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.notificaciones      TO app_rw;

GRANT SELECT ON dbo.roles, dbo.users, dbo.user_roles TO app_rw;

GRANT EXECUTE ON dbo.sp_RegistrarProducto           TO app_rw;
GRANT EXECUTE ON dbo.sp_RegistrarEntradaInventario  TO app_rw;
GRANT EXECUTE ON dbo.sp_RegistrarVentaSimple        TO app_rw;
GRANT EXECUTE ON dbo.sp_RevisarInventarioEnvejecido TO app_rw;

-- app_ro: solo lectura sobre vistas y tablas clave
GRANT SELECT ON dbo.v_CatalogoProductos TO app_ro;
GRANT SELECT ON dbo.v_StockBajo         TO app_ro;
GRANT SELECT ON dbo.v_VentasPorDia      TO app_ro;

GRANT SELECT ON dbo.productos     TO app_ro;
GRANT SELECT ON dbo.existencias   TO app_ro;
GRANT SELECT ON dbo.ofertas       TO app_ro;
GRANT SELECT ON dbo.facturas      TO app_ro;
GRANT SELECT ON dbo.ventas        TO app_ro;

PRINT 'Esquema TiendaOnline creado y permisos configurados correctamente.';
GO
