import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../stores/main_store.dart';
import 'home_screen.dart';

class TestimonialsScreen extends StatefulWidget {
  final MainStore store;
  final String userId;

  const TestimonialsScreen({
    super.key,
    required this.store,
    required this.userId,
  });

  @override
  State<TestimonialsScreen> createState() => _TestimonialsScreenState();
}

class _TestimonialsScreenState extends State<TestimonialsScreen> {
  void _buildProfile() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            HomeScreen(userId: widget.userId, store: widget.store),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive button width (max 343, but adapts to screen)
    final buttonWidth = screenWidth > 343 ? 343.0 : screenWidth - 32;
    final contentWidth = screenWidth > 328 ? 328.0 : screenWidth - 32;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Star ratings and title
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Star ratings
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            return Container(
                              width: 26.86,
                              height: 26.86,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 6.715,
                              ),
                              child: SvgPicture.asset(
                                'assets/svgs/star.svg',
                                width: 26.86,
                                height: 26.86,
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: contentWidth,
                          child: Opacity(
                            opacity: 0.80,
                            child: Text(
                              '85% users love Rizzly.',
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
                      ],
                    ),

                    const SizedBox(height: 28),

                    // Stats cards
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 16,
                            ),
                            decoration: ShapeDecoration(
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.36),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: Text(
                                    '93%',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Color(0xFF0170D2),
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      height: 1,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: Opacity(
                                    opacity: 0.50,
                                    child: Text(
                                      'CONFIDENCE BOOST',
                                      textAlign: TextAlign.center,
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
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 16,
                            ),
                            decoration: ShapeDecoration(
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.36),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: Text(
                                    '4.2x',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Color(0xFF0170D2),
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      height: 1,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: Opacity(
                                    opacity: 0.50,
                                    child: Text(
                                      'MORE 2ND DATES',
                                      textAlign: TextAlign.center,
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
                          ),
                        ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),

            // Testimonials scrollable section (edge to edge)
            SizedBox(
              width: screenWidth,
              height: 156,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildTestimonialCard(
                    quote: '"Better than 10 years of therapy."',
                    author: '- Harry P., Bangalore',
                    width: screenWidth > 234 ? 234.0 : screenWidth - 64,
                  ),
                  const SizedBox(width: 8),
                  _buildTestimonialCard(
                    quote: '"Rizzly\'s insights are invaluable!"',
                    author: '- Mark T., London',
                    width: screenWidth > 234 ? 234.0 : screenWidth - 64,
                  ),
                  const SizedBox(width: 8),
                  _buildTestimonialCard(
                    quote: '"I used to freeze. Now I crave the tension."',
                    author: '- Sarah L., New York',
                    width: screenWidth > 234 ? 234.0 : screenWidth - 64,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Build my profile button
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 36),
              child: Center(
                child: SizedBox(
                  width: buttonWidth,
                  child: GestureDetector(
                    onTap: _buildProfile,
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
                          'Build my profile',
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestimonialCard({
    required String quote,
    required String author,
    required double width,
  }) {
    return Container(
      width: width,
      height: 156,
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: const Color(0xFFFFF4E6),
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 1.77, color: Colors.black.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.circular(12.36),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: width - 32,
            child: Opacity(
              opacity: 0.90,
              child: Text(
                quote,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 12.36,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w400,
                  height: 1.40,
                  letterSpacing: 0.37,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: width - 32,
            child: Opacity(
              opacity: 0.30,
              child: Text(
                author,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 12.36,
                  fontWeight: FontWeight.w600,
                  height: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
