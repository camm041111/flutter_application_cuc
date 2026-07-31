import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../club/screens/club_profile_screen.dart';
import '../../profile/profile_screen.dart';
import '../../profile/providers/profile_providers.dart';
import '../providers/explore_providers.dart';
import 'news_image_attachment.dart';
import 'news_tag.dart';
import 'news_rich_text.dart';

class NewsCard extends ConsumerStatefulWidget {
  const NewsCard({super.key, required this.post});

  final NewsPost post;

  @override
  ConsumerState<NewsCard> createState() => _NewsCardState();
}

class _NewsCardState extends ConsumerState<NewsCard> {
  // la tarjeta recordará su propio Like temporalmente
  late bool _isLikedLocal;
  late int _likesCountLocal;

  @override
  void initState() {
    super.initState();
    _syncWithProvider();
  }

  @override
  void didUpdateWidget(covariant NewsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si Riverpod actualiza la lista global, sincronizamos nuestro estado local con la verdad absoluta de la BD
    if (oldWidget.post.id != widget.post.id ||
        oldWidget.post.likesCount != widget.post.likesCount ||
        oldWidget.post.isLikedByMe != widget.post.isLikedByMe) {
      _syncWithProvider();
    }
  }

  void _syncWithProvider() {
    _isLikedLocal = widget.post.isLikedByMe;
    _likesCountLocal = widget.post.likesCount;
  }

  void _openClubProfile() {
    if (widget.post.clubId.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ClubProfileScreen(clubId: widget.post.clubId),
      ),
    );
  }

  void _openAuthorProfile() {
    if (widget.post.authorId.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileScreen(userId: widget.post.authorId),
      ),
    );
  }

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
    final canManageAsync = ref.watch(canManageNewsProvider(widget.post));
    final canManage = canManageAsync.asData?.value ?? false;
    final userProfile = ref.watch(currentUserProfileProvider).value;
    final isReadOnly = userProfile?.estado != 'activo';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.post.imageUrl != null && widget.post.imageUrl!.isNotEmpty)
            NewsImageAttachment(
              imageUrl: widget.post.imageUrl!,
              newsId: widget.post.id,
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    InkWell(
                      onTap: _openClubProfile,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.campaign_outlined,
                            color: AppColors.primary, size: 20),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: _openClubProfile,
                            child: Text(widget.post.clubName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 13)),
                          ),
                          Row(
                            children: [
                              InkWell(
                                onTap: _openAuthorProfile,
                                child: Text(
                                  '@${widget.post.authorName}',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              Text(
                                ' • ${_relativeTime(widget.post.createdAt)}',
                                style: const TextStyle(
                                    fontSize: 11, color: AppColors.muted),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (canManage && !isReadOnly)
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            size: 20, color: AppColors.muted),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Eliminar noticia'),
                              content: const Text(
                                  '¿Estás seguro de que deseas borrar esta publicación?'),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancelar')),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Eliminar',
                                      style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            final deleted = await ref
                                .read(exploreActionsProvider)
                                .deleteNews(widget.post);
                            if (!context.mounted) return;
                            if (!deleted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'No tienes permiso para eliminar esta noticia.'),
                                ),
                              );
                            }
                          }
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                Text(
                  widget.post.title,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary),
                ),
                const SizedBox(height: 6),
                NewsRichText(content: widget.post.content),
                const SizedBox(height: 12),

                if (widget.post.tags.isNotEmpty)
                  Wrap(
                    spacing: 6.0,
                    runSpacing: 6.0,
                    children: widget.post.tags
                        .map((tag) => NewsTag(label: tag))
                        .toList(),
                  ),

                const SizedBox(height: 12),

                // ⚡ BOTÓN "ME GUSTA" CON RESPUESTA INSTANTÁNEA ⚡
                if (!isReadOnly)
                  InkWell(
                    onTap: () async {
                      // 1. Mutación Optimista: Actualizamos la UI al instante
                      setState(() {
                        _isLikedLocal = !_isLikedLocal;
                        _likesCountLocal += _isLikedLocal ? 1 : -1;
                      });

                      // 2. Ejecutamos tu provider en el backend de forma silenciosa
                      final success = await ref
                          .read(exploreActionsProvider)
                          .toggleLike(widget.post.id);

                      // 3. Rollback: Si la BD rechaza el like o el internet falla, revertimos el color
                      if (!context.mounted) return;
                      if (!success) {
                        setState(() {
                          _isLikedLocal = !_isLikedLocal;
                          _likesCountLocal += _isLikedLocal ? 1 : -1;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Error al conectar con el servidor')),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4.0, vertical: 4.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isLikedLocal
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: _isLikedLocal
                                ? Colors.redAccent
                                : AppColors.muted,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _likesCountLocal.toString(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _isLikedLocal
                                  ? Colors.redAccent
                                  : AppColors.muted,
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
