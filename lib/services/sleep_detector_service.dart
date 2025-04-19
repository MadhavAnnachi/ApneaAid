import 'dart:async';
import 'package:intl/intl.dart';
import '../models/sleep_record.dart';
import 'package:flutter/foundation.dart';

// Static variable to hold all records across app for direct access
List<SleepRecord> globalSleepRecords = [];

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
    
    // Initialize records if not already set
    if (globalSleepRecords.isEmpty) {
      _initMockData();
    }
  }
  
  void _initMockData() {
    // Add mock data only if records is empty
    if (globalSleepRecords.isEmpty) {
      debugPrint("🛠️ SleepDetectorService: initializing mock data");
      globalSleepRecords.addAll([
        SleepRecord(
          date: 'Apr 18, 2025',
          duration: 8.0,
          irregularities: 0,
          severity: 'Low',
          id: '1',
        ),
        SleepRecord(
          date: 'Apr 17, 2025',
          duration: 7.5,
          irregularities: 12,
          severity: 'Medium',
          id: '2',
        ),
        SleepRecord(
          date: 'Apr 16, 2025',
          duration: 6.0,
          irregularities: 28,
          severity: 'High',
          id: '3',
        ),
      ]);
      
      // Emit initial data
      try {
        _recordsController.add(List<SleepRecord>.from(globalSleepRecords));
        debugPrint("🛠️ SleepDetectorService: ${globalSleepRecords.length} mock records added to stream");
      } catch (e) {
        debugPrint("🛠️ SleepDetectorService ERROR: Failed to add records to stream: $e");
      }
    }
  }
  
  bool _isRecording = false;
  int _irregularities = 0;
  DateTime? _recordingStartTime;
  bool _isInitialized = false;
  
  // Controllers for streams - late initialization
  late final StreamController<int> _irregularitiesController;
  late final StreamController<List<SleepRecord>> _recordsController;

  // Initialize service (can be used for permissions or setup)
  void init() {
    // Only initialize once
    if (_isInitialized) return;
    
    _isInitialized = true;
    
    // Immediately emit initial values on streams to unblock any waiting StreamBuilders
    Future.microtask(() {
      try {
        _recordsController.add(List<SleepRecord>.from(globalSleepRecords));
        _irregularitiesController.add(_irregularities);
        debugPrint("🔍 SleepDetectorService initialized with ${globalSleepRecords.length} records");
      } catch (e) {
        debugPrint("🛠️ SleepDetectorService ERROR during init: $e");
      }
    });
  }

  // Force a refresh of all streams - useful for debugging
  void refreshStreams() {
    debugPrint("🔄 SleepDetectorService: Manually refreshing streams");
    try {
      _recordsController.add(List<SleepRecord>.from(globalSleepRecords));
      _irregularitiesController.add(_irregularities);
    } catch (e) {
      debugPrint("🛠️ SleepDetectorService ERROR during refresh: $e");
    }
  }

  // Access streams
  Stream<int> get irregularitiesStream => _irregularitiesController.stream;
  Stream<List<SleepRecord>> get recordsStream => _recordsController.stream;

  // Start recording
  void startRecording() {
    if (_isRecording) return;

    _isRecording = true;
    _irregularities = 0;
    _recordingStartTime = DateTime.now();
    _irregularitiesController.add(_irregularities);
    
    debugPrint("🔴 Recording started at ${_recordingStartTime!.toString()}");

    // Simulate irregularities detection with more frequent updates
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isRecording) {
        timer.cancel();
        return;
      }

      // Random chance to detect an irregularity (apnea event)
      // More realistic simulation with varying probabilities
      final random = DateTime.now().millisecondsSinceEpoch % 100;
      
      // For MVP DEMO: Increase likelihood of events to ensure we see some
      // Approximately 25% chance of detecting an irregularity each check
      if (random < 25) {
        // Sometimes detect multiple irregularities at once (simulating clustered events)
        final eventCount = random < 5 ? 2 : 1; // 5% chance of detecting 2 events at once
        _irregularities += eventCount;
        _irregularitiesController.add(_irregularities);
      }
    });
  }

  // Stop recording
  void stopRecording() {
    if (!_isRecording) return;

    _isRecording = false;
    
    // Calculate duration in hours
    double duration = 0.0;
    if (_recordingStartTime != null) {
      final now = DateTime.now();
      final difference = now.difference(_recordingStartTime!);
      // Convert to hours with one decimal place
      duration = difference.inMinutes / 60.0;
      
      // For demo purposes, if recording duration is too short, make it at least 0.1 hours (6 minutes)
      duration = duration < 0.1 ? 0.1 : duration;
    } else {
      // If start time was somehow not recorded, use a default
      duration = 0.1;
    }
    
    // Format date nicely
    final dateFormat = DateFormat('MMM d, yyyy');
    final formattedDate = dateFormat.format(DateTime.now());
    
    // Generate a simple ID
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    // Create a new record - ensure we have at least a few irregularities for demo purposes
    final irregularitiesCount = _irregularities < 1 ? 3 + (id.hashCode % 10) : _irregularities;
    
    final newRecord = SleepRecord(
      date: formattedDate,
      duration: double.parse(duration.toStringAsFixed(1)), // Round to 1 decimal place
      irregularities: irregularitiesCount,
      severity: _getSeverity(irregularitiesCount),
      id: id,
    );

    // Add to records list at the beginning (most recent first)
    globalSleepRecords.insert(0, newRecord);
    
    // Create a new list to ensure reference changes
    final updatedRecords = List<SleepRecord>.from(globalSleepRecords);
    
    // Notify listeners about the updated records
    try {
      _recordsController.add(updatedRecords);
      debugPrint("🛑 Recording stopped. New record added to stream (${updatedRecords.length} total)");
    } catch (e) {
      debugPrint("🛠️ ERROR adding record to stream: $e");
    }
    
    // Debug log
    debugPrint("   - Date: ${newRecord.date}");
    debugPrint("   - Duration: ${newRecord.duration} hours");
    debugPrint("   - Irregularities: ${newRecord.irregularities}");
    debugPrint("   - Severity: ${newRecord.severity}");
    debugPrint("   - ID: ${newRecord.id}");
    
    // Reset recording start time
    _recordingStartTime = null;
  }

  // Get severity based on irregularities count
  String _getSeverity(int irregularities) {
    if (irregularities < 5) return 'Low';
    if (irregularities < 20) return 'Medium';
    return 'High';
  }

  // Get all records
  List<SleepRecord> getRecords() {
    debugPrint("📋 SleepDetectorService.getRecords() called, returning ${globalSleepRecords.length} records");
    return List<SleepRecord>.from(globalSleepRecords);
  }

  // Check if recording
  bool get isRecording => _isRecording;

  // Dispose resources (should only be called when app is closing)
  void dispose() {
    debugPrint("🚮 SleepDetectorService: dispose called");
    if (!_irregularitiesController.isClosed) {
      _irregularitiesController.close();
    }
    if (!_recordsController.isClosed) {
      _recordsController.close();
    }
  }
}
