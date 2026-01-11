import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../config/api_config.dart';

class ApiService {
  static String? _token;

  static void setToken(String token) {
    debugPrint('🔑 [ApiService] Setting token (length: ${token.length})');
    _token = token;
  }

  static String? get token => _token;

  static Map<String, String> get _authHeaders => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  /// Create user with Google Sign-In token
  static Future<Map<String, dynamic>> createUserWithGoogle(
    String googleIdToken,
  ) async {
    final url = '${ApiConfig.baseUrl}${ApiConfig.createUser}';
    debugPrint('🌐 [ApiService] Creating user with Google token');
    debugPrint('   URL: $url');
    debugPrint('   Token length: ${googleIdToken.length}');

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'token': googleIdToken}),
    );

    debugPrint('📡 [ApiService] Response status: ${response.statusCode}');
    debugPrint('   Response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['token'] != null) {
        setToken(data['token']);
      }
      debugPrint('✅ [ApiService] User created successfully');
      return data;
    } else if (response.statusCode == 400) {
      debugPrint('❌ [ApiService] Missing Google token (400)');
      throw ApiException('Missing Google token', response.statusCode);
    } else if (response.statusCode == 401) {
      debugPrint('❌ [ApiService] Invalid Google token (401)');
      throw ApiException('Invalid Google token', response.statusCode);
    } else {
      debugPrint(
        '❌ [ApiService] Failed to create user (${response.statusCode})',
      );
      throw ApiException('Failed to create user', response.statusCode);
    }
  }

  /// Create user with Apple Sign-In token
  static Future<Map<String, dynamic>> createUserWithApple({
    required String identityToken,
    required String authorizationCode,
    String? email,
    String? fullName,
  }) async {
    final url = '${ApiConfig.baseUrl}${ApiConfig.createUserWithApple}';
    debugPrint('🍎 [ApiService] Creating user with Apple token');
    debugPrint('   URL: $url');
    debugPrint('   Token length: ${identityToken.length}');

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'identityToken': identityToken,
        'authorizationCode': authorizationCode,
        'email': email,
        'fullName': fullName,
      }),
    );

    debugPrint('📡 [ApiService] Response status: ${response.statusCode}');
    debugPrint('   Response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['token'] != null) {
        setToken(data['token']);
      }
      debugPrint('✅ [ApiService] Apple user created successfully');
      return data;
    } else if (response.statusCode == 400) {
      debugPrint('❌ [ApiService] Missing Apple token (400)');
      throw ApiException('Missing Apple token', response.statusCode);
    } else if (response.statusCode == 401) {
      debugPrint('❌ [ApiService] Invalid Apple token (401)');
      throw ApiException('Invalid Apple token', response.statusCode);
    } else {
      debugPrint(
        '❌ [ApiService] Failed to create user (${response.statusCode})',
      );
      throw ApiException('Failed to create user', response.statusCode);
    }
  }

  /// Get current authenticated user
  static Future<Map<String, dynamic>> getCurrentUser() async {
    final url = '${ApiConfig.baseUrl}${ApiConfig.getCurrentUser}';
    debugPrint('🌐 [ApiService] Getting current user');
    debugPrint('   URL: $url');
    debugPrint('   Has token: ${_token != null}');

    final response = await http.get(Uri.parse(url), headers: _authHeaders);

    debugPrint('📡 [ApiService] Response status: ${response.statusCode}');
    debugPrint('   Response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      debugPrint('✅ [ApiService] Current user fetched successfully');
      return data;
    } else if (response.statusCode == 401) {
      debugPrint('❌ [ApiService] Unauthorized (401)');
      throw ApiException('Unauthorized', response.statusCode);
    } else {
      debugPrint(
        '❌ [ApiService] Failed to fetch user (${response.statusCode})',
      );
      throw ApiException('Failed to fetch user', response.statusCode);
    }
  }

  @Deprecated('Use createUserWithGoogle instead')
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
    final url = '${ApiConfig.baseUrl}${ApiConfig.getUnansweredQuestions}';
    debugPrint('🌐 [ApiService] Getting unanswered questions');
    debugPrint('   URL: $url');

    final response = await http.get(Uri.parse(url), headers: _authHeaders);

    debugPrint('📡 [ApiService] Response status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      debugPrint('✅ [ApiService] Questions fetched successfully');
      return data;
    } else if (response.statusCode == 401) {
      debugPrint('❌ [ApiService] Unauthorized (401)');
      throw ApiException('Unauthorized', response.statusCode);
    } else {
      debugPrint(
        '❌ [ApiService] Failed to fetch questions (${response.statusCode})',
      );
      throw ApiException('Failed to fetch questions', response.statusCode);
    }
  }

  static Future<Map<String, dynamic>> submitAnswer({
    required String questionId,
    required File audioFile,
  }) async {
    final url = '${ApiConfig.baseUrl}${ApiConfig.submitAnswer}';
    debugPrint('🌐 [ApiService] Submitting answer');
    debugPrint('   URL: $url');
    debugPrint('   Question ID: $questionId');
    debugPrint('   Audio file: ${audioFile.path}');
    debugPrint('   File size: ${await audioFile.length()} bytes');

    final uri = Uri.parse(url);
    final request = http.MultipartRequest('POST', uri);

    request.headers['Authorization'] = 'Bearer $_token';

    request.fields['question_id'] = questionId;

    final extension = audioFile.path.split('.').last.toLowerCase();
    final mimeType = _getMimeType(extension);
    debugPrint('   MIME type: $mimeType');

    request.files.add(
      await http.MultipartFile.fromPath(
        'audio',
        audioFile.path,
        contentType: MediaType.parse(mimeType),
      ),
    );

    debugPrint('📤 [ApiService] Sending multipart request...');
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    debugPrint('📡 [ApiService] Response status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      debugPrint('✅ [ApiService] Answer submitted successfully');
      return data;
    } else if (response.statusCode == 401) {
      debugPrint('❌ [ApiService] Unauthorized (401)');
      throw ApiException('Unauthorized', response.statusCode);
    } else if (response.statusCode == 404) {
      debugPrint('❌ [ApiService] Question not found (404)');
      throw ApiException('Question not found', response.statusCode);
    } else {
      debugPrint(
        '❌ [ApiService] Failed to submit answer (${response.statusCode})',
      );
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
