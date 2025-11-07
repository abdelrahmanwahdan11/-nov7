import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/design_tokens.dart';
import '../data/models/profile.dart';
import '../data/models/theme_preset.dart';
import '../data/models/user_prefs.dart';
import 'items_controller.dart';

const _langKey = 'prefs.lang';
const _darkKey = 'prefs.dark';
const _primaryKey = 'prefs.primary';
const _firstLaunchKey = 'firstLaunchDone';
const _coachKey = 'coach.pending';
const _profilesKey = 'profiles.json';
const _activeProfileKey = 'profiles.active';
const _featureFlagsKey = 'feature_flags.json';
const _kioskKey = 'kiosk.mode';
const _themePresetsKey = 'theme_presets.json';
const _themeStudioStateKey = 'theme_studio.state';

class AppMessage {
  const AppMessage({required this.text, this.severity = SnackBarSeverity.info});

  final String text;
  final SnackBarSeverity severity;
}

enum SnackBarSeverity { info, success, warning, danger }

class AppController extends ChangeNotifier {
  AppController._(
    this._prefs,
    this._bottomNavIndex,
    this._firstLaunchPending,
    this._tutorialPending,
  ) {
    _messageNotifier = ValueNotifier<AppMessage?>(null);
    _featureFlags = {
      'reduceMotion': false,
      'enableParticles': false,
      'enableDeepAnimations': true,
    };
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
    await controller._loadProfiles();
    controller._loadFeatureFlags();
    controller._loadThemeStudioState();
    controller._kioskMode = prefs.getBool(_kioskKey) ?? false;
    return controller;
  }

  final SharedPreferences _prefs;
  final ValueNotifier<int> _bottomNavIndex;
  late final ValueNotifier<AppMessage?> _messageNotifier;
  ItemsController? _itemsController;
  bool _isDark = false;
  String _lang = 'en';
  Color _primaryColor = DesignTokens.primary;
  bool _firstLaunchPending;
  bool _tutorialPending;
  bool _kioskMode = false;
  Map<String, bool> _featureFlags = const {};
  List<Profile> _profiles = const [];
  String? _activeProfileId;
  List<ThemePreset> _themePresets = const [];
  double _typographyScale = 1.0;
  String? _themePresetId;

  ValueNotifier<int> get bottomNavNotifier => _bottomNavIndex;
  int get bottomNavIndex => _bottomNavIndex.value;
  bool get isDark => _isDark;
  Locale get locale => Locale(_lang);
  Color get primaryColor => _primaryColor;
  bool get shouldShowCoachMarks => _tutorialPending;
  bool get isFirstLaunch => _firstLaunchPending;
  bool get kioskMode => _kioskMode;
  Map<String, bool> get featureFlags => Map.unmodifiable(_featureFlags);
  List<Profile> get profiles => List.unmodifiable(_profiles);
  String? get activeProfileId => _activeProfileId;
  List<ThemePreset> get themePresets => List.unmodifiable(_themePresets);
  double get typographyScale => _typographyScale;
  String? get themePresetId => _themePresetId;
  ValueListenable<AppMessage?> get messageListenable => _messageNotifier;

  void attachItemsController(ItemsController controller) {
    _itemsController = controller;
  }

  Future<void> updateBottomNav(int index) async {
    if (_bottomNavIndex.value == index) return;
    _bottomNavIndex.value = index;
  }

  Future<void> toggleTheme() async {
    _isDark = !_isDark;
    await _prefs.setBool(_darkKey, _isDark);
    _updateActiveProfilePrefs(dark: _isDark);
    notifyListeners();
  }

  Future<void> setLocale(String languageCode) async {
    if (_lang == languageCode) return;
    _lang = languageCode;
    await _prefs.setString(_langKey, languageCode);
    _updateActiveProfilePrefs(lang: languageCode);
    notifyListeners();
  }

  Future<void> setPrimary(Color color) async {
    _primaryColor = color;
    await _prefs.setString(_primaryKey, color.value.toRadixString(16));
    _updateActiveProfilePrefs(primaryColor: color.value.toRadixString(16));
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

  Future<void> toggleKioskMode() async {
    _kioskMode = !_kioskMode;
    await _prefs.setBool(_kioskKey, _kioskMode);
    notifyListeners();
  }

  Future<void> setFeatureFlag(String key, bool value) async {
    _featureFlags = {..._featureFlags, key: value};
    await _prefs.setString(_featureFlagsKey, jsonEncode(_featureFlags));
    notifyListeners();
  }

  Future<void> createProfile(String name) async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final prefs = UserPrefs(
      lang: _lang,
      dark: _isDark,
      primaryColor: _primaryColor.value.toRadixString(16),
    );
    final profile = Profile(id: id, name: name, prefs: prefs, lastActive: DateTime.now());
    _profiles = [..._profiles, profile];
    _activeProfileId = id;
    await _persistProfiles();
    await _prefs.setString(_activeProfileKey, id);
    notifyListeners();
  }

