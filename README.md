# TiendaOnline – Software web para potenciar tienda de ropa

Proyecto académico para el curso **Bases de Datos II** (Universidad Latina de Costa Rica).

Autores:  
- Jerami Thomas Dudley Cerdas  
- David Jesús Cerdas Pérez  

Profesor:  
- Marlon Obando Cordero

---

## 1. Descripción general

Este proyecto implementa una **aplicación web en Java** conectada a **Microsoft SQL Server** para gestionar inventario, ventas y operaciones internas de una tienda de ropa. Incluye:

- Catálogo de productos con talla, estilo, color y precio.
- Control de existencias y bodega.
- Ofertas automáticas basadas en inventario envejecido.
- Registro de ventas con control de concurrencia.
- Trigger de stock bajo.
- Vistas de catálogo, stock y métricas diarias.
- Roles de aplicación (OWNER, GestorInventario, Vendedor, Cliente).
- Roles de base de datos (`app_sysadmin`, `app_owner`, `app_rw`, `app_ro`).
- Stored procedures con TRY/CATCH y transacciones.

La versión actual corresponde a **TiendaOnline 1.0** (referida como *TiendaOnline* en el código).

---

## 2. Estructura de los scripts SQL

El proyecto utiliza **tres scripts principales**:

### 2.1. `01_tiendaonline_schema.sql`
- Crea la base de datos `tiendaonline`.  
- Crea tablas normalizadas del dominio:
  - `roles`, `users`, `user_roles`, `audit_log`
  - `proveedores`, `productos`, `productos_proveedores`
  - `existencias`, `ofertas`
  - `facturas`, `ventas`
  - `usuarios_frecuentes`, `alertas`, `notificaciones`
- Crea índices de búsqueda y optimización.
- Crea vistas:
  - `v_CatalogoProductos`
  - `v_StockBajo`
  - `v_VentasPorDia`
- Define procedimientos almacenados:
  - `sp_RegistrarProducto`
  - `sp_RegistrarEntradaInventario`
  - `sp_RegistrarVentaSimple`
  - `sp_RevisarInventarioEnvejecido`
- Crea trigger:
  - `trg_existencias_stock_bajo`
- Crea roles de base de datos:
  - `app_sysadmin`, `app_owner`, `app_rw`, `app_ro`
- Asigna permisos por rol.

---

### 2.2. `02_tiendaonline_seed.sql`
Incluye datos iniciales:

- Inserción de roles de aplicación.  
- Usuarios con distintos perfiles.  
- Proveedores, productos y existencias.  
- Ofertas iniciales.  

Permite comenzar a usar la aplicación sin cargar datos manualmente.

---

### 2.3. `03_tiendaonline_tests.sql`
Script para pruebas:

- Consultas a vistas.  
- Pruebas de procedimientos.  
- Registro de productos y entradas de inventario.  
- Registro de ventas y verificación de concurrencia.  
- Verificación del trigger de stock bajo.

---

## 3. Cómo instalar la base de datos

### 3.1. Requisitos
- Microsoft SQL Server (Developer / Express / Standard).  
- SSMS (SQL Server Management Studio).  
- Permisos para crear bases de datos.

### 3.2. Pasos
1. Abrir SSMS.  
2. Ejecutar:

```sql
:r 01_tiendaonline_schema.sql
```

3. Confirmar creación:

```sql
SELECT name FROM sys.databases WHERE name = 'tiendaonline';
```

4. Ejecutar seed:

```sql
:r 02_tiendaonline_seed.sql
```

5. Opcional: ejecutar pruebas:

```sql
:r 03_tiendaonline_tests.sql
```

---

## 4. Proyecto web en Eclipse

### 4.1. Tecnologías utilizadas
- Java 17  
- Maven  
- Spark Java  
- JDBC (SQL Server Driver)  
- HTML / JSP  
- CSS minimalista  

### 4.2. Estructura del proyecto

