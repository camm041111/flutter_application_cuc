import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/widgets/cuc_text_field.dart';
// Importamos los nuevos componentes extraídos
import '../widgets/login_header.dart';
import '../widgets/login_footer.dart';


class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // Asegura el color de fondo completo
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                LoginHeader(
                  onBack: () => Navigator.maybePop(context),
                ),
                const SizedBox(height: 40),
                _buildForm(context),
                const SizedBox(height: 40),
                const LoginFooter(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Column(
      children: [
        Text(
          '¡Bienvenido de vuelta, sigamos investigando!',
          style: TextStyle(color: AppColors.muted, fontSize: 13),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        const CucTextField(
          label: 'CORREO ELECTRÓNICO',
          hint: 'researcher@cuc.edu',
          prefixIcon: Icons.alternate_email,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 20),
        const CucTextField(
          label: 'CONTRASEÑA',
          hint: '••••••••',
          prefixIcon: Icons.key_outlined,
          obscureText: true,
        ),
        _buildForgotPassword(),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.main),
            icon: const Icon(Icons.shield_outlined, size: 18),
            label: const Text('INICIAR SESIÓN'),
          ),
        ),
      ],
    );
  }

  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {},
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