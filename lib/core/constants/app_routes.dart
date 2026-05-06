import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Inyección de dependencias y providers de identidad
import '../providers/auth_providers.dart';

// Importaciones de Feature-Modules
import '../../features/auth/login/login_screen.dart';
import '../../features/auth/register/register_screen.dart';
import '../../features/main_shell.dart';
import '../../features/profile/pending_profile_screen.dart';

/// Proveedor global de navegación.
/// Implementa la lógica de "Guardia" para cumplir con el RF01 (Gestión de Usuarios).
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final perfilAsync = ref.watch(perfilUsuarioProvider);
  final supabase = ref.watch(supabaseClientProvider);

  return GoRouter(
    initialLocation: '/login',

    // CRÍTICO: Escucha cambios en Supabase para re-evaluar las rutas automáticamente
    refreshListenable: GoRouterRefreshStream(supabase.auth.onAuthStateChange),

    redirect: (context, state) {
      final isAuth = authState.value?.session != null;
      final isGoingToLogin = state.uri.toString() == '/login';
      final isGoingToRegister = state.uri.toString() == '/register';

      // 1. Protección de Rutas Privadas: Si no hay sesión, al Login.
      if (!isAuth && !isGoingToLogin && !isGoingToRegister) {
        return '/login';
      }

      // 2. Lógica de Redirección post-autenticación
      if (isAuth) {
        // Evita que un usuario autenticado regrese manualmente al Login/Registro
        if (isGoingToLogin || isGoingToRegister) {
          return _evaluateProfileRedirect(perfilAsync);
        }

        // Validación de estado de cuenta (RF01.3: Estado pendiente).
        final redirectPath = _evaluateProfileRedirect(perfilAsync);
        if (redirectPath != null && redirectPath != state.uri.toString()) {
          return redirectPath;
        }
      }

      return null; // Permite la navegación
    },

    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/pending',
        builder: (context, state) => const PendingProfileScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const MainShell(),
      ),
    ],

    // Manejo de errores de ruta (RNF03: Usabilidad)
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Error: ${state.error}')),
    ),
  );
});

/// Evalúa el 'estado' del perfil para cumplir con el control de acceso[cite: 3].
String? _evaluateProfileRedirect(AsyncValue<Map<String, dynamic>?> perfilAsync) {
  return perfilAsync.when(
    data: (perfil) {
      if (perfil == null) return null;

      final estado = perfil['estado'] as String?;

      // RF01.3: Si está registrado pero no aprobado, a pantalla de espera[cite: 3].
      if (estado == 'registrado') {
        return '/pending';
      }

      // Perfiles aprobados, bajas o egresados entran al shell (con restricciones de UI)[cite: 3].
      if (estado == 'activo' || estado == 'baja' || estado == 'inactivo') {
        return '/';
      }
      return null;
    },
    loading: () => null, // Mantiene la vista actual mientras carga la metadata
    error: (_, __) => '/login', // Ante fallo crítico de BD, por seguridad se desloguea
  );
}

/// Helper para convertir el Stream de Auth en un Listenable para GoRouter
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<AuthState> _subscription;

  GoRouterRefreshStream(Stream<AuthState> stream) {
    notifyListeners();
    _subscription = stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}