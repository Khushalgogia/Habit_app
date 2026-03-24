import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voice_growth_archipelago/src/core/theme/app_theme.dart';
import 'package:voice_growth_archipelago/src/features/storytelling/presentation/storytelling_screen.dart';

void main() {
  testWidgets(
    'Storytelling setup keeps the duration selector and initialize button in the first viewport',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(Brightness.light),
          home: const Scaffold(body: StorytellingScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Choose a session length'), findsOneWidget);
      expect(find.text('INITIALIZE'), findsOneWidget);
      expect(
        tester.getBottomLeft(find.text('INITIALIZE')).dy,
        lessThanOrEqualTo(700),
      );
    },
  );
}
