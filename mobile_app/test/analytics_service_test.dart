import 'package:flutter_test/flutter_test.dart';
import 'package:voice_growth_archipelago/src/core/utils/date_utils.dart';
import 'package:voice_growth_archipelago/src/core/utils/starter_data.dart';
import 'package:voice_growth_archipelago/src/features/progress/domain/analytics_service.dart';
import 'package:voice_growth_archipelago/src/features/shared/domain/app_models.dart';

void main() {
  test('today summary counts completed due habits', () {
    final DateTime today = startOfDay(DateTime.now());
    final List<Habit> habits = starterArchipelago();
    final AppSnapshot snapshot = AppSnapshot(
      profile: AppSnapshot.seed(
        user: const AppUser(
            uid: 'u1', displayName: 'User', email: 'user@example.com'),
      ).profile,
      habits: habits,
      dailyLogs: <String, DailyLog>{
        formatDateKey(today): DailyLog(
          dateKey: formatDateKey(today),
          completedHabitIds: const <String>['meditation', 'exercise'],
          completedAtByHabit: <String, int>{
            'meditation': today.millisecondsSinceEpoch,
            'exercise': today.millisecondsSinceEpoch,
          },
          updatedAt: today,
        ),
      },
    );

    final TodaySummary summary = buildTodaySummary(
      snapshot,
      day: today,
      mode: TodayMode.standard,
    );

    expect(summary.completedDueCount, greaterThanOrEqualTo(2));
    expect(summary.totalDueCount, greaterThan(summary.completedDueCount - 1));
  });

  test(
      'day scope drives lite day visibility independently from constellation tracking',
      () {
    final DateTime today = startOfDay(DateTime.now());
    final Habit bothScopesNotCore = Habit(
      id: 'habit-both',
      name: 'Reading',
      subtitle: '15 min',
      iconKey: 'book',
      iconColor: '#6366f1',
      baseColor: '#6366f1',
      glowColor: '#6366f1',
      xPct: 24,
      yPct: 40,
      frequency: HabitFrequency.daily,
      daysDue: const <int>[0, 1, 2, 3, 4, 5, 6],
      scopeMode: DayScopeMode.both,
      isCore: false,
      category: 'Learning',
      categoryColor: '#6366f1',
      status: HabitStatus.active,
      createdAt: today,
      updatedAt: today,
    );
    final Habit standardOnly = bothScopesNotCore.copyWith(
      id: 'habit-standard',
      name: 'Workout',
      scopeMode: DayScopeMode.full,
    );
    final Habit liteOnly = bothScopesNotCore.copyWith(
      id: 'habit-lite',
      name: 'Journal',
      scopeMode: DayScopeMode.short,
    );
    final AppSnapshot snapshot = AppSnapshot(
      profile: AppSnapshot.seed(
        user: const AppUser(
          uid: 'u1',
          displayName: 'User',
          email: 'user@example.com',
        ),
      ).profile,
      habits: <Habit>[bothScopesNotCore, standardOnly, liteOnly],
      dailyLogs: const <String, DailyLog>{},
    );

    final TodaySummary liteSummary = buildTodaySummary(
      snapshot,
      day: today,
      mode: TodayMode.lite,
    );
    final TodaySummary standardSummary = buildTodaySummary(
      snapshot,
      day: today,
      mode: TodayMode.standard,
    );

    expect(
      liteSummary.visibleHabits.map((Habit habit) => habit.id),
      unorderedEquals(<String>['habit-both', 'habit-lite']),
    );
    expect(
      standardSummary.visibleHabits.map((Habit habit) => habit.id),
      unorderedEquals(<String>['habit-both', 'habit-standard']),
    );
  });

  test('today summary exposes partial and full core constellation states', () {
    final DateTime today = startOfDay(DateTime.now());
    final List<Habit> habits = <Habit>[
      Habit(
        id: 'core-1',
        name: 'Meditate',
        subtitle: '10 min',
        iconKey: 'mood',
        iconColor: '#22d3ee',
        baseColor: '#0891b2',
        glowColor: '#22D3EE',
        xPct: 20,
        yPct: 25,
        frequency: HabitFrequency.daily,
        daysDue: const <int>[0, 1, 2, 3, 4, 5, 6],
        scopeMode: DayScopeMode.both,
        isCore: true,
        category: 'Mindfulness',
        categoryColor: '#6366f1',
        status: HabitStatus.active,
        createdAt: today,
        updatedAt: today,
      ),
      Habit(
        id: 'core-2',
        name: 'Journal',
        subtitle: '10 min',
        iconKey: 'edit',
        iconColor: '#f472b6',
        baseColor: '#db2777',
        glowColor: '#F472B6',
        xPct: 50,
        yPct: 50,
        frequency: HabitFrequency.daily,
        daysDue: const <int>[0, 1, 2, 3, 4, 5, 6],
        scopeMode: DayScopeMode.both,
        isCore: true,
        category: 'Mindfulness',
        categoryColor: '#6366f1',
        status: HabitStatus.active,
        createdAt: today,
        updatedAt: today,
      ),
      Habit(
        id: 'core-3',
        name: 'Exercise',
        subtitle: '30 min',
        iconKey: 'trending',
        iconColor: '#fb923c',
        baseColor: '#f97316',
        glowColor: '#FB923C',
        xPct: 80,
        yPct: 25,
        frequency: HabitFrequency.daily,
        daysDue: const <int>[0, 1, 2, 3, 4, 5, 6],
        scopeMode: DayScopeMode.both,
        isCore: true,
        category: 'Discipline',
        categoryColor: '#f59e0b',
        status: HabitStatus.active,
        createdAt: today,
        updatedAt: today,
      ),
      Habit(
        id: 'non-due-core',
        name: 'Language',
        subtitle: 'Class',
        iconKey: 'chat',
        iconColor: '#60a5fa',
        baseColor: '#2563eb',
        glowColor: '#60A5FA',
        xPct: 65,
        yPct: 72,
        frequency: HabitFrequency.weekly,
        daysDue: const <int>[6],
        scopeMode: DayScopeMode.both,
        isCore: true,
        category: 'Learning',
        categoryColor: '#34d399',
        status: HabitStatus.active,
        createdAt: today,
        updatedAt: today,
      ),
    ];

    final AppSnapshot partialSnapshot = AppSnapshot(
      profile: AppSnapshot.seed(
        user: const AppUser(
          uid: 'u1',
          displayName: 'User',
          email: 'user@example.com',
        ),
      ).profile,
      habits: habits,
      dailyLogs: <String, DailyLog>{
        formatDateKey(today): DailyLog(
          dateKey: formatDateKey(today),
          completedHabitIds: const <String>['core-1', 'core-2'],
          completedAtByHabit: <String, int>{
            'core-1': today.millisecondsSinceEpoch,
            'core-2': today.millisecondsSinceEpoch,
          },
          updatedAt: today,
        ),
      },
    );

    final TodaySummary partialSummary = buildTodaySummary(
      partialSnapshot,
      day: today,
      mode: TodayMode.standard,
    );

    expect(partialSummary.dueCoreHabits.map((Habit habit) => habit.id).toSet(),
        <String>{'core-1', 'core-2', 'core-3'});
    expect(
      partialSummary.completedDueCoreHabits
          .map((Habit habit) => habit.id)
          .toSet(),
      <String>{'core-1', 'core-2'},
    );
    expect(partialSummary.celebrationUnlocked, isFalse);

    final AppSnapshot fullSnapshot = partialSnapshot.copyWith(
      dailyLogs: <String, DailyLog>{
        formatDateKey(today): DailyLog(
          dateKey: formatDateKey(today),
          completedHabitIds: const <String>['core-1', 'core-2', 'core-3'],
          completedAtByHabit: <String, int>{
            'core-1': today.millisecondsSinceEpoch,
            'core-2': today.millisecondsSinceEpoch,
            'core-3': today.millisecondsSinceEpoch,
          },
          updatedAt: today,
        ),
      },
    );

    final TodaySummary fullSummary = buildTodaySummary(
      fullSnapshot,
      day: today,
      mode: TodayMode.standard,
    );

    expect(fullSummary.completedDueCoreHabits.length, 3);
    expect(fullSummary.celebrationUnlocked, isTrue);
  });
}
