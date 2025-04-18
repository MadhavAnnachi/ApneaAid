class SleepRecord {
  final String id;
  final String date;
  final int irregularities;
  final String severity;
  final double duration;

  SleepRecord({
    required this.id,
    required this.date,
    required this.irregularities,
    required this.severity,
    this.duration = 8.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'irregularities': irregularities,
      'severity': severity,
      'duration': duration,
    };
  }

  factory SleepRecord.fromMap(Map<String, dynamic> map) {
    return SleepRecord(
      id: map['id'] ?? '',
      date: map['date'] ?? '',
      irregularities: map['irregularities'] ?? 0,
      severity: map['severity'] ?? 'low',
      duration: map['duration']?.toDouble() ?? 8.0,
    );
  }
}
