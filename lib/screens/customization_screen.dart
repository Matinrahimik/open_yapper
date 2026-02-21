import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../services/hotkey_storage.dart';
import '../services/settings_storage.dart';

class CustomizationScreen extends StatefulWidget {
  const CustomizationScreen({
    super.key,
    required this.onHotKeyChanged,
  });

  final VoidCallback onHotKeyChanged;

  @override
  State<CustomizationScreen> createState() => _CustomizationScreenState();
}

class _CustomizationScreenState extends State<CustomizationScreen> {
  HotKey? _currentHotKey;
  final TextEditingController _apiKeyController = TextEditingController();
  bool _apiKeyObscured = true;

  @override
  void initState() {
    super.initState();
    _loadHotKey();
    _loadApiKey();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadHotKey() async {
    final hotKey = await loadRecordHotKey();
    if (mounted) setState(() => _currentHotKey = hotKey);
  }

  Future<void> _loadApiKey() async {
    final key = await loadGeminiApiKey();
    if (mounted) {
      _apiKeyController.text = key ?? '';
    }
  }

  Future<void> _onHotKeyRecorded(HotKey hotKey) async {
    // Space + system scope crashes on macOS (hotkey_manager #65). Reject it.
    if (hotKey.key == PhysicalKeyboardKey.space) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Space key is not supported as a global hotkey on macOS. Try Cmd+Shift+R instead.',
              style: Theme.of(context).textTheme.bodyMedium!,
            ),
          ),
        );
      }
      return;
    }
    // Cmd+V conflicts with paste; use Cmd+Esc instead.
    if (hotKey.logicalKey == LogicalKeyboardKey.keyV) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cmd+V conflicts with paste. Using Cmd+Esc instead.',
              style: Theme.of(context).textTheme.bodyMedium!,
            ),
          ),
        );
      }
      await saveRecordHotKey(hotKey);
      widget.onHotKeyChanged();
      if (mounted) setState(() => _currentHotKey = defaultRecordHotKey);
      return;
    }
    await saveRecordHotKey(hotKey);
    widget.onHotKeyChanged();
    if (mounted) setState(() => _currentHotKey = hotKey);
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
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _Section(
          title: 'Record Hotkey',
          icon: Symbols.keyboard,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Press the hotkey to start or stop recording. Works even when the app is in the background.',
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
              HotKeyRecorder(
                initalHotKey: _currentHotKey ?? defaultRecordHotKey,
                onHotKeyRecorded: _onHotKeyRecorded,
              ),
              if (_currentHotKey != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Current: ${_currentHotKey!.debugName}',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        _Section(
          title: 'API',
          icon: Symbols.settings,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gemini API Key',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Required for voice transcription. Get a key at https://aistudio.google.com/apikey',
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
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
                            setState(() => _apiKeyObscured = !_apiKeyObscured);
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
            ],
          ),
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
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
