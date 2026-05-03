import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/providers/auth_providers.dart';

/// Pantalla de estado de "Solo Lectura"
class PendingProfileScreen extends ConsumerWidget {
  const PendingProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              _buildCentralIcon(),
              const SizedBox(height: 40),
              _buildInformationText(),
              const Spacer(),
              _buildActionButtons(ref),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCentralIcon() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withOpacity(0.1),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.15),
                blurRadius: 35,
                spreadRadius: 5,
              ),
            ],
          ),
        ),
        const Icon(
          Icons.hourglass_empty_rounded,
          size: 80,
          color: AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildInformationText() {
    return const Column(
      children: [
        Text(
          'PERFIL EN REVISIÓN',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.0,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Tu registro ha sido exitoso. Actualmente, tu acceso está pendiente de aprobación por el Coordinador de tu División Académica.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.muted,
            height: 1.6,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildActionButtons(WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Botón para re-validar el estado contra Supabase
        ElevatedButton.icon(
          onPressed: () {
            // Invalidamos el provider del perfil para forzar una nueva consulta a la DB
            // Si el estado cambió a 'activo', GoRouter nos moverá automáticamente[cite: 3].
            ref.invalidate(perfilUsuarioProvider);
          },
          icon: const Icon(Icons.refresh_rounded, size: 20),
          label: const Text('ACTUALIZAR ESTADO'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        // Botón de escape para destruir la sesión (RF01.7)[cite: 3].
        OutlinedButton(
          onPressed: () async {
            await ref.read(authServiceProvider).cerrarSesion();
          },
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            side: BorderSide(color: Colors.white.withOpacity(0.2)),
          ),
          child: const Text(
            'CERRAR SESIÓN',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
        ),
      ],
    );
  }
}