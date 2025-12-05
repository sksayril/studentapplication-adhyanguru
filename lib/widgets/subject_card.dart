import 'package:flutter/material.dart';
import '../utils/colors.dart';

class SubjectCard extends StatelessWidget {
  final String emoji;
  final String subjectName;
  final Color backgroundColor;
  final VoidCallback onTap;

  const SubjectCard({
    Key? key,
    required this.emoji,
    required this.subjectName,
    required this.backgroundColor,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity, // Take full width of parent
        height: double.infinity, // Take full height of parent (constrained by SizedBox)
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: backgroundColor.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon/Emoji container
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.4),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  emoji,
                  style: const TextStyle(
                    fontSize: 36,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Subject name
            Text(
              subjectName,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1F2937),
                letterSpacing: -0.2,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

