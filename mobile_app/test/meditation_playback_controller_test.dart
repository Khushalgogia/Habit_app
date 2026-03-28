import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:voice_growth_archipelago/src/features/meditation/data/meditation_playback_controller.dart';
import 'package:voice_growth_archipelago/src/features/meditation/domain/meditation_models.dart';

void main() {
  test('meditation controller pauses and resumes the current track', () async {
    final _FakeMeditationAudioPlayer player = _FakeMeditationAudioPlayer();
    final JustAudioMeditationPlaybackController controller =
        JustAudioMeditationPlaybackController(player);

    await controller.setTracks(
      <MeditationTrack>[
        _track('track_a', 'Track A'),
        _track('track_b', 'Track B'),
      ],
    );

    expect(await controller.playTrackById('track_a'), isTrue);
    expect(controller.currentIndex, 0);
    expect(player.playCount, 1);

    expect(await controller.pause(), isTrue);
    expect(player.pauseCount, 1);
    expect(controller.isPlaying, isFalse);

    expect(await controller.play(), isTrue);
    expect(player.playCount, 2);
    expect(controller.currentIndex, 0);

    await controller.dispose();
  });

  test('meditation controller next and previous use the shared queue index',
      () async {
    final _FakeMeditationAudioPlayer player = _FakeMeditationAudioPlayer();
    final JustAudioMeditationPlaybackController controller =
        JustAudioMeditationPlaybackController(player);

    await controller.setTracks(
      <MeditationTrack>[
        _track('track_a', 'Track A'),
        _track('track_b', 'Track B'),
        _track('track_c', 'Track C'),
      ],
    );

    expect(await controller.playTrackById('track_b'), isTrue);
    expect(controller.currentIndex, 1);

    await controller.skipToNext();
    expect(controller.currentIndex, 2);

    await controller.skipToPrevious();
    expect(controller.currentIndex, 1);

    await controller.dispose();
  });

  test('meditation controller seek updates playback position cleanly',
      () async {
    final _FakeMeditationAudioPlayer player = _FakeMeditationAudioPlayer();
    final JustAudioMeditationPlaybackController controller =
        JustAudioMeditationPlaybackController(player);

    await controller.setTracks(<MeditationTrack>[_track('track_a', 'Track A')]);
    expect(await controller.playTrackById('track_a'), isTrue);

    await controller.seek(const Duration(seconds: 32));

    expect(player.lastSeekPosition, const Duration(seconds: 32));
    expect(controller.isPlaying, isTrue);

    await controller.dispose();
  });

  test('pause completes promptly even while play future is pending', () async {
    final _BlockingPlayMeditationAudioPlayer player =
        _BlockingPlayMeditationAudioPlayer();
    final JustAudioMeditationPlaybackController controller =
        JustAudioMeditationPlaybackController(player);

    await controller.setTracks(<MeditationTrack>[_track('track_a', 'Track A')]);

    final Future<bool> playRequest = controller.playTrackById('track_a');
    await player.waitUntilPlayInvoked();
    expect(player.playFuturePending, isTrue);

    final Future<bool> pauseRequest = controller.pause();

    expect(
      await playRequest.timeout(
        const Duration(seconds: 2),
        onTimeout: () => false,
      ),
      isTrue,
    );
    expect(
      await pauseRequest.timeout(
        const Duration(seconds: 2),
        onTimeout: () => false,
      ),
      isTrue,
    );
    expect(player.pauseCount, 1);
    expect(controller.isPlaying, isFalse);

    await controller.dispose();
  });

  test('seek completes while play future is pending', () async {
    final _BlockingPlayMeditationAudioPlayer player =
        _BlockingPlayMeditationAudioPlayer();
    final JustAudioMeditationPlaybackController controller =
        JustAudioMeditationPlaybackController(player);

    await controller.setTracks(<MeditationTrack>[_track('track_a', 'Track A')]);

    final Future<bool> playRequest = controller.playTrackById('track_a');
    await player.waitUntilPlayInvoked();
    expect(player.playFuturePending, isTrue);

    final Future<void> seekRequest =
        controller.seek(const Duration(seconds: 32));

    expect(
      await playRequest.timeout(
        const Duration(seconds: 2),
        onTimeout: () => false,
      ),
      isTrue,
    );
    await seekRequest.timeout(const Duration(seconds: 2));
    expect(player.lastSeekPosition, const Duration(seconds: 32));

    await controller.pause();
    await controller.dispose();
  });

  test('rapid play-pause sequence does not deadlock', () async {
    final _BlockingPlayMeditationAudioPlayer player =
        _BlockingPlayMeditationAudioPlayer();
    final JustAudioMeditationPlaybackController controller =
        JustAudioMeditationPlaybackController(player);

    await controller.setTracks(<MeditationTrack>[_track('track_a', 'Track A')]);

    expect(
      await controller.playTrackById('track_a').timeout(
            const Duration(seconds: 2),
            onTimeout: () => false,
          ),
      isTrue,
    );
    expect(
      await controller.pause().timeout(
            const Duration(seconds: 2),
            onTimeout: () => false,
          ),
      isTrue,
    );
    expect(
      await controller.play().timeout(
            const Duration(seconds: 2),
            onTimeout: () => false,
          ),
      isTrue,
    );
    expect(
      await controller.pause().timeout(
            const Duration(seconds: 2),
            onTimeout: () => false,
          ),
      isTrue,
    );
    expect(player.playCount, 2);
    expect(player.pauseCount, 2);

    await controller.dispose();
  });

  test(
      'latest rapid meditation track request still leaves the newest track active',
      () async {
    final _FakeMeditationAudioPlayer player = _FakeMeditationAudioPlayer(
      loadDelay: const Duration(milliseconds: 20),
    );
    final JustAudioMeditationPlaybackController controller =
        JustAudioMeditationPlaybackController(player);
    final List<String> errors = <String>[];
    final StreamSubscription<String> errorSubscription =
        controller.errorStream.listen(errors.add);

    await controller.setTracks(
      <MeditationTrack>[
        _track('track_a', 'Track A'),
        _track('track_b', 'Track B'),
      ],
    );

    final Future<bool> firstRequest = controller.playTrackById('track_a');
    final Future<bool> secondRequest = controller.playTrackById('track_b');

    expect(await firstRequest, isTrue);
    expect(await secondRequest, isTrue);
    expect(controller.currentIndex, 1);
    expect(errors, isEmpty);

    await errorSubscription.cancel();
    await controller.dispose();
  });
}

