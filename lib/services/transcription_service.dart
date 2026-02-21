import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Service that transcribes audio files using the Gemini API.
/// Uses the Files API for reliable audio processing.
class TranscriptionService {
  static const _uploadUrl =
      'https://generativelanguage.googleapis.com/upload/v1beta/files';
  static const _generateUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-lite-latest:generateContent';

  /// Extensive prompt to get a cleaned-up transcription from spoken audio.
  static const _transcriptionPrompt = '''
You are a transcription assistant. Listen to the audio and produce a cleaned-up, readable transcription.

Rules:
1. Transcribe everything that was said accurately.
2. Remove filler words and verbal tics (um, uh, like, you know, I mean, sort of, kind of, etc.) unless they are clearly meaningful.
3. Fix obvious grammar mistakes and run-on sentences. Use proper punctuation and capitalization.
4. Do not add any commentary, headers, footers, or extra text. Output ONLY the cleaned transcription.
5. If the audio is silent or inaudible, output an empty string.
6. Keep the speaker's intended meaning and tone; only clean up the delivery for readability.
''';

  /// Transcribes an audio file using the Gemini API (Files API + generateContent).
  /// Returns the transcription text, or null on error.
  Future<String?> transcribe(String filePath, String? apiKey) async {
    if (apiKey == null || apiKey.trim().isEmpty) {
      debugPrint('[Transcription] No API key provided');
      return null;
    }

    final file = File(filePath);
    if (!await file.exists()) {
      debugPrint('[Transcription] File not found: $filePath');
      return null;
    }

    final key = apiKey.trim();

    try {
      // Step 1: Upload file via Files API (multipart)
      final localFileName = filePath.split(RegExp(r'[/\\]')).last;
      final uploadUri = Uri.parse(
        '$_uploadUrl?uploadType=multipart&key=$key',
      );

      final request = http.MultipartRequest('POST', uploadUri);
      request.fields['metadata'] = jsonEncode({
        'file': {'display_name': localFileName},
      });
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          filePath,
          filename: localFileName,
        ),
      );

      debugPrint('[Transcription] Uploading ${await file.length()} bytes');

      final uploadResponse = await http.Response.fromStream(
        await request.send(),
      );

      if (uploadResponse.statusCode != 200) {
        debugPrint(
          '[Transcription] Upload error ${uploadResponse.statusCode}: '
          '${uploadResponse.body}',
        );
        return null;
      }

      final fileJson = jsonDecode(uploadResponse.body) as Map<String, dynamic>;
      final fileData = fileJson['file'] as Map<String, dynamic>?;
      final apiFileName = fileData?['name'] as String?;
      final fileUri = fileData?['uri'] as String?;
      final mimeType = fileData?['mimeType'] as String? ?? 'audio/mp4';

      if (fileUri == null || fileUri.isEmpty || apiFileName == null) {
        debugPrint('[Transcription] No file URI in upload response: $fileJson');
        return null;
      }

      // Poll until file is ACTIVE (required for audio)
      String? state = fileData?['state'] as String?;
      var attempts = 0;
      while (state == 'PROCESSING' && attempts < 30) {
        await Future<void>.delayed(const Duration(seconds: 1));
        final getUri = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/$apiFileName?key=$key',
        );
        final getResponse = await http.get(getUri);
        if (getResponse.statusCode == 200) {
          final getJson = jsonDecode(getResponse.body) as Map<String, dynamic>;
          state = getJson['state'] as String?;
        }
        attempts++;
      }
      if (state != 'ACTIVE') {
        debugPrint('[Transcription] File not ready, state: $state');
        return null;
      }

      debugPrint('[Transcription] File ready, calling generateContent');

      // Step 2: Call generateContent with file reference
      final generateUri = Uri.parse('$_generateUrl?key=$key');
      final body = {
        'contents': [
          {
            'parts': [
              {
                'fileData': {
                  'mimeType': mimeType,
                  'fileUri': fileUri,
                },
              },
              {
                'text': _transcriptionPrompt,
              },
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.1,
          'maxOutputTokens': 2048,
          'responseMimeType': 'text/plain',
        },
      };

      final genResponse = await http.post(
        generateUri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (genResponse.statusCode != 200) {
        debugPrint(
          '[Transcription] Generate error ${genResponse.statusCode}: '
          '${genResponse.body}',
        );
        return null;
      }

      final json = jsonDecode(genResponse.body) as Map<String, dynamic>;

      final promptFeedback = json['promptFeedback'] as Map<String, dynamic>?;
      if (promptFeedback != null) {
        final blockReason = promptFeedback['blockReason'] as String?;
        if (blockReason != null) {
          debugPrint('[Transcription] Blocked: $blockReason');
          return null;
        }
      }

      final candidates = json['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        debugPrint('[Transcription] No candidates in response: $json');
        return null;
      }

      final content = candidates.first['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List<dynamic>?;
      if (parts == null || parts.isEmpty) {
        debugPrint('[Transcription] No parts in candidate: $content');
        return null;
      }

      final text = parts.first['text'] as String?;
      final result = text?.trim();
      if (result == null || result.isEmpty) {
        debugPrint('[Transcription] Empty transcription returned');
        return null;
      }

      debugPrint('[Transcription] Success: ${result.length} chars');
      return result;
    } catch (e, stack) {
      debugPrint('[Transcription] Error: $e');
      debugPrint('[Transcription] Stack: $stack');
      return null;
    }
  }
}
