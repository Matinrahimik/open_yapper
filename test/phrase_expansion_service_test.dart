import 'package:flutter_test/flutter_test.dart';
import 'package:open_yapper/services/dictionary_service.dart';
import 'package:open_yapper/services/phrase_expansion_service.dart';
import 'package:open_yapper/services/user_profile_service.dart';

void main() {
  group('PhraseExpansionService', () {
    test('replaces profile aliases case-insensitively', () {
      const profile = UserProfile(email: 'me@example.com');
      const text = 'Please send MY EMAIL right now.';

      final result = PhraseExpansionService.expandText(
        text: text,
        profile: profile,
        dictionaryEntries: const [],
        enabled: true,
      );

      expect(result, 'Please send me@example.com right now.');
    });

    test('manual corrections have highest priority and longest match wins', () {
      const profile = UserProfile(email: 'me@example.com');
      final dictionaryEntries = [
        DictionaryEntry(
          id: '1',
          phrase: 'my email',
          replacement: 'email-short',
          source: DictionaryEntrySource.manual,
          enabled: true,
          usageCount: 1,
          sessionCount: 1,
          confidence: 1,
          reasons: const ['manual'],
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
          lastSeenAt: null,
        ),
        DictionaryEntry(
          id: '2',
          phrase: 'email',
          replacement: 'email-token',
          source: DictionaryEntrySource.manual,
          enabled: true,
          usageCount: 1,
          sessionCount: 1,
          confidence: 1,
          reasons: const ['manual'],
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
          lastSeenAt: null,
        ),
      ];

      final result = PhraseExpansionService.expandText(
        text: 'Use my email for contact.',
        profile: profile,
        dictionaryEntries: dictionaryEntries,
        enabled: true,
      );

      expect(result, 'Use email-short for contact.');
    });

    test('manual corrections are case-insensitive', () {
      const profile = UserProfile.empty;
      final dictionaryEntries = [
        DictionaryEntry(
          id: '3',
          phrase: 'open yapper',
          replacement: 'Open Yapper',
          source: DictionaryEntrySource.manual,
          enabled: true,
          usageCount: 1,
          sessionCount: 1,
          confidence: 1,
          reasons: const ['manual'],
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
          lastSeenAt: null,
        ),
      ];

      final result = PhraseExpansionService.expandText(
        text: 'I use OPEN YAPPER daily.',
        profile: profile,
        dictionaryEntries: dictionaryEntries,
        enabled: true,
      );

      expect(result, 'I use Open Yapper daily.');
    });

    test('does not replace partial word matches', () {
      const profile = UserProfile(email: 'me@example.com');

      final result = PhraseExpansionService.expandText(
        text: 'This is my emailing workflow.',
        profile: profile,
        dictionaryEntries: const [],
        enabled: true,
      );

      expect(result, 'This is my emailing workflow.');
    });

    test('matches phrase corrections across variable whitespace', () {
      const profile = UserProfile.empty;
      final dictionaryEntries = [
        DictionaryEntry(
          id: '4',
          phrase: 'my phone number',
          replacement: '+1 555 0101',
          source: DictionaryEntrySource.manual,
          enabled: true,
          usageCount: 1,
          sessionCount: 1,
          confidence: 1,
          reasons: const ['manual'],
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
          lastSeenAt: null,
        ),
      ];

      final result = PhraseExpansionService.expandText(
        text: 'Please use my   phone\nnumber for this.',
        profile: profile,
        dictionaryEntries: dictionaryEntries,
        enabled: true,
      );

      expect(result, 'Please use +1 555 0101 for this.');
    });
  });
}
