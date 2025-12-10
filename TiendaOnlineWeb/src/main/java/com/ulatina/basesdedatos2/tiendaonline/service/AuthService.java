package com.ulatina.basesdedatos2.tiendaonline.service;

import com.ulatina.basesdedatos2.tiendaonline.model.User;
import com.ulatina.basesdedatos2.tiendaonline.repo.UserRepository;

public class AuthService {

    private final UserRepository userRepository;

    public AuthService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    public User login(String email, String plainPassword) {
        return userRepository.findByEmailAndPassword(email, plainPassword);
    }
}