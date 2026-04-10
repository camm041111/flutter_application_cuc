import 'package:flutter/material.dart';
import 'explore/explore_screen.dart';
import 'agenda/agenda_screen.dart';
import 'forum/forum_screen.dart';
import 'repository/repository_screen.dart';
import 'profile/profile_screen.dart';
import '../core/theme/app_theme.dart';

/// Shell principal con BottomNavigationBar que contiene las 5 secciones.
/// Se usa StatefulWidget porque necesita mantener el índice seleccionado.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  static const _screens = [
    ExploreScreen(),
    AgendaScreen(),
    ForumScreen(),
    RepositoryScreen(),
    ProfileScreen(),
  ];

  static const _destinations = [
    NavigationDestination(
      icon: Icon(Icons.explore_outlined),
      selectedIcon: Icon(Icons.explore),
      label: 'EXPLORAR',
    ),
    NavigationDestination(
      icon: Icon(Icons.calendar_month_outlined),
      selectedIcon: Icon(Icons.calendar_month),
      label: 'MI AGENDA',
    ),
    NavigationDestination(
      icon: Icon(Icons.forum_outlined),
      selectedIcon: Icon(Icons.forum),
      label: 'FORO',
    ),
    NavigationDestination(
      icon: Icon(Icons.folder_outlined),
      selectedIcon: Icon(Icons.folder),
      label: 'REPOS',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      label: 'PERFIL',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          destinations: _destinations,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          height: 62,
        ),
      ),
    );
  }
}
