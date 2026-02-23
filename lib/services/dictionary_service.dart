import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

enum DictionaryEntrySource { manual, auto, profile }

class DictionaryEntry {
  const DictionaryEntry({
    required this.id,
    required this.phrase,
    required this.replacement,
    required this.source,
    required this.enabled,
    required this.usageCount,
    required this.sessionCount,
    required this.confidence,
    required this.reasons,
    required this.createdAt,
    required this.updatedAt,
    required this.lastSeenAt,
  });

  final String id;
  final String phrase;
  final String replacement;
  final DictionaryEntrySource source;
  final bool enabled;
  final int usageCount;
  final int sessionCount;
  final double confidence;
  final List<String> reasons;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastSeenAt;

  bool get isCorrection {
    final left = phrase.trim().toLowerCase();
    final right = replacement.trim().toLowerCase();
    return right.isNotEmpty && left != right;
  }

  bool get isSuggestion => isCorrection && !enabled && confidence >= 0.7;

  String get normalizedPhrase => _normalize(phrase);

  DictionaryEntry copyWith({
    String? phrase,
    String? replacement,
    DictionaryEntrySource? source,
    bool? enabled,
    int? usageCount,
    int? sessionCount,
    double? confidence,
    List<String>? reasons,
    DateTime? updatedAt,
    DateTime? lastSeenAt,
  }) {
    return DictionaryEntry(
      id: id,
      phrase: phrase ?? this.phrase,
      replacement: replacement ?? this.replacement,
      source: source ?? this.source,
      enabled: enabled ?? this.enabled,
      usageCount: usageCount ?? this.usageCount,
      sessionCount: sessionCount ?? this.sessionCount,
      confidence: confidence ?? this.confidence,
      reasons: reasons ?? this.reasons,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'phrase': phrase,
    'replacement': replacement,
    'source': source.name,
    'enabled': enabled,
    'usageCount': usageCount,
    'sessionCount': sessionCount,
    'confidence': confidence,
    'reasons': reasons,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'lastSeenAt': lastSeenAt?.toIso8601String(),
  };

  factory DictionaryEntry.fromJson(Map<String, dynamic> json) {
    final sourceName = json['source'] as String? ?? 'manual';
    final source = DictionaryEntrySource.values.firstWhere(
      (v) => v.name == sourceName,
      orElse: () => DictionaryEntrySource.manual,
    );
    final rawReasons = json['reasons'] as List<dynamic>?;
    return DictionaryEntry(
      id: json['id'] as String,
      phrase: (json['phrase'] as String? ?? '').trim(),
      replacement: (json['replacement'] as String? ?? '').trim(),
      source: source,
      enabled: json['enabled'] as bool? ?? true,
      usageCount: json['usageCount'] as int? ?? 0,
      sessionCount: json['sessionCount'] as int? ?? 0,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      reasons: rawReasons == null
          ? const []
          : rawReasons.map((e) => (e as String? ?? '').trim()).toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      lastSeenAt: (json['lastSeenAt'] as String?) == null
          ? null
          : DateTime.parse(json['lastSeenAt'] as String),
    );
  }
}

class DictionaryService extends ChangeNotifier {
  static const _dictionaryFileName = 'dictionary_entries.json';
  static const _autoCorrectionSuggestThreshold = 0.7;
  static const _autoCorrectionApplyThreshold = 0.9;

  DictionaryService({Future<Directory> Function()? documentsDirectoryProvider})
    : _documentsDirectoryProvider =
          documentsDirectoryProvider ?? getApplicationDocumentsDirectory;

  final List<DictionaryEntry> _entries = [];
  final Future<Directory> Function() _documentsDirectoryProvider;
  bool _loaded = false;

  bool get isLoaded => _loaded;
  List<DictionaryEntry> get entries => List.unmodifiable(_entries);

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    await loadEntries();
  }

  Future<Directory> _dictionaryDirectory() async {
    final dir = await _documentsDirectoryProvider();
    final dictionaryDir = Directory('${dir.path}/open_yapper_dictionary');
    if (!await dictionaryDir.exists()) {
      await dictionaryDir.create(recursive: true);
    }
    return dictionaryDir;
  }

