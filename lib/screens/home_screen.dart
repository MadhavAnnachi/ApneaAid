import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';
import '../services/sleep_detector_service.dart';
import '../models/sleep_record.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import '../screens/profile_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final SleepDetectorService _sleepDetectorService = SleepDetectorService();
  final AuthService _authService = AuthService();
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;
  
  // Add recording duration tracking
  DateTime? _recordingStartedAt;
  Timer? _recordingTimer;
  String _recordingDuration = "00:00";
  
  // Last sleep sessions data
  List<SleepRecord> _recentRecords = [];
  StreamSubscription? _recordsSubscription;
  StreamSubscription? _userSubscription;
  
  // User data
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    debugPrint("HomeScreen: initState called");
    // Fix: Initialize animation controller first
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    // Then initialize animations that depend on it
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _rotationAnimation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.linear),
    );

    // Start the animation
    _animationController.repeat();

    // Make sure the service is ready
    _sleepDetectorService.init();
    
    // Load recent records and set up subscription for updates
    _setupRecordsHandling();
    
    // Set up user subscription
    _userSubscription = _authService.userStream.listen((user) {
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
      }
    });
    
    // Get current user immediately
    _currentUser = _authService.currentUser;
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    debugPrint("HomeScreen: didChangeDependencies called");
    // Refresh data when returning to this screen
    _loadRecentRecords();
  }
  
  void _setupRecordsHandling() {
    // Immediately load whatever records are available
    _loadRecentRecords();
    
    // Cancel any existing subscription
    _recordsSubscription?.cancel();
    
    // Set up a subscription to track changes
    _recordsSubscription = _sleepDetectorService.recordsStream.listen((records) {
      if (mounted) {
        debugPrint("HomeScreen: Received ${records.length} records from stream");
        setState(() {
          _recentRecords = records.cast<SleepRecord>().take(7).toList();
        });
      }
    }, onError: (error) {
      debugPrint("HomeScreen: Error receiving records: $error");
    });
    
    // Force an immediate refresh from the service to ensure we're up to date
    Future.microtask(() => _sleepDetectorService.refreshStreams());
  }
  
  void _loadRecentRecords() {
    // Get the most recent records for the visualizations
    final records = globalSleepRecords;
    setState(() {
      _recentRecords = records.cast<SleepRecord>().take(7).toList();
    });
    debugPrint("HomeScreen: Loaded ${_recentRecords.length} records directly from global list");
  }

  @override
  void dispose() {
    _animationController.dispose();
    _recordsSubscription?.cancel();
    _userSubscription?.cancel();
    _sleepDetectorService.dispose();
    _recordingTimer?.cancel();
    super.dispose();
  }

  void _toggleRecording() {
    try {
      // Reset animation controller to make dots start from beginning
      _animationController.reset();
      _animationController.repeat();
    
      if (_sleepDetectorService.isRecording) {
        _sleepDetectorService.stopRecording();
        _stopRecordingTimer();
        
        // Show a success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recording saved to history'),
            backgroundColor: AppTheme.primaryColor,
            duration: Duration(seconds: 2),
          ),
        );
        
        // Refresh the data
        _loadRecentRecords();
        
        // Navigate to history screen after a short delay
        Future.delayed(const Duration(milliseconds: 500), () {
          Navigator.pushNamed(context, '/history');
        });
      } else {
        _sleepDetectorService.startRecording();
        _startRecordingTimer();
      }
      setState(() {}); // Refresh UI
    } catch (e) {
      // Handle any errors silently to prevent red screen
      debugPrint("Error toggling recording: $e");
    }
  }
  
  void _startRecordingTimer() {
    _recordingStartedAt = DateTime.now();
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      
      final now = DateTime.now();
      final difference = now.difference(_recordingStartedAt!);
      
      setState(() {
        final minutes = difference.inMinutes.toString().padLeft(2, '0');
        final seconds = (difference.inSeconds % 60).toString().padLeft(2, '0');
        _recordingDuration = "$minutes:$seconds";
      });
    });
  }
  
  void _stopRecordingTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = null;
    _recordingStartedAt = null;
    _recordingDuration = "00:00";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Updated to pure black background like Opal
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Background gradient glow effect
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF4A2B82).withOpacity(0.5), // Deeper, more vibrant purple matching Opal
                      Colors.black.withOpacity(0.2),
                    ],
                    center: Alignment.topCenter,
                    radius: 0.9, // Slightly larger radius
                  ),
                ),
              ),
            ),
            
            // Add additional subtle purple glow elements
            Positioned(
              top: -50,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
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
            
            // Another subtle glow on the bottom
            Positioned(
              bottom: 100,
              left: -80,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF5E35B1).withOpacity(0.25), // Enhanced glow color
                      Colors.transparent,
                    ],
                    stops: const [0.2, 1.0],
                  ),
                ),
              ),
            ),

            SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 24),

                  // App title with updated styling
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Updated app title to be more modern
                        const Text(
                          'APNEA-AID',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        // Replace notification icon with profile avatar
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context, 
                              MaterialPageRoute(
                                builder: (context) => const ProfileScreen(),
                              ),
                            );
                          },
                          child: Hero(
                            tag: 'profile-avatar',
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryColor.withOpacity(0.4),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  _currentUser?.initials ?? '?',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Main content
                  StreamBuilder<int>(
                    stream: _sleepDetectorService.irregularitiesStream,
                    initialData: 0,
                    builder: (context, snapshot) {
                      final irregularities = snapshot.data ?? 0;

                      return Column(
                        children: [
                          const SizedBox(height: 40),

                          // Start button with enhanced glow effect (Opal-inspired)
                          GestureDetector(
                            onTap: _toggleRecording,
                            child: AnimatedBuilder(
                              animation: _animationController,
                              builder: (context, child) {
                                return Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Enhanced outer glow
                                    Transform.scale(
                                      scale:
                                          _sleepDetectorService.isRecording
                                              ? _pulseAnimation.value
                                              : 1.0,
                                      child: Container(
                                        width: 180,
                                        height: 180,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: RadialGradient(
                                            colors: [
                                              const Color(
                                                0xFF7C4DFF,
                                              ).withOpacity(0.4),
                                              const Color(
                                                0xFF7C4DFF,
                                              ).withOpacity(0.0),
                                            ],
                                            stops: const [0.4, 1.0],
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Main button - Opal-inspired gem effect
                                    Container(
                                      width: 140,
                                      height: 140,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Color(0xFF6A47BB), // More vibrant, Opal-like purple
                                            Color(0xFF4A2B82), // Deeper purple for dimension
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF6A47BB).withOpacity(0.6),
                                            blurRadius: 30,
                                            spreadRadius: 5,
                                          ),
                                        ],
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.4),
                                          width: 2,
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
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Rotating dots - only visible when recording
                                    if (_sleepDetectorService.isRecording)
                                      Transform.rotate(
                                        angle: _rotationAnimation.value,
                                        child: SizedBox(
                                          width: 180,
                                          height: 180,
                                          child: CustomPaint(
                                            painter: DottedCirclePainter(
                                              dotColor: Colors.white,
                                              dotSize: 3.5,
                                              numberOfDots: 24, // Increased dots for more elegant animation
                                              opacity: 1.0,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Statistics with enhanced styling
                          Column(
                            children: [
                              Text(
                                '$irregularities',
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                _sleepDetectorService.isRecording
                                    ? 'Recording $_recordingDuration'
                                    : 'Irregularities Detected',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _sleepDetectorService.isRecording
                                      ? Colors.redAccent
                                      : Colors.white70,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 40),

                          // Apnea events trend chart
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Apnea Events Trend',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  height: 180,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.1),
                                      width: 1,
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  child: _buildApneaEventsChart(),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 30),
                          
                          // Sleep duration trend
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Sleep Duration Trend',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  height: 180,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.1),
                                      width: 1,
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  child: _buildSleepDurationChart(),
                                ),
                              ],
                            ),
                          ),

                          // Add extra space at the bottom to ensure content isn't hidden by nav bar
                          const SizedBox(height: 80),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            // Fixed position bottom navigation - moved to bottom of screen
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(
                      Icons.settings_outlined,
                      'Settings',
                      false,
                      () {
                        Navigator.pushNamed(context, '/settings');
                      },
                    ),
                    _buildNavItem(Icons.home_rounded, 'Home', true, () {}),
                    _buildNavItem(Icons.trending_up_outlined, 'Trends', false, () {
                      Navigator.pushNamed(context, '/trends');
                    }),
                    _buildNavItem(Icons.history_outlined, 'History', false, () {
                      Navigator.pushNamed(context, '/history');
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Apnea events trend chart
  Widget _buildApneaEventsChart() {
    // If no records, show empty state
    if (_recentRecords.isEmpty) {
      return const Center(
        child: Text(
          'No sleep data available yet',
          style: TextStyle(color: Colors.white60),
        ),
      );
    }
    
    // Prepare data for the chart
    final List<BarChartGroupData> barGroups = [];
    final List<String> dates = [];
    
    // Sort the records by date (oldest to newest) for chronological display
    final displayRecords = List<SleepRecord>.from(_recentRecords);
    displayRecords.sort((a, b) {
      // Simple string comparison should work for 'MMM d, yyyy' format
      return a.date.compareTo(b.date);
    });
    
    for (var i = 0; i < displayRecords.length; i++) {
      final record = displayRecords[i];
      
      // Add date - show "Month Day" format instead of just month
      final dateParts = record.date.split(',')[0].split(' ');
      final shortDate = dateParts.length > 1 ? "${dateParts[0]} ${dateParts[1]}" : dateParts[0];
      dates.add(shortDate);
      
      // Add bar
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: record.irregularities.toDouble(),
              color: _getColorForSeverity(record.severity),
              width: 15,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
          ],
        ),
      );
    }
    
    debugPrint("HomeScreen Chart: Displaying ${displayRecords.length} records in apnea events chart");
    
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _getMaxIrregularities() * 1.2,
        barGroups: barGroups,
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 10,
          getDrawingHorizontalLine: _getGridLine,
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value >= 0 && value < dates.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      dates[value.toInt()],
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: _getLeftTitles,
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: const Color(0xFF6A47BB).withOpacity(0.8),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              if (groupIndex >= 0 && groupIndex < displayRecords.length) {
                final record = displayRecords[groupIndex];
                return BarTooltipItem(
                  '${record.date}\n${record.irregularities} events',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }
              return null;
            },
          ),
        ),
      ),
      swapAnimationDuration: const Duration(milliseconds: 300),
    );
  }
  
  // Sleep duration chart
  Widget _buildSleepDurationChart() {
    // If no records, show empty state
    if (_recentRecords.isEmpty) {
      return const Center(
        child: Text(
          'No sleep data available yet',
          style: TextStyle(color: Colors.white60),
        ),
      );
    }
    
    // Sort the records by date (oldest to newest) for chronological display
    final displayRecords = List<SleepRecord>.from(_recentRecords);
    displayRecords.sort((a, b) {
      return a.date.compareTo(b.date);
    });
    
    // Prepare data for the chart
    final List<FlSpot> spots = [];
    final List<String> dates = [];
    
    for (var i = 0; i < displayRecords.length; i++) {
      spots.add(FlSpot(i.toDouble(), displayRecords[i].duration));
      
      // Add date with "Month Day" format instead of just month
      final dateParts = displayRecords[i].date.split(',')[0].split(' ');
      final shortDate = dateParts.length > 1 ? "${dateParts[0]} ${dateParts[1]}" : dateParts[0];
      dates.add(shortDate);
    }
    
    debugPrint("HomeScreen Chart: Displaying ${displayRecords.length} records in sleep duration chart");
    
    return LineChart(
      LineChartData(
        gridData: const FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: _getGridLine,
          horizontalInterval: 2,
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < dates.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      dates[value.toInt()],
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: _getDurationTitles,
              reservedSize: 30,
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: displayRecords.length - 1.0,
        minY: 0,
        maxY: 10,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppTheme.primaryColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                final severity = displayRecords[index].severity;
                return FlDotCirclePainter(
                  radius: 4,
                  color: _getColorForSeverity(severity),
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withOpacity(0.5),
                  AppTheme.primaryColor.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: const Color(0xFF6A47BB).withOpacity(0.8),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final index = spot.x.toInt();
                if (index >= 0 && index < displayRecords.length) {
                  final record = displayRecords[index];
                  return LineTooltipItem(
                    '${record.date}\n${record.duration} hours',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }
                return null;
              }).toList();
            },
          ),
        ),
      ),
    );
  }
  
  // Helper methods
  static Widget _getLeftTitles(double value, TitleMeta meta) {
    if (value % 10 != 0) return const SizedBox();
    
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(
        value.toInt().toString(),
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 10,
        ),
      ),
    );
  }
  
  static Widget _getDurationTitles(double value, TitleMeta meta) {
    if (value % 2 != 0) return const SizedBox();
    
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(
        '${value.toInt()}h',
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 10,
        ),
      ),
    );
  }
  
  static FlLine _getGridLine(double value) {
    return FlLine(
      color: Colors.white10,
      strokeWidth: 1,
    );
  }
  
  Color _getColorForSeverity(String severity) {
    switch (severity.toLowerCase()) {
      case 'low':
        return AppTheme.lowRiskColor;
      case 'medium':
      case 'med':
        return AppTheme.mediumRiskColor;
      case 'high':
        return AppTheme.highRiskColor;
      default:
        return Colors.grey;
    }
  }
  
  double _getMaxIrregularities() {
    if (_recentRecords.isEmpty) return 10;
    
    return _recentRecords
        .map((r) => r.irregularities)
        .reduce((max, value) => max > value ? max : value)
        .toDouble();
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    bool isActive,
    VoidCallback onTap,
  ) {
    const Color activeColor = Color(0xFF6A47BB); // Updated to match Opal purple

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isActive ? activeColor : Colors.white60,
            size: isActive ? 28 : 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? activeColor : Colors.white60,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for the dotted circle animation
class DottedCirclePainter extends CustomPainter {
  final Color dotColor;
  final double dotSize;
  final int numberOfDots;
  final double opacity;

  DottedCirclePainter({
    required this.dotColor,
    required this.dotSize,
    required this.numberOfDots,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // Draw more dots - don't skip as many
    for (int i = 0; i < numberOfDots; i++) {
      // We now draw more dots - every other one instead of every third
      if (i % 2 == 0) {
        final angle = 2 * math.pi * i / numberOfDots;
        final offset = Offset(
          center.dx + radius * math.cos(angle),
          center.dy + radius * math.sin(angle),
        );

        // Vary dot opacity based on position for a more elegant look
        final dotOpacity = opacity * (0.4 + (0.6 * (i / numberOfDots)));
        paint.color = dotColor.withOpacity(dotOpacity);

        // Draw slightly smaller dots
        canvas.drawCircle(offset, dotSize * 0.8, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant DottedCirclePainter oldDelegate) => 
    oldDelegate.opacity != opacity || 
    oldDelegate.dotSize != dotSize;
}
