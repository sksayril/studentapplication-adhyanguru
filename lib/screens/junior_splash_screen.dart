import 'package:flutter/material.dart';
import 'dart:async';
import '../utils/colors.dart';
import '../utils/text_styles.dart';
import 'junior_home_screen.dart';

class JuniorSplashScreen extends StatefulWidget {
  const JuniorSplashScreen({Key? key}) : super(key: key);

  @override
  State<JuniorSplashScreen> createState() => _JuniorSplashScreenState();
}

class _JuniorSplashScreenState extends State<JuniorSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _rotateController;
  late AnimationController _sparkleController;
  late AnimationController _fadeController;
  late Animation<double> _bounceAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _sparkleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
    _navigateToHome();
  }

  void _initializeAnimations() {
    // Bounce animation for logo
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));

    // Rotate animation for sparkles
    _rotateController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_rotateController);

    // Sparkle animation
    _sparkleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _sparkleAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _sparkleController,
      curve: Curves.easeInOut,
    ));

    // Fade animation for text
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _bounceController.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    _fadeController.forward();
  }

  void _navigateToHome() {
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const JuniorHomeScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _rotateController.dispose();
    _sparkleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF8B5CF6),
              const Color(0xFFA78BFA),
              const Color(0xFFEC4899),
              const Color(0xFFF59E0B),
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  // Animated Background Elements
                  ...List.generate(20, (index) => _buildFloatingElement(index, constraints)),
                  
                  // Main Content
                  Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Sparkles around logo
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Rotating sparkles
                        AnimatedBuilder(
                          animation: _rotateAnimation,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: _rotateAnimation.value * 2 * 3.14159,
                              child: SizedBox(
                                width: 260,
                                height: 260,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Positioned(
                                      top: -60,
                                      left: 110,
                                      child: _buildSparkle(0),
                                    ),
                                    Positioned(
                                      right: -60,
                                      top: 110,
                                      child: _buildSparkle(1),
                                    ),
                                    Positioned(
                                      bottom: -60,
                                      left: 110,
                                      child: _buildSparkle(2),
                                    ),
                                    Positioned(
                                      left: -60,
                                      top: 110,
                                      child: _buildSparkle(3),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        
                        // Main Logo with Bounce
                        ScaleTransition(
                          scale: _bounceAnimation,
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white,
                                  Color(0xFFFFF9C4),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.5),
                                  blurRadius: 30,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                '🎓',
                                style: TextStyle(fontSize: 80),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // App Name with Fade
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          const Text(
                            'Adhyan',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 2,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Guru',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 2,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.5),
                                width: 2,
                              ),
                            ),
                            child: const Text(
                              'Learn & Play! 🎮',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 60),
                    
                    // Loading Dots
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (index) {
                          return AnimatedBuilder(
                            animation: _sparkleAnimation,
                            builder: (context, child) {
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 6),
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(
                                    index == 1
                                        ? _sparkleAnimation.value
                                        : _sparkleAnimation.value * 0.6,
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.5),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSparkle(int index) {
    final colors = [
      const Color(0xFFFFD700),
      const Color(0xFFFF6B6B),
      const Color(0xFF4ECDC4),
      const Color(0xFFFFE66D),
    ];
    
    return AnimatedBuilder(
      animation: _sparkleAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _sparkleAnimation.value,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors[index % colors.length],
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colors[index % colors.length].withOpacity(0.6),
                  blurRadius: 15,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: const Center(
              child: Text(
                '✨',
                style: TextStyle(fontSize: 20),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloatingElement(int index, BoxConstraints constraints) {
    final random = (index * 7) % 100;
    final emojis = ['⭐', '🎈', '🎨', '🎯', '🎪', '🎭', '🎨', '🌟'];
    
    final width = constraints.maxWidth.isFinite ? constraints.maxWidth : 400.0;
    final height = constraints.maxHeight.isFinite ? constraints.maxHeight : 800.0;
    
    return Positioned(
      left: (random * 3.7) % width,
      top: (random * 4.2) % height,
      child: AnimatedBuilder(
        animation: _rotateController,
        builder: (context, child) {
          return Transform.rotate(
            angle: _rotateAnimation.value * 2 * 3.14159 * (index % 2 == 0 ? 1 : -1),
            child: Opacity(
              opacity: 0.2,
              child: Text(
                emojis[index % emojis.length],
                style: TextStyle(
                  fontSize: 30 + (index % 3) * 10,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

