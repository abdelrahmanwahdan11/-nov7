import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/design_tokens.dart';
import '../core/utils/export_import.dart';
import '../data/models/profile.dart';
import '../data/models/user_prefs.dart';

const _langKey = 'prefs.lang';
const _darkKey = 'prefs.dark';
const _primaryKey = 'prefs.primary';
const _firstLaunchKey = 'firstLaunchDone';
const _coachKey = 'coach.pending';
const _featureFlagsKey = 'feature_flags.json';
const _exportDumpKey = 'export_dump.json';
const _profilesKey = 'profiles.json';
const _activeProfileKey = 'profiles.active';
const _kioskKey = 'kiosk.mode';
const _themeStudioKey = 'theme_studio.state';

class AppController extends ChangeNotifier {
  AppController._(
    this._prefs,
    this._bottomNavIndex,
    this._firstLaunchPending,
    this._tutorialPending,
    this._featureFlags,
    this._lastExport,
    this._profiles,
    this._activeProfileId,
    this._kioskMode,
    this._themeStudioState,
  );

  static Future<AppController> init() async {
    final prefs = await SharedPreferences.getInstance();
    var lang = prefs.getString(_langKey) ?? 'en';
    var dark = prefs.getBool(_darkKey) ?? false;
    var primary = prefs.getString(_primaryKey) ??
        DesignTokens.primary.value.toRadixString(16);
    final firstLaunchPending = !(prefs.getBool(_firstLaunchKey) ?? false);
    final tutorialPending = prefs.getBool(_coachKey) ?? true;
    final featureFlags = _decodeFeatureFlags(prefs.getString(_featureFlagsKey));
    final lastExport = prefs.getString(_exportDumpKey);
    final profilesJson = prefs.getString(_profilesKey);
    final profiles = profilesJson == null || profilesJson.isEmpty
        ? <Profile>[]
        : Profile.decodeList(profilesJson);
    String? activeProfileId = prefs.getString(_activeProfileKey);
    if (activeProfileId != null &&
        profiles.every((profile) => profile.id != activeProfileId)) {
      activeProfileId = profiles.isEmpty ? null : profiles.first.id;
    }
    final kioskMode = prefs.getBool(_kioskKey) ?? false;
    final themeJson = prefs.getString(_themeStudioKey);
    final themeStudioState = ThemeStudioState.fromJson(themeJson);
    if (activeProfileId != null) {
      try {
        final activeProfile =
            profiles.firstWhere((profile) => profile.id == activeProfileId);
        lang = activeProfile.prefs.lang;
        dark = activeProfile.prefs.dark;
        primary = activeProfile.prefs.primaryColor;
      } catch (_) {
        activeProfileId = null;
      }
    }
    final controller = AppController._(
      prefs,
      ValueNotifier<int>(0),
      firstLaunchPending,
      tutorialPending,
      featureFlags,
      lastExport,
      profiles,
      activeProfileId,
      kioskMode,
      themeStudioState,
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
  List<Profile> _profiles;
  String? _activeProfileId;
  bool _kioskMode;
  ThemeStudioState _themeStudioState;

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
  List<Profile> get profiles => List<Profile>.unmodifiable(_profiles);
  Profile? get activeProfile {
    if (_activeProfileId == null) return null;
    try {
      return _profiles.firstWhere((profile) => profile.id == _activeProfileId);
    } catch (_) {
      return null;
    }
  }

  bool get kioskMode => _kioskMode;
  ThemeStudioState get themeStudioState => _themeStudioState;

  Future<void> updateBottomNav(int index) async {
    if (_bottomNavIndex.value == index) return;
    _bottomNavIndex.value = index;
  }

  Future<void> toggleTheme() async {
    _isDark = !_isDark;
    await _prefs.setBool(_darkKey, _isDark);
    await _syncActiveProfile();
    notifyListeners();
  }

  Future<void> setLocale(String languageCode) async {
    if (_lang == languageCode) return;
    _lang = languageCode;
    await _prefs.setString(_langKey, languageCode);
    await _syncActiveProfile();
    notifyListeners();
  }

  Future<void> setPrimary(Color color) async {
    _primaryColor = color;
    await _prefs.setString(_primaryKey, color.value.toRadixString(16));
    await _syncActiveProfile();
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
    await _prefs.remove(_profilesKey);
    await _prefs.remove(_activeProfileKey);
    await _prefs.remove(_kioskKey);
    await _prefs.remove(_themeStudioKey);
    _lang = 'en';
    _isDark = false;
    _primaryColor = DesignTokens.primary;
    _firstLaunchPending = true;
    _tutorialPending = true;
    _bottomNavIndex.value = 0;
    _featureFlags = {'reduceMotion': false, 'enableParticles': false};
    _lastExport = null;
    _profiles = <Profile>[];
    _activeProfileId = null;
    _kioskMode = false;
    _themeStudioState = const ThemeStudioState();
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
      await _reloadProfilesFromPrefs();
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Profile> createProfile(String name) async {
    final prefs = UserPrefs(
      lang: _lang,
      dark: _isDark,
      primaryColor: _primaryColor.value.toRadixString(16),
    );
    final profile = Profile(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      prefs: prefs,
      lastActive: DateTime.now(),
    );
    _profiles = [..._profiles, profile];
    _activeProfileId = profile.id;
    await _persistProfiles();
    await _prefs.setString(_activeProfileKey, profile.id);
    await _applyProfile(profile);
    notifyListeners();
    return profile;
  }

  Future<void> renameProfile(String id, String name) async {
    _profiles = _profiles.map((profile) {
      if (profile.id == id) {
        return profile.copyWith(name: name);
      }
      return profile;
    }).toList();
    await _persistProfiles();
    notifyListeners();
  }

  Future<void> switchProfile(String id) async {
    if (_activeProfileId == id) return;
    try {
      final profile = _profiles.firstWhere((element) => element.id == id);
      _activeProfileId = id;
      await _prefs.setString(_activeProfileKey, id);
      await _applyProfile(profile.copyWith(lastActive: DateTime.now()));
      _profiles = _profiles.map((element) {
        if (element.id == id) {
          return profile.copyWith(lastActive: DateTime.now());
        }
        return element;
      }).toList();
      await _persistProfiles();
      notifyListeners();
    } catch (_) {
      // ignore
    }
  }

  Future<void> deleteProfile(String id) async {
    final wasActive = _activeProfileId == id;
    _profiles = _profiles.where((profile) => profile.id != id).toList();
    if (wasActive) {
      _activeProfileId = _profiles.isEmpty ? null : _profiles.first.id;
      if (_activeProfileId != null) {
        final replacement =
            _profiles.first.copyWith(lastActive: DateTime.now());
        _profiles[0] = replacement;
        await _applyProfile(replacement);
        await _prefs.setString(_activeProfileKey, _activeProfileId!);
      } else {
        await _prefs.remove(_activeProfileKey);
      }
    }
    await _persistProfiles();
    notifyListeners();
  }

  Future<void> setKioskMode(bool value) async {
    if (_kioskMode == value) return;
    _kioskMode = value;
    await _prefs.setBool(_kioskKey, value);
    notifyListeners();
  }

  Future<void> updateThemeStudio(ThemeStudioState state) async {
    _themeStudioState = state;
    await _prefs.setString(_themeStudioKey, jsonEncode(state.toJson()));
    notifyListeners();
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

  Future<void> _persistProfiles() async {
    await _prefs.setString(_profilesKey, Profile.encodeList(_profiles));
  }

  Future<void> _applyProfile(Profile profile) async {
    _lang = profile.prefs.lang;
    _isDark = profile.prefs.dark;
    _primaryColor = Color(int.parse(profile.prefs.primaryColor, radix: 16));
    await _prefs.setString(_langKey, _lang);
    await _prefs.setBool(_darkKey, _isDark);
    await _prefs.setString(_primaryKey, _primaryColor.value.toRadixString(16));
  }

  Future<void> _syncActiveProfile() async {
    if (_activeProfileId == null) return;
    final index = _profiles.indexWhere((profile) => profile.id == _activeProfileId);
    if (index == -1) return;
    final updatedPrefs = UserPrefs(
      lang: _lang,
      dark: _isDark,
      primaryColor: _primaryColor.value.toRadixString(16),
    );
    _profiles[index] =
        _profiles[index].copyWith(prefs: updatedPrefs, lastActive: DateTime.now());
    await _persistProfiles();
  }

  Future<void> _reloadProfilesFromPrefs() async {
    final profilesJson = _prefs.getString(_profilesKey);
    _profiles = profilesJson == null || profilesJson.isEmpty
        ? <Profile>[]
        : Profile.decodeList(profilesJson);
    _activeProfileId = _prefs.getString(_activeProfileKey);
    _kioskMode = _prefs.getBool(_kioskKey) ?? false;
    _themeStudioState =
        ThemeStudioState.fromJson(_prefs.getString(_themeStudioKey));
    if (_activeProfileId != null) {
      final active = activeProfile;
      if (active != null) {
        await _applyProfile(active);
      }
    }
  }
}

class ThemeStudioState {
  const ThemeStudioState({this.paletteIndex = 0, this.typographyScale = 1.0});

  factory ThemeStudioState.fromJson(String? source) {
    if (source == null || source.isEmpty) {
      return const ThemeStudioState();
    }
    try {
      final decoded = jsonDecode(source) as Map<String, dynamic>;
      return ThemeStudioState(
        paletteIndex: decoded['paletteIndex'] as int? ?? 0,
        typographyScale: (decoded['typographyScale'] as num?)?.toDouble() ?? 1.0,
      );
    } catch (_) {
      return const ThemeStudioState();
    }
  }

  final int paletteIndex;
  final double typographyScale;

  ThemeStudioState copyWith({int? paletteIndex, double? typographyScale}) {
    return ThemeStudioState(
      paletteIndex: paletteIndex ?? this.paletteIndex,
      typographyScale: typographyScale ?? this.typographyScale,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'paletteIndex': paletteIndex,
      'typographyScale': typographyScale,
    };
  }
}
