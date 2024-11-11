//통계 서비스 클래스
// EventService, CategoryService를 활용하여 실제 통계 데이터 계산
// Firebase에서 데이터를 가져와 차트 데이터로 변환


import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/chart_data_model.dart';
import '../model/event_model.dart';
import '../model/event_result_model.dart';
import '../model/category_model.dart';
import '../services/event_service.dart';
import '../services/category_service.dart';

class StatisticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final EventService _eventService = EventService();
  final CategoryService _categoryService = CategoryService();

  String get userId {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User is not logged in');
    }
    return user.uid;
  }

  // 월간 종일 일정 통계 계산
  Future<AllDayStatsModel> _calculateAllDayStats(DateTime month) async {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0);

    final events = await _eventService.getEventsForMonth(startOfMonth, endOfMonth);
    final resultEvents = await _eventService.getResultEventsForMonth(startOfMonth, endOfMonth);

    // 종일 일정만 필터링
    final allDayEvents = events.where((e) => e.isAllDay).toList();
    final allDayResultEvents = resultEvents.where((e) => e.isAllDay ?? false).toList();

    int totalPlanned = allDayEvents.length;
    Map<int, Map<String, int>> weekData = {};  // int로 변경

    // 각 이벤트의 최신 완료 상태를 추적하기 위한 Map
    Map<String, String> eventCompletionStatus = {};  // bool 대신 String 사용

    // events 컬렉션에서 기본 상태 설정
    for (var event in allDayEvents) {
      if (event.eventDate != null) {
        int weekNumber = ((event.eventDate!.day - 1) ~/ 7) + 1;
        weekData.putIfAbsent(weekNumber, () => {'planned': 0, 'completed': 0});
        weekData[weekNumber]!['planned'] = (weekData[weekNumber]!['planned'] ?? 0) + 1;

        // 완료 상태 저장
        eventCompletionStatus[event.eventId] = event.completedYn ?? 'N';
      }
    }

    // result_events에서 최신 완료 상태로 업데이트
    for (var event in allDayResultEvents) {
      if (event.eventResultDate != null) {
        eventCompletionStatus[event.eventId] = event.completedYn;  // eventId 사용
      }
    }

    // 주차별 완료 수 계산
    for (var event in allDayEvents) {
      if (event.eventDate != null && eventCompletionStatus[event.eventId] == 'Y') {
        int weekNumber = ((event.eventDate!.day - 1) ~/ 7) + 1;
        weekData[weekNumber]!['completed'] = (weekData[weekNumber]!['completed'] ?? 0) + 1;
      }
    }

    // 전체 완료 수 계산
    int completedCount = eventCompletionStatus.values
        .where((status) => status == 'Y')
        .length;

    // 주차별 통계 생성
    List<WeeklyAllDayStats> weeklyTrend = weekData.entries.map((entry) =>
        WeeklyAllDayStats(
          weekNumber: entry.key,
          plannedCount: entry.value['planned'] ?? 0,
          completedCount: entry.value['completed'] ?? 0,
        )
    ).toList();

    // 주차 번호로 정렬
    weeklyTrend.sort((a, b) => a.weekNumber.compareTo(b.weekNumber));

    return AllDayStatsModel(
      totalPlanned: totalPlanned,
      completedCount: completedCount,
      weeklyTrend: weeklyTrend,
    );
  }  // 특정 월의 모든 통계 데이터 조회
  Future<MonthlyChartData> getMonthlyStatistics(DateTime month) async {
    final monthlyStats = await _calculateMonthlyStats(month);
    final weeklyStats = await _calculateWeeklyStats(month);
    final categoryStats = await _calculateCategoryStats(month);
    final allDayStats = await _calculateAllDayStats(month);

    return MonthlyChartData(
      month: month,
      monthlyStats: monthlyStats,
      weeklyStats: weeklyStats,
      categoryStats: categoryStats,
      allDayStats: allDayStats,
    );
  }

  // 월간 전체 통계 계산
  Future<MonthlyStatsModel> _calculateMonthlyStats(DateTime month) async {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0);

    final events = await _eventService.getEventsForMonth(startOfMonth, endOfMonth);
    final resultEvents = await _eventService.getResultEventsForMonth(startOfMonth, endOfMonth);

    // 종일 일정과 일반 일정 분리
    final regularEvents = events.where((e) => !(e.isAllDay ?? false)).toList();
    final allDayEvents = events.where((e) => e.isAllDay ?? false).toList();
    final regularResultEvents = resultEvents.where((e) => !(e.isAllDay ?? false)).toList();
    final allDayResultEvents = resultEvents.where((e) => e.isAllDay ?? false).toList();

    // 전체 계획된 일정 수
    final totalPlanned = regularEvents.length + allDayEvents.length;

    // 완료된 일정 수 (result_events에서만 계산)
    final regularCompleted = regularResultEvents
        .where((e) => e.completedYn == 'Y')
        .length;
    final allDayCompleted = allDayResultEvents
        .where((e) => e.completedYn == 'Y')
        .length;

    final totalCompleted = regularCompleted + allDayCompleted;

    return MonthlyStatsModel(
      totalPlanned: totalPlanned,
      totalCompleted: totalCompleted,
    );
  }

  // 주차별 통계 계산
  Future<List<WeeklyStatsModel>> _calculateWeeklyStats(DateTime month) async {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0);
    List<WeeklyStatsModel> weeklyStats = [];

    // 한 번에 월간 데이터 조회
    final events = await _eventService.getEventsForMonth(
        startOfMonth, endOfMonth);
    final resultEvents = await _eventService.getResultEventsForMonth(
        startOfMonth, endOfMonth);

    var weekStart = startOfMonth;
    var weekNumber = 1;

    while (weekStart.month == month.month) {
      var weekEnd = weekStart.add(Duration(days: 6));

      // 해당 주의 이벤트 필터링
      final weekEvents = events.where((event) {
        final eventDate = event.eventDate;
        return eventDate != null &&
            !eventDate.isBefore(weekStart) &&
            (eventDate.isBefore(weekEnd.add(Duration(days: 1))) ||
                eventDate.isAtSameMomentAs(weekEnd)) &&
            eventDate.month == month.month;
      }).toList();

      final weekResultEvents = resultEvents.where((event) {
        final eventDate = event.eventResultDate;
        return eventDate != null &&
            !eventDate.isBefore(weekStart) &&
            (eventDate.isBefore(weekEnd.add(Duration(days: 1))) ||
                eventDate.isAtSameMomentAs(weekEnd)) &&
            eventDate.month == month.month;
      }).toList();

      final plannedCount = weekEvents.length;
      final completedCount = weekResultEvents.where((event) =>
      event.completedYn == 'Y').length;

      weeklyStats.add(WeeklyStatsModel(
        weekNumber: weekNumber,
        plannedCount: plannedCount,
        completedCount: completedCount,
      ));

      weekStart = weekStart.add(Duration(days: 7));
      weekNumber++;
    }

    return weeklyStats;
  }

  // 카테고리별 통계 계산
  Future<List<CategoryStatsModel>> _calculateCategoryStats(
      DateTime month) async {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0);

    // 한 번에 데이터 조회
    final events = await _eventService.getEventsForMonth(
        startOfMonth, endOfMonth);
    final resultEvents = await _eventService.getResultEventsForMonth(
        startOfMonth, endOfMonth);
    final categories = await _categoryService.getCategoriesByUserId(userId);

    // 카테고리별 통계 초기화
    Map<String, CategoryStatsModel> categoryStatsMap = {
      for (var category in categories)
        category.categoryId: CategoryStatsModel(
          categoryId: category.categoryId,
          categoryName: category.categoryName,
          colorCode: category.colorCode,
          plannedCount: 0,
          completedCount: 0,
        )
    };

    // 계획된 이벤트 집계
    for (var event in events) {
      if (categoryStatsMap.containsKey(event.categoryId)) {
        var current = categoryStatsMap[event.categoryId]!;
        categoryStatsMap[event.categoryId] = current.copyWith(
          plannedCount: current.plannedCount + 1,
        );
      }
    }

    // 완료된 이벤트 집계 (result_events)
    for (var event in resultEvents.where((e) => e.completedYn == 'Y')) {
      if (categoryStatsMap.containsKey(event.categoryId)) {
        var current = categoryStatsMap[event.categoryId]!;
        categoryStatsMap[event.categoryId] = current.copyWith(
          completedCount: current.completedCount + 1,
        );
      }
    }

    // 종일 일정의 완료 상태도 확인
    // for (var event in events.where((e) => e.isAllDay && e.completedYn == 'Y')) {
    //   if (categoryStatsMap.containsKey(event.categoryId)) {
    //     var current = categoryStatsMap[event.categoryId]!;
    //     categoryStatsMap[event.categoryId] = current.copyWith(
    //       completedCount: current.completedCount + 1,
    //     );
    //   }
    // }

    return categoryStatsMap.values.toList();
  }
}

//종속성:
// EventService와 CategoryService를 활용
// Firebase Authentication으로 현재 사용자 확인
// Firestore에서 데이터 조회
//
//
// 주요 메서드:
// getMonthlyStatistics: 모든 통계 데이터를 한 번에 조회
// _calculateMonthlyStats: 월간 전체 통계 계산
// _calculateWeeklyStats: 주차별 통계 계산
// _calculateCategoryStats: 카테고리별 통계 계산
//
//
// 날짜 처리:
// 월의 시작일과 종료일을 정확히 계산
// 주차별 계산 시 월요일부터 시작하도록 설정
