import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../stores/main_store.dart';
import '../widgets/floating_hearts.dart';
import 'onboarding_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  final MainStore store;

  const LoginScreen({super.key, required this.store});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;
  int _logoTapCount = 0;
  bool _showTestEmailInput = false;
  final TextEditingController _emailController = TextEditingController();

  Future<void> _handleGoogleSignIn() async {
    debugPrint('[LoginScreen] Google Sign-In button tapped');
    setState(() => _isGoogleLoading = true);

    try {
      debugPrint('[LoginScreen] Initiating Google Sign-In...');
      final result = await AuthService.signInWithGoogle();

      final user = result['user'];
      final userId = user['id']?.toString() ?? '';
      final isNewUser = result['isNewUser'] ?? false;

      debugPrint('[LoginScreen] Sign-in successful');
      debugPrint('   User ID: $userId');
      debugPrint('   Is New User: $isNewUser');

      if (mounted) {
        if (isNewUser) {
          debugPrint('[LoginScreen] New user - Navigating to OnboardingScreen');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  OnboardingScreen(userId: userId, store: widget.store),
            ),
          );
        } else {
          debugPrint('[LoginScreen] Existing user - Navigating to HomeScreen');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  HomeScreen(userId: userId, store: widget.store),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('[LoginScreen] Error signing in: $e');
      debugPrint('   Stack trace: $stackTrace');

      if (mounted) {
        String errorMessage = 'Failed to sign in with Google';
        final errorString = e.toString();

        if (errorString.contains('cancelled')) {
          errorMessage = 'Sign in was cancelled';
        } else if (errorString.contains('network')) {
          errorMessage = 'Network error. Please check your connection';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  Future<void> _handleAppleSignIn() async {
    debugPrint('[LoginScreen] Apple Sign-In button tapped');
    setState(() => _isAppleLoading = true);

    try {
      debugPrint('[LoginScreen] Initiating Apple Sign-In...');
      final result = await AuthService.signInWithApple();

      final user = result['user'];
      final userId = user['id']?.toString() ?? '';
      final isNewUser = result['isNewUser'] ?? false;

      debugPrint('[LoginScreen] Apple Sign-in successful');
      debugPrint('   User ID: $userId');
      debugPrint('   Is New User: $isNewUser');

      if (mounted) {
        if (isNewUser) {
          debugPrint('[LoginScreen] New user - Navigating to OnboardingScreen');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  OnboardingScreen(userId: userId, store: widget.store),
            ),
          );
        } else {
          debugPrint('[LoginScreen] Existing user - Navigating to HomeScreen');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  HomeScreen(userId: userId, store: widget.store),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('[LoginScreen] Error with Apple Sign-In: $e');
      debugPrint('   Stack trace: $stackTrace');

      if (mounted) {
        String errorMessage = 'Failed to sign in with Apple';
        final errorString = e.toString();

        if (errorString.contains('cancelled')) {
          errorMessage = 'Sign in was cancelled';
        } else if (errorString.contains('not available')) {
          errorMessage = 'Apple Sign-In is not available on this device';
        } else if (errorString.contains('network')) {
          errorMessage = 'Network error. Please check your connection';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAppleLoading = false);
      }
    }
  }

  Widget _buildSvgIcon(
    String assetPath, {
    Color? color,
    IconData? fallbackIcon,
  }) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Builder(
        builder: (context) {
          try {
            return SvgPicture.asset(
              assetPath,
              width: 24,
              height: 24,
              fit: BoxFit.contain,
              colorFilter: color != null
                  ? ColorFilter.mode(color, BlendMode.srcIn)
                  : null,
            );
          } catch (e) {
            return Icon(
              fallbackIcon ?? Icons.error,
              size: 24,
              color: color ?? Colors.black,
            );
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleLogoTap() {
    setState(() {
      _logoTapCount++;
      if (_logoTapCount >= 5) {
        _showTestEmailInput = true;
        _logoTapCount = 0; // Reset counter
      }
    });
  }

  Future<void> _handleTestEmailSubmit() async {
    final email = _emailController.text.trim();
    if (email == 'testuser@test.com') {
      // Enable test mode and set token
      ApiService.enableTestMode();

      // Store test token in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', ApiService.token!);

      // Extract user ID from test token (hardcoded)
      const testUserId = '483e90e2-02fc-41d8-a509-8593b6ac8ef6';
      await prefs.setString('user_id', testUserId);
      await prefs.setString('user_email', 'testuser@test.com');

      // Navigate directly to home screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                HomeScreen(userId: testUserId, store: widget.store),
          ),
        );
      }
    } else {
      // Show error for wrong email
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid test email'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive button width (max 343, but adapts to screen)
    final buttonWidth = screenWidth > 343 ? 343.0 : screenWidth - 32;
    final logoSize = screenWidth > 250 ? 90.0 : screenWidth * 0.36;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          const FloatingHeartsBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(
                top: 53,
                left: 16,
                right: 16,
                bottom: 36,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Top section: Logo and tagline
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 250,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: _handleLogoTap,
                              child: Container(
                                width: logoSize,
                                height: logoSize,
                                clipBehavior: Clip.antiAlias,
                                decoration: ShapeDecoration(
                                  color: const Color(0xFF04001B),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20.57),
                                  ),
                                ),
                                child: Center(
                                  child: Image.asset(
                                    'assets/images/small_logo.png',
                                    width: logoSize,
                                    height: logoSize,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: screenWidth > 360 ? 360.0 : screenWidth - 32,
                        child: Text(
                          'Your dating coach',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFF121212),
                            fontSize: 16,
                            fontWeight: FontWeight.w300,
                            height: 1.60,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Bottom section: Buttons or Test Email Input
                  if (_showTestEmailInput)
                    // Test Email Input
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: buttonWidth,
                          child: TextField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              hintText: 'Enter test email',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14998.50),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 15,
                              ),
                            ),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 19.22,
                              fontWeight: FontWeight.w500,
                            ),
                            onSubmitted: (_) => _handleTestEmailSubmit(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: buttonWidth,
                          child: GestureDetector(
                            onTap: _handleTestEmailSubmit,
                            child: Container(
                              height: 60,
                              padding: const EdgeInsets.all(15),
                              decoration: ShapeDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment(0.00, 0.00),
                                  end: Alignment(0.69, 0.42),
                                  colors: [
                                    Color(0xFF006FD1),
                                    Color(0xFF006FD0),
                                  ],
                                ),
                                shape: RoundedRectangleBorder(
                                  side: const BorderSide(
                                    width: 1,
                                    color: Colors.white,
                                  ),
                                  borderRadius: BorderRadius.circular(14998.50),
                                ),
                              ),
                              child: const Center(
                                child: Text(
                                  'Login as Test User',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0xFFFFF7FB),
                                    fontSize: 19.22,
                                    fontWeight: FontWeight.w500,
                                    height: 1.20,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    // Regular Sign-In Buttons
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Google Sign-In Button
                        SizedBox(
                          width: buttonWidth,
                          child: GestureDetector(
                            onTap: _isGoogleLoading
                                ? null
                                : _handleGoogleSignIn,
                            child: Container(
                              height: 60,
                              padding: const EdgeInsets.all(15),
                              decoration: ShapeDecoration(
                                color: Colors.black,
                                shape: RoundedRectangleBorder(
                                  side: const BorderSide(
                                    width: 1,
                                    color: Colors.white,
                                  ),
                                  borderRadius: BorderRadius.circular(14998.50),
                                ),
                              ),
                              child: _isGoogleLoading
                                  ? const Center(
                                      child: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CupertinoActivityIndicator(
                                          color: Colors.white,
                                        ),
                                      ),
                                    )
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        _buildSvgIcon(
                                          'assets/svgs/google.svg',
                                          fallbackIcon: Icons.account_circle,
                                        ),
                                        const SizedBox(width: 15),
                                        Text(
                                          'Continue with Google',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: const Color(0xFFFFF7FB),
                                            fontSize: 19.22,
                                            fontWeight: FontWeight.w500,
                                            height: 1.20,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Apple Sign-In Button
                        SizedBox(
                          width: buttonWidth,
                          child: GestureDetector(
                            onTap: _isAppleLoading ? null : _handleAppleSignIn,
                            child: Container(
                              height: 60,
                              padding: const EdgeInsets.all(15),
                              decoration: ShapeDecoration(
                                color: Colors.white,
                                shape: RoundedRectangleBorder(
                                  side: const BorderSide(width: 1),
                                  borderRadius: BorderRadius.circular(14998.50),
                                ),
                              ),
                              child: _isAppleLoading
                                  ? const Center(
                                      child: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CupertinoActivityIndicator(),
                                      ),
                                    )
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        _buildSvgIcon(
                                          'assets/svgs/apple.svg',
                                          color: Colors.black,
                                          fallbackIcon: Icons.apple,
                                        ),
                                        const SizedBox(width: 15),
                                        Text(
                                          'Continue with Apple',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 19.22,
                                            fontWeight: FontWeight.w500,
                                            height: 1.20,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
