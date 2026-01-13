class ApiConfig {
  static const String baseUrl = 'https://rizzly.up.railway.app';

  // User Endpoints
  static const String createUser = '/api/user/create';
  static const String createUserWithApple = '/api/user/create/apple';
  static const String getCurrentUser = '/api/user/me';

  // Question Endpoints
  static const String getUnansweredQuestions = '/api/questions/unanswered';
  static const String submitAnswer = '/api/questions/answer';

  // Scenario Endpoints
  static const String getScenariosWithConversations =
      '/api/scenarios/with-conversations';

  // Conversation Endpoints
  static const String getEndGoals = '/api/end-goals';
  static const String submitEndGoal = '/api/conversations/submit-end-goal';
  static const String getQuestion = '/api/conversations/get-question';
  static const String submitConversationAnswer =
      '/api/conversations/submit-answer';

  // Google OAuth Configuration
  static const String googleWebClientId =
      '188595500592-390tlrlldrg0r2ls1pe074bqojsd724g.apps.googleusercontent.com';
  static const String googleIosClientId =
      '188595500592-iataacmqile8phcfib9a94s311k2n8gl.apps.googleusercontent.com';

  // Apple Sign-In Configuration
  static const String appleClientId = 'com.rizzly.room42';
}
