import 'package:flutter_test/flutter_test.dart';
import 'package:voice_growth_archipelago/src/features/meditation/data/meditation_library.dart';
import 'package:voice_growth_archipelago/src/features/meditation/domain/meditation_models.dart';

void main() {
  test('findMissingMeditationAssets reports unbundled audio and artwork', () {
    final MeditationCatalog catalog = MeditationCatalog(
      generatedAtIso: '2026-03-24T00:00:00Z',
      sourceDirectory: '/tmp',
      tracks: <MeditationTrack>[
        const MeditationTrack(
          id: 'huberman_nsdr_10',
          title: 'Huberman NSDR (10 min)',
          category: 'NSDR / Yoga Nidra',
          audioAssetPath: 'assets/meditation/audio/huberman_nsdr_10.mp3',
          artworkAssetPath: 'assets/meditation/artwork/huberman_nsdr_10.jpg',
          durationSeconds: 600,
          sourceFileName: 'huberman.mp3',
          processingMode: 'gain_limit',
          gainDb: 0,
          limiterDbfs: -1.5,
          artworkPending: false,
        ),
      ],
    );

    final List<String> missing = findMissingMeditationAssets(
      catalog,
      const <String>['assets/meditation/catalog.json'],
    );

    expect(
      missing,
      const <String>[
        'assets/meditation/audio/huberman_nsdr_10.mp3',
        'assets/meditation/artwork/huberman_nsdr_10.jpg',
      ],
    );
  });
}
