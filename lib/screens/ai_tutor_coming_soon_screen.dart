import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';

class AITutorComingSoonScreen extends StatelessWidget {
  const AITutorComingSoonScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF6C5CE7),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.psychology,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Tutor',
                  style: AppTextStyles.heading3.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'AI Powered',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6C5CE7), Color(0xFF8B7ED8)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated AI Icon
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 1500),
                    curve: Curves.easeOutBack,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Transform.translate(
                          offset: Offset(0, 50 * (1 - value)),
                          child: Container(
                            padding: const EdgeInsets.all(40),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.3),
                                  blurRadius: 30,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.psychology,
                              size: 120,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 60),
                  // Coming Soon Text
                  const Text(
                    'Coming Soon!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  // Description Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'AI Tutor',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Get personalized learning help from our smart AI tutor!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.95),
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Features List
                        _buildFeatureItem('📚', 'Learn any subject'),
                        const SizedBox(height: 12),
                        _buildFeatureItem('💡', 'Get instant explanations'),
                        const SizedBox(height: 12),
                        _buildFeatureItem('🎯', 'Practice with examples'),
                        const SizedBox(height: 12),
                        _buildFeatureItem('📊', 'Track your progress'),
                        const SizedBox(height: 12),
                        _buildFeatureItem('⏰', '24/7 learning assistance'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Notification Button
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('We\'ll notify you when AI Tutor is ready!'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.notifications_outlined, size: 24),
                    label: const Text(
                      'Notify Me',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF6C5CE7),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 18,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Back Button
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Go Back',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String emoji, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 24),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}




