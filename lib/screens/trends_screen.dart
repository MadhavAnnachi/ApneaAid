import 'package:flutter/material.dart';
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
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
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
              _buildWeeklyTrendsView(),
              _buildMonthlyTrendsView(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyTrendsView() {
    final weeklyRecords = _getWeeklyRecords();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Weekly summary card
          _buildSummaryCard(weeklyRecords, 'Weekly'),
          const SizedBox(height: 24),
          
          // Irregularities graph
          if (_showIrregularities) ...[
            _buildSectionTitle('Apnea Events'),
            const SizedBox(height: 8),
            _buildIrregularitiesChart(weeklyRecords, isWeekly: true),
            const SizedBox(height: 24),
          ],
          
          // Sleep duration graph
          if (_showDuration) ...[
            _buildSectionTitle('Sleep Duration'),
            const SizedBox(height: 8),
            _buildDurationChart(weeklyRecords, isWeekly: true),
            const SizedBox(height: 24),
          ],
          
          // Sleep severity distribution
          if (_showSeverity) ...[
            _buildSectionTitle('Severity Distribution'),
            const SizedBox(height: 8),
            _buildSeverityPieChart(weeklyRecords),
            const SizedBox(height: 40),
          ],
        ],
      ),
    );
  }

  Widget _buildMonthlyTrendsView() {
    final monthlyRecords = _getMonthlyRecords();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Monthly summary card
          _buildSummaryCard(monthlyRecords, 'Monthly'),
          const SizedBox(height: 24),
          
          // Irregularities graph
          if (_showIrregularities) ...[
            _buildSectionTitle('Apnea Events Trend'),
            const SizedBox(height: 8),
            _buildIrregularitiesChart(monthlyRecords, isWeekly: false),
            const SizedBox(height: 24),
          ],
          
          // Sleep quality heatmap
          if (_showDuration) ...[
            _buildSectionTitle('Sleep Duration Trend'),
            const SizedBox(height: 8),
            _buildDurationChart(monthlyRecords, isWeekly: false),
            const SizedBox(height: 24),
          ],
          
          // Monthly progress metrics
          if (_showSeverity) ...[
            _buildSectionTitle('Monthly Progress'),
            const SizedBox(height: 12),
            _buildMonthlyProgressIndicators(monthlyRecords),
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
                  Icons.nightlight_outlined,
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

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
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
  
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
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

  Widget _buildMonthlyProgressIndicators(List<SleepRecord> records) {
    // Simple mock data for demonstration
    return Column(
      children: [
        _buildProgressIndicator(
          label: 'Sleep Quality Improvement',
          value: 0.72,
          color: AppTheme.lowRiskColor,
        ),
        const SizedBox(height: 16),
        _buildProgressIndicator(
          label: 'Apnea Events Reduction',
          value: 0.45,
          color: AppTheme.primaryColor,
        ),
        const SizedBox(height: 16),
        _buildProgressIndicator(
          label: 'Sleep Duration Goal',
          value: 0.85,
          color: AppTheme.mediumRiskColor,
        ),
      ],
    );
  }

  Widget _buildProgressIndicator({
    required String label,
    required double value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
            Text(
              '${(value * 100).toInt()}%',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            widthFactor: value,
            alignment: Alignment.centerLeft,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
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
        ),
      ],
    );
  }

  // Helper methods
  List<SleepRecord> _getWeeklyRecords() {
    // For MVP, just return all records in reverse (most recent first)
    // In a real app, you'd filter to last 7 days
    return _sleepDetectorService.getRecords().reversed.toList();
  }

  List<SleepRecord> _getMonthlyRecords() {
    // For MVP, just return all records
    // In a real app, you'd filter to last 30 days
    return _sleepDetectorService.getRecords().reversed.toList();
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
          final label = isWeekly ? dateParts[0].substring(0, 3) : dateParts[0];
          
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
                    'Apnea Events',
                    _showIrregularities,
                    (value) {
                      setModalState(() => _showIrregularities = value);
                      setState(() => _showIrregularities = value);
                    },
                  ),
                  _buildFilterSwitch(
                    'Sleep Duration',
                    _showDuration,
                    (value) {
                      setModalState(() => _showDuration = value);
                      setState(() => _showDuration = value);
                    },
                  ),
                  _buildFilterSwitch(
                    'Severity Distribution',
                    _showSeverity,
                    (value) {
                      setModalState(() => _showSeverity = value);
                      setState(() => _showSeverity = value);
                    },
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

  Widget _buildFilterSwitch(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
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
} 