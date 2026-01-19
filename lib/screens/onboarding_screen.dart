import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../stores/main_store.dart';
import 'level_selection_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final MainStore store;
  final String userId;

  const OnboardingScreen({
    super.key,
    required this.store,
    required this.userId,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _completeOnboarding() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            LevelSelectionScreen(userId: widget.userId, store: widget.store),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(
            top: 53,
            left: 16,
            right: 16,
            bottom: 36,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo at top
              Container(
                width: 167,
                height: 167,
                padding: const EdgeInsets.symmetric(vertical: 31.73),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 60.12,
                      height: 60.12,
                      clipBehavior: Clip.antiAlias,
                      decoration: ShapeDecoration(
                        color: const Color(0xFF04001B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13.74),
                        ),
                      ),
                      child: Center(
                        child: Image.asset(
                          'assets/images/small_logo.png',
                          width: 60.12,
                          height: 60.12,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // PageView for onboarding content
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  children: [_buildPage1(), _buildPage2(), _buildPage3()],
                ),
              ),

              // Progress dots and button
              Column(
                children: [
                  // Progress lines
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      return Container(
                        width: 24,
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: _currentPage == index
                              ? const Color(0xFF121212)
                              : const Color(0xFF121212).withOpacity(0.3),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 28),
                  // Button
                  SizedBox(
                    width: screenWidth > 343 ? 343.0 : screenWidth - 32,
                    child: GestureDetector(
                      onTap: _nextPage,
                      child: Container(
                        height: 53,
                        padding: const EdgeInsets.all(15),
                        decoration: ShapeDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment(0.00, 0.00),
                            end: Alignment(0.69, 0.42),
                            colors: [Color(0xFF006FD1), Color(0xFF006FD0)],
                          ),
                          shape: RoundedRectangleBorder(
                            side: const BorderSide(
                              width: 1,
                              color: Colors.white,
                            ),
                            borderRadius: BorderRadius.circular(14998.50),
                          ),
                          shadows: const [
                            BoxShadow(
                              color: Color(0x4C006FD1),
                              blurRadius: 30.10,
                              offset: Offset(0, 14),
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              _getButtonText(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFFFFF7FB),
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
                  // Additional text for page 3
                  if (_currentPage == 2) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: screenWidth > 343 ? 343.0 : screenWidth - 32,
                      child: Opacity(
                        opacity: 0.70,
                        child: Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(
                                text: '124 MEN',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  height: 1.60,
                                ),
                              ),
                              const TextSpan(
                                text: ' LEVELING UP RIGHT NOW',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                  height: 1.60,
                                ),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getButtonText() {
    switch (_currentPage) {
      case 0:
        return 'Why does this happen?';
      case 1:
        return 'Show me the proof';
      case 2:
        return 'Continue';
      default:
        return 'Continue';
    }
  }

  Widget _buildPage1() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Opacity(
          opacity: 0.80,
          child: Text(
            '🥀',
            textAlign: TextAlign.center,
            style: GoogleFonts.instrumentSerif(
              color: const Color(0xFF121212),
              fontSize: 94,
              fontWeight: FontWeight.w400,
              height: 1,
            ),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: 236,
          child: Opacity(
            opacity: 0.80,
            child: Text(
              'Tired of the \'Nice Guy\' Zone?',
              textAlign: TextAlign.center,
              style: GoogleFonts.instrumentSerif(
                color: const Color(0xFF121212),
                fontSize: 32,
                fontWeight: FontWeight.w400,
                height: 1.30,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: 236,
          child: Opacity(
            opacity: 0.70,
            child: Text(
              'You follow the rules, but you still lose. We know why.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF121212),
                fontSize: 14,
                fontWeight: FontWeight.w300,
                height: 1.60,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPage2() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Opacity(
          opacity: 0.80,
          child: Text(
            '⚖️',
            textAlign: TextAlign.center,
            style: GoogleFonts.instrumentSerif(
              color: const Color(0xFF121212),
              fontSize: 94,
              fontWeight: FontWeight.w400,
              height: 1,
            ),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: 236,
          child: Opacity(
            opacity: 0.80,
            child: Text(
              'Attraction isn\'t luck. It\'s Physics.',
              textAlign: TextAlign.center,
              style: GoogleFonts.instrumentSerif(
                color: const Color(0xFF121212),
                fontSize: 32,
                fontWeight: FontWeight.w400,
                height: 1.30,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: 236,
          child: Opacity(
            opacity: 0.70,
            child: Text(
              '93% of men fail because they seek approval. Status is quiet.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF121212),
                fontSize: 14,
                fontWeight: FontWeight.w300,
                height: 1.60,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPage3() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Opacity(
          opacity: 0.80,
          child: Text(
            '🔥',
            textAlign: TextAlign.center,
            style: GoogleFonts.instrumentSerif(
              color: const Color(0xFF121212),
              fontSize: 94,
              fontWeight: FontWeight.w400,
              height: 1,
            ),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: 236,
          child: Opacity(
            opacity: 0.80,
            child: Text(
              'Don\'t practice on her.',
              textAlign: TextAlign.center,
              style: GoogleFonts.instrumentSerif(
                color: const Color(0xFF121212),
                fontSize: 32,
                fontWeight: FontWeight.w400,
                height: 1.30,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: 236,
          child: Opacity(
            opacity: 0.70,
            child: Text(
              'Make your mistakes here. Be perfect out there. 4.2x more second dates reported.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF121212),
                fontSize: 14,
                fontWeight: FontWeight.w300,
                height: 1.60,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
