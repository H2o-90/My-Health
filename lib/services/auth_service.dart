
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService {
  static const String _userKey = 'nexpulse_registered_user';
  static const String _sessionActiveKey = 'nexpulse_session_active';

  // Encripta la contraseña en SHA-256
  String hashPassword(String plainPassword) {
    final bytes = utf8.encode(plainPassword.trim());
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Registra un nuevo usuario en almacenamiento local
  Future<void> registerUser({
    required String fullName,
    required String email,
    required String gender,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final user = UserModel(
      fullName: fullName.trim(),
      email: email.trim().toLowerCase(),
      gender: gender,
      passwordHash: hashPassword(password),
      biometricEnabled: false,
    );

    await prefs.setString(_userKey, user.toJson());
    await prefs.setBool(_sessionActiveKey, false);
  }

  // Obtiene el usuario registrado actualmente
  Future<UserModel?> getRegisteredUser() async {
    final prefs = await SharedPreferences.getInstance();

    final raw = prefs.getString(_userKey);

    if (raw == null) return null;

    return UserModel.fromJson(raw);
  }

  // Valida el inicio de sesión con correo y contraseña
  Future<bool> loginWithCredentials(
      String email,
      String password,
      ) async {
    final user = await getRegisteredUser();

    if (user == null) return false;

    final matchesEmail =
        user.email == email.trim().toLowerCase();

    final matchesHash =
        user.passwordHash == hashPassword(password);

    if (matchesEmail && matchesHash) {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool(_sessionActiveKey, true);

      return true;
    }

    return false;
  }

  // Marca la sesión como iniciada o cerrada
  Future<void> setSessionActive(bool active) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_sessionActiveKey, active);
  }

  // Verifica si hay una sesión abierta
  Future<bool> isSessionActive() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getBool(_sessionActiveKey) ?? false;
  }

  // Activa o desactiva la biometría desde el perfil
  Future<UserModel?> updateBiometricPreference(
      bool enabled,
      ) async {
    final user = await getRegisteredUser();

    if (user == null) return null;

    final updated = user.copyWith(
      biometricEnabled: enabled,
    );

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_userKey, updated.toJson());

    return updated;
  }

  // Cierra la sesión sin borrar el registro del usuario
  Future<void> logout() async {
    await setSessionActive(false);
  }
}