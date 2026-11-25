import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';

class BiometricResult {
  final bool success;
  final String message;

  const BiometricResult({required this.success, required this.message});
}

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// Verifica si el hardware soporta biometría y si existen huellas/rostros enrollados
  Future<BiometricResult> checkBiometricAvailability() async {
    try {
      final bool canCheckBiometrics = await _auth.canCheckBiometrics;
      final bool isDeviceSupported = await _auth.isDeviceSupported();

      if (!canCheckBiometrics || !isDeviceSupported) {
        return const BiometricResult(
          success: false,
          message: 'Este dispositivo no cuenta con sensores biométricos compatibles.',
        );
      }

      final List<BiometricType> availableBiometrics =
      await _auth.getAvailableBiometrics();

      if (availableBiometrics.isEmpty) {
        return const BiometricResult(
          success: false,
          message:
          'No hay huellas dactilares ni rostros configurados en los ajustes de Android.',
        );
      }

      return const BiometricResult(
        success: true,
        message: 'Biometría disponible y lista.',
      );
    } on PlatformException catch (e) {
      return BiometricResult(
        success: false,
        message: 'Error al consultar hardware biométrico: ${e.message}',
      );
    }
  }

  /// Solicita autenticación por Huella Dactilar o Reconocimiento Facial

  Future<BiometricResult> authenticate({
    required String localizedReason,
  }) async {
    final availability = await checkBiometricAvailability();

    if (!availability.success) {
      return availability;
    }

    try {
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: localizedReason,

        authMessages: const <AuthMessages>[
          AndroidAuthMessages(
            signInTitle: 'Seguridad My Health',
            signInHint: 'Usa tu huella o reconocimiento facial',
            cancelButton: 'Cancelar',
          ),
        ],

        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );

      if (didAuthenticate) {
        return const BiometricResult(
          success: true,
          message: 'Autenticación biométrica exitosa.',
        );
      }

      return const BiometricResult(
        success: false,
        message: 'Autenticación cancelada por el usuario.',
      );
    } on LocalAuthException catch (e) {
      return BiometricResult(
        success: false,
        message: 'Fallo de autenticación: ${e.code}',
      );
    } on PlatformException catch (e) {
      return BiometricResult(
        success: false,
        message: 'Error: ${e.message ?? e.code}',
      );
    }
  }
}
