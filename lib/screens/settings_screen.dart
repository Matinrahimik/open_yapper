import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../services/native_bridge.dart';
import '../services/recording_service.dart';
import '../services/settings_storage.dart';
import '../widgets/pasteable_text_field.dart';

/// Formats a hotkey (keyCode + modifier flags) for display.
String formatHotkeyDisplay(int keyCode, int flags) {
  const modifierSymbols = {
    0x20000: '⇧', // Shift
    0x40000: '⌃', // Control
    0x80000: '⌥', // Option
    0x100000: '⌘', // Command
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
    // Special keys (layout-independent)
    36: 'Return',
    48: 'Tab',
    49: 'Space',
    51: 'Delete',
    53: 'Escape',
    117: 'Forward Delete',
    123: '←',
    124: '→',
    125: '↓',
    126: '↑',
    // Letter keys (ANSI / US QWERTY physical positions)
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
    30: ']',
    31: 'O',
    32: 'U',
    33: '[',
    34: 'I',
    35: 'P',
    37: 'L',
    38: 'J',
    39: "'",
    40: 'K',
    41: ';',
    42: '\\',
    43: ',',
    44: '/',
    45: 'N',
    46: 'M',
    47: '.',
    50: '`',
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
  final TextEditingController _apiKeyController = TextEditingController();
  bool _apiKeyObscured = true;
  bool _genZEnabled = false;
  HotkeyConfig _hotkeyConfig = HotkeyConfig.defaultConfig;
  String? _capturingHotkey; // 'start' | 'stop' | 'hold'

  @override
  void initState() {
    super.initState();
    _loadSettings();
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
    if (mounted) {
      setState(() {
        _apiKeyController.text = key ?? '';
        _hotkeyConfig = hotkeyConfig;
        _genZEnabled = genZEnabled;
      });
    }
  }

  Future<void> _saveGenZ(bool enabled) async {
    await saveGenZEnabled(enabled);
    if (mounted) {
      setState(() => _genZEnabled = enabled);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(enabled ? 'Gen Z mode on' : 'Gen Z mode off'),
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
          ),
        'stop' => HotkeyConfig(
            startKeyCode: _hotkeyConfig.startKeyCode,
            startFlags: _hotkeyConfig.startFlags,
            stopKeyCode: captured['keyCode']!,
            stopFlags: captured['flags']!,
            holdKeyCode: _hotkeyConfig.holdKeyCode,
            holdFlags: _hotkeyConfig.holdFlags,
          ),
        'hold' => HotkeyConfig(
            startKeyCode: _hotkeyConfig.startKeyCode,
            startFlags: _hotkeyConfig.startFlags,
            stopKeyCode: _hotkeyConfig.stopKeyCode,
            stopFlags: _hotkeyConfig.stopFlags,
            holdKeyCode: captured['keyCode']!,
            holdFlags: captured['flags']!,
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hotkey updated')),
        );
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

  Future<void> _saveApiKey() async {
    await saveGeminiApiKey(_apiKeyController.text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API key saved')),
      );
    }
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
              child: Text(
                'Settings',
                style: theme.textTheme.headlineSmall,
              ),
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
                        Text(
                          'Gen Z Mode',
                          style: theme.textTheme.titleSmall,
                        ),
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
                  Switch(
                    value: _genZEnabled,
                    onChanged: _saveGenZ,
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
                                    () => _apiKeyObscured = !_apiKeyObscured);
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
                    isCapturing: _capturingHotkey == 'start',
                    onEdit: () => _captureAndSaveHotkey('start'),
                  ),
                  const SizedBox(height: 12),
                  _HotkeyRow(
                    label: 'Stop recording',
                    description: 'Press to stop and process',
                    keyCode: _hotkeyConfig.stopKeyCode,
                    flags: _hotkeyConfig.stopFlags,
                    isCapturing: _capturingHotkey == 'stop',
                    onEdit: () => _captureAndSaveHotkey('stop'),
                  ),
                  const SizedBox(height: 12),
                  _HotkeyRow(
                    label: 'Hold to record',
                    description: 'Hold to record, release to stop',
                    keyCode: _hotkeyConfig.holdKeyCode,
                    flags: _hotkeyConfig.holdFlags,
                    isCapturing: _capturingHotkey == 'hold',
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
    required this.isCapturing,
    required this.onEdit,
  });

  final String label;
  final String description;
  final int keyCode;
  final int flags;
  final bool isCapturing;
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
        // Key-like display (replication of actual button)
        Container(
          constraints: const BoxConstraints(minWidth: 120, minHeight: 44),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
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
                    display,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          onPressed: isCapturing ? null : onEdit,
          icon: const Icon(Symbols.edit, size: 18),
          tooltip: 'Change hotkey',
          style: IconButton.styleFrom(
            minimumSize: const Size(44, 44),
          ),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
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
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
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
