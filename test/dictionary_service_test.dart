import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_yapper/services/dictionary_service.dart';

void main() {
  group('DictionaryService', () {
    late Directory tempDir;
    late DictionaryService service;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('open_yapper_dict_test_');
      service = DictionaryService(
        documentsDirectoryProvider: () async => tempDir,
      );
      await service.loadEntries();
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('tracks observed terms even with low confidence', () async {
      await service.ingestObservedText('quick brown fox');
      final entries = service.entries;

      expect(entries.where((e) => e.phrase == 'quick').isNotEmpty, isTrue);
      final quick = entries.firstWhere((e) => e.phrase == 'quick');
      expect(quick.usageCount, 1);
      expect(quick.confidence < 0.7, isTrue);
    });

    test('creates suggestion correction for near miss phrase', () async {
      await service.ingestObservedText('my phone');
      await service.ingestObservedText('my phone');
      await service.ingestObservedText('my phone');
      await service.ingestObservedText('my phonee');

      final miss = service.entries.firstWhere((e) => e.phrase == 'my phonee');
      expect(miss.replacement, 'my phone');
      expect(miss.isSuggestion, isTrue);
      expect(miss.enabled, isFalse);
    });
  });
}
