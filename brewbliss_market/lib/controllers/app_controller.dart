import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/design_tokens.dart';
import '../core/utils/export_import.dart';

const _langKey = 'prefs.lang';
const _darkKey = 'prefs.dark';
const _primaryKey = 'prefs.primary';
const _firstLaunchKey = 'firstLaunchDone';
const _coachKey = 'coach.pending';
const _featureFlagsKey = 'feature_flags.json';
const _exportDumpKey = 'export_dump.json';

class AppController extends ChangeNotifier {
  AppController._(
    this._prefs,
    this._bottomNavIndex,
    this._firstLaunchPending,
    this._tutorialPending,
    this._featureFlags,
    this._lastExport,
  );

  static Future<AppController> init() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString(_langKey) ?? 'en';
    final dark = prefs.getBool(_darkKey) ?? false;
    final primary = prefs.getString(_primaryKey) ??
        DesignTokens.primary.value.toRadixString(16);
    final firstLaunchPending = !(prefs.getBool(_firstLaunchKey) ?? false);
    final tutorialPending = prefs.getBool(_coachKey) ?? true;
    final featureFlags = _decodeFeatureFlags(prefs.getString(_featureFlagsKey));
    final lastExport = prefs.getString(_exportDumpKey);
    final controller = AppController._(
      prefs,
      ValueNotifier<int>(0),
      firstLaunchPending,
      tutorialPending,
      featureFlags,
      lastExport,
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
  Map<String, bool> _featureFlags;
  String? _lastExport;

  ValueNotifier<int> get bottomNavNotifier => _bottomNavIndex;
  int get bottomNavIndex => _bottomNavIndex.value;
  bool get isDark => _isDark;
  Locale get locale => Locale(_lang);
  Color get primaryColor => _primaryColor;
  bool get shouldShowCoachMarks => _tutorialPending;
  bool get isFirstLaunch => _firstLaunchPending;
  bool get reduceMotion => _featureFlags['reduceMotion'] ?? false;
  bool get enableParticles => _featureFlags['enableParticles'] ?? false;
  String? get lastExportedSnapshot => _lastExport;

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
    await _prefs.remove(_featureFlagsKey);
    await _prefs.remove(_exportDumpKey);
    _lang = 'en';
    _isDark = false;
    _primaryColor = DesignTokens.primary;
    _firstLaunchPending = true;
    _tutorialPending = true;
    _bottomNavIndex.value = 0;
    _featureFlags = {'reduceMotion': false, 'enableParticles': false};
    _lastExport = null;
    notifyListeners();
  }

  Future<void> setFeatureFlag(String key, bool value) async {
    _featureFlags = {..._featureFlags, key: value};
    await _prefs.setString(_featureFlagsKey, jsonEncode(_featureFlags));
    notifyListeners();
  }

  Future<String> exportAllData() async {
    final dump = ExportImport.buildSnapshot(_prefs);
    final encoded = jsonEncode(dump);
    _lastExport = encoded;
    await _prefs.setString(_exportDumpKey, encoded);
    notifyListeners();
    return encoded;
  }

  Future<bool> importAllData(String rawJson) async {
    try {
      final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
      await ExportImport.restore(_prefs, decoded);
      _lastExport = rawJson;
      await _prefs.setString(_exportDumpKey, rawJson);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _bottomNavIndex.dispose();
    super.dispose();
  }

  static Map<String, bool> _decodeFeatureFlags(String? json) {
    if (json == null || json.isEmpty) {
      return {'reduceMotion': false, 'enableParticles': false};
    }
    try {
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      return {
        'reduceMotion': decoded['reduceMotion'] as bool? ?? false,
        'enableParticles': decoded['enableParticles'] as bool? ?? false,
      };
    } catch (_) {
      return {'reduceMotion': false, 'enableParticles': false};
    }
  }
}
