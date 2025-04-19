import 'package:flutter/material.dart';
import 'dart:async'; // Add this import for StreamSubscription
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../models/sleep_record.dart';
import '../services/sleep_detector_service.dart';

class TrendsScreen extends StatefulWidget {
  const TrendsScreen({Key? key}) : super(key: key);

  @override
  State<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends State<TrendsScreen> with SingleTickerProviderStateMixin {
  final SleepDetectorService _sleepDetectorService = SleepDetectorService();
  late TabController _tabController;
  
  // View options
  bool _showIrregularities = true;
  bool _showDuration = true;
  bool _showSeverity = true;
  bool _showRecommendations = true;

  // Data
  List<SleepRecord> _allRecords = [];
  List<SleepRecord> _weeklyRecords = [];
  List<SleepRecord> _monthlyRecords = [];
  StreamSubscription? _recordsSubscription;
  
  // Analytics data
  Map<String, dynamic> _weeklyAnalytics = {};
  Map<String, dynamic> _monthlyAnalytics = {};
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Initialize service
    _sleepDetectorService.init();
    
    // Load initial data
    _loadRecordsData();
    
    // Set up subscription for data updates
    _setupDataSubscription();
  }
  
  void _setupDataSubscription() {
    // Cancel existing subscription if any
    _recordsSubscription?.cancel();
    
    // Subscribe to record updates
    _recordsSubscription = _sleepDetectorService.recordsStream.listen((records) {
      if (mounted) {
        setState(() {
          _loadRecordsData();
        });
      }
    });
  }
  
  void _loadRecordsData() {
    // Get all records and sort by date (newest first)
    _allRecords = List<SleepRecord>.from(globalSleepRecords);
    
    // Filter for weekly view (last 7 days)
    _weeklyRecords = _filterRecordsForPeriod(_allRecords, 7);
    
    // Filter for monthly view (last 30 days)
    _monthlyRecords = _filterRecordsForPeriod(_allRecords, 30);
    
    // Calculate analytics
    _weeklyAnalytics = _calculateAnalytics(_weeklyRecords);
    _monthlyAnalytics = _calculateAnalytics(_monthlyRecords);
    
    // Debug
    debugPrint("Trends: Loaded ${_allRecords.length} records (${_weeklyRecords.length} weekly, ${_monthlyRecords.length} monthly)");
  }
  
  List<SleepRecord> _filterRecordsForPeriod(List<SleepRecord> records, int days) {
    if (records.isEmpty) return [];
    
    // In a real app, we would filter based on actual date
    // For now, we'll just take the most recent records based on the order
    return records.take(days).toList();
  }
  
