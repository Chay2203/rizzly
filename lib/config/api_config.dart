class ApiConfig {
  static const String baseUrl = 'https://talktojesus-backend.onrender.com';

  // User Endpoints
  static const String createUser = '/api/user/create';
  static const String getCurrentUser = '/api/user/me';

  // Question Endpoints
  static const String getUnansweredQuestions = '/api/questions/unanswered';
  static const String submitAnswer = '/api/questions/answer';

  // Google OAuth Configuration
  static const String googleWebClientId =
      '188595500592-390tlrlldrg0r2ls1pe074bqojsd724g.apps.googleusercontent.com';
}
