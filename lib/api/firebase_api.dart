import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FirebaseApi {
  static final FirebaseApi _instance = FirebaseApi._internal();
  factory FirebaseApi() => _instance;
  FirebaseApi._internal();
  static FirebaseApi get instance => _instance;

  final _firebaseMessaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();
  final _notificationStreamController =
      StreamController<RemoteMessage>.broadcast();

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    importance: Importance.high,
    description: 'This channel is used for important notifications',
  );
  final ValueNotifier<int> notificationCount = ValueNotifier<int>(0);
  final List<RemoteMessage> _notifications = [];

  void incrementCounter() {
    notificationCount.value++;
  }

  void resetNotificationCounter() {
    notificationCount.value = 0;
    _notifications.clear();
  }

  Stream<RemoteMessage> get notificationStream =>
      _notificationStreamController.stream;
  bool _isAppInForeground = true;

  Future<void> initialize() async {
    await _setupNotifications();
    _setupAppLifecycle();
    initializeNotificationCount(); // mets à jour le compteur au démarrage
  }

  void _setupAppLifecycle() {
    WidgetsBinding.instance.addObserver(
      LifecycleObserver(
        onResume: () => _isAppInForeground = true,
        onPause: () => _isAppInForeground = false,
      ),
    );
  }

  Future<void> _setupNotifications() async {
    await _initFirebaseMessaging();
    await _initLocalNotifications();
    _setupHandlers();
  }

  Future<void> _initFirebaseMessaging() async {
    await _firebaseMessaging.requestPermission();
    final token = await _firebaseMessaging.getToken();
    if (kDebugMode) print('FCM Token: $token');
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> _initLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _localNotifications.initialize(
      const InitializationSettings(android: android),
      onDidReceiveNotificationResponse: _onNotificationClicked,
    );

    final androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_androidChannel);
  }

  void _setupHandlers() {
    FirebaseMessaging.onMessage.listen((message) {
      showNotification(message); // Affiche en local
      _notificationStreamController.add(message); // Sauvegarde
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _notificationStreamController.add(message); // Navigation ou sauvegarde
    });

    FirebaseMessaging.onBackgroundMessage(backgroundHandler);
  }

  static Future<void> backgroundHandler(RemoteMessage message) async {
    if (kDebugMode) {
      print('Background message: ${message.notification?.title}');
      print('Payload: ${message.data}');
    }
  }

  Future<void> showNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final android = AndroidNotificationDetails(
      _androidChannel.id,
      _androidChannel.name,
      channelDescription: _androidChannel.description,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    await _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(android: android),
      payload: message.data.toString(),
    );
  }

  void _onNotificationClicked(NotificationResponse response) {
    if (response.payload != null) {
      // Ici, tu pourrais convertir le payload et naviguer
      // Exemple : final data = jsonDecode(response.payload!);
    }
  }

  void addLocalNotification({
    required String title,
    required String body,
    required Map<String, String> data,
  }) {
    final message = RemoteMessage(
      notification: RemoteNotification(title: title, body: body),
      data: data,
      sentTime: DateTime.now(),
      messageId: DateTime.now().millisecondsSinceEpoch.toString(),
    );

    // Afficher la notification localement
    showNotification(message);

    // Ne pas ajouter au stream si l'app est en foreground
    if (!_isAppInForeground) {
      _notificationStreamController.add(message);
    }
  }

  // Appelle ça dans le onMessage Firebase
  void handleIncomingNotification(RemoteMessage message) {
    _notifications.add(message);
    incrementCounter();
    _notificationStreamController.add(message);
  }

  void initializeNotificationCount() {
    notificationCount.value = _notifications.length;
  }
}

class LifecycleObserver extends WidgetsBindingObserver {
  final VoidCallback onResume;
  final VoidCallback onPause;

  LifecycleObserver({required this.onResume, required this.onPause});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResume();
    } else if (state == AppLifecycleState.paused) {
      onPause();
    }
  }
}
