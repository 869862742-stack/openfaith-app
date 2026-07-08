import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _starBreatheAnimation;
  int _statusIndex = 0;
  String _statusText = '正在启动...';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _starBreatheAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.6, end: 1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.6), weight: 50),
    ]).animate(
      AnimationController(vsync: this, duration: const Duration(seconds: 10))
        ..repeat(),
    );
    _controller.forward();
    _startSplashSequence();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _startSplashSequence() async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() {
      _statusIndex = 1;
      _statusText = '正在检查登录状态...';
    });

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() {
      _statusIndex = 2;
      _statusText = '正在连接服务器...';
    });

    final hasToken = await _checkLoginStatus();

    if (!mounted) return;
    setState(() {
      _statusIndex = 3;
      _statusText = '正在同步收藏...';
    });

    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() {
      _statusIndex = 4;
      _statusText = '正在进入...';
    });

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    _navigate(hasToken);
  }

  Future<bool> _checkLoginStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('user_token');
      final userId = prefs.getString('user_id');

      if (token != null && token.isNotEmpty && userId != null && userId.isNotEmpty) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          return true;
        }
      }

      final session = Supabase.instance.client.auth.currentSession;
      return session != null;
    } catch (e) {
      debugPrint('[Splash] Token check error: $e');
      return false;
    }
  }

  void _navigate(bool hasToken) {
    if (!mounted) return;
    if (hasToken) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Starfield background
          AnimatedBuilder(
            animation: _starBreatheAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _starBreatheAnimation.value,
                child: child,
              );
            },
            child: SizedBox.expand(
              child: CustomPaint(painter: _SplashStarfieldPainter()),
            ),
          ),
          // Content - centered aurora text (matching web version)
          FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // "Open Faith · Open World" with aurora gradient
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: AppColors.rainbowColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: const Text(
                      'Open Faith · Open World',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 60),
                  // Loading spinner (cyan accent like web)
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        const Color(0xFF00E5FF),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Status text
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      _statusText,
                      key: ValueKey<int>(_statusIndex),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Splash screen starfield painter
class _SplashStarfieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Background gradient
    final bgGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF0A0E1A),
        const Color(0xFF050816),
        const Color(0xFF0D1117),
      ],
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = bgGradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      ),
    );

    // Colored star dots matching web version
    final rng = Random(42);
    final starColors = [
      const Color(0xFFFF4D6D),
      const Color(0xFFFF9F1C),
      const Color(0xFFFFD60A),
      const Color(0xFF70E000),
      const Color(0xFF00E5FF),
      const Color(0xFF3A86FF),
      const Color(0xFF9D4EDD),
      Colors.white.withOpacity(0.6),
      const Color(0xFFC8DCFF).withOpacity(0.6),
    ];

    for (int i = 0; i < 80; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final r = rng.nextDouble() * 1.5 + 0.3;
      final color = starColors[rng.nextInt(starColors.length)];
      canvas.drawCircle(
        Offset(x, y),
        r,
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}