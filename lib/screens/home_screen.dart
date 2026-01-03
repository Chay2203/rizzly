import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../main.dart';

class HomeScreen extends StatefulWidget {
  final String userId;

  const HomeScreen({super.key, required this.userId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  List<dynamic> _questions = [];
  int _currentQuestionIndex = 0;
  bool _isLoading = true;
  bool _isRecording = false;
  bool _isSubmitting = false;
  bool _showFeedback = false;
  Map<String, dynamic>? _feedback;

  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _recordingPath;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _loadQuestions();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _recorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await AuthService.signOut();
    if (mounted) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LandingPage()));
    }
  }

  Future<void> _loadQuestions() async {
    try {
      final data = await ApiService.getUnansweredQuestions();
      setState(() {
        _questions = data['questions'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to load questions'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    }
  }

  Future<void> _toggleRecording() async {
    debugPrint('Toggle recording: isRecording=$_isRecording');
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    debugPrint('Starting recording...');
    try {
      final hasPermission = await _recorder.hasPermission();
      debugPrint('Has permission: $hasPermission');

      if (hasPermission) {
        final directory = await getTemporaryDirectory();
        _recordingPath =
            '${directory.path}/answer_${DateTime.now().millisecondsSinceEpoch}.m4a';
        debugPrint('Recording path: $_recordingPath');

        await _recorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: _recordingPath!,
        );

        debugPrint('Recording started');
        setState(() => _isRecording = true);
      } else {
        debugPrint('No permission');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Microphone permission required'),
              backgroundColor: Colors.red.shade400,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Recording error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recording error: $e'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    debugPrint('Stopping recording...');
    try {
      final path = await _recorder.stop();
      debugPrint('Recording stopped, path: $path');
      setState(() => _isRecording = false);

      if (path != null && _questions.isNotEmpty) {
        await _submitAnswer(path);
      }
    } catch (e) {
      setState(() => _isRecording = false);
      debugPrint('Stop recording error: $e');
    }
  }

  Future<void> _submitAnswer(String audioPath) async {
    setState(() => _isSubmitting = true);

    try {
      final currentQuestion = _questions[_currentQuestionIndex];
      final response = await ApiService.submitAnswer(
        questionId: currentQuestion['id'],
        audioFile: File(audioPath),
      );

      setState(() {
        _feedback = response;
        _showFeedback = true;
        _isSubmitting = false;
      });

      // Play feedback audio if available
      if (response['feedback_audio'] != null) {
        await _playFeedbackAudio(response['feedback_audio']);
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to submit answer'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    }
  }

  Future<void> _playFeedbackAudio(String base64Audio) async {
    try {
      final audioData = base64Audio.split(',').last;
      final bytes = base64Decode(audioData);
      final directory = await getTemporaryDirectory();
      final audioFile = File('${directory.path}/feedback.mp3');
      await audioFile.writeAsBytes(bytes);
      await _audioPlayer.play(DeviceFileSource(audioFile.path));
    } catch (e) {
      // Silently fail audio playback
    }
  }

  void _nextQuestion() {
    setState(() {
      _showFeedback = false;
      _feedback = null;
      if (_currentQuestionIndex < _questions.length - 1) {
        _currentQuestionIndex++;
      } else {
        _questions = [];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _showFeedback ? _buildFeedbackLayout() : _buildQuestionLayout(),
      ),
    );
  }

  Widget _buildQuestionLayout() {
    return Column(
      children: [
        const SizedBox(height: 16),
        // Top bar with logout
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: _logout,
                child: Text(
                  'Logout',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black45,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Title
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

        const Spacer(),

        // Orb
        SizedBox(
          width: 200,
          height: 200,
          child: Image.asset('assets/orb.png', fit: BoxFit.contain),
        ),

        const SizedBox(height: 40),

        // Question or Status
        SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: _buildContent(),
          ),
        ),

        const Spacer(),

        // Recording Button
        if (!_isLoading && _questions.isNotEmpty && !_showFeedback)
          _buildRecordButton(),

        const SizedBox(height: 60),
      ],
    );
  }

  Widget _buildFeedbackLayout() {
    return Column(
      children: [
        const SizedBox(height: 16),
        // Top bar with logout
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: _logout,
                child: Text(
                  'Logout',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black45,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Title
        Text(
          'Zyphora',
          textAlign: TextAlign.center,
          style: GoogleFonts.playfairDisplay(
            fontSize: 36,
            fontWeight: FontWeight.w500,
            fontStyle: FontStyle.italic,
            letterSpacing: 0,
            color: Colors.black,
          ),
        ),

        const SizedBox(height: 24),

        // Feedback Content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: _buildFeedbackCard(),
          ),
        ),

        const SizedBox(height: 24),

        // Next/Retry Button
        _buildNextButton(),

        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Column(
        children: [
          const CupertinoActivityIndicator(radius: 14),
          const SizedBox(height: 16),
          Text(
            'Loading questions...',
            style: GoogleFonts.inter(fontSize: 15, color: Colors.black45),
          ),
        ],
      );
    }

    if (_questions.isEmpty) {
      return Column(
        children: [
          Text(
            'All caught up!',
            style: GoogleFonts.playfairDisplay(
              fontSize: 24,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No more questions for now',
            style: GoogleFonts.inter(fontSize: 15, color: Colors.black45),
          ),
        ],
      );
    }

    if (_showFeedback && _feedback != null) {
      return _buildFeedbackCard();
    }

    if (_isSubmitting) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const CupertinoActivityIndicator(radius: 14),
          const SizedBox(height: 16),
          Text(
            'Analyzing your response...',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 15, color: Colors.black45),
          ),
        ],
      );
    }

    // Show current question
    final currentQuestion = _questions[_currentQuestionIndex];
    return Column(
      children: [
        Text(
          currentQuestion['text'],
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.5,
            color: Colors.black87,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _isRecording ? 'Tap to stop' : 'Tap to record',
          style: GoogleFonts.inter(fontSize: 14, color: Colors.black38),
        ),
      ],
    );
  }

  Widget _buildFeedbackCard() {
    final isPass = _feedback!['verdict'] == 'PASS';
    final userResponse = _feedback!['user_response'] ?? '';
    final feedbackText = _feedback!['feedback_text'] ?? '';
    final question = _feedback!['question'] ?? '';

    return SingleChildScrollView(
      child: Column(
        children: [
          // Verdict Icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isPass ? Colors.green.shade100 : Colors.orange.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPass ? Icons.check_rounded : Icons.refresh_rounded,
              size: 32,
              color: isPass ? Colors.green.shade700 : Colors.orange.shade700,
            ),
          ),
          const SizedBox(height: 16),

          // Verdict Text
          Text(
            isPass ? 'Great Response!' : 'Try Again',
            style: GoogleFonts.playfairDisplay(
              fontSize: 24,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
              letterSpacing: -0.5,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 24),

          // Question
          if (question.isNotEmpty) ...[
            Text(
              'Question',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
                color: Colors.black38,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              question,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.3,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Your Response
          if (userResponse.isNotEmpty) ...[
            Text(
              'Your Response',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
                color: Colors.black38,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '"$userResponse"',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  letterSpacing: -0.2,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // AI Feedback
          if (feedbackText.isNotEmpty) ...[
            Text(
              'Feedback',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
                color: Colors.black38,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isPass ? Colors.green.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isPass
                      ? Colors.green.shade200
                      : Colors.orange.shade200,
                ),
              ),
              child: Text(
                feedbackText,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  letterSpacing: -0.2,
                  color: isPass
                      ? Colors.green.shade800
                      : Colors.orange.shade800,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecordButton() {
    return GestureDetector(
      onTap: () {
        debugPrint('Mic button tapped!');
        _toggleRecording();
      },
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final scale = _isRecording
              ? 1.0 + (_pulseController.value * 0.1)
              : 1.0;
          return Transform.scale(
            scale: scale,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _isRecording ? Colors.red : Colors.black,
                shape: BoxShape.circle,
                boxShadow: _isRecording
                    ? [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                _isRecording ? Icons.stop_rounded : Icons.mic,
                color: Colors.white,
                size: 32,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNextButton() {
    final isPass = _feedback?['verdict'] == 'PASS';

    return GestureDetector(
      onTap: isPass
          ? _nextQuestion
          : () => setState(() => _showFeedback = false),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          isPass ? 'Next Question' : 'Try Again',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
