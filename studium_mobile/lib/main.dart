import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/app_strings.dart';
import 'router/app_router.dart';
import 'core/theme/app_theme.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );
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
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: AppStrings.appName,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
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