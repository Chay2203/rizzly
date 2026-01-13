import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../stores/main_store.dart';

class EndGoalBottomSheet extends StatefulWidget {
  final String scenarioId;
  final MainStore store;

  const EndGoalBottomSheet({
    super.key,
    required this.scenarioId,
    required this.store,
  });

  @override
  State<EndGoalBottomSheet> createState() => _EndGoalBottomSheetState();
}

class _EndGoalBottomSheetState extends State<EndGoalBottomSheet> {
  String? _selectedEndGoalId;

  @override
  void initState() {
    super.initState();
    // Listen to store changes
    widget.store.addListener(_onStoreChanged);
    // Load end goals if not already loaded
    if (widget.store.endGoals.isEmpty && !widget.store.isLoadingEndGoals) {
      widget.store.loadEndGoals();
    }
  }

  @override
  void dispose() {
    widget.store.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _submitEndGoal() async {
    if (_selectedEndGoalId == null) return;

    try {
      // Submit the end goal
      await ApiService.submitEndGoal(
        scenarioId: widget.scenarioId,
        endGoalId: _selectedEndGoalId!,
      );

      if (mounted) {
        // Return the selected end goal
        final selectedGoal = widget.store.endGoals.firstWhere(
          (g) => g.id == _selectedEndGoalId,
        );
        Navigator.of(context).pop(selectedGoal);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to set goal: $e'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Text(
                'Choose Your Goal',
                style: GoogleFonts.instrumentSerif(
                  fontSize: 28,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),
            ),

            // Content
            if (widget.store.isLoadingEndGoals)
              const Padding(
                padding: EdgeInsets.all(40),
                child: CupertinoActivityIndicator(),
              )
            else if (widget.store.endGoalsError != null)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      'Failed to load goals',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => widget.store.loadEndGoals(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            else if (widget.store.endGoals.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No goals available',
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: widget.store.endGoals.length,
                  itemBuilder: (context, index) {
                    final goal = widget.store.endGoals[index];
                    final isSelected = _selectedEndGoalId == goal.id;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedEndGoalId = goal.id;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.black.withOpacity(0.05)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.black
                                  : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Selection indicator
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.black
                                        : Colors.grey.shade400,
                                    width: 2,
                                  ),
                                  color: isSelected
                                      ? Colors.black
                                      : Colors.transparent,
                                ),
                                child: isSelected
                                    ? const Icon(
                                        Icons.check,
                                        size: 16,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 16),

                              // Goal info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          goal.name,
                                          style: GoogleFonts.instrumentSerif(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        _buildDifficultyChip(goal.difficulty),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      goal.description,
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w300,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

            // Submit button
            if (!widget.store.isLoadingEndGoals &&
                widget.store.endGoalsError == null &&
                widget.store.endGoals.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: GestureDetector(
                  onTap: _selectedEndGoalId != null ? _submitEndGoal : null,
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _selectedEndGoalId != null
                          ? Colors.black
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: _selectedEndGoalId != null
                          ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        'Start Conversation',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.instrumentSerif(
                          color: _selectedEndGoalId != null
                              ? Colors.white
                              : Colors.grey.shade600,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
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

  Widget _buildDifficultyChip(String difficulty) {
    MaterialColor color;
    String label;

    switch (difficulty.toLowerCase()) {
      case 'easy':
        color = Colors.green;
        label = 'Easy';
        break;
      case 'medium':
        color = Colors.orange;
        label = 'Medium';
        break;
      case 'hard':
        color = Colors.red;
        label = 'Hard';
        break;
      default:
        color = Colors.grey;
        label = difficulty;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color[700],
        ),
      ),
    );
  }
}
