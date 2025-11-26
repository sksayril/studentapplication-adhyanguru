import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';
import '../widgets/my_course_card.dart';

class MyCoursesScreen extends StatelessWidget {
  const MyCoursesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with back button
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.navBarBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 24,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'My courses',
                style: AppTextStyles.heading1.copyWith(fontSize: 24),
              ),
            ),
            const SizedBox(height: 24),
            // Course list
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    MyCourseCard(
                      courseName: 'Mathmemtics',
                      subtitle: 'Algebra',
                      progressPercentage: 25,
                      progressColor: const Color(0xFF3B82F6),
                      onTap: () {
                        // Handle tap
                      },
                    ),
                    MyCourseCard(
                      courseName: 'Biology',
                      subtitle: 'Plant kingdom',
                      progressPercentage: 35,
                      progressColor: const Color(0xFFF97316),
                      onTap: () {
                        // Handle tap
                      },
                    ),
                    MyCourseCard(
                      courseName: 'Chemistry',
                      subtitle: 'Algebra',
                      progressPercentage: 60,
                      progressColor: const Color(0xFF9333EA),
                      onTap: () {
                        // Handle tap
                      },
                    ),
                    MyCourseCard(
                      courseName: 'Physics',
                      subtitle: 'Motion',
                      progressPercentage: 25,
                      progressColor: const Color(0xFFEF4444),
                      onTap: () {
                        // Handle tap
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

