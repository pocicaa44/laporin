import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/models/notification_model.dart';

/// Controller to manage application settings including theme mode and notification preferences.
class SettingsController extends ChangeNotifier {
  SettingsController() {
    loadSettings();
  }

  static const String keyThemeMode = 'pref_theme_mode';
  static const String keyNotificationsEnabled = 'pref_notifications_enabled';
  static const String keyNotifyAnnouncements = 'pref_notify_announcements';
  static const String keyNotifyStatusChanges = 'pref_notify_status_changes';
  static const String keyNotifySupports = 'pref_notify_supports';
  static const String keyNotifyComments = 'pref_notify_comments';
  static const String keyNotifyNewReports = 'pref_notify_new_reports';
  static const String keyNotifyReplies = 'pref_notify_replies';

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  bool _notificationsEnabled = true;
  bool get notificationsEnabled => _notificationsEnabled;

  bool _notifyAnnouncements = true;
  bool get notifyAnnouncements => _notifyAnnouncements;

  bool _notifyStatusChanges = true;
  bool get notifyStatusChanges => _notifyStatusChanges;

  bool _notifySupports = true;
  bool get notifySupports => _notifySupports;

  bool _notifyComments = true;
  bool get notifyComments => _notifyComments;

  bool _notifyNewReports = true;
  bool get notifyNewReports => _notifyNewReports;

  bool _notifyReplies = true;
  bool get notifyReplies => _notifyReplies;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Load settings from SharedPreferences
  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();

      // Theme mode
      final themeStr = prefs.getString(keyThemeMode);
      if (themeStr == 'light') {
        _themeMode = ThemeMode.light;
      } else if (themeStr == 'dark') {
        _themeMode = ThemeMode.dark;
      } else {
        _themeMode = ThemeMode.system;
      }

      // Notification preferences
      _notificationsEnabled = prefs.getBool(keyNotificationsEnabled) ?? true;
      _notifyAnnouncements = prefs.getBool(keyNotifyAnnouncements) ?? true;
      _notifyStatusChanges = prefs.getBool(keyNotifyStatusChanges) ?? true;
      _notifySupports = prefs.getBool(keyNotifySupports) ?? true;
      _notifyComments = prefs.getBool(keyNotifyComments) ?? true;
      _notifyNewReports = prefs.getBool(keyNotifyNewReports) ?? true;
      _notifyReplies = prefs.getBool(keyNotifyReplies) ?? true;
    } catch (_) {
      // Graceful fallback to default values
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Change theme mode and persist preference
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      String themeStr;
      switch (mode) {
        case ThemeMode.light:
          themeStr = 'light';
          break;
        case ThemeMode.dark:
          themeStr = 'dark';
          break;
        case ThemeMode.system:
          themeStr = 'system';
          break;
      }
      await prefs.setString(keyThemeMode, themeStr);
    } catch (_) {}
  }

  /// Toggle master notification switch
  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(keyNotificationsEnabled, value);
    } catch (_) {}
  }

  /// Toggle announcement notifications
  Future<void> setNotifyAnnouncements(bool value) async {
    _notifyAnnouncements = value;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(keyNotifyAnnouncements, value);
    } catch (_) {}
  }

  /// Toggle status change notifications
  Future<void> setNotifyStatusChanges(bool value) async {
    _notifyStatusChanges = value;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(keyNotifyStatusChanges, value);
    } catch (_) {}
  }

  /// Toggle upvote/support notifications
  Future<void> setNotifySupports(bool value) async {
    _notifySupports = value;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(keyNotifySupports, value);
    } catch (_) {}
  }

  /// Toggle comment & discussion notifications
  Future<void> setNotifyComments(bool value) async {
    _notifyComments = value;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(keyNotifyComments, value);
    } catch (_) {}
  }

  /// Toggle incoming new report notifications (admin ecosystem)
  Future<void> setNotifyNewReports(bool value) async {
    _notifyNewReports = value;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(keyNotifyNewReports, value);
    } catch (_) {}
  }

  /// Toggle reply notifications (admin ecosystem)
  Future<void> setNotifyReplies(bool value) async {
    _notifyReplies = value;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(keyNotifyReplies, value);
    } catch (_) {}
  }

  /// Check whether a specific notification type should trigger alerts
  bool isNotificationAllowed(NotificationType type, {bool isAdmin = false}) {
    if (!_notificationsEnabled) return false;

    if (isAdmin) {
      switch (type) {
        case NotificationType.newReport:
          return _notifyNewReports;
        case NotificationType.announcement:
          return _notifyAnnouncements;
        case NotificationType.replyComment:
        case NotificationType.newComment:
          return _notifyReplies;
        default:
          return true;
      }
    }

    switch (type) {
      case NotificationType.announcement:
        return _notifyAnnouncements;
      case NotificationType.statusChanged:
        return _notifyStatusChanges;
      case NotificationType.upvoted:
        return _notifySupports;
      case NotificationType.newComment:
      case NotificationType.replyComment:
        return _notifyComments;
      case NotificationType.newReport:
        return _notifyNewReports;
      default:
        return true;
    }
  }
}

