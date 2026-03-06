import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class RizzScoreCard extends StatefulWidget {
  final int score;

  const RizzScoreCard({
    super.key,
    required this.score,
  });

  @override
  State<RizzScoreCard> createState() => _RizzScoreCardState();
}

class _RizzScoreCardState extends State<RizzScoreCard> {
  final GlobalKey _cardKey = GlobalKey();
  bool _isSharing = false;

  String get _rizzLabel {
    if (widget.score <= 30) return 'Cringe';
    if (widget.score <= 50) return 'Below Average';
    if (widget.score <= 70) return 'Decent';
    if (widget.score <= 85) return 'Smooth';
    return 'Elite';
  }

  Color get _scoreColor {
    if (widget.score <= 30) return const Color(0xFFFF4757);
    if (widget.score <= 50) return const Color(0xFFFF6B35);
    if (widget.score <= 70) return const Color(0xFFFFBE0B);
    if (widget.score <= 85) return const Color(0xFF06D6A0);
    return const Color(0xFF00F5D4);
  }

  List<Color> get _cardGradient {
    if (widget.score <= 30) {
      return [const Color(0xFF1A0A0A), const Color(0xFF2D0A16)];
    }
    if (widget.score <= 50) {
      return [const Color(0xFF1A100A), const Color(0xFF2D1A0A)];
    }
    if (widget.score <= 70) {
      return [const Color(0xFF1A1A0A), const Color(0xFF2D2A0A)];
    }
    if (widget.score <= 85) {
      return [const Color(0xFF0A1A14), const Color(0xFF0A2D1E)];
    }
    return [const Color(0xFF0A1A1A), const Color(0xFF0A2D2D)];
  }

  Future<void> _shareCard() async {
    setState(() => _isSharing = true);
    try {
      final boundary = _cardKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final directory = await getTemporaryDirectory();
      final filePath =
          '${directory.path}/rizz_score_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(filePath);
      await file.writeAsBytes(byteData.buffer.asUint8List());

      final box = context.findRenderObject() as RenderBox?;
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'My Rizz Score is ${widget.score}. $_rizzLabel energy. #Rizzly',
        sharePositionOrigin:
            box != null ? box.localToGlobal(Offset.zero) & box.size : null,
      );
    } catch (e) {
      debugPrint('[RizzScoreCard] Share failed: $e');
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RepaintBoundary(
          key: _cardKey,
          child: _buildCard(),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _isSharing ? null : _shareCard,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isSharing
                      ? Icons.hourglass_top_rounded
                      : Icons.share_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  _isSharing ? 'Preparing...' : 'Share',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _cardGradient,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _scoreColor.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top: "Rizzly" branding
          Opacity(
            opacity: 0.50,
            child: Text(
              'Rizzly',
              style: GoogleFonts.instrumentSerif(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Big score
          Text(
            '${widget.score}',
            style: GoogleFonts.instrumentSerif(
              color: _scoreColor,
              fontSize: 96,
              fontWeight: FontWeight.w400,
              height: 0.9,
            ),
          ),

          const SizedBox(height: 8),

          // Label
          Text(
            _rizzLabel.toUpperCase(),
            style: GoogleFonts.dmSans(
              color: _scoreColor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 3,
            ),
          ),

          const SizedBox(height: 28),

          // Score bar
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 4,
              child: LinearProgressIndicator(
                value: widget.score / 100,
                backgroundColor: Colors.white.withValues(alpha: 0.06),
                valueColor: AlwaysStoppedAnimation<Color>(_scoreColor),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Bottom tagline
          Opacity(
            opacity: 0.25,
            child: Text(
              'never miss your rizz',
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w400,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
