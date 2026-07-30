import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

/// AppBar reutilizable con el branding de CUC Research Portal.
/// Usado en todas las pantallas autenticadas (Explorar, Agenda, Foro, Repos, Perfil).
class CucAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const CucAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(notificationsProvider).maybeWhen(
          data: (items) => items.where((item) => !item.read).length,
          orElse: () => 0,
        );

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
            child:
                const Icon(Icons.science, color: AppColors.primary, size: 20),
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
          onPressed: () async {
            try {
              await ref.read(notificationServiceProvider).markAllAsRead();
            } catch (_) {
              // La bandeja debe abrir incluso si la actualizacion remota falla.
            }
            if (context.mounted) {
              _openNotifications(context);
            }
          },
          icon: Badge(
            isLabelVisible: unreadCount > 0,
            label: Text(unreadCount > 9 ? '9+' : '$unreadCount'),
            child: const Icon(Icons.notifications_outlined),
          ),
          color: Colors.white,
        ),
        IconButton(
          tooltip: 'Cerrar sesión',
          onPressed: () => _confirmLogout(context, ref),
          icon: const Icon(Icons.logout_rounded),
          color: AppColors.error,
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

  void _openNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _NotificationsSheet(),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.logout_rounded,
          color: AppColors.error,
        ),
        title: const Text('Cerrar sesión'),
        content: const Text(
          'Tu sesión actual se cerrará y tendrás que identificarte '
          'nuevamente para acceder. ¿Deseas continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Cerrar sesión',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout != true || !context.mounted) return;

    try {
      await ref.read(authServiceProvider).cerrarSesion();
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo cerrar sesión: $error')),
      );
    }
  }
}

class _NotificationsSheet extends ConsumerWidget {
  const _NotificationsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: notificationsAsync.when(
            loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary)),
            error: (error, _) => ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                Text('No se pudieron cargar las notificaciones: $error')
              ],
            ),
            data: (items) => ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text('Notificaciones',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800)),
                    ),
                    IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close)),
                  ],
                ),
                const SizedBox(height: 8),
                if (items.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Aun no tienes notificaciones.',
                        textAlign: TextAlign.center),
                  )
                else
                  ...items.map((item) => _NotificationTile(item: item)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.item});

  final AppNotification item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        leading: Icon(
          item.type == 'agenda'
              ? Icons.event_available_outlined
              : Icons.notifications_outlined,
          color: item.read ? AppColors.muted : AppColors.primary,
        ),
        title: Text(item.title,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(item.body, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: IconButton(
          icon: const Icon(Icons.done, size: 18),
          onPressed: item.read
              ? null
              : () => ref.read(notificationServiceProvider).markAsRead(item.id),
        ),
      ),
    );
  }
}
