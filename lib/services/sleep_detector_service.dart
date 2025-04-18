import 'dart:async';

import '../models/sleep_record.dart';

class SleepDetectorService {
  bool _isRecording = false;
  int _irregularities = 0;
  final List<SleepRecord> _records = [];

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
    _irregularitiesController.add(_irregularities);

    // Simulate irregularities detection
    Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_isRecording) {
        timer.cancel();
        return;
      }

      // Randomly increase irregularities (for demo purposes)
      if (DateTime.now().second % 10 == 0) {
        _irregularities++;
        _irregularitiesController.add(_irregularities);
      }
    });
  }

  // Stop recording
  void stopRecording() {
    if (!_isRecording) return;

    _isRecording = false;

    // Create a new record
    final newRecord = SleepRecord(
      date: DateTime.now().toString().substring(0, 10),
      duration: 8.0, // Mock duration
      irregularities: _irregularities,
      severity: _getSeverity(_irregularities),
      id: '',
    );

    _records.insert(0, newRecord);
    _recordsController.add(_records);
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
