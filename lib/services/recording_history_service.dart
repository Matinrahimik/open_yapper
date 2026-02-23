import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'settings_storage.dart';

/// A single recording entry in history.
class RecordingEntry {
  const RecordingEntry({
    required this.id,
    required this.filePath,
    required this.recordedAt,
    this.durationSeconds,
    this.transcription,
    this.response,
    this.targetApp,
    this.model,
  });

  final String id;
  final String filePath;
  final DateTime recordedAt;
  final double? durationSeconds;
  final String? transcription;
  final String? response;
  final String? targetApp;
  final String? model;

  /// Primary text to display (response from Gemini, or transcription for legacy).
  String get displayText => response ?? transcription ?? '';

  Map<String, dynamic> toJson() => {
    'id': id,
    'filePath': filePath,
    'recordedAt': recordedAt.toIso8601String(),
    'durationSeconds': durationSeconds,
    'transcription': transcription,
    'response': response,
    'targetApp': targetApp,
    'model': model,
  };

  factory RecordingEntry.fromJson(Map<String, dynamic> json) {
    final transcription = json['transcription'] as String?;
    final response = json['response'] as String?;
    return RecordingEntry(
      id: json['id'] as String,
      filePath: json['filePath'] as String,
      recordedAt: DateTime.parse(json['recordedAt'] as String),
      durationSeconds: (json['durationSeconds'] as num?)?.toDouble(),
      transcription: transcription,
      response: response ?? transcription,
      targetApp: json['targetApp'] as String?,
      model: json['model'] as String? ?? defaultGeminiModel,
    );
  }

  RecordingEntry copyWith({
    String? transcription,
    String? response,
    String? targetApp,
    String? model,
    double? durationSeconds,
  }) => RecordingEntry(
    id: id,
    filePath: filePath,
    recordedAt: recordedAt,
    durationSeconds: durationSeconds ?? this.durationSeconds,
    transcription: transcription ?? this.transcription,
    response: response ?? this.response,
    targetApp: targetApp ?? this.targetApp,
    model: model ?? this.model,
  );
}

/// Service that persists and manages recording history.
class RecordingHistoryService extends ChangeNotifier {
  static const _historyFileName = 'recording_history.json';

  List<RecordingEntry> _entries = [];
  bool _loaded = false;

  List<RecordingEntry> get entries => List.unmodifiable(_entries);
  bool get isLoaded => _loaded;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    await _load();
  }

  Future<void> _load() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final historyDir = Directory('${dir.path}/open_yapper_recordings');
      if (!await historyDir.exists()) {
        await historyDir.create(recursive: true);
      }
      final file = File('${historyDir.path}/$_historyFileName');
      if (await file.exists()) {
        final content = await file.readAsString();
        final list = jsonDecode(content) as List<dynamic>;
        _entries =
            list
                .map((e) => RecordingEntry.fromJson(e as Map<String, dynamic>))
                .where(
                  (e) => e.filePath.isEmpty || File(e.filePath).existsSync(),
                )
                .toList()
              ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
      } else {
        _entries = [];
      }
    } catch (e) {
      _entries = [];
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final historyDir = Directory('${dir.path}/open_yapper_recordings');
      if (!await historyDir.exists()) {
        await historyDir.create(recursive: true);
      }
      final file = File('${historyDir.path}/$_historyFileName');
      final list = _entries.map((e) => e.toJson()).toList();
      await file.writeAsString(jsonEncode(list));
    } catch (_) {}
    notifyListeners();
  }

  /// Adds a text-only entry to history (no voice recording file is saved).
  Future<RecordingEntry?> addTextEntry({
    required String response,
    String? targetApp,
    required String model,
    double? durationSeconds,
  }) async {
    try {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final entry = RecordingEntry(
        id: id,
        filePath: '',
        recordedAt: DateTime.now(),
        durationSeconds: durationSeconds,
        response: response,
        targetApp: targetApp,
        model: model,
      );

      await _ensureLoaded();
      _entries.insert(0, entry);
      await _save();
      return entry;
    } catch (_) {
      return null;
    }
  }

  /// Loads history entries (call before displaying).
  Future<List<RecordingEntry>> loadEntries() async {
    await _ensureLoaded();
    return entries;
  }

  /// Updates the transcription for an existing entry.
  Future<void> updateTranscription(String id, String transcription) async {
    await _ensureLoaded();
    final index = _entries.indexWhere((e) => e.id == id);
    if (index < 0) return;
    _entries[index] = _entries[index].copyWith(transcription: transcription);
    await _save();
  }

  /// Updates an entry with Gemini response, target app, and model.
  Future<void> updateEntryResponse({
    required String id,
    required String response,
    String? targetApp,
    required String model,
  }) async {
    await _ensureLoaded();
    final index = _entries.indexWhere((e) => e.id == id);
    if (index < 0) return;
    _entries[index] = _entries[index].copyWith(
      response: response,
      targetApp: targetApp,
      model: model,
    );
    await _save();
  }

  /// Clears all history and deletes any recording files (text-only entries have no file).
  Future<void> clearHistory() async {
    await _ensureLoaded();
    for (final entry in _entries) {
      if (entry.filePath.isEmpty) continue;
      try {
        final file = File(entry.filePath);
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
    _entries.clear();
    await _save();
  }

  /// Removes an entry from history and deletes its file if one exists.
  Future<void> removeRecording(String id) async {
    await _ensureLoaded();
    final index = _entries.indexWhere((e) => e.id == id);
    if (index < 0) return;
    final entry = _entries[index];
    _entries.removeAt(index);
    if (entry.filePath.isNotEmpty) {
      try {
        final file = File(entry.filePath);
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
    await _save();
  }
}
