import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/repositories/shop_repository.dart';
import '../data/providers/current_shop_provider.dart';
import 'auth/login_screen.dart';
import 'dashboard/dashboard_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _logoController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.0, 0.6, curve: Curves.easeIn)),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.0, 0.8, curve: Curves.outBack)),
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic)),
    );

    _mainController.forward();
    _checkLoginState();
  }

  Future<void> _checkLoginState() async {
    // wait for animation/min splash duration
    await Future.delayed(const Duration(milliseconds: 2500));

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedKey = prefs.getString('security_key');

      if (savedKey != null && savedKey.isNotEmpty) {
        if (!mounted) return;
        
        final repo = ref.read(shopRepositoryProvider);
        final shopData = await repo.getShopBySecurityKey(savedKey);

        if (shopData != null && mounted) {
           ref.read(currentShopProvider.notifier).setShop(shopData);
           
           _navigateTo(const DashboardScreen());
           return;
        }
      }
    } catch (e) {
      debugPrint('Auto-login failed: $e');
    }

    if (!mounted) return;
    _navigateTo(const LoginScreen());
  }

  void _navigateTo(Widget screen) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  void dispose() {
    _mainController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6366F1), // Indigo 500
              Color(0xFF4F46E5), // Indigo 600
              Color(0xFF3730A3), // Indigo 800
            ],
          ),
        ),
        child: Stack(
          children: [
            // Subtle background circles
            Positioned(
              top: -100,
              right: -100,
              child: _buildBackgroundCircle(300, Colors.white.withOpacity(0.05)),
            ),
            Positioned(
              bottom: -50,
              left: -50,
              child: _buildBackgroundCircle(200, Colors.white.withOpacity(0.05)),
            ),
            
            Center(
              child: AnimatedBuilder(
                animation: _mainController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildPremiumLogo(),
                          const SizedBox(height: 32),
                          Transform.translate(
                            offset: Offset(0, _slideAnimation.value),
                            child: Column(
                              children: [
                                Text(
                                  'Billingly',
                                  style: GoogleFonts.outfit(
                                    fontSize: 56,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 2,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.3),
                                        offset: const Offset(0, 4),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                                  ),
                                  child: Text(
                                    'SMART BILLING & INVENTORY',
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.9),
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 80),
                          const SizedBox(
                            width: 30,
                            height: 30,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Version info at bottom
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  'Version 1.0.0',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildPremiumLogo() {
    return AnimatedBuilder(
      animation: _logoController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -5 * _logoController.value),
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(35),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                  spreadRadius: -5,
                ),
              ],
            ),
            padding: const EdgeInsets.all(25),
            child: CustomPaint(
              painter: _BillinglyLogoPainter(
                color: const Color(0xFF6366F1),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BillinglyLogoPainter extends CustomPainter {
  final Color color;

  _BillinglyLogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;

    // Draw a stylized "B" that looks like a stack of papers or cards
    
    // Bottom layer (shadow/depth)
    final path1 = Path();
    path1.moveTo(w * 0.1, h * 0.1);
    path1.lineTo(w * 0.7, h * 0.1);
    path1.quadraticBezierTo(w * 0.9, h * 0.1, w * 0.9, h * 0.3);
    path1.lineTo(w * 0.9, h * 0.7);
    path1.quadraticBezierTo(w * 0.9, h * 0.9, w * 0.7, h * 0.9);
    path1.lineTo(w * 0.1, h * 0.9);
    path1.close();
    
    canvas.drawPath(path1, paint);

    // Inner details (white lines like a receipt)
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.08
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(w * 0.3, h * 0.3), Offset(w * 0.7, h * 0.3), linePaint);
    canvas.drawLine(Offset(w * 0.3, h * 0.5), Offset(w * 0.6, h * 0.5), linePaint);
    canvas.drawLine(Offset(w * 0.3, h * 0.7), Offset(w * 0.7, h * 0.7), linePaint);
    
    // Corner accent
    final accentPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(Offset(w * 0.75, h * 0.15), w * 0.1, accentPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
