import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/explore_providers.dart';
import 'news_tag.dart';

class NewsCard extends ConsumerWidget {
  const NewsCard({super.key, required this.post});

  final NewsPost post;

  String _relativeTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inHours < 1) return 'Hace ${diff.inMinutes}m';
    if (diff.inDays < 1) return 'Hace ${diff.inHours}h';
    if (diff.inDays < 7) return 'Hace ${diff.inDays}d';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuchamos el estado para saber si podemos mostrar el botón de eliminar
    final canPublishAsync = ref.watch(canPublishNewsProvider);
    final canManage = canPublishAsync.asData?.value ?? false;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    width: 24, height: 24,
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
                    Text('Error al cargar', style: TextStyle(color: AppColors.muted, fontSize: 12)),
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
                    // Imagen/Avatar del Club (Clickeable)
                    InkWell(
                      onTap: () {
                        // context.push('/club/${post.clubId}'); // Descomentar cuando configures el router
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.campaign_outlined, color: AppColors.primary, size: 20),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Nombre del club (Clickeable)
                          InkWell(
                            onTap: () {
                              // context.push('/club/${post.clubId}');
                            },
                            child: Text(post.clubName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          ),
                          Row(
                            children: [
                              // Nombre del autor (Clickeable)
                              InkWell(
                                onTap: () {
                                  // context.push('/profile/${post.authorId}');
                                },
                                child: Text(
                                  '@${post.authorName}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold),
                                ),
                              ),
                              Text(
                                ' • ${_relativeTime(post.createdAt)}',
                                style: const TextStyle(fontSize: 11, color: AppColors.muted),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Menú de borrado (Solo si el rol lo permite)
                    if (canManage)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.muted),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Eliminar noticia'),
                              content: const Text('¿Estás seguro de que deseas borrar esta publicación? Esta acción no se puede deshacer.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await ref.read(exploreActionsProvider).deleteNews(post.id);
                          }
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                Text(
                  post.title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
                const SizedBox(height: 6),
                Text(
                  post.content,
                  style: const TextStyle(fontSize: 13, color: AppColors.onSurface, height: 1.5),
                ),
                const SizedBox(height: 12),

                // Mapeo Visual de Etiquetas (Hashtags)
                if (post.tags.isNotEmpty)
                  Wrap(
                    spacing: 6.0,
                    runSpacing: 6.0,
                    children: post.tags.map((tag) => NewsTag(label: tag)).toList(),
                  ),

                const SizedBox(height: 12),

                // Botón "Me Gusta"
                InkWell(
                  onTap: () {
                    ref.read(exploreActionsProvider).toggleLike(post.id);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          post.isLikedByMe ? Icons.favorite : Icons.favorite_border,
                          color: post.isLikedByMe ? Colors.redAccent : AppColors.muted,
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          post.likesCount.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: post.isLikedByMe ? Colors.redAccent : AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}