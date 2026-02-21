import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// A single recording entry in history.
class RecordingEntry {
  const RecordingEntry({
    required this.id,
    required this.filePath,
    required this.recordedAt,
    this.durationSeconds,
    this.transcription,
  });

  final String id;
  final String filePath;
  final DateTime recordedAt;
  final double? durationSeconds;
  final String? transcription;

  Map<String, dynamic> toJson() => {
        'id': id,
        'filePath': filePath,
        'recordedAt': recordedAt.toIso8601String(),
        'durationSeconds': durationSeconds,
        'transcription': transcription,
      };

  factory RecordingEntry.fromJson(Map<String, dynamic> json) => RecordingEntry(
        id: json['id'] as String,
        filePath: json['filePath'] as String,
        recordedAt: DateTime.parse(json['recordedAt'] as String),
        durationSeconds: (json['durationSeconds'] as num?)?.toDouble(),
        transcription: json['transcription'] as String?,
      );

  RecordingEntry copyWith({String? transcription}) => RecordingEntry(
        id: id,
        filePath: filePath,
        recordedAt: recordedAt,
        durationSeconds: durationSeconds,
        transcription: transcription ?? this.transcription,
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
        _entries = list
            .map((e) => RecordingEntry.fromJson(e as Map<String, dynamic>))
            .where((e) => File(e.filePath).existsSync())
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

  /// Adds a recording to history by copying the source file.
  Future<RecordingEntry?> addRecording(String sourcePath) async {
    final source = File(sourcePath);
    if (!await source.exists()) return null;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final historyDir = Directory('${dir.path}/open_yapper_recordings');
      if (!await historyDir.exists()) {
        await historyDir.create(recursive: true);
      }

      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final ext = sourcePath.split('.').last;
      final destPath = '${historyDir.path}/recording_$id.$ext';
      await source.copy(destPath);

      final entry = RecordingEntry(
        id: id,
        filePath: destPath,
        recordedAt: DateTime.now(),
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

  /// Removes a recording from history and deletes its file.
  Future<void> removeRecording(String id) async {
    await _ensureLoaded();
    final entry = _entries.firstWhere((e) => e.id == id);
    _entries.removeWhere((e) => e.id == id);
    try {
      final file = File(entry.filePath);
      if (await file.exists()) await file.delete();
    } catch (_) {}
    await _save();
  }
}
