import 'package:flutter/foundation.dart';

class Conversation {
  final String id;
  final String userId;
  final String scenarioId;
  final String endGoalId;
  final String status;
  final bool goalAchieved;
  final int messageCount;
  final String? finalFeedback;
  final DateTime createdAt;
  final DateTime? completedAt;
  final Scenario? scenario;
  final Girl? girl;
  final EndGoal? endGoal;

  Conversation({
    required this.id,
    required this.userId,
    required this.scenarioId,
    required this.endGoalId,
    required this.status,
    required this.goalAchieved,
    required this.messageCount,
    this.finalFeedback,
    required this.createdAt,
    this.completedAt,
    this.scenario,
    this.girl,
    this.endGoal,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    try {
      return Conversation(
        id: json['id']?.toString() ?? '',
        userId: json['user_id']?.toString() ?? '',
        scenarioId: json['scenario_id']?.toString() ?? '',
        endGoalId: json['end_goal_id']?.toString() ?? '',
        status: json['status']?.toString() ?? 'active',
        goalAchieved: json['goal_achieved'] == true,
        messageCount: (json['message_count'] as num?)?.toInt() ?? 0,
        finalFeedback: json['final_feedback']?.toString(),
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'].toString())
            : DateTime.now(),
        completedAt: json['completed_at'] != null
            ? DateTime.parse(json['completed_at'].toString())
            : null,
        scenario: json['scenario'] != null
            ? Scenario.fromJson(json['scenario'] as Map<String, dynamic>)
            : null,
        girl: json['girl'] != null
            ? Girl.fromJson(json['girl'] as Map<String, dynamic>)
            : null,
        endGoal: json['end_goal'] != null
            ? EndGoal.fromJson(json['end_goal'] as Map<String, dynamic>)
            : null,
      );
    } catch (e, stackTrace) {
      debugPrint('[Conversation] Error parsing Conversation: $e');
      debugPrint('[Conversation] Stack trace: $stackTrace');
      debugPrint('[Conversation] JSON data: $json');
      rethrow;
    }
  }
}

class Scenario {
  final String id;
  final String name;
  final String description;
  final String? basePrompt;
  final String? imageUrl;
  final DateTime? createdAt;

  Scenario({
    required this.id,
    required this.name,
    required this.description,
    this.basePrompt,
    this.imageUrl,
    this.createdAt,
  });

  factory Scenario.fromJson(Map<String, dynamic> json) {
    try {
      return Scenario(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        basePrompt: json['base_prompt']?.toString(),
        imageUrl: json['image_url']?.toString(),
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'].toString())
            : null,
      );
    } catch (e, stackTrace) {
      debugPrint('[Scenario] Error parsing Scenario: $e');
      debugPrint('[Scenario] Stack trace: $stackTrace');
      debugPrint('[Scenario] JSON data: $json');
      rethrow;
    }
  }
}

class Girl {
  final String id;
  final String scenarioId;
  final String name;
  final String description;
  final String? personality;
  final String? basePrompt;
  final String? imageUrl;
  final DateTime? createdAt;

  Girl({
    required this.id,
    required this.scenarioId,
    required this.name,
    required this.description,
    this.personality,
    this.basePrompt,
    this.imageUrl,
    this.createdAt,
  });

  factory Girl.fromJson(Map<String, dynamic> json) {
    try {
      return Girl(
        id: json['id']?.toString() ?? '',
        scenarioId: json['scenario_id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        personality: json['personality']?.toString(),
        basePrompt: json['base_prompt']?.toString(),
        imageUrl: json['image_url']?.toString(),
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'].toString())
            : null,
      );
    } catch (e, stackTrace) {
      debugPrint('[Girl] Error parsing Girl: $e');
      debugPrint('[Girl] Stack trace: $stackTrace');
      debugPrint('[Girl] JSON data: $json');
      rethrow;
    }
  }
}

class EndGoal {
  final String id;
  final String name;
  final String description;
  final String difficulty;
  final DateTime? createdAt;

  EndGoal({
    required this.id,
    required this.name,
    required this.description,
    required this.difficulty,
    this.createdAt,
  });

  factory EndGoal.fromJson(Map<String, dynamic> json) {
    try {
      return EndGoal(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        difficulty: json['difficulty']?.toString() ?? 'medium',
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'].toString())
            : null,
      );
    } catch (e, stackTrace) {
      debugPrint('[EndGoal] Error parsing EndGoal: $e');
      debugPrint('[EndGoal] Stack trace: $stackTrace');
      debugPrint('[EndGoal] JSON data: $json');
      rethrow;
    }
  }
}
