// 차트 데이터를 위한 모델 클래스
// 월간 통계, 주차별 통계, 카테고리별 통계 데이터를 담을 모델 클래스 정의
// 데이터 변환 및 계산 메서드 포함



//MonthlyStatsModel:
// 월간 전체 계획 및 완료 수를 관리
// 전체 수행률 계산 메서드 포함
// lib/model/chart_data_model.dart

class MonthlyStatsModel {
  final int totalPlanned;
  final int totalCompleted;

  MonthlyStatsModel({
    required this.totalPlanned,
    required this.totalCompleted,
  });

  double get completionRate =>
      totalPlanned > 0 ? (totalCompleted / totalPlanned * 100) : 0;

  Map<String, dynamic> toJson() => {
    'totalPlanned': totalPlanned,
    'totalCompleted': totalCompleted,
    'completionRate': completionRate,
  };
}

class WeeklyStatsModel {
  final int weekNumber;
  final int plannedCount;
  final int completedCount;

  WeeklyStatsModel({
    required this.weekNumber,
    required this.plannedCount,
    required this.completedCount,
  });

  double get completionRate =>
      plannedCount > 0 ? (completedCount / plannedCount * 100) : 0;

  String get weekLabel => '$weekNumber주차';

  Map<String, dynamic> toJson() => {
    'weekNumber': weekNumber,
    'plannedCount': plannedCount,
    'completedCount': completedCount,
    'completionRate': completionRate,
    'weekLabel': weekLabel,
  };
}

class CategoryStatsModel {
  final String categoryId;
  final String categoryName;
  final String colorCode;
  final int plannedCount;
  final int completedCount;

  CategoryStatsModel({
    required this.categoryId,
    required this.categoryName,
    required this.colorCode,
    required this.plannedCount,
    required this.completedCount,
  });

  double get completionRate =>
      plannedCount > 0 ? (completedCount / plannedCount * 100) : 0;

  Map<String, dynamic> toJson() => {
    'categoryId': categoryId,
    'categoryName': categoryName,
    'colorCode': colorCode,
    'plannedCount': plannedCount,
    'completedCount': completedCount,
    'completionRate': completionRate,
  };


  CategoryStatsModel copyWith({
    String? categoryId,
    String? categoryName,
    String? colorCode,
    int? plannedCount,
    int? completedCount,
  }) {
    return CategoryStatsModel(
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      colorCode: colorCode ?? this.colorCode,
      plannedCount: plannedCount ?? this.plannedCount,
      completedCount: completedCount ?? this.completedCount,
    );
  }
}

class WeeklyAllDayStats {
  final int weekNumber;
  final int plannedCount;
  final int completedCount;

  WeeklyAllDayStats({
    required this.weekNumber,
    required this.plannedCount,
    required this.completedCount,
  });

  double get completionRate =>
      plannedCount > 0 ? (completedCount / plannedCount * 100) : 0;
}

class AllDayStatsModel {
  final int totalPlanned;
  final int completedCount;
  final List<WeeklyAllDayStats> weeklyTrend;

  AllDayStatsModel({
    required this.totalPlanned,
    required this.completedCount,
    required this.weeklyTrend,
  });

  double get completionRate =>
      totalPlanned > 0 ? (completedCount / totalPlanned * 100) : 0;
}

class MonthlyChartData {
  final DateTime month;
  final MonthlyStatsModel monthlyStats;
  final List<WeeklyStatsModel> weeklyStats;
  final List<CategoryStatsModel> categoryStats;
  final AllDayStatsModel allDayStats;

  MonthlyChartData({
    required this.month,
    required this.monthlyStats,
    required this.weeklyStats,
    required this.categoryStats,
    required this.allDayStats,
  });

  Map<String, dynamic> toJson() => {
    'month': month.toIso8601String(),
    'monthlyStats': monthlyStats.toJson(),
    'weeklyStats': weeklyStats.map((w) => w.toJson()).toList(),
    'categoryStats': categoryStats.map((c) => c.toJson()).toList(),
    'allDayStats': {
      'totalPlanned': allDayStats.totalPlanned,
      'completedCount': allDayStats.completedCount,
      'weeklyTrend': allDayStats.weeklyTrend.map((w) => {
        'weekNumber': w.weekNumber,
        'plannedCount': w.plannedCount,
        'completedCount': w.completedCount,
      }).toList(),
    },
  };
}