  Future<void> loadEntries() async {
    try {
      final dir = await _dictionaryDirectory();
      final file = File('${dir.path}/$_dictionaryFileName');
      if (await file.exists()) {
        final raw = await file.readAsString();
        final list = jsonDecode(raw) as List<dynamic>;
        _entries
          ..clear()
          ..addAll(
            list
                .map((e) => DictionaryEntry.fromJson(e as Map<String, dynamic>))
                .where((e) => e.phrase.trim().isNotEmpty),
          );
      }
      _entries.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    } catch (_) {
      _entries.clear();
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    try {
      final dir = await _dictionaryDirectory();
      final file = File('${dir.path}/$_dictionaryFileName');
      final data = _entries.map((e) => e.toJson()).toList();
      await file.writeAsString(jsonEncode(data));
    } catch (_) {}
    notifyListeners();
  }

  Future<void> addOrUpdateManualEntry({
    required String phrase,
    required String replacement,
    bool enabled = true,
  }) async {
    await _ensureLoaded();
    final cleanedPhrase = phrase.trim();
    if (cleanedPhrase.isEmpty) return;
    final now = DateTime.now();
    final normalized = _normalize(cleanedPhrase);
    final index = _entries.indexWhere((e) => e.normalizedPhrase == normalized);
    if (index >= 0) {
      _entries[index] = _entries[index].copyWith(
        phrase: cleanedPhrase,
        replacement: replacement.trim(),
        enabled: enabled,
        source: DictionaryEntrySource.manual,
        updatedAt: now,
      );
    } else {
      _entries.insert(
        0,
        DictionaryEntry(
          id: now.microsecondsSinceEpoch.toString(),
          phrase: cleanedPhrase,
          replacement: replacement.trim(),
          source: DictionaryEntrySource.manual,
          enabled: enabled,
          usageCount: 0,
          sessionCount: 0,
          confidence: 1.0,
          reasons: const ['manual'],
          createdAt: now,
          updatedAt: now,
          lastSeenAt: null,
        ),
      );
    }
    await _save();
  }

  Future<void> removeEntry(String id) async {
    await _ensureLoaded();
    _entries.removeWhere((entry) => entry.id == id);
    await _save();
  }

  Future<void> setEntryEnabled(String id, bool enabled) async {
    await _ensureLoaded();
    final index = _entries.indexWhere((entry) => entry.id == id);
    if (index < 0) return;
    _entries[index] = _entries[index].copyWith(
      enabled: enabled,
      updatedAt: DateTime.now(),
    );
    await _save();
  }

  Future<void> updateEntry({
    required String id,
    required String phrase,
    required String replacement,
    bool? enabled,
  }) async {
    await _ensureLoaded();
    final index = _entries.indexWhere((entry) => entry.id == id);
    if (index < 0) return;
    final trimmedPhrase = phrase.trim();
    if (trimmedPhrase.isEmpty) return;
    _entries[index] = _entries[index].copyWith(
      phrase: trimmedPhrase,
      replacement: replacement.trim(),
      enabled: enabled ?? _entries[index].enabled,
      source: DictionaryEntrySource.manual,
      updatedAt: DateTime.now(),
    );
    await _save();
  }

  Future<void> ingestObservedText(String text) async {
    await _ensureLoaded();
    final normalizedText = _normalizeSentence(text);
    if (normalizedText.isEmpty) return;

    final candidates = _extractCandidates(normalizedText);
    if (candidates.isEmpty) return;
    final now = DateTime.now();
    final seenInThisSession = <String>{};

    for (final candidate in candidates) {
      final normalized = _normalize(candidate);
      if (normalized.isEmpty) continue;
      final index = _entries.indexWhere(
        (e) => e.normalizedPhrase == normalized,
      );
      if (index >= 0) {
        final prev = _entries[index];
        final nextUsage = prev.usageCount + 1;
        final nextSessionCount = seenInThisSession.add(normalized)
            ? prev.sessionCount + 1
            : prev.sessionCount;
        final confidence = _computeConfidence(
          candidate: normalized,
          usageCount: nextUsage,
          sessionCount: nextSessionCount,
        );
        _entries[index] = prev.copyWith(
          usageCount: nextUsage,
          sessionCount: nextSessionCount,
          confidence: confidence,
          reasons: _reasonsForCandidate(normalized, confidence),
          updatedAt: now,
          lastSeenAt: now,
        );
      } else {
        final confidence = _computeConfidence(
          candidate: normalized,
          usageCount: 1,
          sessionCount: 1,
        );
        final correction = _buildAutoCorrection(
          observedCandidate: normalized,
          confidence: confidence,
        );
        final isAutoAppliedCorrection =
            correction != null &&
            correction.confidence >= _autoCorrectionApplyThreshold;
        _entries.add(
          DictionaryEntry(
            id: '${now.microsecondsSinceEpoch}_${_entries.length}',
            phrase: normalized,
            replacement: correction?.replacement ?? '',
            source: DictionaryEntrySource.auto,
            enabled: isAutoAppliedCorrection || correction == null,
            usageCount: 1,
            sessionCount: 1,
            confidence: correction?.confidence ?? confidence,
            reasons:
                correction?.reasons ??
                _reasonsForCandidate(normalized, confidence),
            createdAt: now,
            updatedAt: now,
            lastSeenAt: now,
          ),
        );
      }
    }

    _entries.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    await _save();
  }

  _AutoCorrection? _buildAutoCorrection({
    required String observedCandidate,
    required double confidence,
  }) {
    if (observedCandidate.length < 4) return null;
    DictionaryEntry? best;
    var bestDistance = 999;
    for (final entry in _entries) {
      if (entry.normalizedPhrase == observedCandidate) continue;
      if (entry.usageCount < 3) continue;
      final dist = _levenshtein(observedCandidate, entry.normalizedPhrase);
      if (dist < bestDistance && dist <= 2) {
        bestDistance = dist;
        best = entry;
      }
    }
    if (best == null) return null;
    final correctionConfidence = (confidence + 0.25).clamp(0.0, 1.0);
    if (correctionConfidence < _autoCorrectionSuggestThreshold) return null;
    return _AutoCorrection(
      replacement: best.phrase,
      confidence: correctionConfidence,
      reasons: const ['similarity', 'frequent'],
    );
  }

  List<String> _extractCandidates(String text) {
    final words = RegExp(
      r"[a-z0-9@._'-]+",
    ).allMatches(text.toLowerCase()).map((m) => m.group(0)!).toList();
    if (words.isEmpty) return const [];

    final candidates = <String>{};
    for (final word in words) {
      if (_isValidWord(word)) candidates.add(word);
    }
    for (var n = 2; n <= 4; n++) {
      for (var i = 0; i <= words.length - n; i++) {
        final phrase = words.sublist(i, i + n).join(' ');
        if (_isValidPhrase(phrase)) candidates.add(phrase);
      }
    }
    return candidates.toList();
  }

  bool _isValidWord(String word) {
    if (word.length < 3) return false;
    if (_stopWords.contains(word)) return false;
    if (RegExp(r'^\d+$').hasMatch(word)) return false;
    return true;
  }

  bool _isValidPhrase(String phrase) {
    final words = phrase.split(' ');
    if (words.length < 2 || words.length > 4) return false;
    if (words.every(_stopWords.contains)) return false;
    if (phrase.length < 6) return false;
    return true;
  }

  double _computeConfidence({
    required String candidate,
    required int usageCount,
    required int sessionCount,
  }) {
    var score = 0.0;
    score += (usageCount * 0.08).clamp(0.0, 0.4);
    score += (sessionCount * 0.08).clamp(0.0, 0.3);
    if (candidate.startsWith('my ')) score += 0.2;
    if (candidate.contains('email') ||
        candidate.contains('linkedin') ||
        candidate.contains('phone') ||
        candidate.contains('github')) {
      score += 0.15;
    }
    if (_stopWords.contains(candidate)) score -= 0.2;
    if (candidate.length > 28) score -= 0.1;
    return score.clamp(0.0, 1.0);
  }

  List<String> _reasonsForCandidate(String candidate, double confidence) {
    final reasons = <String>[];
    if (candidate.startsWith('my ')) reasons.add('pattern');
    if (confidence >= 0.7) reasons.add('frequent');
    if (confidence >= 0.9) reasons.add('confirmed');
    return reasons.isEmpty ? const ['auto'] : reasons;
  }
}

class _AutoCorrection {
  const _AutoCorrection({
    required this.replacement,
    required this.confidence,
    required this.reasons,
  });

  final String replacement;
  final double confidence;
  final List<String> reasons;
}

String _normalize(String value) =>
    value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

String _normalizeSentence(String value) => value
    .toLowerCase()
    .replaceAll(RegExp(r'[\r\n]+'), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

int _levenshtein(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;

  final costs = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 1; i <= a.length; i++) {
    var previous = i - 1;
    costs[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final temp = costs[j];
      final substitution = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
      costs[j] = [
        costs[j] + 1,
        costs[j - 1] + 1,
        previous + substitution,
      ].reduce((x, y) => x < y ? x : y);
      previous = temp;
    }
  }
  return costs[b.length];
}

const _stopWords = <String>{
  'a',
  'an',
  'and',
  'are',
  'as',
  'at',
  'be',
  'but',
  'by',
  'for',
  'from',
  'i',
  'if',
  'in',
  'is',
  'it',
  'me',
  'myself',
  'of',
  'on',
  'or',
  'so',
  'the',
  'to',
  'we',
  'with',
  'you',
  'your',
};
