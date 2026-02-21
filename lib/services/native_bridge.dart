import 'package:flutter/services.dart';

class NativeBridge {
  static const _channel = MethodChannel('com.openyapper/native');

  static final NativeBridge instance = NativeBridge._();
  NativeBridge._();

  /// Set up the callback for when the global hotkey is pressed.
  /// The native side invokes "onHotkeyPressed" when the user presses the hotkey.
  void setHotkeyCallback(VoidCallback onPressed) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onHotkeyPressed') {
        onPressed();
      }
      return null;
    });
  }

  Future<void> startHotkeyListener() async {
    await _channel.invokeMethod('startHotkeyListener');
  }

  Future<void> stopHotkeyListener() async {
    await _channel.invokeMethod('stopHotkeyListener');
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

  Future<void> updateOverlayState(String state) async {
    await _channel.invokeMethod('updateOverlayState', {'state': state});
  }

  Future<void> updateOverlayLevel(double level) async {
    await _channel.invokeMethod('updateOverlayLevel', {'level': level});
  }

  Future<void> updateOverlayDuration(double duration) async {
    await _channel.invokeMethod('updateOverlayDuration', {'duration': duration});
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
}
