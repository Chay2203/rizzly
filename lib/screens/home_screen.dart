import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/scenario_with_conversation.dart';
import '../stores/main_store.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
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
        MaterialPageRoute(builder: (_) => LoginScreen(store: widget.store)),
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
        bottom: false,
        child: Stack(
          children: [
            // Layer 1: Scrollable content (starts from top, scrolls under header)
            _buildScenariosList(topPadding: 52),
            // Layer 2: Top gradient fade (below header)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.4, 0.75, 1.0],
                      colors: [
                        Colors.white,
                        Colors.white.withValues(alpha: 0.95),
                        Colors.white.withValues(alpha: 0.5),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Layer 3: Bottom gradient fade
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      stops: const [0.0, 0.4, 0.75, 1.0],
                      colors: [
                        Colors.white,
                        Colors.white.withValues(alpha: 0.95),
                        Colors.white.withValues(alpha: 0.5),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Layer 4: Header (on top of everything)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Logo on top left
                  SvgPicture.asset(
                    'assets/svgs/logo.svg',
                    width: 36,
                    height: 36,
                  ),
                  // Logout button on top right
                  GestureDetector(
                    onTap: _handleLogout,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100.withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.logout_rounded,
                        size: 18,
                        color: Colors.grey.shade600,
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

  Widget _buildScenariosList({double topPadding = 0}) {
    if (widget.store.isLoading) {
      return Center(
        child: Padding(
          padding: EdgeInsets.only(top: topPadding),
          child: const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF006FD1)),
          ),
        ),
      );
    }

    if (widget.store.error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.only(top: topPadding),
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
        ),
      );
    }

    final scenarios = widget.store.scenarios;

    if (scenarios.isEmpty) {
      return CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: SizedBox(height: topPadding)),
          SliverFillRemaining(
            child: Center(
              child: Text(
                'No scenarios available',
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
              ),
            ),
          ),
        ],
      );
    }

    // Group scenarios by conversation status
    final active = widget.store.activeScenarios;
    final completed = widget.store.completedScenarios;
    final failed = widget.store.failedScenarios;
    final newScenarios = widget.store.newScenarios;

    return CustomScrollView(
      slivers: [
        // Top padding for header space
        SliverToBoxAdapter(child: SizedBox(height: topPadding)),

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
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildScenarioCard(active[index], 'active'),
                ),
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
              child: _buildSectionHeader('New Scenarios', Colors.grey.shade800),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildScenarioCard(newScenarios[index], 'new'),
                ),
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
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildScenarioCard(completed[index], 'completed'),
                ),
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
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildScenarioCard(failed[index], 'failed'),
                ),
                childCount: failed.length,
              ),
            ),
          ),
        ],
      ],
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
    final bool isActive = category == 'active';

    // Get subtitle - use description or challenge text
    String subtitle = scenario.scenario.description;
    if (category == 'active' && scenario.conversation?.endGoal != null) {
      subtitle = scenario.conversation!.endGoal!.name;
    }

    return GestureDetector(
      onTap: () => _navigateToScenarioDetail(scenario),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 100, 16),
            decoration: ShapeDecoration(
              color: Colors.white,
              shape: RoundedRectangleBorder(
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
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Opacity(
                  opacity: isActive ? 0.80 : 0.50,
                  child: Text(
                    scenario.scenario.name,
                    textAlign: TextAlign.left,
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
                  opacity: isActive ? 0.50 : 0.30,
                  child: Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF121212),
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                      height: 1.60,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 20,
            top: 0,
            bottom: 0,
            child: Center(
              child: Image.asset(
                'assets/images/blue_arrow.png',
                width: 50,
                height: 50,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
