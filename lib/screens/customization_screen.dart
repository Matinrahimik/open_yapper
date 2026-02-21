import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../services/native_bridge.dart';
import '../services/recording_service.dart';
import '../services/settings_storage.dart';

class CustomizationScreen extends StatefulWidget {
  const CustomizationScreen({
    super.key,
    required this.recordingService,
    required this.onHotKeyChanged,
  });

  final RecordingService recordingService;
  final VoidCallback onHotKeyChanged;

  @override
  State<CustomizationScreen> createState() => _CustomizationScreenState();
}

class _CustomizationScreenState extends State<CustomizationScreen> {
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _systemPromptController = TextEditingController();
  bool _apiKeyObscured = true;
  String _selectedModel = 'gemini-2.0-flash';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _systemPromptController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final key = await loadGeminiApiKey();
    final prompt = await loadSystemPrompt();
    final model = await loadGeminiModel();
    if (mounted) {
      setState(() {
        _apiKeyController.text = key ?? '';
        _systemPromptController.text = prompt;
        _selectedModel = model;
        _isLoading = false;
      });
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

  Future<void> _saveSystemPrompt() async {
    await saveSystemPrompt(_systemPromptController.text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('System prompt saved')),
      );
    }
  }

  Future<void> _saveModel(String? value) async {
    if (value == null) return;
    await saveGeminiModel(value);
    if (mounted) setState(() => _selectedModel = value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: widget.recordingService,
      builder: (context, _) {
        final recordingService = widget.recordingService;
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
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
            const SizedBox(height: 24),
            _Section(
              title: 'Gemini Model',
              icon: Symbols.smart_toy,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedModel,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'gemini-2.0-flash',
                        child: Text('Gemini 2.0 Flash (fast)'),
                      ),
                      DropdownMenuItem(
                        value: 'gemini-2.0-pro',
                        child: Text('Gemini 2.0 Pro (smarter)'),
                      ),
                    ],
                    onChanged: _saveModel,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _Section(
              title: 'System Prompt',
              icon: Symbols.psychology,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Instructions for Gemini. Tells it how to process your voice input.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _systemPromptController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText: 'Instructions for Gemini...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: _saveSystemPrompt,
                    child: const Text('Save'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _Section(
              title: 'Global Hotkey',
              icon: Symbols.keyboard,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Press the hotkey to start or stop recording. Works even when the app is in the background.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '⌥ Space (Option + Space)',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hotkey customization coming in a future update.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
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
      child: Padding(
        padding: const EdgeInsets.all(20),
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
