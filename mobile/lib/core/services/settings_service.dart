import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sound_service.dart';

class SettingsService extends ChangeNotifier {
  static final SettingsService instance = SettingsService._internal();
  SettingsService._internal();

  bool _isDarkMode = true;
  bool _soundEffects = true;
  bool _vibration = true;
  String _dialect = 'لهجة مصرية';
  bool _familyMode = false;
  bool _isInitialized = false;

  bool get isDarkMode => _isDarkMode;
  bool get soundEffects => _soundEffects;
  bool get vibration => _vibration;
  String get dialect => _dialect;
  bool get familyMode => _familyMode;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool('pref_dark_mode') ?? true;
      _soundEffects = prefs.getBool('pref_sound_effects') ?? true;
      _vibration = prefs.getBool('pref_vibration') ?? true;
      _dialect = prefs.getString('pref_dialect') ?? 'لهجة مصرية';
      _familyMode = prefs.getBool('pref_family_mode') ?? false;

      SoundService.instance.setEnabled(_soundEffects);
      _isInitialized = true;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('pref_dark_mode', value);
    } catch (_) {}
  }

  Future<void> setSoundEffects(bool value) async {
    _soundEffects = value;
    SoundService.instance.setEnabled(value);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('pref_sound_effects', value);
    } catch (_) {}
  }

  Future<void> setVibration(bool value) async {
    _vibration = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('pref_vibration', value);
    } catch (_) {}
  }

  Future<void> setDialect(String value) async {
    _dialect = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pref_dialect', value);
    } catch (_) {}
  }

  Future<void> setFamilyMode(bool value) async {
    _familyMode = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('pref_family_mode', value);
    } catch (_) {}
  }

  /// تنفيذ اهتزاز لمسي فقط إذا كان خيار الاهتزاز مفعلاً
  void triggerHaptic({bool isHeavy = false}) {
    if (!_vibration) return;
    if (isHeavy) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }
  }
}

