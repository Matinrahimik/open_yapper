import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:characters/characters.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'gemini_service.dart';
import 'native_bridge.dart';
import 'phrase_expansion_service.dart';
import 'prompt_builder.dart';
import 'dictionary_service.dart';
import 'recording_history_service.dart';
import 'settings_storage.dart';
import 'user_profile_service.dart';

/// Service that manages voice recording, Gemini processing, and paste.
class RecordingService extends ChangeNotifier {
  RecordingService({
    RecordingHistoryService? historyService,
    DictionaryService? dictionaryService,
    UserProfileService? userProfileService,
    Future<String?> Function()? loadApiKey,
    Future<String> Function()? loadModel,
  }) : _historyService = historyService,
       _dictionaryService = dictionaryService,
       _userProfileService = userProfileService,
       _loadApiKey = loadApiKey ?? (() async => null),
       _loadModel = loadModel ?? (() async => defaultGeminiModel) {
    _init();
  }

  final RecordingHistoryService? _historyService;
  final DictionaryService? _dictionaryService;
  final UserProfileService? _userProfileService;
  final Future<String?> Function() _loadApiKey;
  final Future<String> Function() _loadModel;

  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  final _native = NativeBridge.instance;

  bool _hasPermission = false;
  bool _accessibilityGranted = false;
  bool _isRecording = false;
  bool _isProcessing = false;
  int _processingGeneration = 0;
  bool _isPasteSuccess = false;
  bool _isPlaying = false;
  String? _recordedFilePath;
  String? _initError;
  String? _lastError;
  RecordingEntry? _latestEntry;
  double _recordingDuration = 0;
  double _currentAudioLevel = 0;

  Timer? _durationTimer;
  StreamSubscription<Amplitude>? _amplitudeSub;

  bool get hasPermission => _hasPermission;
  bool get accessibilityGranted => _accessibilityGranted;
  bool get isRecording => _isRecording;
  bool get isProcessing => _isProcessing;
  bool get isPasteSuccess => _isPasteSuccess;
  bool get isPlaying => _isPlaying;
  String? get recordedFilePath => _recordedFilePath;
  String? get initError => _initError;
  String? get lastError => _lastError;
  bool get hasRecording =>
      _recordedFilePath != null && File(_recordedFilePath!).existsSync();
  RecordingEntry? get latestEntry => _latestEntry;
  double get recordingDuration => _recordingDuration;
  double get currentAudioLevel => _currentAudioLevel;
  bool get allPermissionsGranted => _hasPermission && _accessibilityGranted;

  String get statusText {
    if (_isRecording) return 'Recording...';
    if (_isProcessing) return 'Processing with Gemini...';
    if (_isPasteSuccess) return 'Pasted successfully!';
    if (_lastError != null) return 'Error — see details below';
    return 'Ready — Press ⌥ Space to record';
  }

  Future<void> _init() async {
    try {
      _hasPermission = await _recorder.hasPermission();
      if (!_hasPermission) {
        _initError = 'Microphone permission denied';
      }
      _accessibilityGranted = await _native.checkAccessibility();
      _player.onPlayerComplete.listen((_) {
        _isPlaying = false;
        notifyListeners();
      });
      await _native.setStopHotkeyEnabled(false);
    } catch (e) {
      _initError = e.toString();
    }
    notifyListeners();
  }

  Future<void> checkPermissions() async {
    // Use recorder package status for passive checks to avoid re-triggering prompts.
    _hasPermission = await _recorder.hasPermission();
    _accessibilityGranted = await _native.checkAccessibility();
    notifyListeners();
  }

  Future<void> requestAccessibility() async {
    await _native.requestAccessibility();
    Timer.periodic(const Duration(seconds: 2), (timer) async {
      final granted = await _native.checkAccessibility();
      if (granted) {
        _accessibilityGranted = true;
        timer.cancel();
        notifyListeners();
      }
    });
  }

  Future<void> startRecording() async {
    if (!_hasPermission || _isRecording || _isProcessing) return;

    final apiKey = await _loadApiKey();
    if (apiKey == null || apiKey.trim().isEmpty) {
      _lastError = 'Please set your Gemini API key in Settings.';
      notifyListeners();
      return;
    }

    if (!_accessibilityGranted) {
      _lastError = 'Please grant Accessibility permission first.';
      notifyListeners();
      return;
    }

    try {
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/openyapper_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          sampleRate: 16000,
          numChannels: 1,
          bitRate: 64000,
        ),
        path: path,
      );

      _isRecording = true;
      _isPasteSuccess = false;
      _lastError = null;
      _recordedFilePath = null;
      _recordingDuration = 0;
      _currentAudioLevel = 0;
      await _native.setStopHotkeyEnabled(true);

      _amplitudeSub = _recorder
          .onAmplitudeChanged(const Duration(milliseconds: 50))
          .listen((amp) {
            final normalized = ((amp.current + 50) / 50).clamp(0.0, 1.0);
            _currentAudioLevel = normalized;
            _native.updateOverlayLevel(normalized);
            notifyListeners();
          });

      _durationTimer = Timer.periodic(const Duration(milliseconds: 100), (t) {
        _recordingDuration += 0.1;
        _native.updateOverlayDuration(_recordingDuration);
        notifyListeners();
      });

