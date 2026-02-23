import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../services/dictionary_service.dart';
import '../widgets/pasteable_text_field.dart';

class DictionaryScreen extends StatefulWidget {
  const DictionaryScreen({super.key, required this.dictionaryService});

  final DictionaryService dictionaryService;

  @override
  State<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  bool _showAllFrequent = false;
  int _activeTabIndex = 0;
  late final TabController _tabController = TabController(
    length: 3,
    vsync: this,
  );

  @override
  void initState() {
    super.initState();
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() => _activeTabIndex = _tabController.index);
    });
    widget.dictionaryService.loadEntries();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openEntryEditor({DictionaryEntry? entry}) async {
    final phraseController = TextEditingController(text: entry?.phrase ?? '');
    final replacementController = TextEditingController(
      text: entry?.replacement ?? '',
    );
    var enabled = entry?.enabled ?? true;
    final isEditing = entry != null;

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isEditing ? 'Edit dictionary entry' : 'Add dictionary entry',
        ),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PasteableTextField(
                controller: phraseController,
                decoration: const InputDecoration(
                  labelText: 'Phrase',
                  hintText: 'e.g. open yapper',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              PasteableTextField(
                controller: replacementController,
                decoration: const InputDecoration(
                  labelText: 'Replacement (optional)',
                  hintText: 'e.g. Open Yapper',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              StatefulBuilder(
                builder: (context, setDialogState) => Row(
                  children: [
                    const Text('Enabled'),
                    const Spacer(),
                    Switch(
                      value: enabled,
                      onChanged: (value) =>
                          setDialogState(() => enabled = value),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (shouldSave != true) return;
    final phrase = phraseController.text.trim();
    final replacement = replacementController.text.trim();
    if (phrase.isEmpty) return;
    if (entry == null) {
      await widget.dictionaryService.addOrUpdateManualEntry(
        phrase: phrase,
        replacement: replacement,
        enabled: enabled,
      );
    } else {
      await widget.dictionaryService.updateEntry(
        id: entry.id,
        phrase: phrase,
        replacement: replacement,
        enabled: enabled,
      );
    }
  }

  List<DictionaryEntry> _filtered(List<DictionaryEntry> entries) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return entries;
    return entries
        .where(
          (entry) =>
              entry.phrase.toLowerCase().contains(query) ||
              entry.replacement.toLowerCase().contains(query),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: widget.dictionaryService,
      builder: (context, _) {
        final entries = widget.dictionaryService.entries;
        final frequentBase = entries
            .where(
              (e) =>
                  !e.isCorrection &&
                  (_showAllFrequent ||
                      e.usageCount >= 2 ||
                      e.confidence >= 0.6 ||
                      e.source == DictionaryEntrySource.manual),
            )
            .toList();
        frequentBase.sort((a, b) {
          final usageCmp = b.usageCount.compareTo(a.usageCount);
          if (usageCmp != 0) return usageCmp;
          final confidenceCmp = b.confidence.compareTo(a.confidence);
          if (confidenceCmp != 0) return confidenceCmp;
          return b.updatedAt.compareTo(a.updatedAt);
        });
        final frequent = _filtered(frequentBase);
        final corrections = _filtered(
          entries.where((e) => e.isCorrection && !e.isSuggestion).toList(),
        );
        final suggestions = _filtered(
          entries.where((e) => e.isSuggestion).toList(),
        );

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Dictionary',
                    style: theme.textTheme.headlineSmall,
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _openEntryEditor(),
                  icon: const Icon(Symbols.add, size: 18),
                  label: const Text('Add entry'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Your personal vocabulary memory with frequent terms, corrections, and suggestions.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            PasteableTextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search dictionary...',
                prefixIcon: Icon(Symbols.search, size: 20),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Corrections'),
                Tab(text: 'Frequent Terms'),
                Tab(text: 'Suggestions'),
              ],
            ),
            const SizedBox(height: 12),
            if (_activeTabIndex == 1)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _showAllFrequent
                            ? 'Showing all frequent terms.'
                            : 'Showing high-signal terms only to reduce clutter.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() => _showAllFrequent = !_showAllFrequent);
                      },
                      child: Text(_showAllFrequent ? 'Show less' : 'Show all'),
                    ),
                  ],
                ),
              ),
            SizedBox(
              height: 520,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _EntryList(
                    entries: corrections,
                    emptyLabel: 'No correction rules yet',
                    onEdit: _openEntryEditor,
                    onDelete: (entry) =>
                        widget.dictionaryService.removeEntry(entry.id),
                    onToggleEnabled: (entry, value) => widget.dictionaryService
                        .setEntryEnabled(entry.id, value),
                    onAcceptSuggestion: null,
                  ),
                  _EntryList(
                    entries: frequent,
                    emptyLabel: 'No frequent terms yet',
                    onEdit: _openEntryEditor,
                    onDelete: (entry) =>
                        widget.dictionaryService.removeEntry(entry.id),
                    onToggleEnabled: (entry, value) => widget.dictionaryService
                        .setEntryEnabled(entry.id, value),
                    onAcceptSuggestion: null,
                  ),
                  _EntryList(
                    entries: suggestions,
                    emptyLabel: 'No suggestions waiting for review',
                    onEdit: _openEntryEditor,
                    onDelete: (entry) =>
                        widget.dictionaryService.removeEntry(entry.id),
                    onToggleEnabled: (entry, value) => widget.dictionaryService
                        .setEntryEnabled(entry.id, value),
                    onAcceptSuggestion: (entry) => widget.dictionaryService
                        .setEntryEnabled(entry.id, true),
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

class _EntryList extends StatelessWidget {
  const _EntryList({
    required this.entries,
    required this.emptyLabel,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleEnabled,
    required this.onAcceptSuggestion,
  });

  final List<DictionaryEntry> entries;
  final String emptyLabel;
  final Future<void> Function({DictionaryEntry? entry}) onEdit;
  final Future<void> Function(DictionaryEntry entry) onDelete;
  final Future<void> Function(DictionaryEntry entry, bool value)
  onToggleEnabled;
  final Future<void> Function(DictionaryEntry entry)? onAcceptSuggestion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (entries.isEmpty) {
      return Center(
        child: Text(
          emptyLabel,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return Material(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.phrase,
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    Switch(
                      value: entry.enabled,
                      onChanged: (value) => onToggleEnabled(entry, value),
                    ),
                  ],
                ),
                if (entry.replacement.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '→ ${entry.replacement}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Tag(label: entry.source.name),
                    _Tag(label: 'usage ${entry.usageCount}'),
                    _Tag(
                      label: 'confidence ${(entry.confidence * 100).round()}%',
                    ),
                    ...entry.reasons.take(2).map((r) => _Tag(label: r)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => onEdit(entry: entry),
                      icon: const Icon(Symbols.edit, size: 18),
                      label: const Text('Edit'),
                    ),
                    const SizedBox(width: 6),
                    if (onAcceptSuggestion != null)
                      TextButton.icon(
                        onPressed: () => onAcceptSuggestion!(entry),
                        icon: const Icon(Symbols.check, size: 18),
                        label: const Text('Accept'),
                      ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => onDelete(entry),
                      tooltip: 'Delete',
                      icon: const Icon(Symbols.delete_outline, size: 20),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}