```
TiendaOnlineWeb/
 ├── pom.xml
 ├── src/main/java/com/ulatina/basesdedatos2/tiendaonline/
 │     ├── config/
 │     ├── controller/
 │     ├── repository/
 │     ├── service/
 │     └── web/ (Routes.java)
 └── src/main/resources/public/
       ├── style.css
       ├── login.html
       ├── owner.html
       ├── gestor.html
       ├── vendedor.html
       └── cliente.html
```

Cada pantalla está alineada al **rol** del usuario.

---

## 5. Configuración de conexión a SQL Server (JDBC)

La aplicación usa JDBC para conectar a SQL Server.  
Antes de usar Java, **SQL Server debe aceptar conexiones TCP/IP**.

---

# 6. Habilitar SQL Server para conexiones JDBC (TCP/IP)

Esta sección documenta los pasos necesarios para permitir que Java se conecte a MS SQL Server.

---

## 6.1. Habilitar TCP/IP

1. Abrir **SQL Server Configuration Manager**.  
2. Ir a:
```
SQL Server Network Configuration → Protocols for MSSQLSERVER
```
3. Habilitar:
```
TCP/IP → Enabled = Yes
Listen All = Yes
```
4. En la pestaña **IP Addresses**, al final (IPAll):

```
TCP Dynamic Ports:   (vacío)
TCP Port:            1433
```

> Es obligatorio **borrar** el valor “TCP Dynamic Ports”.  
> Si no, SQL Server no escuchará en 1433.

5. Guardar cambios.

---

## 6.2. Reiniciar el servicio SQL Server

En SQL Server Configuration Manager:

```
SQL Server Services → SQL Server (MSSQLSERVER) → Restart
```

---

## 6.3. Verificar que el puerto 1433 está activo

### Opción A: usando DMV

```sql
SELECT * FROM sys.dm_tcp_listener_states;
```

Debe mostrar puerto **1433**.

### Opción B: usando netstat

```cmd
netstat -an | find "1433"
```

Debe mostrar:

```
TCP    0.0.0.0:1433     LISTENING
```

---

## 6.4. Probar la conexión con app_user vía TCP

En SSMS usar:

```
Server name: tcp:127.0.0.1,1433
Authentication: SQL Server Authentication
Login: app_user
Password: ChangeThis!123
```

---

## 6.5. Confirmar que la sesión está usando TCP

```sql
SELECT protocol_desc, local_tcp_port
FROM sys.dm_exec_connections
WHERE session_id = @@SPID;
```

Debe mostrar:

```
protocol_desc = TCP
local_tcp_port = 1433
```

Si aparece **Shared Memory**, la conexión no es TCP.

---

## 6.6. Configuración JDBC final en Java

Usar esta URL:

```java
private static final String URL =
    "jdbc:sqlserver://127.0.0.1:1433;"
  + "databaseName=tiendaonline;"
  + "encrypt=true;"
  + "trustServerCertificate=true;";

private static final String USER = "app_user";
private static final String PASS = "YOUR SECRET HERE *****";
```

Se usa **127.0.0.1** para evitar problemas de resolución DNS con hostnames como `DAVO`.

---

## 7. Importar el proyecto en Eclipse

1. Abrir Eclipse.  
2. `File → Import...`  
3. `Existing Maven Projects`  
4. Seleccionar carpeta `TiendaOnlineWeb/`  
5. Completar el asistente.  
6. Esperar a que Maven instale dependencias.  

---

## 8. Ejecutar la aplicación

1. Ejecutar `Routes.java` como **Java Application**.  
2. Abrir navegador:

```
http://localhost:4567/
```

3. Iniciar sesión con usuarios del seed.  
4. Explorar pantallas según el rol.  

---

## 9. Notas finales

- Este proyecto demuestra:
  - Normalización.
  - Roles y control de acceso.
  - Vistas e índices.
  - Stored Procedures con TRY/CATCH.
  - Trigger de stock bajo.
  - Control de concurrencia.
  - Integración Java + SQL Server vía JDBC.
- La documentación está diseñada para defensa académica y presentación a cliente final.