      await _native.showRecordingOverlay();
      notifyListeners();
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
    }
  }

  Future<void> stopRecording() async {
    if (!_isRecording) return;

    _durationTimer?.cancel();
    _amplitudeSub?.cancel();

    if (_recordingDuration < 0.5) {
      final path = await _recorder.stop();
      _isRecording = false;
      await _native.setStopHotkeyEnabled(false);
      await _native.dismissRecordingOverlay();
      if (path != null) {
        try {
          await File(path).delete();
        } catch (_) {}
      }
      notifyListeners();
      return;
    }

    final path = await _recorder.stop();
    final duration = _recordingDuration;
    final processingGeneration = ++_processingGeneration;
    _isRecording = false;
    await _native.setStopHotkeyEnabled(false);
    _isProcessing = true;
    notifyListeners();

    await _native.updateOverlayState('processing');

    final targetApp = await _native.getFrontmostAppName();
    final appKey = targetApp ?? 'Default';
    final tone = await loadAppTone(appKey);
    final customPrompt = await loadAppPrompt(appKey);
    final genZ = await loadGenZEnabled();
    final systemPrompt = PromptBuilder.build(
      tone: tone,
      targetApp: targetApp,
      customPrompt: customPrompt,
      genZ: genZ,
    );
    final model = await _loadModel();
    final apiKey = await _loadApiKey();

    if (path == null || apiKey == null || apiKey.trim().isEmpty) {
      _isProcessing = false;
      _lastError = 'Recording failed or no API key.';
      await _native.dismissRecordingOverlay();
      notifyListeners();
      return;
    }

    try {
      final gemini = GeminiService(apiKey: apiKey, model: model);
      final response = await gemini.processAudio(
        audioFilePath: path,
        systemPrompt: systemPrompt,
      );
      final profile =
          await _userProfileService?.loadProfile() ?? UserProfile.empty;
      final dictionaryService = _dictionaryService;
      if (dictionaryService != null && !dictionaryService.isLoaded) {
        await dictionaryService.loadEntries();
      }
      final expansionEnabled = await loadPhraseExpansionEnabled();
      final expandedResponse = PhraseExpansionService.expandText(
        text: response,
        profile: profile,
        dictionaryEntries: dictionaryService?.entries ?? const [],
        enabled: expansionEnabled,
      );

      if (_isStaleProcessing(processingGeneration)) {
        _isProcessing = false;
        try {
          await File(path).delete();
        } catch (_) {}
        notifyListeners();
        return;
      }

      await _native.pasteText(expandedResponse, restoreClipboard: true);

      if (_isStaleProcessing(processingGeneration)) {
        _isProcessing = false;
        try {
          await File(path).delete();
        } catch (_) {}
        notifyListeners();
        return;
      }

      _isProcessing = false;
      _isPasteSuccess = true;
      notifyListeners();

      if (_historyService != null) {
        final entry = await _historyService.addTextEntry(
          response: expandedResponse,
          targetApp: targetApp,
          model: model,
          durationSeconds: duration,
        );
        if (entry != null) {
          _latestEntry = entry;
        }
      }

      if (dictionaryService != null) {
        unawaited(dictionaryService.ingestObservedText(expandedResponse));
      }

      await _native.updateOverlayState(
        'success',
        charCount: expandedResponse.characters.length,
        duration: duration,
      );

      Future.delayed(const Duration(seconds: 2), () {
        _isPasteSuccess = false;
        notifyListeners();
      });

      try {
        await File(path).delete();
      } catch (_) {}
    } catch (e) {
      if (!_isStaleProcessing(processingGeneration)) {
        _isProcessing = false;
        _lastError = e.toString();
        await _native.dismissRecordingOverlay();
      }
      try {
        await File(path).delete();
      } catch (_) {}
      notifyListeners();
    }
  }

  bool _isStaleProcessing(int generation) =>
      generation != _processingGeneration;

  /// Cancels recording or processing when the user taps the escape button.
  Future<void> cancelRecordingOrProcessing() async {
    if (_isRecording) {
      _durationTimer?.cancel();
      _amplitudeSub?.cancel();
      final path = await _recorder.stop();
      _isRecording = false;
      await _native.setStopHotkeyEnabled(false);
      _isProcessing = false;
      await _native.dismissRecordingOverlay();
      if (path != null) {
        try {
          await File(path).delete();
        } catch (_) {}
      }
      notifyListeners();
      return;
    }
    if (_isProcessing) {
      _processingGeneration++;
      await _native.dismissRecordingOverlay();
      _isProcessing = false;
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

  void clearLastError() {
    _lastError = null;
    notifyListeners();
  }

  Future<void> play() async {
    if (_isPlaying) return;

    final path = _recordedFilePath ?? _latestEntry?.filePath;
    if (path == null || !File(path).existsSync()) return;

    try {
      await _player.play(DeviceFileSource(path));
      _isPlaying = true;
      notifyListeners();
    } catch (e) {
      _initError = e.toString();
      notifyListeners();
    }
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
    _durationTimer?.cancel();
    _amplitudeSub?.cancel();
    unawaited(_recorder.dispose());
    _player.dispose();
    super.dispose();
  }
}