MeditationTrack _track(String id, String title) {
  return MeditationTrack(
    id: id,
    title: title,
    category: 'Focus / Binaural',
    audioAssetPath: 'assets/meditation/audio/$id.mp3',
    artworkAssetPath: 'assets/meditation/artwork/_placeholder.jpg',
    durationSeconds: 60,
    sourceFileName: '$id.mp3',
    processingMode: 'copy_original',
    gainDb: 0,
    limiterDbfs: -1.5,
    artworkPending: false,
  );
}

class _FakeMeditationAudioPlayer implements MeditationAudioPlayer {
  _FakeMeditationAudioPlayer({
    this.loadDelay = Duration.zero,
  }) {
    _playerStateController.add(PlayerState(false, ProcessingState.ready));
    _positionController.add(Duration.zero);
    _durationController.add(const Duration(seconds: 60));
    _loopModeController.add(_loopMode);
  }

  final Duration loadDelay;
  final StreamController<PlayerState> _playerStateController =
      StreamController<PlayerState>.broadcast();
  final StreamController<Duration> _positionController =
      StreamController<Duration>.broadcast();
  final StreamController<Duration?> _durationController =
      StreamController<Duration?>.broadcast();
  final StreamController<int?> _currentIndexController =
      StreamController<int?>.broadcast();
  final StreamController<LoopMode> _loopModeController =
      StreamController<LoopMode>.broadcast();

