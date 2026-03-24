import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:voice_growth_archipelago/src/core/theme/app_theme.dart';
import 'package:voice_growth_archipelago/src/features/breathe/presentation/breathe_screen.dart';
import 'package:voice_growth_archipelago/src/features/home/presentation/home_shell_screen.dart';
import 'package:voice_growth_archipelago/src/features/meditation/data/meditation_playback_controller.dart';
import 'package:voice_growth_archipelago/src/features/meditation/domain/meditation_models.dart';
import 'package:voice_growth_archipelago/src/features/meditation/presentation/meditation_screen.dart';

void main() {
  testWidgets('Meditation screen renders categories and tracks', (
    WidgetTester tester,
  ) async {
    final _FakeMeditationPlaybackController controller =
        _FakeMeditationPlaybackController();
    final MeditationCatalog catalog = MeditationCatalog(
      generatedAtIso: '2026-03-24T00:00:00Z',
      sourceDirectory: '/tmp',
      tracks: <MeditationTrack>[
        _track(
          id: 'nsdr_huberman_10',
          title: 'Huberman NSDR (10 min)',
          category: 'NSDR / Yoga Nidra',
        ),
        _track(
          id: 'money_affirmations',
          title: 'Money Affirmations',
          category: 'Affirmations / Manifestation',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(
          body: MeditationScreen(
            catalogLoader: () async => catalog,
            playbackController: controller,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Meditation Library'), findsOneWidget);
    expect(find.text('NSDR / Yoga Nidra'), findsOneWidget);
    expect(find.text('Affirmations / Manifestation'), findsOneWidget);
    expect(find.text('Huberman NSDR (10 min)'), findsOneWidget);
    expect(find.text('Money Affirmations'), findsOneWidget);
  });

  testWidgets('Meditation screen shows mini player after track play', (
    WidgetTester tester,
  ) async {
    final _FakeMeditationPlaybackController controller =
        _FakeMeditationPlaybackController();
    final MeditationCatalog catalog = MeditationCatalog(
      generatedAtIso: '2026-03-24T00:00:00Z',
      sourceDirectory: '/tmp',
      tracks: <MeditationTrack>[
        _track(
          id: 'nsdr_huberman_10',
          title: 'Huberman NSDR (10 min)',
          category: 'NSDR / Yoga Nidra',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(
          body: MeditationScreen(
            catalogLoader: () async => catalog,
            playbackController: controller,
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byIcon(Icons.play_arrow_rounded).first);
    await tester.pump();

    expect(find.text('Huberman NSDR (10 min)'), findsWidgets);
    expect(
      find.byKey(const ValueKey<String>('meditation-mini-player')),
      findsOneWidget,
    );
  });

  testWidgets('Meditation player sheet opens from the mini player', (
    WidgetTester tester,
  ) async {
    final _FakeMeditationPlaybackController controller =
        _FakeMeditationPlaybackController();
    final MeditationCatalog catalog = MeditationCatalog(
      generatedAtIso: '2026-03-24T00:00:00Z',
      sourceDirectory: '/tmp',
      tracks: <MeditationTrack>[
        _track(
          id: 'nsdr_huberman_10',
          title: 'Huberman NSDR (10 min)',
          category: 'NSDR / Yoga Nidra',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(
          body: MeditationScreen(
            catalogLoader: () async => catalog,
            playbackController: controller,
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byIcon(Icons.play_arrow_rounded).first);
    await tester.pump();
    await tester
        .tap(find.byKey(const ValueKey<String>('meditation-mini-player')));
    await tester.pumpAndSettle();

    expect(find.text('Loop: Off'), findsOneWidget);
    expect(find.text('Huberman NSDR (10 min)'), findsWidgets);
  });

  testWidgets('Home nav destination order includes Meditation after Breathe', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.dark),
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: HomeBottomNavigationBar(
              selectedIndex: 0,
              isAuraTab: false,
              isStoryTab: false,
              auraPalette: defaultAuraShellPalette,
              onDestinationSelected: (_) {},
            ),
          ),
        ),
      ),
    );

    final NavigationBar nav =
        tester.widget<NavigationBar>(find.byType(NavigationBar));
    final List<String> labels = nav.destinations
        .map((Widget destination) =>
            (destination as NavigationDestination).label)
        .toList(growable: false);

    expect(
      labels,
      const <String>[
        'Today',
        'Breathe',
        'Meditation',
        'Story',
        'Progress',
      ],
    );
  });
}

MeditationTrack _track({
  required String id,
  required String title,
  required String category,
}) {
  return MeditationTrack(
    id: id,
    title: title,
    category: category,
    audioAssetPath: 'assets/meditation/audio/$id.mp3',
    artworkAssetPath: 'assets/meditation/artwork/_placeholder.jpg',
    durationSeconds: 120,
    sourceFileName: '$id.mp3',
    processingMode: 'gain_limit',
    gainDb: 0,
    limiterDbfs: -1.5,
    artworkPending: false,
  );
}

class _FakeMeditationPlaybackController
    implements MeditationPlaybackController {
  final StreamController<String> _errors = StreamController<String>.broadcast();
  final StreamController<PlayerState> _playerState =
      StreamController<PlayerState>.broadcast();
  final StreamController<Duration> _position =
      StreamController<Duration>.broadcast();
  final StreamController<Duration?> _duration =
      StreamController<Duration?>.broadcast();
  final StreamController<int?> _index = StreamController<int?>.broadcast();
  final StreamController<LoopMode> _loop =
      StreamController<LoopMode>.broadcast();

  List<MeditationTrack> _tracks = <MeditationTrack>[];
  int? _currentIndex;
  bool _playing = false;
  LoopMode _mode = LoopMode.off;

  _FakeMeditationPlaybackController() {
    _playerState.add(PlayerState(false, ProcessingState.ready));
    _position.add(Duration.zero);
    _duration.add(const Duration(seconds: 120));
    _index.add(null);
    _loop.add(_mode);
  }

  @override
  int? get currentIndex => _currentIndex;

  @override
  bool get isPlaying => _playing;

  @override
  Stream<String> get errorStream => _errors.stream;

  @override
  Stream<int?> get currentIndexStream => _index.stream;

  @override
  Stream<Duration?> get durationStream => _duration.stream;

  @override
  Stream<LoopMode> get loopModeStream => _loop.stream;

  @override
  Stream<PlayerState> get playerStateStream => _playerState.stream;

  @override
  Stream<Duration> get positionStream => _position.stream;

  @override
  Future<void> dispose() async {
    await _errors.close();
    await _playerState.close();
    await _position.close();
    await _duration.close();
    await _index.close();
    await _loop.close();
  }

  @override
  Future<bool> pause() async {
    _playing = false;
    _playerState.add(PlayerState(false, ProcessingState.ready));
    return true;
  }

  @override
  Future<bool> play() async {
    _playing = true;
    _playerState.add(PlayerState(true, ProcessingState.ready));
    return true;
  }

  @override
  Future<bool> playTrackById(String trackId) async {
    final int foundIndex =
        _tracks.indexWhere((MeditationTrack t) => t.id == trackId);
    if (foundIndex < 0) {
      return false;
    }
    _currentIndex = foundIndex;
    _playing = true;
    _index.add(_currentIndex);
    _playerState.add(PlayerState(true, ProcessingState.ready));
    return true;
  }

  @override
  Future<void> seek(Duration position) async {
    _position.add(position);
  }

  @override
  Future<void> setTracks(List<MeditationTrack> tracks) async {
    _tracks = tracks;
    _duration.add(const Duration(seconds: 120));
  }

  @override
  Future<void> skipToNext() async {
    if (_tracks.isEmpty) {
      return;
    }
    _currentIndex = ((_currentIndex ?? -1) + 1).clamp(0, _tracks.length - 1);
    _index.add(_currentIndex);
  }

  @override
  Future<void> skipToPrevious() async {
    if (_tracks.isEmpty) {
      return;
    }
    _currentIndex = ((_currentIndex ?? 0) - 1).clamp(0, _tracks.length - 1);
    _index.add(_currentIndex);
  }

  @override
  Future<void> toggleLoopMode() async {
    _mode = switch (_mode) {
      LoopMode.off => LoopMode.one,
      LoopMode.one => LoopMode.all,
      LoopMode.all => LoopMode.off,
    };
    _loop.add(_mode);
  }
}
