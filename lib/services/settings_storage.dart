import 'package:shared_preferences/shared_preferences.dart';

const _geminiApiKeyKey = 'gemini_api_key';

/// Loads the stored Gemini API key.
Future<String?> loadGeminiApiKey() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_geminiApiKeyKey);
  } catch (_) {
    return null;
  }
}

/// Saves the Gemini API key.
Future<void> saveGeminiApiKey(String key) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_geminiApiKeyKey, key.trim());
  } catch (_) {
    // Silently ignore
  }
}
