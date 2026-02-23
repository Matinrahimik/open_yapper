import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../services/recording_history_service.dart';

/// Reference values for comparisons.
const _avgTypingCharsPerMin = 200.0; // ~40 WPM, ~5 chars/word

/// Approximate tokens per character for Gemini (text).
const _charsPerToken = 4.0;

/// Approximate tokens per second of audio for Gemini.
const _tokensPerAudioSecond = 32.0;

/// System prompt is ~500 tokens per request.
const _systemPromptTokens = 500.0;

/// Gemini 2.5 Flash-Lite pricing (per 1M tokens). Update if model changes.
const _inputPricePer1M = 0.10;
const _outputPricePer1M = 0.40;

/// WhisperFlow subscription price for comparison.
const _whisperFlowMonthlyPrice = 16.0;

class StatsScreen extends StatefulWidget {
  const StatsScreen({
    super.key,
    required this.historyService,
  });

  final RecordingHistoryService historyService;

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  @override
  void initState() {
    super.initState();
    widget.historyService.addListener(_onHistoryChanged);
    widget.historyService.loadEntries();
  }

  @override
  void dispose() {
    widget.historyService.removeListener(_onHistoryChanged);
    super.dispose();
  }

  void _onHistoryChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = widget.historyService.entries;

    final totalChars = entries.fold<int>(
      0,
      (sum, e) => sum + (e.displayText.length),
    );
    final totalWords = entries.fold<int>(
      0,
      (sum, e) => sum + _wordCount(e.displayText),
    );
    final totalSeconds = entries.fold<double>(
      0,
      (sum, e) => sum + (e.durationSeconds ?? 0),
    );

    // Typing comparison: how long would typing have taken at avg speed?
    final typingMinutes = totalChars / _avgTypingCharsPerMin;
    final typingSeconds = typingMinutes * 60;
    final timeSavedSeconds = typingSeconds - totalSeconds;
    final speedMultiplier = totalSeconds > 0 ? typingSeconds / totalSeconds : 0.0;

    // Speaking speed: chars produced per minute of speech
    final speakingCharsPerMin =
        totalSeconds > 0 ? (totalChars / (totalSeconds / 60)) : 0.0;

    // API cost estimate (all time)
    final costBreakdown = _estimateApiCost(entries);

    // This month's entries for WhisperFlow comparison
    final now = DateTime.now();
    final thisMonthEntries = entries
        .where((e) =>
            e.recordedAt.year == now.year && e.recordedAt.month == now.month)
        .toList();
    final monthCostBreakdown = _estimateApiCost(thisMonthEntries);
    final monthlySavings =
        _whisperFlowMonthlyPrice - monthCostBreakdown.totalCost;

