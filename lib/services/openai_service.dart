import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_keys.dart';

class OpenAIService {
  final String apiKey = ApiKeys.openaiApiKey;
  final String baseUrl = 'https://api.openai.com/v1';

  Future<String> analyzeImageWithGPT4o(File imageFile, String prompt) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final url = Uri.parse('$baseUrl/chat/completions');

      final payload = jsonEncode({
        'model': 'gpt-4o',
        'messages': [
          {
            'role': 'system',
            'content': 'You are a helpful assistant that analyzes images and provides information in Russian language.'
          },
          {
            'role': 'user',
            'content': [
              {'type': 'text', 'text': prompt},
              {
                'type': 'image_url',
                'image_url': {
                  'url': 'data:image/jpeg;base64,$base64Image'
                }
              }
            ]
          }
        ],
        'max_tokens': 1000
      });

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: payload,
      );

      if (response.statusCode == 200) {
        final responseData = utf8.decode(response.bodyBytes);
        final jsonResponse = jsonDecode(responseData);
        return jsonResponse['choices'][0]['message']['content'];
      } else {
        throw Exception('Failed to analyze image: ${utf8.decode(response.bodyBytes)}');
      }
    } catch (e) {
      print('Error in analyzeImageWithGPT4o: $e');
      rethrow;
    }
  }

  Future<String> getChatCompletion(String prompt) async {
    try {
      final url = Uri.parse('$baseUrl/chat/completions');

      final payload = jsonEncode({
        'model': 'gpt-4o',
        'messages': [
          {
            'role': 'system',
            'content': 'You are a helpful assistant providing responses in Russian language.'
          },
          {
            'role': 'user',
            'content': prompt
          }
        ],
        'max_tokens': 2000
      });

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: payload,
      );

      if (response.statusCode == 200) {
        final responseData = utf8.decode(response.bodyBytes);
        final jsonResponse = jsonDecode(responseData);
        return jsonResponse['choices'][0]['message']['content'];
      } else {
        throw Exception('Failed to get completion: ${utf8.decode(response.bodyBytes)}');
      }
    } catch (e) {
      print('Error in getChatCompletion: $e');
      rethrow;
    }
  }
}
