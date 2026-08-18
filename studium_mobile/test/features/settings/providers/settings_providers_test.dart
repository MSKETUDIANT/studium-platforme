import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mocktail/mocktail.dart';
import 'package:studium_mobile/features/settings/presentation/providers/settings_providers.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  late MockFlutterSecureStorage storage;
  late ProviderContainer container;

  setUp(() {
    storage = MockFlutterSecureStorage();
    container = ProviderContainer(overrides: [
      secureStorageProvider.overrideWithValue(storage),
    ]);
    addTearDown(container.dispose);
  });

  group('ThemeModeNotifier', () {
    test('defaults to light and stays light when nothing is persisted', () async {
      when(() => storage.read(key: 'settings_theme')).thenAnswer((_) async => null);

      expect(container.read(themeModeProvider), ThemeMode.light);
      await _settle();

      expect(container.read(themeModeProvider), ThemeMode.light);
    });

    test('loads a persisted dark theme on build', () async {
      when(() => storage.read(key: 'settings_theme')).thenAnswer((_) async => 'dark');

      container.read(themeModeProvider);
      await _settle();

      expect(container.read(themeModeProvider), ThemeMode.dark);
    });

    test('toggle flips the theme and persists the new value', () async {
      when(() => storage.read(key: 'settings_theme')).thenAnswer((_) async => null);
      when(() => storage.write(key: 'settings_theme', value: any(named: 'value')))
          .thenAnswer((_) async {});

      container.read(themeModeProvider);
      await _settle();

      await container.read(themeModeProvider.notifier).toggle();
      expect(container.read(themeModeProvider), ThemeMode.dark);
      verify(() => storage.write(key: 'settings_theme', value: 'dark')).called(1);

      await container.read(themeModeProvider.notifier).toggle();
      expect(container.read(themeModeProvider), ThemeMode.light);
      verify(() => storage.write(key: 'settings_theme', value: 'light')).called(1);
    });
  });

  group('LocaleNotifier', () {
    test('defaults to fr and stays fr when nothing is persisted', () async {
      when(() => storage.read(key: 'settings_locale')).thenAnswer((_) async => null);

      expect(container.read(localeProvider), const Locale('fr'));
      await _settle();

      expect(container.read(localeProvider), const Locale('fr'));
    });

    test('loads a persisted english locale on build', () async {
      when(() => storage.read(key: 'settings_locale')).thenAnswer((_) async => 'en');

      container.read(localeProvider);
      await _settle();

      expect(container.read(localeProvider), const Locale('en'));
    });

    test('setLocale updates the state and persists the language code', () async {
      when(() => storage.read(key: 'settings_locale')).thenAnswer((_) async => null);
      when(() => storage.write(key: 'settings_locale', value: any(named: 'value')))
          .thenAnswer((_) async {});

      container.read(localeProvider);
      await _settle();

      await container.read(localeProvider.notifier).setLocale(const Locale('en'));

      expect(container.read(localeProvider), const Locale('en'));
      verify(() => storage.write(key: 'settings_locale', value: 'en')).called(1);
    });
  });
}
