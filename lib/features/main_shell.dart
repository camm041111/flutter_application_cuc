import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'explore/explore_screen.dart';
import 'agenda/agenda_screen.dart';
import 'forum/forum_screen.dart';
import 'repository/repository_screen.dart';
import 'profile/profile_screen.dart';
import '../core/theme/app_theme.dart';
import '../core/providers/supabase_provider.dart'; // 👈 Inyección de dependencias

/// Shell principal con BottomNavigationBar.
/// Evolucionado a ConsumerStatefulWidget para combinar estado local y global.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _currentIndex = 0;

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
    // 1. Interceptamos la sesión activa directamente desde Riverpod
    final currentUser = ref.watch(supabaseClientProvider).auth.currentUser;

    // 🛡️ Filtro de Seguridad (Fail-Fast)
    // Si la sesión es nula, el enrutador falló en bloquear esta ruta.
    // Detenemos el renderizado antes de que ProfileScreen lance una excepción fatal.
    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Error Crítico: Sesión no encontrada.',
            style: TextStyle(color: Colors.redAccent),
          ),
        ),
      );
    }

    // 2. Construimos la lista de pantallas en tiempo de ejecución.
    // Mantenemos 'const' en las que son estáticas para ahorrar memoria.
    final screens = [
      const ExploreScreen(),
      const AgendaScreen(),
      const ForumScreen(),
      const RepositoryScreen(),
      ProfileScreen(userId: currentUser.id), // 👈 Inyección dinámica segura
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
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