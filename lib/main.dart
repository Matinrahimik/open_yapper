import 'dart:io';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

import 'screens/customization_screen.dart';
import 'screens/dictionary_screen.dart';
import 'screens/history_screen.dart';
// import 'screens/home_screen.dart'; // Commented out - History is main page
import 'screens/settings_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/user_info_screen.dart';
import 'views/onboarding_view.dart';
import 'widgets/screen_container.dart';
import 'services/dictionary_service.dart';
import 'services/native_bridge.dart';
import 'services/recording_history_service.dart';
import 'services/recording_service.dart';
import 'services/settings_storage.dart';
import 'services/update_service.dart';
import 'services/user_profile_service.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final historyService = RecordingHistoryService();
  final dictionaryService = DictionaryService();
  final userProfileService = UserProfileService();
  final recordingService = RecordingService(
    historyService: historyService,
    dictionaryService: dictionaryService,
    userProfileService: userProfileService,
    loadApiKey: loadGeminiApiKey,
    loadModel: () async => 'gemini-flash-lite-latest',
  );

  NativeBridge.instance.setHotkeyCallbacks(
    onStart: () => recordingService.toggleRecording(),
    onStop: () => recordingService.stopRecording(),
    onHoldDown: () => recordingService.startRecording(),
    onHoldUp: () => recordingService.stopRecording(),
  );
  NativeBridge.instance.setCancelCallback(
    () => recordingService.cancelRecordingOrProcessing(),
  );

  runApp(
    MainApp(
      recordingService: recordingService,
      historyService: historyService,
      dictionaryService: dictionaryService,
      userProfileService: userProfileService,
    ),
  );

  // Start hotkey listener after the window is created and platform channel is ready
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    final config = await loadHotkeyConfig();
    await NativeBridge.instance.setHotkeyConfig(
      startKeyCode: config.startKeyCode,
      startFlags: config.startFlags,
      stopKeyCode: config.stopKeyCode,
      stopFlags: config.stopFlags,
      holdKeyCode: config.holdKeyCode,
      holdFlags: config.holdFlags,
      startEnabled: config.startEnabled,
      stopEnabled: config.stopEnabled,
      holdEnabled: config.holdEnabled,
    );
    await NativeBridge.instance.startHotkeyListener();
  });
}

class MainApp extends StatelessWidget {
  const MainApp({
    super.key,
    required this.recordingService,
    required this.historyService,
    required this.dictionaryService,
    required this.userProfileService,
  });

  final RecordingService recordingService;
  final RecordingHistoryService historyService;
  final DictionaryService dictionaryService;
  final UserProfileService userProfileService;

  @override
  Widget build(BuildContext context) {
    final materialTheme = MaterialTheme.withTypography();
    return MaterialApp(
      title: 'Open Yapper',
      theme: materialTheme.light(),
      darkTheme: materialTheme.dark(),
      themeMode: ThemeMode.dark,
      home: MainScaffold(
        recordingService: recordingService,
        historyService: historyService,
        dictionaryService: dictionaryService,
        userProfileService: userProfileService,
      ),
    );
  }
}

enum RailDestination {
  history,
  dictionary,
  userInfo,
  stats,
  customization,
  settings,
}

