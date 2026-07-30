import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/cuc_app_bar.dart';
import '../../../core/widgets/cuc_pill_tab_bar.dart';
import '../tabs/members_management_tab.dart';
import '../tabs/pending_documents_tab.dart';

class CoordinatorPanelScreen extends ConsumerWidget {
  const CoordinatorPanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: CucAppBar(),
        body: ColoredBox(
          color: AppColors.background,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(20, 26, 20, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Panel de Gestión',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Aprobación para líderes y coordinadores',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.muted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              CucPillTabBar(
                labels: ['MIEMBROS', 'DOCUMENTOS'],
              ),
              SizedBox(height: 8),
              Expanded(
                child: TabBarView(
                  children: [
                    MembersManagementTab(),
                    PendingDocumentsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
