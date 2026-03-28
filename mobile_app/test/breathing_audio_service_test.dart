import 'package:flutter_test/flutter_test.dart';
import 'package:voice_growth_archipelago/src/features/breathe/data/breathing_audio_service.dart';
import 'package:voice_growth_archipelago/src/features/breathe/domain/breathing_models.dart';

void main() {
  test('inhale and exhale use duration matched playback while hold loops',
      () async {
    final _FakeBreathingCuePlayer player = _FakeBreathingCuePlayer(
      durationsByPath: <String, Duration>{
        '/cache/inhale.mp3': const Duration(seconds: 6),
        '/cache/hold.mp3': const Duration(seconds: 2),
        '/cache/exhale.mp3': const Duration(seconds: 5),
      },
    );
    final CueBreathingAudioService service = CueBreathingAudioService(
      player: player,
      assetCache: _FakeBreathingCueAssetCache(
        <String, String>{
          'assets/breathe/sounds/inhale_sound.mp3': '/cache/inhale.mp3',
          'assets/breathe/sounds/hold_sound.mp3': '/cache/hold.mp3',
          'assets/breathe/sounds/exhale_sound.mp3': '/cache/exhale.mp3',
        },
      ),
    );

    await service.preload();
    await service.playPhase(
      BreathingPhase.inhale,
      durationSeconds: 3,
      soundMode: BreathingSoundMode.cues,
    );
    expect(player.currentSourcePath, '/cache/inhale.mp3');
    expect(player.lastReleaseMode, BreathingCueReleaseMode.stop);
    expect(player.lastSpeed, 2);
    expect(player.resumeCount, 1);

    await service.playPhase(
      BreathingPhase.holdIn,
      durationSeconds: 7,
      soundMode: BreathingSoundMode.cues,
    );
    expect(player.currentSourcePath, '/cache/hold.mp3');
    expect(player.lastReleaseMode, BreathingCueReleaseMode.loop);
    expect(player.lastSpeed, 1);
    expect(player.resumeCount, 2);

    await service.playPhase(
      BreathingPhase.exhale,
      durationSeconds: 10,
      soundMode: BreathingSoundMode.cues,
    );
    expect(player.currentSourcePath, '/cache/exhale.mp3');
    expect(player.lastReleaseMode, BreathingCueReleaseMode.stop);
    expect(player.lastSpeed, 0.5);
    expect(player.resumeCount, 3);
  });

  test('completion uses inhale cue at slower original rate', () async {
    final _FakeBreathingCuePlayer player = _FakeBreathingCuePlayer(
      durationsByPath: <String, Duration>{
        '/cache/inhale.mp3': const Duration(seconds: 6),
        '/cache/hold.mp3': const Duration(seconds: 2),
        '/cache/exhale.mp3': const Duration(seconds: 5),
      },
    );
    final CueBreathingAudioService service = CueBreathingAudioService(
      player: player,
      assetCache: _FakeBreathingCueAssetCache(
        <String, String>{
          'assets/breathe/sounds/inhale_sound.mp3': '/cache/inhale.mp3',
          'assets/breathe/sounds/hold_sound.mp3': '/cache/hold.mp3',
          'assets/breathe/sounds/exhale_sound.mp3': '/cache/exhale.mp3',
        },
      ),
    );

    await service.preload();
    await service.playComplete(BreathingSoundMode.cues);

    expect(player.currentSourcePath, '/cache/inhale.mp3');
    expect(player.lastReleaseMode, BreathingCueReleaseMode.stop);
    expect(player.lastSpeed, 0.6);
    expect(player.resumeCount, 1);
  });
}

class _FakeBreathingCuePlayer implements BreathingCuePlayer {
  _FakeBreathingCuePlayer({required this.durationsByPath});

  final Map<String, Duration> durationsByPath;
  String? currentSourcePath;
  BreathingCueReleaseMode? lastReleaseMode;
  double? lastSpeed;
  double? lastVolume;
  Duration? lastSeek;
  int resumeCount = 0;
  int stopCount = 0;
  int disposeCount = 0;

  @override
  Future<void> dispose() async {
    disposeCount += 1;
  }

  @override
  Future<Duration?> getDuration() async {
    return durationsByPath[currentSourcePath];
  }

  @override
  Future<void> resume() async {
    resumeCount += 1;
  }

  @override
  Future<void> seek(Duration position) async {
    lastSeek = position;
  }

  @override
  Future<void> setPlaybackRate(double speed) async {
    lastSpeed = speed;
  }

  @override
  Future<void> setReleaseMode(BreathingCueReleaseMode mode) async {
    lastReleaseMode = mode;
  }

  @override
  Future<void> setSourceDeviceFile(String path) async {
    currentSourcePath = path;
  }

  @override
  Future<void> setVolume(double volume) async {
    lastVolume = volume;
  }

  @override
  Future<void> stop() async {
    stopCount += 1;
  }
}

class _FakeBreathingCueAssetCache implements BreathingCueAssetCache {
  _FakeBreathingCueAssetCache(this.pathsByAsset);

  final Map<String, String> pathsByAsset;

  @override
  Future<String> loadPath(String assetPath) async {
    return pathsByAsset[assetPath]!;
  }
}
