import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:voice_growth_archipelago/src/features/breathe/data/breathing_audio_service.dart';
import 'package:voice_growth_archipelago/src/features/breathe/domain/breathing_models.dart';

void main() {
  test('inhale and exhale use duration matched playback while hold loops',
      () async {
    final _FakeBreathingPlayer inhale = _FakeBreathingPlayer(
      duration: const Duration(seconds: 6),
    );
    final _FakeBreathingPlayer hold = _FakeBreathingPlayer(
      duration: const Duration(seconds: 2),
    );
    final _FakeBreathingPlayer exhale = _FakeBreathingPlayer(
      duration: const Duration(seconds: 5),
    );
    final _FakeBreathingPlayer complete = _FakeBreathingPlayer(
      duration: const Duration(seconds: 6),
    );
    final JustAudioBreathingAudioService service =
        JustAudioBreathingAudioService(
      inhalePlayer: inhale,
      holdPlayer: hold,
      exhalePlayer: exhale,
      completePlayer: complete,
    );

    await service.preload();
    await service.playPhase(
      BreathingPhase.inhale,
      durationSeconds: 3,
      soundMode: BreathingSoundMode.cues,
    );
    expect(inhale.lastLoopMode, LoopMode.off);
    expect(inhale.lastSpeed, 2);
    expect(inhale.playCount, 1);

    await service.playPhase(
      BreathingPhase.holdIn,
      durationSeconds: 7,
      soundMode: BreathingSoundMode.cues,
    );
    expect(hold.lastLoopMode, LoopMode.one);
    expect(hold.lastSpeed, 1);
    expect(hold.playCount, 1);

    await service.playPhase(
      BreathingPhase.exhale,
      durationSeconds: 10,
      soundMode: BreathingSoundMode.cues,
    );
    expect(exhale.lastLoopMode, LoopMode.off);
    expect(exhale.lastSpeed, 0.5);
    expect(exhale.playCount, 1);
  });

  test('completion uses inhale asset at slower original rate', () async {
    final _FakeBreathingPlayer inhale = _FakeBreathingPlayer();
    final _FakeBreathingPlayer hold = _FakeBreathingPlayer();
    final _FakeBreathingPlayer exhale = _FakeBreathingPlayer();
    final _FakeBreathingPlayer complete = _FakeBreathingPlayer();
    final JustAudioBreathingAudioService service =
        JustAudioBreathingAudioService(
      inhalePlayer: inhale,
      holdPlayer: hold,
      exhalePlayer: exhale,
      completePlayer: complete,
    );

    await service.preload();

    expect(complete.assetPath, 'assets/breathe/sounds/inhale_sound.mp3');

    await service.playComplete(BreathingSoundMode.cues);

    expect(complete.lastLoopMode, LoopMode.off);
    expect(complete.lastSpeed, 0.6);
    expect(complete.playCount, 1);
  });
}

class _FakeBreathingPlayer implements BreathingAudioPlayer {
  _FakeBreathingPlayer({this.duration = const Duration(seconds: 4)});

  final Duration duration;
  String? assetPath;
  LoopMode? lastLoopMode;
  double? lastSpeed;
  double? lastVolume;
  Duration? lastSeek;
  int playCount = 0;
  int stopCount = 0;
  int disposeCount = 0;

  @override
  Future<void> dispose() async {
    disposeCount += 1;
  }

  @override
  Future<void> play() async {
    playCount += 1;
  }

  @override
  Future<Duration?> setAsset(String assetPath) async {
    this.assetPath = assetPath;
    return duration;
  }

  @override
  Future<void> setLoopMode(LoopMode mode) async {
    lastLoopMode = mode;
  }

  @override
  Future<void> setSpeed(double speed) async {
    lastSpeed = speed;
  }

  @override
  Future<void> setVolume(double volume) async {
    lastVolume = volume;
  }

  @override
  Future<void> seek(Duration position) async {
    lastSeek = position;
  }

  @override
  Future<void> stop() async {
    stopCount += 1;
  }
}
