import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/native_bridge.dart';
import '../services/recording_service.dart';
import '../services/settings_storage.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({
    super.key,
    required this.recordingService,
  });

  final RecordingService recordingService;

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _initOnboarding();
    _startPolling();
  }

  Future<void> _initOnboarding() async {
    // Re-check permissions immediately when welcome screen would show
    await widget.recordingService.checkPermissions();
    if (widget.recordingService.allPermissionsGranted) {
      await setOnboardingCompleted(true);
      if (mounted) setState(() {});
      return;
    }
    // Request both permissions for preview: trigger mic request and accessibility prompt
    if (!widget.recordingService.hasPermission) {
      await NativeBridge.instance.checkMicrophonePermission();
    }
    if (!widget.recordingService.accessibilityGranted) {
      await NativeBridge.instance.requestAccessibility();
    }
    if (mounted) setState(() {});
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (!widget.recordingService.allPermissionsGranted) {
        await widget.recordingService.checkPermissions();
        if (widget.recordingService.allPermissionsGranted) {
          await setOnboardingCompleted(true);
        }
        if (mounted) setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _openMicrophoneSettings() async {
    const url =
        'x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone';
    // Try native first (uses shell `open` command), then url_launcher fallback
    try {
      await NativeBridge.instance.openMicrophoneSettings();
    } catch (_) {
      await _openSettingsUrl(url);
    }
  }

  Future<void> _openAccessibilitySettings() async {
    const url =
        'x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility';
    try {
      await NativeBridge.instance.openAccessibilitySettings();
    } catch (_) {
      await _openSettingsUrl(url);
    }
  }

  Future<void> _openSettingsUrl(String urlString) async {
    if (!Platform.isMacOS) return;
    final uri = Uri.parse(urlString);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Future<void> _restartApp() async {
    try {
      await NativeBridge.instance.restartApp();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.recordingService,
      builder: (context, _) {
        if (widget.recordingService.allPermissionsGranted) {
          return const SizedBox.shrink();
        }

        return Container(
          color: Colors.black54,
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Welcome to Open Yapper',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Open Yapper needs two permissions to work properly.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 32),
                  _PermissionTile(
                    icon: Symbols.mic,
                    title: 'Microphone',
                    subtitle: 'To record your voice',
                    granted: widget.recordingService.hasPermission,
                    onGrant: _openMicrophoneSettings,
                  ),
                  const SizedBox(height: 16),
                  _PermissionTile(
                    icon: Symbols.accessibility_new,
                    title: 'Accessibility',
                    subtitle:
                        'To capture the global hotkey and paste into other apps',
                    granted: widget.recordingService.accessibilityGranted,
                    onGrant: _openAccessibilitySettings,
                  ),
                  const SizedBox(height: 24),
                  if (!widget.recordingService.accessibilityGranted) ...[
                    Text(
                      'After enabling Accessibility, restart the app for it to take effect.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    if (Platform.isMacOS) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _restartApp,
                        icon: const Icon(Symbols.refresh, size: 18),
                        label: const Text('Restart Open Yapper'),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.granted,
    required this.onGrant,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool granted;
  final Future<void> Function() onGrant;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 28,
            color: granted ? colorScheme.primary : colorScheme.error,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          if (granted)
            Icon(Symbols.check_circle, color: colorScheme.primary, size: 28)
          else
            FilledButton(
              onPressed: onGrant,
              child: const Text('Open Settings'),
            ),
        ],
      ),
    );
  }
}
