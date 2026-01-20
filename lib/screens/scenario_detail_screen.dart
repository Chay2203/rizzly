import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/scenario_with_conversation.dart';
import '../models/conversation.dart';
import '../stores/main_store.dart';
import 'conversation_screen.dart';
import '../widgets/end_goal_bottom_sheet.dart';

class ScenarioDetailScreen extends StatefulWidget {
  final ScenarioWithConversation scenario;
  final MainStore store;

  const ScenarioDetailScreen({
    super.key,
    required this.scenario,
    required this.store,
  });

  @override
  State<ScenarioDetailScreen> createState() => _ScenarioDetailScreenState();
}

class _ScenarioDetailScreenState extends State<ScenarioDetailScreen> {
  bool get isActive => widget.scenario.hasActiveConversation;
  bool get isNew => widget.scenario.hasNoConversation;
  bool get isCompleted => widget.scenario.hasCompletedConversation;
  bool get isFailed => widget.scenario.hasFailedConversation;

  void _handleStartConversation() async {
    // Show end goal selection bottom sheet
    final selectedEndGoal = await showModalBottomSheet<EndGoal>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EndGoalBottomSheet(
        scenarioId: widget.scenario.scenario.id,
        store: widget.store,
      ),
    );

    if (selectedEndGoal != null && mounted) {
      // Navigate to conversation screen with the selected end goal
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ConversationScreen(
            scenarioId: widget.scenario.scenario.id,
            endGoalId: selectedEndGoal.id,
            girlName: widget.scenario.girl.name,
            store: widget.store,
          ),
        ),
      );
    }
  }

  void _handleContinueConversation() {
    // Navigate to conversation screen with existing end goal
    final conversation = widget.scenario.conversation;
    if (conversation?.endGoal != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ConversationScreen(
            scenarioId: widget.scenario.scenario.id,
            endGoalId: conversation!.endGoal!.id,
            girlName: widget.scenario.girl.name,
            store: widget.store,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scenario = widget.scenario.scenario;
    final girl = widget.scenario.girl;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
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
                        scenario.name,
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
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Scenario Description
                    Text(
                      'The Scene',
                      style: GoogleFonts.instrumentSerif(
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      scenario.description,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w300,
                        height: 1.60,
                        color: Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Girl Info
                    Text(
                      'Meet ${girl.name}',
                      style: GoogleFonts.instrumentSerif(
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      girl.description,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w300,
                        height: 1.60,
                        color: Colors.black87,
                      ),
                    ),
                    if (girl.personality != null &&
                        girl.personality!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.only(left: 16, top: 12, bottom: 12, right: 16),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade800),
                        ),
                        child: Text(
                          girl.personality!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.instrumentSerif(
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                            color: Colors.orange.shade800,
                          ),
                        ),
                      ),
                    ],

                    // End Goal (for active conversations)
                    if (isActive &&
                        widget.scenario.conversation?.endGoal != null) ...[
                      const SizedBox(height: 24),
                      Text(
                        'Your Goal',
                        style: GoogleFonts.instrumentSerif(
                          fontSize: 20,
                          fontWeight: FontWeight.w400,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.green.shade50,
                              Colors.green.shade100,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.flag_outlined,
                                  color: Colors.green.shade700,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  widget.scenario.conversation!.endGoal!.name,
                                  style: GoogleFonts.instrumentSerif(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.green.shade900,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget
                                  .scenario
                                  .conversation!
                                  .endGoal!
                                  .description,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w300,
                                color: Colors.green.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Message count
                      if (widget.scenario.conversation != null)
                        Text(
                          'Messages: ${widget.scenario.conversation!.messageCount}',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],

                    // Completion Feedback (for completed/failed)
                    if ((isCompleted || isFailed) &&
                        widget.scenario.conversation?.finalFeedback !=
                            null) ...[
                      const SizedBox(height: 24),
                      Text(
                        isCompleted ? 'Final Evaluation' : 'What Went Wrong',
                        style: GoogleFonts.instrumentSerif(
                          fontSize: 20,
                          fontWeight: FontWeight.w400,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isCompleted
                                ? Colors.green.shade300
                                : Colors.red.shade300,
                          ),
                        ),
                        child: Text(
                          widget.scenario.conversation!.finalFeedback!,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w300,
                            height: 1.60,
                            color: isCompleted
                                ? Colors.green.shade900
                                : Colors.red.shade900,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Action Button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: _buildActionButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    String buttonText;
    VoidCallback? onPressed;
    Color backgroundColor;
    Color textColor;
    Color? borderColor;

    if (isActive) {
      buttonText = 'Continue Conversation →';
      onPressed = _handleContinueConversation;
      backgroundColor = Colors.black;
      textColor = Colors.white;
      borderColor = null;
    } else if (isNew) {
      buttonText = 'Get Started';
      onPressed = _handleStartConversation;
      backgroundColor = Colors.black;
      textColor = Colors.white;
      borderColor = null;
    } else if (isFailed) {
      buttonText = 'Try Again';
      onPressed = _handleStartConversation;
      backgroundColor = Colors.red.shade50;
      textColor = Colors.red.shade700;
      borderColor = Colors.red.shade300;
    } else {
      // Completed
      buttonText = 'Completed ✓';
      onPressed = null;
      backgroundColor = Colors.green.shade50;
      textColor = Colors.green.shade700;
      borderColor = Colors.green.shade300;
    }

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(28),
          border: borderColor != null
              ? Border.all(color: borderColor, width: 1.5)
              : null,
          boxShadow: onPressed != null
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            buttonText,
            textAlign: TextAlign.center,
            style: GoogleFonts.instrumentSerif(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