class AppSidebar extends StatelessWidget {
  const AppSidebar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: colorScheme.surfaceContainerHighest,
      child: NavigationRail(
        extended: false,
        backgroundColor: Colors.transparent,
        indicatorColor: colorScheme.primary,
        groupAlignment: 0.0,
        destinations: [
          NavigationRailDestination(
            icon: IconTheme(
              data: IconThemeData(color: colorScheme.onSurfaceVariant),
              child: const Tooltip(
                message: 'History',
                child: Icon(Symbols.history),
              ),
            ),
            selectedIcon: IconTheme(
              data: IconThemeData(color: colorScheme.surface),
              child: const Tooltip(
                message: 'History',
                child: Icon(Symbols.history, fill: 1),
              ),
            ),
            label: Text(
              'History',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          NavigationRailDestination(
            icon: IconTheme(
              data: IconThemeData(color: colorScheme.onSurfaceVariant),
              child: const Tooltip(
                message: 'Dictionary',
                child: Icon(Symbols.book_2),
              ),
            ),
            selectedIcon: IconTheme(
              data: IconThemeData(color: colorScheme.surface),
              child: const Tooltip(
                message: 'Dictionary',
                child: Icon(Symbols.book_2, fill: 1),
              ),
            ),
            label: Text(
              'Dictionary',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          NavigationRailDestination(
            icon: IconTheme(
              data: IconThemeData(color: colorScheme.onSurfaceVariant),
              child: const Tooltip(
                message: 'User info',
                child: Icon(Symbols.badge),
              ),
            ),
            selectedIcon: IconTheme(
              data: IconThemeData(color: colorScheme.surface),
              child: const Tooltip(
                message: 'User info',
                child: Icon(Symbols.badge, fill: 1),
              ),
            ),
            label: Text(
              'User Info',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          NavigationRailDestination(
            icon: IconTheme(
              data: IconThemeData(color: colorScheme.onSurfaceVariant),
              child: const Tooltip(
                message: 'Stats',
                child: Icon(Symbols.emoji_events),
              ),
            ),
            selectedIcon: IconTheme(
              data: IconThemeData(color: colorScheme.surface),
              child: const Tooltip(
                message: 'Stats',
                child: Icon(Symbols.emoji_events, fill: 1),
              ),
            ),
            label: Text('Stats', style: Theme.of(context).textTheme.labelLarge),
          ),
          NavigationRailDestination(
            icon: IconTheme(
              data: IconThemeData(color: colorScheme.onSurfaceVariant),
              child: const Tooltip(
                message: 'Customization',
                child: Icon(Symbols.tune),
              ),
            ),
            selectedIcon: IconTheme(
              data: IconThemeData(color: colorScheme.surface),
              child: const Tooltip(
                message: 'Customization',
                child: Icon(Symbols.tune, fill: 1),
              ),
            ),
            label: Text(
              'Customization',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          NavigationRailDestination(
            icon: IconTheme(
              data: IconThemeData(color: colorScheme.onSurfaceVariant),
              child: const Tooltip(
                message: 'Settings',
                child: Icon(Symbols.settings),
              ),
            ),
            selectedIcon: IconTheme(
              data: IconThemeData(color: colorScheme.surface),
              child: const Tooltip(
                message: 'Settings',
                child: Icon(Symbols.settings, fill: 1),
              ),
            ),
            label: Text(
              'Settings',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
        ],
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
      ),
    );
  }
}

class MainScaffold extends StatefulWidget {
  const MainScaffold({
    super.key,
    required this.recordingService,
    required this.historyService,
    required this.dictionaryService,
    required this.userProfileService,
  });

  final RecordingService recordingService;
  final RecordingHistoryService historyService;
  final DictionaryService dictionaryService;
  final UserProfileService userProfileService;

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  static const _updateService = GitHubUpdateService(
    owner: 'Matinrahimik',
    repo: 'open_yapper',
  );
  RailDestination _selectedDestination = RailDestination.history;
  bool _hasCheckedLaunchUpdates = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdatesOnLaunch();
    });
  }

  Future<void> _checkForUpdatesOnLaunch() async {
    if (_hasCheckedLaunchUpdates) return;
    _hasCheckedLaunchUpdates = true;

    final result = await _updateService.checkForUpdate();
    if (!mounted || result == null || !result.hasUpdate) return;

    final dismissedVersion = await loadDismissedUpdateVersion();
    if (!mounted) return;
    if (dismissedVersion == result.latestVersion) return;

    await _showLaunchUpdateDialog(result);
  }

  Future<void> _showLaunchUpdateDialog(UpdateCheckResult result) async {
    final notes = (result.releaseNotes ?? '').trim();
    final preview = notes.isEmpty
        ? 'A newer version of Open Yapper is available.'
        : notes.split('\n').take(4).join('\n');
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Update available'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Current: v${result.currentVersion}'),
              Text('Latest: ${result.releaseTag}'),
              const SizedBox(height: 12),
              Text(preview),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await saveDismissedUpdateVersion(result.latestVersion);
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('Later'),
            ),
            FilledButton(
              onPressed: () async {
                await saveDismissedUpdateVersion(null);
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
                if (Platform.isMacOS) {
                  try {
                    await NativeBridge.instance.checkForNativeUpdates();
                    return;
                  } catch (_) {}
                }
                final target = result.downloadUrl ?? result.releasePageUrl;
                if (target != null) {
                  await launchUrl(Uri.parse(target));
                }
              },
              child: const Text('Update now'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          body: Row(
            children: [
              AppSidebar(
                selectedIndex: _selectedDestination.index,
                onDestinationSelected: (index) {
                  setState(() {
                    _selectedDestination = RailDestination.values[index];
                  });
                },
              ),
              Expanded(
                child: ScreenContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: switch (_selectedDestination) {
                          RailDestination.history => HistoryScreen(
                            historyService: widget.historyService,
                          ),
                          RailDestination.dictionary => DictionaryScreen(
                            dictionaryService: widget.dictionaryService,
                          ),
                          RailDestination.userInfo => UserInfoScreen(
                            userProfileService: widget.userProfileService,
                          ),
                          RailDestination.stats => StatsScreen(
                            historyService: widget.historyService,
                          ),
                          RailDestination.customization => CustomizationScreen(
                            historyService: widget.historyService,
                          ),
                          RailDestination.settings => SettingsScreen(
                            recordingService: widget.recordingService,
                            onHotKeyChanged: () async {
                              final config = await loadHotkeyConfig();
                              await NativeBridge.instance.setHotkeyConfig(
                                startKeyCode: config.startKeyCode,
                                startFlags: config.startFlags,
                                stopKeyCode: config.stopKeyCode,
                                stopFlags: config.stopFlags,
                                holdKeyCode: config.holdKeyCode,
                                holdFlags: config.holdFlags,
                                startEnabled: config.startEnabled,
                                stopEnabled: config.stopEnabled,
                                holdEnabled: config.holdEnabled,
                              );
                            },
                          ),
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        OnboardingView(recordingService: widget.recordingService),
      ],
    );
  }
}
