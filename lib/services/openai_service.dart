import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenAIService {
  static const _baseUrl = 'https://api.openai.com/v1/chat/completions';
  static const _model = 'gpt-4.1';

  final String apiKey;

  OpenAIService({required this.apiKey});

  Stream<String> streamMessage({
    required List<Map<String, dynamic>> messages,
    required String systemPrompt,
  }) async* {
    final request = http.Request('POST', Uri.parse(_baseUrl))
      ..headers.addAll({
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      })
      ..body = jsonEncode({
        'model': _model,
        'stream': true,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          ...messages,
        ],
      });

    final response = await http.Client().send(request);

    if (response.statusCode != 200) {
      final body = await response.stream.bytesToString();
      throw Exception('OpenAI error ${response.statusCode}: $body');
    }

    // Buffer incomplete lines across chunks — this prevents cut-off words
    var remainder = '';

    await for (final chunk in response.stream.transform(utf8.decoder)) {
      final lines = (remainder + chunk).split('\n');
      // The last element may be an incomplete line — keep it for the next chunk
      remainder = lines.removeLast();

      for (final line in lines) {
        final trimmed = line.trim();
        if (!trimmed.startsWith('data: ')) continue;
        final data = trimmed.substring(6).trim();
        if (data == '[DONE]') return;

        try {
          final json = jsonDecode(data) as Map<String, dynamic>;
          final delta =
              ((json['choices'] as List).first as Map)['delta']['content']
                  as String?;
          if (delta != null && delta.isNotEmpty) yield delta;
        } catch (_) {
          // truly incomplete JSON — skip silently
        }
      }
    }
  }
}
