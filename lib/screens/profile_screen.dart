import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';
import '../widgets/liquid_glass_widgets.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _biometricService = BiometricService();

  UserModel? _user;
  bool _sensitiveUnlocked = false;
  bool _isProcessingBio = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = await _authService.getRegisteredUser();
    if (!mounted) return;
    setState(() {
      _user = user;
      _sensitiveUnlocked = !(user?.biometricEnabled ?? false);
    });
  }

  Future<void> _toggleBiometrics(bool newValue) async {
    if (_isProcessingBio || _user == null) return;
    setState(() => _isProcessingBio = true);

    if (newValue) {
      final result = await _biometricService.authenticate(
        localizedReason:
        'Confirma tu huella dactilar o rostro para activar la seguridad biométrica en My Health',
      );

      if (!mounted) return;

      if (result.success) {
        final updated = await _authService.updateBiometricPreference(true);
        setState(() {
          _user = updated;
          _sensitiveUnlocked = true;
          _isProcessingBio = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Biometría (Huella y Rostro) activada correctamente.',
              ),
              backgroundColor: Color(0xFFFF5520),
            ),
          );
        }
      } else {
        setState(() => _isProcessingBio = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: Colors.orangeAccent,
            ),
          );
        }
      }
    } else {
      final updated = await _authService.updateBiometricPreference(false);
      if (!mounted) return;
      setState(() {
        _user = updated;
        _sensitiveUnlocked = true;
        _isProcessingBio = false;
      });
    }
  }

  Future<void> _unlockSensitiveData() async {
    final result = await _biometricService.authenticate(
      localizedReason:
      'Autentícate con huella o rostro para desbloquear tus datos sensibles',
    );
    if (!mounted) return;
    if (result.success) {
      setState(() => _sensitiveUnlocked = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0.0, -0.7),
          radius: 1.15,
          colors: [
            Color(0x33FF5520),
            Color(0xFF0A0A0C),
          ],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Perfil y Seguridad',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),

              // Tarjeta de identidad Liquid Glass
              LiquidGlassCard(
                highlightBorder: true,
                child: Column(
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF5520), Color(0xFFFF9F1C)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF5520)
                                .withValues(alpha: 0.4),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 38,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _user!.fullName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _user!.email,
                      style: const TextStyle(color: Color(0xFF9A9AA2)),
                    ),
                    Divider(
                        height: 28,
                        color: Colors.white.withValues(alpha: 0.12)),
                    if (!_sensitiveUnlocked)
                      Column(
                        children: [
                          const Icon(Icons.lock_person_outlined,
                              color: Color(0xFFFF5520), size: 32),
                          const SizedBox(height: 8),
                          const Text(
                            'Datos biométricos y hash SHA-256 protegidos',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xFF9A9AA2)),
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: _unlockSensitiveData,
                            icon: const Icon(Icons.fingerprint),
                            label: const Text('Desbloquear con Biometría'),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          _ProfileRow(
                            label: 'Sexo / Calibración',
                            value:
                            '${_user!.gender} (${(_user!.strideLengthMeters * 100).toInt()} cm/paso)',
                          ),
                          const SizedBox(height: 10),
                          _ProfileRow(
                            label: 'Hash SHA-256',
                            value:
                            '${_user!.passwordHash.substring(0, 18)}...',
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Interruptor de Biometría Liquid Glass
              LiquidGlassCard(
                padding: const EdgeInsets.all(16),
                borderRadius: 20,
                highlightBorder: _user!.biometricEnabled,
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: const Color(0xFFFF5520),
                  secondary: const Icon(
                    Icons.fingerprint,
                    size: 32,
                    color: Color(0xFFFF5520),
                  ),
                  title: const Text(
                    'Huella Dactilar y Reconocimiento Facial',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  subtitle: const Text(
                    'Habilita el inicio de sesión rápido y la protección de datos sensibles mediante biometría nativa.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF9A9AA2)),
                  ),
                  value: _user!.biometricEnabled,
                  onChanged: _toggleBiometrics,
                ),
              ),
              const SizedBox(height: 28),

              SizedBox(
                height: 50,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFF5520),
                    side: const BorderSide(color: Color(0xFFFF5520)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: const Text(
                    'Cerrar Sesión',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF9A9AA2))),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}