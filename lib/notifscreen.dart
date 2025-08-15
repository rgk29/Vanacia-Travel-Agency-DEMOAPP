import 'dart:async';
import 'dart:convert';

import 'package:agencedevoyage/api/firebase_api.dart';
import 'package:agencedevoyage/resumer.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalNotification {
  final String? title;
  final String? body;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  LocalNotification({
    required this.title,
    required this.body,
    required this.timestamp,
    required this.data,
  });

  factory LocalNotification.fromRemoteMessage(RemoteMessage msg) {
    final title = msg.notification?.title ?? msg.data['title'];
    final body = msg.notification?.body ?? msg.data['body'];

    return LocalNotification(
      title: title,
      body: body,
      timestamp: msg.sentTime ?? DateTime.now(),
      data: msg.data,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'body': body,
        'timestamp': timestamp.toIso8601String(),
        'data': data,
      };

  factory LocalNotification.fromJson(Map<String, dynamic> json) {
    return LocalNotification(
      title: json['title'],
      body: json['body'],
      timestamp: DateTime.parse(json['timestamp']),
      data: Map<String, dynamic>.from(json['data']),
    );
  }
}

class NotificationsScreen extends StatefulWidget {
  static const String route = '/notifications';

  const NotificationsScreen({super.key});

  @override
  NotificationsScreenState createState() => NotificationsScreenState();
}

class NotificationsScreenState extends State<NotificationsScreen> {
  final List<LocalNotification> _notifications = [];
  late StreamSubscription _subscription;

  static const _storageKey = 'saved_notifications';

  @override
  void initState() {
    super.initState();

    FirebaseApi.instance.resetNotificationCounter();

    // ⬇️ Charge les anciennes notifications sauvegardées
    _loadSavedNotifications();

    // ⬇️ Écoute les nouvelles notifications entrantes
    _subscription = FirebaseApi.instance.notificationStream.listen((message) {
      if (kDebugMode) {
        print(
            'Notification reçue dans NotificationsScreen: ${message.notification?.title}');
        print('Contenu data: ${message.data}');
      }

      final notif = LocalNotification.fromRemoteMessage(message);
      _addNotification(notif);
    });

    // ⬇️ Charge la notification si l'app a été lancée via une notification
    _loadInitialNotifications();
  }

  Future<void> _loadInitialNotifications() async {
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      final notif = LocalNotification.fromRemoteMessage(initialMessage);

      // Ne pas ajouter si la notification est vide
      final isEmpty = (notif.title == null || notif.title!.trim().isEmpty) &&
          (notif.body == null || notif.body!.trim().isEmpty);
      if (!isEmpty) {
        _addNotification(notif);
      }
    }
  }

  Future<void> _loadSavedNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getStringList(_storageKey) ?? [];

    final savedNotifications = <LocalNotification>[];
    for (final e in savedData) {
      try {
        final decoded = json.decode(e);
        savedNotifications.add(LocalNotification.fromJson(decoded));
      } catch (ex) {
        if (kDebugMode) print('Erreur de décodage: $ex');
      }
    }

    if (!mounted) return;
    setState(() {
      _notifications
        ..clear()
        ..addAll(savedNotifications.reversed);
    });
  }

  Future<void> _saveNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final data =
        _notifications.reversed.map((n) => json.encode(n.toJson())).toList();
    await prefs.setStringList(_storageKey, data);
  }

  void _addNotification(LocalNotification notif) {
    if (!mounted) return;

    final isEmpty = (notif.title == null || notif.title!.trim().isEmpty) &&
        (notif.body == null || notif.body!.trim().isEmpty);

    if (kDebugMode) {
      print("Ajout d'une notif: $notif - Vide: $isEmpty");
    }

    if (isEmpty) return;

    setState(() {
      _notifications.insert(0, notif);
    });
    _saveNotifications();
  }

  void _removeNotification(int index) {
    setState(() {
      _notifications.removeAt(index);
    });
    _saveNotifications();
  }

  void _clearAllNotifications() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Supprimer_tout'.tr()),
        content: Text('Voulez_vous_supprimer_toutes_les_notifications'.tr()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Annuler'.tr())),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Confirmer'.tr())),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _notifications.clear());
      _saveNotifications();
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'.tr()),
        centerTitle: true,
        actions: [
          if (_notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_forever),
              tooltip: 'Tout_supprimer'.tr(),
              onPressed: _clearAllNotifications,
            ),
        ],
      ),
      body: _notifications.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadSavedNotifications,
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: _notifications.length,
                itemBuilder: (context, index) => Dismissible(
                  key: Key(_notifications[index].timestamp.toIso8601String()),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    color: Colors.redAccent,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => _removeNotification(index),
                  child: _buildNotificationCard(_notifications[index]),
                ),
                separatorBuilder: (_, __) => const SizedBox(height: 10),
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_rounded,
              size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('Aucune_notification'.tr(),
              style: TextStyle(fontSize: 16, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(LocalNotification notif) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: Icon(Icons.notifications_active, color: Colors.blue),
        ),
        title: Text(
          notif.title ?? 'Sans titre',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(notif.body ?? 'Pas de contenu'),
            const SizedBox(height: 8),
            Text(
              DateFormat('dd MMM yyyy – HH:mm').format(notif.timestamp),
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
        onTap: () => _handleNotificationTap(notif),
      ),
    );
  }

  void _handleNotificationTap(LocalNotification notif) {
    if (notif.data['type'] == 'reservation') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MesReservationsPage()),
      );
    }
  }
}
