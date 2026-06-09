import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

  String _apiKey = '';

  String get apiKey => _apiKey;

  Future<void> loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString('google_gemini_api_key') ?? '';
  }

  Future<void> saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('google_gemini_api_key', key);
    _apiKey = key;
  }

  Future<String> queryGemini(String prompt, {String? systemInstruction}) async {
    if (_apiKey.isEmpty) {
      return '';
    }

    try {
      final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_apiKey');
      
      final Map<String, dynamic> requestBody = {
        'contents': [
          {
            'parts': [
              {
                'text': systemInstruction != null ? "$systemInstruction\n\nUser Question: $prompt" : prompt
              }
            ]
          }
        ]
      };

      final response = await http.post(
        url,
        headers: {
          'content-type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
        if (text != null && text.isNotEmpty) {
          return text;
        }
      }

      final err = jsonDecode(response.body);
      final errMsg = err['error']?['message'] ?? 'Unknown Gemini API error';
      return "Google AI Error: $errMsg (Status Code: ${response.statusCode})";
    } catch (e) {
      return "Network error connecting to Google AI: $e";
    }
  }

  Stream<String> queryGeminiStream(
    List<Map<String, dynamic>> contents, {
    String? systemInstruction,
  }) async* {
    if (_apiKey.isEmpty) {
      yield "Google AI is temporarily unavailable.";
      return;
    }

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:streamGenerateContent?key=$_apiKey',
    );

    final Map<String, dynamic> requestBody = {
      'contents': contents,
    };

    if (systemInstruction != null) {
      requestBody['systemInstruction'] = {
        'parts': [
          {'text': systemInstruction}
        ]
      };
    }

    final client = http.Client();
    try {
      final request = http.Request('POST', url);
      request.headers['content-type'] = 'application/json';
      request.body = jsonEncode(requestBody);

      final response = await client.send(request);

      if (response.statusCode != 200) {
        yield "Google AI is temporarily unavailable.";
        client.close();
        return;
      }

      StringBuffer buffer = StringBuffer();
      await for (final chunk in response.stream.transform(utf8.decoder)) {
        buffer.write(chunk);
        final str = buffer.toString();

        int braceCount = 0;
        int startIndex = -1;
        List<String> jsonObjects = [];

        for (int i = 0; i < str.length; i++) {
          if (str[i] == '{') {
            if (braceCount == 0) {
              startIndex = i;
            }
            braceCount++;
          } else if (str[i] == '}') {
            braceCount--;
            if (braceCount == 0 && startIndex != -1) {
              jsonObjects.add(str.substring(startIndex, i + 1));
              startIndex = -1;
            }
          }
        }

        if (startIndex != -1) {
          buffer.clear();
          buffer.write(str.substring(startIndex));
        } else {
          buffer.clear();
        }

        for (final jsonStr in jsonObjects) {
          try {
            final data = jsonDecode(jsonStr);
            final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
            if (text != null && text.isNotEmpty) {
              yield text;
            }
          } catch (e) {
            // Ignore incomplete chunks
          }
        }
      }
    } catch (e) {
      yield "Google AI is temporarily unavailable.";
    } finally {
      client.close();
    }
  }
}
