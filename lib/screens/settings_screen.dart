import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  bool _notifyHighRisk = true;
  bool _autoRecording = false;
  double _sensitivityLevel = 2.0;
  String _recordingDuration = '8 hours';
  final List<String> _durationOptions = [
    '6 hours',
    '8 hours',
    '10 hours',
    'Until stopped',
  ];

  // Accessibility settings
  double _fontSize = 1.0;
  bool _highContrast = false;
  String _colorBlindnessMode = 'None';
  bool _textToSpeech = false;
  final List<String> _colorBlindnessOptions = [
    'None',
    'Protanopia',
    'Deuteranopia',
    'Tritanopia',
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
    // Listen for settings changes
    _settingsService.settingsStream.listen((settings) {
      setState(() {
        _notifyHighRisk = settings['notify_high_risk'];
        _autoRecording = settings['auto_recording'];
        _sensitivityLevel = settings['sensitivity_level'];
        _recordingDuration = settings['recording_duration'];

        // Listen for accessibility settings changes
        _fontSize = settings['font_size'];
        _highContrast = settings['high_contrast'];
        _colorBlindnessMode = settings['color_blindness_mode'];
        _textToSpeech = settings['text_to_speech'];
      });
    });
  }

  void _loadSettings() {
    setState(() {
      _notifyHighRisk = _settingsService.notifyHighRisk;
      _autoRecording = _settingsService.autoRecording;
      _sensitivityLevel = _settingsService.sensitivityLevel;
      _recordingDuration = _settingsService.recordingDuration;

      // Load accessibility settings
      _fontSize = _settingsService.fontSize;
      _highContrast = _settingsService.highContrast;
      _colorBlindnessMode = _settingsService.colorBlindnessMode;
      _textToSpeech = _settingsService.textToSpeech;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _settingsService.resetToDefaults();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Settings reset to defaults'),
                  backgroundColor: AppTheme.primaryColor,
                ),
              );
            },
            tooltip: 'Reset to defaults',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background gradient glow effect
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF4A2B82).withOpacity(0.5),
                    Colors.black.withOpacity(0.2),
                  ],
                  center: Alignment.topCenter,
                  radius: 0.9,
                ),
              ),
            ),
          ),

          // Add subtle glow on the right side
          Positioned(
            top: 100,
            right: -100,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF6A47BB).withOpacity(0.35),
                    Colors.transparent,
                  ],
                  stops: const [0.2, 1.0],
                ),
              ),
            ),
          ),

          ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildHeader('Recording Settings'),
              _buildSwitchTile(
                'Auto Recording',
                'Start recording automatically at bedtime',
                _autoRecording,
                (value) {
                  _settingsService.setAutoRecording(value);
                },
              ),
              _buildDropdownTile(),
              _buildHeader('Detection Settings'),
              _buildSliderTile(),

              // Add Accessibility Settings Section
              _buildHeader('Accessibility Settings'),
              _buildFontSizeSliderTile(),
              _buildSwitchTile(
                'High Contrast',
                'Enhance text visibility with higher contrast',
                _highContrast,
                (value) {
                  _settingsService.setHighContrast(value);
                },
              ),
              _buildColorBlindnessTile(),
              _buildSwitchTile(
                'Text-to-Speech',
                'Read on-screen content aloud',
                _textToSpeech,
                (value) {
                  _settingsService.setTextToSpeech(value);
                },
              ),

              _buildHeader('Notifications'),
              _buildSwitchTile(
                'High Risk Alerts',
                'Get notified for high risk results',
                _notifyHighRisk,
                (value) {
                  _settingsService.setNotifyHighRisk(value);
                },
              ),
              _buildHeader('App Info'),
              ListTile(
                title: const Text(
                  'About APNEA-AID',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Version 1.0.0',
                  style: TextStyle(color: Colors.white70),
                ),
                onTap: _showSimpleAboutDialog,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18.0,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: ListTile(
        title: Text(title, style: const TextStyle(color: Colors.white)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white70)),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildDropdownTile() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: ListTile(
        title: const Text(
          'Recording Duration',
          style: TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          _recordingDuration,
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: DropdownButton<String>(
          value: _recordingDuration,
          dropdownColor: Colors.black,
          underline: Container(),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
          items:
              _durationOptions
                  .map(
                    (value) => DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                  .toList(),
          onChanged: (newValue) {
            if (newValue != null) {
              _settingsService.setRecordingDuration(newValue);
            }
          },
        ),
      ),
    );
  }

  Widget _buildSliderTile() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Sensitivity', style: TextStyle(color: Colors.white)),
          const SizedBox(height: 4.0),
          const Text(
            'Adjust detection sensitivity',
            style: TextStyle(color: Colors.white70, fontSize: 12.0),
          ),
          const SizedBox(height: 8.0),
          Row(
            children: [
              const Text('Low', style: TextStyle(color: Colors.white70)),
              Expanded(
                child: Slider(
                  value: _sensitivityLevel,
                  min: 1.0,
                  max: 3.0,
                  divisions: 2,
                  activeColor: AppTheme.primaryColor,
                  inactiveColor: Colors.grey.shade800,
                  onChanged: (value) {
                    _settingsService.setSensitivityLevel(value);
                  },
                ),
              ),
              const Text('High', style: TextStyle(color: Colors.white70)),
            ],
          ),
        ],
      ),
    );
  }

  // New Font Size Slider Tile
  Widget _buildFontSizeSliderTile() {
    String fontSizeLabel = 'Normal';
    if (_fontSize <= 0.85) {
      fontSizeLabel = 'Small';
    } else if (_fontSize <= 1.0) {
      fontSizeLabel = 'Normal';
    } else if (_fontSize <= 1.15) {
      fontSizeLabel = 'Large';
    } else {
      fontSizeLabel = 'Extra Large';
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Font Size', style: TextStyle(color: Colors.white)),
          const SizedBox(height: 4.0),
          Text(
            fontSizeLabel,
            style: const TextStyle(color: Colors.white70, fontSize: 12.0),
          ),
          const SizedBox(height: 8.0),
          Row(
            children: [
              const Text(
                'A',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              Expanded(
                child: Slider(
                  value: _fontSize,
                  min: 0.85,
                  max: 1.3,
                  divisions: 3,
                  activeColor: AppTheme.primaryColor,
                  inactiveColor: Colors.grey.shade800,
                  onChanged: (value) {
                    _settingsService.setFontSize(value);
                  },
                ),
              ),
              const Text(
                'A',
                style: TextStyle(color: Colors.white70, fontSize: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // New Color Blindness Dropdown Tile
  Widget _buildColorBlindnessTile() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: ListTile(
        title: const Text(
          'Color Blindness Mode',
          style: TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          _colorBlindnessMode,
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: DropdownButton<String>(
          value: _colorBlindnessMode,
          dropdownColor: Colors.black,
          underline: Container(),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
          items:
              _colorBlindnessOptions
                  .map(
                    (value) => DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                  .toList(),
          onChanged: (newValue) {
            if (newValue != null) {
              _settingsService.setColorBlindnessMode(newValue);
            }
          },
        ),
      ),
    );
  }

  void _showSimpleAboutDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.black,
            title: const Text(
              'About APNEA-AID',
              style: TextStyle(color: Colors.white),
            ),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI-powered sleep apnea detection app',
                  style: TextStyle(color: Colors.white70),
                ),
                SizedBox(height: 16),
                Text(
                  'Not a medical device',
                  style: TextStyle(color: Colors.redAccent, fontSize: 12),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Close',
                  style: TextStyle(color: AppTheme.primaryColor),
                ),
              ),
            ],
          ),
    );
  }
}
