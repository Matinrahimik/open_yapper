import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../services/native_bridge.dart';
import '../services/prompt_builder.dart';
import '../services/recording_history_service.dart';
import '../services/settings_storage.dart';
import '../widgets/pasteable_text_field.dart';

const _gridColumns = 5;
const _cellWidth = 72.0;
const _cellHeight = 88.0;

class InstalledApp {
  InstalledApp({
    required this.name,
    required this.path,
    this.iconBase64,
  });

  final String name;
  final String path;
  final String? iconBase64;

  ImageProvider? get iconProvider {
    if (iconBase64 == null || iconBase64!.isEmpty) return null;
    try {
      final bytes = base64Decode(iconBase64!);
      return MemoryImage(bytes);
    } catch (_) {
      return null;
    }
  }
}

class CustomizationScreen extends StatefulWidget {
  const CustomizationScreen({
    super.key,
    required this.historyService,
  });

  final RecordingHistoryService historyService;

  @override
  State<CustomizationScreen> createState() => _CustomizationScreenState();
}

class _CustomizationScreenState extends State<CustomizationScreen> {
  Map<String, String> _appTones = {};
  Map<String, String> _appPrompts = {};
  Set<String> _savedToneAppNames = {};
  List<InstalledApp> _apps = [];
  bool _loaded = false;
  bool _loading = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _isCustomized(String appName) =>
      _savedToneAppNames.contains(appName) || _appPrompts.containsKey(appName);

  Future<void> _load() async {
    setState(() => _loading = true);
    await widget.historyService.loadEntries();
    final tones = await loadAllAppTones();
    final prompts = await loadAllAppPrompts();
    final defaultTone = await loadAppTone('Default');

    List<InstalledApp> apps = [];
    try {
      final raw = await NativeBridge.instance.getInstalledApps();
      apps = raw
          .map((m) => InstalledApp(
                name: m['name'] as String? ?? '',
                path: m['path'] as String? ?? '',
                iconBase64: m['iconBase64'] as String?,
              ))
          .where((a) => a.name.isNotEmpty)
          .toList();
    } catch (_) {
      final used = widget.historyService.entries
          .map((e) => e.targetApp)
          .whereType<String>()
          .where((a) => a.isNotEmpty)
          .toSet()
          .toList()
        ..sort((a, b) => a.compareTo(b));
      apps = used.map((n) => InstalledApp(name: n, path: '')).toList();
    }

    if (mounted) {
      setState(() {
        _appTones = tones;
        _appTones['Default'] ??= defaultTone;
        _appPrompts = prompts;
        _savedToneAppNames = tones.keys.toSet();
        _apps = apps;
        _loaded = true;
        _loading = false;
      });
    }
  }

