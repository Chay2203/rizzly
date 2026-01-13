import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../config/api_config.dart';

class ApiService {
  static String? _token;

  static void setToken(String token) {
    debugPrint('[ApiService] Setting token (length: ${token.length})');
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
    debugPrint('[ApiService] Creating user with Google token');
    debugPrint('   URL: $url');
    debugPrint('   Token length: ${googleIdToken.length}');

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'token': googleIdToken}),
    );

    debugPrint('[ApiService] Response status: ${response.statusCode}');
    debugPrint('   Response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['token'] != null) {
        setToken(data['token']);
      }
      debugPrint('[ApiService] User created successfully');
      return data;
    } else if (response.statusCode == 400) {
      debugPrint('[ApiService] Missing Google token (400)');
      throw ApiException('Missing Google token', response.statusCode);
    } else if (response.statusCode == 401) {
      debugPrint('[ApiService] Invalid Google token (401)');
      throw ApiException('Invalid Google token', response.statusCode);
    } else {
      debugPrint('[ApiService] Failed to create user (${response.statusCode})');
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
    debugPrint('[ApiService] Creating user with Apple token');
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

    debugPrint('[ApiService] Response status: ${response.statusCode}');
    debugPrint('   Response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['token'] != null) {
        setToken(data['token']);
      }
      debugPrint('[ApiService] Apple user created successfully');
      return data;
    } else if (response.statusCode == 400) {
      debugPrint('[ApiService] Missing Apple token (400)');
      throw ApiException('Missing Apple token', response.statusCode);
    } else if (response.statusCode == 401) {
      debugPrint('[ApiService] Invalid Apple token (401)');
      throw ApiException('Invalid Apple token', response.statusCode);
    } else {
      debugPrint('[ApiService] Failed to create user (${response.statusCode})');
      throw ApiException('Failed to create user', response.statusCode);
    }
  }

  /// Get current authenticated user
  static Future<Map<String, dynamic>> getCurrentUser() async {
    final url = '${ApiConfig.baseUrl}${ApiConfig.getCurrentUser}';
    debugPrint('[ApiService] Getting current user');
    debugPrint('   URL: $url');
    debugPrint('   Has token: ${_token != null}');

    final response = await http.get(Uri.parse(url), headers: _authHeaders);

    debugPrint('[ApiService] Response status: ${response.statusCode}');
    debugPrint('   Response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      debugPrint('[ApiService] Current user fetched successfully');
      return data;
    } else if (response.statusCode == 401) {
      debugPrint('[ApiService] Unauthorized (401)');
      throw ApiException('Unauthorized', response.statusCode);
    } else {
      debugPrint('[ApiService] Failed to fetch user (${response.statusCode})');
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
    debugPrint('[ApiService] Getting unanswered questions');
    debugPrint('   URL: $url');

    final response = await http.get(Uri.parse(url), headers: _authHeaders);

    debugPrint('[ApiService] Response status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      debugPrint('[ApiService] Questions fetched successfully');
      return data;
    } else if (response.statusCode == 401) {
      debugPrint('[ApiService] Unauthorized (401)');
      throw ApiException('Unauthorized', response.statusCode);
    } else {
      debugPrint(
        '[ApiService] Failed to fetch questions (${response.statusCode})',
      );
      throw ApiException('Failed to fetch questions', response.statusCode);
    }
  }

  static Future<Map<String, dynamic>> submitAnswer({
    required String questionId,
    required File audioFile,
  }) async {
    final url = '${ApiConfig.baseUrl}${ApiConfig.submitAnswer}';
    debugPrint('[ApiService] Submitting answer');
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

    debugPrint('[ApiService] Sending multipart request...');
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    debugPrint('[ApiService] Response status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      debugPrint('[ApiService] Answer submitted successfully');
      return data;
    } else if (response.statusCode == 401) {
      debugPrint('[ApiService] Unauthorized (401)');
      throw ApiException('Unauthorized', response.statusCode);
    } else if (response.statusCode == 404) {
      debugPrint('[ApiService] Question not found (404)');
      throw ApiException('Question not found', response.statusCode);
    } else {
      debugPrint(
        '[ApiService] Failed to submit answer (${response.statusCode})',
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

  // ==================== SCENARIO APIs ====================

  /// Get all scenarios with conversations for current user
  static Future<Map<String, dynamic>> getScenariosWithConversations({
    String? status,
  }) async {
    var url = '${ApiConfig.baseUrl}${ApiConfig.getScenariosWithConversations}';
    if (status != null) {
      url += '?status=$status';
    }
    debugPrint('[ApiService] Getting scenarios with conversations');
    debugPrint('   URL: $url');

    final response = await http.get(Uri.parse(url), headers: _authHeaders);

    debugPrint('[ApiService] Response status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      debugPrint('[ApiService] Scenarios fetched successfully');
      debugPrint('[ApiService] Response data: $data');
      debugPrint(
        '[ApiService] Scenarios count: ${(data['scenarios'] as List?)?.length ?? 0}',
      );
      return data;
    } else if (response.statusCode == 401) {
      debugPrint('[ApiService] Unauthorized (401)');
      throw ApiException('Unauthorized', response.statusCode);
    } else {
      debugPrint(
        '[ApiService] Failed to fetch scenarios (${response.statusCode})',
      );
      throw ApiException('Failed to fetch scenarios', response.statusCode);
    }
  }

  /// Get all available end goals
  static Future<Map<String, dynamic>> getAllEndGoals() async {
    final url = '${ApiConfig.baseUrl}${ApiConfig.getEndGoals}';
    debugPrint('[ApiService] Getting end goals');
    debugPrint('   URL: $url');

    final response = await http.get(Uri.parse(url), headers: _authHeaders);

    debugPrint('[ApiService] Response status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      debugPrint('[ApiService] End goals fetched successfully');
      return data;
    } else if (response.statusCode == 401) {
      debugPrint('[ApiService] Unauthorized (401)');
      throw ApiException('Unauthorized', response.statusCode);
    } else {
      debugPrint(
        '[ApiService] Failed to fetch end goals (${response.statusCode})',
      );
      throw ApiException('Failed to fetch end goals', response.statusCode);
    }
  }

  /// Submit end goal for a conversation
  static Future<Map<String, dynamic>> submitEndGoal({
    required String scenarioId,
    required String endGoalId,
  }) async {
    final url = '${ApiConfig.baseUrl}${ApiConfig.submitEndGoal}';
    debugPrint('[ApiService] Submitting end goal');
    debugPrint('   URL: $url');
    debugPrint('   Scenario ID: $scenarioId');
    debugPrint('   End Goal ID: $endGoalId');

    final response = await http.post(
      Uri.parse(url),
      headers: _authHeaders,
      body: jsonEncode({'scenario_id': scenarioId, 'end_goal_id': endGoalId}),
    );

    debugPrint('[ApiService] Response status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      debugPrint('[ApiService] End goal submitted successfully');
      return data;
    } else if (response.statusCode == 400) {
      debugPrint('[ApiService] Bad request (400)');
      throw ApiException(
        'Missing scenario_id or end_goal_id',
        response.statusCode,
      );
    } else if (response.statusCode == 404) {
      debugPrint('[ApiService] Not found (404)');
      throw ApiException('Scenario or end goal not found', response.statusCode);
    } else {
      debugPrint(
        '[ApiService] Failed to submit end goal (${response.statusCode})',
      );
      throw ApiException('Failed to submit end goal', response.statusCode);
    }
  }

  /// Get next question from conversation
  static Future<Map<String, dynamic>> getQuestion({
    required String scenarioId,
    required String endGoalId,
  }) async {
    final url = '${ApiConfig.baseUrl}${ApiConfig.getQuestion}';
    debugPrint('[ApiService] Getting question');
    debugPrint('   URL: $url');
    debugPrint('   Scenario ID: $scenarioId');
    debugPrint('   End Goal ID: $endGoalId');

    final response = await http.post(
      Uri.parse(url),
      headers: _authHeaders,
      body: jsonEncode({'scenario_id': scenarioId, 'end_goal_id': endGoalId}),
    );

    debugPrint('[ApiService] Response status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      debugPrint('[ApiService] Question fetched successfully');
      return data;
    } else if (response.statusCode == 400) {
      debugPrint('[ApiService] Bad request (400)');
      throw ApiException('Bad request', response.statusCode);
    } else if (response.statusCode == 404) {
      debugPrint('[ApiService] Not found (404)');
      throw ApiException('Scenario or end goal not found', response.statusCode);
    } else {
      debugPrint(
        '[ApiService] Failed to get question (${response.statusCode})',
      );
      throw ApiException('Failed to get question', response.statusCode);
    }
  }

  /// Submit answer to conversation (audio or text)
  static Future<Map<String, dynamic>> submitConversationAnswer({
    required String scenarioId,
    required String endGoalId,
    File? audioFile,
    String? message,
  }) async {
    final url = '${ApiConfig.baseUrl}${ApiConfig.submitConversationAnswer}';
    debugPrint('[ApiService] Submitting conversation answer');
    debugPrint('   URL: $url');
    debugPrint('   Scenario ID: $scenarioId');
    debugPrint('   End Goal ID: $endGoalId');

    if (audioFile != null) {
      // Submit audio
      debugPrint('   Audio file: ${audioFile.path}');
      debugPrint('   File size: ${await audioFile.length()} bytes');

      final uri = Uri.parse(url);
      final request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = 'Bearer $_token';

      request.fields['scenario_id'] = scenarioId;
      request.fields['end_goal_id'] = endGoalId;

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

      debugPrint('[ApiService] Sending multipart request...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('[ApiService] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('[ApiService] Answer submitted successfully');
        return data;
      } else {
        debugPrint(
          '[ApiService] Failed to submit answer (${response.statusCode})',
        );
        throw ApiException('Failed to submit answer', response.statusCode);
      }
    } else if (message != null) {
      // Submit text
      debugPrint('   Text message: $message');

      final response = await http.post(
        Uri.parse(url),
        headers: _authHeaders,
        body: jsonEncode({
          'scenario_id': scenarioId,
          'end_goal_id': endGoalId,
          'message': message,
        }),
      );

      debugPrint('[ApiService] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('[ApiService] Answer submitted successfully');
        return data;
      } else {
        debugPrint(
          '[ApiService] Failed to submit answer (${response.statusCode})',
        );
        throw ApiException('Failed to submit answer', response.statusCode);
      }
    } else {
      throw ApiException('Either audio file or message must be provided', 400);
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
