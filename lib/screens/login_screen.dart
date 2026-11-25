import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';
import '../widgets/liquid_glass_widgets.dart';
import 'home_shell_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  final _authService = AuthService();
  final _biometricService = BiometricService();

  UserModel? _registeredUser;
  bool _obscurePass = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserStatus();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUserStatus() async {
    final user = await _authService.getRegisteredUser();
    if (!mounted) return;
    setState(() {
      _registeredUser = user;
      if (user != null && _emailCtrl.text.isEmpty) {
        _emailCtrl.text = user.email;
      }
      _isLoading = false;
    });
  }

  Future<void> _loginWithPassword() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await _authService.loginWithCredentials(
      _emailCtrl.text,
      _passCtrl.text,
    );

    if (!mounted) return;

    if (success) {
      _navigateToHome();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Credenciales incorrectas o usuario no registrado.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _loginWithBiometrics() async {
    final result = await _biometricService.authenticate(
      localizedReason:
      'Verifica tu huella dactilar o rostro para acceder a My Health',
    );

    if (!mounted) return;

    if (result.success) {
      await _authService.setSessionActive(true);
      if (!mounted) return;
      _navigateToHome();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: Colors.orangeAccent,
        ),
      );
    }
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canUseBiometrics =
        _registeredUser != null && _registeredUser!.biometricEnabled;

    return Scaffold(
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.0, -0.6),
            radius: 1.2,
            colors: [
              Color(0x40FF5520),
              Color(0xFF0A0A0C),
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF5520), Color(0xFFFF9F1C)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF5520)
                              .withValues(alpha: 0.45),
                          blurRadius: 24,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.monitor_heart_outlined,
                      size: 52,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'My Health',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Biometría y Telemetría de Movimiento en Tiempo Real',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFFFF9F1C),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 36),
                LiquidGlassCard(
                  padding: const EdgeInsets.all(20),
                  borderRadius: 24,
                  highlightBorder: true,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Iniciar Sesión',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Correo electrónico',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (val) =>
                          (val == null || val.trim().isEmpty)
                              ? 'Ingresa tu correo'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _passCtrl,
                          obscureText: _obscurePass,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePass
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () => setState(
                                      () => _obscurePass = !_obscurePass),
                            ),
                          ),
                          validator: (val) =>
                          (val == null || val.isEmpty)
                              ? 'Ingresa tu contraseña'
                              : null,
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 50,
                          child: FilledButton(
                            onPressed: _loginWithPassword,
                            child: const Text(
                              'Entrar con Contraseña',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        if (canUseBiometrics) ...[
                          const SizedBox(height: 14),
                          SizedBox(
                            height: 50,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Color(0xFFFF5520),
                                  width: 1.5,
                                ),
                                foregroundColor: const Color(0xFFFF5520),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: _loginWithBiometrics,
                              icon:
                              const Icon(Icons.fingerprint, size: 26),
                              label: const Text(
                                'Acceso Rápido (Huella / Rostro)',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ] else if (_registeredUser != null) ...[
                          const SizedBox(height: 12),
                          const Text(
                            'Tip: Activa el acceso por Huella y Rostro dentro de tu Perfil después de iniciar sesión.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF9A9AA2),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton.icon(
                  onPressed: () async {
                    final created = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RegisterScreen(),
                      ),
                    );
                    if (created == true) {
                      _loadUserStatus();
                    }
                  },
                  icon: const Icon(Icons.person_add_alt_1,
                      color: Color(0xFFFF9F1C)),
                  label: const Text(
                    '¿No tienes cuenta? Regístrate aquí',
                    style: TextStyle(color: Color(0xFFFF9F1C)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}