package com.ulatina.basesdedatos2.tiendaonline.service;

import com.ulatina.basesdedatos2.tiendaonline.model.Product;
import com.ulatina.basesdedatos2.tiendaonline.repo.SqlServerProductRepository;

import java.util.List;

/**
 * Capa de servicio para operaciones de inventario / catálogo.
 * Actúa como intermediario entre los controladores (Routes)
 * y la capa de acceso a datos (SqlServerProductRepository).
 */
public class InventoryService {

    private final SqlServerProductRepository productRepository;

    public InventoryService(SqlServerProductRepository productRepository) {
        this.productRepository = productRepository;
    }

    /**
     * Devuelve el catálogo de productos completo.
     * Usado por la página de gestor y por el catálogo público.
     */
    public List<Product> getCatalog() {
        return productRepository.findCatalog();
    }

    // Aquí podrías añadir otros métodos:
    // - getStockBajo()
    // - registrarEntradaInventario(...)
    // - aplicarOferta(...)
}
