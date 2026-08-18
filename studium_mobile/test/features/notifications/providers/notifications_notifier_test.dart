import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:studium_mobile/features/notifications/data/datasources/notifications_remote_datasource.dart';
import 'package:studium_mobile/features/notifications/domain/entities/app_notification.dart';
import 'package:studium_mobile/features/notifications/presentation/providers/notifications_providers.dart';
import 'package:studium_mobile/features/profile/presentation/providers/profile_providers.dart';

class MockNotificationsRemoteDatasource extends Mock implements NotificationsRemoteDatasource {}

AppNotification _notification({String id = 'n1', DateTime? readAt}) => AppNotification(
      id: id,
      type: 'application_status',
      title: 'Titre',
      payload: const {},
      readAt: readAt,
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  late MockNotificationsRemoteDatasource datasource;
  late ProviderContainer container;

  setUp(() {
    datasource = MockNotificationsRemoteDatasource();
    container = ProviderContainer(overrides: [
      notificationsDatasourceProvider.overrideWithValue(datasource),
      currentUserIdProvider.overrideWithValue('u1'),
    ]);
    addTearDown(container.dispose);
  });

  test('build returns an empty list when there is no current user', () async {
    final noUserContainer = ProviderContainer(overrides: [
      notificationsDatasourceProvider.overrideWithValue(datasource),
      currentUserIdProvider.overrideWithValue(null),
    ]);
    addTearDown(noUserContainer.dispose);

    final result = await noUserContainer.read(notificationsProvider.future);

    expect(result, isEmpty);
    verifyNever(() => datasource.fetchAll(any()));
  });

  test('build fetches all notifications for the current user', () async {
    when(() => datasource.fetchAll('u1')).thenAnswer((_) async => [_notification()]);

    final result = await container.read(notificationsProvider.future);

    expect(result, hasLength(1));
    verify(() => datasource.fetchAll('u1')).called(1);
  });

  test('markRead patches the target notification locally without refetching', () async {
    when(() => datasource.fetchAll('u1')).thenAnswer((_) async => [_notification(id: 'n1'), _notification(id: 'n2')]);
    when(() => datasource.markAsRead('n1')).thenAnswer((_) async {});

    await container.read(notificationsProvider.future);
    await container.read(notificationsProvider.notifier).markRead('n1');

    final state = container.read(notificationsProvider).valueOrNull!;
    expect(state.firstWhere((n) => n.id == 'n1').isRead, isTrue);
    expect(state.firstWhere((n) => n.id == 'n2').isRead, isFalse);
    verify(() => datasource.markAsRead('n1')).called(1);
    // Local patch, not a refetch.
    verify(() => datasource.fetchAll('u1')).called(1);
  });

  test('markAllRead patches every notification locally', () async {
    when(() => datasource.fetchAll('u1')).thenAnswer((_) async => [_notification(id: 'n1'), _notification(id: 'n2')]);
    when(() => datasource.markAllAsRead('u1')).thenAnswer((_) async {});

    await container.read(notificationsProvider.future);
    await container.read(notificationsProvider.notifier).markAllRead();

    final state = container.read(notificationsProvider).valueOrNull!;
    expect(state.every((n) => n.isRead), isTrue);
    verify(() => datasource.markAllAsRead('u1')).called(1);
    verify(() => datasource.fetchAll('u1')).called(1);
  });
}
