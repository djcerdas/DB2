package com.ulatina.basesdedatos2.tiendaonline.service;

import com.ulatina.basesdedatos2.tiendaonline.model.Product;
import com.ulatina.basesdedatos2.tiendaonline.repo.ProductRepository;

import java.util.List;

/**
 * Business service that exposes operations related to the product catalog.
 */
public class InventoryService {

    private final ProductRepository productRepository;

    public InventoryService(ProductRepository productRepository) {
        this.productRepository = productRepository;
    }

    /**
     * Returns the catalog of products ready to be displayed.
     */
    public List<Product> getCatalog() {
        return productRepository.findCatalog();
    }
}
