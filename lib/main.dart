import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/api_service.dart';
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
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    try {
      final isLoggedIn = await AuthService.isLoggedIn().timeout(
        const Duration(seconds: 2),
        onTimeout: () => false,
      );

      if (!mounted) return;

      if (isLoggedIn) {
        final userId = await AuthService.getUserId();
        if (!mounted) return;

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => HomeScreen(userId: userId ?? ''),
          ),
        );
      } else {
        _goToLanding();
      }
    } catch (e) {
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

  Future<void> _handleGetStarted() async {
    setState(() => _isLoading = true);

    try {
      final data = await ApiService.createUser();

      final user = data['user'];
      final token = data['token'];

      if (user == null || token == null) {
        throw Exception('Invalid response');
      }

      final userId = user['id']?.toString() ?? '';

      // Save session
      await AuthService.saveSession(token.toString(), userId);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(userId: userId),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
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
                GestureDetector(
                  onTap: _isLoading ? null : _handleGetStarted,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      color: _isLoading ? Colors.black54 : Colors.black,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CupertinoActivityIndicator(
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Get Started',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0,
                              color: Colors.white,
                            ),
                          ),
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
