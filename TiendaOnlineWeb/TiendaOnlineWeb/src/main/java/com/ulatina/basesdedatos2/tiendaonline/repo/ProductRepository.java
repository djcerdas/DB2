package com.ulatina.basesdedatos2.tiendaonline.repo;

import com.ulatina.basesdedatos2.tiendaonline.model.Product;

import java.util.List;
import java.util.Optional;

/**
 * Repository abstraction for product persistence.
 *
 * This is the DAO/Repository pattern, providing an interface that
 * hides JDBC details from the rest of the code.
 */
public interface ProductRepository {

    List<Product> findCatalog();

    Optional<Product> findById(int id);
}
