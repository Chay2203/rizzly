import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'question_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userId;

  const HomeScreen({super.key, required this.userId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _questions = [];

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    debugPrint('📋 [HomeScreen] Loading questions...');
    debugPrint('   Token set: ${ApiService.token != null}');
    try {
      final data = await ApiService.getUnansweredQuestions();
      debugPrint('✅ [HomeScreen] Questions response: $data');
      if (mounted) {
        setState(() {
          _questions = data['questions'] ?? [];
        });
        debugPrint('   Loaded ${_questions.length} questions');
      }
    } catch (e) {
      debugPrint('❌ [HomeScreen] Error loading questions: $e');
    }
  }

  void _navigateToQuestions(String title) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuestionDetailScreen(
          categoryTitle: title,
          questions: _questions,
        ),
      ),
    ).then((_) {
      // Reload questions when coming back
      _loadQuestions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            // Title
            Text(
              'Rizzly',
              textAlign: TextAlign.center,
              style: GoogleFonts.instrumentSerif(
                fontSize: 48,
                fontWeight: FontWeight.w400,
                fontStyle: FontStyle.italic,
                letterSpacing: 0,
                color: Colors.black,
              ),
            ),

            const Spacer(),

            // Stacked Question Cards at bottom
            _buildStackedQuestionCards(),
          ],
        ),
      ),
    );
  }

  Widget _buildStackedQuestionCards() {
    final questionCards = [
      {'title': 'First Date.', 'subtitle': 'She is here: The challenge'},
      {'title': 'Getting along', 'subtitle': 'Finding her favorite dish'},
      {'title': 'Give "All of you"', 'subtitle': 'Nurture a bond lasting eternity'},
      {'title': 'Coming soon.', 'subtitle': '---------'},
    ];

    const double cardPeekHeight = 12.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Card 4 (bottom-most in z-order, rendered first)
              Positioned(
                left: 12,
                right: 12,
                bottom: -(cardPeekHeight * 3),
                child: _buildQuestionCard(
                  title: questionCards[3]['title']!,
                  subtitle: questionCards[3]['subtitle']!,
                  isActive: false,
                ),
              ),
              // Card 3
              Positioned(
                left: 8,
                right: 8,
                bottom: -(cardPeekHeight * 2),
                child: _buildQuestionCard(
                  title: questionCards[2]['title']!,
                  subtitle: questionCards[2]['subtitle']!,
                  isActive: false,
                ),
              ),
              // Card 2
              Positioned(
                left: 4,
                right: 4,
                bottom: -(cardPeekHeight * 1),
                child: _buildQuestionCard(
                  title: questionCards[1]['title']!,
                  subtitle: questionCards[1]['subtitle']!,
                  isActive: false,
                ),
              ),
              // Card 1 (top-most, rendered last = in front) - Clickable
              GestureDetector(
                onTap: () => _navigateToQuestions(
                  questionCards[0]['title']!,
                ),
                child: _buildQuestionCard(
                  title: questionCards[0]['title']!,
                  subtitle: questionCards[0]['subtitle']!,
                  isActive: true,
                ),
              ),
            ],
          ),
          // Space for the peeking cards
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildQuestionCard({
    required String title,
    required String subtitle,
    required bool isActive,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        shadows: const [
          BoxShadow(
            color: Color(0x19000000),
            blurRadius: 15.30,
            offset: Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Opacity(
                  opacity: 0.80,
                  child: Text(
                    title,
                    style: GoogleFonts.instrumentSerif(
                      color: const Color(0xFF121212),
                      fontSize: 32,
                      fontWeight: FontWeight.w400,
                      height: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Opacity(
                  opacity: 0.50,
                  child: Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF121212),
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                      height: 1.60,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 48,
            height: 48,
            decoration: ShapeDecoration(
              gradient: const LinearGradient(
                begin: Alignment(0.00, 0.00),
                end: Alignment(0.69, 0.42),
                colors: [Color(0xFF006FD1), Color(0xFF006FD0)],
              ),
              shape: RoundedRectangleBorder(
                side: const BorderSide(width: 1, color: Colors.white),
                borderRadius: BorderRadius.circular(24),
              ),
              shadows: const [
                BoxShadow(
                  color: Color(0x4C006FD1),
                  blurRadius: 22.80,
                  offset: Offset(0, 19),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}
