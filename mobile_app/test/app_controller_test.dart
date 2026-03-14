import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voice_growth_archipelago/src/core/utils/date_utils.dart';
import 'package:voice_growth_archipelago/src/core/utils/starter_data.dart';
import 'package:voice_growth_archipelago/src/features/progress/domain/analytics_service.dart';
import 'package:voice_growth_archipelago/src/features/shared/data/app_repositories.dart';
import 'package:voice_growth_archipelago/src/features/shared/domain/app_models.dart';
import 'package:voice_growth_archipelago/src/features/shared/state/app_controllers.dart';

void main() {
  group('AppController habit mutations', () {
    test('restores archived habit when adding duplicate name', () async {
      final AppUser user = const AppUser(
        uid: 'u1',
        displayName: 'User',
        email: 'user@example.com',
      );
      final DateTime now = DateTime.now();
      final Habit archivedHabit = Habit(
        id: 'archived-reading',
        name: 'Reading',
        subtitle: '15 min Reading',
        iconKey: 'book',
        iconColor: '#6366f1',
        baseColor: '#6366f1',
        glowColor: '#6366f1',
        xPct: 24,
        yPct: 34,
        frequency: HabitFrequency.daily,
        daysDue: const <int>[0, 1, 2, 3, 4, 5, 6],
        scopeMode: DayScopeMode.both,
        isCore: false,
        category: 'Learning',
        categoryColor: '#34d399',
        status: HabitStatus.archived,
        createdAt: now,
        archivedAt: now,
        updatedAt: now,
      );
      final AppSnapshot snapshot = AppSnapshot(
        profile: AppSnapshot.seed(user: user).profile.copyWith(
              onboardingState: OnboardingState.completed,
            ),
        habits: <Habit>[archivedHabit, ...starterArchipelago()],
        dailyLogs: const <String, DailyLog>{},
      );
      final _FakeAppRepository repository = _FakeAppRepository(snapshot);
      final AppController controller = AppController(
        user: user,
        repository: repository,
        cache: _MemorySnapshotCacheStore(),
        themeMode: StateController<AppThemeMode>(AppThemeMode.dark),
      );

      await controller.bootstrap();

      final Habit draft = archivedHabit.copyWith(
        id: 'draft',
        name: 'Reading',
        subtitle: '20 min Reading',
        category: 'Mindfulness',
        categoryColor: '#ec4899',
        iconKey: 'mood',
        frequency: HabitFrequency.twiceWeekly,
        daysDue: const <int>[1, 3],
        status: HabitStatus.active,
        clearArchivedAt: true,
      );

      final HabitMutationResult result =
          await controller.submitHabitDraft(draft);

      expect(result.status, HabitMutationStatus.restoredArchived);
      final Habit restored = controller.state.snapshot!.habits.firstWhere(
        (Habit habit) => habit.id == archivedHabit.id,
      );
      expect(restored.isActive, isTrue);
      expect(restored.subtitle, '20 min Reading');
      expect(restored.frequency, HabitFrequency.twiceWeekly);
      expect(restored.daysDue, const <int>[1, 3]);
    });

    test('blocks archiving the last active habit', () async {
      final AppUser user = const AppUser(
        uid: 'u1',
        displayName: 'User',
        email: 'user@example.com',
      );
      final Habit onlyHabit = starterArchipelago().first;
      final AppSnapshot snapshot = AppSnapshot(
        profile: AppSnapshot.seed(user: user).profile.copyWith(
              onboardingState: OnboardingState.completed,
            ),
        habits: <Habit>[onlyHabit],
        dailyLogs: const <String, DailyLog>{},
      );
      final AppController controller = AppController(
        user: user,
        repository: _FakeAppRepository(snapshot),
        cache: _MemorySnapshotCacheStore(),
        themeMode: StateController<AppThemeMode>(AppThemeMode.dark),
      );

      await controller.bootstrap();

      final HabitMutationResult result = await controller.updateHabitStatus(
        onlyHabit.id,
        HabitStatus.archived,
      );

      expect(result.status, HabitMutationStatus.validationError);
      expect(result.message, 'At least one active habit is required.');
      expect(controller.state.snapshot!.habits.single.isActive, isTrue);
    });
  });

  group('Progress analytics', () {
    test('filters archived and deleted habits like the web app', () {
      final DateTime today = startOfDay(DateTime.now());
      final List<Habit> habits = starterArchipelago();
      final Habit archived = habits[0].copyWith(
        id: 'archived-habit',
        status: HabitStatus.archived,
        archivedAt: today,
      );
      final Habit deleted = habits[1].copyWith(
        id: 'deleted-habit',
        status: HabitStatus.deleted,
        deletedAt: today,
      );
      final AppSnapshot snapshot = AppSnapshot(
        profile: AppSnapshot.seed(
          user: const AppUser(
            uid: 'u1',
            displayName: 'User',
            email: 'user@example.com',
          ),
        ).profile,
        habits: <Habit>[archived, deleted, habits[2]],
        dailyLogs: const <String, DailyLog>{},
      );

      final List<Habit> withoutArchived = progressHabits(
        snapshot,
        coreOnly: false,
        includeArchived: false,
      );
      final List<Habit> withArchived = progressHabits(
        snapshot,
        coreOnly: false,
        includeArchived: true,
      );

      expect(
        withoutArchived.map((Habit habit) => habit.id),
        orderedEquals(<String>[habits[2].id]),
      );
      expect(
        withArchived.map((Habit habit) => habit.id).toSet(),
        <String>{archived.id, habits[2].id},
      );
    });

    test('uses weekly cadence labels for 30 day ranges', () {
      final DateTime end = startOfDay(DateTime.now());
      final DateTime start = addDays(end, -29);
      final List<Habit> habits = starterArchipelago();
      final AppSnapshot snapshot = AppSnapshot(
        profile: AppSnapshot.seed(
          user: const AppUser(
            uid: 'u1',
            displayName: 'User',
            email: 'user@example.com',
          ),
        ).profile,
        habits: habits,
        dailyLogs: <String, DailyLog>{
          formatDateKey(end): DailyLog(
            dateKey: formatDateKey(end),
            completedHabitIds: <String>[habits.first.id],
            completedAtByHabit: <String, int>{
              habits.first.id: end.millisecondsSinceEpoch,
            },
            updatedAt: end,
          ),
        },
      );

      final ProgressAnalytics analytics = buildProgressAnalytics(
        snapshot,
        range: ProgressRange(
          start: start,
          end: end,
          dayCount: 30,
          modeLabel: '30-day',
        ),
        coreOnly: false,
        includeArchived: false,
      );

      expect(analytics.cadence, isNotEmpty);
      expect(analytics.cadence.first.label, 'Week 1');
    });
  });
}

