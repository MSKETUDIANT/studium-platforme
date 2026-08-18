import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:studium_mobile/features/dashboard/presentation/pages/dashboard_page.dart';
import '../features/applications/domain/entities/application.dart';
import '../features/applications/presentation/pages/applications_page.dart';
import '../features/applications/presentation/pages/application_detail_page.dart';
import '../features/applications/presentation/pages/new_application_wizard.dart';
import '../features/auth/presentation/screens/accept_terms_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/onboarding_wizard.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/email_confirmation_screen.dart';
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
import '../features/messaging/presentation/pages/messages_page.dart';
import '../features/notifications/presentation/pages/notifications_page.dart';
import '../features/settings/presentation/pages/settings_page.dart';
import '../features/ambassador/presentation/pages/ambassador_page.dart';
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
        '/email-sent',
      ];
      final isPublic = publicRoutes.any(
        (r) => state.matchedLocation.startsWith(r),
      );

      final onboardingDone =
          Supabase.instance.client.auth.currentUser
              ?.userMetadata?['onboarding_done'] == true;

      // Consentement RGPD (CGU / politique de confidentialité). Fixé dès
      // l'inscription pour le flux email/mot de passe (auth_remote_datasource.dart) ;
      // pour Google/Apple, ce flag n'existe pas encore -> interstitiel obligatoire
      // avant tout accès à l'app, quel que soit l'écran d'entrée (Login ou Register).
      final termsAccepted =
          Supabase.instance.client.auth.currentUser
              ?.userMetadata?['terms_accepted'] == true;

      if (user == null && !isPublic) return '/login';

      if (user != null) {
        if (isPublic) {
          if (!termsAccepted) return '/accept-terms';
          return onboardingDone ? '/home' : '/onboarding';
        }
        if (!termsAccepted &&
            !state.matchedLocation.startsWith('/accept-terms')) {
          return '/accept-terms';
        }
        if (termsAccepted &&
            state.matchedLocation.startsWith('/accept-terms')) {
          return onboardingDone ? '/home' : '/onboarding';
        }
        if (termsAccepted && !onboardingDone &&
            !state.matchedLocation.startsWith('/onboarding')) {
          return '/onboarding';
        }
        if (termsAccepted && onboardingDone &&
            state.matchedLocation.startsWith('/onboarding')) {
          return '/home';
        }
      }
      return null;
    },

    routes: [
      //  Routes publiques 
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login',  builder: (_, __) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) {
          final ref = state.uri.queryParameters['ref'];
          return RegisterScreen(refCode: ref);
        },
      ),
      GoRoute(
        path: '/email-sent',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return EmailConfirmationScreen(email: email);
        },
      ),
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

      //  Consentement RGPD (plein écran, avant onboarding — comptes Google/Apple)
      GoRoute(
        path: '/accept-terms',
        parentNavigatorKey: navigatorKey,
        builder: (_, __) => const AcceptTermsScreen(),
      ),

      //  Onboarding (plein écran, post-inscription)
      GoRoute(
        path: '/onboarding',
        parentNavigatorKey: navigatorKey,
        builder: (_, __) => const OnboardingWizard(),
      ),

      //  Shell avec bottom nav
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => MainShell(navigationShell: shell),
        branches: [
          // Branche 0  Accueil
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home',
              builder: (_, __) => const DashboardPage(),
            ),
          ]),

          // Branche 1  Programmes
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/programs',
              builder: (_, __) => const ProgramsPage(),
            ),
          ]),

          // Branche 2  Candidatures
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/applications',
              builder: (_, __) => const ApplicationsPage(),
            ),
          ]),

          // Branche 3  Messages
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/messages',
              builder: (_, state) =>
                  MessagesPage(prefillText: state.extra as String?),
            ),
          ]),

          // Branche 4  Profil
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/profile',
              builder: (_, __) => const ProfilePage(),
            ),
          ]),
        ],
      ),

      //  Routes hors shell (plein écran, sans bottom nav) 
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
          final extra = state.extra;
          if (extra is Map) {
            return NewApplicationWizard(
              program: extra['program'] as Program?,
              draftId: extra['draftId'] as String?,
              motivationLetter: extra['motivationLetter'] as String?,
            );
          }
          return NewApplicationWizard(program: extra as Program?);
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
      GoRoute(
        path: '/notifications',
        parentNavigatorKey: navigatorKey,
        builder: (_, __) => const NotificationsPage(),
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: navigatorKey,
        builder: (_, __) => const SettingsPage(),
      ),
      GoRoute(
        path: '/ambassador',
        parentNavigatorKey: navigatorKey,
        builder: (_, __) => const AmbassadorPage(),
      ),
    ],
  );
});