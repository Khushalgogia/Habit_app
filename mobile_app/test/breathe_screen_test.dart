import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voice_growth_archipelago/src/core/theme/app_theme.dart';
import 'package:voice_growth_archipelago/src/features/breathe/data/breathing_audio_service.dart';
import 'package:voice_growth_archipelago/src/features/breathe/data/breathing_preferences.dart';
import 'package:voice_growth_archipelago/src/features/breathe/presentation/breathe_screen.dart';
import 'package:voice_growth_archipelago/src/features/breathe/domain/breathing_models.dart';
import 'package:voice_growth_archipelago/src/features/home/presentation/home_shell_screen.dart';

void main() {
  testWidgets('Breathe screen opens detail and starts a session', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final _FakePreferencesStore preferencesStore = _FakePreferencesStore();
    final _FakeAudioService audioService = _FakeAudioService();

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(
          body: BreatheScreen(
            preferencesStore: preferencesStore,
            audioService: audioService,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Aura'), findsOneWidget);
    expect(find.text('Relax'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border_rounded), findsNothing);

    await tester.tap(find.text('Relax'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('ANATOMY OF THE BREATH'), findsOneWidget);

    await tester.tap(find.text('Fast'));
    await tester.pump();
    expect(find.text('8 Breaths/Min'), findsOneWidget);

    await tester.tap(find.text('3 min'));
    await tester.pump();
    expect(find.text('3 minutes'), findsOneWidget);

    expect(tester.getBottomRight(find.text('Begin Journey')).dy, lessThan(844));
    await tester.tap(find.text('Begin Journey'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(audioService.preloadCalls, 1);
    expect(find.text('Inhale'), findsOneWidget);
    expect(audioService.phaseCalls, isNotEmpty);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Breathe pauses meditation before starting a session', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    bool meditationPauseCalled = false;
    bool preloadSawPause = false;
    final _FakeAudioService audioService = _FakeAudioService(
      onPreload: () {
        preloadSawPause = meditationPauseCalled;
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(
          body: BreatheScreen(
            preferencesStore: _FakePreferencesStore(),
            audioService: audioService,
            onBeforeSessionStart: () async {
              meditationPauseCalled = true;
            },
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Relax'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('Begin Journey'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(meditationPauseCalled, isTrue);
    expect(preloadSawPause, isTrue);
    expect(find.text('Inhale'), findsOneWidget);
  });

  testWidgets('Breathe home cards keep labels horizontal on phone width', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(
          body: BreatheScreen(
            preferencesStore: _FakePreferencesStore(),
            audioService: _FakeAudioService(),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.scrollUntilVisible(
      find.text('Balance'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    expect(find.textContaining('5s In'), findsWidgets);
    expect(find.textContaining('5s Out'), findsWidgets);
    expect(find.text('Balance'), findsOneWidget);
  });

  testWidgets('Home shell uses Aura nav styling on Breathe tab', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.dark),
        darkTheme: buildAppTheme(Brightness.dark),
        home: _NavHarness(),
      ),
    );
    await tester.pump();

    AnimatedContainer navSurface = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey<String>('home-nav-surface')),
    );
    BoxDecoration decoration = navSurface.decoration! as BoxDecoration;
    expect(
      (decoration.gradient! as LinearGradient).colors.first,
      const Color(0xFF1F2937),
    );

    await tester.tap(find.text('Breathe'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    navSurface = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey<String>('home-nav-surface')),
    );
    decoration = navSurface.decoration! as BoxDecoration;
    expect(
      (decoration.gradient! as LinearGradient).colors.first,
      Colors.white.withValues(alpha: 0.88),
    );
  });

  testWidgets('Custom mode saves presets and supports 30 minute sessions', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final _FakePreferencesStore preferencesStore = _FakePreferencesStore();

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(
          body: BreatheScreen(
            preferencesStore: preferencesStore,
            audioService: _FakeAudioService(),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.scrollUntilVisible(
      find.text('Custom'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    await tester.tap(find.text('Custom'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('New Preset'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Preset name'),
      'Reset',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Inhale seconds'),
      '4',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Hold seconds'),
      '2',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Exhale seconds'),
      '6',
    );
    await tester.tap(find.text('Save Preset'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Reset'), findsWidgets);

    await tester.tap(find.text('30 min'));
    await tester.pump();

    expect(find.text('30 minutes'), findsOneWidget);
    expect(preferencesStore.customPresets.single.name, 'Reset');
  });
}

class _FakePreferencesStore implements BreathingPreferencesStore {
  BreathingSettings current = defaultBreathingSettings;
  List<CustomBreathingPreset> customPresets = <CustomBreathingPreset>[];

  @override
  Future<BreathingSettings> load() async => current;

  @override
  Future<List<CustomBreathingPreset>> loadCustomPresets() async =>
      customPresets;

  @override
  Future<void> save(BreathingSettings settings) async {
    current = settings;
  }

  @override
  Future<void> saveCustomPresets(List<CustomBreathingPreset> presets) async {
    customPresets = List<CustomBreathingPreset>.from(presets);
  }
}

class _NavHarness extends StatefulWidget {
  @override
  State<_NavHarness> createState() => _NavHarnessState();
}

class _NavHarnessState extends State<_NavHarness> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Align(
        alignment: Alignment.bottomCenter,
        child: HomeBottomNavigationBar(
          selectedIndex: _selectedIndex,
          isAuraTab: _selectedIndex == 1 || _selectedIndex == 2,
          isStoryTab: _selectedIndex == 3,
          auraPalette: defaultAuraShellPalette,
          onDestinationSelected: (int index) {
            setState(() => _selectedIndex = index);
          },
        ),
      ),
    );
  }
}

class _FakeAudioService implements BreathingAudioService {
  _FakeAudioService({this.onPreload});

  final VoidCallback? onPreload;
  int preloadCalls = 0;
  int stopCalls = 0;
  int completeCalls = 0;
  final List<BreathingPhase> phaseCalls = <BreathingPhase>[];

  @override
  Future<void> dispose() async {}

  @override
  Future<void> playComplete(BreathingSoundMode soundMode) async {
    completeCalls += 1;
  }

  @override
  Future<void> playPhase(
    BreathingPhase phase, {
    required double durationSeconds,
    required BreathingSoundMode soundMode,
  }) async {
    phaseCalls.add(phase);
  }

  @override
  Future<void> preload() async {
    preloadCalls += 1;
    onPreload?.call();
  }

  @override
  Future<void> stopAll() async {
    stopCalls += 1;
  }
}