  bool _playing = false;
  int? _currentIndex;
  LoopMode _loopMode = LoopMode.off;
  PlayerState _playerState = PlayerState(false, ProcessingState.ready);
  Duration? lastSeekPosition;
  int playCount = 0;
  int pauseCount = 0;

  @override
  int? get currentIndex => _currentIndex;

  @override
  Stream<int?> get currentIndexStream => _currentIndexController.stream;

  @override
  Stream<Duration?> get durationStream => _durationController.stream;

  @override
  LoopMode get loopMode => _loopMode;

  @override
  Stream<LoopMode> get loopModeStream => _loopModeController.stream;

  @override
  bool get playing => _playing;

  @override
  PlayerState get playerState => _playerState;

  @override
  Stream<PlayerState> get playerStateStream => _playerStateController.stream;

  @override
  Stream<Duration> get positionStream => _positionController.stream;

  @override
  Future<void> dispose() async {
    await _playerStateController.close();
    await _positionController.close();
    await _durationController.close();
    await _currentIndexController.close();
    await _loopModeController.close();
  }

  @override
  Future<void> pause() async {
    pauseCount += 1;
    _playing = false;
    _playerState = PlayerState(false, ProcessingState.ready);
    _playerStateController.add(_playerState);
  }

  @override
  Future<void> play() async {
    playCount += 1;
    _playing = true;
    _playerState = PlayerState(true, ProcessingState.ready);
    _playerStateController.add(_playerState);
  }

  @override
  Future<void> seek(Duration? position, {int? index}) async {
    if (index != null) {
      _currentIndex = index;
      _currentIndexController.add(index);
    }
    final Duration resolvedPosition = position ?? Duration.zero;
    lastSeekPosition = resolvedPosition;
    _positionController.add(resolvedPosition);
  }

  @override
  Future<void> seekToNext() async {
    if (_currentIndex == null) {
      return;
    }
    _currentIndex = _currentIndex! + 1;
    _currentIndexController.add(_currentIndex);
    _positionController.add(Duration.zero);
  }

  @override
  Future<void> seekToPrevious() async {
    if (_currentIndex == null || _currentIndex == 0) {
      return;
    }
    _currentIndex = _currentIndex! - 1;
    _currentIndexController.add(_currentIndex);
    _positionController.add(Duration.zero);
  }

  @override
  Future<void> setAudioSources(
    List<AudioSource> sources, {
    bool preload = true,
    int? initialIndex,
    Duration? initialPosition,
  }) async {
    await Future<void>.delayed(loadDelay);
    _currentIndex = initialIndex ?? 0;
    _currentIndexController.add(_currentIndex);
    _durationController.add(const Duration(seconds: 60));
    _positionController.add(initialPosition ?? Duration.zero);
  }

  @override
  Future<void> setLoopMode(LoopMode mode) async {
    _loopMode = mode;
    _loopModeController.add(mode);
  }

  @override
  Future<void> stop() async {
    _playing = false;
    _positionController.add(Duration.zero);
    _playerState = PlayerState(false, ProcessingState.ready);
    _playerStateController.add(_playerState);
  }
}

class _BlockingPlayMeditationAudioPlayer extends _FakeMeditationAudioPlayer {
  final Completer<void> _playInvoked = Completer<void>();
  Completer<void>? _pendingPlayCompleter;

  bool get playFuturePending =>
      _pendingPlayCompleter != null && !_pendingPlayCompleter!.isCompleted;

  Future<void> waitUntilPlayInvoked() => _playInvoked.future;

  @override
  Future<void> play() async {
    await super.play();
    if (!_playInvoked.isCompleted) {
      _playInvoked.complete();
    }

    final Completer<void> completer = Completer<void>();
    _pendingPlayCompleter = completer;
    return completer.future;
  }

  @override
  Future<void> pause() async {
    await super.pause();
    _completePendingPlay();
  }

  @override
  Future<void> stop() async {
    await super.stop();
    _completePendingPlay();
  }

  @override
  Future<void> dispose() async {
    _completePendingPlay();
    await super.dispose();
  }

  void _completePendingPlay() {
    final Completer<void>? completer = _pendingPlayCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }
}
