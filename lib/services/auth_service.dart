import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'api_service.dart';
import '../config/api_config.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';

  // Initialize Google Sign-In with platform-specific client IDs
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: Platform.isIOS ? ApiConfig.googleIosClientId : null,
    serverClientId: ApiConfig.googleWebClientId,
    scopes: ['email'],
  );

  /// Sign in with Google and authenticate with backend
  static Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Google sign-in was cancelled');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        debugPrint('❌ [AuthService] No ID Token found');
        throw Exception('No ID Token found. Please try again.');
      }

      final response = await ApiService.createUserWithGoogle(idToken);

      final user = response['user'];
      final token = response['token'];

      if (user == null || token == null) {
        debugPrint('❌ [AuthService] Invalid response from server: $response');
        throw Exception('Invalid response from server');
      }

      final userId = user['id']?.toString() ?? '';
      final userEmail = user['email']?.toString() ?? googleUser.email;

      await saveSession(token.toString(), userId, userEmail);

      return {
        'user': user,
        'token': token,
        'googleUser': {
          'email': googleUser.email,
          'displayName': googleUser.displayName,
          'photoUrl': googleUser.photoUrl,
        },
      };
    } on PlatformException catch (e) {
      debugPrint('❌ [AuthService] PlatformException: ${e.code} - ${e.message}');

      try {
        await _googleSignIn.signOut();
      } catch (signOutError) {
        debugPrint('⚠️ [AuthService] Error during sign out: $signOutError');
      }

      String errorMessage = 'Failed to sign in with Google';
      if (e.code == 'sign_in_failed') {
        if (e.message?.contains('10') == true) {
          errorMessage =
              'DEVELOPER_ERROR: Check Google Cloud Console configuration.\n'
              'Verify:\n'
              '1. SHA-1 certificate is registered\n'
              '2. Package name matches (com.rizzly.room42)\n'
              '3. OAuth client IDs are configured correctly';
        } else {
          errorMessage = 'Google Sign-In failed. Please try again.';
        }
      } else if (e.code == 'network_error') {
        errorMessage = 'Network error. Please check your connection.';
      }

      throw Exception(
        '$errorMessage\n\nError Code: ${e.code}\nMessage: ${e.message}',
      );
    } catch (e, stackTrace) {
      debugPrint('❌ [AuthService] Error during sign-in: $e');
      debugPrint('   StackTrace: $stackTrace');

      try {
        await _googleSignIn.signOut();
      } catch (signOutError) {
        debugPrint('⚠️ [AuthService] Error during sign out: $signOutError');
      }

      rethrow;
    }
  }

  /// Sign out from both Google and the app
  static Future<void> signOut() async {
    debugPrint(
      '🚪 [AuthService] Signing out from Google and clearing local session...',
    );
    // Disconnect account to force account picker on next sign-in
    try {
      await _googleSignIn.disconnect();
    } catch (e) {
      debugPrint('⚠️ [AuthService] Error disconnecting: $e');
    }
    // Also sign out (in case disconnect didn't work)
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('⚠️ [AuthService] Error signing out: $e');
    }
    await logout();
    debugPrint('✅ [AuthService] Sign out complete');
  }

  /// Save user session
  static Future<void> saveSession(
    String token,
    String userId, [
    String? email,
  ]) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userIdKey, userId);
    if (email != null) {
      await prefs.setString(_userEmailKey, email);
    }
    ApiService.setToken(token);
  }

  /// Check if user is logged in (only checks local storage)
  static Future<bool> hasStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    return token != null && token.isNotEmpty;
  }

  /// Validate JWT token by calling backend API
  /// Returns user data if token is valid, throws exception if invalid
  static Future<Map<String, dynamic>> validateToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);

    if (token == null || token.isEmpty) {
      throw Exception('No token found');
    }

    ApiService.setToken(token);

    try {
      final userData = await ApiService.getCurrentUser();

      final user = userData['user'];
      if (user != null) {
        final userId = user['id']?.toString() ?? '';
        final userEmail = user['email']?.toString();

        await prefs.setString(_userIdKey, userId);
        if (userEmail != null) {
          await prefs.setString(_userEmailKey, userEmail);
        }
      }

      return userData;
    } catch (e) {
      debugPrint('❌ [AuthService] Token validation failed: $e');
      await logout();
      rethrow;
    }
  }

  /// Check if user is logged in and token is valid
  /// This method validates the token with the backend
  static Future<bool> isLoggedIn() async {
    try {
      await validateToken();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get current user ID
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  /// Get current user email
  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  /// Get current user from backend
  static Future<Map<String, dynamic>> getCurrentUser() async {
    return await ApiService.getCurrentUser();
  }

  /// Clear local session
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userEmailKey);
  }

  /// Log current Google Sign-In configuration for debugging
  static void logConfiguration() {
    debugPrint('📋 [AuthService] Google Sign-In Configuration:');
    debugPrint('   - Server Client ID: ${ApiConfig.googleWebClientId}');
    debugPrint('   - Package Name: com.rizzly.room42');
    debugPrint(
      '   - Expected SHA-1: 37:7E:7C:A8:1F:3F:EE:28:41:80:B4:A4:17:36:96:87:83:09:8D:C1',
    );
  }

  /// Sign in with Apple Tester account (for App Store review)
  static Future<Map<String, dynamic>> signInAsAppleTester() async {
    debugPrint('🍎 [AuthService] Signing in as Apple Tester...');

    const String testUserId = '00000000-0000-0000-0000-000000000001';
    const String testEmail = 'apple.tester@talktojesus.app';
    const String testToken =
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiIwMDAwMDAwMC0wMDAwLTAwMDAtMDAwMC0wMDAwMDAwMDAwMDEiLCJpYXQiOjE3Njc4NTI0MjAsImV4cCI6MTc3MzkwMDQyMH0.H_BC2498AwUo8Ujn9O6HUiI0YW1ql5HIXSHlhUv_dUc';

    await saveSession(testToken, testUserId, testEmail);

    debugPrint('✅ [AuthService] Apple Tester sign-in complete');

    return {
      'user': {
        'id': testUserId,
        'email': testEmail,
      },
      'token': testToken,
    };
  }
}
