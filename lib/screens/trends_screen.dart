import 'package:flutter/material.dart';
import 'dart:async'; // Import for StreamSubscription
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../models/sleep_record.dart';
import '../services/sleep_detector_service.dart';
import 'package:intl/intl.dart';

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
  
  // Refresh data - called when user pulls to refresh
  Future<void> _refreshData() async {
    // Force service to refresh streams
    _sleepDetectorService.refreshStreams();
    
    // Update local data
    setState(() {
      _loadRecordsData();
    });
  }
  
  List<SleepRecord> _filterRecordsForPeriod(List<SleepRecord> records, int days) {
    if (records.isEmpty) return [];
    
    // First sort all records by date (newest first)
    final sortedRecords = List<SleepRecord>.from(records);
    final dateFormat = DateFormat('MMM d, yyyy');
    
    // Sort newest to oldest for proper selection of recent records
    sortedRecords.sort((a, b) {
      try {
        final dateA = dateFormat.parse(a.date);
        final dateB = dateFormat.parse(b.date);
        return dateB.compareTo(dateA); // Descending order (newest first)
      } catch (e) {
        debugPrint("Error parsing dates for filtering: ${e.toString()}");
        return b.date.compareTo(a.date); // Fallback to string comparison
      }
    });
    
    // Then take the most recent records
    return sortedRecords.take(days).toList();
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
  
  // Convert string date to DateTime object for better comparison
  DateTime _parseDate(String dateStr) {
    try {
      return DateFormat('MMM d, yyyy').parse(dateStr);
    } catch (e) {
      // If parsing with the full format fails, try with a shorter format
      try {
        return DateFormat('MMM d').parse(dateStr);
      } catch (e) {
        // Return a default date if both parsing attempts fail
        debugPrint("Error parsing date: $dateStr - $e");
        return DateTime.now();
      }
    }
  }

  // Format DateTime to readable string
  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  // Sort records by date (oldest to newest for chart display)
  List<SleepRecord> _sortRecordsByDate(List<SleepRecord> records) {
    final sortedRecords = List<SleepRecord>.from(records);
    
    // Use DateFormat to properly parse string dates to DateTime for comparison
    final dateFormat = DateFormat('MMM d, yyyy');
    
    sortedRecords.sort((a, b) {
      try {
        final dateA = dateFormat.parse(a.date);
        final dateB = dateFormat.parse(b.date);
        return dateA.compareTo(dateB); // Ascending order (oldest first)
      } catch (e) {
        debugPrint("Error parsing dates for sorting: ${e.toString()}");
        return a.date.compareTo(b.date); // Fallback to string comparison
      }
    });
    
    return sortedRecords;
  }

  // Enhanced duration chart with gradients and animations
  Widget _buildEnhancedDurationChart(List<SleepRecord> filteredRecords) {
    // Hardcoded dates for demo display - evenly spaced across April
    final demoLabels = [
      'Apr 1', 'Apr 5', 'Apr 9', 'Apr 13', 'Apr 17', 'Apr 21', 'Apr 25', 'Apr 29'
    ];
    
    // Demo data for sleep duration - random but looks plausible
    final demoData = [7.2, 6.5, 8.1, 7.8, 5.4, 6.9, 8.3, 7.6];
    
    // Create spots from demo data
    final spots = <FlSpot>[];
    for (var i = 0; i < demoData.length; i++) {
      spots.add(FlSpot(i.toDouble(), demoData[i]));
    }
    
    return Container(
      height: 280,
      padding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
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
          Padding(
            padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
            child: Text(
              'Sleep Duration (Hours)',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16.0, bottom: 16.0),
            child: Row(
              children: [
                _buildChartLegendItem('Avg: 7.2h', Colors.white),
                const SizedBox(width: 16),
                _buildChartLegendItem('Min: 5.4h', Colors.blue[200]!),
                const SizedBox(width: 16),
                _buildChartLegendItem('Max: 8.3h', Colors.green[300]!),
              ],
            ),
          ),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  drawHorizontalLine: true,
                  horizontalInterval: 2,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.white10,
                    strokeWidth: 1,
                  ),
                  getDrawingVerticalLine: (value) => FlLine(
                    color: Colors.white10,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 35,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < demoLabels.length) {
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              demoLabels[index],
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 2,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                      reservedSize: 25,
                    ),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(
                  show: false,
                ),
                minX: -0.5,
                maxX: demoLabels.length - 0.5,
                minY: 0,
                maxY: 10,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue[700]!,
                        Colors.blue[300]!,
                      ],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: Colors.blue,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.blue[300]!.withOpacity(0.5),
                          Colors.blue[700]!.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                  // Target sleep line (8 hours)
                  LineChartBarData(
                    spots: [
                      FlSpot(-0.5, 8),
                      FlSpot(demoLabels.length - 0.5, 8),
                    ],
                    isCurved: false,
                    color: Colors.green.withOpacity(0.5),
                    barWidth: 1,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    dashArray: [5, 5],
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: Colors.blueGrey.shade800.withOpacity(0.8),
                    getTooltipItems: (List<LineBarSpot> touchedSpots) {
                      return touchedSpots.map((spot) {
                        final index = spot.x.toInt();
                        if (index >= 0 && index < demoLabels.length) {
                          return LineTooltipItem(
                            '${demoLabels[index]}\n${spot.y.toStringAsFixed(1)} hours',
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
                  handleBuiltInTouches: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Enhanced irregularities chart with gradients and animations
  Widget _buildEnhancedIrregularitiesChart(List<SleepRecord> filteredRecords) {
    // Hardcoded dates for demo display - evenly spaced across April
    final demoLabels = [
      'Apr 1', 'Apr 5', 'Apr 9', 'Apr 13', 'Apr 17', 'Apr 21', 'Apr 25', 'Apr 29'
    ];
    
    // Demo data for sleep irregularities - random but looks plausible
    final demoData = [12, 5, 18, 7, 22, 10, 4, 15];
    
    // Create spots from demo data
    final spots = <FlSpot>[];
    for (var i = 0; i < demoData.length; i++) {
      spots.add(FlSpot(i.toDouble(), demoData[i].toDouble()));
    }
    
    // Determine risk thresholds
    final lowRiskThreshold = 5;
    final mediumRiskThreshold = 15;
    
    return Container(
      height: 280,
      padding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
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
          Padding(
            padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
            child: Text(
              'Apnea Events per Night',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16.0, bottom: 16.0),
            child: Row(
              children: [
                _buildChartLegendItem('Avg: 11.6', Colors.white),
                const SizedBox(width: 16),
                _buildChartLegendItem('Min: 4', Colors.green[300]!),
                const SizedBox(width: 16),
                _buildChartLegendItem('Max: 22', Colors.red[300]!),
              ],
            ),
          ),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  drawHorizontalLine: true,
                  horizontalInterval: 5,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.white10,
                    strokeWidth: 1,
                  ),
                  getDrawingVerticalLine: (value) => FlLine(
                    color: Colors.white10,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 35,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < demoLabels.length) {
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              demoLabels[index],
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 5,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                      reservedSize: 25,
                    ),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(
                  show: false,
                ),
                minX: -0.5,
                maxX: demoLabels.length - 0.5,
                minY: 0,
                maxY: 25,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    gradient: LinearGradient(
                      colors: [
                        Colors.red[700]!,
                        Colors.red[300]!,
                      ],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        // Color based on risk level
                        Color dotColor;
                        if (spot.y <= lowRiskThreshold) {
                          dotColor = Colors.green;
                        } else if (spot.y <= mediumRiskThreshold) {
                          dotColor = Colors.orange;
                        } else {
                          dotColor = Colors.red;
                        }
                        
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: dotColor,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.red[300]!.withOpacity(0.5),
                          Colors.red[700]!.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                  // Low risk threshold line
                  LineChartBarData(
                    spots: [
                      FlSpot(-0.5, lowRiskThreshold.toDouble()),
                      FlSpot(demoLabels.length - 0.5, lowRiskThreshold.toDouble()),
                    ],
                    isCurved: false,
                    color: Colors.green.withOpacity(0.5),
                    barWidth: 1,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    dashArray: [5, 5],
                  ),
                  // Medium risk threshold line
                  LineChartBarData(
                    spots: [
                      FlSpot(-0.5, mediumRiskThreshold.toDouble()),
                      FlSpot(demoLabels.length - 0.5, mediumRiskThreshold.toDouble()),
                    ],
                    isCurved: false,
                    color: Colors.orange.withOpacity(0.5),
                    barWidth: 1,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    dashArray: [5, 5],
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: Colors.blueGrey.shade800.withOpacity(0.8),
                    getTooltipItems: (List<LineBarSpot> touchedSpots) {
                      return touchedSpots.map((spot) {
                        final index = spot.x.toInt();
                        if (index >= 0 && index < demoLabels.length) {
                          final count = spot.y.toInt();
                          String riskLevel;
                          if (count <= lowRiskThreshold) {
                            riskLevel = 'Low Risk';
                          } else if (count <= mediumRiskThreshold) {
                            riskLevel = 'Medium Risk';
                          } else {
                            riskLevel = 'High Risk';
                          }
                          return LineTooltipItem(
                            '${demoLabels[index]}\n$count events\n$riskLevel',
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
                  handleBuiltInTouches: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget for chart legends
  Widget _buildChartLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSeverityPieChart(List<SleepRecord> records) {
    if (records.isEmpty) {
      return const Center(
        child: Text(
          'No sleep data available',
          style: TextStyle(color: Colors.white60),
        ),
      );
    }
    
    // Count severity levels
    int lowCount = 0, mediumCount = 0, highCount = 0;
    for (final record in records) {
      switch (record.severity.toLowerCase()) {
        case 'low': lowCount++; break;
        case 'medium': case 'med': mediumCount++; break;
        case 'high': highCount++; break;
      }
    }
    
    final totalCount = lowCount + mediumCount + highCount;
    
    // Calculate percentages
    final lowPercent = totalCount > 0 ? (lowCount / totalCount * 100).round() : 0;
    final mediumPercent = totalCount > 0 ? (mediumCount / totalCount * 100).round() : 0;
    final highPercent = totalCount > 0 ? (highCount / totalCount * 100).round() : 0;
    
    // Define pie sections and colors
    final sections = <PieChartSectionData>[];
    
    if (lowCount > 0) {
      sections.add(
        PieChartSectionData(
          color: AppTheme.lowRiskColor,
          value: lowCount.toDouble(),
          title: '$lowPercent%',
          radius: 50,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      );
    }
    
    if (mediumCount > 0) {
      sections.add(
        PieChartSectionData(
          color: AppTheme.mediumRiskColor,
          value: mediumCount.toDouble(),
          title: '$mediumPercent%',
          radius: 50,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      );
    }
    
    if (highCount > 0) {
      sections.add(
        PieChartSectionData(
          color: AppTheme.highRiskColor,
          value: highCount.toDouble(),
          title: '$highPercent%',
          radius: 50,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      );
    }
    
    // If no data, show placeholder
    if (sections.isEmpty) {
      sections.add(
        PieChartSectionData(
          color: Colors.grey,
          value: 1,
          title: 'No Data',
          radius: 50,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      );
    }
    
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Pie chart
          Expanded(
            flex: 2,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 0,
                sectionsSpace: 2,
                startDegreeOffset: 180,
              ),
            ),
          ),
          // Legend
          Expanded(
            flex: 3,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPieChartLegendItem(
                  'Low Risk', 
                  lowCount, 
                  AppTheme.lowRiskColor,
                  'Good sleep quality',
                ),
                const SizedBox(height: 16),
                _buildPieChartLegendItem(
                  'Medium Risk', 
                  mediumCount, 
                  AppTheme.mediumRiskColor,
                  'Moderate sleep disturbance',
                ),
                const SizedBox(height: 16),
                _buildPieChartLegendItem(
                  'High Risk', 
                  highCount, 
                  AppTheme.highRiskColor,
                  'Significant sleep disturbance',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Helper to build pie chart legend items
  Widget _buildPieChartLegendItem(String label, int count, Color color, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          margin: const EdgeInsets.only(top: 2),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$label ($count)',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyProgressIndicators(List<SleepRecord> records, Map<String, dynamic> analytics) {
    final avgIrregularities = analytics['avgIrregularities'] as double;
    final avgDuration = analytics['avgDuration'] as double;
    final improvement = analytics['improvement'] as double;
    
    return Column(
      children: [
        _buildProgressIndicator(
          title: 'Sleep Duration',
          subtitle: 'Average hours of sleep per night',
          value: avgDuration,
          maxValue: 10.0,
          targetValue: 8.0,
          valueFormat: '${avgDuration.toStringAsFixed(1)} hrs',
          targetLabel: 'Target: 8 hrs',
          color: AppTheme.primaryColor,
          icon: Icons.nightlight_round,
        ),
        const SizedBox(height: 16),
        _buildProgressIndicator(
          title: 'Apnea Events',
          subtitle: 'Average number of irregularities per night',
          value: avgIrregularities,
          maxValue: 30.0,
          targetValue: 5.0,
          valueFormat: avgIrregularities.toStringAsFixed(1),
          targetLabel: 'Target: <5',
          color: avgIrregularities <= 5 ? Colors.green : 
                  avgIrregularities <= 15 ? AppTheme.mediumRiskColor : 
                  AppTheme.highRiskColor,
          icon: Icons.waves,
          inverseProgress: true, // Lower is better
        ),
        const SizedBox(height: 16),
        _buildTrendIndicator(
          improvement: improvement,
          records: records,
        ),
      ],
    );
  }
  
  // Helper to build progress indicators
  Widget _buildProgressIndicator({
    required String title,
    required String subtitle,
    required double value,
    required double maxValue,
    required double targetValue,
    required String valueFormat,
    required String targetLabel,
    required Color color,
    required IconData icon,
    bool inverseProgress = false,
  }) {
    // Calculate progress
    double progress = (value / maxValue).clamp(0.0, 1.0);
    if (inverseProgress) {
      progress = 1.0 - progress;
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                valueFormat,
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Stack(
            children: [
              // Background
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              // Progress
              Container(
                height: 8,
                width: MediaQuery.of(context).size.width * 0.7 * progress,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              // Target indicator
              if (!inverseProgress)
                Positioned(
                  left: (targetValue / maxValue) * MediaQuery.of(context).size.width * 0.7,
                  child: Container(
                    height: 8,
                    width: 2,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                inverseProgress ? 'High' : '0',
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 10,
                ),
              ),
              Text(
                targetLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                ),
              ),
              Text(
                inverseProgress ? '0' : 'Max',
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // Helper to build trend indicator
  Widget _buildTrendIndicator({
    required double improvement,
    required List<SleepRecord> records,
  }) {
    // Set trend info
    IconData trendIcon;
    Color trendColor;
    String trendText;
    String description;
    
    if (improvement > 10) {
      trendIcon = Icons.trending_down;
      trendColor = Colors.green;
      trendText = 'Significant Improvement';
      description = 'Your sleep apnea patterns are showing notable improvement. Keep up with your current habits.';
    } else if (improvement > 0) {
      trendIcon = Icons.trending_down;
      trendColor = Colors.green;
      trendText = 'Slight Improvement';
      description = 'Your sleep patterns are gradually improving. Continue monitoring and following recommendations.';
    } else if (improvement < -10) {
      trendIcon = Icons.trending_up;
      trendColor = Colors.red;
      trendText = 'Significant Decline';
      description = 'Your sleep patterns have worsened considerably. Consider consulting with a healthcare professional.';
    } else if (improvement < 0) {
      trendIcon = Icons.trending_up;
      trendColor = Colors.orange;
      trendText = 'Slight Decline';
      description = 'Your sleep patterns show a slight worsening. Review and adjust your sleep habits.';
    } else {
      trendIcon = Icons.trending_flat;
      trendColor = Colors.amber;
      trendText = 'Stable Pattern';
      description = 'Your sleep patterns remain consistent. Continue monitoring for any changes.';
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: trendColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              trendIcon,
              color: trendColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trendText,
                  style: TextStyle(
                    color: trendColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
          final date = _parseDate(record.date);
          
          // Format date based on view type
          final String label;
          if (isWeekly) {
            // For weekly view: "Apr 2" format
            label = DateFormat('MMM d').format(date);
          } else {
            // For monthly view: just day to save space
            label = DateFormat('d').format(date);
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
      builder: (context) => StatefulBuilder(
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
      ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Sleep Trends'),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterOptions,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background gradient
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
          
          // Content
          Column(
            children: [
              // Tab bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: AppTheme.primaryColor,
                  indicatorWeight: 3,
                  tabs: const [
                    Tab(text: 'Weekly'),
                    Tab(text: 'Monthly'),
                    Tab(text: 'Insights'),
                  ],
                ),
              ),
              
              // Tab views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildWeeklyTrendsView(),
                    _buildMonthlyTrendsView(),
                    _buildInsightsView(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Weekly trends view
  Widget _buildWeeklyTrendsView() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      color: AppTheme.primaryColor,
      child: _weeklyRecords.isEmpty
          ? const Center(
              child: Text(
                'No weekly sleep data available',
                style: TextStyle(color: Colors.white60),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Weekly Sleep Trends',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Based on the last ${_weeklyRecords.length} sleep records',
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_showIrregularities) ...[
                    const Text(
                      'Apnea Events Trend',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildEnhancedIrregularitiesChart(_weeklyRecords),
                    const SizedBox(height: 24),
                  ],
                  if (_showDuration) ...[
                    const Text(
                      'Sleep Duration Trend',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildEnhancedDurationChart(_weeklyRecords),
                    const SizedBox(height: 24),
                  ],
                  if (_showSeverity) ...[
                    const Text(
                      'Sleep Quality Distribution',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildSeverityPieChart(_weeklyRecords),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
    );
  }

  // Monthly trends view
  Widget _buildMonthlyTrendsView() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      color: AppTheme.primaryColor,
      child: _monthlyRecords.isEmpty
          ? const Center(
              child: Text(
                'No monthly sleep data available',
                style: TextStyle(color: Colors.white60),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Monthly Sleep Trends',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Based on the last ${_monthlyRecords.length} sleep records',
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_showIrregularities) ...[
                    const Text(
                      'Apnea Events Trend',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildEnhancedIrregularitiesChart(_monthlyRecords),
                    const SizedBox(height: 24),
                  ],
                  if (_showDuration) ...[
                    const Text(
                      'Sleep Duration Trend',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildEnhancedDurationChart(_monthlyRecords),
                    const SizedBox(height: 24),
                  ],
                  if (_showSeverity) ...[
                    const Text(
                      'Sleep Quality Distribution',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildSeverityPieChart(_monthlyRecords),
                    const SizedBox(height: 24),
                  ],
                  if (_showRecommendations) ...[
                    const Text(
                      'Monthly Progress',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildMonthlyProgressIndicators(_monthlyRecords, _monthlyAnalytics),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
    );
  }

  // Insights view
  Widget _buildInsightsView() {
    final analytics = _calculateAnalytics(_allRecords); // Define the analytics variable
    
    return RefreshIndicator(
      onRefresh: _refreshData,
      color: AppTheme.primaryColor,
      child: _allRecords.isEmpty
          ? const Center(
              child: Text(
                'No sleep data available for insights',
                style: TextStyle(color: Colors.white60),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sleep Insights & Recommendations',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Sleep Stats Card
                  Container(
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
                          'Your Sleep Statistics',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildInsightCard(
                                'Average\nSleep Duration',
                                '${(analytics['avgDuration'] as double).toStringAsFixed(1)} hrs',
                                Icons.bedtime_outlined,
                                AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildInsightCard(
                                'Average\nApnea Events',
                                '${(analytics['avgIrregularities'] as double).toStringAsFixed(1)}',
                                Icons.waves,
                                _getColorForValue(
                                  analytics['avgIrregularities'] as double, 
                                  lowerIsBetter: true,
                                  good: 5,
                                  moderate: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildInsightCard(
                                'Most Common\nSeverity',
                                _getMostCommonSeverity(
                                  analytics['lowCount'] as int, 
                                  analytics['mediumCount'] as int, 
                                  analytics['highCount'] as int,
                                ),
                                Icons.show_chart,
                                _getSeverityColor(_getMostCommonSeverity(
                                  analytics['lowCount'] as int, 
                                  analytics['mediumCount'] as int, 
                                  analytics['highCount'] as int,
                                )),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildInsightCard(
                                'Change\nOver Time',
                                '${(analytics['improvement'] as double).abs().toStringAsFixed(1)}%',
                                (analytics['improvement'] as double) > 0 
                                  ? Icons.trending_down 
                                  : Icons.trending_up,
                                (analytics['improvement'] as double) > 0 
                                  ? Colors.green 
                                  : Colors.red,
                                suffix: (analytics['improvement'] as double) > 0 
                                  ? 'Better' 
                                  : 'Worse',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Recommendations
                  Container(
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
                        Row(
                          children: [
                            const Icon(
                              Icons.lightbulb,
                              color: Colors.amber,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Personalized Recommendations',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ...(analytics['recommendedActions'] as List).map((action) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.check,
                                      color: AppTheme.primaryColor,
                                      size: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    action as String,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.amber.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: Colors.amber,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'These recommendations are based on your sleep patterns. For medical advice, please consult a healthcare professional.',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  if (_showIrregularities) ...[
                    const Text(
                      'Apnea Events Overview',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildEnhancedIrregularitiesChart(_allRecords),
                    const SizedBox(height: 24),
                  ],
                  
                  if (_showSeverity) ...[
                    const Text(
                      'Sleep Quality Distribution',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildSeverityPieChart(_allRecords),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
    );
  }

  // Helper for insights view
  Widget _buildInsightCard(String title, String value, IconData icon, Color color, {String? suffix}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (suffix != null) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    suffix,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
  
  // Helper to get color based on value
  Color _getColorForValue(double value, {
    required bool lowerIsBetter,
    required double good,
    required double moderate,
  }) {
    if (lowerIsBetter) {
      if (value <= good) return Colors.green;
      if (value <= moderate) return Colors.orange;
      return Colors.red;
    } else {
      if (value >= good) return Colors.green;
      if (value >= moderate) return Colors.orange;
      return Colors.red;
    }
  }

  // Helper method to get severity color
  Color _getSeverityColor(String severity) {
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
} 