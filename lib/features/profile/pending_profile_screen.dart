import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/cache/app_cache_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/auth_service.dart';
import '../../core/providers/supabase_provider.dart';
import 'providers/profile_providers.dart';

/// Pantalla de estado de "Solo Lectura" para solicitudes en revisión o rechazadas
class PendingProfileScreen extends ConsumerWidget {
  const PendingProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: profileAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (e, s) => _buildRetryButton(ref),
            data: (profile) {
              final isRejected = profile?.estado == 'rechazado';
              final comment = profile?.comentariosRevision;

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  _buildCentralIcon(isRejected),
                  const SizedBox(height: 40),
                  _buildInformationText(isRejected, comment),
                  const Spacer(),
                  _buildActionButtons(context, ref, isRejected, profile),
                  const SizedBox(height: 24),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRetryButton(WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            color: AppColors.error,
            size: 44,
          ),
          const SizedBox(height: 12),
          const Text(
            'No se pudo cargar tu estado.',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {
              final user = ref.read(supabaseClientProvider).auth.currentUser;
              if (user != null) {
                ref.read(appCacheServiceProvider).invalidate('profile:${user.id}');
                ref.invalidate(profileProvider(user.id));
              }
              ref.invalidate(currentUserProfileProvider);
            },
            child: const Text('REINTENTAR'),
          ),
        ],
      ),
    );
  }

  Widget _buildCentralIcon(bool isRejected) {
    final color = isRejected ? AppColors.error : AppColors.primary;
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.1),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.15),
                blurRadius: 35,
                spreadRadius: 5,
              ),
            ],
          ),
        ),
        Icon(
          isRejected
              ? Icons.cancel_outlined
              : Icons.hourglass_empty_rounded,
          size: 80,
          color: color,
        ),
      ],
    );
  }

  Widget _buildInformationText(bool isRejected, String? comment) {
    if (!isRejected) {
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
          SizedBox(height: 16),
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

    return Column(
      children: [
        const Text(
          'SOLICITUD RECHAZADA',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.0,
            color: AppColors.error,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        const Text(
          'Tu solicitud de ingreso fue rechazada. Revisa los comentarios del coordinador, corrige tus datos y vuelve a enviarla.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.muted,
            height: 1.6,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.45)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.feedback_outlined,
                    color: AppColors.error,
                    size: 18,
                  ),
                  SizedBox(width: 7),
                  Text(
                    'COMENTARIOS DE REVISIÓN',
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                comment?.trim().isNotEmpty == true
                    ? comment!.trim()
                    : 'El coordinador no agregó comentarios.',
                style: const TextStyle(
                  color: AppColors.onSurface,
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    bool isRejected,
    UserProfile? profile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isRejected)
          ElevatedButton.icon(
            onPressed: () => _openCorrectionForm(context, ref, profile),
            icon: const Icon(Icons.edit_document, size: 20),
            label: const Text('CORREGIR Y REENVIAR'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          )
        else
          // Botón para re-validar el estado contra Supabase
          ElevatedButton.icon(
            onPressed: () async {
              // Invalidamos el provider del perfil para forzar una nueva consulta a la DB
              // Si el estado cambió a 'activo', GoRouter nos moverá automáticamente.
              final user = ref.read(supabaseClientProvider).auth.currentUser;
              if (user != null) {
                await ref
                    .read(appCacheServiceProvider)
                    .invalidate('profile:${user.id}');
                ref.invalidate(profileProvider(user.id));
              }
              ref.invalidate(currentUserProfileProvider);
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
        // Botón de escape para destruir la sesión (RF01.7).
        OutlinedButton(
          onPressed: () async {
            await ref.read(authServiceProvider).cerrarSesion();
          },
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
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

  Future<void> _openCorrectionForm(
    BuildContext context,
    WidgetRef ref,
    UserProfile? profile,
  ) async {
    final nombreController =
        TextEditingController(text: profile?.nombreCompleto ?? '');
    final matriculaController =
        TextEditingController(text: profile?.matricula ?? '');
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(
                color: AppColors.border.withValues(alpha: 0.5),
              ),
            ),
            title: const Row(
              children: [
                Icon(
                  Icons.edit_document,
                  color: AppColors.primary,
                  size: 23,
                ),
                SizedBox(width: 10),
                Text('Corregir y Reenviar'),
              ],
            ),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Corrige tus datos y tu solicitud volverá a la cola de aprobación.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: nombreController,
                    decoration: InputDecoration(
                      labelText: 'NOMBRE COMPLETO',
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().length < 3) {
                        return 'Mínimo 3 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: matriculaController,
                    decoration: InputDecoration(
                      labelText: 'MATRÍCULA INSTITUCIONAL',
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Campo requerido';
                      }
                      if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value.trim())) {
                        return 'Solo caracteres alfanuméricos';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed:
                    isSubmitting ? null : () => Navigator.pop(dialogContext),
                child: const Text(
                  'CANCELAR',
                  style: TextStyle(color: AppColors.muted),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setState(() => isSubmitting = true);

                        var success = true;
                        String message = 'Solicitud enviada de nuevo';
                        try {
                          await ref
                              .read(profileActionsProvider)
                              .reenviarSolicitudIngreso(
                            nombre: nombreController.text.trim(),
                            matricula: matriculaController.text.trim(),
                          );
                        } catch (e) {
                          success = false;
                          message = 'Fallo en la base de datos';
                        }

                        if (!dialogContext.mounted) return;
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? message
                                  : 'Error al procesar la solicitud',
                            ),
                            backgroundColor:
                                success ? const Color(0xFF007A33) : Colors.red,
                          ),
                        );
                      },
                child: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('REENVIAR'),
              ),
            ],
          );
        },
      ),
    );
  }
}
