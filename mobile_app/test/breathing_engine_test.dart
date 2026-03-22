import 'package:flutter_test/flutter_test.dart';
import 'package:voice_growth_archipelago/src/features/breathe/domain/breathing_engine.dart';
import 'package:voice_growth_archipelago/src/features/breathe/domain/breathing_models.dart';

void main() {
  const BreathingEngine engine = BreathingEngine();

  group('BreathingEngine', () {
    test('scales the relax pattern to the target BPM', () {
      final List<double> pattern = engine.getScaledPattern(
        BreathingModeId.relax,
        6,
      );

      expect(pattern[0], closeTo(4 * (10 / 19), 0.0001));
      expect(pattern[1], closeTo(7 * (10 / 19), 0.0001));
      expect(pattern[2], closeTo(8 * (10 / 19), 0.0001));
      expect(pattern[3], 0);
    });

    test('skips zero-duration hold phases', () {
      final List<BreathingStep> sequence = engine.buildSequence(
        BreathingModeId.balance,
        6,
      );

      expect(
        sequence.map((BreathingStep step) => step.phase),
        orderedEquals(<BreathingPhase>[
          BreathingPhase.inhale,
          BreathingPhase.exhale,
        ]),
      );
    });

    test('marks the frame complete at the session boundary', () {
      final BreathingMode mode = breathingModes.firstWhere(
        (BreathingMode candidate) => candidate.id == BreathingModeId.focus,
      );
      final BreathingFrame frame = engine.frameFor(
        mode: mode,
        bpm: 6,
        totalDurationSeconds: 120,
        elapsedSeconds: 120,
      );

      expect(frame.isComplete, isTrue);
      expect(frame.remainingSessionSeconds, 0);
      expect(frame.elapsedSessionSeconds, 120);
    });
  });
}