  Future<void> switchProfile(String id) async {
    final profile = _profiles.firstWhere((element) => element.id == id);
    _lang = profile.prefs.lang;
    _isDark = profile.prefs.dark;
    _primaryColor = Color(int.parse(profile.prefs.primaryColor, radix: 16));
    _activeProfileId = id;
    await _prefs.setString(_langKey, _lang);
    await _prefs.setBool(_darkKey, _isDark);
    await _prefs.setString(_primaryKey, _primaryColor.value.toRadixString(16));
    await _prefs.setString(_activeProfileKey, id);
    _profiles = _profiles
        .map((element) => element.id == id
            ? element.copyWith(lastActive: DateTime.now())
            : element)
        .toList();
    await _persistProfiles();
    notifyListeners();
  }

  Future<void> deleteProfile(String id) async {
    if (_profiles.length <= 1) return;
    _profiles = _profiles.where((profile) => profile.id != id).toList();
    if (_activeProfileId == id) {
      final fallback = _profiles.first;
      await switchProfile(fallback.id);
    }
    await _persistProfiles();
    notifyListeners();
  }

  Future<void> saveThemePreset(ThemePreset preset) async {
    final presets = [..._themePresets];
    final index = presets.indexWhere((element) => element.id == preset.id);
    if (index == -1) {
      presets.add(preset);
    } else {
      presets[index] = preset;
    }
    _themePresets = presets;
    await _prefs.setString(_themePresetsKey, ThemePreset.encodeList(presets));
    notifyListeners();
  }

  Future<void> applyThemePreset(String id) async {
    final preset = _themePresets.firstWhere((element) => element.id == id);
    _themePresetId = id;
    _typographyScale = preset.scale;
    await setPrimary(Color(preset.primaryColor));
    await _persistThemeStudioState();
    notifyListeners();
  }

  Future<void> setTypographyScale(double scale) async {
    _typographyScale = scale;
    await _persistThemeStudioState();
    notifyListeners();
  }

  Future<void> pushMessage(AppMessage message) async {
    _messageNotifier.value = message;
  }

  Future<void> clearMessage() async {
    _messageNotifier.value = null;
  }

  Future<String> exportAllData() async {
    final controller = _itemsController;
    final export = <String, dynamic>{
      'prefs': {
        'lang': _lang,
        'dark': _isDark,
        'primaryColor': _primaryColor.value,
      },
      'featureFlags': _featureFlags,
      'kioskMode': _kioskMode,
      'profiles': _profiles.map((e) => e.toJson()).toList(),
      'themeStudio': {
        'scale': _typographyScale,
        'presetId': _themePresetId,
        'presets': _themePresets.map((e) => e.toJson()).toList(),
      },
    };
    if (controller != null) {
      export['items'] = controller.allItems.map((e) => e.toJson()).toList();
      export['favorites'] = controller.favoritesListenable.value.toList();
      export['compare'] = controller.compareListenable.value.toList();
      export['wishlist'] = controller.wishlistListenable.value.toList();
      export['collections'] = controller.collectionsListenable.value
          .map((e) => e.toJson())
          .toList();
      export['bundles'] = controller.bundlesListenable.value.map((e) => e.toJson()).toList();
    }
    final json = jsonEncode(export);
    await _prefs.setString('export_dump.json', json);
    return json;
  }

