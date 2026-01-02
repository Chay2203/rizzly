import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../config/api_config.dart';

class ApiService {
  static String? _token;

  static void setToken(String token) {
    _token = token;
  }

  static String? get token => _token;

  static Map<String, String> get _authHeaders => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  static Future<Map<String, dynamic>> createUser() async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.createUser}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({}),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      if (data['token'] != null) {
        setToken(data['token']);
      }
      return data;
    } else {
      throw ApiException('Failed to create user', response.statusCode);
    }
  }

  static Future<Map<String, dynamic>> getUnansweredQuestions() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getUnansweredQuestions}'),
      headers: _authHeaders,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      throw ApiException('Unauthorized', response.statusCode);
    } else {
      throw ApiException('Failed to fetch questions', response.statusCode);
    }
  }

  static Future<Map<String, dynamic>> submitAnswer({
    required String questionId,
    required File audioFile,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.submitAnswer}');
    final request = http.MultipartRequest('POST', uri);

    request.headers['Authorization'] = 'Bearer $_token';

    request.fields['question_id'] = questionId;

    final extension = audioFile.path.split('.').last.toLowerCase();
    final mimeType = _getMimeType(extension);

    request.files.add(
      await http.MultipartFile.fromPath(
        'audio',
        audioFile.path,
        contentType: MediaType.parse(mimeType),
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      throw ApiException('Unauthorized', response.statusCode);
    } else if (response.statusCode == 404) {
      throw ApiException('Question not found', response.statusCode);
    } else {
      throw ApiException('Failed to submit answer', response.statusCode);
    }
  }

  static String _getMimeType(String extension) {
    switch (extension) {
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'webm':
        return 'audio/webm';
      case 'm4a':
        return 'audio/m4a';
      case 'ogg':
        return 'audio/ogg';
      default:
        return 'audio/mpeg';
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}
