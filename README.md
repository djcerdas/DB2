# TiendaOnline – Software web para potenciar tienda de ropa

Proyecto académico para el curso **Bases de Datos II** (Universidad Latina de Costa Rica).

Autores:
- Jerami Thomas Dudley Cerdas
- David Jesús Cerdas Pérez

Profesor:
- Marlon Obando Cordero

---

## 1. Descripción general

Este proyecto implementa una **aplicación web** conectada a **Microsoft SQL Server** para gestionar el inventario y las ventas de una tienda de ropa física, permitiendo:

- Catálogo de productos con talla, color, estilo y precio.
- Control de existencias en bodega.
- Ofertas y descuentos automáticos para inventario envejecido.
- Registro de facturas y detalle de ventas.
- Usuarios con roles (OWNER, GestorInventario, Vendedor, Cliente, etc.).
- Vistas, procedimientos almacenados, triggers, control de concurrencia e índices.

La versión actual corresponde a la **Tienda Online 1.0**, pero en el repositorio y en el código se hace referencia únicamente como **TiendaOnline** (sin sufijos de versión).

---

## 2. Estructura de los scripts SQL

El proyecto utiliza **tres archivos principales .sql** para la base de datos (MS SQL Server):

1. `01_tiendaonline_schema.sql`  
   - Crea la base de datos `tiendaonline`.
   - Crea todas las tablas normalizadas:
     - `roles`, `users`, `user_roles`
     - `proveedores`, `productos`, `productos_proveedores`
     - `existencias`, `ofertas`
     - `facturas`, `ventas`
     - `usuarios_frecuentes`, `alertas`, `notificaciones`
   - Crea índices para mejorar el rendimiento de las consultas.
   - Crea vistas:
     - `v_CatalogoProductos`
     - `v_StockBajo`
     - `v_VentasPorDia`
   - Crea procedimientos almacenados con **TRY/CATCH** y transacciones:
     - `sp_RegistrarProducto`
     - `sp_RegistrarEntradaInventario`
     - `sp_RegistrarVentaSimple`
     - `sp_RevisarInventarioEnvejecido`
   - Crea un trigger con TRY/CATCH:
     - `trg_existencias_stock_bajo`
   - Configura roles de base de datos:
     - `app_sysadmin`, `app_owner`, `app_rw`, `app_ro`
   - Asigna permisos a cada rol de acuerdo con el análisis de usuarios:
     - Sólo el **Administrador / SysAdmin (DBA)** puede modificar la estructura de la base de datos.
     - El **Dueño (Owner)** sólo consulta información a través de la aplicación.

2. `02_tiendaonline_seed.sql`  
   - Debe ejecutarse después del esquema.
   - Inserta:
     - Roles de aplicación.
     - Usuarios iniciales (SysAdmin, Owner, GestorInventario, Vendedor, Cliente, etc.).
     - Productos de ejemplo (camisetas, pantalones, vestidos, etc.).
     - Proveedores de ejemplo.
     - Existencias en bodega.
     - Ofertas iniciales.
   - Prepara datos suficientes para probar consultas, vistas, triggers y procedimientos.

3. `03_tiendaonline_tests.sql`  
   - Script de **pruebas y demostración**:
     - Ejecuta consultas sobre las vistas (`v_CatalogoProductos`, `v_StockBajo`, `v_VentasPorDia`).
     - Llama a los procedimientos almacenados para:
       - Registrar un producto nuevo con existencia inicial.
       - Registrar entradas de inventario.
       - Registrar ventas y validar el control de stock.
     - Verifica la generación de alertas por stock bajo.
   - Este script permite mostrar al profesor/cliente final que cada concepto funciona:
     - Roles y control de acceso.
     - Vistas.
     - Índices.
     - Procedimientos almacenados con TRY/CATCH.
     - Trigger de stock bajo.
     - Control de concurrencia.

---

## 3. Cómo instalar la base de datos

### 3.1. Requisitos

- Microsoft SQL Server (Developer / Express / Standard).
- SQL Server Management Studio (SSMS) o herramienta equivalente.
- Permisos para crear bases de datos.

### 3.2. Pasos

1. Abrir SSMS y conectarse al servidor.
2. Ejecutar el script de esquema:

   ```sql
   -- Ejecutar completo
   :r 01_tiendaonline_schema.sql
   ```

   O copiar y pegar el contenido de `01_tiendaonline_schema.sql` y ejecutarlo.

3. Verificar que la base de datos `tiendaonline` se haya creado:

   ```sql
   SELECT name FROM sys.databases WHERE name = 'tiendaonline';
   ```