  Future<void> importAllData(String rawJson) async {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map<String, dynamic>) return;
    final prefs = decoded['prefs'] as Map<String, dynamic>?;
    if (prefs != null) {
      final lang = prefs['lang'] as String?;
      final dark = prefs['dark'] as bool?;
      final primary = prefs['primaryColor'] as int?;
      if (lang != null) _lang = lang;
      if (dark != null) _isDark = dark;
      if (primary != null) _primaryColor = Color(primary);
      await _prefs.setString(_langKey, _lang);
      await _prefs.setBool(_darkKey, _isDark);
      await _prefs.setString(_primaryKey, _primaryColor.value.toRadixString(16));
    }
    final flags = decoded['featureFlags'] as Map<String, dynamic>?;
    if (flags != null) {
      _featureFlags = flags.map((key, value) => MapEntry(key, value as bool));
      await _prefs.setString(_featureFlagsKey, jsonEncode(_featureFlags));
    }
    final kiosk = decoded['kioskMode'] as bool?;
    if (kiosk != null) {
      _kioskMode = kiosk;
      await _prefs.setBool(_kioskKey, kiosk);
    }
    final profiles = decoded['profiles'] as List<dynamic>?;
    if (profiles != null) {
      _profiles = profiles
          .whereType<Map<String, dynamic>>()
          .map(Profile.fromJson)
          .toList();
      if (_profiles.isNotEmpty) {
        _activeProfileId = _profiles.first.id;
        await _prefs.setString(_activeProfileKey, _activeProfileId!);
      }
      await _persistProfiles();
    }
    final themeStudio = decoded['themeStudio'] as Map<String, dynamic>?;
    if (themeStudio != null) {
      final presets = themeStudio['presets'] as List<dynamic>?;
      if (presets != null) {
        _themePresets = presets
            .whereType<Map<String, dynamic>>()
            .map(ThemePreset.fromJson)
            .toList();
        await _prefs.setString(
          _themePresetsKey,
          ThemePreset.encodeList(_themePresets),
        );
      }
      _typographyScale = (themeStudio['scale'] as num?)?.toDouble() ?? _typographyScale;
      _themePresetId = themeStudio['presetId'] as String?;
      await _persistThemeStudioState();
    }
    final controller = _itemsController;
    if (controller != null) {
      final items = decoded['items'] as List<dynamic>?;
      if (items != null) {
        final parsed = items
            .whereType<Map<String, dynamic>>()
            .map(Item.fromJson)
            .toList();
        await controller.setItems(parsed);
      }
      final favorites = decoded['favorites'] as List<dynamic>?;
      if (favorites != null) {
        await _prefs.setStringList(
          'favorites.ids',
          favorites.map((e) => '$e').toList(),
        );
      }
    }
    notifyListeners();
  }

  Future<bool> shareOrCopy(String text, {String? url}) async {
    try {
      final buffer = StringBuffer(text);
      if (url != null) buffer.writeln(url);
      await Clipboard.setData(ClipboardData(text: buffer.toString()));
      await pushMessage(const AppMessage(text: 'Copied to clipboard', severity: SnackBarSeverity.success));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> clearStorage() async {
    await _prefs.remove(_langKey);
    await _prefs.remove(_darkKey);
    await _prefs.remove(_primaryKey);
    await _prefs.remove(_firstLaunchKey);
    await _prefs.remove(_coachKey);
    await _prefs.remove(_profilesKey);
    await _prefs.remove(_activeProfileKey);
    await _prefs.remove(_featureFlagsKey);
    await _prefs.remove(_kioskKey);
    await _prefs.remove(_themePresetsKey);
    await _prefs.remove(_themeStudioStateKey);
    _lang = 'en';
    _isDark = false;
    _primaryColor = DesignTokens.primary;
    _firstLaunchPending = true;
    _tutorialPending = true;
    _bottomNavIndex.value = 0;
    _profiles = [];
    _activeProfileId = null;
    _featureFlags = {
      'reduceMotion': false,
      'enableParticles': false,
      'enableDeepAnimations': true,
    };
    _kioskMode = false;
    _themePresets = const [];
    _typographyScale = 1.0;
    _themePresetId = null;
    await _loadProfiles();
    notifyListeners();
  }

  Future<void> _loadProfiles() async {
    final json = _prefs.getString(_profilesKey);
    if (json != null && json.isNotEmpty) {
      _profiles = Profile.decodeList(json);
    } else {
      final defaultProfile = Profile(
        id: 'default',
        name: 'Personal',
        prefs: UserPrefs(
          lang: _lang,
          dark: _isDark,
          primaryColor: _primaryColor.value.toRadixString(16),
        ),
        lastActive: DateTime.now(),
      );
      _profiles = [defaultProfile];
      await _persistProfiles();
    }
    _activeProfileId = _prefs.getString(_activeProfileKey) ?? _profiles.first.id;
  }

  void _loadFeatureFlags() {
    final json = _prefs.getString(_featureFlagsKey);
    if (json != null && json.isNotEmpty) {
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      _featureFlags = decoded.map((key, value) => MapEntry(key, value as bool));
    }
  }

  void _loadThemeStudioState() {
    final presetsJson = _prefs.getString(_themePresetsKey);
    if (presetsJson != null && presetsJson.isNotEmpty) {
      _themePresets = ThemePreset.decodeList(presetsJson);
    }
    final stateJson = _prefs.getString(_themeStudioStateKey);
    if (stateJson != null && stateJson.isNotEmpty) {
      final decoded = jsonDecode(stateJson) as Map<String, dynamic>;
      _typographyScale = (decoded['scale'] as num?)?.toDouble() ?? 1.0;
      _themePresetId = decoded['presetId'] as String?;
    }
  }

  Future<void> _persistProfiles() async {
    await _prefs.setString(_profilesKey, Profile.encodeList(_profiles));
  }

  Future<void> _persistThemeStudioState() async {
    await _prefs.setString(
      _themeStudioStateKey,
      jsonEncode({'scale': _typographyScale, 'presetId': _themePresetId}),
    );
  }

  void _updateActiveProfilePrefs({String? lang, bool? dark, String? primaryColor}) {
    final id = _activeProfileId;
    if (id == null) return;
    final index = _profiles.indexWhere((element) => element.id == id);
    if (index == -1) return;
    final profile = _profiles[index];
    final updated = profile.copyWith(
      prefs: profile.prefs.copyWith(
        lang: lang ?? profile.prefs.lang,
        dark: dark ?? profile.prefs.dark,
        primaryColor: primaryColor ?? profile.prefs.primaryColor,
      ),
      lastActive: DateTime.now(),
    );
    _profiles = [..._profiles]..[index] = updated;
    _persistProfiles();
  }

  @override
  void dispose() {
    _bottomNavIndex.dispose();
    _messageNotifier.dispose();
    super.dispose();
  }
}
