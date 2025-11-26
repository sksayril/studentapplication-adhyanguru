import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';

class FreeCourseCard extends StatelessWidget {
  final String title;
  final String lessons;
  final Color backgroundColor;
  final VoidCallback onTap;

  const FreeCourseCard({
    Key? key,
    required this.title,
    required this.lessons,
    required this.backgroundColor,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Icon decoration in top right
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: Colors.white.withOpacity(0.3),
                  size: 40,
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Course title
            Text(
              title,
              style: AppTextStyles.heading2.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            // Lessons info
            Row(
              children: [
                const Icon(
                  Icons.play_circle_outline,
                  size: 16,
                  color: AppColors.textPrimary,
                ),
                const SizedBox(width: 6),
                Text(
                  '$lessons lessons',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

