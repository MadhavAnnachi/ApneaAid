import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/sleep_record.dart';

class SleepRecordDetailScreen extends StatelessWidget {
  final SleepRecord record;

  const SleepRecordDetailScreen({Key? key, required this.record})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Sleep Record: ${record.date}'),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCard(),
            const SizedBox(height: 24),
            _buildSeverityInfo(),
            const SizedBox(height: 24),
            _buildSymptomsInfo(),
            const SizedBox(height: 24),
            _buildRecommendations(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      color: AppTheme.cardColor,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                _buildSeverityTag(record.severity),
              ],
            ),
            const Divider(color: Colors.white24),
            const SizedBox(height: 8),
            _buildSummaryItem('Date', record.date),
            _buildSummaryItem('Irregularities', '${record.irregularities}'),
            _buildSummaryItem('Duration', '${record.duration} hours'),
            _buildSummaryItem('Sleep Quality', _getSleepQuality()),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeverityInfo() {
    return Card(
      color: AppTheme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'What This Means',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getSeverityDescription(),
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSymptomsInfo() {
    return Card(
      color: AppTheme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Common Symptoms',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            ..._getSymptomsList().map((symptom) => _buildSymptomItem(symptom)),
          ],
        ),
      ),
    );
  }

  Widget _buildSymptomItem(String symptom) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.circle, size: 8, color: Colors.white70),
          const SizedBox(width: 8),
          Expanded(
            child: Text(symptom, style: const TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
    return Card(
      color: AppTheme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recommendations',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getRecommendations(),
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            const Text(
              'Disclaimer: This app is not a medical device and should not replace professional medical advice.',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
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

  String _getSleepQuality() {
    switch (record.severity.toLowerCase()) {
      case 'low':
        return 'Good';
      case 'med':
      case 'medium':
        return 'Fair';
      case 'high':
        return 'Poor';
      default:
        return 'Unknown';
    }
  }

  String _getSeverityDescription() {
    switch (record.severity.toLowerCase()) {
      case 'low':
        return 'Your sleep pattern shows minimal irregularities. This suggests a low risk of sleep apnea. Continue monitoring your sleep to maintain awareness of your sleep health.';
      case 'med':
      case 'medium':
        return 'Your sleep pattern shows some irregularities that may indicate mild to moderate sleep-disordered breathing. Consider consulting with a healthcare provider if you are experiencing daytime symptoms.';
      case 'high':
        return 'Your sleep pattern shows significant irregularities that may indicate severe sleep-disordered breathing. It is recommended that you consult with a healthcare provider for proper evaluation and diagnosis.';
      default:
        return 'Unable to determine severity level for this sleep record.';
    }
  }

  List<String> _getSymptomsList() {
    switch (record.severity.toLowerCase()) {
      case 'low':
        return [
          'Occasional loud snoring',
          'Mild morning headaches',
          'Slight daytime fatigue',
        ];
      case 'med':
      case 'medium':
        return [
          'Regular loud snoring',
          'Noticeable breathing pauses during sleep',
          'Morning headaches',
          'Daytime sleepiness',
          'Difficulty concentrating',
          'Irritability',
        ];
      case 'high':
        return [
          'Chronic loud snoring',
          'Frequent observed breathing pauses during sleep',
          'Gasping or choking during sleep',
          'Excessive daytime sleepiness',
          'Morning headaches',
          'Difficulty concentrating',
          'Mood changes',
          'High blood pressure',
          'Decreased libido',
          'Night sweats',
        ];
      default:
        return ['No symptoms information available'];
    }
  }

  String _getRecommendations() {
    switch (record.severity.toLowerCase()) {
      case 'low':
        return 'Continue monitoring your sleep patterns. Consider lifestyle changes such as maintaining a healthy weight, regular exercise, and consistent sleep schedule.';
      case 'med':
      case 'medium':
        return 'Consider consulting with a healthcare provider for further evaluation. In the meantime, avoid alcohol and sedatives before bedtime, maintain a healthy weight, and try sleeping on your side instead of your back.';
      case 'high':
        return 'It is strongly recommended that you consult with a healthcare provider or sleep specialist for proper evaluation and diagnosis. Sleep apnea is a serious condition that may require treatment such as CPAP therapy or other interventions.';
      default:
        return 'No specific recommendations available.';
    }
  }
}
