import 'native_bridge.dart';

const _geminiApiKeyKey = 'gemini_api_key';

Future<String?> loadGeminiApiKeyFromKeychain() async {
  return NativeBridge.instance.keychainLoad(_geminiApiKeyKey);
}

Future<void> saveGeminiApiKeyToKeychain(String key) async {
  await NativeBridge.instance.keychainSave(_geminiApiKeyKey, key.trim());
}
