import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Gestionnaire background (top-level, obligatoire pour FCM)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[FCM Background] ${message.notification?.title}');
}

class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  final _messaging    = FirebaseMessaging.instance;
  final _localNotifs  = FlutterLocalNotificationsPlugin();

  // Canal Android haute priorité
  static const _channel = AndroidNotificationChannel(
    'studium_high',
    'Studium Notifications',
    description: 'Candidatures, messages et alertes Studium',
    importance: Importance.max,
  );

  Future<void> initialize() async {
    // Gestionnaire background
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Notifications locales (foreground Android)
    await _localNotifs.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS:     DarwinInitializationSettings(),
      ),
    );

    await _localNotifs
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Demander permission iOS / Android 13+
    final settings = await _messaging.requestPermission(
      alert: true, badge: true, sound: true,
    );
    debugPrint('[FCM] Permission: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      await _registerToken();
    }

    // Foreground : afficher la notif localement
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // Tap sur notif quand app en background
    FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationTap);
  }

  //  Token 

  Future<void> _registerToken() async {
    final token = await _messaging.getToken();
    if (token == null) return;
    await _upsertToken(token);

    // Renouvellement automatique du token
    _messaging.onTokenRefresh.listen(_upsertToken);
  }

  Future<void> _upsertToken(String token) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final platform = Platform.isIOS ? 'ios' : 'android';

    await Supabase.instance.client.from('fcm_tokens').upsert({
      'user_id':    userId,
      'token':      token,
      'platform':   platform,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id, token');

    debugPrint('[FCM] Token enregistré ($platform)');
  }

  // Supprimer le token à la déconnexion
  Future<void> removeToken() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    final token = await _messaging.getToken();
    if (token == null) return;

    await Supabase.instance.client
        .from('fcm_tokens')
        .delete()
        .eq('user_id', userId)
        .eq('token', token);

    await _messaging.deleteToken();
  }

  //  Handlers 

  void _onForegroundMessage(RemoteMessage message) {
    final notif = message.notification;
    if (notif == null) return;

    _localNotifs.show(
      notif.hashCode,
      notif.title,
      notif.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
      ),
    );
  }

  void _onNotificationTap(RemoteMessage message) {
    debugPrint('[FCM] Tap notif: ${message.data}');
    // Navigation selon message.data['type'] à implémenter selon le routeur
  }
}
