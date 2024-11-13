// 통계 프로바이더
// 통계 서비스를 사용하여 상태 관리
// 날짜 변경 등의 UI 상태 관리

import 'package:flutter/material.dart';
import '../model/chart_data_model.dart';
import '../services/statistics_service.dart';

class StatisticsProvider extends ChangeNotifier {
  final StatisticsService _statisticsService = StatisticsService();
  DateTime _selectedMonth = DateTime.now();
  MonthlyChartData? _chartData;
  bool _isLoading = false;
  String? _error;
  bool _disposed = false;
  DateTime? _lastLoadTime;
  static const refreshThreshold = Duration(seconds: 5);
  // DateTime _lastUpdateTime = DateTime(0); // 마지막 업데이트 시간 추적
  // 중복 로드 방지를 위한 플래그
  bool _isLoadingData = false;
  // Getters
  DateTime get selectedMonth => _selectedMonth;
  MonthlyChartData? get chartData => _chartData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> loadStatistics([DateTime? month]) async {
    if (_disposed) return; // disposed 체크

    if (_isLoadingData) return;

    if (_lastLoadTime != null &&
        DateTime.now().difference(_lastLoadTime!) < refreshThreshold) {
      return;
    }

    try {
      _isLoadingData = true;
      _isLoading = true;
      if (!_disposed) notifyListeners();

      final targetMonth = month ?? _selectedMonth;
      _chartData = await _statisticsService.getMonthlyStatistics(targetMonth);

      if (month != null) {
        _selectedMonth = month;
      }
      _lastLoadTime = DateTime.now();
      _error = null;
    } catch (e) {
      _error = e.toString();
      print('Statistics loading error: $e');
    } finally {
      _isLoading = false;
      _isLoadingData = false;
      if (!_disposed) { // disposed 체크
        notifyListeners(); // 마지막 알림
      }
    }
  }
  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }




    // 강제 새로고침
  Future<void> forceRefresh() async {
    _chartData = null;  // 기존 데이터 초기화
    _lastLoadTime = null;  // 마지막 로드 시간 초기화
    await loadStatistics(_selectedMonth);
  }


  // 이전 월로 이동
  void previousMonth() {
    final previousMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month - 1,
      1,
    );
    _lastLoadTime = null;  // 월 변경 시 강제 로드
    loadStatistics(previousMonth);
  }

  // 다음 월로 이동
  void nextMonth() {
    final nextMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
      1,
    );
    _lastLoadTime = null;  // 월 변경 시 강제 로드
    loadStatistics(nextMonth);
  }

  // 특정 월 선택
  void selectMonth(DateTime month) {
    final selectedMonth = DateTime(month.year, month.month, 1);
    loadStatistics(selectedMonth);
  }

  // 카테고리별 데이터 정렬
  List<CategoryStatsModel> get sortedCategoryStats {
    if (_chartData == null) return [];

    final stats = List<CategoryStatsModel>.from(_chartData!.categoryStats);
    stats.sort((a, b) => b.completionRate.compareTo(a.completionRate));
    return stats;
  }

  // 주차별 데이터의 최대값 (차트 스케일링용)
  int get maxWeeklyCount {
    if (_chartData == null) return 0;

    return _chartData!.weeklyStats.fold(0, (max, week) {
      final weekMax = week.plannedCount > week.completedCount
          ? week.plannedCount
          : week.completedCount;
      return weekMax > max ? weekMax : max;
    });
  }

  // 데이터 새로고침
  Future<void> refresh() async {
    await loadStatistics(_selectedMonth);
  }

  // 에러 초기화
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // 월 표시 포맷
  String getFormattedMonth() {
    return '${_selectedMonth.year}년 ${_selectedMonth.month}월';
  }

  // 주차 라벨 생성
  String getWeekLabel(int weekNumber) {
    return '$weekNumber주차';
  }

  // 수행률 포맷
  String formatCompletionRate(double rate) {
    return '${rate.toStringAsFixed(1)}%';
  }

  // 색상 코드를 Color 객체로 변환
  Color getColorFromCode(String colorCode) {
    final colorValue = int.tryParse(colorCode) ?? 0xFF000000;
    return Color(colorValue);
  }


}