import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';
import '../services/sleep_detector_service.dart';
import '../models/sleep_record.dart';
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
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;
  
  // Add recording duration tracking
  DateTime? _recordingStartedAt;
  Timer? _recordingTimer;
  String _recordingDuration = "00:00";

  // Hourly data for the bar chart - simplified to make visualization clearer
  final List<double> hourlyData = [
    0.2,
    0.3,
    0.1,
    0.2,
    0.1,
    0.3,
    0.7,
    0.2,
    0.3,
    0.5,
    0.2,
    0.3,
    0.1,
    0.2,
    0.8,
    0.3,
    0.1,
    0.2,
    0.3,
    0.1,
    0.2,
    0.1,
    0.2,
    0.1,
  ];

  // Mock data for the sleep quality graph - corrected to remove duplicates
  final List<FlSpot> weeklyData = [
    const FlSpot(0, 5), // Monday
    const FlSpot(1, 6), // Tuesday
    const FlSpot(2, 8), // Wednesday
    const FlSpot(3, 6), // Thursday
    const FlSpot(4, 6), // Friday
    const FlSpot(5, 7), // Saturday
    const FlSpot(6, 6), // Sunday
  ];

  // Day labels for the weekly chart
  final List<String> weekDays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  @override
  void initState() {
    super.initState();
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
  }

  @override
  void dispose() {
    _animationController.dispose();
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
                        // Notification icon with more elegant styling
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.notifications_none_outlined,
                            color: Colors.white70,
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

                          // Hourly activity bars (improved visualization)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Hourly Apnea Events',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.1),
                                      width: 1,
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: List.generate(
                                      hourlyData.length,
                                      (index) => Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 1,
                                          ),
                                          child: Column(
                                            children: [
                                              Expanded(
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                  ),
                                                  width: double.infinity,
                                                  alignment:
                                                      Alignment.bottomCenter,
                                                  child: FractionallySizedBox(
                                                    heightFactor:
                                                        hourlyData[index],
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        color: _getBarColor(
                                                          hourlyData[index],
                                                        ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              2,
                                                            ),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: _getBarColor(
                                                              hourlyData[index],
                                                            ).withOpacity(0.6),
                                                            blurRadius: 4,
                                                            spreadRadius: 0,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              // Show hour labels every 6 hours
                                              if (index % 6 == 0)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 4,
                                                      ),
                                                  child: Text(
                                                    '${index}h',
                                                    style: TextStyle(
                                                      color: Colors.white
                                                          .withOpacity(0.6),
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 40),

                          // Weekly graph (fixed day labels)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Weekly Sleep Quality',
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
                                  child: LineChart(
                                    LineChartData(
                                      gridData: FlGridData(
                                        show: true,
                                        drawVerticalLine: true,
                                        horizontalInterval: 2,
                                        verticalInterval: 1,
                                        getDrawingHorizontalLine: (value) {
                                          return const FlLine(
                                            color: Colors.white10,
                                            strokeWidth: 1,
                                          );
                                        },
                                        getDrawingVerticalLine: (value) {
                                          return const FlLine(
                                            color: Colors.white10,
                                            strokeWidth: 1,
                                          );
                                        },
                                      ),
                                      titlesData: FlTitlesData(
                                        leftTitles: const AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: false,
                                          ),
                                        ),
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            getTitlesWidget: (value, meta) {
                                              const style = TextStyle(
                                                color: Colors.white54,
                                                fontSize: 11,
                                              );

                                              if (value.toInt() >= 0 &&
                                                  value.toInt() <
                                                      weekDays.length) {
                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 8.0,
                                                      ),
                                                  child: Text(
                                                    weekDays[value.toInt()],
                                                    style: style,
                                                  ),
                                                );
                                              }
                                              return const Text(
                                                '',
                                                style: style,
                                              );
                                            },
                                            reservedSize: 30,
                                          ),
                                        ),
                                        rightTitles: const AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: false,
                                          ),
                                        ),
                                        topTitles: const AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: false,
                                          ),
                                        ),
                                      ),
                                      borderData: FlBorderData(show: false),
                                      minX: 0,
                                      maxX: 6,
                                      minY: 0,
                                      maxY: 10,
                                      lineBarsData: [
                                        LineChartBarData(
                                          spots: weeklyData,
                                          isCurved: true,
                                          color: const Color(0xFF6A47BB),
                                          barWidth: 3,
                                          isStrokeCapRound: true,
                                          dotData: FlDotData(
                                            show: true,
                                            getDotPainter: (
                                              spot,
                                              percent,
                                              barData,
                                              index,
                                            ) {
                                              Color dotColor = const Color(
                                                0xFF6A47BB,
                                              );
                                              // Highlight the last dot (today)
                                              if (index ==
                                                  weeklyData.length - 1) {
                                                dotColor = Colors.white;
                                              }
                                              return FlDotCirclePainter(
                                                radius:
                                                    index ==
                                                            weeklyData.length -
                                                                1
                                                        ? 4
                                                        : 3,
                                                color: dotColor,
                                                strokeWidth: 2,
                                                strokeColor: const Color(
                                                  0xFF6A47BB,
                                                ),
                                              );
                                            },
                                          ),
                                          belowBarData: BarAreaData(
                                            show: true,
                                            gradient: LinearGradient(
                                              colors: [
                                                const Color(
                                                  0xFF6A47BB,
                                                ).withOpacity(0.5),
                                                const Color(
                                                  0xFF6A47BB,
                                                ).withOpacity(0.0),
                                              ],
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                            ),
                                          ),
                                        ),
                                      ],
                                      lineTouchData: LineTouchData(
                                        touchTooltipData: LineTouchTooltipData(
                                          tooltipBgColor: const Color(
                                            0xFF6A47BB,
                                          ).withOpacity(0.8),
                                          getTooltipItems: (touchedSpots) {
                                            return touchedSpots.map((
                                              touchedSpot,
                                            ) {
                                              return LineTooltipItem(
                                                'Score: ${touchedSpot.y.toInt()}',
                                                const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              );
                                            }).toList();
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
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

  // Get color based on value with enhanced colors
  Color _getBarColor(double value) {
    if (value < 0.3) {
      return const Color(0xFF6A47BB); // Opal purple
    } else if (value < 0.6) {
      return const Color(0xFFFFD166); // Amber (unchanged)
    } else {
      return const Color(0xFFFF5677); // Pinkish-Red (unchanged)
    }
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
