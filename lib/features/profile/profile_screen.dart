import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/cuc_app_bar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CucAppBar(),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: const [
          _ProfileHeader(),
          _StatsRow(),
          _RankCard(),
          SizedBox(height: 16),
          _ActivitySection(),
          SizedBox(height: 16),
          _RecentPostsSection(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.background,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ── Sub-widgets ─────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1B2B20),
              border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 2),
            ),
            child: const Icon(Icons.person, color: AppColors.primary, size: 40),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NOMBRE DE USUARIO',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFCBD5CE)),
                ),
                SizedBox(height: 2),
                Text(
                  'NOMBRE CLUB',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.folder_outlined, color: AppColors.primary, size: 26),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              label: 'PUBLICACIONES',
              value: '42',
              trend: '+12%',
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: _StatCard(
              label: 'MIEMBRO DESDE',
              value: '2020',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, this.trend});

  final String label;
  final String value;
  final String? trend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: AppColors.muted)),
              if (trend != null)
                Text(
                  trend!,
                  style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w700),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.onBackground),
          ),
        ],
      ),
    );
  }
}

class _RankCard extends StatelessWidget {
  const _RankCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top 5%',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.onBackground),
          ),
          SizedBox(height: 2),
          Text(
            'EN CONTRIBUCIONES',
            style: TextStyle(fontSize: 11, color: AppColors.muted, letterSpacing: 0.8),
          ),
        ],
      ),
    );
  }
}

class _ActivitySection extends StatelessWidget {
  const _ActivitySection();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Actividad', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              Row(
                children: [
                  _LegendDot(color: Color(0xFF1A2B20)),
                  SizedBox(width: 3),
                  _LegendDot(color: Color(0xFF234B22)),
                  SizedBox(width: 3),
                  _LegendDot(color: Color(0xFF3D8C2D)),
                  SizedBox(width: 3),
                  _LegendDot(color: Color(0xFF58C235)),
                  SizedBox(width: 3),
                  _LegendDot(color: AppColors.primary),
                ],
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            '356 contribuciones este año',
            style: TextStyle(fontSize: 11, color: AppColors.muted),
          ),
          SizedBox(height: 10),
          _ActivityHeatmap(),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ENE', style: TextStyle(fontSize: 10, color: AppColors.muted)),
              Text('FEB', style: TextStyle(fontSize: 10, color: AppColors.muted)),
              Text('MAR', style: TextStyle(fontSize: 10, color: AppColors.muted)),
              Text('ABR', style: TextStyle(fontSize: 10, color: AppColors.muted)),
              Text('MAY', style: TextStyle(fontSize: 10, color: AppColors.muted)),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
    );
  }
}

// Heatmap generado programáticamente con datos aleatorios seed-fijos
class _ActivityHeatmap extends StatelessWidget {
  const _ActivityHeatmap();

  static final _levels = [
    const Color(0xFF1A2B20),
    const Color(0xFF234B22),
    const Color(0xFF3D8C2D),
    const Color(0xFF58C235),
    AppColors.primary,
  ];

  static final _rng = Random(42); // seed fijo para reproducibilidad

  static final List<int> _data = List.generate(
    20 * 5, // 20 columnas × 5 filas = 100 celdas
    (_) => _rng.nextInt(5),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 20,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
          childAspectRatio: 1,
        ),
        itemCount: _data.length,
        itemBuilder: (_, i) => Container(
          decoration: BoxDecoration(
            color: _levels[_data[i]],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

class _RecentPostsSection extends StatelessWidget {
  const _RecentPostsSection();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Últimas publicaciones', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          SizedBox(height: 12),
          _RecentPost(icon: Icons.psychology_outlined, title: 'Neural Synapse Mapping'),
          SizedBox(height: 12),
          _RecentPost(icon: Icons.hub_outlined, title: 'Quantum Entanglement Study'),
          SizedBox(height: 12),
          _RecentPost(icon: Icons.biotech_outlined, title: 'Protocolo CRISPR-Cas9 Revisado'),
        ],
      ),
    );
  }
}

class _RecentPost extends StatelessWidget {
  const _RecentPost({required this.icon, required this.title});

  final IconData icon;
  final String title;

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
            decoration: BoxDecoration(
              color: const Color(0xFF1C2E22),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.muted, size: 20),
        ],
      ),
    );
  }
}
