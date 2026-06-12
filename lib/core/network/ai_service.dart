import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  String _apiKey = '';
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = 'llama-3.3-70b-versatile';

  String get apiKey => _apiKey;

  Future<void> loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString('groq_api_key') ?? '';
  }

  Future<void> saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('groq_api_key', key);
    _apiKey = key;
  }

  Future<String> query(String prompt, {String? systemPrompt}) async {
    if (_apiKey.isEmpty) {
      return 'Please configure your AI API key in settings. Get a free key at console.groq.com';
    }

    try {
      final messages = <Map<String, dynamic>>[];
      if (systemPrompt != null) {
        messages.add({'role': 'system', 'content': systemPrompt});
      }
      messages.add({'role': 'user', 'content': prompt});

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _model,
          'messages': messages,
          'max_tokens': 1024,
          'temperature': 0.7,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['choices'][0]['message']['content'] as String;
      }

      try {
        final err = jsonDecode(response.body) as Map<String, dynamic>;
        final msg = err['error']?['message'] ?? 'Unknown error';
        return 'AI Error (${response.statusCode}): $msg';
      } catch (_) {
        return 'AI Error: HTTP ${response.statusCode}';
      }
    } catch (e) {
      return 'Network error: Please check your connection and try again.';
    }
  }

  Stream<String> queryStream(
    List<Map<String, String>> conversationHistory, {
    String? systemPrompt,
  }) async* {
    if (_apiKey.isEmpty) {
      yield 'Please configure your Groq API key to use this feature. Get a free key at console.groq.com';
      return;
    }

    final allMessages = <Map<String, dynamic>>[];
    if (systemPrompt != null) {
      allMessages.add({'role': 'system', 'content': systemPrompt});
    }
    for (final m in conversationHistory) {
      allMessages.add({'role': m['role']!, 'content': m['content']!});
    }

    final client = http.Client();
    try {
      final request = http.Request('POST', Uri.parse(_baseUrl));
      request.headers['Authorization'] = 'Bearer $_apiKey';
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode({
        'model': _model,
        'messages': allMessages,
        'stream': true,
        'max_tokens': 1024,
        'temperature': 0.7,
      });

      final streamResponse = await client.send(request).timeout(const Duration(seconds: 30));

      if (streamResponse.statusCode != 200) {
        final body = await streamResponse.stream.bytesToString();
        try {
          final err = jsonDecode(body) as Map<String, dynamic>;
          final msg = err['error']?['message'] ?? body;
          yield 'AI Error (${streamResponse.statusCode}): $msg';
        } catch (_) {
          yield 'AI Error: HTTP ${streamResponse.statusCode}. Check your API key at console.groq.com';
        }
        return;
      }

      final buffer = StringBuffer();
      await for (final chunk in streamResponse.stream.transform(utf8.decoder)) {
        buffer.write(chunk);
        final raw = buffer.toString();
        final lines = raw.split('\n');
        buffer.clear();

        for (int i = 0; i < lines.length - 1; i++) {
          final line = lines[i].trim();
          if (line.startsWith('data: ') && line != 'data: [DONE]') {
            try {
              final json = jsonDecode(line.substring(6)) as Map<String, dynamic>;
              final content = json['choices']?[0]?['delta']?['content'] as String?;
              if (content != null && content.isNotEmpty) {
                yield content;
              }
            } catch (_) {}
          }
        }
        if (lines.isNotEmpty) {
          buffer.write(lines.last);
        }
      }
    } catch (e) {
      yield 'Connection error. Please check your network.';
    } finally {
      client.close();
    }
  }
}
