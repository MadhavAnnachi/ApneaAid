import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  // Singleton instance
  static final SettingsService _instance = SettingsService._internal();

  factory SettingsService() {
    return _instance;
  }

  SettingsService._internal() {
    _init();
  }

  // Stream controllers
  final _settingsController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Stream getter
  Stream<Map<String, dynamic>> get settingsStream => _settingsController.stream;

  // Default values
  bool _notifyHighRisk = true;
  bool _autoRecording = false;
  double _sensitivityLevel = 2.0;
  String _recordingDuration = '8 hours';

  // Accessibility settings defaults
  double _fontSize = 1.0; // Normal size (1.0x)
  bool _highContrast = false;
  String _colorBlindnessMode = 'None';
  bool _textToSpeech = false;

  // Getters for settings
  bool get notifyHighRisk => _notifyHighRisk;
  bool get autoRecording => _autoRecording;
  double get sensitivityLevel => _sensitivityLevel;
  String get recordingDuration => _recordingDuration;

  // Getters for accessibility settings
  double get fontSize => _fontSize;
  bool get highContrast => _highContrast;
  String get colorBlindnessMode => _colorBlindnessMode;
  bool get textToSpeech => _textToSpeech;

  // Init method to load settings from SharedPreferences
  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load saved settings with defaults if not found
      _notifyHighRisk = prefs.getBool('notify_high_risk') ?? true;
      _autoRecording = prefs.getBool('auto_recording') ?? false;
      _sensitivityLevel = prefs.getDouble('sensitivity_level') ?? 2.0;
      _recordingDuration = prefs.getString('recording_duration') ?? '8 hours';

      // Load accessibility settings
      _fontSize = prefs.getDouble('font_size') ?? 1.0;
      _highContrast = prefs.getBool('high_contrast') ?? false;
      _colorBlindnessMode = prefs.getString('color_blindness_mode') ?? 'None';
      _textToSpeech = prefs.getBool('text_to_speech') ?? false;

      // Emit initial settings
      _emitSettings();

      debugPrint('⚙️ SettingsService: Settings loaded from storage');
    } catch (e) {
      debugPrint('⚙️ SettingsService ERROR loading settings: $e');
    }
  }

  // Emit current settings to stream
  void _emitSettings() {
    _settingsController.add({
      'notify_high_risk': _notifyHighRisk,
      'auto_recording': _autoRecording,
      'sensitivity_level': _sensitivityLevel,
      'recording_duration': _recordingDuration,
      'font_size': _fontSize,
      'high_contrast': _highContrast,
      'color_blindness_mode': _colorBlindnessMode,
      'text_to_speech': _textToSpeech,
    });
  }

  // Update notification settings
  Future<void> setNotifyHighRisk(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notify_high_risk', value);
      _notifyHighRisk = value;
      _emitSettings();
      debugPrint('⚙️ SettingsService: Updated notify_high_risk to $value');
    } catch (e) {
      debugPrint('⚙️ SettingsService ERROR updating notify_high_risk: $e');
    }
  }

  // Update auto recording settings
  Future<void> setAutoRecording(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('auto_recording', value);
      _autoRecording = value;
      _emitSettings();
      debugPrint('⚙️ SettingsService: Updated auto_recording to $value');
    } catch (e) {
      debugPrint('⚙️ SettingsService ERROR updating auto_recording: $e');
    }
  }

  // Update sensitivity level settings
  Future<void> setSensitivityLevel(double value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('sensitivity_level', value);
      _sensitivityLevel = value;
      _emitSettings();
      debugPrint('⚙️ SettingsService: Updated sensitivity_level to $value');
    } catch (e) {
      debugPrint('⚙️ SettingsService ERROR updating sensitivity_level: $e');
    }
  }

  // Update recording duration settings
  Future<void> setRecordingDuration(String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('recording_duration', value);
      _recordingDuration = value;
      _emitSettings();
      debugPrint('⚙️ SettingsService: Updated recording_duration to $value');
    } catch (e) {
      debugPrint('⚙️ SettingsService ERROR updating recording_duration: $e');
    }
  }

  // Update font size settings
  Future<void> setFontSize(double value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('font_size', value);
      _fontSize = value;
      _emitSettings();
      debugPrint('⚙️ SettingsService: Updated font_size to $value');
    } catch (e) {
      debugPrint('⚙️ SettingsService ERROR updating font_size: $e');
    }
  }

  // Update high contrast settings
  Future<void> setHighContrast(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('high_contrast', value);
      _highContrast = value;
      _emitSettings();
      debugPrint('⚙️ SettingsService: Updated high_contrast to $value');
    } catch (e) {
      debugPrint('⚙️ SettingsService ERROR updating high_contrast: $e');
    }
  }

  // Update color blindness mode settings
  Future<void> setColorBlindnessMode(String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('color_blindness_mode', value);
      _colorBlindnessMode = value;
      _emitSettings();
      debugPrint('⚙️ SettingsService: Updated color_blindness_mode to $value');
    } catch (e) {
      debugPrint('⚙️ SettingsService ERROR updating color_blindness_mode: $e');
    }
  }

  // Update text to speech settings
  Future<void> setTextToSpeech(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('text_to_speech', value);
      _textToSpeech = value;
      _emitSettings();
      debugPrint('⚙️ SettingsService: Updated text_to_speech to $value');
    } catch (e) {
      debugPrint('⚙️ SettingsService ERROR updating text_to_speech: $e');
    }
  }

  // Reset all settings to defaults
  Future<void> resetToDefaults() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notify_high_risk', true);
      await prefs.setBool('auto_recording', false);
      await prefs.setDouble('sensitivity_level', 2.0);
      await prefs.setString('recording_duration', '8 hours');

      // Reset accessibility settings
      await prefs.setDouble('font_size', 1.0);
      await prefs.setBool('high_contrast', false);
      await prefs.setString('color_blindness_mode', 'None');
      await prefs.setBool('text_to_speech', false);

      _notifyHighRisk = true;
      _autoRecording = false;
      _sensitivityLevel = 2.0;
      _recordingDuration = '8 hours';

      // Reset accessibility settings
      _fontSize = 1.0;
      _highContrast = false;
      _colorBlindnessMode = 'None';
      _textToSpeech = false;

      _emitSettings();
      debugPrint('⚙️ SettingsService: Reset all settings to defaults');
    } catch (e) {
      debugPrint('⚙️ SettingsService ERROR resetting settings: $e');
    }
  }

  // Dispose resources
  void dispose() {
    _settingsController.close();
  }
}
