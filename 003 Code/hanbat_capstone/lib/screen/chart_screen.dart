import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/statistics_provider.dart';
import '../model/chart_data_model.dart';

class ChartScreen extends StatefulWidget {
  const ChartScreen({Key? key}) : super(key: key);

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => false;  // false로 설정하여 매번 새로고침되도록

  int _selectedSection = 0; // 0: 전체/종일, 1: 주차별, 2: 카테고리별

  @override
  void initState() {
    super.initState();

  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    Future.microtask(() => _initializeScreen());
  }

  Future<void> _initializeScreen() async {
    if (!mounted) return;
    final provider = context.read<StatisticsProvider>();
    await provider.loadStatistics(); // forceRefresh 대신 일반 로드 사용
  }



  @override
  Widget build(BuildContext context) {
    super.build(context);  // AutomaticKeepAliveClientMixin 사용시 필요
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => context.read<StatisticsProvider>().forceRefresh(),
        child: Consumer<StatisticsProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('오류가 발생했습니다: ${provider.error}'),
                    ElevatedButton(
                      onPressed: () => provider.refresh(),
                      child: const Text('다시 시도'),
                    ),
                  ],
                ),
              );
            }

            final chartData = provider.chartData;
            if (chartData == null) {
              return const Center(child: Text('데이터가 없습니다.'));
            }

            return Column(
              children: [
                _buildMonthSelector(provider),
                const SizedBox(height: 16),
                _buildToggleButtons(),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildSelectedSection(chartData),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildToggleButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: _selectedSection == 0
                    ? Colors.blue[900]
                    : Colors.grey[200],
                foregroundColor: _selectedSection == 0
                    ? Colors.white
                    : Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => setState(() => _selectedSection = 0),
              child: const Text('전체/종일'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: _selectedSection == 1
                    ? Colors.blue[900]
                    : Colors.grey[200],
                foregroundColor: _selectedSection == 1
                    ? Colors.white
                    : Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => setState(() => _selectedSection = 1),
              child: const Text('주차별'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: _selectedSection == 2
                    ? Colors.blue[900]
                    : Colors.grey[200],
                foregroundColor: _selectedSection == 2
                    ? Colors.white
                    : Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => setState(() => _selectedSection = 2),
              child: const Text('카테고리'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedSection(MonthlyChartData chartData) {
    switch (_selectedSection) {
      case 0:
        return Column(
          children: [
            _buildTotalStats(chartData),
            const SizedBox(height: 20),
            _buildAllDayStats(chartData),
          ],
        );
      case 1:
        if (chartData.weeklyStats.isEmpty) {
          return Column(
            children: [
              const Text(
                '주차별 통계',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text('해당 월에 등록된 일정이 없습니다.'),
              ),
            ],
          );
        }
        return _buildWeeklyStats(chartData);
      case 2:
        return _buildCategoryStats(chartData);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildMonthSelector(StatisticsProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: provider.previousMonth,
            icon: const Icon(Icons.chevron_left),
          ),
          Text(
            provider.getFormattedMonth(),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            onPressed: provider.nextMonth,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalStats(MonthlyChartData chartData) {
    final monthlyStats = chartData.monthlyStats;
    final completionRate = monthlyStats.completionRate;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '월간 전체 수행률',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: Stack(
              children: [
                PieChart(
                  PieChartData(
                    sections: [
                      PieChartSectionData(
                        value: completionRate,
                        color: Colors.blue[900] ?? Colors.blue,
                        radius: 40,
                        title: '',
                      ),
                      PieChartSectionData(
                        value: 100 - completionRate,
                        color: Colors.grey[300],
                        radius: 40,
                        title: '',
                      ),
                    ],
                    sectionsSpace: 2,
                    centerSpaceRadius: 60,
                    startDegreeOffset: -90,
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${completionRate.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${monthlyStats.totalCompleted}/${monthlyStats.totalPlanned}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                '전체 일정',
                monthlyStats.totalPlanned.toString(),
                Icons.calendar_today,
              ),
              _buildStatItem(
                '완료',
                monthlyStats.totalCompleted.toString(),
                Icons.check_circle_outline,
              ),
              _buildStatItem(
                '미완료',
                (monthlyStats.totalPlanned - monthlyStats.totalCompleted).toString(),
                Icons.pending_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue[900]),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyStats(MonthlyChartData chartData) {
    final weeklyStats = chartData.weeklyStats;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '주차별 통계',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          // weeklyStats가 비어있거나 모든 계획 수가 0인 경우 메시지 표시
          if (weeklyStats.isEmpty || weeklyStats.every((stat) => stat.plannedCount == 0))
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  '해당 월에 등록된 일정이 없습니다.',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
              ),
            )
          else
            Column(
              children: [
                SizedBox(
                  height: 300,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: weeklyStats.fold(0.0, (max, stat) =>
                      stat.plannedCount > max ? stat.plannedCount.toDouble() : max) * 1.2,
                      titlesData: FlTitlesData(
                        show: true,
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '${value.toInt() + 1}주차',
                                style: const TextStyle(fontSize: 12),
                              );
                            },
                          ),
                        ),
                      ),
                      gridData: const FlGridData(
                        show: false,
                        drawVerticalLine: false,
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: weeklyStats.asMap().entries.map((entry) {
                        final index = entry.key;
                        final stat = entry.value;
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: stat.plannedCount.toDouble(),
                              width: 15,
                              color: Colors.blue[900]?.withOpacity(0.5),
                            ),
                            BarChartRodData(
                              toY: stat.completedCount.toDouble(),
                              width: 15,
                              color: Colors.blue[900],
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem('계획', Colors.blue[900]?.withOpacity(0.5) ?? Colors.blue.withOpacity(0.5)),
                    const SizedBox(width: 20),
                    _buildLegendItem('완료', Colors.blue[900] ?? Colors.blue),
                  ],
                ),
                const SizedBox(height: 16),
                _buildWeeklyStatsTable(weeklyStats),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }

  Widget _buildWeeklyStatsTable(List<WeeklyStatsModel> weeklyStats) {
    return Table(
      border: TableBorder.all(
        color: Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      children: [
        const TableRow(
          decoration: BoxDecoration(
            color: Colors.grey,
          ),
          children: [
            TableCell(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Center(child: Text('주차')),
              ),
            ),
            TableCell(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Center(child: Text('계획')),
              ),
            ),
            TableCell(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Center(child: Text('완료')),
              ),
            ),
            TableCell(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Center(child: Text('달성률')),
              ),
            ),
          ],
        ),
        ...weeklyStats.map((stat) => TableRow(
          children: [
            TableCell(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(child: Text('${stat.weekNumber}주차')),
              ),
            ),
            TableCell(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(child: Text('${stat.plannedCount}')),
              ),
            ),
            TableCell(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(child: Text('${stat.completedCount}')),
              ),
            ),
            TableCell(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                  child: Text(
                    '${stat.completionRate.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: stat.completionRate >= 80 ? Colors.blue[900] :
                      stat.completionRate >= 50 ? Colors.orange :
                      Colors.red,
                    ),
                  ),
                ),
              ),
            ),
          ],
        )).toList(),
      ],
    );
  }

  Widget _buildAllDayStats(MonthlyChartData chartData) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '종일 일정 현황',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue[900]?.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '달성률 ${chartData.allDayStats.completionRate.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: Colors.blue[900],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildAllDayStatCard(
                  '전체',
                  chartData.allDayStats.totalPlanned,
                  Icons.event,
                  Colors.grey,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _buildAllDayStatCard(
                  '완료',
                  chartData.allDayStats.completedCount,
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _buildAllDayStatCard(
                  '미완료',
                  chartData.allDayStats.totalPlanned - chartData.allDayStats.completedCount,
                  Icons.pending,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAllDayStatCard(String label, int count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryStats(MonthlyChartData chartData) {
    final categoryStats = chartData.categoryStats;
    categoryStats.sort((a, b) => b.completionRate.compareTo(a.completionRate));

    if (categoryStats.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Column(
          children: [
            Text(
              '카테고리별 통계',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: Text('등록된 카테고리가 없습니다.'),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '카테고리별 통계',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categoryStats.length,
            itemBuilder: (context, index) {
              final stat = categoryStats[index];
              return _buildCategoryStatItem(stat);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryStatItem(CategoryStatsModel stat) {
    final categoryColor = Color(int.parse(stat.colorCode));

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: categoryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: categoryColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: categoryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    stat.categoryName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text(
                '${stat.completionRate.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: categoryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: stat.completionRate / 100,
            backgroundColor: Colors.grey.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(categoryColor),
            borderRadius: BorderRadius.circular(2),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '계획: ${stat.plannedCount}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                '완료: ${stat.completedCount}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}