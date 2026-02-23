import 'dart:io';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/native_bridge.dart';
import '../services/recording_service.dart';
import '../services/settings_storage.dart';
import '../services/update_service.dart';
import '../widgets/pasteable_text_field.dart';

/// Formats a hotkey (keyCode + modifier flags) for display.
String formatHotkeyDisplay(int keyCode, int flags) {
  // Keep macOS modifier order consistent with menu item display.
  const modifierSymbols = <int, String>{
    0x40000: '⌃', // Control
    0x80000: '⌥', // Option
    0x20000: '⇧', // Shift
    0x100000: '⌘', // Command
    0x800000: 'fn', // Function (Globe/Fn)
  };
  final parts = <String>[];
  for (final entry in modifierSymbols.entries) {
    if ((flags & entry.key) != 0) parts.add(entry.value);
  }
  parts.add(_keyCodeToLabel(keyCode));
  return parts.join(' ');
}

/// Maps macOS virtual key codes (HIToolbox/Carbon) to display labels.
/// These codes are physical key positions on a US QWERTY keyboard.
String _keyCodeToLabel(int code) {
  const labels = {
    // Letters
    0: 'A',
    1: 'S',
    2: 'D',
    3: 'F',
    4: 'H',
    5: 'G',
    6: 'Z',
    7: 'X',
    8: 'C',
    9: 'V',
    11: 'B',
    12: 'Q',
    13: 'W',
    14: 'E',
    15: 'R',
    16: 'Y',
    17: 'T',
    31: 'O',
    32: 'U',
    34: 'I',
    35: 'P',
    37: 'L',
    38: 'J',
    40: 'K',
    45: 'N',
    46: 'M',
    // Number row
    18: '1',
    19: '2',
    20: '3',
    21: '4',
    22: '6',
    23: '5',
    24: '=',
    25: '9',
    26: '7',
    27: '-',
    28: '8',
    29: '0',
    // Symbols
    30: ']',
    33: '[',
    39: "'",
    41: ';',
    42: '\\',
    43: ',',
    44: '/',
    47: '.',
    50: '`',
    // Main keyboard / navigation
    36: 'Return',
    48: 'Tab',
    49: 'Space',
    51: 'Delete',
    53: 'Escape',
    54: 'Right Command',
    55: 'Command',
    56: 'Shift',
    57: 'Caps Lock',
    58: 'Option',
    59: 'Control',
    60: 'Right Shift',
    61: 'Right Option',
    62: 'Right Control',
    63: 'Fn',
    65: 'Keypad .',
    67: 'Keypad *',
    69: 'Keypad +',
    71: 'Clear',
    72: 'Volume Up',
    73: 'Volume Down',
    74: 'Mute',
    75: 'Keypad /',
    76: 'Keypad Enter',
    78: 'Keypad -',
    81: 'Keypad =',
    82: 'Keypad 0',
    83: 'Keypad 1',
    84: 'Keypad 2',
    85: 'Keypad 3',
    86: 'Keypad 4',
    87: 'Keypad 5',
    88: 'Keypad 6',
    89: 'Keypad 7',
    91: 'Keypad 8',
    92: 'Keypad 9',
    96: 'F5',
    97: 'F6',
    98: 'F7',
    99: 'F3',
    100: 'F8',
    101: 'F9',
    103: 'F11',
    105: 'F13',
    106: 'F16',
    107: 'F14',
    109: 'F10',
    111: 'F12',
    113: 'F15',
    114: 'Help',
    115: 'Home',
    116: 'Page Up',
    117: 'Forward Delete',
    118: 'F4',
    119: 'End',
    120: 'F2',
    121: 'Page Down',
    122: 'F1',
    123: '←',
    124: '→',
    125: '↓',
    126: '↑',
    // ISO / JIS layout-specific keys
    10: 'Section',
    93: 'Yen',
    94: 'Underscore',
    95: 'Keypad Comma',
    // Additional function keys
    64: 'F17',
    79: 'F18',
    80: 'F19',
    90: 'F20',
  };
  return labels[code] ?? 'Key $code';
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.recordingService,
    required this.onHotKeyChanged,
  });

  final RecordingService recordingService;
  final VoidCallback onHotKeyChanged;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _updateService = GitHubUpdateService(
    owner: 'Matinrahimik',
    repo: 'open_yapper',
  );
  final TextEditingController _apiKeyController = TextEditingController();
  bool _apiKeyObscured = true;
  bool _genZEnabled = false;
  bool _phraseExpansionEnabled = true;
  HotkeyConfig _hotkeyConfig = HotkeyConfig.defaultConfig;
  String? _capturingHotkey; // 'start' | 'stop' | 'hold'
  String _appVersion = '...';
  bool _isCheckingUpdates = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadAppVersion();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final key = await loadGeminiApiKey();
    final hotkeyConfig = await loadHotkeyConfig();
    final genZEnabled = await loadGenZEnabled();
    final phraseExpansionEnabled = await loadPhraseExpansionEnabled();
    if (mounted) {
      setState(() {
        _apiKeyController.text = key ?? '';
        _hotkeyConfig = hotkeyConfig;
        _genZEnabled = genZEnabled;
        _phraseExpansionEnabled = phraseExpansionEnabled;
      });
    }
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() {
        _appVersion = info.version;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _appVersion = 'unknown');
    }
  }

  Future<void> _saveGenZ(bool enabled) async {
    await saveGenZEnabled(enabled);
    if (mounted) {
      setState(() => _genZEnabled = enabled);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(enabled ? 'Gen Z mode on' : 'Gen Z mode off')),
      );
    }
  }

  Future<void> _savePhraseExpansion(bool enabled) async {
    await savePhraseExpansionEnabled(enabled);
    if (mounted) {
      setState(() => _phraseExpansionEnabled = enabled);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            enabled ? 'Phrase expansion on' : 'Phrase expansion off',
          ),
        ),
      );
    }
  }

  Future<void> _captureAndSaveHotkey(String which) async {
    setState(() => _capturingHotkey = which);
    try {
      final captured = await NativeBridge.instance.captureNextHotkey();
      if (!mounted) return;
      final newConfig = switch (which) {
        'start' => HotkeyConfig(
          startKeyCode: captured['keyCode']!,
          startFlags: captured['flags']!,
          stopKeyCode: _hotkeyConfig.stopKeyCode,
          stopFlags: _hotkeyConfig.stopFlags,
          holdKeyCode: _hotkeyConfig.holdKeyCode,
          holdFlags: _hotkeyConfig.holdFlags,
          startEnabled: _hotkeyConfig.startEnabled,
          stopEnabled: _hotkeyConfig.stopEnabled,
          holdEnabled: _hotkeyConfig.holdEnabled,
        ),
        'stop' => HotkeyConfig(
          startKeyCode: _hotkeyConfig.startKeyCode,
          startFlags: _hotkeyConfig.startFlags,
          stopKeyCode: captured['keyCode']!,
          stopFlags: captured['flags']!,
          holdKeyCode: _hotkeyConfig.holdKeyCode,
          holdFlags: _hotkeyConfig.holdFlags,
          startEnabled: _hotkeyConfig.startEnabled,
          stopEnabled: _hotkeyConfig.stopEnabled,
          holdEnabled: _hotkeyConfig.holdEnabled,
        ),
        'hold' => HotkeyConfig(
          startKeyCode: _hotkeyConfig.startKeyCode,
          startFlags: _hotkeyConfig.startFlags,
          stopKeyCode: _hotkeyConfig.stopKeyCode,
          stopFlags: _hotkeyConfig.stopFlags,
          holdKeyCode: captured['keyCode']!,
          holdFlags: captured['flags']!,
          startEnabled: _hotkeyConfig.startEnabled,
          stopEnabled: _hotkeyConfig.stopEnabled,
          holdEnabled: _hotkeyConfig.holdEnabled,
        ),
        _ => _hotkeyConfig,
      };
      await saveHotkeyConfig(newConfig);
      setState(() {
        _hotkeyConfig = newConfig;
        _capturingHotkey = null;
      });
      widget.onHotKeyChanged();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Hotkey updated')));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _capturingHotkey = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to capture hotkey')),
        );
      }
    }
  }

  Future<void> _saveHotkeyEnabled(String which, bool enabled) async {
    final newConfig = switch (which) {
      'start' => HotkeyConfig(
        startKeyCode: _hotkeyConfig.startKeyCode,
        startFlags: _hotkeyConfig.startFlags,
        stopKeyCode: _hotkeyConfig.stopKeyCode,
        stopFlags: _hotkeyConfig.stopFlags,
        holdKeyCode: _hotkeyConfig.holdKeyCode,
        holdFlags: _hotkeyConfig.holdFlags,
        startEnabled: enabled,
        stopEnabled: _hotkeyConfig.stopEnabled,
        holdEnabled: _hotkeyConfig.holdEnabled,
      ),
      'stop' => HotkeyConfig(
        startKeyCode: _hotkeyConfig.startKeyCode,
        startFlags: _hotkeyConfig.startFlags,
        stopKeyCode: _hotkeyConfig.stopKeyCode,
        stopFlags: _hotkeyConfig.stopFlags,
        holdKeyCode: _hotkeyConfig.holdKeyCode,
        holdFlags: _hotkeyConfig.holdFlags,
        startEnabled: _hotkeyConfig.startEnabled,
        stopEnabled: enabled,
        holdEnabled: _hotkeyConfig.holdEnabled,
      ),
      'hold' => HotkeyConfig(
        startKeyCode: _hotkeyConfig.startKeyCode,
        startFlags: _hotkeyConfig.startFlags,
        stopKeyCode: _hotkeyConfig.stopKeyCode,
        stopFlags: _hotkeyConfig.stopFlags,
        holdKeyCode: _hotkeyConfig.holdKeyCode,
        holdFlags: _hotkeyConfig.holdFlags,
        startEnabled: _hotkeyConfig.startEnabled,
        stopEnabled: _hotkeyConfig.stopEnabled,
        holdEnabled: enabled,
      ),
      _ => _hotkeyConfig,
    };

    await saveHotkeyConfig(newConfig);
    if (!mounted) return;
    setState(() => _hotkeyConfig = newConfig);
    widget.onHotKeyChanged();
  }

  Future<void> _saveApiKey() async {
    await saveGeminiApiKey(_apiKeyController.text);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('API key saved')));
    }
  }

  Future<void> _checkForUpdatesManually() async {
    if (_isCheckingUpdates) return;
    setState(() => _isCheckingUpdates = true);
    final result = await _updateService.checkForUpdate();
    if (!mounted) return;
    setState(() => _isCheckingUpdates = false);

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not check for updates right now')),
      );
      return;
    }
    if (!result.hasUpdate) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You are up to date (v${result.currentVersion})'),
        ),
      );
      return;
    }
    await _showUpdateDialog(result);
  }

  Future<void> _showUpdateDialog(UpdateCheckResult result) async {
    final notes = (result.releaseNotes ?? '').trim();
    final preview = notes.isEmpty
        ? 'A new version is available.'
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
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: widget.recordingService,
      builder: (context, _) {
        final recordingService = widget.recordingService;
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text('Settings', style: theme.textTheme.headlineSmall),
            ),
            _Section(
              title: 'Output',
              icon: Symbols.auto_awesome,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Gen Z Mode', style: theme.textTheme.titleSmall),
                        const SizedBox(height: 2),
                        Text(
                          'Rewrite output in Gen Z slang—humorous and relatable',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(value: _genZEnabled, onChanged: _saveGenZ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _Section(
              title: 'Text Expansion',
              icon: Symbols.short_text,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Phrase Expansion',
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Replace aliases like "my email" with saved user info and dictionary corrections.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _phraseExpansionEnabled,
                    onChanged: _savePhraseExpansion,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _Section(
              title: 'Gemini API Key',
              icon: Symbols.key,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Required for voice-to-AI processing. Get a key at https://aistudio.google.com/apikey',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: PasteableTextField(
                          controller: _apiKeyController,
                          obscureText: _apiKeyObscured,
                          decoration: InputDecoration(
                            hintText: 'Enter your Gemini API key',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _apiKeyObscured
                                    ? Symbols.visibility
                                    : Symbols.visibility_off,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(
                                  () => _apiKeyObscured = !_apiKeyObscured,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _saveApiKey,
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Stored securely in macOS Keychain',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _Section(
              title: 'Global Hotkeys',
              icon: Symbols.keyboard,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Configure hotkeys for recording. Works even when the app is in the background. Tap a key to remap.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _HotkeyRow(
                    label: 'Start recording',
                    description: 'Press to begin recording',
                    keyCode: _hotkeyConfig.startKeyCode,
                    flags: _hotkeyConfig.startFlags,
                    enabled: _hotkeyConfig.startEnabled,
                    isCapturing: _capturingHotkey == 'start',
                    onToggleEnabled: (value) =>
                        _saveHotkeyEnabled('start', value),
                    onEdit: () => _captureAndSaveHotkey('start'),
                  ),
                  const SizedBox(height: 12),
                  _HotkeyRow(
                    label: 'Stop recording',
                    description: 'Press to stop and process',
                    keyCode: _hotkeyConfig.stopKeyCode,
                    flags: _hotkeyConfig.stopFlags,
                    enabled: _hotkeyConfig.stopEnabled,
                    isCapturing: _capturingHotkey == 'stop',
                    onToggleEnabled: (value) =>
                        _saveHotkeyEnabled('stop', value),
                    onEdit: () => _captureAndSaveHotkey('stop'),
                  ),
                  const SizedBox(height: 12),
                  _HotkeyRow(
                    label: 'Hold to record',
                    description: 'Hold to record, release to stop',
                    keyCode: _hotkeyConfig.holdKeyCode,
                    flags: _hotkeyConfig.holdFlags,
                    enabled: _hotkeyConfig.holdEnabled,
                    isCapturing: _capturingHotkey == 'hold',
                    onToggleEnabled: (value) =>
                        _saveHotkeyEnabled('hold', value),
                    onEdit: () => _captureAndSaveHotkey('hold'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _Section(
              title: 'Permissions',
              icon: Symbols.shield,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PermissionRow(
                    label: 'Microphone',
                    granted: recordingService.hasPermission,
                    onFix: () => NativeBridge.instance.openMicrophoneSettings(),
                  ),
                  const SizedBox(height: 8),
                  _PermissionRow(
                    label: 'Accessibility',
                    granted: recordingService.accessibilityGranted,
                    onFix: () =>
                        NativeBridge.instance.openAccessibilitySettings(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Text(
                    'Version $_appVersion',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.7,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextButton.icon(
                    onPressed: _isCheckingUpdates
                        ? null
                        : _checkForUpdatesManually,
                    icon: _isCheckingUpdates
                        ? const SizedBox(
                            height: 14,
                            width: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Symbols.system_update_alt, size: 18),
                    label: Text(
                      _isCheckingUpdates ? 'Checking...' : 'Check for updates',
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HotkeyRow extends StatelessWidget {
  const _HotkeyRow({
    required this.label,
    required this.description,
    required this.keyCode,
    required this.flags,
    required this.enabled,
    required this.isCapturing,
    required this.onToggleEnabled,
    required this.onEdit,
  });

  final String label;
  final String description;
  final int keyCode;
  final int flags;
  final bool enabled;
  final bool isCapturing;
  final ValueChanged<bool> onToggleEnabled;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final display = formatHotkeyDisplay(keyCode, flags);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.titleSmall),
              const SizedBox(height: 2),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Switch(value: enabled, onChanged: onToggleEnabled),
        const SizedBox(width: 8),
        // Key-like display (replication of actual button)
        Container(
          constraints: const BoxConstraints(minWidth: 120, minHeight: 44),
          decoration: BoxDecoration(
            color: enabled
                ? theme.colorScheme.surfaceContainerHighest
                : theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.6,
                  ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withValues(alpha: 0.08),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Center(
            child: isCapturing
                ? Text(
                    'Press any key…',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                : Text(
                    enabled ? display : 'Disabled',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: enabled
                          ? null
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          onPressed: isCapturing ? null : onEdit,
          icon: const Icon(Symbols.edit, size: 18),
          tooltip: 'Change hotkey',
          style: IconButton.styleFrom(minimumSize: const Size(44, 44)),
        ),
      ],
    );
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    required this.label,
    required this.granted,
    required this.onFix,
  });

  final String label;
  final bool granted;
  final VoidCallback onFix;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          granted ? Symbols.check_circle : Symbols.error,
          color: granted ? theme.colorScheme.primary : theme.colorScheme.error,
          size: 18,
        ),
        const SizedBox(width: 8),
        Text(label, style: theme.textTheme.bodyLarge),
        const Spacer(),
        if (!granted)
          FilledButton.tonal(
            onPressed: onFix,
            child: const Text('Open Settings'),
          ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
