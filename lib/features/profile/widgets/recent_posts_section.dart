import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/supabase_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../repository/providers/repository_providers.dart';
import '../../repository/widgets/repository_detail_sheet.dart';
import '../providers/profile_providers.dart';

class RecentPostsSection extends ConsumerWidget {
  final String userId;
  const RecentPostsSection({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentPostsAsync = ref.watch(recentPostsProvider(userId));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Últimas publicaciones',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          recentPostsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
            error: (e, s) => const Text(
              'No se pudieron cargar las publicaciones',
              style: TextStyle(color: AppColors.muted),
            ),
            data: (posts) {
              if (posts.isEmpty) {
                return const Text(
                  'Sin publicaciones aprobadas aún.',
                  style: TextStyle(color: AppColors.muted),
                );
              }

              return Column(
                children: posts.map((post) {
                  IconData postIcon = Icons.article_outlined;
                  if (post.categoria == 'investigacion') {
                    postIcon = Icons.biotech_outlined;
                  } else if (post.categoria == 'codigo') {
                    postIcon = Icons.code;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _RecentPostTile(
                      icon: postIcon,
                      post: post,
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RecentPostTile extends ConsumerStatefulWidget {
  final IconData icon;
  final RecentPost post;

  const _RecentPostTile({required this.icon, required this.post});

  @override
  ConsumerState<_RecentPostTile> createState() => _RecentPostTileState();
}

class _RecentPostTileState extends ConsumerState<_RecentPostTile> {
  bool _isLoading = false;

  Future<void> _openDetail() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final supabase = ref.read(supabaseClientProvider);

      // Consulta atómica y específica para el documento requerido
      final response = await supabase
          .from('publicaciones_repositorio')
          .select(
          'id, id_autor, id_club, titulo, descripcion, categoria, area_conocimiento, etiquetas, urls_archivos, estado, fecha_creacion, perfiles(nombre_completo), clubes(nombre)')
          .eq('id', widget.post.id)
          .single();

      final document = RepositoryDocument.fromJson(response);

      if (!mounted) return;

      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => RepositoryDetailSheet(document: document),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar el documento: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _openDetail,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface, // Unificado con el fondo de tarjetas
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(widget.icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.post.titulo,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              const Icon(Icons.chevron_right, color: AppColors.muted, size: 20),
          ],
        ),
      ),
    );
  }
}