import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _hotkeyStorageKey = 'record_hotkey';

/// Default: Cmd+Esc.
HotKey get defaultRecordHotKey => HotKey(
      key: LogicalKeyboardKey.escape,
      modifiers: [HotKeyModifier.meta],
      scope: HotKeyScope.system,
    );

/// Ensures the hotkey uses system scope for global registration.
HotKey _withSystemScope(HotKey hotKey) {
  return HotKey(
    key: hotKey.key,
    modifiers: hotKey.modifiers,
    scope: HotKeyScope.system,
  );
}

bool _isInvalidHotKey(KeyboardKey key) {
  if (key == PhysicalKeyboardKey.space) return true;
  // Cmd+V conflicts with paste; use Cmd+Esc instead.
  if (key == PhysicalKeyboardKey.keyV || key == LogicalKeyboardKey.keyV) {
    return true;
  }
  return false;
}

Future<HotKey> loadRecordHotKey() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_hotkeyStorageKey);
    if (jsonStr == null) return defaultRecordHotKey;

    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    final hotKey = _withSystemScope(HotKey.fromJson(map));
    // Space + system scope crashes on macOS (hotkey_manager #65). Use default instead.
    // Cmd+V conflicts with paste; use Cmd+Esc instead.
    if (_isInvalidHotKey(hotKey.key)) {
      await prefs.remove(_hotkeyStorageKey);
      return defaultRecordHotKey;
    }
    return hotKey;
  } catch (_) {
    return defaultRecordHotKey;
  }
}

Future<void> saveRecordHotKey(HotKey hotKey) async {
  try {
    // Space + system scope crashes on macOS (hotkey_manager #65). Don't save.
    // Cmd+V conflicts with paste; reject it and clear stored value so default (Cmd+Esc) is used.
    if (_isInvalidHotKey(hotKey.key)) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_hotkeyStorageKey);
      return;
    }
    final normalized = _withSystemScope(hotKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_hotkeyStorageKey, jsonEncode(normalized.toJson()));
  } catch (_) {
    // Silently ignore
  }
}
