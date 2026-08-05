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
          onPressed: () {
            _openNotifications(context);
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
            data: (items) => RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.surface,
              onRefresh: () =>
                  ref.read(notificationsProvider.notifier).refresh(),
              child: ListView(
                controller: scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Notificaciones',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w800)),
                      ),
                      if (items.any((item) => !item.read))
                        TextButton.icon(
                          onPressed: () => ref
                              .read(notificationServiceProvider)
                              .markAllAsRead(),
                          icon: const Icon(Icons.done_all, size: 16),
                          label: const Text('LEER TODO',
                              style: TextStyle(fontSize: 11)),
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
    final unread = !item.read;
    final iconData = _iconForType(item.type);
    final color = _colorForType(item.type);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: unread ? AppColors.surfaceVariant : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: unread
                ? AppColors.primary.withValues(alpha: 0.35)
                : AppColors.border,
          ),
        ),
        child: ListTile(
          onTap: unread
              ? () => ref.read(notificationServiceProvider).markAsRead(item.id)
              : null,
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(iconData, color: color, size: 20),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: unread ? FontWeight.w800 : FontWeight.w600,
                    color: unread
                        ? AppColors.onBackground
                        : AppColors.onSurface,
                  ),
                ),
              ),
              if (unread)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),
              Text(
                item.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                _relativeTime(item.createdAt),
                style: const TextStyle(color: AppColors.muted, fontSize: 10),
              ),
            ],
          ),
          trailing: IconButton(
            tooltip: 'Eliminar',
            icon: const Icon(
              Icons.delete_outline,
              size: 18,
              color: AppColors.muted,
            ),
            onPressed: () =>
                ref.read(notificationServiceProvider).deleteNotification(item.id),
          ),
        ),
      ),
    );
  }
}

IconData _iconForType(String type) {
  switch (type) {
    case 'solicitud_ingreso':
      return Icons.person_add_alt_1_outlined;
    case 'repositorio':
      return Icons.description_outlined;
    case 'agenda':
      return Icons.event_available_outlined;
    case 'foro':
      return Icons.forum_outlined;
    case 'noticia':
      return Icons.newspaper_outlined;
    case 'sistema':
      return Icons.info_outline;
    default:
      return Icons.notifications_outlined;
  }
}

Color _colorForType(String type) {
  switch (type) {
    case 'solicitud_ingreso':
      return const Color(0xFF4FC3F7);
    case 'repositorio':
      return AppColors.primary;
    case 'agenda':
      return const Color(0xFFFFB74D);
    case 'foro':
      return const Color(0xFFBA68C8);
    case 'noticia':
      return const Color(0xFFFF8A65);
    default:
      return AppColors.muted;
  }
}

String _relativeTime(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inSeconds < 60) return 'ahora mismo';
  if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'hace ${diff.inHours} h';
  if (diff.inDays == 1) return 'ayer';
  if (diff.inDays < 7) return 'hace ${diff.inDays} días';
  return '${date.day}/${date.month}/${date.year}';
}
