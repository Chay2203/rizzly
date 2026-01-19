import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import '../services/api_service.dart';

class QuestionDetailScreen extends StatefulWidget {
  final String categoryTitle;
  final List<dynamic> questions;

  const QuestionDetailScreen({
    super.key,
    required this.categoryTitle,
    required this.questions,
  });

  @override
  State<QuestionDetailScreen> createState() => _QuestionDetailScreenState();
}

class _QuestionDetailScreenState extends State<QuestionDetailScreen>
    with SingleTickerProviderStateMixin {
  int _currentQuestionIndex = 0;
  bool _isRecording = false;
  bool _isSubmitting = false;
  bool _showFeedback = false;
  bool _isLoadingNextQuestion = false;
  Map<String, dynamic>? _feedback;

  // Mutable list of questions - removes answered ones
  late List<dynamic> _questions;

  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _recordingPath;

  late AnimationController _pulseController;

  // Audio amplitude for waveform - stores history for real-time visualization
  final List<double> _amplitudeHistory = [];
  static const int _maxAmplitudeHistory = 60; // Number of bars to display
  Stream<Amplitude>? _amplitudeStream;

  @override
  void initState() {
    super.initState();
    // Create a mutable copy of questions
    _questions = List.from(widget.questions);
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _recorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _startAmplitudeListener() {
    // Clear history when starting new recording
    _amplitudeHistory.clear();

    _amplitudeStream = _recorder.onAmplitudeChanged(
      const Duration(milliseconds: 50), // Faster updates for smoother waveform
    );
    _amplitudeStream?.listen((amp) {
      if (mounted && _isRecording) {
        setState(() {
          // Convert dB to 0-1 range (dB typically ranges from -60 to 0)
          final amplitude = ((amp.current + 60) / 60).clamp(0.0, 1.0);

          // Add new amplitude to history
          _amplitudeHistory.add(amplitude);

          // Keep history limited to max size
          if (_amplitudeHistory.length > _maxAmplitudeHistory) {
            _amplitudeHistory.removeAt(0);
          }
        });
      }
    });
  }

  void _stopAmplitudeListener() {
    _amplitudeHistory.clear();
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
      final hasPermission = await _recorder.hasPermission();
      if (hasPermission) {
        final directory = await getTemporaryDirectory();
        _recordingPath =
            '${directory.path}/answer_${DateTime.now().millisecondsSinceEpoch}.m4a';

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
      _stopAmplitudeListener();
      final path = await _recorder.stop();
      setState(() => _isRecording = false);

      if (path != null && _questions.isNotEmpty) {
        await _submitAnswer(path);
      }
    } catch (e) {
      setState(() => _isRecording = false);
    }
  }

  Future<void> _submitAnswer(String audioPath) async {
    setState(() => _isSubmitting = true);

    try {
      final currentQuestion = _questions[_currentQuestionIndex];
      debugPrint(
        '[QuestionDetail] Submitting answer for question: ${currentQuestion['id']}',
      );

      final response = await ApiService.submitAnswer(
        questionId: currentQuestion['id'],
        audioFile: File(audioPath),
      );

      debugPrint('[QuestionDetail] Answer submitted successfully');
      debugPrint('   Response: $response');

      setState(() {
        _feedback = response;
        _showFeedback = true;
        _isSubmitting = false;
      });

      if (response['feedback_audio'] != null) {
        await _playFeedbackAudio(response['feedback_audio']);
      }
    } catch (e) {
      debugPrint('[QuestionDetail] Failed to submit answer: $e');
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
    debugPrint('[QuestionDetail] Moving to next question');
    debugPrint(
      '   Current index: $_currentQuestionIndex, Total: ${_questions.length}',
    );

    setState(() {
      _showFeedback = false;
      _feedback = null;
      _isLoadingNextQuestion = true;
    });

    // Brief delay to show loading state, then transition
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      setState(() {
        // Remove the answered question from the list
        if (_questions.isNotEmpty) {
          final removedQuestion = _questions.removeAt(_currentQuestionIndex);
          debugPrint('   Removed question: ${removedQuestion['id']}');
        }

        // Check if there are more questions
        if (_questions.isEmpty) {
          debugPrint('   No more questions, going back to home');
          Navigator.of(context).pop();
        } else {
          // Adjust index if needed (stay at same index since we removed one)
          if (_currentQuestionIndex >= _questions.length) {
            _currentQuestionIndex = _questions.length - 1;
          }
          debugPrint('   Remaining questions: ${_questions.length}');
          _isLoadingNextQuestion = false;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _showFeedback ? _buildFeedbackView() : _buildQuestionView(),
      ),
    );
  }

  Widget _buildQuestionView() {
    final currentQuestion = _questions.isNotEmpty
        ? _questions[_currentQuestionIndex]
        : null;

    return Column(
      children: [
        // Header
        _buildHeader(),

        // Scrollable content including question
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
        // Question Area
        Container(
          width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 32,
                  ),
          decoration: const BoxDecoration(color: Color(0xFFE3E3E3)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isLoadingNextQuestion)
                SizedBox(
                  width: 328,
                  child: Opacity(
                    opacity: 0.80,
                    child: Text(
                      'Loading next question...',
                      style: GoogleFonts.instrumentSerif(
                        color: const Color(0xFF121212),
                        fontSize: 32,
                        fontWeight: FontWeight.w400,
                        height: 1.30,
                        letterSpacing: 0.72,
                      ),
                    ),
                  ),
                )
              else if (currentQuestion != null) ...[
                SizedBox(
                  width: 328,
                  child: Opacity(
                    opacity: 0.80,
                    child: Text(
                              currentQuestion['text'] ??
                                  'No question available',
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
                        'Think less. Don\'t defend. Just play.',
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
            ],
          ),
        ),

                // Waveform when recording
                if (_isRecording)
                  SizedBox(height: 200, child: Center(child: _buildWaveform())),

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
                      ? 'Analyzing'
                      : (_isRecording ? 'Tap to stop' : 'Tap to speak'),
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
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(Icons.arrow_back, color: Colors.black54),
          ),
          Expanded(
            child: Opacity(
              opacity: 0.80,
              child: Text(
                widget.categoryTitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.instrumentSerif(
                  color: const Color(0xFF121212),
                  fontSize: 24,
                  fontWeight: FontWeight.w400,
                  height: 1.60,
                ),
              ),
            ),
          ),
          const SizedBox(width: 24), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildWaveform() {
    return SizedBox(
      width: double.infinity,
      height: 120,
      child: CustomPaint(
        painter: RealtimeWaveformPainter(
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
          : AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final scale = _isRecording
                    ? 1.0 + (_pulseController.value * 0.1)
                    : 1.0;
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 72,
                    height: 72,
                    clipBehavior: Clip.antiAlias,
                    decoration: ShapeDecoration(
                      gradient: LinearGradient(
                        begin: const Alignment(0.00, 0.00),
                        end: const Alignment(0.69, 0.42),
                        colors: _isRecording
                            ? [const Color(0xFFFF6F91), const Color(0xFFFF4470)]
                            : [
                                const Color(0xFF006FD1),
                                const Color(0xFF006FD0),
                              ],
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
                          : SvgPicture.asset(
                              'assets/svgs/record.svg',
                              width: 26,
                              height: 26,
                              colorFilter: const ColorFilter.mode(
                                Colors.white,
                                BlendMode.srcIn,
                              ),
                            ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildFeedbackView() {
    final isPass = _feedback?['verdict'] == 'PASS';
    final feedbackText = _feedback?['feedback_text'] ?? '';
    final feedbackTitle = isPass ? '!! Brilliant Move !!' : 'Noisy';
    final statusScore = isPass ? 0.9 : 0.1;
    final currentQuestion = _questions.isNotEmpty
        ? _questions[_currentQuestionIndex]
        : null;

    return Column(
      children: [
        // Header with title and tags
        _buildFeedbackHeader(),

        // Scrollable content including question and feedback
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
        // Question Section
        Container(
          width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 32,
                  ),
          decoration: const BoxDecoration(color: Color(0xFFE3E3E3)),
          child: SizedBox(
            width: 328,
            child: Opacity(
              opacity: 0.80,
              child: Text(
                currentQuestion?['text'] ?? '',
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

                // Feedback Card - wrapped in similar container style
                Container(
                  width: double.infinity,
            padding: const EdgeInsets.all(25),
                  color: Colors.white,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                top: 41,
                left: 20,
                right: 20,
                bottom: 20,
              ),
              decoration: ShapeDecoration(
                color: isPass
                    ? const Color(0xFF008972).withValues(alpha: 0.05)
                    : const Color(0xFF006FD1).withValues(alpha: 0.05),
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    width: 2,
                    color: isPass
                        ? const Color(0xFF008972).withValues(alpha: 0.2)
                        : const Color(0xFF006FD1).withValues(alpha: 0.2),
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: isPass
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.start,
                children: [
                  // Status Bar
                  _buildStatusBar(statusScore, isPass),
                  const SizedBox(height: 36),
                  // Feedback Title
                  Text(
                    feedbackTitle,
                    style: GoogleFonts.instrumentSerif(
                      color: isPass
                          ? const Color(0xFF008972)
                          : const Color(0xFF006FD1),
                      fontSize: 24,
                      fontWeight: FontWeight.w400,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Feedback Text
                  if (feedbackText.isNotEmpty)
                    Text(
                      feedbackText,
                            textAlign: isPass
                                ? TextAlign.center
                                : TextAlign.start,
                      style: GoogleFonts.dmSans(
                        color: isPass
                            ? const Color(0xFF008972)
                            : const Color(0xFF006FD1),
                        fontSize: 14,
                        fontWeight: FontWeight.w300,
                        height: 1.60,
                      ),
                    ),
                ],
            ),
          ),
        ),

        // Try Again / Next Button
                Container(
                  width: double.infinity,
          padding: const EdgeInsets.fromLTRB(25, 0, 25, 32),
                  color: Colors.white,
          child: GestureDetector(
            onTap: isPass
                ? _nextQuestion
                : () => setState(() => _showFeedback = false),
            child: isPass
                ? Container(
                    width: double.infinity,
                    height: 53,
                    decoration: ShapeDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment(0.00, 0.00),
                        end: Alignment(0.69, 0.42),
                        colors: [Color(0xFF008972), Color(0xFF047A66)],
                      ),
                      shape: RoundedRectangleBorder(
                                side: const BorderSide(
                                  width: 1,
                                  color: Colors.white,
                                ),
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      shadows: const [
                        BoxShadow(
                          color: Color(0x4C008972),
                          blurRadius: 30.10,
                          offset: Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'Next moment →',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: const Color(0xFFFFF7FB),
                          fontSize: 19,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                : Container(
                    width: double.infinity,
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
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      shadows: const [
                        BoxShadow(
                          color: Color(0x4C006FD1),
                          blurRadius: 30.10,
                          offset: Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'Try again',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: const Color(0xFFFFF7FB),
                          fontSize: 19,
                          fontWeight: FontWeight.w500,
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
      ],
    );
  }

  Widget _buildFeedbackHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(Icons.arrow_back, color: Colors.black54),
          ),
          Expanded(
            child: Opacity(
              opacity: 0.80,
              child: Text(
                widget.categoryTitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.instrumentSerif(
                  color: const Color(0xFF121212),
                  fontSize: 24,
                  fontWeight: FontWeight.w400,
                  height: 1.60,
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
        ],
      ),
    );
  }

  Widget _buildStatusBar(double score, bool isPass) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final barWidth = constraints.maxWidth;
        final markerPosition = score * (barWidth - 103); // 103 is label width

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status bar with marker
            SizedBox(
              height: 45,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // "YOUR RESPONSE" label
                  Positioned(
                    left: markerPosition,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: ShapeDecoration(
                        color: const Color(0xFF6BB9FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: Text(
                        'YOUR RESPONSE',
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          height: 1.60,
                        ),
                      ),
                    ),
                  ),
                  // Vertical marker line
                  Positioned(
                    left: markerPosition + 51.5, // Center of label
                    top: 22,
                    child: Container(
                      width: 2,
                      height: 15,
                      color: const Color(0xFF6BB9FF),
                    ),
                  ),
                  // Gradient bar
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 37,
                    child: Container(
                      height: 5,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment(0.00, 0.50),
                          end: Alignment(1.00, 0.50),
                          colors: [Color(0xFFEEEEEE), Color(0xFF004B3E)],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Labels
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Opacity(
                  opacity: isPass ? 0.30 : 0.80,
                  child: Text(
                    'Low Status',
                    style: GoogleFonts.playfairDisplay(
                      color: const Color(0xFF121212),
                      fontSize: 13,
                      fontWeight: FontWeight.w300,
                      height: 1.60,
                    ),
                  ),
                ),
                Opacity(
                  opacity: isPass ? 0.80 : 0.30,
                  child: Text(
                    'High Status',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.playfairDisplay(
                      color: const Color(0xFF121212),
                      fontSize: 13,
                      fontWeight: FontWeight.w300,
                      height: 1.60,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class RealtimeWaveformPainter extends CustomPainter {
  final List<double> amplitudes;
  final int maxBars;

  RealtimeWaveformPainter({required this.amplitudes, required this.maxBars});

  @override
  void paint(Canvas canvas, Size size) {
    if (amplitudes.isEmpty) {
      // Draw a flat line when no audio data
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

    // Calculate starting position to right-align the bars (new bars appear on right)
    final startIndex = maxBars - amplitudes.length;

    for (int i = 0; i < amplitudes.length; i++) {
      final amplitude = amplitudes[i];
      final barHeight = minBarHeight + (amplitude * maxBarHeight);

      // Position from left, offset by how many empty slots there are
      final x = (startIndex + i) * barWidth + gap / 2;

      // Create gradient effect based on amplitude
      final color = Color.lerp(
        const Color(0xFF58B0FD),
        const Color(0xFF006FD1),
        amplitude,
      )!;

      paint.color = color;

      // Draw rounded rectangle bar centered vertically
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
  bool shouldRepaint(covariant RealtimeWaveformPainter oldDelegate) {
    if (oldDelegate.amplitudes.length != amplitudes.length) return true;
    for (int i = 0; i < amplitudes.length; i++) {
      if (oldDelegate.amplitudes[i] != amplitudes[i]) return true;
    }
    return false;
  }
}
