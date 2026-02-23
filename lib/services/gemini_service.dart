import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'settings_storage.dart';

class GeminiService {
  GeminiService({required this.apiKey, this.model = defaultGeminiModel});

  final String apiKey;
  final String model;
  static const _baseUrl = 'https://generativelanguage.googleapis.com/v1beta';

  Future<String> processAudio({
    required String audioFilePath,
    required String systemPrompt,
  }) async {
    final audioBytes = await File(audioFilePath).readAsBytes();
    final base64Audio = base64Encode(audioBytes);

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': systemPrompt},
            {
              'inline_data': {'mime_type': 'audio/mp4', 'data': base64Audio},
            },
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.7,
        'thinkingConfig': {'thinkingBudget': 0},
      },
    });

    final response = await http
        .post(
          Uri.parse('$_baseUrl/models/$model:generateContent?key=$apiKey'),
          headers: {'Content-Type': 'application/json'},
          body: body,
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw GeminiException(
        'API error (${response.statusCode}): ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final text =
        data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
    if (text == null || text.isEmpty) {
      throw GeminiException('Gemini returned an empty response.');
    }
    return text;
  }

  Future<String> processText({
    required String transcription,
    required String systemPrompt,
  }) async {
    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': '$systemPrompt\n\nUser said: $transcription'},
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.7,
        'thinkingConfig': {'thinkingBudget': 0},
      },
    });

    final response = await http
        .post(
          Uri.parse('$_baseUrl/models/$model:generateContent?key=$apiKey'),
          headers: {'Content-Type': 'application/json'},
          body: body,
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw GeminiException(
        'API error (${response.statusCode}): ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final text =
        data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
    if (text == null || text.isEmpty) {
      throw GeminiException('Gemini returned an empty response.');
    }
    return text;
  }
}

class GeminiException implements Exception {
  GeminiException(this.message);
  final String message;
  @override
  String toString() => message;
}
