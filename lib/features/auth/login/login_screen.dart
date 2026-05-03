import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/cuc_text_field.dart';
import '../../../core/services/auth_service.dart';
import '../widgets/login_header.dart';
import '../widgets/login_footer.dart';

// Convertimos a ConsumerStatefulWidget para gestionar el estado de carga y acceder a providers
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  // Controladores para capturar la entrada de texto
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Lógica de autenticación que cumple con el RF01.4
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Llamada al servicio de autenticación
    final errorMessage = await ref.read(authServiceProvider).iniciarSesion(
      correo: _emailController.text,
      contrasena: _passwordController.text,
    );

    if (mounted) {
      setState(() => _isLoading = false);

      if (errorMessage != null) {
        // Manejo de errores (Credenciales inválidas o falta de red)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        // NOTA: No llamamos a context.go() aquí.
        // El routerProvider detectará el cambio de sesión y redirigirá automáticamente
        // a '/' o a '/pending' según el estado del usuario[cite: 3].
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  LoginHeader(
                    onBack: () => Navigator.maybePop(context),
                  ),
                  const SizedBox(height: 40),
                  _buildWelcomeText(),
                  const SizedBox(height: 32),

                  // Campo de Correo
                  CucTextField(
                    controller: _emailController,
                    label: 'CORREO INSTITUCIONAL',
                    hint: 'usuario@alumno.ujat.mx',
                    prefixIcon: Icons.alternate_email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Ingresa tu correo';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Campo de Contraseña
                  CucTextField(
                    controller: _passwordController,
                    label: 'CONTRASEÑA',
                    hint: '••••••••',
                    prefixIcon: Icons.key_outlined,
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Ingresa tu contraseña';
                      return null;
                    },
                  ),

                  _buildForgotPassword(),
                  const SizedBox(height: 32),

                  // Botón de Acción con estado de carga
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _handleLogin,
                      icon: _isLoading
                          ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                      )
                          : const Icon(Icons.shield_outlined, size: 18),
                      label: Text(_isLoading ? 'VERIFICANDO...' : 'INICIAR SESIÓN'),
                    ),
                  ),

                  const SizedBox(height: 40),
                  const LoginFooter(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeText() {
    return Column(
      children: const [
        Text(
          '¡Bienvenido de vuelta!',
          style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8),
        Text(
          'Sigamos impulsando la ciencia en la UJAT.',
          style: TextStyle(color: AppColors.muted, fontSize: 13),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {
          // Implementar flujo de recuperación RF01.6[cite: 3]
        },
        child: Text(
          '¿Olvidaste tu contraseña?',
          style: TextStyle(
            fontSize: 10,
            color: AppColors.primary.withOpacity(0.7),
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}