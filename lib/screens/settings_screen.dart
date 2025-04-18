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
      backgroundColor:
          Colors.indigo.shade900, // Fallback if AppTheme is causing issues
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.indigo.shade900,
        elevation: 0,
      ),
      body: ListView(
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
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18.0,
          fontWeight: FontWeight.bold,
          color: Colors.teal.shade400, // Fallback if AppTheme is causing issues
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
        color: Colors.indigo.shade800,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: ListTile(
        title: Text(title, style: const TextStyle(color: Colors.white)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white70)),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.teal.shade400,
        ),
      ),
    );
  }

  Widget _buildDropdownTile() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.indigo.shade800,
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
          dropdownColor: Colors.indigo.shade700,
          underline: Container(),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
          items:
              _durationOptions.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _recordingDuration = newValue;
              });
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
        color: Colors.indigo.shade800,
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
                  activeColor: Colors.teal.shade400,
                  inactiveColor: Colors.indigo.shade600,
                  onChanged: (double value) {
                    setState(() {
                      _sensitivityLevel = value;
                    });
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

  void _showSimpleAboutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.indigo.shade800,
          title: const Text(
            'About APNEA-AID',
            style: TextStyle(color: Colors.white),
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'APNEA-AID is an AI-powered sleep apnea detection app that monitors your breathing patterns during sleep.',
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 16),
              Text(
                'Disclaimer: This app is not a medical device and should not replace professional medical advice.',
                style: TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Close',
                style: TextStyle(color: Colors.teal.shade400),
              ),
            ),
          ],
        );
      },
    );
  }
}