  Map<String, dynamic> _calculateAnalytics(List<SleepRecord> records) {
    if (records.isEmpty) {
      return {
        'avgIrregularities': 0.0,
        'avgDuration': 0.0,
        'lowCount': 0,
        'mediumCount': 0,
        'highCount': 0,
        'totalCount': 0,
        'improvement': 0.0,
        'trend': 'neutral',
        'recommendedActions': []
      };
    }
    
    // Calculate averages
    final avgIrregularities = records.map((r) => r.irregularities).reduce((a, b) => a + b) / records.length;
    final avgDuration = records.map((r) => r.duration).reduce((a, b) => a + b) / records.length;
    
    // Severity counts
    int lowCount = 0, mediumCount = 0, highCount = 0;
    for (final record in records) {
      switch (record.severity.toLowerCase()) {
        case 'low': lowCount++; break;
        case 'medium': case 'med': mediumCount++; break;
        case 'high': highCount++; break;
      }
    }
    
    // Calculate trend (improvement/deterioration)
    // For this demo, we compare the first half with the second half of records
    double improvement = 0.0;
    String trend = 'neutral';
    
    if (records.length >= 4) {
      final firstHalf = records.sublist(records.length ~/ 2);
      final secondHalf = records.sublist(0, records.length ~/ 2);
      
      final firstHalfAvg = firstHalf.map((r) => r.irregularities).reduce((a, b) => a + b) / firstHalf.length;
      final secondHalfAvg = secondHalf.map((r) => r.irregularities).reduce((a, b) => a + b) / secondHalf.length;
      
      // Calculate improvement percentage (negative means improvement, fewer irregularities)
      if (firstHalfAvg > 0) {
        improvement = (secondHalfAvg - firstHalfAvg) / firstHalfAvg * -100;
      }
      
      if (improvement > 5) trend = 'improving';
      else if (improvement < -5) trend = 'deteriorating';
    }
    
    // Generate recommended actions based on data
    final List<String> recommendedActions = [];
    
    if (avgDuration < 6.0) {
      recommendedActions.add('Aim for longer sleep periods (7-8 hours recommended)');
    }
    
    if (highCount > lowCount) {
      recommendedActions.add('Consult with a sleep specialist about your sleep apnea symptoms');
    }
    
    if (avgIrregularities > 10) {
      recommendedActions.add('Consider sleeping position changes (side sleeping often reduces apnea events)');
    }
    
    if (recommendedActions.isEmpty) {
      recommendedActions.add('Continue your current sleep patterns and monitoring');
    }
    
    return {
      'avgIrregularities': avgIrregularities,
      'avgDuration': avgDuration,
      'lowCount': lowCount,
      'mediumCount': mediumCount,
      'highCount': highCount,
      'totalCount': lowCount + mediumCount + highCount,
      'improvement': improvement,
      'trend': trend,
      'recommendedActions': recommendedActions
    };
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _recordsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Sleep Trends',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryColor,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'WEEKLY'),
            Tab(text: 'MONTHLY'),
            Tab(text: 'INSIGHTS'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterOptions,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background gradient effect
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF4A2B82).withOpacity(0.5),
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
            top: 50,
            right: -150,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF6A47BB).withOpacity(0.35),
                    Colors.transparent,
                  ],
                  stops: const [0.2, 1.0],
                ),
              ),
            ),
          ),
          
          // Main content
          TabBarView(
            controller: _tabController,
            children: [
              _buildWeeklyTrendsView(_weeklyRecords, _weeklyAnalytics),
              _buildMonthlyTrendsView(_monthlyRecords, _monthlyAnalytics),
              _buildInsightsView(_allRecords),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyTrendsView(List<SleepRecord> records, Map<String, dynamic> analytics) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Weekly summary card with trend indicators
          _buildEnhancedSummaryCard(records, analytics, 'Weekly'),
          const SizedBox(height: 24),
          
          // Irregularities graph
          if (_showIrregularities) ...[
            _buildSectionTitle('Apnea Events Pattern', icon: Icons.multiline_chart),
            const SizedBox(height: 8),
            _buildEnhancedIrregularitiesChart(records, isWeekly: true),
            const SizedBox(height: 24),
          ],
          
          // Sleep duration graph with severity overlay
          if (_showDuration) ...[
            _buildSectionTitle('Sleep Duration & Quality', icon: Icons.nightlight_round),
            const SizedBox(height: 8),
            _buildEnhancedDurationChart(records, isWeekly: true),
            const SizedBox(height: 24),
          ],
          
          // Sleep severity distribution
          if (_showSeverity) ...[
            _buildSectionTitle('Severity Distribution', icon: Icons.pie_chart),
            const SizedBox(height: 8),
            _buildSeverityPieChart(records),
            const SizedBox(height: 24),
          ],
          
          // Sleep pattern analysis
          if (_showRecommendations) ...[
            _buildSectionTitle('Weekly Analysis', icon: Icons.analytics),
            const SizedBox(height: 8),
            _buildSleepPatternAnalysis(records, analytics),
            const SizedBox(height: 40),
          ],
        ],
      ),
    );
  }

  Widget _buildMonthlyTrendsView(List<SleepRecord> records, Map<String, dynamic> analytics) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Monthly summary card
          _buildEnhancedSummaryCard(records, analytics, 'Monthly'),
          const SizedBox(height: 24),
          
          // Irregularities graph with trend line
          if (_showIrregularities) ...[
            _buildSectionTitle('Monthly Apnea Events', icon: Icons.timeline),
            const SizedBox(height: 8),
            _buildEnhancedIrregularitiesChart(records, isWeekly: false),
            const SizedBox(height: 24),
          ],
          
          // Sleep quality heatmap
          if (_showDuration) ...[
            _buildSectionTitle('Sleep Duration Pattern', icon: Icons.hotel),
            const SizedBox(height: 8),
            _buildEnhancedDurationChart(records, isWeekly: false),
            const SizedBox(height: 24),
          ],
          
          // Monthly progress metrics
          if (_showSeverity) ...[
            _buildSectionTitle('Monthly Progress', icon: Icons.insights),
            const SizedBox(height: 12),
            _buildMonthlyProgressIndicators(records, analytics),
            const SizedBox(height: 24),
          ],
          
          // Recommendations based on data
          if (_showRecommendations) ...[
            _buildSectionTitle('Recommended Actions', icon: Icons.lightbulb_outline),
            const SizedBox(height: 8),
            _buildRecommendations(analytics),
            const SizedBox(height: 40),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryCard(List<SleepRecord> records, String timeFrame) {
    // Calculate averages and trends
    final avgIrregularities = records.isEmpty 
        ? 0.0 
        : records.map((r) => r.irregularities).reduce((a, b) => a + b) / records.length;
    
    final avgDuration = records.isEmpty 
        ? 0.0 
        : records.map((r) => r.duration).reduce((a, b) => a + b) / records.length;
    
    // Count severity distribution
    int lowCount = 0, medCount = 0, highCount = 0;
    for (final record in records) {
      switch (record.severity.toLowerCase()) {
        case 'low': lowCount++; break;
        case 'medium': case 'med': medCount++; break;
        case 'high': highCount++; break;
      }
    }
    
    return Card(
      color: AppTheme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$timeFrame Summary',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(color: Colors.white24),
            const SizedBox(height: 8),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryItem(
                  'Avg. Events', 
                  '${avgIrregularities.toStringAsFixed(1)}',
                  Icons.error_outline,
                ),
                _buildSummaryItem(
                  'Avg. Sleep', 
                  '${avgDuration.toStringAsFixed(1)}h',
                  Icons.bedtime_outlined,
                ),
                _buildSummaryItem(
                  'Most Common', 
                  _getMostCommonSeverity(lowCount, medCount, highCount),
                  Icons.analytics_outlined,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    String label, 
    String value, 
    IconData icon, 
    {Color? color}
  ) {
    return Column(
      children: [
        Icon(icon, color: color ?? AppTheme.primaryColor, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: color ?? Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
  
  Widget _buildSectionTitle(String title, {IconData? icon}) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, color: AppTheme.primaryColor, size: 20),
          const SizedBox(width: 8),
        ],
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildIrregularitiesChart(List<SleepRecord> records, {required bool isWeekly}) {
    final maxY = records.isEmpty 
        ? 10.0 
        : (records.map((r) => r.irregularities).reduce((a, b) => a > b ? a : b) * 1.2)
            .toDouble()
            .clamp(10, 100);
    
    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: records.isEmpty
          ? const Center(
              child: Text(
                'Not enough data yet',
                style: TextStyle(color: Colors.white70),
              ),
            )
          : LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: maxY / 5,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.white.withOpacity(0.1),
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: Colors.white.withOpacity(0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  bottomTitles: _getBottomTitles(records, isWeekly),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value % (maxY ~/ 5) != 0) return const SizedBox();
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        );
                      },
                      reservedSize: 32,
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
                maxX: records.length - 1,
                minY: 0,
                maxY: maxY.toDouble(),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      records.length,
                      (i) => FlSpot(i.toDouble(), records[i].irregularities.toDouble()),
                    ),
                    isCurved: true,
                    color: const Color(0xFFFF5677), // Red for irregularities
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: const Color(0xFFFF5677),
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFFF5677).withOpacity(0.4),
                          const Color(0xFFFF5677).withOpacity(0.0),
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
                        if (index >= records.length) return null;
                        final record = records[index];
                        return LineTooltipItem(
                          '${record.date}\n${record.irregularities} events',
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
    );
  }

  Widget _buildDurationChart(List<SleepRecord> records, {required bool isWeekly}) {
    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: records.isEmpty
          ? const Center(
              child: Text(
                'Not enough data yet',
                style: TextStyle(color: Colors.white70),
              ),
            )
          : LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 2,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.white.withOpacity(0.1),
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: Colors.white.withOpacity(0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  bottomTitles: _getBottomTitles(records, isWeekly),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value % 2 != 0) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            '${value.toInt()}h',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                      reservedSize: 32,
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
                maxX: records.length - 1,
                minY: 0,
                maxY: 12,
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      records.length,
                      (i) => FlSpot(i.toDouble(), records[i].duration),
                    ),
                    isCurved: true,
                    color: const Color(0xFF6A47BB),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: const Color(0xFF6A47BB),
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF6A47BB).withOpacity(0.4),
                          const Color(0xFF6A47BB).withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  // Add visual guides for recommended sleep (7-8 hours)
                  LineChartBarData(
                    spots: [
                      FlSpot(0, 7),
                      FlSpot(records.length - 1, 7),
                    ],
                    isCurved: false,
                    color: Colors.green.withOpacity(0.5),
                    barWidth: 1,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    dashArray: [3, 3],
                  ),
                  LineChartBarData(
                    spots: [
                      FlSpot(0, 8),
                      FlSpot(records.length - 1, 8),
                    ],
                    isCurved: false,
                    color: Colors.green.withOpacity(0.5),
                    barWidth: 1,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    dashArray: [3, 3],
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: const Color(0xFF6A47BB).withOpacity(0.8),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final index = spot.x.toInt();
                        if (index >= records.length || spot.barIndex != 0) return null;
                        final record = records[index];
                        return LineTooltipItem(
                          '${record.date}\n${record.duration} hours',
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
    );
  }

  Widget _buildSeverityPieChart(List<SleepRecord> records) {
    // Count severity distribution
    int lowCount = 0, medCount = 0, highCount = 0;
    for (final record in records) {
      switch (record.severity.toLowerCase()) {
        case 'low': lowCount++; break;
        case 'medium': case 'med': medCount++; break;
        case 'high': highCount++; break;
      }
    }
    
    final totalRecords = lowCount + medCount + highCount;
    
    return SizedBox(
      height: 240,
      child: totalRecords == 0
          ? const Center(
              child: Text(
                'Not enough data yet',
                style: TextStyle(color: Colors.white70),
              ),
            )
          : Row(
              children: [
                // Pie chart
                Expanded(
                  flex: 3,
                  child: PieChart(
                    PieChartData(
                      sections: [
                        if (lowCount > 0)
                          PieChartSectionData(
                            value: lowCount.toDouble(),
                            title: '${((lowCount / totalRecords) * 100).toInt()}%',
                            color: AppTheme.lowRiskColor,
                            radius: 80,
                            titleStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        if (medCount > 0)
                          PieChartSectionData(
                            value: medCount.toDouble(),
                            title: '${((medCount / totalRecords) * 100).toInt()}%',
                            color: AppTheme.mediumRiskColor,
                            radius: 80,
                            titleStyle: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        if (highCount > 0)
                          PieChartSectionData(
                            value: highCount.toDouble(),
                            title: '${((highCount / totalRecords) * 100).toInt()}%',
                            color: AppTheme.highRiskColor,
                            radius: 80,
                            titleStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                      ],
                      centerSpaceRadius: 0,
                      sectionsSpace: 2,
                      startDegreeOffset: 180,
                    ),
                  ),
                ),
                
                // Legend
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSeverityLegendItem('Low', lowCount, AppTheme.lowRiskColor),
                      const SizedBox(height: 16),
                      _buildSeverityLegendItem('Medium', medCount, AppTheme.mediumRiskColor),
                      const SizedBox(height: 16),
                      _buildSeverityLegendItem('High', highCount, AppTheme.highRiskColor),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSeverityLegendItem(String label, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$label ($count)',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyProgressIndicators(List<SleepRecord> records, Map<String, dynamic> analytics) {
    if (records.isEmpty) {
      return _buildEmptyChart();
    }
    
    // Calculate progress metrics based on real data
    final improvementValue = analytics['improvement'].abs() / 100;
    final durationGoalProgress = (analytics['avgDuration'] / 8.0).clamp(0.0, 1.0);
    
    // Calculate quality score based on severity distribution
    final totalRecords = analytics['totalCount'].toDouble();
    final qualityProgress = totalRecords > 0 
        ? ((analytics['lowCount'] * 1.0 + analytics['mediumCount'] * 0.5) / totalRecords).clamp(0.0, 1.0)
        : 0.0;
    
    return Column(
      children: [
        _buildProgressIndicator(
          label: 'Sleep Quality',
          value: qualityProgress,
          color: AppTheme.lowRiskColor,
          description: 'Based on severity distribution',
        ),
        const SizedBox(height: 20),
        _buildProgressIndicator(
          label: analytics['trend'] == 'improving' ? 'Apnea Events Reduction' : 'Apnea Events Change',
          value: improvementValue.clamp(0.0, 1.0),
          color: analytics['trend'] == 'improving' ? AppTheme.primaryColor : AppTheme.highRiskColor,
          description: 'Comparing first and last records',
        ),
        const SizedBox(height: 20),
        _buildProgressIndicator(
          label: 'Sleep Duration Goal (8h)',
          value: durationGoalProgress,
          color: AppTheme.mediumRiskColor,
          description: 'Current: ${analytics['avgDuration'].toStringAsFixed(1)}h / 8h target',
        ),
      ],
    );
  }

  Widget _buildProgressIndicator({
    required String label,
    required double value,
    required Color color,
    String? description,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (description != null)
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            Text(
              '${(value * 100).toInt()}%',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          height: 10,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Background gradient to show the "goal" range
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.red.withOpacity(0.2),
                      Colors.amber.withOpacity(0.2),
                      Colors.green.withOpacity(0.2),
                    ],
                    stops: const [0.3, 0.7, 1.0],
                  ),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              // Current progress
              FractionallySizedBox(
                widthFactor: value,
                alignment: Alignment.centerLeft,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.5),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper methods
  List<SleepRecord> _getWeeklyRecords() {
    // For MVP, just return all records in reverse (most recent first)
    // In a real app, you'd filter to last 7 days
    return _weeklyRecords;
  }

  List<SleepRecord> _getMonthlyRecords() {
    // For MVP, just return all records
    // In a real app, you'd filter to last 30 days
    return _monthlyRecords;
  }

  String _getMostCommonSeverity(int low, int med, int high) {
    if (low >= med && low >= high) return 'Low';
    if (med >= low && med >= high) return 'Medium';
    return 'High';
  }

  AxisTitles _getBottomTitles(List<SleepRecord> records, bool isWeekly) {
    return AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        getTitlesWidget: (value, meta) {
          final index = value.toInt();
          if (index >= records.length || (records.length > 10 && index % 2 != 0)) {
            return const SizedBox();
          }
          
          final record = records[index];
          final dateParts = record.date.split(', ')[0].split(' ');
          
          // Change this to include both month and day for more meaningful labels
          final String label;
          if (isWeekly) {
            // For weekly view: "Apr 2" format
            label = dateParts.length > 1 ? "${dateParts[0]} ${dateParts[1]}" : dateParts[0];
          } else {
            // For monthly view: "2" (just day) to save space, or full "Apr 2" if space permits
            label = dateParts.length > 1 ? dateParts[1] : dateParts[0];
          }
          
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
          );
        },
        reservedSize: 24,
      ),
    );
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Chart Filters',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildFilterSwitch(
                    'Apnea Events Pattern',
                    _showIrregularities,
                    (value) {
                      setModalState(() => _showIrregularities = value);
                      setState(() => _showIrregularities = value);
                    },
                    icon: Icons.multiline_chart,
                  ),
                  _buildFilterSwitch(
                    'Sleep Duration',
                    _showDuration,
                    (value) {
                      setModalState(() => _showDuration = value);
                      setState(() => _showDuration = value);
                    },
                    icon: Icons.bedtime_outlined,
                  ),
                  _buildFilterSwitch(
                    'Severity Distribution',
                    _showSeverity,
                    (value) {
                      setModalState(() => _showSeverity = value);
                      setState(() => _showSeverity = value);
                    },
                    icon: Icons.pie_chart,
                  ),
                  _buildFilterSwitch(
                    'Recommendations & Analysis',
                    _showRecommendations,
                    (value) {
                      setModalState(() => _showRecommendations = value);
                      setState(() => _showRecommendations = value);
                    },
                    icon: Icons.lightbulb_outline,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterSwitch(
    String label, 
    bool value, 
    ValueChanged<bool> onChanged, 
    {IconData? icon}
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: AppTheme.primaryColor, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedSummaryCard(List<SleepRecord> records, Map<String, dynamic> analytics, String timeFrame) {
    // Extract analytics data
    final avgIrregularities = analytics['avgIrregularities'];
    final avgDuration = analytics['avgDuration'];
    final trend = analytics['trend'];
    final improvement = analytics['improvement'];
    
    return Card(
      color: AppTheme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$timeFrame Summary',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildTrendIndicator(trend, improvement),
              ],
            ),
            const Divider(color: Colors.white24),
            const SizedBox(height: 8),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryItem(
                  'Avg. Events', 
                  avgIrregularities.toStringAsFixed(1),
                  Icons.error_outline,
                  color: _getSeverityColorForValue(avgIrregularities),
                ),
                _buildSummaryItem(
                  'Avg. Sleep', 
                  '${avgDuration.toStringAsFixed(1)}h',
                  Icons.bedtime_outlined,
                  color: _getColorForSleepDuration(avgDuration),
                ),
                _buildSummaryItem(
                  'Most Common', 
                  _getMostCommonSeverity(
                    analytics['lowCount'], 
                    analytics['mediumCount'], 
                    analytics['highCount']
                  ),
                  Icons.analytics_outlined,
                  color: _getColorForSeverity(_getMostCommonSeverity(
                    analytics['lowCount'], 
                    analytics['mediumCount'], 
                    analytics['highCount']
                  )),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTrendIndicator(String trend, double improvement) {
    IconData icon;
    Color color;
    String label;
    
    switch (trend) {
      case 'improving':
        icon = Icons.trending_up;
        color = Colors.green;
        label = '${improvement.abs().toStringAsFixed(1)}% better';
        break;
      case 'deteriorating':
        icon = Icons.trending_down;
        color = Colors.red;
        label = '${improvement.abs().toStringAsFixed(1)}% worse';
        break;
      default:
        icon = Icons.trending_flat;
        color = Colors.grey;
        label = 'Stable';
    }
    
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  Color _getSeverityColorForValue(double irregularities) {
    if (irregularities < 5) return AppTheme.lowRiskColor;
    if (irregularities < 20) return AppTheme.mediumRiskColor;
    return AppTheme.highRiskColor;
  }
  
  Color _getColorForSleepDuration(double duration) {
    if (duration < 6) return AppTheme.highRiskColor;
    if (duration < 7) return AppTheme.mediumRiskColor;
    return AppTheme.lowRiskColor;
  }
  
  Color _getColorForSeverity(String severity) {
    switch (severity.toLowerCase()) {
      case 'low': return AppTheme.lowRiskColor;
      case 'medium': case 'med': return AppTheme.mediumRiskColor;
      case 'high': return AppTheme.highRiskColor;
      default: return Colors.grey;
    }
  }

  Widget _buildInsightsView(List<SleepRecord> allRecords) {
    // Create summary data for insights
    final weekdayData = _analyzeWeekdayPatterns(allRecords);
    final timeData = _analyzeTimePatterns(allRecords);
    final longTermTrend = _analyzeLongTermTrend(allRecords);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInsightCard(
            title: 'Sleep Apnea Severity Trend',
            icon: Icons.show_chart,
            content: _buildSeverityTrendInsight(allRecords, longTermTrend),
          ),
          const SizedBox(height: 20),
          
          _buildInsightCard(
            title: 'Best/Worst Days',
            icon: Icons.calendar_today,
            content: _buildWeekdayInsight(weekdayData),
          ),
          const SizedBox(height: 20),
          
          _buildInsightCard(
            title: 'Sleep Duration Analysis',
            icon: Icons.access_time,
            content: _buildDurationInsight(allRecords),
          ),
          const SizedBox(height: 20),
          
          _buildInsightCard(
            title: 'Sleep Health Score',
            icon: Icons.favorite,
            content: _buildSleepScoreInsight(allRecords, longTermTrend),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
  
  Widget _buildInsightCard({
    required String title,
    required IconData icon,
    required Widget content,
  }) {
    return Card(
      color: AppTheme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white24),
            const SizedBox(height: 8),
            content,
          ],
        ),
      ),
    );
  }
  
  Map<String, dynamic> _analyzeWeekdayPatterns(List<SleepRecord> records) {
    // This would analyze which days of the week have the most/least irregularities
    // For demo, we'll return mock data
    return {
      'bestDay': 'Saturday',
      'worstDay': 'Monday',
      'data': [
        {'day': 'Mon', 'value': 15.0},
        {'day': 'Tue', 'value': 12.0},
        {'day': 'Wed', 'value': 10.0},
        {'day': 'Thu', 'value': 11.0},
        {'day': 'Fri', 'value': 8.0},
        {'day': 'Sat', 'value': 5.0},
        {'day': 'Sun', 'value': 9.0},
      ],
    };
  }
  
  Map<String, dynamic> _analyzeTimePatterns(List<SleepRecord> records) {
    // This would analyze time patterns (not implemented in demo)
    return {};
  }
  
  Map<String, dynamic> _analyzeLongTermTrend(List<SleepRecord> records) {
    if (records.isEmpty) {
      return {'trend': 'neutral', 'improvement': 0.0};
    }
    
    // In a real app, we'd do more sophisticated trend analysis
    // For this demo, we'll calculate a simple trend
    
    // Sort records by date (oldest to newest)
    final sortedRecords = List<SleepRecord>.from(records);
    sortedRecords.sort((a, b) => a.date.compareTo(b.date));
    
    if (sortedRecords.length < 4) {
      return {'trend': 'neutral', 'improvement': 0.0};
    }
    
    final firstQuarter = sortedRecords.sublist(0, sortedRecords.length ~/ 4);
    final lastQuarter = sortedRecords.sublist(3 * sortedRecords.length ~/ 4);
    
    final firstAvg = firstQuarter.map((r) => r.irregularities).reduce((a, b) => a + b) / firstQuarter.length;
    final lastAvg = lastQuarter.map((r) => r.irregularities).reduce((a, b) => a + b) / lastQuarter.length;
    
    double improvement = 0.0;
    String trend = 'neutral';
    
    // Calculate improvement percentage (negative means improvement, fewer irregularities)
    if (firstAvg > 0) {
      improvement = (lastAvg - firstAvg) / firstAvg * -100;
    }
    
    if (improvement > 10) trend = 'improving';
    else if (improvement < -10) trend = 'deteriorating';
    
    return {
      'trend': trend,
      'improvement': improvement,
      'firstPeriodAvg': firstAvg,
      'lastPeriodAvg': lastAvg,
    };
  }

  Widget _buildSeverityTrendInsight(List<SleepRecord> records, Map<String, dynamic> trendData) {
    if (records.isEmpty) {
      return const Center(
        child: Text(
          'Not enough data yet',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }
    
    final trend = trendData['trend'];
    final improvement = trendData['improvement'];
    
    // Build message based on trend
    String message;
    Color messageColor;
    
    switch (trend) {
      case 'improving':
        message = 'Your sleep apnea symptoms have improved by approximately ${improvement.abs().toStringAsFixed(0)}% over time. Keep up the good work!';
        messageColor = Colors.green;
        break;
      case 'deteriorating':
        message = 'Your sleep apnea symptoms have worsened by approximately ${improvement.abs().toStringAsFixed(0)}% over time. Consider consulting with a healthcare provider.';
        messageColor = Colors.redAccent;
        break;
      default:
        message = 'Your sleep apnea symptoms have remained relatively stable over time.';
        messageColor = Colors.white70;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message,
          style: TextStyle(color: messageColor, fontSize: 16),
        ),
        const SizedBox(height: 20),
        
        // Simple visualization of before/after
        if (trend != 'neutral') ...[
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'First Period Avg',
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: _getSeverityColorForValue(trendData['firstPeriodAvg']),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          trendData['firstPeriodAvg'].toStringAsFixed(1),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                trend == 'improving' ? Icons.arrow_forward : Icons.arrow_forward,
                color: Colors.white30,
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Recent Period Avg',
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: _getSeverityColorForValue(trendData['lastPeriodAvg']),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          trendData['lastPeriodAvg'].toStringAsFixed(1),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
  
  Widget _buildWeekdayInsight(Map<String, dynamic> weekdayData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildDayQualityIndicator(
              'Best Day',
              weekdayData['bestDay'],
              Colors.green,
              Icons.thumb_up_outlined,
            ),
            _buildDayQualityIndicator(
              'Worst Day',
              weekdayData['worstDay'],
              Colors.redAccent,
              Icons.thumb_down_outlined,
            ),
          ],
        ),
        const SizedBox(height: 20),
        
        // Weekday chart
        Container(
          height: 180,
          padding: const EdgeInsets.only(top: 16),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.center,
              barGroups: _createWeekdayBarGroups(weekdayData['data']),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.white.withOpacity(0.1),
                    strokeWidth: 1,
                  );
                },
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                      if (value >= 0 && value < weekdays.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            weekdays[value.toInt()],
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
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
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
      ],
    );
  }
  
  List<BarChartGroupData> _createWeekdayBarGroups(List<dynamic> data) {
    return List.generate(data.length, (index) {
      final item = data[index];
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: item['value'],
            color: _getSeverityColorForValue(item['value']),
            width: 16,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    });
  }
  
  Widget _buildDayQualityIndicator(String label, String day, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            day,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDurationInsight(List<SleepRecord> records) {
    if (records.isEmpty) {
      return const Center(
        child: Text(
          'Not enough data yet',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }
    
    // Calculate average duration
    final avgDuration = records.map((r) => r.duration).reduce((a, b) => a + b) / records.length;
    
    // Determine if the average duration is good
    final isGoodDuration = avgDuration >= 7.0;
    final isOkDuration = avgDuration >= 6.0 && avgDuration < 7.0;
    
    String message;
    Color messageColor;
    
    if (isGoodDuration) {
      message = 'Your average sleep duration of ${avgDuration.toStringAsFixed(1)} hours is good. Consistent 7-8 hours of sleep helps reduce sleep apnea symptoms.';
      messageColor = Colors.green;
    } else if (isOkDuration) {
      message = 'Your average sleep duration of ${avgDuration.toStringAsFixed(1)} hours is acceptable but could be improved. Aim for 7-8 hours for better sleep health.';
      messageColor = Colors.amber;
    } else {
      message = 'Your average sleep duration of ${avgDuration.toStringAsFixed(1)} hours is below recommended levels. Try to get 7-8 hours of sleep for better management of sleep apnea.';
      messageColor = Colors.redAccent;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message,
          style: TextStyle(color: messageColor, fontSize: 16),
        ),
        const SizedBox(height: 20),
        
        // Visualization of ideal sleep range
        Stack(
          children: [
            // Background scale
            Container(
              height: 20,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Colors.red,
                    Colors.amber,
                    Colors.green,
                    Colors.amber,
                    Colors.red,
                  ],
                  stops: [0.0, 0.2, 0.4, 0.6, 1.0],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            
            // Markers for hours
            SizedBox(
              height: 30,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('<5h', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                  Text('6h', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                  Text('7h', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                  Text('8h', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                  Text('9h+', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                ],
              ),
            ),
            
            // Current position indicator
            Positioned(
              left: ((avgDuration.clamp(4.0, 10.0) - 4.0) / 6.0 * 100).clamp(0.0, 100.0) * 0.01 * MediaQuery.of(context).size.width * 0.85,
              child: Container(
                margin: const EdgeInsets.only(top: 5),
                child: Icon(
                  Icons.arrow_drop_down,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildSleepScoreInsight(List<SleepRecord> records, Map<String, dynamic> trendData) {
    if (records.isEmpty) {
      return const Center(
        child: Text(
          'Not enough data yet',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }
    
    // Calculate sleep score (0-100) based on various factors
    // In a real app, this would be a more complex algorithm
    final avgIrregularities = records.map((r) => r.irregularities).reduce((a, b) => a + b) / records.length;
    final avgDuration = records.map((r) => r.duration).reduce((a, b) => a + b) / records.length;
    
    // Count severity distribution
    int lowCount = 0, medCount = 0, highCount = 0;
    for (final record in records) {
      switch (record.severity.toLowerCase()) {
        case 'low': lowCount++; break;
        case 'medium': case 'med': medCount++; break;
        case 'high': highCount++; break;
      }
    }
    
    // Calculate approximate score components
    final durationScore = ((avgDuration.clamp(4.0, 9.0) - 4.0) / 5.0 * 100).clamp(0.0, 100.0) * 0.4;
    final irregularitiesScore = (100 - (avgIrregularities.clamp(0.0, 30.0) / 30.0 * 100)).clamp(0.0, 100.0) * 0.4;
    
    // Quality score based on severity distribution
    final totalRecords = (lowCount + medCount + highCount).toDouble();
    final qualityScore = totalRecords > 0 
        ? ((lowCount * 100 + medCount * 50) / totalRecords).clamp(0.0, 100.0) * 0.2
        : 0.0;
    
    final overallScore = (durationScore + irregularitiesScore + qualityScore).round();
    
    // Determine score category and message
    String category;
    Color categoryColor;
    String message;
    
    if (overallScore >= 80) {
      category = 'Excellent';
      categoryColor = Colors.green;
      message = 'Your sleep health is excellent! Keep maintaining your current sleep habits.';
    } else if (overallScore >= 60) {
      category = 'Good';
      categoryColor = Colors.lightGreen;
      message = 'Your sleep health is good. Small improvements could help you reach excellent status.';
    } else if (overallScore >= 40) {
      category = 'Fair';
      categoryColor = Colors.amber;
      message = 'Your sleep health is fair. Consider the recommended actions to improve.';
    } else {
      category = 'Needs Improvement';
      categoryColor = Colors.redAccent;
      message = 'Your sleep health needs improvement. Consider consulting a healthcare provider.';
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Sleep Health Score',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  category,
                  style: TextStyle(
                    color: categoryColor,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
                border: Border.all(
                  color: categoryColor,
                  width: 3,
                ),
              ),
              child: Center(
                child: Text(
                  overallScore.toString(),
                  style: TextStyle(
                    color: categoryColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildSleepPatternAnalysis(List<SleepRecord> records, Map<String, dynamic> analytics) {
    if (records.isEmpty) {
      return _buildEmptyChart();
    }
    
    // Determine if there's a correlation between sleep duration and irregularities
    bool durationAffectsIrregularities = false;
    String correlationMessage = '';
    
    if (records.length >= 3) {
      // Group records by duration ranges and calculate average irregularities
      final shortSleepRecords = records.where((r) => r.duration < 6.5).toList();
      final longSleepRecords = records.where((r) => r.duration >= 6.5).toList();
      
      if (shortSleepRecords.isNotEmpty && longSleepRecords.isNotEmpty) {
        final shortSleepAvg = shortSleepRecords.map((r) => r.irregularities).reduce((a, b) => a + b) / 
            shortSleepRecords.length;
        final longSleepAvg = longSleepRecords.map((r) => r.irregularities).reduce((a, b) => a + b) / 
            longSleepRecords.length;
        
        final difference = (shortSleepAvg - longSleepAvg).abs();
        
        if (difference > 3) {
          durationAffectsIrregularities = true;
          if (shortSleepAvg > longSleepAvg) {
            correlationMessage = 'Your data suggests that longer sleep duration (≥6.5 hours) tends to result in fewer apnea events.';
          } else {
            correlationMessage = 'Your data shows an unusual pattern where shorter sleep duration is associated with fewer apnea events.';
          }
        }
      }
    }
    
    if (!durationAffectsIrregularities) {
      correlationMessage = 'No clear pattern detected between sleep duration and apnea events. Continue monitoring for more insights.';
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            correlationMessage,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          
          // Add key findings
          const Text(
            'Key Findings:',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          
          _buildFindingItem(
            'Average of ${analytics['avgIrregularities'].toStringAsFixed(1)} apnea events detected per session',
            icon: Icons.error_outline,
            color: _getSeverityColorForValue(analytics['avgIrregularities']),
          ),
          _buildFindingItem(
            'Average sleep duration: ${analytics['avgDuration'].toStringAsFixed(1)} hours',
            icon: Icons.bedtime_outlined,
            color: _getColorForSleepDuration(analytics['avgDuration']),
          ),
          _buildFindingItem(
            'Most common severity: ${_getMostCommonSeverity(
               analytics['lowCount'], 
               analytics['mediumCount'], 
               analytics['highCount']
             )}',
            icon: Icons.analytics_outlined,
            color: _getColorForSeverity(_getMostCommonSeverity(
              analytics['lowCount'], 
              analytics['mediumCount'], 
              analytics['highCount']
            )),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFindingItem(String text, {required IconData icon, required Color color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.white.withOpacity(0.9)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations(Map<String, dynamic> analytics) {
    final recommendations = analytics['recommendedActions'] as List<String>;
    
    if (recommendations.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: const Center(
          child: Text(
            'Continue your current sleep monitoring routine',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Based on your data, consider:',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),
          
          ...recommendations.map((rec) => _buildRecommendationItem(rec)).toList(),
          
          const SizedBox(height: 16),
          const Text(
            'Disclaimer: These recommendations are based on your recorded data and are not a substitute for professional medical advice.',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRecommendationItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline,
            color: AppTheme.primaryColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChart() {
    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: const Center(
        child: Text(
          'Not enough data yet',
          style: TextStyle(color: Colors.white70),
        ),
      ),
    );
  }

  // Add the missing chart methods
  Widget _buildEnhancedIrregularitiesChart(List<SleepRecord> records, {required bool isWeekly}) {
    if (records.isEmpty) {
      return _buildEmptyChart();
    }
    
    final maxY = records.isEmpty 
        ? 10.0 
        : (records.map((r) => r.irregularities).reduce((a, b) => a > b ? a : b) * 1.2)
            .toDouble()
            .clamp(10, 100);
    
    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: maxY / 5,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.white.withOpacity(0.1),
                strokeWidth: 1,
              );
            },
            getDrawingVerticalLine: (value) {
              return FlLine(
                color: Colors.white.withOpacity(0.1),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            bottomTitles: _getBottomTitles(records, isWeekly), // Use the improved labels
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value % (maxY ~/ 5) != 0) return const SizedBox();
                  return Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  );
                },
                reservedSize: 32,
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
          maxX: records.length - 1,
          minY: 0,
          maxY: maxY.toDouble(),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                records.length,
                (i) => FlSpot(i.toDouble(), records[i].irregularities.toDouble()),
              ),
              isCurved: true,
              color: const Color(0xFFFF5677), // Red for irregularities
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: const Color(0xFFFF5677),
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFF5677).withOpacity(0.4),
                    const Color(0xFFFF5677).withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            // Add a trend line based on moving average
            LineChartBarData(
              spots: _calculateTrendLine(records),
              isCurved: true,
              color: Colors.white.withOpacity(0.7),
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              dashArray: [5, 5],
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: const Color(0xFF6A47BB).withOpacity(0.8),
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final index = spot.x.toInt();
                  if (index >= records.length || spot.barIndex != 0) return null;
                  final record = records[index];
                  return LineTooltipItem(
                    '${record.date}\n${record.irregularities} events',
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
    );
  }

  List<FlSpot> _calculateTrendLine(List<SleepRecord> records) {
    if (records.length < 3) {
      return [];
    }
    
    // Simple moving average for trend line
    const windowSize = 3;
    List<FlSpot> trendSpots = [];
    
    for (int i = 0; i < records.length; i++) {
      if (i >= windowSize - 1) {
        double sum = 0;
        for (int j = 0; j < windowSize; j++) {
          sum += records[i - j].irregularities;
        }
        double avg = sum / windowSize;
        trendSpots.add(FlSpot(i.toDouble(), avg));
      }
    }
    
    return trendSpots;
  }

  Widget _buildEnhancedDurationChart(List<SleepRecord> records, {required bool isWeekly}) {
    if (records.isEmpty) {
      return _buildEmptyChart();
    }
    
    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: 2,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.white.withOpacity(0.1),
                strokeWidth: 1,
              );
            },
            getDrawingVerticalLine: (value) {
              return FlLine(
                color: Colors.white.withOpacity(0.1),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            bottomTitles: _getBottomTitles(records, isWeekly), // Use the improved labels
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value % 2 != 0) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      '${value.toInt()}h',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  );
                },
                reservedSize: 32,
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
          maxX: records.length - 1,
          minY: 0,
          maxY: 12,
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                records.length,
                (i) => FlSpot(i.toDouble(), records[i].duration),
              ),
              isCurved: true,
              color: const Color(0xFF6A47BB),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  // Use severity colors for the dots to show sleep quality
                  return FlDotCirclePainter(
                    radius: 4,
                    color: _getColorForSeverity(records[index].severity),
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF6A47BB).withOpacity(0.4),
                    const Color(0xFF6A47BB).withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            // Optimal sleep range (7-8 hours)
            LineChartBarData(
              spots: [
                FlSpot(0, 7),
                FlSpot(records.length - 1, 7),
              ],
              isCurved: false,
              color: Colors.green.withOpacity(0.5),
              barWidth: 1,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              dashArray: [3, 3],
            ),
            LineChartBarData(
              spots: [
                FlSpot(0, 8),
                FlSpot(records.length - 1, 8),
              ],
              isCurved: false,
              color: Colors.green.withOpacity(0.5),
              barWidth: 1,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              dashArray: [3, 3],
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: const Color(0xFF6A47BB).withOpacity(0.8),
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final index = spot.x.toInt();
                  if (index >= records.length || spot.barIndex != 0) return null;
                  final record = records[index];
                  return LineTooltipItem(
                    '${record.date}\n${record.duration} hours\nQuality: ${_getSleepQualityFromSeverity(record.severity)}',
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
    );
  }
  
  String _getSleepQualityFromSeverity(String severity) {
    switch (severity.toLowerCase()) {
      case 'low': return 'Good';
      case 'medium': case 'med': return 'Fair';
      case 'high': return 'Poor';
      default: return 'Unknown';
    }
  }
} 