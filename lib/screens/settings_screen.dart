import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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
                (value) => setState(() => _autoRecording = value),
              ),
              _buildDropdownTile(),
              _buildHeader('Detection Settings'),
              _buildSliderTile(),
              _buildHeader('Notifications'),
              _buildSwitchTile(
                'High Risk Alerts',
                'Get notified for high risk results',
                _notifyHighRisk,
                (value) => setState(() => _notifyHighRisk = value),
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
          onChanged:
              (newValue) => setState(() => _recordingDuration = newValue!),
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
                  onChanged:
                      (value) => setState(() => _sensitivityLevel = value),
                ),
              ),
              const Text('High', style: TextStyle(color: Colors.white70)),
            ],
          ),
        ],
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
