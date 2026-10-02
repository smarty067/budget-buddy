import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';

/// Service for managing local notifications, requesting permissions,
/// and sending alerts for budget reminders, loan calculations, and investments.
class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'budget_buddy_alerts';
  static const String _channelName = 'Budget Buddy Alerts';
  static const String _channelDesc =
      'Important budget updates, daily expense reminders, and financial milestone alerts.';

  static const String _settingsBoxName = 'settings_box';
  static const String _keyNotificationsEnabled = 'notifications_enabled';

  /// Initialize local notification plugin and default channels.
  static Future<void> initialize() async {
    try {
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('[NotificationService] Notification tapped: ${response.payload}');
        },
      );

      // Create Android Notification Channel
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDesc,
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          ),
        );
      }
    } catch (e) {
      debugPrint('[NotificationService] Initialization error: $e');
    }
  }

  /// Request notification permissions (Android 13+ and iOS).
  static Future<bool> requestPermission() async {
    try {
      bool granted = false;

      // Android 13+ (API 33+)
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final bool? androidGranted =
            await androidPlugin.requestNotificationsPermission();
        granted = androidGranted ?? false;
      }

      // iOS
      final iosPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      if (iosPlugin != null) {
        final bool? iosGranted = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        granted = iosGranted ?? false;
      }

      final box = Hive.isBoxOpen(_settingsBoxName)
          ? Hive.box(_settingsBoxName)
          : await Hive.openBox(_settingsBoxName);
      await box.put(_keyNotificationsEnabled, granted);

      if (granted) {
        await showWelcomeNotification();
      }

      return granted;
    } catch (e) {
      debugPrint('[NotificationService] Error requesting permission: $e');
      return false;
    }
  }

  /// Check if notifications are enabled in settings.
  static bool get areNotificationsEnabled {
    try {
      if (Hive.isBoxOpen(_settingsBoxName)) {
        return Hive.box(_settingsBoxName)
            .get(_keyNotificationsEnabled, defaultValue: true) as bool;
      }
    } catch (_) {}
    return true;
  }

  /// Set notification enabled state in settings.
  static Future<void> setNotificationsEnabled(bool enabled) async {
    try {
      final box = Hive.isBoxOpen(_settingsBoxName)
          ? Hive.box(_settingsBoxName)
          : await Hive.openBox(_settingsBoxName);
      await box.put(_keyNotificationsEnabled, enabled);
      if (enabled) {
        await requestPermission();
      }
    } catch (_) {}
  }

  /// Send an immediate notification to the user.
  static Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!areNotificationsEnabled) return;

    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await _notificationsPlugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: platformDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint('[NotificationService] Error displaying notification: $e');
    }
  }

  /// Notification when notifications are first enabled.
  static Future<void> showWelcomeNotification() async {
    await showNotification(
      title: '🔔 Notifications Activated!',
      body:
          'Budget Buddy will keep you updated with smart budget tracking and loan payment reminders.',
    );
  }

  /// Notification when a loan calculation is saved.
  static Future<void> showLoanSavedAlert({
    required String title,
    required double monthlyEmi,
  }) async {
    await showNotification(
      title: '💼 Loan Calculation Saved',
      body: 'Successfully saved $title. Monthly EMI: ₹${monthlyEmi.round()}/mo.',
    );
  }

  /// Notification when a new investment/asset is added.
  static Future<void> showInvestmentSavedAlert({
    required String name,
    required double amount,
  }) async {
    await showNotification(
      title: '📈 Portfolio Asset Recorded',
      body: '$name (₹${amount.round()}) has been added to your Wealth Hub.',
    );
  }
}
