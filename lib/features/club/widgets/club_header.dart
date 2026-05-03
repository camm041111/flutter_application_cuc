import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/club_providers.dart';

class ClubHeader extends ConsumerWidget {
  final String clubId;
  const ClubHeader({super.key, required this.clubId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identityAsync = ref.watch(clubIdentityProvider(clubId));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      child: identityAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, s) => const Text('Error al cargar la identidad del club', style: TextStyle(color: Colors.redAccent)),
        data: (club) {
          final acronimo = club['divisiones_academicas']?['acronimo'] ?? 'Desconocida';

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Identidad Visual: Logo del Club
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF1B2B20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.5), width: 2),
                  image: club['url_logo'] != null && club['url_logo'].toString().isNotEmpty
                      ? DecorationImage(image: NetworkImage(club['url_logo']), fit: BoxFit.cover)
                      : null,
                ),
                child: club['url_logo'] == null || club['url_logo'].toString().isEmpty
                    ? const Icon(Icons.science_outlined, color: AppColors.primary, size: 40)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre oficial del club
                    Text(
                      club['nombre'].toString().toUpperCase(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onBackground,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Acrónimo Distintivo
                    Text(
                      'División Académica: $acronimo',
                      style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    // Descripción del enfoque de investigación
                    Text(
                      club['descripcion'] ?? 'Sin descripción disponible.',
                      style: const TextStyle(fontSize: 12, color: AppColors.muted, height: 1.4),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}