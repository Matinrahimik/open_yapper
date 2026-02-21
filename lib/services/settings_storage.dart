import 'package:shared_preferences/shared_preferences.dart';

import 'keychain_service.dart';

const _geminiApiKeyKey = 'gemini_api_key';
const _systemPromptKey = 'system_prompt';
const _geminiModelKey = 'gemini_model';
const _onboardingCompletedKey = 'onboarding_completed';

const _defaultSystemPrompt =
    'You are a helpful assistant. The user is dictating via voice. '
    'Respond with only the text to paste. No preamble, no markdown.';

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

/// Loads the system prompt.
Future<String> loadSystemPrompt() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_systemPromptKey) ?? _defaultSystemPrompt;
  } catch (_) {
    return _defaultSystemPrompt;
  }
}

/// Saves the system prompt.
Future<void> saveSystemPrompt(String prompt) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_systemPromptKey, prompt);
}

/// Loads the Gemini model.
Future<String> loadGeminiModel() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_geminiModelKey) ?? 'gemini-2.0-flash';
  } catch (_) {
    return 'gemini-2.0-flash';
  }
}

/// Saves the Gemini model.
Future<void> saveGeminiModel(String model) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_geminiModelKey, model);
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
