import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/sleep_detector_service.dart';
import '../widgets/sleep_record_card.dart';
import '../models/sleep_record.dart'; // Ensure SleepRecord is imported from the correct file

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final SleepDetectorService _sleepDetectorService = SleepDetectorService();
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _sleepDetectorService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // App title
            Text('APNEA-AID', style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 30),

            // Main content
            Expanded(
              child: StreamBuilder<int>(
                stream: _sleepDetectorService.irregularitiesStream,
                initialData: 0,
                builder: (context, snapshot) {
                  final irregularities = snapshot.data ?? 0;

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Start button
                      GestureDetector(
                        onTap: _toggleRecording,
                        child: AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale:
                                  _sleepDetectorService.isRecording
                                      ? _pulseAnimation.value
                                      : 1.0,
                              child: Container(
                                width: 180,
                                height: 180,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.primaryColor,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primaryColor.withOpacity(
                                        0.3,
                                      ),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                  border: Border.all(
                                    color: AppTheme.accentColor,
                                    width: 4,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    _sleepDetectorService.isRecording
                                        ? 'STOP'
                                        : 'START',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Statistics
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              Text(
                                '$irregularities',
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const Text(
                                'Irregularities',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),

            // Recent records
            Expanded(
              child: StreamBuilder<List<SleepRecord>>(
                stream: _sleepDetectorService.recordsStream,
                initialData: _sleepDetectorService.getRecords(),
                builder: (context, snapshot) {
                  final records = snapshot.data ?? [];

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: records.length,
                    itemBuilder: (context, index) {
                      return SleepRecordCard(record: records[index]);
                    },
                  );
                },
              ),
            ),

            // Bottom navigation
            Container(
              height: 60,
              color: AppTheme.backgroundColor.withOpacity(0.8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white70),
                    onPressed: () {
                      Navigator.pushNamed(context, '/settings');
                    },
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.home,
                      color: AppTheme.primaryColor,
                      size: 32,
                    ),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.history, color: Colors.white70),
                    onPressed: () {
                      Navigator.pushNamed(context, '/history');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleRecording() {
    if (_sleepDetectorService.isRecording) {
      _sleepDetectorService.stopRecording();
    } else {
      _sleepDetectorService.startRecording();
    }
  }
}
