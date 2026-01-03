import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/auth_service.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const ZyphoraApp());
}

class ZyphoraApp extends StatelessWidget {
  const ZyphoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zyphora',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuth();
    });
  }

  Future<void> _checkAuth() async {
    debugPrint('🚀 [SplashScreen] Starting auth check...');
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    try {
      // Step 1: Check if JWT exists in local storage
      debugPrint('📋 [SplashScreen] Step 1: Checking for stored token...');
      final hasToken = await AuthService.hasStoredToken().timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          debugPrint('⏱️ [SplashScreen] Token check timeout');
          return false;
        },
      );

      if (!mounted) return;

      if (hasToken) {
        debugPrint('✅ [SplashScreen] Token found, validating...');
        // Step 2: JWT exists, validate it by calling getCurrentUser API
        try {
          final userData = await AuthService.validateToken().timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              debugPrint('⏱️ [SplashScreen] Token validation timeout');
              throw Exception('Request timeout');
            },
          );

          if (!mounted) return;

          // Step 3: API call succeeded, token is valid - redirect to dashboard
          final user = userData['user'];
          final userId = user['id']?.toString() ?? '';

          debugPrint('✅ [SplashScreen] Token valid, navigating to HomeScreen');
          debugPrint('   User ID: $userId');

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => HomeScreen(userId: userId),
            ),
          );
        } catch (e) {
          // Step 4: API call failed (token invalid/expired) - redirect to login
          debugPrint('❌ [SplashScreen] Token validation failed: $e');
          if (!mounted) return;
          debugPrint('🔄 [SplashScreen] Redirecting to login page');
          _goToLanding();
        }
      } else {
        // No JWT in local storage - redirect to login
        debugPrint('❌ [SplashScreen] No token found');
        debugPrint('🔄 [SplashScreen] Redirecting to login page');
        _goToLanding();
      }
    } catch (e) {
      // Any other error - redirect to login
      debugPrint('❌ [SplashScreen] Auth check error: $e');
      if (!mounted) return;
      debugPrint('🔄 [SplashScreen] Redirecting to login page');
      _goToLanding();
    }
  }

  void _goToLanding() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const LandingPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Text(
          'Zyphora',
          style: GoogleFonts.playfairDisplay(
            fontSize: 48,
            fontWeight: FontWeight.w500,
            fontStyle: FontStyle.italic,
            letterSpacing: 0,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    debugPrint('👆 [LandingPage] Google Sign-In button tapped');
    setState(() => _isLoading = true);

    try {
      debugPrint('🔄 [LandingPage] Initiating Google Sign-In...');
      final result = await AuthService.signInWithGoogle();

      final user = result['user'];
      final userId = user['id']?.toString() ?? '';

      debugPrint('✅ [LandingPage] Sign-in successful');
      debugPrint('   User ID: $userId');

      if (mounted) {
        debugPrint('🔄 [LandingPage] Navigating to HomeScreen');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(userId: userId),
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [LandingPage] Error signing in: $e');
      debugPrint('   Stack trace: $stackTrace');
      
      if (mounted) {
        String errorMessage = 'Failed to sign in with Google';
        String? detailedError;
        
        final errorString = e.toString();
        
        if (errorString.contains('cancelled')) {
          errorMessage = 'Sign in was cancelled';
        } else if (errorString.contains('network')) {
          errorMessage = 'Network error. Please check your connection';
        } else if (errorString.contains('DEVELOPER_ERROR')) {
          errorMessage = 'Configuration Error';
          detailedError = errorString.contains('Error Code:')
              ? errorString.split('Error Code:')[1].trim()
              : 'Check Google Cloud Console settings';
        } else if (errorString.contains('Invalid')) {
          errorMessage = 'Authentication failed. Please try again';
        } else if (errorString.contains('10')) {
          errorMessage = 'Configuration Error (Code 10)';
          detailedError = 'Verify SHA-1 certificate and OAuth client IDs in Google Cloud Console';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  errorMessage,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (detailedError != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    detailedError,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ],
            ),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                Text(
                  'Zyphora',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 48,
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 0,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Experience the flow',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 1,
                    color: Colors.black45,
                  ),
                ),
                const Spacer(),
                // Google Sign-In Button
                GestureDetector(
                  onTap: _isLoading ? null : _handleGoogleSignIn,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: _isLoading ? Colors.black26 : Colors.black12,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CupertinoActivityIndicator(
                              color: Colors.black,
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.network(
                                'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                                height: 24,
                                width: 24,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.g_mobiledata_rounded,
                                    size: 24,
                                    color: Colors.black87,
                                  );
                                },
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Continue with Google',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Sign in to save your progress',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Colors.black38,
                  ),
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
