import 'dart:math' as math;

import 'package:flutter/material.dart';

class DragonballSplashScreen extends StatefulWidget {
  const DragonballSplashScreen({required this.onFinished, super.key});

  final VoidCallback onFinished;

  @override
  State<DragonballSplashScreen> createState() => _DragonballSplashScreenState();
}

class _DragonballSplashScreenState extends State<DragonballSplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _animationController;
  late final AnimationController _progressController;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
      lowerBound: .08,
      value: .08,
    );
    _initializeApplication();
  }

  Future<void> _initializeApplication() async {
    // Start the progress immediately. Asset decoding is handled by the
    // Image widget and must not be allowed to block the splash animation.
    await _moveProgressTo(.55);
    if (!mounted) return;

    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    await _moveProgressTo(.82);
    if (!mounted) return;

    await _moveProgressTo(1);
    if (!mounted || _hasNavigated) return;

    _hasNavigated = true;
    widget.onFinished();
  }

  Future<void> _moveProgressTo(double target) {
    return _progressController.animateTo(
      target,
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090B16),
      body: RepaintBoundary(
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _animationController,
            _progressController,
          ]),
          builder: (context, _) {
            return CustomPaint(
              painter: _DragonballBackgroundPainter(
                animationValue: _animationController.value,
              ),
              child: SafeArea(
                child: _DragonballSplashContent(
                  progress: _progressController.value,
                  animationValue: _animationController.value,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DragonballSplashContent extends StatelessWidget {
  const _DragonballSplashContent({
    required this.progress,
    required this.animationValue,
  });

  final double progress;
  final double animationValue;

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).round().clamp(0, 100);
    final pulse = math.sin(animationValue * math.pi * 2) * .5 + .5;

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 42, 28, 34),
      child: Column(
        children: [
          const Text(
            'DRAGON BALL',
            style: TextStyle(
              color: Color(0xFFFFC928),
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
              shadows: [Shadow(color: Color(0xFFE53935), blurRadius: 12)],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'CHARACTER ARCHIVE',
            style: TextStyle(
              color: Colors.white.withValues(alpha: .62),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 3.2,
            ),
          ),
          Expanded(
            child: Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final ballSize = math.min(
                    constraints.maxWidth * .72,
                    constraints.maxHeight * .62,
                  );
                  final scale = 1 + pulse * .025;

                  return Transform.scale(
                    scale: scale,
                    child: SizedBox(
                      width: ballSize,
                      height: ballSize,
                      child: Image.asset(
                        'assets/bola.png',
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: _LoadingBar(progress: progress),
          ),
          const SizedBox(height: 9),
          Text(
            '$percent%',
            style: TextStyle(
              color: Colors.white.withValues(alpha: .78),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingBar extends StatelessWidget {
  const _LoadingBar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final normalizedProgress = progress.clamp(0.0, 1.0).toDouble();
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: 7,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFFFC928).withValues(alpha: .3),
            ),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: constraints.maxWidth * normalizedProgress,
              height: 7,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE53935), Color(0xFFFFC928)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(color: Color(0xFFFFA000), blurRadius: 8),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DragonballBackgroundPainter extends CustomPainter {
  const _DragonballBackgroundPainter({required this.animationValue});

  final double animationValue;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF121A3A), Color(0xFF090B16), Color(0xFF1A0D12)],
        ).createShader(rect),
    );

    final pulse = math.sin(animationValue * math.pi * 2) * .5 + .5;
    final center = Offset(size.width / 2, size.height * .51);
    final aura = Paint()
      ..shader =
          RadialGradient(
            colors: [
              const Color(0xFFFFA000).withValues(alpha: .13 + pulse * .05),
              const Color(0xFFE53935).withValues(alpha: .04),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(center: center, radius: size.shortestSide * .62),
          );
    canvas.drawCircle(center, size.shortestSide * .62, aura);

    final rings = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = const Color(0xFFFFC928).withValues(alpha: .11 + pulse * .08);
    for (var i = 1; i <= 3; i++) {
      canvas.drawCircle(center, size.shortestSide * (.25 + i * .105), rings);
    }

    final stars = Paint()..color = Colors.white.withValues(alpha: .4);
    for (var i = 0; i < 24; i++) {
      final seed = i * 43.0;
      final x = (seed * 1.7) % size.width;
      final y = (seed * 2.3) % size.height;
      final radius = (i % 3 + 1) * .45;
      canvas.drawCircle(Offset(x, y), radius, stars);
    }
  }

  @override
  bool shouldRepaint(covariant _DragonballBackgroundPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
