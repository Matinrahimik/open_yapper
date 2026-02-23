import 'package:shared_preferences/shared_preferences.dart';

import 'keychain_service.dart';
import 'prompt_builder.dart';

const _geminiApiKeyKey = 'gemini_api_key';
const _geminiModelKey = 'gemini_model';
const _onboardingCompletedKey = 'onboarding_completed';
const _genZEnabledKey = 'gen_z_enabled';
const _appTonePrefix = 'app_tone_';
const _appPromptPrefix = 'app_prompt_';
const _hotkeyStartKeyCodeKey = 'hotkey_start_keycode';
const _hotkeyStartFlagsKey = 'hotkey_start_flags';
const _hotkeyStopKeyCodeKey = 'hotkey_stop_keycode';
const _hotkeyStopFlagsKey = 'hotkey_stop_flags';
const _hotkeyHoldKeyCodeKey = 'hotkey_hold_keycode';
const _hotkeyHoldFlagsKey = 'hotkey_hold_flags';
const _hotkeyStartEnabledKey = 'hotkey_start_enabled';
const _hotkeyStopEnabledKey = 'hotkey_stop_enabled';
const _hotkeyHoldEnabledKey = 'hotkey_hold_enabled';
const _phraseExpansionEnabledKey = 'phrase_expansion_enabled';
const _dismissedUpdateVersionKey = 'dismissed_update_version';

const geminiFlashLatestModel = 'gemini-flash-latest';
const geminiFlashLiteLatestModel = 'gemini-flash-lite-latest';
const defaultGeminiModel = geminiFlashLiteLatestModel;
const supportedGeminiModels = <String>{
  geminiFlashLatestModel,
  geminiFlashLiteLatestModel,
};

/// Hotkey configuration for global shortcuts.
class HotkeyConfig {
  const HotkeyConfig({
    required this.startKeyCode,
    required this.startFlags,
    required this.stopKeyCode,
    required this.stopFlags,
    required this.holdKeyCode,
    required this.holdFlags,
    required this.startEnabled,
    required this.stopEnabled,
    required this.holdEnabled,
  });

  final int startKeyCode;
  final int startFlags;
  final int stopKeyCode;
  final int stopFlags;
  final int holdKeyCode;
  final int holdFlags;
  final bool startEnabled;
  final bool stopEnabled;
  final bool holdEnabled;

  static const HotkeyConfig defaultConfig = HotkeyConfig(
    startKeyCode: 49, // kVK_Space
    startFlags: 0x80000, // maskAlternate (Option)
    stopKeyCode: 36, // kVK_Return
    stopFlags: 0x80000, // maskAlternate (Option)
    holdKeyCode: 49, // kVK_Space
    holdFlags: 0x40000, // maskControl (Control) - avoids Cmd+Space (Spotlight)
    startEnabled: true,
    stopEnabled: true,
    holdEnabled: true,
  );
}

/// Loads the stored Gemini API key (Keychain first, with migration from SharedPreferences).
Future<String?> loadGeminiApiKey() async {
  try {
    var key = await loadGeminiApiKeyFromKeychain();
    if (key != null && key.isNotEmpty) return key;

    final prefs = await SharedPreferences.getInstance();
    key = prefs.getString(_geminiApiKeyKey);
    if (key != null && key.isNotEmpty) {
      await saveGeminiApiKeyToKeychain(key);
      await prefs.remove(_geminiApiKeyKey);
      return key;
    }
    return null;
  } catch (_) {
    return null;
  }
}

/// Saves the Gemini API key to Keychain.
Future<void> saveGeminiApiKey(String key) async {
  await saveGeminiApiKeyToKeychain(key);
}

/// Loads the selected Gemini model, defaulting to flash-lite when unset.
Future<String> loadGeminiModel() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final model = prefs.getString(_geminiModelKey);
    if (model != null && supportedGeminiModels.contains(model)) {
      return model;
    }
    return defaultGeminiModel;
  } catch (_) {
    return defaultGeminiModel;
  }
}

/// Saves the selected Gemini model.
Future<void> saveGeminiModel(String model) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final safeModel = supportedGeminiModels.contains(model)
        ? model
        : defaultGeminiModel;
    await prefs.setString(_geminiModelKey, safeModel);
  } catch (_) {}
}

/// Loads the tone for a specific app. Returns default when not configured.
Future<String> loadAppTone(String appName) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_appTonePrefix$appName';
    final tone = prefs.getString(key);
    if (tone != null && PromptBuilder.validTones.contains(tone)) {
      return tone;
    }
    return PromptBuilder.validTones[1]; // 'normal'
  } catch (_) {
    return PromptBuilder.validTones[1];
  }
}

/// Saves the tone for a specific app.
Future<void> saveAppTone(String appName, String tone) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_appTonePrefix$appName';
    await prefs.setString(key, tone);
  } catch (_) {}
}

/// Loads the custom prompt for a specific app. Returns null when not set.
Future<String?> loadAppPrompt(String appName) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_appPromptPrefix$appName');
  } catch (_) {
    return null;
  }
}