    if (!widget.historyService.isLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            'Your Stats',
            style: theme.textTheme.headlineSmall,
          ),
        ),
        if (entries.isEmpty)
          Card(
            color: theme.colorScheme.surfaceContainerHighest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Symbols.emoji_events,
                      size: 64,
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No recordings yet',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start dictating to see your stats, time saved, and API usage.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          )
        else ...[
          _StatCard(
            icon: Symbols.text_fields,
            title: 'Transcription totals',
            children: [
              _StatRow(
                label: 'Characters transcribed',
                value: _formatNumber(totalChars),
              ),
              _StatRow(
                label: 'Words transcribed',
                value: _formatNumber(totalWords),
              ),
              _StatRow(
                label: 'Audio duration',
                value: _formatDuration(totalSeconds),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _StatCard(
            icon: Symbols.speed,
            title: 'Speed comparison',
            children: [
              _StatRow(
                label: 'Your speaking speed',
                value: '${speakingCharsPerMin.toStringAsFixed(0)} chars/min',
                subtitle: 'Characters produced per minute of speech',
              ),
              _StatRow(
                label: 'Avg typing speed',
                value: '${_avgTypingCharsPerMin.toStringAsFixed(0)} chars/min',
                subtitle: 'Typical human typing (~40 WPM)',
              ),
              _StatRow(
                label: 'Time saved vs typing',
                value: _formatDuration(timeSavedSeconds.clamp(0, double.infinity)),
                subtitle: timeSavedSeconds > 0
                    ? 'You spoke ${speedMultiplier.toStringAsFixed(1)}× faster than typing'
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _StatCard(
            icon: Symbols.receipt_long,
            title: 'API cost breakdown',
            children: [
              _StatRow(
                label: 'Input tokens (est.)',
                value: _formatNumber(costBreakdown.inputTokens.round()),
                subtitle: 'System prompt + audio (~${_tokensPerAudioSecond.toStringAsFixed(0)}/sec)',
              ),
              _StatRow(
                label: 'Output tokens (est.)',
                value: _formatNumber(costBreakdown.outputTokens.round()),
                subtitle: 'Response text (~${_charsPerToken.toStringAsFixed(0)} chars/token)',
              ),
              const Divider(height: 24),
              _StatRow(
                label: 'Input cost',
                value: '\$${costBreakdown.inputCost.toStringAsFixed(4)}',
                subtitle: '\$$_inputPricePer1M per 1M tokens (input)',
              ),
              _StatRow(
                label: 'Output cost',
                value: '\$${costBreakdown.outputCost.toStringAsFixed(4)}',
                subtitle: '\$$_outputPricePer1M per 1M tokens (output)',
              ),
              const Divider(height: 24),
              _StatRow(
                label: 'Total estimated cost',
                value: '\$${costBreakdown.totalCost.toStringAsFixed(4)}',
                subtitle: 'Gemini Flash-Lite pricing (approximate)',
              ),
              const Divider(height: 24),
              _StatRow(
                label: 'This month\'s API cost',
                value: '\$${monthCostBreakdown.totalCost.toStringAsFixed(4)}',
                subtitle: 'Based on ${thisMonthEntries.length} recording(s)',
              ),
              _StatRow(
                label: 'Wispr Flow equivalent',
                value: '\$${_whisperFlowMonthlyPrice.toStringAsFixed(0)}/mo',
                subtitle: 'Fixed subscription price',
              ),
              _StatRow(
                label: 'Savings vs Wispr Flow',
                value: monthlySavings > 0
                    ? '\$${monthlySavings.toStringAsFixed(2)}/mo'
                    : monthlySavings < 0
                        ? '-\$${(-monthlySavings).toStringAsFixed(2)}/mo'
                        : '\$0/mo',
                subtitle: monthlySavings > 0
                    ? 'You\'re spending less with pay-per-use'
                    : monthlySavings < 0
                        ? 'Above Wispr Flow this month'
                        : 'Break-even',
              ),
            ],
          ),
        ],
      ],
    );
  }

  int _wordCount(String text) {
    if (text.trim().isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).length;
  }

  ({int inputTokens, int outputTokens, double inputCost, double outputCost, double totalCost})
      _estimateApiCost(List<RecordingEntry> entries) {
    var inputTokens = 0.0;
    var outputTokens = 0.0;

    for (final entry in entries) {
      final duration = entry.durationSeconds ?? 0;
      final outputChars = entry.displayText.length;

      inputTokens += _systemPromptTokens + (duration * _tokensPerAudioSecond);
      outputTokens += outputChars / _charsPerToken;
    }

    final inputCost = (inputTokens / 1e6) * _inputPricePer1M;
    final outputCost = (outputTokens / 1e6) * _outputPricePer1M;

    return (
      inputTokens: inputTokens.round(),
      outputTokens: outputTokens.round(),
      inputCost: inputCost,
      outputCost: outputCost,
      totalCost: inputCost + outputCost,
    );
  }
}

String _formatNumber(int n) {
  if (n >= 1e6) return '${(n / 1e6).toStringAsFixed(1)}M';
  if (n >= 1e3) return '${(n / 1e3).toStringAsFixed(1)}k';
  return n.toString();
}

String _formatDuration(double seconds) {
  if (seconds < 60) {
    return '${seconds.toStringAsFixed(1)} sec';
  }
  final mins = (seconds / 60).floor();
  final secs = (seconds % 60).round();
  if (mins < 60) {
    return secs > 0 ? '$mins min $secs sec' : '$mins min';
  }
  final hours = (mins / 60).floor();
  final remainMins = mins % 60;
  return remainMins > 0 ? '$hours hr $remainMins min' : '$hours hr';
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

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
            ...children,
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    this.subtitle,
  });

  final String label;
  final String value;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
