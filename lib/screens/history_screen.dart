import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../services/native_bridge.dart';
import '../services/recording_history_service.dart';

/// Groups entries by day and hour for sectioned display.
class _HistorySection {
  const _HistorySection({
    required this.dayLabel,
    required this.hourLabel,
    required this.entries,
  });

  final String dayLabel;
  final String hourLabel;
  final List<RecordingEntry> entries;
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({
    super.key,
    required this.historyService,
  });

  final RecordingHistoryService historyService;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final Map<String, ImageProvider> _appIcons = {};

  @override
  void initState() {
    super.initState();
    widget.historyService.loadEntries();
    _loadInstalledAppIcons();
  }

  Future<void> _loadInstalledAppIcons() async {
    try {
      final apps = await NativeBridge.instance.getInstalledApps();
      final icons = <String, ImageProvider>{};
      for (final app in apps) {
        final name = app['name'] as String? ?? '';
        final iconBase64 = app['iconBase64'] as String? ?? '';
        if (name.isEmpty || iconBase64.isEmpty) continue;
        try {
          icons[name] = MemoryImage(base64Decode(iconBase64));
        } catch (_) {
          // Ignore broken icon payloads.
        }
      }
      if (!mounted) return;
      setState(() {
        _appIcons
          ..clear()
          ..addAll(icons);
      });
    } catch (_) {
      // Ignore native errors; app names still render without icons.
    }
  }

  void _copyText(String text) {
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  Future<void> _deleteRecording(RecordingEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete recording',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        content: Text(
          'Remove this recording from history? This cannot be undone.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(
              'Delete',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await widget.historyService.removeRecording(entry.id);
    }
  }

  String _formatDayLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final recordDay = DateTime(dt.year, dt.month, dt.day);
    if (recordDay == today) return 'Today';
    final yesterday = today.subtract(const Duration(days: 1));
    if (recordDay == yesterday) return 'Yesterday';
    return '${dt.month}/${dt.day}/${dt.year}';
  }

  String _formatHourBucket(DateTime dt) {
    final h = dt.hour;
    final am = h < 12;
    final hour = am ? (h == 0 ? 12 : h) : (h == 12 ? 12 : h - 12);
    return '$hour ${am ? 'AM' : 'PM'}';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour;
    final m = dt.minute;
    final am = h < 12;
    final hour = am ? (h == 0 ? 12 : h) : (h == 12 ? 12 : h - 12);
    return '$hour:${m.toString().padLeft(2, '0')} ${am ? 'AM' : 'PM'}';
  }

  List<_HistorySection> _buildSections(List<RecordingEntry> entries) {
    final sections = <_HistorySection>[];
    DateTime? lastDay;
    int? lastHour;
    List<RecordingEntry>? currentEntries;

    for (final entry in entries) {
      final recordDay = DateTime(
        entry.recordedAt.year,
        entry.recordedAt.month,
        entry.recordedAt.day,
      );
      final hour = entry.recordedAt.hour;

      if (lastDay != recordDay || lastHour != hour) {
        if (currentEntries != null && currentEntries.isNotEmpty) {
          sections.add(_HistorySection(
            dayLabel: _formatDayLabel(lastDay!),
            hourLabel: _formatHourBucket(DateTime(0, 1, 1, lastHour!)),
            entries: currentEntries,
          ));
        }
        lastDay = recordDay;
        lastHour = hour;
        currentEntries = [entry];
      } else {
        currentEntries!.add(entry);
      }
    }
    if (currentEntries != null && currentEntries.isNotEmpty && lastDay != null && lastHour != null) {
      sections.add(_HistorySection(
        dayLabel: _formatDayLabel(lastDay),
        hourLabel: _formatHourBucket(DateTime(0, 1, 1, lastHour)),
        entries: currentEntries,
      ));
    }
    return sections;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.historyService,
      builder: (context, _) {
        final entries = widget.historyService.entries;

        if (entries.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Symbols.history,
                    size: 64,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No recordings yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your voice interactions will appear here.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          );
        }

        final sections = _buildSections(entries);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'History',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    TextButton.icon(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Clear history'),
                          content: const Text(
                            'Remove all recordings from history? This cannot be undone.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: FilledButton.styleFrom(
                                backgroundColor:
                                    Theme.of(ctx).colorScheme.error,
                              ),
                              child: const Text('Clear'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true && mounted) {
                        await widget.historyService.clearHistory();
                      }
                    },
                    icon: const Icon(Symbols.delete_outline, size: 18),
                    label: const Text('Clear'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: sections.length,
                itemBuilder: (context, index) {
                  final section = sections[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: RichText(
                          text: TextSpan(
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                            children: [
                              TextSpan(
                                text: section.dayLabel.toLowerCase(),
                                style: const TextStyle(fontSize: 14),
                              ),
                              TextSpan(
                                text: ' · ',
                                style: const TextStyle(fontSize: 14),
                              ),
                              TextSpan(
                                text: section.hourLabel,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      ...section.entries.map((entry) => _HistoryCard(
                            entry: entry,
                            formatTime: _formatTime,
                            appIcon: _appIcons[entry.targetApp],
                            onCopy: _copyText,
                            onDelete: _deleteRecording,
                          )),
                      const SizedBox(height: 20),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
        );
      },
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.entry,
    required this.formatTime,
    this.appIcon,
    required this.onCopy,
    required this.onDelete,
  });

  final RecordingEntry entry;
  final String Function(DateTime) formatTime;
  final ImageProvider? appIcon;
  final void Function(String) onCopy;
  final void Function(RecordingEntry) onDelete;

  @override
  Widget build(BuildContext context) {
    final text = entry.displayText.isNotEmpty
        ? entry.displayText
        : (entry.transcription ?? 'No text');
    final canCopy = text.isNotEmpty;
    final appName = (entry.targetApp?.trim().isNotEmpty ?? false)
        ? entry.targetApp!.trim()
        : 'Unknown app';
    final charCount = text.characters.length;
    final duration = entry.durationSeconds ?? 0;
    final durationLabel = duration >= 10
        ? '${duration.toStringAsFixed(1)}s'
        : '${duration.toStringAsFixed(2)}s';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: canCopy ? () => onCopy(text) : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        text,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (canCopy)
                          IconButton(
                            onPressed: () => onCopy(text),
                            icon: const Icon(Symbols.content_copy, size: 22),
                            tooltip: 'Copy',
                          ),
                        IconButton(
                          onPressed: () => onDelete(entry),
                          icon: const Icon(Symbols.delete_outline, size: 22),
                          tooltip: 'Delete',
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _HistoryInfoPill(
                      child: Text(
                        formatTime(entry.recordedAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      fit: FlexFit.loose,
                      child: _HistoryInfoPill(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (appIcon != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image(
                                  image: appIcon!,
                                  width: 14,
                                  height: 14,
                                  fit: BoxFit.cover,
                                ),
                              )
                            else
                              Icon(
                                Symbols.apps,
                                size: 14,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            const SizedBox(width: 6),
                            Flexible(
                              fit: FlexFit.loose,
                              child: Text(
                                appName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: _HistoryInfoPill(
                    child: Text(
                      '$durationLabel • $charCount chars',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryInfoPill extends StatelessWidget {
  const _HistoryInfoPill({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}
