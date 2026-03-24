import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voice_growth_archipelago/src/app/app_environment.dart';
import 'package:voice_growth_archipelago/src/core/theme/app_theme.dart';
import 'package:voice_growth_archipelago/src/core/utils/date_utils.dart';
import 'package:voice_growth_archipelago/src/core/utils/starter_data.dart';
import 'package:voice_growth_archipelago/src/features/progress/presentation/progress_screen.dart';
import 'package:voice_growth_archipelago/src/features/shared/domain/app_models.dart';

void main() {
  testWidgets(
    'Progress screen shows summary stats and calendar ahead of full filters on phone width',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _buildProgressApp(
          child: ProgressScreen(
            user: const AppUser(
              uid: 'u1',
              displayName: 'User',
              email: 'user@example.com',
            ),
            snapshot: _buildSnapshot(),
            preferencesStore: _MemoryProgressPreferencesStore(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(
        find.byKey(const ValueKey<String>('progress-filters-edit')),
        findsOneWidget,
      );
      expect(find.text('Activity Calendar'), findsOneWidget);
      expect(
        tester.getBottomLeft(find.text('Activity Calendar')).dy,
        lessThanOrEqualTo(700),
      );
      expect(find.text('Apply Filters'), findsNothing);
    },
  );

  testWidgets(
    'Progress screen opens mobile filters in a bottom sheet and applies the selection',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _buildProgressApp(
          child: ProgressScreen(
            user: const AppUser(
              uid: 'u1',
              displayName: 'User',
              email: 'user@example.com',
            ),
            snapshot: _buildSnapshot(),
            preferencesStore: _MemoryProgressPreferencesStore(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(
        find.byKey(const ValueKey<String>('progress-filters-edit')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Apply Filters'), findsOneWidget);

      await tester.tap(find.text('90 Days'));
      await tester.pump();
      await tester.tap(find.text('Apply Filters'));
      await tester.pumpAndSettle();

      expect(find.text('Apply Filters'), findsNothing);
      expect(find.text('90 Days'), findsOneWidget);
    },
  );

  testWidgets(
    'Progress screen opens Settings from the header button',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _buildProgressApp(
          child: ProgressScreen(
            user: const AppUser(
              uid: 'u1',
              displayName: 'User',
              email: 'user@example.com',
            ),
            snapshot: _buildSnapshot(),
            preferencesStore: _MemoryProgressPreferencesStore(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(
        find.byKey(const ValueKey<String>('progress-settings-button')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('App Build'), findsOneWidget);
    },
  );
}

Widget _buildProgressApp({required Widget child}) {
  return ProviderScope(
    overrides: [
      appEnvironmentProvider.overrideWithValue(_testEnvironment()),
    ],
    child: MaterialApp(
      theme: buildAppTheme(Brightness.light),
      home: Scaffold(body: child),
    ),
  );
}

class _MemoryProgressPreferencesStore implements ProgressPreferencesStore {
  final Map<String, String> _values = <String, String>{};

  @override
  Future<String?> getString(String key) async => _values[key];

  @override
  Future<void> setString(String key, String value) async {
    _values[key] = value;
  }
}

AppSnapshot _buildSnapshot() {
  final AppSnapshot seed = AppSnapshot.seed(
    user: const AppUser(
      uid: 'u1',
      displayName: 'User',
      email: 'user@example.com',
    ),
    habits: starterArchipelago(),
  );
  final DateTime today = startOfDay(DateTime.now());

  return AppSnapshot(
    profile: seed.profile,
    habits: seed.habits,
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
}

AppEnvironment _testEnvironment() {
  return const AppEnvironment(
    appName: 'Voice Growth Archipelago',
    applicationId: 'com.voicegrowth.archipelago',
    appVersion: '2.2.4',
    appBuildNumber: '9',
    useDemoBackend: true,
    supportUrl: 'mailto:support@voicegrowth.archipelago',
    supabaseUrl: '',
    supabasePublishableKey: '',
    supabaseRedirectScheme: 'com.voicegrowth.archipelago',
    supabaseRedirectHost: 'login-callback',
  );
}
