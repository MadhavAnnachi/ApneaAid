import 'dart:async';
import 'package:intl/intl.dart';
import '../models/sleep_record.dart';
import 'package:flutter/foundation.dart';
import 'settings_service.dart';

// Static variable to hold all records across app for direct access
List<SleepRecord> globalSleepRecords = [];

// Permanent hardcoded preset records that are always available
final List<SleepRecord> presetRecords = [
  // Mixed severity examples with more natural distribution
  SleepRecord(
    date: 'Apr 2, 2025',
    duration: 7.3,
    irregularities: 5,
    severity: 'Medium',
    id: 'preset-1',
  ),
  SleepRecord(
    date: 'Apr 5, 2025',
    duration: 5.1,
    irregularities: 25,
    severity: 'High',
    id: 'preset-2',
  ),
  SleepRecord(
    date: 'Apr 7, 2025',
    duration: 8.2,
    irregularities: 2,
    severity: 'Low',
    id: 'preset-3',
  ),
  SleepRecord(
    date: 'Apr 9, 2025',
    duration: 6.7,
    irregularities: 18,
    severity: 'Medium',
    id: 'preset-4',
  ),
  SleepRecord(
    date: 'Apr 11, 2025',
    duration: 7.9,
    irregularities: 3,
    severity: 'Low',
    id: 'preset-5',
  ),
  SleepRecord(
    date: 'Apr 14, 2025',
    duration: 4.5,
    irregularities: 31,
    severity: 'High',
    id: 'preset-6',
  ),
];

class SleepDetectorService {
  // Singleton instance
  static final SleepDetectorService _instance = SleepDetectorService._internal();
  
  // Factory constructor to return the same instance
  factory SleepDetectorService() {
    return _instance;
  }
  
  // Private constructor for singleton
  SleepDetectorService._internal() {
    debugPrint("🛠️ SleepDetectorService: private constructor called");
    // Create streams immediately in the constructor
    _irregularitiesController = StreamController<int>.broadcast();
    _recordsController = StreamController<List<SleepRecord>>.broadcast();
    
    // Initialize with preset records regardless of whether records is empty
    _initPresetRecords();
    
    // Initialize settings service
    _settingsService = SettingsService();
    
    // Listen for settings changes
    _settingsService.settingsStream.listen(_handleSettingsChange);
  }
  
  // Handle settings changes
  void _handleSettingsChange(Map<String, dynamic> settings) {
    // Update local settings based on user preferences
    _sensitivityLevel = settings['sensitivity_level'];
    
    // Parse recording duration
    final durationString = settings['recording_duration'];
    if (durationString == 'Until stopped') {
      _recordingDurationHours = null; // Unlimited duration
    } else {
      // Extract hours from string like "8 hours"
      final hoursStr = durationString.split(' ').first;
      _recordingDurationHours = double.tryParse(hoursStr) ?? 8.0;
    }
    
    // Log settings update
    debugPrint("🛠️ SleepDetectorService: Settings updated - sensitivity: $_sensitivityLevel, duration: $_recordingDurationHours");
  }
  
  void _initPresetRecords() {
    // Clear existing records to prevent duplicates when app restarts
    globalSleepRecords.clear();
    
    // Add preset records that are always available
    globalSleepRecords.addAll(presetRecords);
    
    debugPrint("🛠️ SleepDetectorService: ${globalSleepRecords.length} preset records loaded");
    
    // Emit initial data
    try {
      _recordsController.add(List<SleepRecord>.from(globalSleepRecords));
    } catch (e) {
      debugPrint("🛠️ SleepDetectorService ERROR: Failed to add records to stream: $e");
    }
  }
  
  bool _isRecording = false;
  int _irregularities = 0;
  DateTime? _recordingStartTime;
  bool _isInitialized = false;
  
  // Settings from SettingsService
  late final SettingsService _settingsService;
  double _sensitivityLevel = 2.0; // Default medium sensitivity
  double? _recordingDurationHours = 8.0; // Default 8 hours, null means unlimited
  
  // Controllers for streams - late initialization
  late final StreamController<int> _irregularitiesController;
  late final StreamController<List<SleepRecord>> _recordsController;
  
  // Getters
  Stream<int> get irregularitiesStream => _irregularitiesController.stream;
  Stream<List<SleepRecord>> get recordsStream => _recordsController.stream;
  bool get isRecording => _isRecording;
  int get irregularities => _irregularities;
  
