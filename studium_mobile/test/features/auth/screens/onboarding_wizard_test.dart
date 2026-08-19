import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:studium_mobile/features/auth/presentation/screens/onboarding_wizard.dart';
import 'package:studium_mobile/features/settings/presentation/providers/settings_providers.dart';

// `_saveDraft()` (triggered on every step transition) touches
// `Supabase.instance.client` unguarded by try/catch. It safely no-ops as
// soon as `client.auth.currentUser` is null, but `Supabase.instance` itself
// throws unless the SDK has been initialized at least once — so a minimal,
// unauthenticated init (no real network calls) is required for these tests.
Future<void> _ensureSupabaseInitialized() async {
  SharedPreferences.setMockInitialValues({});
  await Supabase.initialize(
    url: 'http://127.0.0.1:1',
    anonKey: 'test-anon-key',
    // Disabled: GoTrue's periodic auto-refresh timer would otherwise outlive
    // the widget tree and fail flutter_test's "no pending timers" check.
    authOptions: const FlutterAuthClientOptions(autoRefreshToken: false),
  );
}

Future<void> _pumpWizard(WidgetTester tester) async {
  await _ensureSupabaseInitialized();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        motivationMinWordsProvider.overrideWith((ref) async => 300),
      ],
      child: const MaterialApp(home: OnboardingWizard()),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tapText(WidgetTester tester, String text) async {
  final finder = find.text(text);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _enterTextByHint(WidgetTester tester, String hint, String value) async {
  final finder = find.widgetWithText(TextField, hint);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.enterText(finder, value);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('opens on the welcome step', (tester) async {
    await _pumpWizard(tester);

    expect(find.text('Bienvenue\nsur Studium'), findsOneWidget);
    expect(find.text('Commencer'), findsOneWidget);
  });

  testWidgets('tapping Continuer with empty identity fields shows Requis on both fields '
      'and stays on the identity step', (tester) async {
    await _pumpWizard(tester);

    await _tapText(tester, 'Commencer');
    expect(find.text('Votre identité'), findsOneWidget);

    await _tapText(tester, 'Continuer');

    expect(find.text('Requis'), findsNWidgets(2));
    // Still on the identity step, not advanced to motivation.
    expect(find.text('Votre identité'), findsOneWidget);
    expect(find.text('Modèle de lettre de motivation'), findsNothing);
  });

  testWidgets('filling first/last name and tapping Continuer advances to the motivation step',
      (tester) async {
    await _pumpWizard(tester);

    await _tapText(tester, 'Commencer');
    await _enterTextByHint(tester, 'Mohammed', 'Aly');
    await _enterTextByHint(tester, 'Sansy', 'Syla');
    await _tapText(tester, 'Continuer');

    expect(find.text('Modèle de lettre de motivation'), findsOneWidget);
    expect(find.text('Passer cette étape'), findsOneWidget);
  });

  testWidgets('tapping "Passer cette étape" on the motivation step advances to the recap step',
      (tester) async {
    await _pumpWizard(tester);

    await _tapText(tester, 'Commencer');
    await _enterTextByHint(tester, 'Mohammed', 'Aly');
    await _enterTextByHint(tester, 'Sansy', 'Syla');
    await _tapText(tester, 'Continuer');

    await _tapText(tester, 'Passer cette étape');

    // Left the motivation step behind.
    expect(find.text('Modèle de lettre de motivation'), findsNothing);
  });
}
