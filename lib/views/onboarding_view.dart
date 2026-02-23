import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/native_bridge.dart';
import '../services/recording_service.dart';
import '../services/settings_storage.dart';
import '../widgets/pasteable_text_field.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key, required this.recordingService});

  final RecordingService recordingService;

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  Timer? _pollTimer;
  bool _apiKeySet = false;
  final TextEditingController _apiKeyController = TextEditingController();
  bool _apiKeyObscured = true;
  bool _savingApiKey = false;

  @override
  void initState() {
    super.initState();
    _initOnboarding();
    _startPolling();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<bool> _checkApiKey() async {
    final key = await loadGeminiApiKey();
    final isSet = key != null && key.trim().isNotEmpty;
    if (mounted) setState(() => _apiKeySet = isSet);
    return isSet;
  }

  Future<void> _initOnboarding() async {
    // Re-check permissions immediately when welcome screen would show
    await widget.recordingService.checkPermissions();
    final apiKeySet = await _checkApiKey();
    if (widget.recordingService.allPermissionsGranted && apiKeySet) {
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

  bool _shouldHideOnboarding() =>
      widget.recordingService.allPermissionsGranted && _apiKeySet;

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (!widget.recordingService.allPermissionsGranted) {
        await widget.recordingService.checkPermissions();
      }
      await _checkApiKey();
      if (_shouldHideOnboarding()) {
        await setOnboardingCompleted(true);
      }
      if (mounted) setState(() {});
    });
  }

  Future<void> _openMicrophoneSettings() async {
    const urls = [
      'x-apple.systemsettings:com.apple.preference.security?Privacy_Microphone',
      'x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone',
      'x-apple.systemsettings:',
    ];
    // Try native first, then URL fallbacks for different macOS versions.
    try {
      await NativeBridge.instance.openMicrophoneSettings();
    } catch (_) {
      for (final url in urls) {
        if (await _openSettingsUrl(url)) break;
      }
    }
  }

  Future<void> _openAccessibilitySettings() async {
    const urls = [
      'x-apple.systemsettings:com.apple.preference.security?Privacy_Accessibility',
      'x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility',
      'x-apple.systemsettings:',
    ];
    try {
      await NativeBridge.instance.openAccessibilitySettings();
    } catch (_) {
      for (final url in urls) {
        if (await _openSettingsUrl(url)) break;
      }
    }
  }

  Future<bool> _openSettingsUrl(String urlString) async {
    if (!Platform.isMacOS) return false;
    final uri = Uri.parse(urlString);
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
    return false;
  }

  Future<void> _openGeminiApiKeyUrl() async {
    try {
      await launchUrl(
        Uri.parse('https://aistudio.google.com/apikey'),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {}
  }

  Future<void> _saveApiKeyAndComplete() async {
    final key = _apiKeyController.text.trim();
    if (key.isEmpty) {
      return;
    }
    setState(() => _savingApiKey = true);
    try {
      await saveGeminiApiKey(key);
      await setOnboardingCompleted(true);
      if (mounted) {
        setState(() {
          _apiKeySet = true;
          _savingApiKey = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _savingApiKey = false);
    }
  }

  void _skipApiKey() async {
    await setOnboardingCompleted(true);
    if (mounted) setState(() => _apiKeySet = true);
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
        if (_shouldHideOnboarding()) {
          return const SizedBox.shrink();
        }

        // Step 2: API key (after permissions are granted)
        if (widget.recordingService.allPermissionsGranted) {
          return _ApiKeyOnboardingContent(
            controller: _apiKeyController,
            obscured: _apiKeyObscured,
            saving: _savingApiKey,
            onObscuredChanged: () =>
                setState(() => _apiKeyObscured = !_apiKeyObscured),
            onChanged: () => setState(() {}),
            onGetKey: _openGeminiApiKeyUrl,
            onSave: _saveApiKeyAndComplete,
            onSkip: _skipApiKey,
          );
        }

        // Step 1: Permissions
        return Container(
          color: Colors.black54,
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20)],
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

class _ApiKeyOnboardingContent extends StatelessWidget {
  const _ApiKeyOnboardingContent({
    required this.controller,
    required this.obscured,
    required this.saving,
    required this.onObscuredChanged,
    required this.onChanged,
    required this.onGetKey,
    required this.onSave,
    required this.onSkip,
  });

  final TextEditingController controller;
  final bool obscured;
  final bool saving;
  final VoidCallback onObscuredChanged;
  final VoidCallback onChanged;
  final VoidCallback onGetKey;
  final VoidCallback onSave;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Symbols.key, size: 32, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  Text(
                    'Set up Gemini API',
                    style: theme.textTheme.headlineSmall,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Open Yapper uses Google\'s Gemini AI to transcribe your voice recordings into text. To enable this, you\'ll need a free API key from Google AI Studio.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: onGetKey,
                icon: const Icon(Symbols.link, size: 18),
                label: const Text(
                  'Get your API key at aistudio.google.com/apikey',
                ),
                style: TextButton.styleFrom(alignment: Alignment.centerLeft),
              ),
              const SizedBox(height: 24),
              PasteableTextField(
                controller: controller,
                obscureText: obscured,
                onChanged: (_) => onChanged(),
                decoration: InputDecoration(
                  hintText: 'Paste your Gemini API key here',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscured ? Symbols.visibility : Symbols.visibility_off,
                      size: 20,
                    ),
                    onPressed: onObscuredChanged,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Symbols.lock, size: 18, color: colorScheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Your API key is stored securely in your Mac\'s Keychain—the same system that protects your passwords and login credentials. It never leaves your device.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: saving ? null : onSkip,
                    child: const Text('Skip for now'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: saving || controller.text.trim().isEmpty
                        ? null
                        : onSave,
                    child: saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save & continue'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
                Text(title, style: Theme.of(context).textTheme.titleMedium),
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
