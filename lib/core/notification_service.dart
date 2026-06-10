import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        // Request permissions
        await requestPermissions();

        // Local notifications setup
        const AndroidInitializationSettings androidSettings =
            AndroidInitializationSettings('@mipmap/ic_launcher');
        const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );

        const InitializationSettings initSettings = InitializationSettings(
          android: androidSettings,
          iOS: iosSettings,
        );

        await _localNotifications.initialize(
          initSettings,
          onDidReceiveNotificationResponse: (details) {
            debugPrint("Notification clicked: ${details.payload}");
          },
        );

        // Create android notification channel
        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          'aoun_channel', // id
          'Aoun Alerts', // title
          description: 'Notifications for medicine doses and tracking alerts',
          importance: Importance.max,
          playSound: true,
        );

        await _localNotifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);

        // FCM foreground listener
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          debugPrint("Foreground message received: ${message.notification?.title}");
          _showLocalNotification(message);
        });

        // FCM background click listener
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          debugPrint("Notification opened app: ${message.notification?.title}");
        });

        _isInitialized = true;
        debugPrint("NotificationService initialized successfully!");
      } catch (e) {
        debugPrint("NotificationService initialization error: $e");
      }
    }
  }

  Future<void> requestPermissions() async {
    try {
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      debugPrint("FCM Authorization status: ${settings.authorizationStatus}");
    } catch (e) {
      debugPrint("Error requesting notification permissions: $e");
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'aoun_channel',
            'Aoun Alerts',
            channelDescription: 'Notifications for medicine doses and tracking alerts',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data.toString(),
      );
    }
  }

  Future<void> uploadFcmToken() async {
    try {
      if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;

      String? token = await _fcm.getToken();
      if (token != null) {
        debugPrint("FCM Token: $token");
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'fcmToken': token,
            'lastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          debugPrint("FCM Token uploaded to Firestore for user: ${user.uid}");
        }
      }
    } catch (e) {
      debugPrint("Error uploading FCM token: $e");
    }
  }
}
