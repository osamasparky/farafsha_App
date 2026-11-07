import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SoundService {
  static final SoundService instance = SoundService._internal();
  SoundService._internal();

  final AudioPlayer _player = AudioPlayer();
  bool _isEnabled = true;

  bool get isEnabled => _isEnabled;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isEnabled = prefs.getBool('pref_sound_effects') ?? true;
    } catch (e) {
      debugPrint('⚠️ Error initializing SoundService: $e');
    }
  }

  void setEnabled(bool enabled) async {
    _isEnabled = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('pref_sound_effects', enabled);
    } catch (_) {}
  }

  Future<void> playClick() async {
    if (!_isEnabled) return;
    try {
      await _player.stop();
      await _player.play(AssetSource('audio/click.wav'), volume: 0.6);
    } catch (e) {
      debugPrint('Sound play error: $e');
    }
  }

  Future<void> playCorrect() async {
    if (!_isEnabled) return;
    try {
      await _player.stop();
      await _player.play(AssetSource('audio/correct.wav'), volume: 0.85);
    } catch (e) {
      debugPrint('Sound play error: $e');
    }
  }

  Future<void> playWrong() async {
    if (!_isEnabled) return;
    try {
      await _player.stop();
      await _player.play(AssetSource('audio/wrong.wav'), volume: 0.75);
    } catch (e) {
      debugPrint('Sound play error: $e');
    }
  }

  Future<void> playTick() async {
    if (!_isEnabled) return;
    try {
      await _player.stop();
      await _player.play(AssetSource('audio/timer_tick.wav'), volume: 0.5);
    } catch (e) {
      debugPrint('Sound play error: $e');
    }
  }

  Future<void> playWin() async {
    if (!_isEnabled) return;
    try {
      await _player.stop();
      await _player.play(AssetSource('audio/win.wav'), volume: 0.95);
    } catch (e) {
      debugPrint('Sound play error: $e');
    }
  }
}

