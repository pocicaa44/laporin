import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';

import '../../data/models/notification_model.dart';
import '../../data/services/supabase_service.dart';
import '../../features/announcements/screens/announcements_screen.dart';
import '../../features/auth/controllers/auth_controller.dart';
import '../../features/notifications/controllers/notification_controller.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/report_detail/screens/report_detail_screen.dart';
import '../../features/settings/controllers/settings_controller.dart';

/// Top-level background message handler sesuai standar Firebase Messaging
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  } catch (_) {}
  debugPrint('FCM background message: ${message.messageId}');
}

/// Service untuk menangani Firebase Cloud Messaging (FCM), permission,
/// token lifecycle, dan navigasi saat notifikasi dibuka.
class FcmService {
  FcmService._internal();

  static final FcmService instance = FcmService._internal();

  /// Global navigator key agar notifikasi dapat membuka halaman dari mana saja
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Plugin untuk menampilkan notifikasi pop-up sistem di Android (Heads-Up Notification)
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Android notification channel dengan Importance.max agar sistem Android menampilkan pop-up banner
  static const AndroidNotificationChannel androidNotificationChannel =
      AndroidNotificationChannel(
        'laporin_channel',
        'Notifikasi Laporin',
        description:
            'Pemberitahuan pembaruan status laporan dan pengumuman warga.',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

  FirebaseMessaging? _messagingInstance;
  FirebaseMessaging? get _messaging {
    if (_messagingInstance != null) return _messagingInstance;
    try {
      if (Firebase.apps.isNotEmpty) {
        _messagingInstance = FirebaseMessaging.instance;
      }
    } catch (_) {}
    return _messagingInstance;
  }

  /// Setter untuk unit testing
  void setMessagingForTesting(FirebaseMessaging? messaging) {
    _messagingInstance = messaging;
  }

  bool _isInitialized = false;
  String? _lastToken;
  RemoteMessage? _pendingInitialMessage;

  String? get lastToken => _lastToken;

  /// Inisialisasi service FCM dan listener
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (Firebase.apps.isEmpty) {
        debugPrint('FcmService: Firebase apps belum diinisialisasi.');
        return;
      }

      final messaging = _messaging;
      if (messaging == null) return;

      // Inisialisasi plugin notifikasi lokal agar sistem Android dapat memunculkan pop-up
      try {
        const AndroidInitializationSettings initializationSettingsAndroid =
            AndroidInitializationSettings('@mipmap/ic_launcher');
        const DarwinInitializationSettings initializationSettingsDarwin =
            DarwinInitializationSettings();
        const InitializationSettings initializationSettings =
            InitializationSettings(
              android: initializationSettingsAndroid,
              iOS: initializationSettingsDarwin,
            );

        await _localNotifications.initialize(
          settings: initializationSettings,
          onDidReceiveNotificationResponse: (NotificationResponse response) {
            final payload = response.payload;
            if (payload != null && payload.isNotEmpty) {
              try {
                final data = jsonDecode(payload) as Map<String, dynamic>;
                handlePayloadNavigation(data);
              } catch (_) {}
            }
          },
        );

        // Buat notification channel dengan Importance.max di sistem Android
        await _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.createNotificationChannel(androidNotificationChannel);
      } catch (e) {
        debugPrint('FcmService local notifications init notice: $e');
      }

      // 1. Daftarkan background message handler tingkat atas
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 2. Minta izin notifikasi (Android 13+ & iOS)
      await requestPermission();

      // 3. Konfigurasi opsi presentasi foreground
      try {
        await messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      } catch (_) {}

      // 4. Daftarkan listener notifikasi saat aplikasi aktif (foreground)
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // 5. Daftarkan listener saat notifikasi ditekan dari background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationClick);

      // 6. Tangani pembaruan token FCM via onRegistered stream
      messaging.onRegistered.listen((newToken) {
        _lastToken = newToken;
        syncTokenWithSupabase();
      });
      try {
        await messaging.register();
      } catch (_) {}

      // 7. Periksa apakah aplikasi dibuka dari kondisi terminated oleh notifikasi
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        _pendingInitialMessage = initialMessage;
      }

      _isInitialized = true;

