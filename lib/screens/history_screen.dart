import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../services/recording_history_service.dart';

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
  final AudioPlayer _player = AudioPlayer();
  String? _playingId;

  @override
  void initState() {
    super.initState();
    widget.historyService.loadEntries();
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playingId = null);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlayback(RecordingEntry entry) async {
    if (!File(entry.filePath).existsSync()) return;

    if (_playingId == entry.id) {
      await _player.stop();
      if (mounted) setState(() => _playingId = null);
    } else {
      await _player.stop();
      await _player.play(DeviceFileSource(entry.filePath));
      if (mounted) setState(() => _playingId = entry.id);
    }
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
      if (_playingId == entry.id) {
        await _player.stop();
        _playingId = null;
      }
      await widget.historyService.removeRecording(entry.id);
    }
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final recordDay = DateTime(dt.year, dt.month, dt.day);
    if (recordDay == today) {
      return 'Today, ${_formatTime(dt)}';
    }
    final yesterday = today.subtract(const Duration(days: 1));
    if (recordDay == yesterday) {
      return 'Yesterday, ${_formatTime(dt)}';
    }
    return '${dt.month}/${dt.day}/${dt.year} ${_formatTime(dt)}';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour;
    final m = dt.minute;
    final am = h < 12;
    final hour = am ? (h == 0 ? 12 : h) : (h == 12 ? 12 : h - 12);
    return '$hour:${m.toString().padLeft(2, '0')} ${am ? 'AM' : 'PM'}';
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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
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
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            final exists = File(entry.filePath).existsSync();
            final isPlaying = _playingId == entry.id;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: exists ? () => _togglePlayback(entry) : null,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isPlaying ? Symbols.stop : Symbols.audio_file,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SelectableText(
                                entry.displayText.isNotEmpty
                                    ? entry.displayText
                                    : 'Audio input',
                                style: Theme.of(context).textTheme.bodyMedium,
                                maxLines: 2,
                              ),
                              if (entry.transcription != null &&
                                  entry.transcription != entry.response &&
                                  entry.transcription!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    entry.transcription!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant
                                              .withValues(alpha: 0.6),
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    _formatDate(entry.recordedAt),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                  ),
                                  if (entry.targetApp != null) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      '→ ${entry.targetApp}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant
                                                .withValues(alpha: 0.6),
                                          ),
                                    ),
                                  ],
                                  if (entry.durationSeconds != null) ...[
                                    const SizedBox(width: 8),
                                    _Chip(
                                        '${entry.durationSeconds!.toStringAsFixed(1)}s'),
                                  ],
                                  if (entry.model != null) ...[
                                    const SizedBox(width: 4),
                                    _Chip(entry.model!),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (entry.displayText.isNotEmpty)
                          IconButton(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(
                                text: entry.displayText,
                              ));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Copied to clipboard')),
                              );
                            },
                            icon: Icon(Symbols.content_copy, size: 22),
                            tooltip: 'Copy',
                          ),
                        if (exists)
                          IconButton(
                            onPressed: () => _togglePlayback(entry),
                            icon: Icon(
                              isPlaying ? Symbols.stop : Symbols.play_arrow,
                              size: 24,
                            ),
                            tooltip: isPlaying ? 'Stop' : 'Play',
                          ),
                        IconButton(
                          onPressed: () => _deleteRecording(entry),
                          icon: const Icon(Symbols.delete_outline, size: 22),
                          tooltip: 'Delete',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
            ),
          ],
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}
