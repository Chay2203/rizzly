import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import '../services/api_service.dart';
import '../stores/main_store.dart';

class ConversationScreen extends StatefulWidget {
  final String scenarioId;
  final String endGoalId;
  final String girlName;
  final MainStore store;

  const ConversationScreen({
    super.key,
    required this.scenarioId,
    required this.endGoalId,
    required this.girlName,
    required this.store,
  });

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen>
    with SingleTickerProviderStateMixin {
  bool _isRecording = false;
  bool _isSubmitting = false;
  bool _showFeedback = false;
  bool _conversationCompleted = false;
  bool _isLoadingQuestion = false;
  Map<String, dynamic>? _feedback;
  Map<String, dynamic>? _currentQuestion;

  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _recordingPath;

  late AnimationController _pulseController;

  // Audio amplitude for waveform
  final List<double> _amplitudeHistory = [];
  static const int _maxAmplitudeHistory = 60;
  Stream<Amplitude>? _amplitudeStream;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _loadQuestion();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _recorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadQuestion() async {
    debugPrint('[ConversationScreen] Loading question...');
    setState(() {
      _isLoadingQuestion = true;
    });

    try {
      final response = await ApiService.getQuestion(
        scenarioId: widget.scenarioId,
        endGoalId: widget.endGoalId,
      );

      debugPrint('[ConversationScreen] Question response: $response');

      if (response['conversation_completed'] == true) {
        setState(() {
          _conversationCompleted = true;
          _feedback = response;
          _showFeedback = true;
          _isLoadingQuestion = false;
        });
      } else {
        setState(() {
          _currentQuestion = response;
          _isLoadingQuestion = false;
        });
      }
    } catch (e) {
      debugPrint('[ConversationScreen] Error loading question: $e');
      setState(() {
        _isLoadingQuestion = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to load question'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    }
  }

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

      if (path != null) {
        await _submitAnswer(path);
      }
    } catch (e) {
      setState(() => _isRecording = false);
    }
  }

  Future<void> _submitAnswer(String audioPath) async {
    setState(() => _isSubmitting = true);

    try {
      debugPrint('[ConversationScreen] Submitting answer');

      final response = await ApiService.submitConversationAnswer(
        scenarioId: widget.scenarioId,
        endGoalId: widget.endGoalId,
        audioFile: File(audioPath),
      );

      debugPrint('[ConversationScreen] Answer submitted successfully');
      debugPrint('   Response: $response');

      setState(() {
        _feedback = response;
        _showFeedback = true;
        _isSubmitting = false;

        // Check if conversation is completed
        if (response['conversation_completed'] == true) {
          _conversationCompleted = true;
        }
      });
    } catch (e) {
      debugPrint('[ConversationScreen] Failed to submit answer: $e');
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

  void _nextQuestion() {
    debugPrint('[ConversationScreen] Moving to next question');

    if (_conversationCompleted) {
      // Mark conversation as completed in store and go back
      widget.store.markConversationCompleted('');
      Navigator.of(context).pop();
    } else {
      setState(() {
        _showFeedback = false;
        _feedback = null;
      });
      _loadQuestion();
    }
  }

  void _tryAgain() {
    // This is only used for the completion view "Try Again" button
    // which restarts the whole scenario
    widget.store.loadScenarios();
    Navigator.of(context).pop();
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
    final questionText = _currentQuestion?['message'] ?? '';

    return Column(
      children: [
        // Header
        _buildHeader(),

        // Question Area
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
          decoration: const BoxDecoration(color: Color(0xFFE3E3E3)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isLoadingQuestion)
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
              else
                SizedBox(
                  width: 328,
                  child: Opacity(
                    opacity: 0.80,
                    child: Text(
                      questionText,
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
          ),
        ),

        // Waveform when recording, otherwise spacer
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
                widget.girlName,
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
    if (_conversationCompleted) {
      return _buildCompletionView();
    }

    final feedbackVerdict = _feedback?['feedback_verdict'] ?? '';
    final isGood = feedbackVerdict.toLowerCase() == 'good';
    final feedbackText = _feedback?['feedback_text'] ?? '';
    final feedbackTitle = isGood ? '!! Brilliant Move !!' : 'Could Be Better';
    final statusScore = isGood ? 0.9 : 0.3;
    final questionText = _currentQuestion?['message'] ?? '';

    return Column(
      children: [
        // Header
        _buildHeader(),

        // Question Section
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
          decoration: const BoxDecoration(color: Color(0xFFE3E3E3)),
          child: SizedBox(
            width: 328,
            child: Opacity(
              opacity: 0.80,
              child: Text(
                questionText,
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

        // Feedback Card
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(25),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                top: 41,
                left: 20,
                right: 20,
                bottom: 20,
              ),
              decoration: ShapeDecoration(
                color: isGood
                    ? const Color(0xFF008972).withOpacity(0.05)
                    : const Color(0xFF006FD1).withOpacity(0.05),
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    width: 2,
                    color: isGood
                        ? const Color(0xFF008972).withOpacity(0.2)
                        : const Color(0xFF006FD1).withOpacity(0.2),
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: isGood
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.start,
                children: [
                  // Status Bar
                  _buildStatusBar(statusScore, isGood),
                  const SizedBox(height: 36),
                  // Feedback Title
                  Text(
                    feedbackTitle,
                    style: GoogleFonts.instrumentSerif(
                      color: isGood
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
                      textAlign: isGood ? TextAlign.center : TextAlign.start,
                      style: GoogleFonts.dmSans(
                        color: isGood
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
        ),

        // Action Button - Always show Next to move forward
        Padding(
          padding: const EdgeInsets.fromLTRB(25, 0, 25, 32),
          child: GestureDetector(
            onTap: _nextQuestion,
            child: _buildActionButton('Next →', Colors.black),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletionView() {
    final status = _feedback?['status'] ?? '';
    final goalAchieved = _feedback?['goal_achieved'] ?? false;
    final finalFeedback = _feedback?['final_feedback'] ?? '';
    final endGoalName = _feedback?['end_goal'] ?? '';

    final isSuccess = status == 'completed' && goalAchieved;

    return Column(
      children: [
        _buildHeader(),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                const SizedBox(height: 40),
                Icon(
                  isSuccess
                      ? Icons.celebration_outlined
                      : Icons.cancel_outlined,
                  size: 80,
                  color: isSuccess ? Colors.green : Colors.red,
                ),
                const SizedBox(height: 24),
                Text(
                  isSuccess ? 'Congratulations!' : 'Mission Failed',
                  style: GoogleFonts.instrumentSerif(
                    fontSize: 36,
                    fontWeight: FontWeight.w400,
                    color: isSuccess
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                  ),
                ),
                const SizedBox(height: 16),
                if (endGoalName.isNotEmpty)
                  Text(
                    isSuccess
                        ? 'Goal Achieved: $endGoalName'
                        : 'Goal: $endGoalName',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.black87,
                    ),
                  ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isSuccess
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSuccess
                          ? Colors.green.shade300
                          : Colors.red.shade300,
                    ),
                  ),
                  child: Text(
                    finalFeedback,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w300,
                      height: 1.60,
                      color: isSuccess
                          ? Colors.green.shade900
                          : Colors.red.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
          child: GestureDetector(
            onTap: isSuccess
                ? () {
                    widget.store.loadScenarios();
                    Navigator.of(context).pop();
                  }
                : _tryAgain,
            child: isSuccess
                ? _buildActionButton('Continue', Colors.green)
                : _buildActionButton('Try Again', Colors.red),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(String text, Color color) {
    // Determine colors based on color parameter
    Color backgroundColor;
    Color textColor;
    List<Color> gradientColors;

    if (color == Colors.black) {
      backgroundColor = Colors.black;
      textColor = Colors.white;
      gradientColors = [Colors.black, Colors.black];
    } else if (color == Colors.green) {
      backgroundColor = Colors.transparent;
      textColor = const Color(0xFFFFF7FB);
      gradientColors = [const Color(0xFF008972), const Color(0xFF047A66)];
    } else if (color == Colors.red) {
      backgroundColor = Colors.transparent;
      textColor = const Color(0xFFFFF7FB);
      gradientColors = [Colors.red.shade400, Colors.red.shade600];
    } else {
      backgroundColor = Colors.transparent;
      textColor = const Color(0xFFFFF7FB);
      gradientColors = [const Color(0xFF006FD1), const Color(0xFF006FD0)];
    }

    return Container(
      width: double.infinity,
      height: color == Colors.black ? 56 : 53,
      decoration: color == Colors.black
          ? BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            )
          : ShapeDecoration(
              gradient: LinearGradient(
                begin: const Alignment(0.00, 0.00),
                end: const Alignment(0.69, 0.42),
                colors: gradientColors,
              ),
              shape: RoundedRectangleBorder(
                side: const BorderSide(width: 1, color: Colors.white),
                borderRadius: BorderRadius.circular(9999),
              ),
              shadows: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 30.10,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: color == Colors.black
              ? GoogleFonts.instrumentSerif(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                )
              : GoogleFonts.poppins(
                  color: textColor,
                  fontSize: 19,
                  fontWeight: FontWeight.w500,
                ),
        ),
      ),
    );
  }

  Widget _buildStatusBar(double score, bool isGood) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final barWidth = constraints.maxWidth;
        final markerPosition = score * (barWidth - 103);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 45,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
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
                  Positioned(
                    left: markerPosition + 51.5,
                    top: 22,
                    child: Container(
                      width: 2,
                      height: 15,
                      color: const Color(0xFF6BB9FF),
                    ),
                  ),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Opacity(
                  opacity: isGood ? 0.30 : 0.80,
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
                  opacity: isGood ? 0.80 : 0.30,
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

// Reuse the waveform painter from question_detail_screen
class RealtimeWaveformPainter extends CustomPainter {
  final List<double> amplitudes;
  final int maxBars;

  RealtimeWaveformPainter({required this.amplitudes, required this.maxBars});

  @override
  void paint(Canvas canvas, Size size) {
    if (amplitudes.isEmpty) {
      final paint = Paint()
        ..color = const Color(0xFF58B0FD).withOpacity(0.3)
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
  bool shouldRepaint(covariant RealtimeWaveformPainter oldDelegate) {
    if (oldDelegate.amplitudes.length != amplitudes.length) return true;
    for (int i = 0; i < amplitudes.length; i++) {
      if (oldDelegate.amplitudes[i] != amplitudes[i]) return true;
    }
    return false;
  }
}
