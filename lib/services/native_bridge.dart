import 'package:flutter/services.dart';

class NativeBridge {
  static const _channel = MethodChannel('com.openyapper/native');

  static final NativeBridge instance = NativeBridge._();
  NativeBridge._();

  VoidCallback? _onHotkeyStart;
  VoidCallback? _onHotkeyStop;
  VoidCallback? _onHotkeyHoldDown;
  VoidCallback? _onHotkeyHoldUp;
  VoidCallback? _onCancelRequested;

  /// Set up callbacks for global hotkeys.
  void setHotkeyCallbacks({
    required VoidCallback onStart,
    required VoidCallback onStop,
    required VoidCallback onHoldDown,
    required VoidCallback onHoldUp,
  }) {
    _onHotkeyStart = onStart;
    _onHotkeyStop = onStop;
    _onHotkeyHoldDown = onHoldDown;
    _onHotkeyHoldUp = onHoldUp;
    _installChannelHandler();
  }

  /// Set up the callback for when the user taps the escape button on the overlay.
  void setCancelCallback(VoidCallback onCancel) {
    _onCancelRequested = onCancel;
    _installChannelHandler();
  }

  void _installChannelHandler() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onHotkeyStart':
          _onHotkeyStart?.call();
          break;
        case 'onHotkeyStop':
          _onHotkeyStop?.call();
          break;
        case 'onHotkeyHoldDown':
          _onHotkeyHoldDown?.call();
          break;
        case 'onHotkeyHoldUp':
          _onHotkeyHoldUp?.call();
          break;
        case 'onCancelRequested':
          _onCancelRequested?.call();
          break;
      }
      return null;
    });
  }

  /// Apply hotkey configuration to the native listener.
  Future<void> setHotkeyConfig({
    required int startKeyCode,
    required int startFlags,
    required int stopKeyCode,
    required int stopFlags,
    required int holdKeyCode,
    required int holdFlags,
    required bool startEnabled,
    required bool stopEnabled,
    required bool holdEnabled,
  }) async {
    await _channel.invokeMethod('setHotkeyConfig', {
      'startKeyCode': startKeyCode,
      'startFlags': startFlags,
      'stopKeyCode': stopKeyCode,
      'stopFlags': stopFlags,
      'holdKeyCode': holdKeyCode,
      'holdFlags': holdFlags,
      'startEnabled': startEnabled,
      'stopEnabled': stopEnabled,
      'holdEnabled': holdEnabled,
    });
  }

  /// Capture the next key press and return keyCode and flags.
  /// Used when remapping hotkeys in settings.
  Future<Map<String, int>> captureNextHotkey() async {
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'captureNextHotkey',
    );
    if (result == null) {
      throw Exception('Failed to capture hotkey');
    }
    return {
      'keyCode': result['keyCode'] as int,
      'flags': result['flags'] as int,
    };
  }

  Future<void> startHotkeyListener() async {
    await _channel.invokeMethod('startHotkeyListener');
  }

  Future<void> stopHotkeyListener() async {
    await _channel.invokeMethod('stopHotkeyListener');
  }

  Future<void> setStopHotkeyEnabled(bool enabled) async {
    await _channel.invokeMethod('setStopHotkeyEnabled', {'enabled': enabled});
  }

  Future<void> pasteText(String text, {bool restoreClipboard = true}) async {
    await _channel.invokeMethod('pasteText', {
      'text': text,
      'restoreClipboard': restoreClipboard,
    });
  }

  Future<String?> getFrontmostAppName() async {
    return await _channel.invokeMethod<String>('getFrontmostAppName');
  }

  /// Returns list of installed apps with name and base64 PNG icon.
  /// Each map: {name: String, path: String, iconBase64: String}
  Future<List<Map<String, dynamic>>> getInstalledApps() async {
    final result = await _channel.invokeMethod<List<dynamic>>(
      'getInstalledApps',
    );
    if (result == null) return [];
    return result
        .map(
          (e) => (e as Map<dynamic, dynamic>).map(
            (k, v) => MapEntry(k.toString(), v),
          ),
        )
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
  }

  Future<bool> checkAccessibility() async {
    return await _channel.invokeMethod<bool>('checkAccessibility') ?? false;
  }

  Future<bool> requestAccessibility() async {
    return await _channel.invokeMethod<bool>('requestAccessibility') ?? false;
  }

  Future<bool> checkMicrophonePermission() async {
    return await _channel.invokeMethod<bool>('checkMicrophonePermission') ??
        false;
  }

  Future<void> openAccessibilitySettings() async {
    await _channel.invokeMethod('openAccessibilitySettings');
  }

  Future<void> openMicrophoneSettings() async {
    await _channel.invokeMethod('openMicrophoneSettings');
  }

  /// Restart the app (needed after granting Accessibility - macOS doesn't detect it until restart).
  Future<void> restartApp() async {
    await _channel.invokeMethod('restartApp');
  }

  Future<void> showRecordingOverlay() async {
    await _channel.invokeMethod('showRecordingOverlay');
  }

  Future<void> updateOverlayState(
    String state, {
    int? charCount,
    double? duration,
  }) async {
    final args = <String, dynamic>{'state': state};
    if (charCount != null) args['charCount'] = charCount;
    if (duration != null) args['duration'] = duration;
    await _channel.invokeMethod('updateOverlayState', args);
  }

  Future<void> updateOverlayLevel(double level) async {
    await _channel.invokeMethod('updateOverlayLevel', {'level': level});
  }

  Future<void> updateOverlayDuration(double duration) async {
    await _channel.invokeMethod('updateOverlayDuration', {
      'duration': duration,
    });
  }

  Future<void> dismissRecordingOverlay() async {
    await _channel.invokeMethod('dismissRecordingOverlay');
  }

  Future<void> keychainSave(String key, String value) async {
    await _channel.invokeMethod('keychainSave', {'key': key, 'value': value});
  }

  Future<String?> keychainLoad(String key) async {
    return await _channel.invokeMethod<String>('keychainLoad', {'key': key});
  }

  /// Trigger native updater UI (Sparkle on macOS).
  Future<void> checkForNativeUpdates() async {
    await _channel.invokeMethod('checkForNativeUpdates');
  }
}
