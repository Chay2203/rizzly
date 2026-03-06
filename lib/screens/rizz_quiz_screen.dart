import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import '../services/api_service.dart';
import '../stores/main_store.dart';
import '../widgets/rizz_score_card.dart';
import 'testimonials_screen.dart';

class RizzQuizScreen extends StatefulWidget {
  final MainStore store;
  final String userId;

  const RizzQuizScreen({
    super.key,
    required this.store,
    required this.userId,
  });

  @override
  State<RizzQuizScreen> createState() => _RizzQuizScreenState();
}

class _RizzQuizScreenState extends State<RizzQuizScreen>
    with TickerProviderStateMixin {
  // Session state
  String? _sessionId;
  int _questionNumber = 0;
  int _totalQuestions = 5;
  String _questionText = '';
  String? _questionAudio;

  // UI state
  bool _isStarting = true;
  bool _isRecording = false;
  bool _isSubmitting = false;
  bool _showFeedback = false;
  bool _completed = false;
  String? _error;
  String? _aiFeedback;
  String? _feedbackAudio;
  String? _userResponse;
  Map<String, dynamic>? _assessment;

  // Audio
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _recordingPath;
  bool _isPlayingAudio = false;

  // Waveform
  final List<double> _amplitudeHistory = [];
  static const int _maxAmplitudeHistory = 60;
  Stream<Amplitude>? _amplitudeStream;

  // Animations
  late AnimationController _scoreController;
  late Animation<double> _scoreAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _scoreController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scoreAnimation = CurvedAnimation(
      parent: _scoreController,
      curve: Curves.easeOutCubic,
    );
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _startAssessment();
  }

  @override
  void dispose() {
    _scoreController.dispose();
    _fadeController.dispose();
    _recorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // ─── API CALLS ───

  Future<void> _startAssessment() async {
    setState(() {
      _isStarting = true;
      _error = null;
    });

    try {
      final response = await ApiService.startRizzAssessment();
      if (!mounted) return;

      setState(() {
        _sessionId = response['session_id'];
        _questionNumber = response['question_number'] ?? 1;
        _totalQuestions = response['total_questions'] ?? 5;
        _questionText = response['question_text'] ?? '';
        _questionAudio = response['question_audio'];
        _isStarting = false;
      });

      _fadeController.forward();
      _playQuestionAudio();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _isStarting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to start assessment. Please try again.';
        _isStarting = false;
      });
    }
  }

  Future<void> _submitAnswer(String audioPath) async {
    if (_sessionId == null) return;

    setState(() => _isSubmitting = true);

    try {
      final response = await ApiService.submitRizzAssessmentAnswer(
        sessionId: _sessionId!,
        audioFile: File(audioPath),
      );

      if (!mounted) return;

      final completed = response['completed'] == true;

      setState(() {
        _userResponse = response['user_response'];
        _aiFeedback = response['ai_feedback'];
        _feedbackAudio = response['feedback_audio'];
        _showFeedback = true;
        _isSubmitting = false;
        _completed = completed;

        if (!completed) {
          // Next question data is in the same response
          _questionText = response['question_text'] ?? '';
          _questionAudio = response['question_audio'];
          _questionNumber = response['question_number'] ?? _questionNumber + 1;
          _totalQuestions = response['total_questions'] ?? _totalQuestions;
        } else {
          _assessment = response['assessment'];
        }
      });

      _playFeedbackAudio();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _error = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _error = 'Failed to submit answer. Please try again.';
      });
    }
  }

  // ─── AUDIO PLAYBACK ───

  Future<void> _playQuestionAudio() async {
    if (_questionAudio == null || _questionAudio!.isEmpty) return;
    await _playBase64Audio(_questionAudio!);
  }

  Future<void> _playFeedbackAudio() async {
    if (_feedbackAudio == null || _feedbackAudio!.isEmpty) return;
    await _playBase64Audio(_feedbackAudio!);
  }

  Future<void> _playBase64Audio(String dataUri) async {
    try {
      setState(() => _isPlayingAudio = true);

      // Strip "data:audio/mpeg;base64," prefix
      final base64Data = dataUri.contains(',')
          ? dataUri.split(',').last
          : dataUri;

      final Uint8List bytes = base64Decode(base64Data);

      // Write to temp file and play
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/tts_${DateTime.now().millisecondsSinceEpoch}.mp3');
      await file.writeAsBytes(bytes);

      _audioPlayer.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _isPlayingAudio = false);
      });

      await _audioPlayer.play(DeviceFileSource(file.path));
    } catch (e) {
      debugPrint('[RizzQuiz] Audio playback error: $e');
      if (mounted) setState(() => _isPlayingAudio = false);
    }
  }

  // ─── RECORDING ───

  void _startAmplitudeListener() {
    _amplitudeHistory.clear();
    _amplitudeStream = _recorder.onAmplitudeChanged(
      const Duration(milliseconds: 50),
    );
    _amplitudeStream?.listen((amp) {
      if (mounted && _isRecording) {
        setState(() {
          final amplitude = ((amp.current + 60) / 60).clamp(0.0, 1.0);
          _amplitudeHistory.add(amplitude);
          if (_amplitudeHistory.length > _maxAmplitudeHistory) {
            _amplitudeHistory.removeAt(0);
          }
        });
      }
    });
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    try {
      // Stop any playing audio first
      await _audioPlayer.stop();

      final hasPermission = await _recorder.hasPermission();
      if (hasPermission) {
        final directory = await getTemporaryDirectory();
        _recordingPath =
            '${directory.path}/rizz_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _recorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: _recordingPath!,
        );

        setState(() => _isRecording = true);
        _startAmplitudeListener();
      } else {
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
    try {
      _amplitudeHistory.clear();
      final path = await _recorder.stop();
      setState(() => _isRecording = false);

      if (path != null) {
        await _submitAnswer(path);
      }
    } catch (e) {
      setState(() => _isRecording = false);
    }
  }

  // ─── NAVIGATION ───

  void _moveToNextQuestion() {
    if (_completed && _assessment != null) {
      // Show assessment results
      setState(() {
        _showFeedback = false;
      });
      _scoreController.forward();
    } else {
      // Move to next question
      _fadeController.reset();
      setState(() {
        _showFeedback = false;
        _aiFeedback = null;
        _feedbackAudio = null;
        _userResponse = null;
      });
      _fadeController.forward();
      _playQuestionAudio();
    }
  }

  void _continueToTestimonials() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            TestimonialsScreen(userId: widget.userId, store: widget.store),
      ),
    );
  }

  // ─── BUILD ───

  @override
  Widget build(BuildContext context) {
    if (_isStarting) return _buildLoadingView('Preparing your assessment...');
    if (_error != null && !_showFeedback) return _buildErrorView();
    if (_completed && !_showFeedback && _assessment != null) {
      return _buildResultView();
    }
    if (_showFeedback) return _buildFeedbackView();
    return _buildQuestionView();
  }

  // ─── LOADING VIEW ───

  Widget _buildLoadingView(String message) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CupertinoActivityIndicator(
                radius: 14,
                color: Color(0xFF006FD1),
              ),
              const SizedBox(height: 24),
              Opacity(
                opacity: 0.80,
                child: Text(
                  message,
                  style: GoogleFonts.instrumentSerif(
                    color: const Color(0xFF121212),
                    fontSize: 24,
                    fontWeight: FontWeight.w400,
                    height: 1.30,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Opacity(
                opacity: 0.50,
                child: Text(
                  'This will only take a moment',
                  style: TextStyle(
                    color: Color(0xFF121212),
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                    height: 1.60,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── ERROR VIEW ───

  Widget _buildErrorView() {
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonWidth = screenWidth > 343 ? 343.0 : screenWidth - 32;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Opacity(
                  opacity: 0.80,
                  child: Text(
                    'Oops',
                    style: TextStyle(
                      color: Color(0xFF121212),
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Opacity(
                  opacity: 0.50,
                  child: Text(
                    _error ?? 'Something went wrong.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF121212),
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                      height: 1.60,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: buttonWidth,
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _error = null);
                      _startAssessment();
                    },
                    child: Container(
                      height: 53,
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
                      child: const Center(
                        child: Text(
                          'Try again',
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
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _continueToTestimonials,
                  child: const Opacity(
                    opacity: 0.50,
                    child: Text(
                      'Skip for now',
                      style: TextStyle(
                        color: Color(0xFF121212),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── QUESTION VIEW (Voice Recording) ───

  Widget _buildQuestionView() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar + question count
            Padding(
              padding: const EdgeInsets.only(
                top: 20,
                left: 16,
                right: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: List.generate(_totalQuestions, (i) {
                      return Expanded(
                        child: Container(
                          height: 3,
                          margin: EdgeInsets.only(
                            right: i < _totalQuestions - 1 ? 6 : 0,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(1.5),
                            color: i < _questionNumber
                                ? const Color(0xFF121212)
                                : const Color(0xFF121212)
                                    .withValues(alpha: 0.15),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  Opacity(
                    opacity: 0.40,
                    child: Text(
                      '$_questionNumber of $_totalQuestions',
                      style: const TextStyle(
                        color: Color(0xFF121212),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Question Area
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 16),
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
              decoration: const BoxDecoration(color: Color(0xFFE3E3E3)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SizedBox(
                      width: 328,
                      child: Opacity(
                        opacity: 0.80,
                        child: Text(
                          _questionText,
                          style: GoogleFonts.instrumentSerif(
                            color: const Color(0xFF121212),
                            fontSize: 32,
                            fontWeight: FontWeight.w400,
                            height: 1.30,
                            letterSpacing: 0.72,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Opacity(
                    opacity: 0.30,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.lightbulb_outline,
                          size: 16,
                          color: Colors.black,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Speak naturally. Be yourself.',
                          style: GoogleFonts.dmSans(
                            color: Colors.black,
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            height: 1.30,
                            letterSpacing: 0.26,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Waveform when recording
            Expanded(
              child: _isRecording
                  ? Center(child: _buildWaveform())
                  : const SizedBox.shrink(),
            ),

            // Bottom Section with Mic
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  _buildRecordButton(),
                  const SizedBox(height: 10),
                  Opacity(
                    opacity: 0.30,
                    child: Text(
                      _isSubmitting
                          ? 'Analyzing...'
                          : (_isRecording
                              ? 'Tap to stop'
                              : 'Tap to speak'),
                      textAlign: TextAlign.center,
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
          ],
        ),
      ),
    );
  }

  Widget _buildWaveform() {
    return SizedBox(
      width: double.infinity,
      height: 120,
      child: CustomPaint(
        painter: _RizzWaveformPainter(
          amplitudes: List.from(_amplitudeHistory),
          maxBars: _maxAmplitudeHistory,
        ),
        size: Size.infinite,
      ),
    );
  }

  Widget _buildRecordButton() {
    return GestureDetector(
      onTap: _isSubmitting ? null : _toggleRecording,
      child: _isSubmitting
          ? Container(
              width: 72,
              height: 72,
              clipBehavior: Clip.antiAlias,
              decoration: ShapeDecoration(
                color: const Color(0xFFE0E0E0),
                shape: RoundedRectangleBorder(
                  side: const BorderSide(width: 1, color: Colors.white),
                  borderRadius: BorderRadius.circular(9999),
                ),
              ),
              child: const Center(
                child: CupertinoActivityIndicator(
                  radius: 14,
                  color: Colors.black54,
                ),
              ),
            )
          : Container(
              width: 72,
              height: 72,
              clipBehavior: Clip.antiAlias,
              decoration: ShapeDecoration(
                gradient: LinearGradient(
                  begin: const Alignment(0.00, 0.00),
                  end: const Alignment(0.69, 0.42),
                  colors: _isRecording
                      ? [const Color(0xFFFF6F91), const Color(0xFFFF4470)]
                      : [const Color(0xFF006FD1), const Color(0xFF006FD0)],
                ),
                shape: RoundedRectangleBorder(
                  side: const BorderSide(width: 1, color: Colors.white),
                  borderRadius: BorderRadius.circular(9999),
                ),
                shadows: [
                  BoxShadow(
                    color: _isRecording
                        ? const Color(0x4CFF6F91)
                        : const Color(0x4C006FD1),
                    blurRadius: 22.80,
                    offset: const Offset(0, 19),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Center(
                child: _isRecording
                    ? const Icon(
                        Icons.stop_rounded,
                        color: Colors.white,
                        size: 32,
                      )
                    : const Icon(
                        Icons.mic,
                        color: Colors.white,
                        size: 28,
                      ),
              ),
            ),
    );
  }

  // ─── FEEDBACK VIEW ───

  Widget _buildFeedbackView() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            Padding(
              padding: const EdgeInsets.only(
                top: 20,
                left: 16,
                right: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: List.generate(_totalQuestions, (i) {
                      return Expanded(
                        child: Container(
                          height: 3,
                          margin: EdgeInsets.only(
                            right: i < _totalQuestions - 1 ? 6 : 0,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(1.5),
                            color: i < _questionNumber
                                ? const Color(0xFF121212)
                                : const Color(0xFF121212)
                                    .withValues(alpha: 0.15),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  Opacity(
                    opacity: 0.40,
                    child: Text(
                      '${_completed ? _totalQuestions : _questionNumber - 1} of $_totalQuestions',
                      style: const TextStyle(
                        color: Color(0xFF121212),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Feedback content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(25),
                child: Column(
                  children: [
                    // User's transcribed response
                    if (_userResponse != null && _userResponse!.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Opacity(
                              opacity: 0.40,
                              child: Text(
                                'YOUR RESPONSE',
                                style: GoogleFonts.dmSans(
                                  color: const Color(0xFF121212),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _userResponse!,
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF121212),
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                height: 1.55,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // AI feedback card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: ShapeDecoration(
                        color:
                            const Color(0xFF006FD1).withValues(alpha: 0.05),
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            width: 2,
                            color: const Color(0xFF006FD1)
                                .withValues(alpha: 0.2),
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _isPlayingAudio
                                    ? Icons.volume_up
                                    : Icons.auto_awesome,
                                size: 18,
                                color: const Color(0xFF006FD1),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Feedback',
                                style: GoogleFonts.instrumentSerif(
                                  color: const Color(0xFF006FD1),
                                  fontSize: 20,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_aiFeedback != null)
                            Text(
                              _aiFeedback!,
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF006FD1),
                                fontSize: 14,
                                fontWeight: FontWeight.w300,
                                height: 1.60,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Next button
            Padding(
              padding: const EdgeInsets.fromLTRB(25, 0, 25, 36),
              child: GestureDetector(
                onTap: _moveToNextQuestion,
                child: Container(
                  width: double.infinity,
                  height: 53,
                  decoration: ShapeDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment(0.00, 0.00),
                      end: Alignment(0.69, 0.42),
                      colors: [Color(0xFF006FD1), Color(0xFF006FD0)],
                    ),
                    shape: RoundedRectangleBorder(
                      side:
                          const BorderSide(width: 1, color: Colors.white),
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
                      _completed ? 'See my results' : 'Next',
                      textAlign: TextAlign.center,
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
          ],
        ),
      ),
    );
  }

  // ─── RESULT VIEW ───

  Widget _buildResultView() {
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonWidth = screenWidth > 343 ? 343.0 : screenWidth - 32;

    final score = _assessment!['rizz_score'] as int? ?? 50;
    final summary = _assessment!['summary'] as String? ?? '';
    final areas = _assessment!['improvement_areas'] as List? ?? [];
    final ctaMessage = _assessment!['cta_message'] as String? ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(
                  top: 53,
                  left: 16,
                  right: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Shareable Rizz Score Card
                    RizzScoreCard(score: score),

                    const SizedBox(height: 24),

                    // Summary
                    Opacity(
                      opacity: 0.75,
                      child: Text(
                        summary,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF121212),
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          height: 1.55,
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Improvement areas header
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Opacity(
                        opacity: 0.40,
                        child: Text(
                          'WHERE TO IMPROVE',
                          style: TextStyle(
                            color: Color(0xFF121212),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Improvement area cards
                    ...areas.map((area) {
                      final areaMap = area as Map<String, dynamic>;
                      final areaName =
                          areaMap['area'] as String? ?? '';
                      final areaScore =
                          areaMap['score'] as int? ?? 50;
                      final tip = areaMap['tip'] as String? ?? '';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    areaName,
                                    style: const TextStyle(
                                      color: Color(0xFF121212),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      height: 1.3,
                                    ),
                                  ),
                                  Text(
                                    '$areaScore',
                                    style: TextStyle(
                                      color:
                                          _getScoreColor(areaScore),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(2),
                                child: AnimatedBuilder(
                                  animation: _scoreAnimation,
                                  builder: (context, _) {
                                    return LinearProgressIndicator(
                                      value:
                                          _scoreAnimation.value *
                                              areaScore /
                                              100,
                                      minHeight: 4,
                                      backgroundColor:
                                          const Color(0xFF121212)
                                              .withValues(
                                                  alpha: 0.06),
                                      valueColor:
                                          AlwaysStoppedAnimation<
                                              Color>(
                                        _getScoreColor(areaScore),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 10),
                              Opacity(
                                opacity: 0.55,
                                child: Text(
                                  tip,
                                  style: const TextStyle(
                                    color: Color(0xFF121212),
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w400,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                    // CTA message
                    if (ctaMessage.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF4E6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                Colors.black.withValues(alpha: 0.05),
                          ),
                        ),
                        child: Text(
                          ctaMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF121212),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            fontStyle: FontStyle.italic,
                            height: 1.50,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),

            // Continue button
            Padding(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: 36,
              ),
              child: Center(
                child: SizedBox(
                  width: buttonWidth,
                  child: GestureDetector(
                    onTap: _continueToTestimonials,
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
                          colors: [
                            Color(0xFF006FD1),
                            Color(0xFF006FD0)
                          ],
                        ),
                        shape: RoundedRectangleBorder(
                          side: const BorderSide(
                            width: 1,
                            color: Colors.white,
                          ),
                          borderRadius:
                              BorderRadius.circular(14998.50),
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
                      child: const Center(
                        child: Text(
                          'Continue',
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 65) return const Color(0xFF34A853);
    if (score >= 45) return const Color(0xFFE8A317);
    return const Color(0xFFE84B4B);
  }
}

// ─── WAVEFORM PAINTER ───

class _RizzWaveformPainter extends CustomPainter {
  final List<double> amplitudes;
  final int maxBars;

  _RizzWaveformPainter({required this.amplitudes, required this.maxBars});

  @override
  void paint(Canvas canvas, Size size) {
    if (amplitudes.isEmpty) {
      final paint = Paint()
        ..color = const Color(0xFF58B0FD).withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawLine(
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        paint,
      );
      return;
    }

    final barWidth = size.width / maxBars;
    final gap = barWidth * 0.3;
    final effectiveBarWidth = barWidth - gap;
    final centerY = size.height / 2;
    final maxBarHeight = size.height * 0.8;
    final minBarHeight = 4.0;

    final paint = Paint()..style = PaintingStyle.fill;

    final startIndex = maxBars - amplitudes.length;

    for (int i = 0; i < amplitudes.length; i++) {
      final amplitude = amplitudes[i];
      final barHeight = minBarHeight + (amplitude * maxBarHeight);

      final x = (startIndex + i) * barWidth + gap / 2;

      final color = Color.lerp(
        const Color(0xFF58B0FD),
        const Color(0xFF006FD1),
        amplitude,
      )!;

      paint.color = color;

      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(x + effectiveBarWidth / 2, centerY),
          width: effectiveBarWidth,
          height: barHeight,
        ),
        Radius.circular(effectiveBarWidth / 2),
      );

      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RizzWaveformPainter oldDelegate) {
    if (oldDelegate.amplitudes.length != amplitudes.length) return true;
    for (int i = 0; i < amplitudes.length; i++) {
      if (oldDelegate.amplitudes[i] != amplitudes[i]) return true;
    }
    return false;
  }
}
