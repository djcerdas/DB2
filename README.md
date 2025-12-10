# TiendaOnline — Academic Web System for Inventory & Sales

Proyecto académico para el curso Bases de Datos II (Universidad Latina de Costa Rica).

Autores:
- David Jesús Cerdas Pérez
- Jerami Thomas Dudley Cerdas

Profesor:
- Marlon Obando Cordero

Este proyecto consiste en una aplicación web desarrollada en Java, un backend con Spark Framework, un repositorio DAO con JDBC, y una base de datos SQL Server completamente normalizada, segura y documentada.

------------------------------------------------------------
1. PROJECT STRUCTURE
------------------------------------------------------------

/TiendaOnlineWeb
│
├─ sql/
│   ├─ 01_tiendaonline_schema.sql
│   ├─ 02_tiendaonline_seed.sql
│   └─ 03_tiendaonline_test_queries.sql
│
├─ src/main/java/com/ulatina/basesdedatos2/tiendaonline/
│   ├─ model/
│   ├─ repo/
│   ├─ service/
│   └─ web/
│
├─ resources/
│   └─ application.properties
│
└─ public/
    ├─ index.html
    ├─ gestor.html
    └─ assets/

------------------------------------------------------------
2. SQL FILES OVERVIEW
------------------------------------------------------------

01_tiendaonline_schema.sql:
- Crea la base de datos tiendaonline
- Tablas normalizadas
- Vistas (v_CatalogoProductos, v_StockBajo, v_VentasPorDia)
- Procedimientos almacenados
- Trigger de stock bajo
- Roles de BD (app_sysadmin, app_owner, app_rw, app_ro)
- Usuario técnico app_user (login + user + role)
- Prueba de permisos con EXECUTE AS USER

02_tiendaonline_seed.sql:
- Inserta proveedores
- Inserta productos
- Inserta existencias
- Inserta ofertas
- Inserta usuarios, roles y asignaciones
- Inserta facturas de prueba

03_tiendaonline_test_queries.sql:
- Pruebas del catálogo
- Pruebas de stock
- Pruebas de ventas por día
- Validación de permisos
- Ejecución de SPs

------------------------------------------------------------
3. INSTALLING SQL SERVER
------------------------------------------------------------

Requisitos:
- SQL Server 2019 o superior
- SQL Server Management Studio (SSMS)

Pasos:
1. Abrir SSMS y conectarse al servidor
2. Ejecutar 01_tiendaonline_schema.sql
3. Ejecutar 02_tiendaonline_seed.sql
4. (Opcional) Ejecutar 03_tiendaonline_test_queries.sql

------------------------------------------------------------
4. ECLIPSE INSTALLATION & JAVA SETUP
------------------------------------------------------------

1. Instalar Eclipse IDE:
   https://www.eclipse.org/downloads/

2. Crear proyecto Maven:
   File → New → Maven Project
   Seleccionar: maven-archetype-quickstart

3. Agregar dependencias al pom.xml:

    <dependencies>
        <dependency>
            <groupId>com.sparkjava</groupId>
            <artifactId>spark-core</artifactId>
            <version>2.9.4</version>
        </dependency>

        <dependency>
            <groupId>com.microsoft.sqlserver</groupId>
            <artifactId>mssql-jdbc</artifactId>
            <version>12.4.2.jre11</version>
        </dependency>

        <dependency>
            <groupId>com.google.code.gson</groupId>
            <artifactId>gson</artifactId>
            <version>2.10</version>
        </dependency>
    </dependencies>

------------------------------------------------------------
5. DATABASE CONFIGURATION
------------------------------------------------------------

Archivo:
resources/application.properties

Contenido:

db.url=jdbc:sqlserver://localhost:1433;databaseName=tiendaonline;encrypt=true;trustServerCertificate=true;
db.username=app_user
db.password=*************
db.driver=com.microsoft.sqlserver.jdbc.SQLServerDriver

------------------------------------------------------------
6. JAVA PACKAGE STRUCTURE
------------------------------------------------------------

El paquete principal debe ser:

com.ulatina.basesdedatos2.tiendaonline

Subcarpetas:
- model
- repo
- service
- web

------------------------------------------------------------
7. RUNNING THE APPLICATION
------------------------------------------------------------

Ejecutar la clase:

src/main/java/com/ulatina/basesdedatos2/tiendaonline/App.java

El servidor iniciará en:

http://localhost:8080/

------------------------------------------------------------
8. SYSTEM PAGES & API ENDPOINTS
------------------------------------------------------------

Home page:
http://localhost:8080/index.html

Inventory dashboard:
http://localhost:8080/gestor.html

API - Product catalog:
http://localhost:8080/api/catalog

API - Inventory operations:
http://localhost:8080/api/inventory

API - Register sale:
http://localhost:8080/api/sell

