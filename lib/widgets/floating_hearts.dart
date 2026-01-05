import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class HeartParticle {
  Offset position;
  Offset velocity;
  double size;
  double opacity;
  double rotation;
  Color color;

  HeartParticle({
    required this.position,
    this.velocity = Offset.zero,
    this.size = 24.0,
    this.opacity = 0.6,
    this.rotation = 0.0,
    required this.color,
  });
}

class FloatingHeartsBackground extends StatefulWidget {
  const FloatingHeartsBackground({super.key});

  @override
  State<FloatingHeartsBackground> createState() =>
      _FloatingHeartsBackgroundState();
}

class _FloatingHeartsBackgroundState extends State<FloatingHeartsBackground>
    with SingleTickerProviderStateMixin {
  static const List<Color> _heartColors = [
    Color(0xFFFF6B9D), // Pink
    Color(0xFFFF8FAB), // Light pink
    Color(0xFFFF5C8A), // Hot pink
    Color(0xFFFF7AA2), // Rose
    Color(0xFFE91E63), // Material pink
  ];

  late List<HeartParticle> _hearts;
  late AnimationController _animationController;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  Offset _gravity = Offset.zero;
  Size _screenSize = Size.zero;
  final Random _random = Random();
  DateTime _lastUpdate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _hearts = [];

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    _animationController.addListener(_updatePhysics);

    _subscribeToAccelerometer();
  }

  void _initializeHearts(Size size) {
    _screenSize = size;
    _hearts = List.generate(18, (index) {
      return HeartParticle(
        position: Offset(
          _random.nextDouble() * size.width,
          _random.nextDouble() * size.height,
        ),
        velocity: Offset(
          (_random.nextDouble() - 0.5) * 20,
          (_random.nextDouble() - 0.5) * 20,
        ),
        size: 16.0 + _random.nextDouble() * 20.0,
        opacity: 0.3 + _random.nextDouble() * 0.4,
        rotation: _random.nextDouble() * 2 * pi,
        color: _heartColors[_random.nextInt(_heartColors.length)],
      );
    });
  }

  void _subscribeToAccelerometer() {
    _accelerometerSubscription = accelerometerEventStream().listen(
      (AccelerometerEvent event) {
        _gravity = Offset(
          event.x * 15,
          -event.y * 15,
        );
      },
      onError: (error) {
        debugPrint('Accelerometer error: $error');
      },
      cancelOnError: false,
    );
  }

  void _updatePhysics() {
    if (_screenSize == Size.zero || _hearts.isEmpty) return;

    final now = DateTime.now();
    final dt = (now.difference(_lastUpdate).inMicroseconds / 1000000.0)
        .clamp(0.0, 0.05);
    _lastUpdate = now;

    for (final heart in _hearts) {
      // Apply gravity-based acceleration
      heart.velocity += _gravity * dt;

      // Apply friction/drag
      heart.velocity *= 0.995;

      // Limit max velocity
      final speed = heart.velocity.distance;
      if (speed > 200) {
        heart.velocity = heart.velocity / speed * 200;
      }

      // Update position
      heart.position += heart.velocity * dt;

      // Rotate based on horizontal velocity
      heart.rotation += heart.velocity.dx * dt * 0.02;

      // Wrap around screen edges
      _wrapAroundEdges(heart);
    }

    setState(() {});
  }

  void _wrapAroundEdges(HeartParticle heart) {
    final padding = heart.size;

    // Horizontal wrapping
    if (heart.position.dx < -padding) {
      heart.position = Offset(_screenSize.width + padding, heart.position.dy);
    } else if (heart.position.dx > _screenSize.width + padding) {
      heart.position = Offset(-padding, heart.position.dy);
    }

    // Vertical wrapping
    if (heart.position.dy < -padding) {
      heart.position = Offset(heart.position.dx, _screenSize.height + padding);
    } else if (heart.position.dy > _screenSize.height + padding) {
      heart.position = Offset(heart.position.dx, -padding);
    }
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    _animationController.removeListener(_updatePhysics);
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        if (_screenSize != size) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _initializeHearts(size);
            }
          });
        }

        return RepaintBoundary(
          child: CustomPaint(
            painter: HeartsPainter(hearts: _hearts),
            size: size,
          ),
        );
      },
    );
  }
}

class HeartsPainter extends CustomPainter {
  final List<HeartParticle> hearts;

  HeartsPainter({required this.hearts});

  @override
  void paint(Canvas canvas, Size size) {
    for (final heart in hearts) {
      canvas.save();
      canvas.translate(heart.position.dx, heart.position.dy);
      canvas.rotate(heart.rotation);

      _drawHeart(canvas, heart);

      canvas.restore();
    }
  }

  void _drawHeart(Canvas canvas, HeartParticle heart) {
    final paint = Paint()
      ..color = heart.color.withValues(alpha: heart.opacity)
      ..style = PaintingStyle.fill;

    final path = Path();
    final s = heart.size / 2;

    // Heart shape using bezier curves
    path.moveTo(0, s * 0.3);
    path.cubicTo(-s * 0.8, -s * 0.5, -s * 1.2, s * 0.3, 0, s * 1.2);
    path.cubicTo(s * 1.2, s * 0.3, s * 0.8, -s * 0.5, 0, s * 0.3);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant HeartsPainter oldDelegate) => true;
}
