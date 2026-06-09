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
}
