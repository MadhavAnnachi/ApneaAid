import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/sleep_record.dart';
import '../screens/sleep_record_detail_screen.dart'; // Add this import

class SleepRecordCard extends StatelessWidget {
  final SleepRecord record;

  const SleepRecordCard({Key? key, required this.record}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.cardColor,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SleepRecordDetailScreen(record: record),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Display irregularities count instead of date format
              Text(
                '${record.irregularities}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.date,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              _buildSeverityTag(record.severity),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeverityTag(String severity) {
    Color color;
    switch (severity.toLowerCase()) {
      case 'low':
        color = AppTheme.lowRiskColor;
        break;
      case 'med':
      case 'medium':
        color = AppTheme.mediumRiskColor;
        break;
      case 'high':
        color = AppTheme.highRiskColor;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        severity.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
