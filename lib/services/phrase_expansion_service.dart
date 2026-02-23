import 'dictionary_service.dart';
import 'user_profile_service.dart';

class PhraseExpansionService {
  const PhraseExpansionService._();

  static String expandText({
    required String text,
    required UserProfile profile,
    required List<DictionaryEntry> dictionaryEntries,
    required bool enabled,
  }) {
    if (!enabled || text.trim().isEmpty) return text;

    final replacements = <String, _ReplacementRule>{};
    void upsertRule({
      required String phrase,
      required String replacement,
      required int priority,
    }) {
      final normalizedPhrase = _normalizeLookupKey(phrase);
      final normalizedReplacement = replacement.trim();
      if (normalizedPhrase.isEmpty || normalizedReplacement.isEmpty) return;
      final existing = replacements[normalizedPhrase];
      if (existing == null || priority > existing.priority) {
        replacements[normalizedPhrase] = _ReplacementRule(
          replacement: normalizedReplacement,
          priority: priority,
        );
      }
    }

    // Profile aliases are applied, but manual dictionary rules can override.
    for (final entry in profile.aliasMap.entries) {
      upsertRule(phrase: entry.key, replacement: entry.value, priority: 100);
    }

    for (final entry in dictionaryEntries) {
      final phrase = entry.phrase.trim();
      final replacement = entry.replacement.trim();
      if (!entry.enabled || phrase.isEmpty || replacement.isEmpty) continue;
      if (phrase == replacement) continue;
      final priority = entry.source == DictionaryEntrySource.manual ? 300 : 200;
      upsertRule(phrase: phrase, replacement: replacement, priority: priority);
    }

    if (replacements.isEmpty) return text;

    final sortedKeys = replacements.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    final pattern = sortedKeys.map(_phrasePatternFromKey).join('|');
    if (pattern.isEmpty) return text;

    final regex = RegExp('(?<!\\w)($pattern)(?!\\w)', caseSensitive: false);

    return text.replaceAllMapped(regex, (match) {
      final matched = _normalizeLookupKey(match.group(0)!);
      return replacements[matched]?.replacement ?? match.group(0)!;
    });
  }
}

class _ReplacementRule {
  const _ReplacementRule({required this.replacement, required this.priority});

  final String replacement;
  final int priority;
}

String _normalizeLookupKey(String value) =>
    value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

String _phrasePatternFromKey(String key) => key
    .split(RegExp(r'\s+'))
    .where((token) => token.isNotEmpty)
    .map(RegExp.escape)
    .join(r'\s+');
