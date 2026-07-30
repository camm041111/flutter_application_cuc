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
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // 1. Métrica de Miembros Activos
          Expanded(
            child: directoryAsync.when(
              loading: () => const _ClubStatCard(
                  label: 'MIEMBROS ACTIVOS', value: '...', isLoading: true),
              error: (_, __) =>
                  const _ClubStatCard(label: 'MIEMBROS ACTIVOS', value: '0'),
              data: (dir) => _ClubStatCard(
                  label: 'MIEMBROS ACTIVOS',
                  value: dir.activos.length.toString()),
            ),
          ),
          const SizedBox(width: 12),

          // 2. Métrica de Documentos Generados (Conectado a BD real)
          Expanded(
            child: docsCountAsync.when(
              loading: () => const _ClubStatCard(
                  label: 'DOCS. GENERADOS', value: '...', isLoading: true),
              error: (_, __) =>
                  const _ClubStatCard(label: 'DOCS. GENERADOS', value: '0'),
              data: (count) => _ClubStatCard(
                  label: 'DOCS. GENERADOS', value: count.toString()),
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

  const _ClubStatCard(
      {required this.label, required this.value, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 152,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.75),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  label == 'MIEMBROS ACTIVOS'
                      ? Icons.groups_outlined
                      : Icons.description_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isLoading)
            const SizedBox(
              height: 32,
              width: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            )
          else
            Text(
              value,
              style: const TextStyle(
                fontSize: 32,
                height: 1,
                fontWeight: FontWeight.w800,
                color: AppColors.onBackground,
              ),
            ),
          const SizedBox(height: 9),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9,
              height: 1.25,
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