      // 8. Sinkronisasi token awal jika user sudah login
      await syncTokenWithSupabase();
    } catch (e) {
      debugPrint('FcmService initialize notice: $e');
    }
  }

  /// Minta izin notifikasi secara aman
  Future<NotificationSettings?> requestPermission() async {
    try {
      final messaging = _messaging;
      if (messaging == null) return null;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      return settings;
    } catch (e) {
      debugPrint('FcmService requestPermission notice: $e');
      return null;
    }
  }

  /// Ambil token perangkat FCM saat ini
  Future<String?> getToken() async {
    try {
      if (_lastToken != null && _lastToken!.isNotEmpty) {
        return _lastToken;
      }
      final messaging = _messaging;
      if (messaging == null) return null;
      try {
        await messaging.register();
      } catch (_) {}
      if (_lastToken != null && _lastToken!.isNotEmpty) {
        return _lastToken;
      }
      // ignore: deprecated_member_use
      final token = await messaging.getToken();
      if (token != null && token.isNotEmpty) {
        _lastToken = token;
      }
      return token;
    } catch (e) {
      debugPrint('FcmService getToken notice: $e');
      return null;
    }
  }

  /// Sinkronisasi token perangkat ke database Supabase
  Future<void> syncTokenWithSupabase() async {
    try {
      final client = SupabaseService.instance.client;
      if (client == null || client.auth.currentUser == null) {
        return;
      }

      final token = _lastToken ?? await getToken();
      if (token == null || token.isEmpty) {
        return;
      }

      final platformName = kIsWeb
          ? 'web'
          : defaultTargetPlatform.name.toLowerCase();

      await client.rpc(
        'upsert_device_token',
        params: {'p_token': token, 'p_platform': platformName},
      );
    } catch (e) {
      debugPrint('FcmService syncTokenWithSupabase notice: $e');
    }
  }

  /// Hapus asosiasi token dari Supabase saat logout
  Future<void> removeTokenFromSupabase() async {
    try {
      final client = SupabaseService.instance.client;
      final token = _lastToken ?? await getToken();

      if (client != null && token != null && token.isNotEmpty) {
        await client.rpc('delete_device_token', params: {'p_token': token});
      }
      _lastToken = null;
    } catch (e) {
      debugPrint('FcmService removeTokenFromSupabase notice: $e');
    }
  }

  /// Proses notifikasi yang membuka aplikasi saat terminated (cold start)
  void consumePendingInitialMessage() {
    if (_pendingInitialMessage != null) {
      final message = _pendingInitialMessage!;
      _pendingInitialMessage = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleNotificationClick(message);
      });
    }
  }

  /// Penanganan notifikasi saat aplikasi berada di latar depan (foreground)
  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    final title =
        notification?.title ??
        (message.data['title'] as String?) ??
        'Notifikasi Baru';
    final body = notification?.body ?? (message.data['body'] as String?) ?? '';
    final typeStr = (message.data['type'] as String?) ??
        (message.data['notification_type'] as String?);
    final notifType = NotificationType.fromString(typeStr);

    final context = navigatorKey.currentContext;
    bool isAllowedBySettings = true;

    if (context != null) {
      // 1. Refresh otomatis riwayat notifikasi in-app dan unread badge counter
      try {
        final notifController = Provider.of<NotificationController>(
          context,
          listen: false,
        );
        notifController.fetchNotifications();
      } catch (_) {}

      // 2. Evaluasi apakah jenis notifikasi ini diizinkan di SettingsScreen
      try {
        final settings = Provider.of<SettingsController>(
          context,
          listen: false,
        );
        final auth = Provider.of<AuthController?>(context, listen: false);
        final isAdmin = auth?.isAdmin ?? false;
        isAllowedBySettings = settings.isNotificationAllowed(
          notifType,
          isAdmin: isAdmin,
        );
      } catch (_) {}
    }

    // 3. Tampilkan notifikasi pop-up sistem di Android (Heads-Up Banner) hanya jika diizinkan oleh pengaturan
    if (isAllowedBySettings && (title.isNotEmpty || body.isNotEmpty)) {
      final notificationId =
          message.messageId?.hashCode ??
          DateTime.now().millisecondsSinceEpoch.remainder(100000);

      _localNotifications.show(
        id: notificationId,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'laporin_channel',
            'Notifikasi Laporin',
            channelDescription:
                'Pemberitahuan pembaruan status laporan dan pengumuman warga.',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            playSound: true,
            enableVibration: true,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }

  /// Helper untuk pengujian unit & widget
  @visibleForTesting
  void handleForegroundMessageForTesting(RemoteMessage message) {
    _handleForegroundMessage(message);
  }

  /// Penanganan saat pengguna menekan notifikasi (background / terminated / foreground)
  void _handleNotificationClick(RemoteMessage message) {
    handlePayloadNavigation(message.data);
  }

  /// Routing navigasi berdasarkan data payload notifikasi
  void handlePayloadNavigation(Map<String, dynamic> data) {
    if (data.isEmpty) return;

    final type = data['type'] as String?;
    final reportId = data['report_id'] as String?;
    final announcementId = data['announcement_id'] as String?;

    final navState = navigatorKey.currentState;
    if (navState == null) return;

    if (type == 'report_status_changed' ||
        type == 'new_comment' ||
        type == 'reply_comment' ||
        type == 'report_upvoted' ||
        type == 'new_report' ||
        type == 'new_report_created' ||
        (reportId != null && reportId.isNotEmpty)) {
      if (reportId != null && reportId.isNotEmpty) {
        navState.push(
          MaterialPageRoute(
            builder: (_) => ReportDetailScreen(reportId: reportId),
          ),
        );
      }
    } else if (type == 'announcement_published' ||
        type == 'announcement' ||
        (announcementId != null && announcementId.isNotEmpty)) {
      navState.push(
        MaterialPageRoute(builder: (_) => const AnnouncementsScreen()),
      );
    } else {
      navState.push(
        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
      );
    }
  }
}
