import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/sleep_detector_service.dart';
import '../widgets/sleep_record_card.dart';
import '../models/sleep_record.dart'; // Ensure SleepRecord is imported

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
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Sleep History'),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
      ),
      body: StreamBuilder<List<SleepRecord>>(
        stream: _sleepDetectorService.recordsStream,
        initialData: _sleepDetectorService.getRecords(),
        builder: (context, snapshot) {
          final records = snapshot.data ?? [];
          
          if (records.isEmpty) {
            return const Center(
              child: Text('No sleep records yet'),
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: records.length,
            itemBuilder: (context, index) {
              return SleepRecordCard(record: records[index]);
            },
          );
        },
      ),
    );
  }
}