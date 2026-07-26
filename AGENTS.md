# CUC Research Portal — Agent Guide

## Identity
- **Package**: `cuc_research_portal` — research portal for "Clubes Universitarios de Ciencias"
- **Stack**: Flutter (Material 3) + Riverpod + GoRouter + Supabase + flutter_dotenv

## Setup
- Requires `.env` at project root with `SUPABASE_URL` and `SUPABASE_ANON_KEY`
- `flutter pub get` to install dependencies
- Font **SpaceGrotesk** is used in theme — install via Google Fonts or add locally; currently no local font file bundled

## Dev Commands
- `flutter run` — launch app
- `flutter test` — run all tests
- `dart analyze` — static analysis (uses `package:flutter_lints/flutter.yaml`)
- Lint rules in `analysis_options.yaml`: `prefer_const_constructors`, `prefer_single_quotes`, `avoid_unnecessary_containers`, `use_key_in_widget_constructors`, `sized_box_for_whitespace`

## Architecture
- **Feature-based**: `lib/features/<name>/` — each feature may have `providers/`, `widgets/`, screens
- **Core shared**: `lib/core/` — theme, constants, services, cache, providers, widgets
- **State management**: Riverpod providers throughout. Never call `Supabase.instance.client` directly — use `supabaseClientProvider`
- **Routing**: `GoRouter` defined in `lib/core/constants/app_routes.dart` via `routerProvider`. Auth guard logic (redirect) lives there — redirects unauthenticated → `/login`, pending-profile → `/pending`
- **Entrypoint**: `lib/main.dart` — loads `.env`, initializes Supabase, wraps app in `ProviderScope`
- **Shell**: `MaterialApp.router` → `MainShell` at `/` with 5-tab `IndexedStack` (Explore, Agenda, Forum, Repository, Profile)

## Auth
- **Supabase Auth** with email/password
- **Business rule**: only `@alumno.ujat.mx` or `@ujat.mx` emails accepted (enforced in `AuthService.registrarUsuario`)
- **Profile states**: `registrado` → `/pending`, `activo`/`baja`/`inactivo` → `/`

## Testing
- `wrap in ProviderScope` for any widget test using Riverpod
- Mock Supabase init + `SharedPreferences.setMockInitialValues` in `setUpAll`

## Key Conventions
- Dark theme (`AppTheme.dark`), primary green `#6EE718`
- UI labels in Spanish (MX), English fallback
- `const` constructors preferred (enforced by linter)
- Single quotes preferred (enforced by linter)
