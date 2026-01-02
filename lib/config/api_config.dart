class ApiConfig {
  static const String baseUrl = 'https://talktojesus-backend.onrender.com';

  // User Endpoints
  static const String createUser = '/api/user/create';

  // Question Endpoints
  static const String getUnansweredQuestions = '/api/questions/unanswered';
  static const String submitAnswer = '/api/questions/answer';
}
