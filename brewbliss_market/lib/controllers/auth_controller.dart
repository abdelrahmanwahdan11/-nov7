import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/utils/validators.dart';

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
    if (Validators.required(identifier, 'id') != null || Validators.minLength(password, 8, 'pwd') != null) {
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
    if (Validators.required(name, 'name') != null || Validators.email(email, 'email') != null || Validators.minLength(password, 8, 'pwd') != null) {
      _authState.value = AuthState.error;
      throw const FormatException('Invalid sign up');
    }
    _authState.value = AuthState.authenticated;
  }

  Future<void> forgotPassword(String email) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (Validators.email(email, 'email') != null) {
      throw const FormatException('Email required');
    }
  }

  void continueAsGuest() {
    _authState.value = AuthState.guest;
  }

  void updatePasswordStrength(String password) {
    final score = Validators.passwordStrengthScore(password);
    passwordStrength.value = score / 4;
  }

  void dispose() {
    isPasswordVisible.dispose();
    isConfirmVisible.dispose();
    passwordStrength.dispose();
    _authState.dispose();
  }
}

enum AuthState { guest, loading, authenticated, error }
