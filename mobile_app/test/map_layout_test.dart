import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:voice_growth_archipelago/src/core/utils/map_layout.dart';
import 'package:voice_growth_archipelago/src/features/shared/domain/app_models.dart';

void main() {
  test(
      'resolveHabitLayouts keeps crowded islands within bounds and spaced apart',
      () {
    final DateTime now = DateTime.now();
    final List<Habit> habits = List<Habit>.generate(4, (int index) {
      return Habit(
        id: 'habit-$index',
        name: 'Habit $index',
        subtitle: 'Task',
        iconKey: 'book',
        iconColor: '#6366f1',
        baseColor: '#6366f1',
        glowColor: '#6366f1',
        xPct: 50,
        yPct: 50,
        frequency: HabitFrequency.daily,
        daysDue: const <int>[0, 1, 2, 3, 4, 5, 6],
        scopeMode: DayScopeMode.both,
        isCore: index.isEven,
        category: 'Focus',
        categoryColor: '#6366f1',
        status: HabitStatus.active,
        createdAt: now,
        updatedAt: now,
      );
    });

    final List<ResolvedHabitLayout> layouts = resolveHabitLayouts(
      habits,
      const Size(320, 380),
    );

    expect(layouts, hasLength(4));
    for (final ResolvedHabitLayout layout in layouts) {
      expect(layout.center.dx, inInclusiveRange(52, 268));
      expect(layout.center.dy, inInclusiveRange(52, 328));
    }

    for (int i = 0; i < layouts.length; i += 1) {
      for (int j = i + 1; j < layouts.length; j += 1) {
        expect(
          (layouts[i].center - layouts[j].center).distance,
          greaterThanOrEqualTo(84),
        );
      }
    }
  });

  test(
      'resolvePreferredHabitPosition avoids existing crowded anchors for new habits',
      () {
    final DateTime now = DateTime.now();
    final List<Habit> habits = <Habit>[
      Habit(
        id: 'habit-1',
        name: 'Habit 1',
        subtitle: 'Task',
        iconKey: 'book',
        iconColor: '#6366f1',
        baseColor: '#6366f1',
        glowColor: '#6366f1',
        xPct: 50,
        yPct: 50,
        frequency: HabitFrequency.daily,
        daysDue: const <int>[0, 1, 2, 3, 4, 5, 6],
        scopeMode: DayScopeMode.both,
        isCore: false,
        category: 'Focus',
        categoryColor: '#6366f1',
        status: HabitStatus.active,
        createdAt: now,
        updatedAt: now,
      ),
      Habit(
        id: 'habit-2',
        name: 'Habit 2',
        subtitle: 'Task',
        iconKey: 'book',
        iconColor: '#6366f1',
        baseColor: '#6366f1',
        glowColor: '#6366f1',
        xPct: 62,
        yPct: 50,
        frequency: HabitFrequency.daily,
        daysDue: const <int>[0, 1, 2, 3, 4, 5, 6],
        scopeMode: DayScopeMode.both,
        isCore: false,
        category: 'Focus',
        categoryColor: '#6366f1',
        status: HabitStatus.active,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    final PreferredHabitPosition preferred = resolvePreferredHabitPosition(
      habits,
      preferredXPct: 50,
      preferredYPct: 50,
    );

    expect(preferred.xPct, inInclusiveRange(18, 82));
    expect(preferred.yPct, inInclusiveRange(18, 82));
    expect(
      (Offset(preferred.xPct, preferred.yPct) - const Offset(50, 50)).distance,
      greaterThan(6),
    );
  });
}
