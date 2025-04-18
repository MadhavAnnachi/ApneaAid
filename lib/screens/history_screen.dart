import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/sleep_detector_service.dart';
import '../widgets/sleep_record_card.dart';
import '../models/sleep_record.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final SleepDetectorService _sleepDetectorService = SleepDetectorService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Sleep History'),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<List<SleepRecord>>(
        stream: _sleepDetectorService.recordsStream,
        initialData: _sleepDetectorService.getRecords(),
        builder: (context, snapshot) {
          final records = snapshot.data ?? [];

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: records.length,
            itemBuilder:
                (context, index) => SleepRecordCard(record: records[index]),
          );
        },
      ),
    );
  }
}
