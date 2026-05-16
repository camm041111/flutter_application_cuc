import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/cache/app_cache_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/cuc_app_bar.dart';
import 'providers/events_providers.dart';
import 'widgets/create_event_sheet.dart';
import 'widgets/events_list.dart';
import 'widgets/filter_tabs.dart';
import 'widgets/agenda_empty_state.dart';

class AgendaScreen extends ConsumerWidget {
  const AgendaScreen({super.key});

  void _openCreateEventSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CreateEventSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showFuture = ref.watch(showFutureEventsProvider);
    final eventsAsync = ref.watch(eventsProvider);
    final canManageAsync = ref.watch(canManageEventsProvider);

    return Scaffold(
      appBar: const CucAppBar(),
      body: Column(
        children: [
          FilterTabs(
            showFuture: showFuture,
            onChanged: (value) => ref
                .read(showFutureEventsProvider.notifier)
                .setShowFuture(value),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref.read(appCacheServiceProvider).invalidatePrefix('events:');
                ref.invalidate(eventsProvider);
              },
              child: eventsAsync.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary)),
                error: (e, s) => AgendaEmptyState(
                  title: 'No se pudieron cargar los eventos',
                  subtitle: '$e',
                ),
                data: (events) => EventsList(
                  events: events,
                  showFuture: showFuture,
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: canManageAsync.maybeWhen(
        data: (canManage) => canManage
            ? FloatingActionButton(
          onPressed: () => _openCreateEventSheet(context),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.background,
          child: const Icon(Icons.add),
        )
            : null,
        orElse: () => null,
      ),
    );
  }
}