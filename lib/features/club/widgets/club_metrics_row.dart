import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/club_providers.dart';

class ClubMetricsRow extends ConsumerWidget {
  final String clubId;
  const ClubMetricsRow({super.key, required this.clubId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuchamos ambos proveedores en paralelo
    final directoryAsync = ref.watch(clubDirectoryProvider(clubId));
    final docsCountAsync = ref.watch(clubDocsCountProvider(clubId));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          // 1. Métrica de Miembros Activos
          Expanded(
            child: directoryAsync.when(
              loading: () => const _ClubStatCard(label: 'MIEMBROS ACTIVOS', value: '...', isLoading: true),
              error: (_, __) => const _ClubStatCard(label: 'MIEMBROS ACTIVOS', value: '0'),
              data: (dir) => _ClubStatCard(label: 'MIEMBROS ACTIVOS', value: dir.activos.length.toString()),
            ),
          ),
          const SizedBox(width: 14),

          // 2. Métrica de Documentos Generados (Conectado a BD real)
          Expanded(
            child: docsCountAsync.when(
              loading: () => const _ClubStatCard(label: 'DOCS. GENERADOS', value: '...', isLoading: true),
              error: (_, __) => const _ClubStatCard(label: 'DOCS. GENERADOS', value: '0'),
              data: (count) => _ClubStatCard(label: 'DOCS. GENERADOS', value: count.toString()),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClubStatCard extends StatelessWidget {
  final String label;
  final String value;
  final bool isLoading;

  const _ClubStatCard({required this.label, required this.value, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface, // Fondo oscuro antracita
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.muted)),
          const SizedBox(height: 6),
          if (isLoading)
            const SizedBox(
                height: 28,
                width: 28,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)
            )
          else
            Text(
                value,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.onBackground)
            ),
        ],
      ),
    );
  }
}