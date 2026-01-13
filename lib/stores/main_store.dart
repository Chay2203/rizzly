import 'package:flutter/foundation.dart';
import '../models/conversation.dart';
import '../models/scenario_with_conversation.dart';
import '../services/api_service.dart';

class MainStore extends ChangeNotifier {
  List<ScenarioWithConversation> _scenarios = [];
  bool _isLoading = false;
  String? _error;

  List<EndGoal> _endGoals = [];
  bool _isLoadingEndGoals = false;
  String? _endGoalsError;

  List<ScenarioWithConversation> get scenarios => _scenarios;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<EndGoal> get endGoals => _endGoals;
  bool get isLoadingEndGoals => _isLoadingEndGoals;
  String? get endGoalsError => _endGoalsError;

  // Get scenarios grouped by conversation status
  List<ScenarioWithConversation> get activeScenarios =>
      _scenarios.where((s) => s.hasActiveConversation).toList();

  List<ScenarioWithConversation> get completedScenarios =>
      _scenarios.where((s) => s.hasCompletedConversation).toList();

  List<ScenarioWithConversation> get failedScenarios =>
      _scenarios.where((s) => s.hasFailedConversation).toList();

  List<ScenarioWithConversation> get newScenarios =>
      _scenarios.where((s) => s.hasNoConversation).toList();

  Future<void> loadScenarios() async {
    debugPrint('[MainStore] Loading scenarios...');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await ApiService.getScenariosWithConversations();
      debugPrint('[MainStore] Raw API response: $data');

      final scenariosList = data['scenarios'] as List?;
      debugPrint(
        '[MainStore] Scenarios list type: ${scenariosList.runtimeType}',
      );
      debugPrint(
        '[MainStore] Scenarios list length: ${scenariosList?.length ?? 0}',
      );

      if (scenariosList == null || scenariosList.isEmpty) {
        debugPrint('[MainStore] No scenarios in response');
        _scenarios = [];
        _isLoading = false;
        notifyListeners();
        // Extract end goals from scenarios if available, otherwise load separately
        _extractEndGoalsFromScenarios();
        return;
      }

      _scenarios = [];
      for (int i = 0; i < scenariosList.length; i++) {
        try {
          final json = scenariosList[i] as Map<String, dynamic>;
          debugPrint('[MainStore] Parsing scenario $i: ${json['id']}');
          final scenario = ScenarioWithConversation.fromJson(json);
          _scenarios.add(scenario);
          debugPrint('[MainStore] Successfully parsed scenario $i');
        } catch (e, stackTrace) {
          debugPrint('[MainStore] Error parsing scenario $i: $e');
          debugPrint('[MainStore] Stack trace: $stackTrace');
          debugPrint('[MainStore] Scenario data: ${scenariosList[i]}');
        }
      }

      debugPrint(
        '[MainStore] Loaded ${_scenarios.length} scenarios out of ${scenariosList.length}',
      );
      _isLoading = false;
      notifyListeners();

      // Extract end goals from scenarios (they're included in the response)
      _extractEndGoalsFromScenarios();
    } catch (e, stackTrace) {
      debugPrint('[MainStore] Error loading scenarios: $e');
      debugPrint('[MainStore] Stack trace: $stackTrace');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void _extractEndGoalsFromScenarios() {
    // Extract unique end goals from all scenarios
    final Set<String> seenGoalIds = {};
    _endGoals = [];

    for (final scenario in _scenarios) {
      for (final goal in scenario.endGoals) {
        if (!seenGoalIds.contains(goal.id)) {
          _endGoals.add(goal);
          seenGoalIds.add(goal.id);
        }
      }
    }

    debugPrint(
      '[MainStore] Extracted ${_endGoals.length} unique end goals from scenarios',
    );

    // If no end goals found in scenarios, load them separately
    if (_endGoals.isEmpty) {
      loadEndGoals();
    }
  }

  void markConversationCompleted(String conversationId) {
    final index = _scenarios.indexWhere(
      (s) => s.conversation?.id == conversationId,
    );
    if (index != -1) {
      debugPrint(
        '[MainStore] Marking conversation $conversationId as completed',
      );
      // Reload scenarios to get updated data
      loadScenarios();
    }
  }

  Future<void> loadEndGoals() async {
    // Don't reload if already loaded
    if (_endGoals.isNotEmpty) {
      debugPrint('[MainStore] End goals already loaded, skipping...');
      return;
    }

    debugPrint('[MainStore] Loading end goals in background...');
    _isLoadingEndGoals = true;
    _endGoalsError = null;
    notifyListeners();

    try {
      final data = await ApiService.getAllEndGoals();
      _endGoals = (data['end_goals'] as List)
          .map((json) => EndGoal.fromJson(json))
          .toList();
      debugPrint('[MainStore] Loaded ${_endGoals.length} end goals');
      _isLoadingEndGoals = false;
      notifyListeners();
    } catch (e) {
      debugPrint('[MainStore] Error loading end goals: $e');
      _endGoalsError = e.toString();
      _isLoadingEndGoals = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearEndGoalsError() {
    _endGoalsError = null;
    notifyListeners();
  }
}