  // Start recording - can be triggered manually or automatically
  void startRecording() {
    if (_isRecording) return;
    
    debugPrint("🛠️ SleepDetectorService: Recording started with sensitivity: $_sensitivityLevel");
    
    _isRecording = true;
    _irregularities = 0;
    _recordingStartTime = DateTime.now();
    _irregularitiesController.add(_irregularities);
    
    // Start detecting irregularities
    _startDetectingIrregularities();
    
    // Set up automatic stop if duration is specified
    if (_recordingDurationHours != null) {
      final durationMs = (_recordingDurationHours! * 60 * 60 * 1000).toInt();
      Future.delayed(Duration(milliseconds: durationMs), () {
        if (_isRecording) {
          debugPrint("🛠️ SleepDetectorService: Auto-stopping after $_recordingDurationHours hours");
          stopRecording();
        }
      });
    }
  }
  
  // Stop recording
  SleepRecord? stopRecording() {
    if (!_isRecording || _recordingStartTime == null) return null;
    
    _isRecording = false;
    final now = DateTime.now();
    final recordingDuration = now.difference(_recordingStartTime!);
    
    // Calculate duration in hours
    final durationHours = recordingDuration.inMinutes / 60;
    
    // Format the date
    final formattedDate = DateFormat('MMM d, yyyy').format(_recordingStartTime!);
    
    // Determine severity based on irregularity count and sensitivity
    final String severity = _calculateSeverity(_irregularities, _sensitivityLevel);
    
    // Create new record
    final newRecord = SleepRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: formattedDate,
      duration: double.parse(durationHours.toStringAsFixed(1)),
      irregularities: _irregularities,
      severity: severity,
    );
    
    // Add to global records
    globalSleepRecords.insert(0, newRecord);
    
    // Emit updated records
    _recordsController.add(List<SleepRecord>.from(globalSleepRecords));
    
    debugPrint("🛠️ SleepDetectorService: Recording stopped, created record with ${_irregularities} irregularities, severity: $severity");
    
    return newRecord;
  }
  
  // Calculate severity based on irregularities and sensitivity
  String _calculateSeverity(int irregularities, double sensitivity) {
    // Adjust thresholds based on sensitivity level
    int lowThreshold, highThreshold;
    
    switch (sensitivity.round()) {
      case 1: // Low sensitivity
        lowThreshold = 10;
        highThreshold = 25;
        break;
      case 3: // High sensitivity
        lowThreshold = 3;
        highThreshold = 10;
        break;
      case 2: // Medium sensitivity (default)
      default:
        lowThreshold = 5;
        highThreshold = 15;
        break;
    }
    
    // Determine severity
    if (irregularities >= highThreshold) {
      return 'High';
    } else if (irregularities >= lowThreshold) {
      return 'Medium';
    } else {
      return 'Low';
    }
  }
  
  // Simulates detection of irregularities during sleep
  void _startDetectingIrregularities() {
    if (!_isRecording) return;
    
    // Random irregularity detection simulation
    // Higher sensitivity produces more detected irregularities
    final detectionInterval = 
        _sensitivityLevel == 1.0 ? 15000 : // Low sensitivity: slower detection
        _sensitivityLevel == 3.0 ? 5000 :  // High sensitivity: faster detection
        10000;                             // Medium sensitivity: normal detection
    
    Future.delayed(Duration(milliseconds: detectionInterval), () {
      if (_isRecording) {
        // Randomly determine if an irregularity is detected
        // Higher sensitivity increases chance of detection
        final detectionRate = 
            _sensitivityLevel == 1.0 ? 0.3 : // Low sensitivity: 30% chance
            _sensitivityLevel == 3.0 ? 0.7 : // High sensitivity: 70% chance
            0.5;                             // Medium sensitivity: 50% chance
        
        if (detectionRate > 0.5) {
          _irregularities++;
          _irregularitiesController.add(_irregularities);
          debugPrint("🛠️ SleepDetectorService: Irregularity detected - Total: $_irregularities");
        }
        
        // Continue detecting
        _startDetectingIrregularities();
      }
    });
  }
  
  // Get record by ID
  SleepRecord? getRecordById(String id) {
    try {
      return globalSleepRecords.firstWhere((record) => record.id == id);
    } catch (e) {
      return null;
    }
  }
  
  // Refresh streams with current data
  void refreshStreams() {
    _irregularitiesController.add(_irregularities);
    _recordsController.add(List<SleepRecord>.from(globalSleepRecords));
  }
  
  // Dispose resources
  void dispose() {
    _irregularitiesController.close();
    _recordsController.close();
  }
}
