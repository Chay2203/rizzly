class ApiConfig {
  static const String baseUrl =
      'https://unforensically-apographic-thalia.ngrok-free.dev';

  // User Endpoints
  static const String createUser = '/api/user/create';
  static const String createUserWithApple = '/api/user/create/apple';
  static const String getCurrentUser = '/api/user/me';

  // Question Endpoints
  static const String getUnansweredQuestions = '/api/questions/unanswered';
  static const String submitAnswer = '/api/questions/answer';

  // Google OAuth Configuration
  static const String googleWebClientId =
      '188595500592-390tlrlldrg0r2ls1pe074bqojsd724g.apps.googleusercontent.com';
  static const String googleIosClientId =
      '188595500592-iataacmqile8phcfib9a94s311k2n8gl.apps.googleusercontent.com';

  // Apple Sign-In Configuration
  static const String appleClientId = 'com.rizzly.room42';
}
