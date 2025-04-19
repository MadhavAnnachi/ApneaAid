import 'package:flutter/material.dart';
import 'dart:async';
import '../services/sleep_detector_service.dart';
import '../widgets/sleep_record_card.dart';
import '../models/sleep_record.dart';
import '../theme/app_theme.dart';
import 'package:flutter/foundation.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with WidgetsBindingObserver {
  final SleepDetectorService _sleepDetectorService = SleepDetectorService();
  bool _isLoading = false;
  String _errorMessage = '';
  StreamSubscription? _recordsSubscription;

  @override
  void initState() {
    super.initState();
    debugPrint("🔍 History Screen: initState");
    WidgetsBinding.instance.addObserver(this);
    
    // Ensure service is initialized
    _sleepDetectorService.init();
    
    // Manually force a refresh of all streams in the service
    _sleepDetectorService.refreshStreams();
    
    // Listen for updates
    _setupStreamListener();
  }
  
  @override
  void dispose() {
    debugPrint("🔍 History Screen: dispose");
    WidgetsBinding.instance.removeObserver(this);
    _recordsSubscription?.cancel();
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh when coming back to this screen
      debugPrint("🔍 History Screen: resumed, refreshing");
      setState(() {}); // Just refresh the UI
    }
  }
  
  // Called when the screen is displayed
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when returning to this screen
    debugPrint("🔍 History Screen: didChangeDependencies called");
    setState(() {}); // Just refresh the UI
  }
  
  void _setupStreamListener() {
    // Cancel existing subscription
    _recordsSubscription?.cancel();
    
    // Listen to stream for updates
    _recordsSubscription = _sleepDetectorService.recordsStream.listen((updatedRecords) {
      if (mounted) {
        debugPrint("🔄 History Screen: Stream updated with ${updatedRecords.length} records");
        setState(() {});
      }
    }, onError: (error) {
      if (mounted) {
        debugPrint("❌ History Screen: Stream error: $error");
        setState(() {
          _errorMessage = 'Error: $error';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get records directly from global variable
    final records = List<SleepRecord>.from(globalSleepRecords);
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'Sleep History (${records.length})',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          // Add a refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _sleepDetectorService.refreshStreams();
              setState(() {});
            },
            tooltip: 'Refresh records',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background gradient glow effect
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF4A2B82).withOpacity(0.5), // Deeper, more vibrant purple
                    Colors.black.withOpacity(0.2),
                  ],
                  center: Alignment.topCenter,
                  radius: 0.9,
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
                    const Color(0xFF6A47BB).withOpacity(0.35), // Enhanced glow color
                    Colors.transparent,
                  ],
                  stops: const [0.2, 1.0],
                ),
              ),
            ),
          ),
          
          // Handle different states
          if (_isLoading)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: AppTheme.primaryColor,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading sleep records...',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            )
          else if (_errorMessage.isNotEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      _sleepDetectorService.refreshStreams();
                      setState(() {
                        _errorMessage = '';
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                    ),
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            )
          else if (records.isEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.nights_stay_outlined,
                    size: 64,
                    color: Colors.white.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No sleep records yet',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Start a recording session to track your sleep',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context); // Go back to home screen
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start Recording'),
                  ),
                ],
              ),
            )
          else
            RefreshIndicator(
              onRefresh: () async {
                debugPrint("🔄 History Screen: Pull-to-refresh triggered");
                _sleepDetectorService.refreshStreams();
                setState(() {});
              },
              color: AppTheme.primaryColor,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: records.length,
                itemBuilder: (context, index) => SleepRecordCard(
                  record: records[index],
                  key: ValueKey(records[index].id), // Use ID as key for better list updates
                ),
              ),
            ),
        ],
      ),
    );
  }
}