  Future<void> _saveTone(String appName, String tone) async {
    await saveAppTone(appName, tone);
    if (mounted) {
      setState(() {
        _appTones[appName] = tone;
        _savedToneAppNames = {..._savedToneAppNames, appName};
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tone for $appName saved')),
      );
    }
  }

  Future<void> _savePrompt(String appName, String? prompt) async {
    await saveAppPrompt(appName, prompt);
    if (mounted) {
      setState(() {
        if (prompt == null || prompt.trim().isEmpty) {
          _appPrompts.remove(appName);
        } else {
          _appPrompts[appName] = prompt;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Custom prompt for $appName saved')),
      );
    }
  }

  void _showAppMenu(BuildContext context, InstalledApp app) {
    final tone = _appTones[app.name] ?? PromptBuilder.validTones[1];
    final prompt = _appPrompts[app.name] ?? '';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AppConfigSheet(
        app: app,
        initialTone: tone,
        initialPrompt: prompt,
        onSaveTone: (t) => _saveTone(app.name, t),
        onSavePrompt: (p) => _savePrompt(app.name, p),
        onClose: () => Navigator.pop(context),
      ),
    );
  }

  List<InstalledApp> get _filteredApps {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _apps;
    return _apps.where((a) => a.name.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!_loaded) {
      return const Center(child: CircularProgressIndicator());
    }

    final filtered = _filteredApps;
    final defaultApp = InstalledApp(name: 'Default', path: '');
    final allApps = [defaultApp, ...filtered];
    final customized =
        allApps.where((a) => _isCustomized(a.name)).toList();
    final notCustomized =
        allApps.where((a) => !_isCustomized(a.name)).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            'Customization',
            style: theme.textTheme.headlineSmall,
          ),
        ),
        _Section(
          title: 'Per-app customization',
          icon: Symbols.tune,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tap an app to set the tone and optional custom instructions. The app in focus when you record determines which settings are used.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              PasteableTextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search apps...',
                  prefixIcon: Icon(Symbols.search, size: 20),
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 24),
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else ...[
                if (customized.isNotEmpty) ...[
                  Text(
                    'Customized',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _AppGrid(
                    apps: customized,
                    appTones: _appTones,
                    onTap: (app) => _showAppMenu(context, app),
                  ),
                  const SizedBox(height: 24),
                ],
                Text(
                  'Not customized',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                _AppGrid(
                  apps: notCustomized,
                  appTones: _appTones,
                  onTap: (app) => _showAppMenu(context, app),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _AppGrid extends StatelessWidget {
  const _AppGrid({
    required this.apps,
    required this.appTones,
    required this.onTap,
  });

  final List<InstalledApp> apps;
  final Map<String, String> appTones;
  final ValueChanged<InstalledApp> onTap;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: _gridColumns,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: _cellWidth / _cellHeight,
      children: apps
          .map((app) => _AppGridItem(
                app: app,
                tone: appTones[app.name] ?? PromptBuilder.validTones[1],
                onTap: () => onTap(app),
              ))
          .toList(),
    );
  }
}

class _AppGridItem extends StatelessWidget {
  const _AppGridItem({
    required this.app,
    required this.tone,
    required this.onTap,
  });

  final InstalledApp app;
  final String tone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (app.iconProvider != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image(
                  image: app.iconProvider!,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  app.name == 'Default' ? Symbols.settings : Symbols.apps,
                  size: 28,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: 6),
            Text(
              app.name,
              style: theme.textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _AppConfigSheet extends StatefulWidget {
  const _AppConfigSheet({
    required this.app,
    required this.initialTone,
    required this.initialPrompt,
    required this.onSaveTone,
    required this.onSavePrompt,
    required this.onClose,
  });

  final InstalledApp app;
  final String initialTone;
  final String initialPrompt;
  final Future<void> Function(String) onSaveTone;
  final Future<void> Function(String?) onSavePrompt;
  final VoidCallback onClose;

  @override
  State<_AppConfigSheet> createState() => _AppConfigSheetState();
}

class _AppConfigSheetState extends State<_AppConfigSheet> {
  late String _tone;
  late TextEditingController _promptController;
  late bool _isAdvanced;

  @override
  void initState() {
    super.initState();
    _tone = widget.initialTone;
    _promptController = TextEditingController(text: widget.initialPrompt);
    _isAdvanced = widget.initialPrompt.trim().isNotEmpty;
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header: icon, name, mode toggle (top right)
              Row(
                children: [
                  if (widget.app.iconProvider != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image(
                        image: widget.app.iconProvider!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Symbols.apps,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      widget.app.name,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('Simple')),
                      ButtonSegment(value: true, label: Text('Advanced')),
                    ],
                    selected: {_isAdvanced},
                    onSelectionChanged: (selected) {
                      setState(() => _isAdvanced = selected.first);
                      if (!_isAdvanced &&
                          _promptController.text.trim().isNotEmpty) {
                        widget.onSavePrompt(null);
                        _promptController.clear();
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Tone',
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<String>(
                        segments: PromptBuilder.validTones
                            .map((t) => ButtonSegment<String>(
                                  value: t,
                                  label: Text(
                                      t[0].toUpperCase() + t.substring(1)),
                                ))
                            .toList(),
                        selected: {_tone},
                        onSelectionChanged: (selected) async {
                          if (selected.isNotEmpty) {
                            setState(() => _tone = selected.first);
                            await widget.onSaveTone(selected.first);
                          }
                        },
                      ),
                      if (_isAdvanced) ...[
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Custom instructions for how you want the output to be',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () async {
                                final data =
                                    await Clipboard.getData(Clipboard.kTextPlain);
                                final text = data?.text ?? '';
                                if (text.isNotEmpty) {
                                  _promptController.text =
                                      _promptController.text + text;
                                  _promptController.selection =
                                      TextSelection.collapsed(
                                          offset: _promptController.text.length);
                                  setState(() {});
                                }
                              },
                              icon: const Icon(Symbols.content_paste, size: 18),
                              label: const Text('Paste'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        PasteableTextField(
                          controller: _promptController,
                          maxLines: 4,
                          cursorColor: _promptController.text.trim().isNotEmpty
                              ? theme.colorScheme.primary
                              : null,
                          decoration: const InputDecoration(
                            hintText:
                                'e.g. Always use bullet points, keep it brief, write in first person...',
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                          onChanged: (_) => setState(() {}),
                          onSubmitted: (_) async {
                            await widget.onSavePrompt(
                                _promptController.text.trim().isEmpty
                                    ? null
                                    : _promptController.text);
                            if (mounted) {
                              widget.onClose();
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // Bottom buttons with spacing from content
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_isAdvanced)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilledButton(
                        onPressed: () async {
                          final text = _promptController.text.trim();
                          await widget.onSavePrompt(text.isEmpty ? null : text);
                          if (mounted) {
                            widget.onClose();
                          }
                        },
                        child: const Text('Save custom prompt'),
                      ),
                    ),
                  TextButton(
                    onPressed: widget.onClose,
                    child: const Text('Done'),
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
