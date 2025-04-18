import 'dart:async';
import 'dart:math';
import 'package:intl/intl.dart';
import '../models/sleep_record.dart';

class SleepDetectorService {
  bool _isRecording = false;
  final StreamController<int> _irregularitiesController =
      StreamController<int>.broadcast();
  final StreamController<List<SleepRecord>> _recordsController =
      StreamController<List<SleepRecord>>.broadcast();

  // In-memory storage for records (would be replaced with a database in a real app)
  final List<SleepRecord> _records = [];

  // Current session data
  int _currentIrregularities = 0;
  Timer? _simulationTimer;

  SleepDetectorService() {
    // Initialize with some sample data
    _initializeSampleData();
  }

  void _initializeSampleData() {
    // Today's date
    final now = DateTime.now();
    final dateFormat = DateFormat('MMM d, yyyy');

    // Add some sample records for the past few days
    for (int i = 0; i < 4; i++) {
      final date = now.subtract(Duration(days: i));
      final dateStr = dateFormat.format(date);

      // Generate irregularities based on a pattern
      final irregularities = 5 + (i % 3 == 0 ? 1 : (i % 3 == 1 ? 2 : 3));

      // Determine severity based on irregularities
      String severity;
      if (irregularities < 6) {
        severity = 'LOW';
      } else if (irregularities < 8) {
        severity = 'MED';
      } else {
        severity = 'HIGH';
      }

      _records.add(
        SleepRecord(
          id: 'record_${date.millisecondsSinceEpoch}',
          date: dateStr,
          irregularities: irregularities,
          severity: severity,
          duration: 8.0,
        ),
      );
    }

    // Add records to stream
    _recordsController.add(_records);
  }

  Stream<int> get irregularitiesStream => _irregularitiesController.stream;
  Stream<List<SleepRecord>> get recordsStream => _recordsController.stream;
  bool get isRecording => _isRecording;

  void startRecording() {
    if (_isRecording) return;

    _isRecording = true;
    _currentIrregularities = 0;
    _irregularitiesController.add(_currentIrregularities);

    // Simulate detecting irregularities
    _simulationTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      // Simulate detecting an irregularity occasionally
      if (Random().nextInt(3) == 0) {
        _currentIrregularities++;
        _irregularitiesController.add(_currentIrregularities);
      }
    });
  }

  void stopRecording() {
    if (!_isRecording) return;

    _isRecording = false;
    _simulationTimer?.cancel();

    // Save the recording
    final now = DateTime.now();
    final dateFormat = DateFormat('MMM d, yyyy');

    // Determine severity based on irregularities
    String severity;
    if (_currentIrregularities < 6) {
      severity = 'LOW';
    } else if (_currentIrregularities < 8) {
      severity = 'MED';
    } else {
      severity = 'HIGH';
    }

    final record = SleepRecord(
      id: 'record_${now.millisecondsSinceEpoch}',
      date: dateFormat.format(now),
      irregularities: _currentIrregularities,
      severity: severity,
      duration: 8.0,
    );

    _records.insert(0, record);
    _recordsController.add(_records);

    // Reset current irregularities
    _currentIrregularities = 0;
    _irregularitiesController.add(_currentIrregularities);
  }

  List<SleepRecord> getRecords() {
    return _records;
  }

  void dispose() {
    _irregularitiesController.close();
    _recordsController.close();
    _simulationTimer?.cancel();
  }
}
