import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
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
          const Text('Últimas publicaciones', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          recentPostsAsync.when(
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(20.0), child: CircularProgressIndicator(color: AppColors.primary))),
            error: (e, s) => const Text('No se pudieron cargar las publicaciones', style: TextStyle(color: AppColors.muted)),
            data: (posts) {
              if (posts.isEmpty) return const Text('Sin publicaciones aprobadas aún.', style: TextStyle(color: AppColors.muted));

              return Column(
                children: posts.map((post) {
                  IconData postIcon = Icons.article_outlined;
                  if (post['categoria'] == 'investigacion') postIcon = Icons.biotech_outlined;
                  if (post['categoria'] == 'codigo') postIcon = Icons.code;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _RecentPost(icon: postIcon, title: post['titulo'] ?? 'Sin título'),
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

class _RecentPost extends StatelessWidget {
  final IconData icon;
  final String title;

  const _RecentPost({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1520),
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: const Color(0xFF1C2E22), borderRadius: BorderRadius.circular(6)),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
          const Icon(Icons.chevron_right, color: AppColors.muted, size: 20),
        ],
      ),
    );
  }
}