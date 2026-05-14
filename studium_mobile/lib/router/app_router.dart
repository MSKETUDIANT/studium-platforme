import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:studium_mobile/features/dashboard/presentation/pages/dashboard_page.dart';
import '../features/applications/domain/entities/application.dart';
import '../features/applications/presentation/pages/applications_page.dart';
import '../features/applications/presentation/pages/application_detail_page.dart';
import '../features/applications/presentation/pages/new_application_wizard.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/reset_password_screen.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/profile/presentation/pages/profile_page.dart';
import '../features/profile/presentation/pages/edit_profile_page.dart';
import '../features/documents/presentation/pages/documents_page.dart';
import '../features/programs/domain/entities/program.dart';
import '../features/programs/presentation/pages/programs_page.dart';
import '../shared/widgets/main_shell.dart';
import '../shared/widgets/placeholder_screen.dart';
import '../main.dart';

final isResettingPasswordProvider = StateProvider<bool>((ref) => false);

class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier(this._ref) {
    _ref.listen<AsyncValue>(authStateProvider, (_, __) => notifyListeners());
  }
  final Ref _ref;
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthNotifier(ref);

  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/splash',
    refreshListenable: notifier,

    onException: (context, state, router) {
      final uri = state.uri;
      final token = uri.queryParameters['token'] ??
                    uri.queryParameters['code'];
      if (token != null) {
        router.go('/reset-password?code=$token');
      } else {
        router.go('/login');
      }
    },

    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      if (authState.isLoading) return null;

      final isResetting = ref.read(isResettingPasswordProvider);
      if (isResetting) return null;
      if (state.matchedLocation.startsWith('/reset-password')) return null;

      final user = authState.valueOrNull;
      const publicRoutes = [
        '/login',
        '/register',
        '/splash',
        '/forgot-password',
        '/reset-password',
      ];
      final isPublic = publicRoutes.any(
        (r) => state.matchedLocation.startsWith(r),
      );

      if (user == null && !isPublic) return '/login';
      if (user != null && isPublic) return '/home';
      return null;
    },

    routes: [
      // ─── Routes publiques ────────────────────────────────────────────────
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login',  builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/forgot-password',
          builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) {
          final code = state.uri.queryParameters['code'] ??
                       state.uri.queryParameters['token'];
          return ResetPasswordScreen(code: code);
        },
      ),

      // ─── Shell avec bottom nav ───────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => MainShell(navigationShell: shell),
        branches: [
          // Branche 0 — Accueil
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home',
              builder: (_, __) => const DashboardPage(),
            ),
          ]),

          // Branche 1 — Programmes
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/programs',
              builder: (_, __) => const ProgramsPage(),
            ),
          ]),

          // Branche 2 — Candidatures
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/applications',
              builder: (_, __) => const ApplicationsPage(),
            ),
          ]),

          // Branche 3 — Messages
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/messages',
              builder: (_, __) => const MessagesScreen(),
            ),
          ]),

          // Branche 4 — Profil
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/profile',
              builder: (_, __) => const ProfilePage(),
            ),
          ]),
        ],
      ),

      // ─── Routes hors shell (plein écran, sans bottom nav) ───────────────
      GoRoute(
        path: '/profile/edit',
        parentNavigatorKey: navigatorKey,
        builder: (_, __) => const EditProfilePage(),
      ),
      GoRoute(
        path: '/documents',
        parentNavigatorKey: navigatorKey,
        builder: (_, __) => const DocumentsPage(),
      ),
      GoRoute(
        path: '/applications/new',
        parentNavigatorKey: navigatorKey,
        builder: (context, state) {
          final program = state.extra as Program?;
          return NewApplicationWizard(program: program);
        },
      ),
      GoRoute(
        path: '/applications/:id',
        parentNavigatorKey: navigatorKey,
        builder: (context, state) {
          final app = state.extra as Application;
          return ApplicationDetailPage(app: app);
        },
      ),
    ],
  );
});