import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/colors.dart';
import '../../utils/level_theme.dart';
import '../../utils/education_level.dart';
import '../../providers/level_provider.dart';
import '../../widgets/skeleton_loader.dart';

class JuniorCoursesScreen extends StatelessWidget {
  const JuniorCoursesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final levelProvider = Provider.of<LevelProvider>(context);
    final currentLevel = levelProvider.currentLevel ?? EducationLevel.junior;
    final primaryColor = LevelTheme.getPrimaryColor(currentLevel);
    
    return Container(
      decoration: BoxDecoration(
        gradient: LevelTheme.getBackgroundGradient(currentLevel),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          const SizedBox(height: 10),
          const Text(
            'My Courses',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F2937),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Keep learning and growing!',
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          _buildCourseCard(
            emoji: '🔬',
            subject: 'Science',
            progress: 0.65,
            lessons: '12 of 18 lessons',
            color: primaryColor,
            backgroundColor: const Color(0xFFF3E8FF),
          ),
          const SizedBox(height: 16),
          _buildCourseCard(
            emoji: '📐',
            subject: 'Mathematics',
            progress: 0.45,
            lessons: '9 of 20 lessons',
            color: const Color(0xFFF59E0B),
            backgroundColor: const Color(0xFFFEF3C7),
          ),
          const SizedBox(height: 16),
          _buildCourseCard(
            emoji: '🌍',
            subject: 'Geography',
            progress: 0.80,
            lessons: '16 of 20 lessons',
            color: const Color(0xFF3B82F6),
            backgroundColor: const Color(0xFFDBEAFE),
          ),
          const SizedBox(height: 16),
          _buildCourseCard(
            emoji: '📚',
            subject: 'English',
            progress: 0.30,
            lessons: '6 of 20 lessons',
            color: const Color(0xFF10B981),
            backgroundColor: const Color(0xFFD1FAE5),
          ),
          const SizedBox(height: 16),
          _buildCourseCard(
            emoji: '🧬',
            subject: 'Biology',
            progress: 0.55,
            lessons: '11 of 20 lessons',
            color: const Color(0xFFEC4899),
            backgroundColor: const Color(0xFFFCE7F3),
          ),
          const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseCard({
    required String emoji,
    required String subject,
    required double progress,
    required String lessons,
    required Color color,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 36),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  lessons,
                  style: TextStyle(
                    fontSize: 13,
                    color: color.withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white.withOpacity(0.7),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}

