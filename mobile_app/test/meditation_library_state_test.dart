import 'package:flutter_test/flutter_test.dart';
import 'package:voice_growth_archipelago/src/features/meditation/data/meditation_library_state.dart';

void main() {
  test(
    'persist/load meditation library state keeps resume and recents',
    () async {
      final _MemoryMeditationLibraryStore store =
          _MemoryMeditationLibraryStore();
      const MeditationLibraryState expected = MeditationLibraryState(
        lastPlayedTrackId: 'nsdr_huberman_10',
        lastPositionMs: 42000,
        recentTrackIds: <String>['nsdr_huberman_10', 'money_affirmations'],
      );

      await persistMeditationLibraryState(expected, store: store);
      final MeditationLibraryState loaded = await loadMeditationLibraryState(
        store: store,
      );

      expect(loaded.lastPlayedTrackId, expected.lastPlayedTrackId);
      expect(loaded.lastPositionMs, expected.lastPositionMs);
      expect(loaded.recentTrackIds, expected.recentTrackIds);
    },
  );

  test('rememberTrack dedupes and caps recent items', () {
    const MeditationLibraryState seed = MeditationLibraryState(
      lastPlayedTrackId: 'track_b',
      lastPositionMs: 1000,
      recentTrackIds: <String>['track_b', 'track_c', 'track_d'],
    );

    final MeditationLibraryState updated = seed.rememberTrack(
      'track_c',
      lastPositionMs: 5000,
      maxRecentTracks: 3,
    );

    expect(updated.lastPlayedTrackId, 'track_c');
    expect(updated.lastPositionMs, 5000);
    expect(updated.recentTrackIds, const <String>[
      'track_c',
      'track_b',
      'track_d',
    ]);
  });
}

class _MemoryMeditationLibraryStore
    implements MeditationLibraryPreferencesStore {
  final Map<String, String> _values = <String, String>{};

  @override
  Future<String?> getString(String key) async => _values[key];

  @override
  Future<void> setString(String key, String value) async {
    _values[key] = value;
  }
}
