import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/design_tokens.dart';

const _langKey = 'prefs.lang';
const _darkKey = 'prefs.dark';
const _primaryKey = 'prefs.primary';
const _firstLaunchKey = 'firstLaunchDone';
const _coachKey = 'coach.pending';

class AppController extends ChangeNotifier {
  AppController._(this._prefs, this._bottomNavIndex, this._firstLaunchPending,
      this._tutorialPending) {
    _notificationController = StreamController<AppNotification>.broadcast();
    _notificationNotifier = ValueNotifier<AppNotification?>(null);
  }

  static Future<AppController> init() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString(_langKey) ?? 'en';
    final dark = prefs.getBool(_darkKey) ?? false;
    final primary = prefs.getString(_primaryKey) ??
        DesignTokens.primary.value.toRadixString(16);
    final firstLaunchPending = !(prefs.getBool(_firstLaunchKey) ?? false);
    final tutorialPending = prefs.getBool(_coachKey) ?? true;
    final controller = AppController._(
      prefs,
      ValueNotifier<int>(0),
      firstLaunchPending,
      tutorialPending,
    );
    controller
      .._lang = lang
      .._isDark = dark
      .._primaryColor = Color(int.parse(primary, radix: 16));
    return controller;
  }

  final SharedPreferences _prefs;
  final ValueNotifier<int> _bottomNavIndex;
  bool _isDark = false;
  String _lang = 'en';
  Color _primaryColor = DesignTokens.primary;
  bool _firstLaunchPending;
  bool _tutorialPending;
  late final StreamController<AppNotification> _notificationController;
  late final ValueNotifier<AppNotification?> _notificationNotifier;

  ValueNotifier<int> get bottomNavNotifier => _bottomNavIndex;
  int get bottomNavIndex => _bottomNavIndex.value;
  bool get isDark => _isDark;
  Locale get locale => Locale(_lang);
  Color get primaryColor => _primaryColor;
  bool get shouldShowCoachMarks => _tutorialPending;
  bool get isFirstLaunch => _firstLaunchPending;
  Stream<AppNotification> get notificationStream => _notificationController.stream;
  ValueListenable<AppNotification?> get lastNotificationListenable =>
      _notificationNotifier;

  Future<void> updateBottomNav(int index) async {
    if (_bottomNavIndex.value == index) return;
    _bottomNavIndex.value = index;
  }

  Future<void> toggleTheme() async {
    _isDark = !_isDark;
    await _prefs.setBool(_darkKey, _isDark);
    notifyListeners();
  }

  Future<void> setLocale(String languageCode) async {
    if (_lang == languageCode) return;
    _lang = languageCode;
    await _prefs.setString(_langKey, languageCode);
    notifyListeners();
  }

  Future<void> setPrimary(Color color) async {
    _primaryColor = color;
    await _prefs.setString(_primaryKey, color.value.toRadixString(16));
    notifyListeners();
  }

  Future<void> markCoachMarksSeen() async {
    if (!_tutorialPending) return;
    _tutorialPending = false;
    await _prefs.setBool(_coachKey, false);
    notifyListeners();
  }

  Future<void> resetCoachMarks() async {
    _tutorialPending = true;
    await _prefs.setBool(_coachKey, true);
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    _firstLaunchPending = false;
    _tutorialPending = true;
    await _prefs.setBool(_firstLaunchKey, true);
    await _prefs.setBool(_coachKey, true);
    notifyListeners();
  }

  Future<void> clearStorage() async {
    await _prefs.remove(_langKey);
    await _prefs.remove(_darkKey);
    await _prefs.remove(_primaryKey);
    await _prefs.remove(_firstLaunchKey);
    await _prefs.remove(_coachKey);
    _lang = 'en';
    _isDark = false;
    _primaryColor = DesignTokens.primary;
    _firstLaunchPending = true;
    _tutorialPending = true;
    _bottomNavIndex.value = 0;
    notifyListeners();
  }

  void showNotification(AppNotification notification) {
    _notificationNotifier.value = notification;
    _notificationController.add(notification);
  }

  Future<void> shareOrCopy(String text, {String? url}) async {
    final buffer = StringBuffer(text.trim());
    if (url != null && url.isNotEmpty) {
      if (buffer.isNotEmpty) {
        buffer.writeln();
      }
      buffer.write(url);
    }
    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    showNotification(
      AppNotification(
        message: 'Copied to clipboard',
        type: AppNotificationType.info,
      ),
    );
  }

  @override
  void dispose() {
    _bottomNavIndex.dispose();
    _notificationNotifier.dispose();
    _notificationController.close();
    super.dispose();
  }
}

enum AppNotificationType { info, success, warning, error }

class AppNotification {
  const AppNotification({
    required this.message,
    this.description,
    this.type = AppNotificationType.info,
  });

  final String message;
  final String? description;
  final AppNotificationType type;
}
