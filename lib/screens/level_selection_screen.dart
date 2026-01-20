import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../stores/main_store.dart';
import 'testimonials_screen.dart';

class LevelSelectionScreen extends StatefulWidget {
  final MainStore store;
  final String userId;

  const LevelSelectionScreen({
    super.key,
    required this.store,
    required this.userId,
  });

  @override
  State<LevelSelectionScreen> createState() => _LevelSelectionScreenState();
}

class _LevelSelectionScreenState extends State<LevelSelectionScreen> {
  void _continueToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            TestimonialsScreen(userId: widget.userId, store: widget.store),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive button width (max 343, but adapts to screen)
    final buttonWidth = screenWidth > 343 ? 343.0 : screenWidth - 32;
    final contentWidth = screenWidth > 278 ? 278.0 : screenWidth - 32;

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
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Title and subtitle
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: contentWidth,
                    child: Opacity(
                      opacity: 0.80,
                      child: Text(
                        'Beyond the Swipe.',
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
                    width: contentWidth,
                    child: Opacity(
                      opacity: 0.70,
                      child: Text(
                        'We train you for the real world.',
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
              ),

              const SizedBox(height: 28),

              // Features card
              SizedBox(
                width: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(
                        top: 20,
                        left: 20,
                        right: 12,
                        bottom: 20,
                      ),
                      clipBehavior: Clip.antiAlias,
                      decoration: ShapeDecoration(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.36),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Feature 1
                          _buildFeatureItem(
                            number: '1',
                            text:
                                'Practice "Scenario Simulations" for bars, events, and dates.',
                            maxWidth: screenWidth - 64, // Account for padding
                          ),
                          const SizedBox(height: 10),
                          // Feature 2
                          _buildFeatureItem(
                            number: '2',
                            text: 'Get instant "Conversation Depth" scores.',
                            maxWidth: screenWidth - 64,
                          ),
                          const SizedBox(height: 10),
                          // Feature 3
                          _buildFeatureItem(
                            number: '3',
                            text:
                                'Learn why it works, so you can do it without the app.',
                            maxWidth: screenWidth - 64,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Continue button
              Center(
                child: SizedBox(
                  width: buttonWidth,
                  child: GestureDetector(
                    onTap: _continueToHome,
                    child: Container(
                      height: 53,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 12,
                      ),
                      decoration: ShapeDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment(0.00, 0.00),
                          end: Alignment(0.69, 0.42),
                          colors: [Color(0xFF006FD1), Color(0xFF006FD0)],
                        ),
                        shape: RoundedRectangleBorder(
                          side: const BorderSide(width: 1, color: Colors.white),
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
                      child: Center(
                        child: Text(
                          'Continue',
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.visible,
                          style: const TextStyle(
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required String number,
    required String text,
    required double maxWidth,
  }) {
    return Container(
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: ShapeDecoration(
              color: const Color(0xFF0170D2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(691.62),
              ),
            ),
            child: Center(
              child: Text(
                number,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.46,
                  fontWeight: FontWeight.w500,
                  height: 1.40,
                  letterSpacing: 0.37,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Opacity(
              opacity: 0.50,
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 12.36,
                  fontWeight: FontWeight.w500,
                  height: 1.40,
                  letterSpacing: 0.37,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
