package com.ulatina.basesdedatos2.tiendaonline.service;

import com.ulatina.basesdedatos2.tiendaonline.model.User;
import com.ulatina.basesdedatos2.tiendaonline.repo.UserRepository;

import java.util.Optional;

/**
 * Authentication and authorization related business logic.
 */
public class AuthService {

    private final UserRepository userRepository;

    public AuthService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    public Optional<User> login(String email, String password) {
        return userRepository.findByEmailAndPassword(email, password);
    }
}