4. Ejecutar el script de datos de semilla:

   ```sql
   :r 02_tiendaonline_seed.sql
   ```

5. Opcional: ejecutar el script de pruebas para validar todos los conceptos:

   ```sql
   :r 03_tiendaonline_tests.sql
   ```

---

## 4. Proyecto web en Eclipse

### 4.1. Tecnologías utilizadas

- Java 17 (o 11 según configuración).
- Maven.
- Spark Java (mini framework web para rutas HTTP).
- JSP/HTML estático para la interfaz.
- JDBC para conexión a SQL Server.
- CSS sencillo con zonas reservadas para imágenes e identidad visual futura.

### 4.2. Estructura del proyecto

El ZIP del proyecto web incluye un directorio raíz, por ejemplo:

- `TiendaOnlineWeb/`
  - `pom.xml`
  - `src/main/java/com/ulatina/basesdedatos2/tiendaonline/...`
    - `config/` → clases de configuración (DB, rutas base).
    - `controller/` → controladores por rol:
      - `OwnerController`
      - `InventoryController`
      - `SalesController`
      - `ClientController`
      - `AuthController`
    - `repository/` → acceso a datos:
      - `ProductRepository`
      - `InventoryRepository`
      - `UserRepository`
      - `ReportRepository`
    - `service/` → lógica de negocio:
      - `InventoryService`
      - `AuthService`
      - `DbTestService`
    - `web/` → definición de rutas en Spark:
      - `Routes.java`
  - `src/main/resources/public/`
    - `style.css` (diseño básico, colores suaves, espacios para imágenes).
    - `login.html`
    - `owner.html`
    - `gestor.html`
    - `vendedor.html`
    - `cliente.html`

Cada pantalla incluye **botones y opciones alineadas al rol**:
- OWNER: reportes, resumen de ventas, ofertas activas, inventario envejecido.
- GestorInventario: alta/baja/modificación de productos, existencias, ofertas.
- Vendedor: registrar ventas, consultar facturas recientes.
- Cliente: ver catálogo, simular compra/pruebas con vistas.
- SysAdmin/DBA: pruebas de conexión y diagnóstico (no modifica estructura).

---

## 5. Configuración de la conexión a la base de datos

> Nota: Ajustar estos pasos según cómo esté implementada la clase de conexión en el código.

1. Ubicar la clase de configuración de base de datos, por ejemplo:

   - `src/main/java/com/ulatina/basesdedatos2/tiendaonline/config/DatabaseConfig.java`

2. Editar los parámetros de conexión:

   ```java
   private static final String URL  = "jdbc:sqlserver://localhost:1433;databaseName=tiendaonline;encrypt=false;";
   private static final String USER = "tu_usuario_sql";
   private static final String PASS = "tu_password_sql";
   ```

3. Asegurarse de que el usuario de SQL Server tenga al menos:
   - Rol de base de datos asignado (`app_rw` o `app_ro` según el caso).
   - Permisos para conectar y ejecutar los procedimientos necesarios.

---

## 6. Importar el proyecto en Eclipse

1. Abrir **Eclipse IDE**.
2. Ir a: `File` → `Import...`.
3. Seleccionar: `Existing Maven Projects`.
4. En *Root Directory*, seleccionar la carpeta `TiendaOnlineWeb/`.
5. Finalizar el asistente de importación.
6. Esperar a que Maven descargue las dependencias.
7. Verificar que el proyecto compile sin errores.

---

## 7. Ejecutar la aplicación web

1. En Eclipse, localizar la clase principal, por ejemplo:

   - `src/main/java/com/ulatina/basesdedatos2/tiendaonline/web/Routes.java`

2. Ejecutar como **Java Application**.
3. Abrir el navegador y acceder a:

   - `http://localhost:4567/`

4. Probar el login con los usuarios de ejemplo creados en `02_tiendaonline_seed.sql`.
5. Navegar por las interfaces de cada rol y realizar pruebas:
   - Consultar catálogo.
   - Registrar ventas.
   - Probar alertas de stock bajo.
   - Consultar reportes.

---

## 8. Notas finales

- Este proyecto está orientado a fines **académicos**, demostrando:
  - Normalización de la base de datos.
  - Implementación de **roles**, **control de acceso**, **vistas**, **procedimientos almacenados**, **triggers**, **control de concurrencia** e **indexación**.
  - Integración de una aplicación web en Java con SQL Server.
- La lógica y la interfaz están documentadas y pensadas para ser presentadas a un **cliente final** o en defensa de proyecto universitario.
