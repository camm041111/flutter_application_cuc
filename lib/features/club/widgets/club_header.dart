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

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.75),
        ),
      ),
      child: identityAsync.when(
        loading: () => const SizedBox(
          height: 96,
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
        error: (e, s) => const SizedBox(
          height: 96,
          child: Center(
            child: Text(
              'Error al cargar la identidad del club',
              style: TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        data: (club) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Identidad Visual: Logo del Club
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.65),
                    width: 2,
                  ),
                  image: club.urlLogo != null
                      ? DecorationImage(
                          image: NetworkImage(club.urlLogo!), fit: BoxFit.cover)
                      : null,
                ),
                child: club.urlLogo == null
                    ? const Icon(
                        Icons.science_outlined,
                        color: AppColors.primary,
                        size: 40,
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre oficial del club
                    Text(
                      club.nombre,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onBackground,
                        height: 1.15,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 9),
                    // Acrónimo Distintivo
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        club.acronimoDivision.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 9,
                          color: AppColors.background,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 9),
                    // Descripción del enfoque de investigación
                    Text(
                      club.descripcion.isEmpty
                          ? 'Sin descripción disponible.'
                          : club.descripcion,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                        fontWeight: FontWeight.w500,
                        height: 1.45,
                      ),
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
