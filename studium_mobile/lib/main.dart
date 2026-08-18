import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/app_strings.dart';
import 'core/services/cache_service.dart';
import 'core/services/push_notification_service.dart';
import 'router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/presentation/providers/settings_providers.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );

  await CacheService.instance.init();

  // Firebase  nécessite google-services.json (Android) et GoogleService-Info.plist (iOS)
  try {
    await Firebase.initializeApp();
    await PushNotificationService.instance.initialize();
  } catch (e) {
    debugPrint('[FCM] Firebase non configuré : $e');
  }

  runApp(const ProviderScope(child: StudiumApp()));
}

class StudiumApp extends ConsumerStatefulWidget {
  const StudiumApp({super.key});
  @override
  ConsumerState<StudiumApp> createState() => _StudiumAppState();
}

class _StudiumAppState extends ConsumerState<StudiumApp> {
  late final AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();

    // Enregistrer la navigation pour les taps sur notifications push
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final router = ref.read(appRouterProvider);
      PushNotificationService.setNavigate((route) => router.go(route));
    });

    _appLinks.uriLinkStream.listen((uri) async {
      final params = uri.queryParameters;
      final fragment = uri.fragment;

      Map<String, String> fragmentParams = {};
      if (fragment.isNotEmpty) {
        fragmentParams = Uri.splitQueryString(fragment);
      }

      final token = params['token'] ?? params['code'] ??
                    fragmentParams['access_token'] ?? fragmentParams['token'];

      if (uri.scheme == 'studium' && uri.host == 'reset-password' && token != null) {
        ref.read(isResettingPasswordProvider.notifier).state = true;

        try {
          await Supabase.instance.client.auth.getSessionFromUrl(uri);
        } catch (e) {
          debugPrint('getSessionFromUrl error: $e');
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(appRouterProvider).go('/reset-password?code=$token');
        });
      }

      // Lien de parrainage ambassadeur : studium://register?ref=CODE
      if (uri.scheme == 'studium' && uri.host == 'register') {
        final refCode = params['ref'];
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(appRouterProvider).go(
            refCode != null ? '/register?ref=$refCode' : '/register',
          );
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final router    = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale    = ref.watch(localeProvider);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: AppStrings.appName,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      locale: locale,
      routerConfig: router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('fr'), Locale('en')],
    );
  }
}