/// Saves the custom prompt for a specific app.
Future<void> saveAppPrompt(String appName, String? prompt) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_appPromptPrefix$appName';
    if (prompt == null || prompt.isEmpty) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, prompt);
    }
  } catch (_) {}
}

/// Loads all app prompt overrides for the Customization UI.
Future<Map<String, String>> loadAllAppPrompts() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_appPromptPrefix));
    final map = <String, String>{};
    for (final k in keys) {
      final appName = k.substring(_appPromptPrefix.length);
      final prompt = prefs.getString(k);
      if (prompt != null && prompt.isNotEmpty) {
        map[appName] = prompt;
      }
    }
    return map;
  } catch (_) {
    return {};
  }
}

/// Loads all app tone overrides for the Customization UI.
Future<Map<String, String>> loadAllAppTones() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_appTonePrefix));
    final map = <String, String>{};
    for (final k in keys) {
      final appName = k.substring(_appTonePrefix.length);
      final tone = prefs.getString(k);
      if (tone != null && PromptBuilder.validTones.contains(tone)) {
        map[appName] = tone;
      }
    }
    return map;
  } catch (_) {
    return {};
  }
}

/// Whether onboarding (permissions screen) has been completed.
Future<bool> getOnboardingCompleted() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingCompletedKey) ?? false;
  } catch (_) {
    return false;
  }
}

/// Mark onboarding as completed (both permissions granted).
Future<void> setOnboardingCompleted(bool value) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompletedKey, value);
  } catch (_) {}
}

/// Whether Gen Z mode is enabled (rewrites output in Gen Z style).
Future<bool> loadGenZEnabled() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_genZEnabledKey) ?? false;
  } catch (_) {
    return false;
  }
}

/// Saves the Gen Z mode setting.
Future<void> saveGenZEnabled(bool value) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_genZEnabledKey, value);
  } catch (_) {}
}

/// Whether phrase expansion is enabled (aliases and dictionary corrections).
Future<bool> loadPhraseExpansionEnabled() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_phraseExpansionEnabledKey) ?? true;
  } catch (_) {
    return true;
  }
}

/// Saves phrase expansion toggle.
Future<void> savePhraseExpansionEnabled(bool value) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_phraseExpansionEnabledKey, value);
  } catch (_) {}
}

/// Version string of the last update prompt dismissed with "Later".
Future<String?> loadDismissedUpdateVersion() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_dismissedUpdateVersionKey);
  } catch (_) {
    return null;
  }
}

/// Stores or clears the last dismissed update version.
Future<void> saveDismissedUpdateVersion(String? version) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    if (version == null || version.isEmpty) {
      await prefs.remove(_dismissedUpdateVersionKey);
    } else {
      await prefs.setString(_dismissedUpdateVersionKey, version);
    }
  } catch (_) {}
}

/// Loads the stored hotkey configuration.
Future<HotkeyConfig> loadHotkeyConfig() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final startKeyCode = prefs.getInt(_hotkeyStartKeyCodeKey);
    final startFlags = prefs.getInt(_hotkeyStartFlagsKey);
    final stopKeyCode = prefs.getInt(_hotkeyStopKeyCodeKey);
    final stopFlags = prefs.getInt(_hotkeyStopFlagsKey);
    final holdKeyCode = prefs.getInt(_hotkeyHoldKeyCodeKey);
    final holdFlags = prefs.getInt(_hotkeyHoldFlagsKey);
    final startEnabled = prefs.getBool(_hotkeyStartEnabledKey) ?? true;
    final stopEnabled = prefs.getBool(_hotkeyStopEnabledKey) ?? true;
    final holdEnabled = prefs.getBool(_hotkeyHoldEnabledKey) ?? true;

    if (startKeyCode != null &&
        startFlags != null &&
        stopKeyCode != null &&
        stopFlags != null &&
        holdKeyCode != null &&
        holdFlags != null) {
      return HotkeyConfig(
        startKeyCode: startKeyCode,
        startFlags: startFlags,
        stopKeyCode: stopKeyCode,
        stopFlags: stopFlags,
        holdKeyCode: holdKeyCode,
        holdFlags: holdFlags,
        startEnabled: startEnabled,
        stopEnabled: stopEnabled,
        holdEnabled: holdEnabled,
      );
    }
  } catch (_) {}
  return HotkeyConfig.defaultConfig;
}

/// Saves the hotkey configuration.
Future<void> saveHotkeyConfig(HotkeyConfig config) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_hotkeyStartKeyCodeKey, config.startKeyCode);
    await prefs.setInt(_hotkeyStartFlagsKey, config.startFlags);
    await prefs.setInt(_hotkeyStopKeyCodeKey, config.stopKeyCode);
    await prefs.setInt(_hotkeyStopFlagsKey, config.stopFlags);
    await prefs.setInt(_hotkeyHoldKeyCodeKey, config.holdKeyCode);
    await prefs.setInt(_hotkeyHoldFlagsKey, config.holdFlags);
    await prefs.setBool(_hotkeyStartEnabledKey, config.startEnabled);
    await prefs.setBool(_hotkeyStopEnabledKey, config.stopEnabled);
    await prefs.setBool(_hotkeyHoldEnabledKey, config.holdEnabled);
  } catch (_) {}
}
