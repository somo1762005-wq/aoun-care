import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const String _defaultIcon = '@mipmap/launcher_icon';
  static const String _alertsChannelId = 'aoun_channel';
  static const String _alarmChannelId = 'alarm_channel_high_priority';
  static const String _alarmMethodChannel = 'com.aoun.app/alarm';

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static const MethodChannel _alarmChannel = MethodChannel(_alarmMethodChannel);

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        await requestPermissions();

        const AndroidInitializationSettings androidSettings =
            AndroidInitializationSettings(_defaultIcon);
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

        final androidPlugin = _localNotifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

        const AndroidNotificationChannel alertsChannel = AndroidNotificationChannel(
          _alertsChannelId,
          'Aoun Alerts',
          description: 'Notifications for medicine doses and tracking alerts',
          importance: Importance.max,
          playSound: true,
        );

        const AndroidNotificationChannel alarmChannel = AndroidNotificationChannel(
          _alarmChannelId,
          'Aoun Alarm Alerts',
          description: 'High-priority medicine alarm notifications',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        );

        await androidPlugin?.createNotificationChannel(alertsChannel);
        await androidPlugin?.createNotificationChannel(alarmChannel);

        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          debugPrint("Foreground message received: ${message.notification?.title}");
          _showLocalNotification(message);
        });

        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          debugPrint("Notification opened app: ${message.notification?.title}");
        });

        _isInitialized = true;
        debugPrint("NotificationService initialized successfully!");
      } catch (e, stack) {
        debugPrint("NotificationService initialization error: $e\n$stack");
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

    if (notification != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _alertsChannelId,
            'Aoun Alerts',
            channelDescription: 'Notifications for medicine doses and tracking alerts',
            importance: Importance.max,
            priority: Priority.high,
            icon: _defaultIcon,
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

  Future<void> showAlarmNotification({
    required String title,
    required String body,
    required String tone,
    required bool vibration,
  }) async {
    final String? soundResource = tone == 'default' ? null : tone;

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _alarmChannelId,
      'Aoun Alarm Alerts',
      channelDescription: 'High-priority medicine alarm notifications',
      importance: Importance.max,
      priority: Priority.high,
      icon: _defaultIcon,
      sound: soundResource != null ? RawResourceAndroidNotificationSound(soundResource) : null,
      playSound: true,
      enableVibration: vibration,
      vibrationPattern: vibration ? Int64List.fromList([0, 1000, 500, 1000]) : null,
      ongoing: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      audioAttributesUsage: AudioAttributesUsage.alarm,
    );

    await _localNotifications.show(
      999,
      title,
      body,
      NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.critical,
        ),
      ),
    );
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

  Future<void> startAlarmForegroundService({
    required String title,
    required String body,
    required String tone,
    required bool vibration,
  }) async {
    if (!Platform.isAndroid) return;
    
    try {
      await _alarmChannel.invokeMethod('startAlarm', {
        'title': title,
        'body': body,
        'tone': tone,
        'vibration': vibration,
      });
      debugPrint("Alarm foreground service started");
    } catch (e) {
      debugPrint("Error starting alarm foreground service: $e");
    }
  }

  Future<void> stopAlarmForegroundService() async {
    if (!Platform.isAndroid) return;
    
    try {
      await _alarmChannel.invokeMethod('stopAlarm');
      debugPrint("Alarm foreground service stopped");
    } catch (e) {
      debugPrint("Error stopping alarm foreground service: $e");
    }
  }
}
