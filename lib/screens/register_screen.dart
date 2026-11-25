import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  String _selectedGender = 'Masculino';
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _isSaving = false;

  final _authService = AuthService();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    await _authService.registerUser(
      fullName: _nameCtrl.text,
      email: _emailCtrl.text,
      gender: _selectedGender,
      password: _passCtrl.text,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Cuenta creada con cifrado SHA-256. Inicia sesión con tu contraseña.',
        ),
        backgroundColor: Color(0xFF159B68),
      ),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Cuenta My Health'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Crea tu cuenta',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF18352A),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Tus credenciales se almacenan localmente protegidas mediante hash SHA-256.',
                  style: TextStyle(color: Color(0xFF718078), fontSize: 14),
                ),
                const SizedBox(height: 24),

                // Nombre completo
                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nombre completo',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().length < 3) {
                      return 'Ingresa tu nombre completo (mínimo 3 caracteres)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Correo electrónico
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Ingresa tu correo electrónico';
                    }
                    final regex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$');
                    if (!regex.hasMatch(val.trim())) {
                      return 'Formato de correo inválido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Selector de Sexo
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  dropdownColor: const Color(0xFFFFFFFF),
                  decoration: const InputDecoration(
                    labelText: 'Sexo (Calibración de zancada)',
                    prefixIcon: Icon(Icons.wc_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Masculino', child: Text('Masculino')),
                    DropdownMenuItem(value: 'Femenino', child: Text('Femenino')),
                    DropdownMenuItem(value: 'Otro', child: Text('Otro')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedGender = val);
                  },
                ),
                const SizedBox(height: 16),

                // Contraseña
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscurePass,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePass ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePass = !_obscurePass),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.length < 6) {
                      return 'La contraseña debe tener al menos 6 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirmar Contraseña
                TextFormField(
                  controller: _confirmPassCtrl,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirmar contraseña',
                    prefixIcon: const Icon(Icons.verified_user_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (val) {
                    if (val != _passCtrl.text) {
                      return 'Las contraseñas no coinciden exactamente';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),

                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _isSaving ? null : _handleRegister,
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(
                      _isSaving ? 'Cifrando datos...' : 'Registrar Usuario',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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