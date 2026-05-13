import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/cache/app_cache_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/cuc_app_bar.dart';
import '../social/social_providers.dart';

class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});

  void _openNewsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _NewsComposerSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsAsync = ref.watch(newsProvider);
    final canPublishAsync = ref.watch(canPublishNewsProvider);

    return Scaffold(
      appBar: const CucAppBar(),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(appCacheServiceProvider).invalidatePrefix('social:news');
          ref.invalidate(newsProvider);
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _NewsSearchBar()),
            newsAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              ),
              error: (error, _) => SliverFillRemaining(
                child: _ExploreEmptyState(
                  icon: Icons.feed_outlined,
                  title: 'No se pudieron cargar las noticias',
                  subtitle: '$error',
                ),
              ),
              data: (posts) {
                if (posts.isEmpty) {
                  return const SliverFillRemaining(
                    child: _ExploreEmptyState(
                      icon: Icons.campaign_outlined,
                      title: 'Sin noticias publicadas',
                      subtitle: 'Cuando lideres o coordinadores publiquen anuncios apareceran aqui.',
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  sliver: SliverList.separated(
                    itemCount: posts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, index) => _NewsCard(post: posts[index]),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: canPublishAsync.maybeWhen(
        data: (canPublish) => canPublish
            ? FloatingActionButton(
                onPressed: () => _openNewsSheet(context),
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.background,
                child: const Icon(Icons.campaign_outlined),
              )
            : null,
        orElse: () => null,
      ),
    );
  }
}

class _NewsSearchBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            decoration: const InputDecoration(
              hintText: 'Buscar noticias, clubes o comunicados...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) => ref.read(newsSearchProvider.notifier).setSearch(value),
          ),
          const SizedBox(height: 12),
          const Text(
            'Noticias de clubes',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({required this.post});

  final NewsPost post;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                post.imageUrl!,
                height: 168,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
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
                Text(
                  post.title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary),
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

class _NewsComposerSheet extends ConsumerStatefulWidget {
  const _NewsComposerSheet();

  @override
  ConsumerState<_NewsComposerSheet> createState() => _NewsComposerSheetState();
}

class _NewsComposerSheetState extends ConsumerState<_NewsComposerSheet> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _imageCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _imageCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(socialActionsProvider).createNews(
            NewsInput(
              title: _titleCtrl.text,
              content: _contentCtrl.text,
              imageUrl: _imageCtrl.text.trim().isEmpty ? null : _imageCtrl.text,
            ),
          );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Noticia publicada.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo publicar: $error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Publicar noticia', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(hintText: 'Titulo'),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Ingresa un titulo' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _contentCtrl,
                  minLines: 4,
                  maxLines: 8,
                  decoration: const InputDecoration(hintText: 'Contenido del comunicado'),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Ingresa el contenido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _imageCtrl,
                  decoration: const InputDecoration(
                    hintText: 'URL de imagen opcional',
                    prefixIcon: Icon(Icons.image_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _submit,
                    icon: _saving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.send_outlined),
                    label: const Text('PUBLICAR'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExploreEmptyState extends StatelessWidget {
  const _ExploreEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.muted, size: 36),
              const SizedBox(height: 10),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700), textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 12), textAlign: TextAlign.center),
            ],
          ),
        ),
      ],
    );
  }
}

String _relativeTime(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'Ahora';
  if (diff.inHours < 1) return 'Hace ${diff.inMinutes}m';
  if (diff.inDays < 1) return 'Hace ${diff.inHours}h';
  if (diff.inDays < 7) return 'Hace ${diff.inDays}d';
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
