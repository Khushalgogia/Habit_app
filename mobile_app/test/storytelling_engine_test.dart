import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voice_growth_archipelago/src/features/storytelling/domain/storytelling_engine.dart';
import 'package:voice_growth_archipelago/src/features/storytelling/domain/storytelling_models.dart';

void main() {
  group('StorytellingEngine', () {
    test('never emits silence for 1 minute sessions', () {
      final _StoryRunResult result = _runSession(60);

      expect(result.promptCounts[PromptType.silence] ?? 0, 0);
    });

    test(
        'guarantees at least one silence for every supported duration above 1 minute',
        () {
      for (final int duration
          in storyDurationOptions.where((int value) => value > 60)) {
        final _StoryRunResult result = _runSession(duration);

        expect(
          result.promptCounts[PromptType.silence] ?? 0,
          greaterThanOrEqualTo(1),
          reason: 'Expected at least one silence for $duration seconds.',
        );
      }
    });

    test('respects the 3 minute silence cap', () {
      final _StoryRunResult result = _runSession(180);

      expect(
          result.promptCounts[PromptType.silence] ?? 0, lessThanOrEqualTo(1));
    });

    test('respects the 6 minute silence cap', () {
      final _StoryRunResult result = _runSession(360);

      expect(
          result.promptCounts[PromptType.silence] ?? 0, lessThanOrEqualTo(2));
    });

    test('manual silence injection counts toward the silence guarantee', () {
      final _StoryRunResult result = _runSession(
        180,
        onEngineReady: (StorytellingEngine engine) {
          engine.injectPrompt(PromptType.silence);
        },
      );

      expect(result.promptCounts[PromptType.silence] ?? 0, 1);
    });
  });
}

_StoryRunResult _runSession(
  int durationSeconds, {
  void Function(StorytellingEngine engine)? onEngineReady,
}) {
  return fakeAsync((FakeAsync async) {
    StorySessionState? latestState;
    StoryPrompt? lastPrompt;
    final Map<PromptType, int> promptCounts = <PromptType, int>{};
    final StorytellingEngine engine = StorytellingEngine(
      durationSeconds: durationSeconds,
      objects: const <String>['Mirror'],
      emotions: const <EmotionPrompt>[
        EmotionPrompt(name: 'Awe', vocalCue: 'Whispering, wide eyes'),
      ],
      onStateChanged: (StorySessionState state) {
        latestState = state;
        if (state.activePrompt != null &&
            !identical(lastPrompt, state.activePrompt)) {
          promptCounts.update(
            state.activePrompt!.type,
            (int count) => count + 1,
            ifAbsent: () => 1,
          );
        }
        lastPrompt = state.activePrompt;
      },
    );

    engine.start();
    onEngineReady?.call(engine);

    int safety = 0;
    while (!(latestState?.isComplete ?? false) && safety < 2000) {
      async.elapse(const Duration(seconds: 1));
      safety += 1;
    }

    engine.dispose();
    return _StoryRunResult(promptCounts: promptCounts);
  });
}

class _StoryRunResult {
  const _StoryRunResult({required this.promptCounts});

  final Map<PromptType, int> promptCounts;
}
