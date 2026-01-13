import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/scenario_with_conversation.dart';
import '../stores/main_store.dart';
import '../services/auth_service.dart';
import '../main.dart';
import 'scenario_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userId;
  final MainStore store;

  const HomeScreen({super.key, required this.userId, required this.store});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Listen to store changes
    widget.store.addListener(_onStoreChanged);
    _loadScenarios();
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

  Future<void> _loadScenarios() async {
    await widget.store.loadScenarios();
  }

  Future<void> _handleLogout() async {
    debugPrint('[HomeScreen] Logout button tapped');
    await AuthService.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => LandingPage(store: widget.store)),
        (route) => false,
      );
    }
  }

  void _navigateToScenarioDetail(ScenarioWithConversation scenario) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ScenarioDetailScreen(scenario: scenario, store: widget.store),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with logout button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Logout button
                  GestureDetector(
                    onTap: _handleLogout,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.logout_rounded,
                        size: 18,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 36), // Balance the row
                ],
              ),
            ),
            const SizedBox(height: 8),
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

            const SizedBox(height: 20),

            // Scenarios List
            Expanded(child: _buildScenariosList()),
          ],
        ),
      ),
    );
  }

  Widget _buildScenariosList() {
    if (widget.store.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF006FD1)),
        ),
      );
    }

    if (widget.store.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error loading scenarios',
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadScenarios,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final scenarios = widget.store.scenarios;

    if (scenarios.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadScenarios,
        color: const Color(0xFF006FD1),
        child: ListView(
          padding: const EdgeInsets.all(40),
          children: [
            Center(
              child: Text(
                'No scenarios available',
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
              ),
            ),
          ],
        ),
      );
    }

    // Group scenarios by conversation status
    final active = widget.store.activeScenarios;
    final completed = widget.store.completedScenarios;
    final failed = widget.store.failedScenarios;
    final newScenarios = widget.store.newScenarios;

    return RefreshIndicator(
      onRefresh: _loadScenarios,
      color: const Color(0xFF006FD1),
      child: CustomScrollView(
        slivers: [
          // Active Scenarios Section
          if (active.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: _buildSectionHeader(
                  'Continue Your Journey',
                  Colors.blue.shade700,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) =>
                      _buildScenarioCard(active[index], 'active'),
                  childCount: active.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],

          // New Scenarios Section
          if (newScenarios.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: _buildSectionHeader(
                  'New Scenarios',
                  Colors.grey.shade800,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) =>
                      _buildScenarioCard(newScenarios[index], 'new'),
                  childCount: newScenarios.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],

          // Completed Scenarios Section
          if (completed.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: _buildSectionHeader(
                  'Passed Levels',
                  Colors.green.shade700,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) =>
                      _buildScenarioCard(completed[index], 'completed'),
                  childCount: completed.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],

          // Failed Scenarios Section
          if (failed.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: _buildSectionHeader('Try Again', Colors.red.shade700),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) =>
                      _buildScenarioCard(failed[index], 'failed'),
                  childCount: failed.length,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: GoogleFonts.instrumentSerif(
          fontSize: 20,
          fontWeight: FontWeight.w400,
          color: color,
        ),
      ),
    );
  }

  Widget _buildScenarioCard(
    ScenarioWithConversation scenario,
    String category,
  ) {
    Color cardColor;
    Color borderColor;

    switch (category) {
      case 'completed':
        cardColor = Colors.green.shade50;
        borderColor = Colors.green.shade300;
        break;
      case 'failed':
        cardColor = Colors.red.shade50;
        borderColor = Colors.red.shade300;
        break;
      case 'active':
        cardColor = Colors.blue.shade50;
        borderColor = Colors.blue.shade300;
        break;
      default:
        cardColor = Colors.white;
        borderColor = Colors.grey.shade300;
    }

    return GestureDetector(
      onTap: () => _navigateToScenarioDetail(scenario),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: ShapeDecoration(
          color: cardColor,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: borderColor, width: 1),
            borderRadius: BorderRadius.circular(4),
          ),
          shadows: const [
            BoxShadow(
              color: Color(0x19000000),
              blurRadius: 15.30,
              offset: Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Scenario Name
            Opacity(
              opacity: 0.80,
              child: Text(
                scenario.scenario.name,
                style: GoogleFonts.instrumentSerif(
                  color: const Color(0xFF121212),
                  fontSize: 22,
                  fontWeight: FontWeight.w400,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            // Girl Name only
            Opacity(
              opacity: 0.60,
              child: Text(
                scenario.girl.name,
                style: GoogleFonts.poppins(
                  color: const Color(0xFF121212),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.40,
                ),
              ),
            ),
            // End Goal if active
            if (category == 'active' &&
                scenario.conversation?.endGoal != null) ...[
              const SizedBox(height: 6),
              Opacity(
                opacity: 0.50,
                child: Text(
                  'Goal: ${scenario.conversation!.endGoal!.name}',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF121212),
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    height: 1.40,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
