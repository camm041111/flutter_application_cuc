import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/auth_providers.dart';
import '../../features/auth/login/login_screen.dart';
import '../../features/auth/register/register_screen.dart';
import '../../features/main_navigation_bar.dart';
import '../../features/profile/banned_profile_screen.dart';
import '../../features/profile/pending_profile_screen.dart';
import '../../features/profile/providers/profile_providers.dart';

// 🛡️ 1. NUEVO: Notificador unificado de seguridad
// Este puente avisa a GoRouter cuando la sesión O el perfil cambian.
final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  RouterNotifier(this._ref) {
    _ref.listen(authStateProvider, (_, __) => notifyListeners());
    _ref.listen(currentUserProfileProvider, (_, __) => notifyListeners());
  }
}

// 🛡️ 2. REFACTORIZACIÓN DEL ROUTER
final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: '/splash',
    // GoRouter ahora es reactivo a ambos estados
    refreshListenable: notifier,

    redirect: (context, state) {
      final isSplash = state.uri.toString() == '/splash';

      // CRÍTICO: Usamos ref.read() para evitar el anti-patrón de reconstrucción
      final authState = ref.read(authStateProvider);
      final profileAsync = ref.read(currentUserProfileProvider);

      if (authState.isLoading) {
        return isSplash ? null : '/splash';
      }

      final isAuth = authState.value?.session != null;
      final isGoingToLogin = state.uri.toString() == '/login';
      final isGoingToRegister = state.uri.toString() == '/register';

      // Protección 1: Sin sesión, a las rutas públicas.
      if (!isAuth) {
        return (isGoingToLogin || isGoingToRegister) ? null : '/login';
      }

      // 🛡️ CANDADO ARQUITECTÓNICO: Si está autenticado pero el perfil
      // aún se está descargando de la BD, lo forzamos a quedarse en el Splash.
      if (profileAsync.isLoading) {
        return isSplash ? null : '/splash';
      }

      // Una vez que tenemos los datos, evaluamos el estado.
      final redirectPath = _evaluateProfileRedirect(profileAsync);

      // Si viene de arranque o de login, lo mandamos a su ruta designada
      if (isSplash || isGoingToLogin || isGoingToRegister) {
        return redirectPath ?? '/';
      }

      // Si ya está navegando pero su estado exige otra pantalla (ej. baneado en tiempo real)
      if (redirectPath != null && redirectPath != state.uri.toString()) {
        return redirectPath;
      }

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const _AuthLoadingScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(path: '/pending', builder: (context, state) => const PendingProfileScreen()),
      GoRoute(path: '/banned', builder: (context, state) => const BannedProfileScreen()),
      GoRoute(path: '/', builder: (context, state) => const MainShell()),
    ],
    errorBuilder: (context, state) => Scaffold(body: Center(child: Text('Error de ruteo: ${state.error}'))),
  );
});

class _AuthLoadingScreen extends StatelessWidget {
  const _AuthLoadingScreen();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

// 🛡️ 3. EVALUACIÓN ESTRICTA DEL ESTADO
String? _evaluateProfileRedirect(AsyncValue<UserProfile?> profileAsync) {
  return profileAsync.when(
    data: (profile) {
      if (profile == null) return '/login';

      final estado = profile.estado;
      if (estado == 'registrado' || estado == 'rechazado') return '/pending';
      if (estado == 'baja') return '/banned';

      // Activos e inactivos (Solo lectura) tienen acceso a la estructura principal
      return null;
    },
    loading: () => '/splash',
    error: (_, __) => '/login', // Si Supabase falla críticamente, deslogueamos por seguridad
  );
}