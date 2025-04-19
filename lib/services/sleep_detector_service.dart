import 'dart:async';
import 'package:intl/intl.dart';
import '../models/sleep_record.dart';

class SleepDetectorService {
  bool _isRecording = false;
  int _irregularities = 0;
  final List<SleepRecord> _records = [];
  DateTime? _recordingStartTime;
  
  // Controllers for streams
  final _irregularitiesController = StreamController<int>.broadcast();
  final _recordsController = StreamController<List<SleepRecord>>.broadcast();

  // Mock data for initial load
  SleepDetectorService() {
    _records.addAll([
      SleepRecord(
        date: 'Apr 18, 2025',
        duration: 8.0,
        irregularities: 0,
        severity: 'Low',
        id: '',
      ),
      SleepRecord(
        date: 'Apr 17, 2025',
        duration: 7.5,
        irregularities: 12,
        severity: 'Medium',
        id: '',
      ),
      SleepRecord(
        date: 'Apr 16, 2025',
        duration: 6.0,
        irregularities: 28,
        severity: 'High',
        id: '',
      ),
    ]);
  }

  // Initialize service (can be used for permissions or setup)
  void init() {
    // Initialize necessary components
    // For MVP, we're just setting up streams
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

    // Simulate irregularities detection with more frequent updates
    Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!_isRecording) {
        timer.cancel();
        return;
      }

      // Random chance to detect an irregularity (apnea event)
      // More realistic simulation with varying probabilities
      final random = DateTime.now().millisecondsSinceEpoch % 100;
      
      // Approximately 15% chance of detecting an irregularity each check
      if (random < 15) {
        // Sometimes detect multiple irregularities at once (simulating clustered events)
        final eventCount = random < 3 ? 2 : 1; // 3% chance of detecting 2 events at once
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

    // Create a new record
    final newRecord = SleepRecord(
      date: formattedDate,
      duration: double.parse(duration.toStringAsFixed(1)), // Round to 1 decimal place
      irregularities: _irregularities,
      severity: _getSeverity(_irregularities),
      id: id,
    );

    _records.insert(0, newRecord);
    _recordsController.add(_records);
    
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
  List<SleepRecord> getRecords() => _records;

  // Check if recording
  bool get isRecording => _isRecording;

  // Dispose resources
  void dispose() {
    _irregularitiesController.close();
    _recordsController.close();
  }
}
