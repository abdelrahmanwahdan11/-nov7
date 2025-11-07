import 'dart:async';

import 'package:flutter/foundation.dart';

class AuthController {
  AuthController() {
    isPasswordVisible = ValueNotifier<bool>(false);
    isConfirmVisible = ValueNotifier<bool>(false);
    passwordStrength = ValueNotifier<double>(0);
    _authState = ValueNotifier<AuthState>(AuthState.guest);
  }

  late final ValueNotifier<bool> isPasswordVisible;
  late final ValueNotifier<bool> isConfirmVisible;
  late final ValueNotifier<double> passwordStrength;
  late final ValueNotifier<AuthState> _authState;

  ValueListenable<AuthState> get authStateListenable => _authState;

  Future<void> signIn(String identifier, String password) async {
    _authState.value = AuthState.loading;
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (identifier.isEmpty || password.length < 6) {
      _authState.value = AuthState.error;
      throw const FormatException('Invalid credentials');
    }
    _authState.value = AuthState.authenticated;
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    _authState.value = AuthState.loading;
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (name.isEmpty || email.isEmpty || password.length < 6) {
      _authState.value = AuthState.error;
      throw const FormatException('Invalid sign up');
    }
    _authState.value = AuthState.authenticated;
  }

  Future<void> forgotPassword(String email) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (email.isEmpty) {
      throw const FormatException('Email required');
    }
  }

  void continueAsGuest() {
    _authState.value = AuthState.guest;
  }

  void updatePasswordStrength(String password) {
    double strength = 0;
    if (password.isEmpty) {
      strength = 0;
    } else {
      if (password.length >= 6) strength += 0.3;
      if (RegExp(r'[A-Z]').hasMatch(password)) strength += 0.2;
      if (RegExp(r'[0-9]').hasMatch(password)) strength += 0.2;
      if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) strength += 0.3;
      strength = strength.clamp(0, 1);
    }
    passwordStrength.value = strength;
  }

  void dispose() {
    isPasswordVisible.dispose();
    isConfirmVisible.dispose();
    passwordStrength.dispose();
    _authState.dispose();
  }
}

enum AuthState { guest, loading, authenticated, error }
