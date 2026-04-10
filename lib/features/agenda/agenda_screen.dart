import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/cuc_app_bar.dart';

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  bool _showFuture = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CucAppBar(),
      body: Column(
        children: [
          _FilterTabs(
            showFuture: _showFuture,
            onChanged: (v) => setState(() => _showFuture = v),
          ),
          Expanded(
            child: _showFuture ? const _FutureEvents() : const _PastEvents(),
          ),
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

class _FilterTabs extends StatelessWidget {
  const _FilterTabs({required this.showFuture, required this.onChanged});
  final bool showFuture;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabButton(
              label: 'Eventos Futuros',
              icon: Icons.upcoming_outlined,
              active: showFuture,
              onTap: () => onChanged(true),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _TabButton(
              label: 'Eventos Pasados',
              icon: Icons.history,
              active: !showFuture,
              onTap: () => onChanged(false),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({required this.label, required this.icon, required this.active, required this.onTap});
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: active ? AppColors.primary.withOpacity(0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? AppColors.primary : AppColors.border,
          ),
          boxShadow: active
              ? [BoxShadow(color: AppColors.primary.withOpacity(0.15), blurRadius: 12)]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: active ? AppColors.primary : AppColors.muted),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: active ? AppColors.primary : AppColors.muted,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FutureEvents extends StatelessWidget {
  const _FutureEvents();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(label: 'CUC DACyTI', badge: 'HOY'),
          SizedBox(height: 12),
          _FeaturedEventCard(),
          SizedBox(height: 24),
          Text(
            'Próximos Eventos',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 12),
          _SmallEventCard(
            month: 'Oct',
            day: '18',
            title: 'Taller de Nanotecnología',
            subtitle: 'Fundamentos de Microestructuras',
            location: 'Lab de Materiales Avanzados',
          ),
          SizedBox(height: 10),
          _SmallEventCard(
            month: 'Nov',
            day: '02',
            title: 'Hackathon de Bioinformática',
            subtitle: 'Análisis de Secuencias Genómicas',
            location: 'Lab de Cómputo - Piso 3',
          ),
        ],
      ),
    );
  }
}

class _PastEvents extends StatelessWidget {
  const _PastEvents();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Eventos Pasados', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          SizedBox(height: 12),
          _SmallEventCard(month: 'Sep', day: '30', title: 'Conferencia de Astrofísica', subtitle: 'Materia oscura y cosmología moderna', location: 'Sala de Conferencias B', past: true),
          SizedBox(height: 10),
          _SmallEventCard(month: 'Sep', day: '20', title: 'Hackathon de Bioinformática', subtitle: 'Análisis de secuencias genómicas', location: 'Lab de Cómputo - Piso 3', past: true),
          SizedBox(height: 10),
          _SmallEventCard(month: 'Sep', day: '10', title: 'Seminario de Robótica', subtitle: 'Automatización industrial con ROS 2', location: 'Taller de Mecatrónica', past: true),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label, this.badge});
  final String label;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 4, height: 24, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(99))),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const Spacer(),
        if (badge != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(badge!, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary)),
          ),
      ],
    );
  }
}

class _FeaturedEventCard extends StatelessWidget {
  const _FeaturedEventCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                height: 160,
                color: AppColors.surfaceVariant,
                child: const Center(child: Icon(Icons.event, color: AppColors.muted, size: 48)),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text('EN VIVO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.background, letterSpacing: 1.5)),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Simposio de Biotecnología Aplicada', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                const Text(
                  'Exploración de avances en edición genética CRISPR y las implicaciones de la bioética en el siglo XXI.',
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                const _InfoRow(icon: Icons.calendar_today, label: '15 Oct, 2023'),
                const SizedBox(height: 4),
                const _InfoRow(icon: Icons.schedule, label: '09:00 AM'),
                const SizedBox(height: 6),
                const _InfoRow(icon: Icons.location_on, label: 'Auditorio Principal - Edificio A', primary: true),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(onPressed: () {}, child: const Text('VER DETALLES')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, this.primary = false});
  final IconData icon;
  final String label;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: primary ? AppColors.primary : AppColors.muted),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: primary ? AppColors.primary : AppColors.muted,
            fontWeight: primary ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _SmallEventCard extends StatelessWidget {
  const _SmallEventCard({
    required this.month,
    required this.day,
    required this.title,
    required this.subtitle,
    required this.location,
    this.past = false,
  });

  final String month;
  final String day;
  final String title;
  final String subtitle;
  final String location;
  final bool past;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: past ? 0.55 : 1.0,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: past ? AppColors.surface : AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(month, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: past ? AppColors.muted : AppColors.primary)),
                    Text(day, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: past ? AppColors.muted : AppColors.primary)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
                    Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.muted), overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 12, color: past ? AppColors.muted : AppColors.primary),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            location,
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: past ? AppColors.muted : AppColors.primary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: past ? AppColors.muted : AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
