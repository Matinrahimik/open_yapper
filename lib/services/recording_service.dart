import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'recording_history_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'transcription_service.dart';

/// Service that manages voice recording and playback.
class RecordingService extends ChangeNotifier {
  RecordingService({
    RecordingHistoryService? historyService,
    TranscriptionService? transcriptionService,
    Future<String?> Function()? loadApiKey,
  })  : _historyService = historyService,
        _transcriptionService = transcriptionService ?? TranscriptionService(),
        _loadApiKey = loadApiKey ?? (() async => null) {
    _init();
  }

  final RecordingHistoryService? _historyService;
  final TranscriptionService _transcriptionService;
  final Future<String?> Function() _loadApiKey;

  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  bool _hasPermission = false;
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _recordedFilePath;
  String? _initError;
  RecordingEntry? _latestEntry;

  bool get hasPermission => _hasPermission;
  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;
  String? get recordedFilePath => _recordedFilePath;
  String? get initError => _initError;
  bool get hasRecording => _recordedFilePath != null && File(_recordedFilePath!).existsSync();
  RecordingEntry? get latestEntry => _latestEntry;

  Future<void> _init() async {
    try {
      _hasPermission = await _recorder.hasPermission();
      if (!_hasPermission) {
        _initError = 'Microphone permission denied';
      }
      _player.onPlayerComplete.listen((_) {
        _isPlaying = false;
        notifyListeners();
      });
    } catch (e) {
      _initError = e.toString();
    }
    notifyListeners();
  }

  Future<void> startRecording() async {
    if (!_hasPermission || _isRecording) return;

    try {
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );
      _isRecording = true;
      _recordedFilePath = null;
      notifyListeners();
    } catch (e) {
      _initError = e.toString();
      notifyListeners();
    }
  }

  Future<void> stopRecording() async {
    if (!_isRecording) return;

    try {
      final path = await _recorder.stop();
      _isRecording = false;
      _recordedFilePath = path;
      if (path != null && _historyService != null) {
        final entry = await _historyService.addRecording(path);
        if (entry != null) {
          _latestEntry = entry;
          unawaited(_transcribeAndUpdate(entry));
        }
      }
      notifyListeners();
    } catch (e) {
      _initError = e.toString();
      _isRecording = false;
      notifyListeners();
    }
  }

  Future<void> _transcribeAndUpdate(RecordingEntry entry) async {
    final apiKey = await _loadApiKey();
    if (apiKey == null || apiKey.trim().isEmpty) return;

    final text = await _transcriptionService.transcribe(entry.filePath, apiKey);
    if (text != null && text.isNotEmpty && _historyService != null) {
      await _historyService.updateTranscription(entry.id, text);
      _latestEntry = entry.copyWith(transcription: text);
      notifyListeners();
    }
  }

  Future<void> toggleRecording() async {
    if (_isRecording) {
      await stopRecording();
    } else {
      await startRecording();
    }
  }

  Future<void> play() async {
    if (_recordedFilePath == null || !File(_recordedFilePath!).existsSync()) return;
    if (_isPlaying) return;

    try {
      await _player.play(DeviceFileSource(_recordedFilePath!));
      _isPlaying = true;
      notifyListeners();
    } catch (e) {
      _initError = e.toString();
      notifyListeners();
    }
  }

  Future<void> pause() async {
    if (!_isPlaying) return;
    await _player.pause();
    _isPlaying = false;
    notifyListeners();
  }

  Future<void> stop() async {
    await _player.stop();
    _isPlaying = false;
    notifyListeners();
  }

  Future<void> togglePlayback() async {
    if (_isPlaying) {
      await stop();
    } else {
      await play();
    }
  }

  void clearRecording() {
    _recordedFilePath = null;
    _latestEntry = null;
    _isPlaying = false;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_recorder.dispose());
    _player.dispose();
    super.dispose();
  }
}
