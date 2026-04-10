import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/cuc_app_bar.dart';

class ForumScreen extends StatelessWidget {
  const ForumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CucAppBar(),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              const TextField(
                decoration: InputDecoration(
                  hintText: 'Buscar discusiones...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 20),
              const _ForumPostCard(
                authorName: 'Dr. Alan Smith',
                authorRole: 'Biología Molecular',
                timeAgo: 'Hace 2h',
                title: 'Eficiencia de CRISPR-Cas9 en Células T',
                body: '¿Alguien ha experimentado efectos fuera de objetivo al usar la nueva variante de Cas9 en células T humanas primarias? Nuestros ensayos muestran escisión inesperada...',
                tags: ['Genética', 'CRISPR'],
                likes: 24,
                replies: 8,
                liked: false,
              ),
              const SizedBox(height: 16),
              const _ForumPostCard(
                authorName: 'Sarah Chen',
                authorRole: 'Astrofísica',
                timeAgo: 'Hace 5h',
                title: 'Lecturas anómalas del arreglo de telescopios Sector 7G',
                body: 'Hemos detectado ráfagas de radio repetitivas. Adjuntamos los datos del espectrógrafo. Parece no aleatorio, pero aún no se ha descartado interferencia.',
                tags: ['Radioastronomía'],
                likes: 156,
                replies: 42,
                liked: true,
                hasMedia: true,
              ),
              const SizedBox(height: 16),
              const _ForumPostCard(
                authorName: 'Quantum Lab Group',
                authorRole: 'Computación Cuántica',
                timeAgo: 'Hace 1d',
                title: 'Estrategia de extensión del tiempo de coherencia de qubits',
                body: 'Proponemos un nuevo esquema de corrección de errores que teóricamente duplicaría los tiempos de coherencia. Buscamos revisión de pares de las matemáticas.',
                tags: [],
                likes: 89,
                replies: 12,
                liked: false,
                isGroup: true,
              ),
            ],
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: _ForumFab(),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ─────────────────────────────────────────────────────────────

class _ForumPostCard extends StatelessWidget {
  const _ForumPostCard({
    required this.authorName,
    required this.authorRole,
    required this.timeAgo,
    required this.title,
    required this.body,
    required this.tags,
    required this.likes,
    required this.replies,
    required this.liked,
    this.hasMedia = false,
    this.isGroup = false,
  });

  final String authorName;
  final String authorRole;
  final String timeAgo;
  final String title;
  final String body;
  final List<String> tags;
  final int likes;
  final int replies;
  final bool liked;
  final bool hasMedia;
  final bool isGroup;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author row
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isGroup ? AppColors.primary.withOpacity(0.1) : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: isGroup
                      ? const Icon(Icons.hub, color: AppColors.primary, size: 20)
                      : const Icon(Icons.person, color: AppColors.muted, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(authorName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      Text(
                        '$authorRole • $timeAgo',
                        style: const TextStyle(fontSize: 9, color: AppColors.muted, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.more_vert, color: AppColors.muted, size: 20),
              ],
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              body,
              style: const TextStyle(fontSize: 12, color: AppColors.muted, height: 1.5),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            // Imagen placeholder
            if (hasMedia) ...[
              const SizedBox(height: 10),
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Center(
                  child: Icon(Icons.bar_chart, color: AppColors.primary, size: 36),
                ),
              ),
            ],
            // Tags
            if (tags.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                children: tags.map((t) => Chip(label: Text(t))).toList(),
              ),
            ],
            // Divider + actions
            const SizedBox(height: 12),
            Divider(color: AppColors.border.withOpacity(0.5), height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                _ForumAction(icon: Icons.thumb_up_outlined, label: '$likes', active: liked),
                const SizedBox(width: 20),
                _ForumAction(icon: Icons.chat_bubble_outline, label: '$replies Respuestas'),
                const Spacer(),
                const Icon(Icons.share_outlined, size: 18, color: AppColors.muted),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ForumAction extends StatelessWidget {
  const _ForumAction({required this.icon, required this.label, this.active = false});
  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: active ? AppColors.primary : AppColors.muted),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: active ? AppColors.primary : AppColors.muted)),
      ],
    );
  }
}

class _ForumFab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.35), blurRadius: 20)],
        ),
        child: const Icon(Icons.add_comment, color: AppColors.background, size: 26),
      ),
    );
  }
}
