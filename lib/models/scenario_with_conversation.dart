import 'package:flutter/foundation.dart';
import 'conversation.dart';

class ScenarioWithConversation {
  final Scenario scenario;
  final Girl girl;
  final List<EndGoal> endGoals;
  final ConversationSummary? conversation;

  ScenarioWithConversation({
    required this.scenario,
    required this.girl,
    required this.endGoals,
    this.conversation,
  });

  factory ScenarioWithConversation.fromJson(Map<String, dynamic> json) {
    try {
      return ScenarioWithConversation(
        scenario: Scenario.fromJson(json),
        girl: Girl.fromJson(json['girl'] as Map<String, dynamic>),
        endGoals: (json['end_goals'] as List?)
                ?.map((e) => EndGoal.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        conversation: json['conversation'] != null
            ? ConversationSummary.fromJson(
                json['conversation'] as Map<String, dynamic>,
              )
            : null,
      );
    } catch (e, stackTrace) {
      debugPrint('[ScenarioWithConversation] Error parsing: $e');
      debugPrint('[ScenarioWithConversation] Stack trace: $stackTrace');
      debugPrint('[ScenarioWithConversation] JSON data: $json');
      rethrow;
    }
  }

  // Helper getters for status
  bool get hasActiveConversation =>
      conversation != null && conversation!.status == 'active';
  bool get hasCompletedConversation =>
      conversation != null && conversation!.status == 'completed';
  bool get hasFailedConversation =>
      conversation != null && conversation!.status == 'failed';
  bool get hasNoConversation => conversation == null;
}

class ConversationSummary {
  final String id;
  final String status;
  final bool goalAchieved;
  final int messageCount;
  final String? finalFeedback;
  final DateTime createdAt;
  final DateTime? completedAt;
  final EndGoal? endGoal;

  ConversationSummary({
    required this.id,
    required this.status,
    required this.goalAchieved,
    required this.messageCount,
    this.finalFeedback,
    required this.createdAt,
    this.completedAt,
    this.endGoal,
  });

  factory ConversationSummary.fromJson(Map<String, dynamic> json) {
    try {
      return ConversationSummary(
        id: json['id']?.toString() ?? '',
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
        endGoal: json['end_goal'] != null
            ? EndGoal.fromJson(json['end_goal'] as Map<String, dynamic>)
            : null,
      );
    } catch (e, stackTrace) {
      debugPrint('[ConversationSummary] Error parsing: $e');
      debugPrint('[ConversationSummary] Stack trace: $stackTrace');
      debugPrint('[ConversationSummary] JSON data: $json');
      rethrow;
    }
  }
}

