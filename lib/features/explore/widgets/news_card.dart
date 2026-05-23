import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Importación del nuevo paquete
import '../../../core/theme/app_theme.dart';
import '../providers/explore_providers.dart'; // Importación del modelo

class NewsCard extends StatelessWidget {
  const NewsCard({super.key, required this.post});

  final NewsPost post; // Tipado fuerte y seguro

  String _relativeTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inHours < 1) return 'Hace ${diff.inMinutes}m';
    if (diff.inDays < 1) return 'Hace ${diff.inHours}h';
    if (diff.inDays < 7) return 'Hace ${diff.inDays}d';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Renderizado eficiente con caché en disco duro
          if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
            CachedNetworkImage(
              imageUrl: post.imageUrl!,
              height: 168,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                height: 168,
                width: double.infinity,
                color: AppColors.surface,
                child: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                height: 168,
                width: double.infinity,
                color: AppColors.surfaceVariant,
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image_outlined, color: AppColors.muted, size: 32),
                    SizedBox(height: 8),
                    Text('No se pudo cargar la imagen', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                  ],
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),

                      ),
                      child: const Icon(Icons.campaign_outlined, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(post.clubName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          Text(
                            '${post.authorName} • ${_relativeTime(post.createdAt)}',
                            style: const TextStyle(fontSize: 11, color: AppColors.muted),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                //
                Text(
                  post.title,
                  style: const TextStyle(fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary),
                ),
                const SizedBox(height: 6),
                Text(
                  post.content,
                  style: const TextStyle(fontSize: 13, color: AppColors.onSurface, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}