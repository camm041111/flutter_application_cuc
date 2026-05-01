import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/login_header.dart';
import '../widgets/auth_divider.dart';
import '../widgets/register_form.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                LoginHeader(
                  onBack: () => Navigator.pop(context),
                ),
                const SizedBox(height: 32), // Espacio optimizado tras quitar el picker
                const RegisterForm(),
                const SizedBox(height: 32),
                const AuthDivider(label: '¿Ya estás registrado?'),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                      'INICIAR SESIÓN',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      )
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}