import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/cuc_app_bar.dart';
import '../../core/constants/app_routes.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CucAppBar(),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _SearchAndFilters()),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList.separated(
                  itemCount: 3,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (_, i) => _ResearchPostCard(index: i),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: _Fab(
              onTap: () => Navigator.pushNamed(context, AppRoutes.newPost),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ─────────────────────────────────────────────────────────────

class _SearchAndFilters extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Investiguemos un poco...',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(label: 'Recientes', active: true),
                SizedBox(width: 8),
                _FilterChip(label: 'Clubes'),
                SizedBox(width: 8),
                _FilterChip(label: 'Fecha'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, this.active = false});
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: active ? AppColors.primary : AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: active ? AppColors.primary : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: active ? AppColors.background : AppColors.onSurface,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.expand_more,
            size: 16,
            color: active ? AppColors.background : AppColors.muted,
          ),
        ],
      ),
    );
  }
}

// Modelo de datos de ejemplo
final _posts = [
  (club: 'Club de Ecología', author: 'Dr. Roberto Gómez', time: 'Hace 2h', icon: Icons.eco,
    title: 'Análisis de Sostenibilidad Urbana', body: 'Nuestros últimos hallazgos sugieren que la implementación de techos verdes en el campus principal reduciría la huella térmica en un 15%.', likes: 128, comments: 24),
  (club: 'Quantum Computing Lab', author: 'Dra. Ana López', time: 'Hace 5h', icon: Icons.hub,
    title: 'Extensión de Coherencia en Qubits', body: 'Proponemos un nuevo esquema de corrección de errores que duplicaría los tiempos de coherencia. Buscamos revisión de pares.', likes: 89, comments: 12),
  (club: 'Club de Biología Molecular', author: 'Dr. Alan Smith', time: 'Hace 1d', icon: Icons.biotech,
    title: 'Eficiencia de CRISPR-Cas9 en Células T', body: '¿Alguien ha experimentado efectos fuera de objetivo usando la nueva variante de Cas9 en células T primarias humanas?', likes: 156, comments: 42),
];

class _ResearchPostCard extends StatelessWidget {
  const _ResearchPostCard({required this.index});
  final int index;

  @override
  Widget build(BuildContext context) {
    final p = _posts[index];
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header del post
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(p.icon, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.club, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      Text(
                        '${p.author} • ${p.time}',
                        style: const TextStyle(fontSize: 11, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.more_horiz, color: AppColors.muted),
              ],
            ),
          ),
          // Contenido
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  p.body,
                  style: const TextStyle(fontSize: 13, color: AppColors.onSurface, height: 1.5),
                ),
              ],
            ),
          ),
          // Imagen de placeholder (solo primer post)
          if (index == 0)
            Container(
              margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              height: 180,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Icon(Icons.image_outlined, color: AppColors.muted, size: 40),
              ),
            ),
          // Acciones
          Divider(color: AppColors.primary.withOpacity(0.05), height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                _ActionButton(icon: Icons.favorite_outline, label: '${p.likes}', active: index == 2),
                const SizedBox(width: 20),
                _ActionButton(icon: Icons.chat_bubble_outline, label: '${p.comments}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.label, this.active = false});
  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: active ? AppColors.primary : AppColors.muted),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: active ? AppColors.primary : AppColors.muted,
          ),
        ),
      ],
    );
  }
}

class _Fab extends StatelessWidget {
  const _Fab({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.4),
              blurRadius: 20,
            ),
          ],
        ),
        child: const Icon(Icons.add, color: AppColors.background, size: 28),
      ),
    );
  }
}
