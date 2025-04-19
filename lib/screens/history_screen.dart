import 'package:flutter/material.dart';
import '../services/sleep_detector_service.dart';
import '../widgets/sleep_record_card.dart';
import '../models/sleep_record.dart';
import '../theme/app_theme.dart';

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
        title: const Text(
          'Sleep History',
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
                    Colors.deepPurple.withOpacity(0.25),
                    Colors.black.withOpacity(0.0),
                  ],
                  center: Alignment.topCenter,
                  radius: 0.8,
                ),
              ),
            ),
          ),
          
          // Add subtle side glow
          Positioned(
            top: 150,
            right: -100,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF7C4DFF).withOpacity(0.15),
                    Colors.transparent,
                  ],
                  stops: const [0.2, 1.0],
                ),
              ),
            ),
          ),
          
          StreamBuilder<List<SleepRecord>>(
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
        ],
      ),
    );
  }
}
