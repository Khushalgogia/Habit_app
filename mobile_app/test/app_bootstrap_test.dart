import 'package:flutter_test/flutter_test.dart';
import 'package:voice_growth_archipelago/src/app/app_bootstrap.dart';
import 'package:voice_growth_archipelago/src/app/app_environment.dart';

void main() {
  group('bootstrapApp', () {
    test('keeps startup alive when background audio init throws', () async {
      bool backendCalled = false;

      final AppLaunchState state = await bootstrapApp(
        environment: _testEnvironment(),
        backgroundAudioInitializer: () async {
          throw StateError('audio init failed');
        },
        backendBootstrapper: (AppEnvironment environment) async {
          backendCalled = true;
        },
      );

      expect(state.environment.appVersion, '2.2.4');
      expect(state.isBackgroundAudioAvailable, isFalse);
      expect(state.backgroundAudioWarning, isNotNull);
      expect(backendCalled, isTrue);
    });

    test('marks background audio available when init succeeds', () async {
      bool backendCalled = false;

      final AppLaunchState state = await bootstrapApp(
        environment: _testEnvironment(),
        backgroundAudioInitializer: () async {},
        backendBootstrapper: (AppEnvironment environment) async {
          backendCalled = true;
        },
      );

      expect(state.isBackgroundAudioAvailable, isTrue);
      expect(state.backgroundAudioWarning, isNull);
      expect(backendCalled, isTrue);
    });
  });
}

AppEnvironment _testEnvironment() {
  return const AppEnvironment(
    appName: 'Voice Growth Archipelago',
    applicationId: 'com.voicegrowth.archipelago',
    appVersion: '2.2.4',
    appBuildNumber: '9',
    useDemoBackend: true,
    supportUrl: 'mailto:support@voicegrowth.archipelago',
    supabaseUrl: '',
    supabasePublishableKey: '',
    supabaseRedirectScheme: 'com.voicegrowth.archipelago',
    supabaseRedirectHost: 'login-callback',
  );
}