class _FakeAppRepository implements AppRepository {
  _FakeAppRepository(this.snapshot);

  AppSnapshot snapshot;

  @override
  Future<void> completeOnboarding(
    String uid, {
    required UserProfile profile,
    required List<Habit> starterHabits,
  }) async {
    snapshot = AppSnapshot(
      profile: profile,
      habits: starterHabits,
      dailyLogs: snapshot.dailyLogs,
    );
  }

  @override
  Future<void> deleteAccountData(String uid) async {}

  @override
  Future<AppSnapshot> loadBootstrap(
    String uid, {
    required AppUser user,
    int windowDays = 120,
  }) async {
    return snapshot;
  }

  @override
  Future<void> saveHabit(String uid, Habit habit) async {
    final List<Habit> habits = <Habit>[...snapshot.habits];
    final int index = habits.indexWhere((Habit item) => item.id == habit.id);
    if (index == -1) {
      habits.add(habit);
    } else {
      habits[index] = habit;
    }
    snapshot = snapshot.copyWith(habits: habits);
  }

  @override
  Future<void> saveThemeMode(String uid, AppThemeMode themeMode) async {
    snapshot = snapshot.copyWith(
      profile: snapshot.profile.copyWith(themeMode: themeMode),
    );
  }

  @override
  Future<DailyLog> toggleCompletion(
    String uid, {
    required Habit habit,
    required DateTime day,
    required bool completed,
  }) async {
    final String dateKey = formatDateKey(day);
    final DailyLog existing = snapshot.dailyLogs[dateKey] ??
        DailyLog(
          dateKey: dateKey,
          completedHabitIds: const <String>[],
          completedAtByHabit: const <String, int>{},
          updatedAt: day,
        );
    final Set<String> ids = <String>{...existing.completedHabitIds};
    final Map<String, int> stamps = <String, int>{
      ...existing.completedAtByHabit
    };
    if (completed) {
      ids.add(habit.id);
      stamps[habit.id] = day.millisecondsSinceEpoch;
    } else {
      ids.remove(habit.id);
      stamps.remove(habit.id);
    }
    final DailyLog updated = existing.copyWith(
      completedHabitIds: ids.toList()..sort(),
      completedAtByHabit: stamps,
      updatedAt: day,
    );
    snapshot = snapshot.copyWith(
      dailyLogs: <String, DailyLog>{...snapshot.dailyLogs, dateKey: updated},
    );
    return updated;
  }
}

class _MemorySnapshotCacheStore implements SnapshotCache {
  AppSnapshot? stored;

  @override
  Future<void> clear(String uid) async {
    stored = null;
  }

  @override
  Future<AppSnapshot?> read(String uid) async => stored;

  @override
  Future<void> write(String uid, AppSnapshot snapshot) async {
    stored = snapshot;
  }
}
