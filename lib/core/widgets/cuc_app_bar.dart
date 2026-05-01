import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// AppBar reutilizable con el branding de CUC Research Portal.
/// Usado en todas las pantallas autenticadas (Explorar, Agenda, Foro, Repos, Perfil).
class CucAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CucAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      titleSpacing: 16,
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF122114),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.science, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CUC',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
              Text(
                'RESEARCH PORTAL',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.primary,
                  letterSpacing: 1.2,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_outlined),
          color: Colors.white,
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.account_circle_outlined),
          color: Colors.white,
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(
          height: 1,
          thickness: 1,
          color: AppColors.primary.withValues(alpha: 0.1),
        ),
      ),
    );
  }
}
