import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';
import '../utils/navigation_helper.dart';
import '../widgets/skeleton_loader.dart';
import 'course_details_screen.dart';

class AllCoursesScreen extends StatefulWidget {
  final String courseType; // 'premium', 'live', 'free'
  final String title;

  const AllCoursesScreen({
    Key? key,
    required this.courseType,
    required this.title,
  }) : super(key: key);

  @override
  State<AllCoursesScreen> createState() => _AllCoursesScreenState();
}

class _AllCoursesScreenState extends State<AllCoursesScreen> {
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (!didPop) {
          NavigationHelper.goBack(context);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: _buildCoursesList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const CustomBackButton(
            backgroundColor: Colors.transparent,
            iconColor: AppColors.textPrimary,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              widget.title,
              style: AppTextStyles.heading2.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoursesList() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      physics: const BouncingScrollPhysics(),
      children: [
        if (widget.courseType == 'live') ..._buildLiveCourses(),
        if (widget.courseType == 'premium') ..._buildPremiumCourses(),
        if (widget.courseType == 'free') ..._buildFreeCourses(),
        const SizedBox(height: 20),
      ],
    );
  }

  List<Widget> _buildLiveCourses() {
    final courses = [
      {
        'title': 'Class 9',
        'lessons': '12 lesson',
        'duration': '6 months',
        'price': '\$454.00',
        'bgColor': const Color(0xFFFFC5D9),
        'imageUrl': 'https://source.unsplash.com/random/400x400/?teacher,man,professional',
      },
      {
        'title': 'Class 10',
        'lessons': '12 lesson',
        'duration': '6 months',
        'price': '\$653.00',
        'bgColor': const Color(0xFFE8F5E9),
        'imageUrl': 'https://source.unsplash.com/random/400x400/?instructor,male,teaching',
      },
      {
        'title': 'Class 11',
        'lessons': '12 lesson',
        'duration': '7 months',
        'price': '\$1100.00',
        'bgColor': const Color(0xFFE3F2FD),
        'imageUrl': 'https://source.unsplash.com/random/400x400/?teacher,young,professor',
      },
      {
        'title': 'Class 12',
        'lessons': '15 lesson',
        'duration': '8 months',
        'price': '\$1250.00',
        'bgColor': const Color(0xFFFFF4E6),
        'imageUrl': 'https://source.unsplash.com/random/400x400/?educator,professional,male',
      },
    ];

    return courses.map((course) => _buildLiveCourseCard(
      course['title'] as String,
      course['lessons'] as String,
      course['duration'] as String,
      course['price'] as String,
      course['bgColor'] as Color,
      course['imageUrl'] as String,
    )).toList();
  }

  List<Widget> _buildPremiumCourses() {
    final courses = [
      {
        'title': 'English Speaking',
        'lessons': '24 lesson',
        'duration': '4 months',
        'price': '\$45.00',
        'rating': 4.8,
      },
      {
        'title': 'Spanish Basics',
        'lessons': '18 lesson',
        'duration': '3 months',
        'price': '\$35.00',
        'rating': 4.5,
      },
      {
        'title': 'French Speaking',
        'lessons': '20 lesson',
        'duration': '4 months',
        'price': '\$40.00',
        'rating': 4.7,
      },
      {
        'title': 'German Language',
        'lessons': '22 lesson',
        'duration': '5 months',
        'price': '\$50.00',
        'rating': 4.9,
      },
      {
        'title': 'Japanese Basics',
        'lessons': '16 lesson',
        'duration': '3 months',
        'price': '\$55.00',
        'rating': 4.6,
      },
    ];

    return courses.map((course) => _buildPremiumCourseCard(
      course['title'] as String,
      course['lessons'] as String,
      course['duration'] as String,
      course['price'] as String,
      course['rating'] as double,
    )).toList();
  }

  List<Widget> _buildFreeCourses() {
    final courses = [
      {
        'title': 'Chemistry',
        'lessons': '14 lesson',
        'duration': '2 months',
        'bgColor': const Color(0xFFFFF4C4),
      },
      {
        'title': 'Physics',
        'lessons': '18 lesson',
        'duration': '3 months',
        'bgColor': const Color(0xFFFFE4C4),
      },
      {
        'title': 'Mathematics',
        'lessons': '20 lesson',
        'duration': '3 months',
        'bgColor': const Color(0xFFE8F5E9),
      },
      {
        'title': 'Biology',
        'lessons': '16 lesson',
        'duration': '2 months',
        'bgColor': const Color(0xFFE3F2FD),
      },
    ];

    return courses.map((course) => _buildFreeCourseCard(
      course['title'] as String,
      course['lessons'] as String,
      course['duration'] as String,
      course['bgColor'] as Color,
    )).toList();
  }

  Widget _buildLiveCourseCard(
    String title,
    String lessons,
    String duration,
    String price,
    Color bgColor,
    String imageUrl,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CourseDetailsScreen(
              courseName: '$title Full Course',
              price: price,
              isFree: false,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Stack(
                children: [
                  // Background pattern
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      child: CustomPaint(
                        painter: _PatternPainter(),
                      ),
                    ),
                  ),
                  // Instructor image
                  Center(
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      height: 180,
                      width: 150,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => SkeletonLoader(
                        width: 150,
                        height: 180,
                        borderRadius: BorderRadius.circular(0),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.transparent,
                        child: const Icon(
                          Icons.person,
                          size: 80,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  // Bookmark icon
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.bookmark_outline,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Info section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.heading3.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        price,
                        style: AppTextStyles.heading3.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.play_circle_outline,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        lessons,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        duration,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumCourseCard(
    String title,
    String lessons,
    String duration,
    String price,
    double rating,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CourseDetailsScreen(
              courseName: '$title Course',
              price: price,
              isFree: false,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.book,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.heading3.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.play_circle_outline,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        lessons,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        duration,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        size: 16,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        rating.toString(),
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        price,
                        style: AppTextStyles.heading3.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFreeCourseCard(
    String title,
    String lessons,
    String duration,
    Color bgColor,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CourseDetailsScreen(
              courseName: '$title Fundamentals',
              price: 'Free',
              isFree: true,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.science_outlined,
                size: 40,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.heading3.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.play_circle_outline,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        lessons,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        duration,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.successGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Free',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.successGreen,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painter for background pattern
class _PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Draw some decorative lines
    for (var i = 0; i < 5; i++) {
      final y = (size.height / 6) * (i + 1);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width * 0.3, y),
        paint,
      );
      canvas.drawLine(
        Offset(size.width * 0.7, y),
        Offset(size.width, y),
        paint,
      );
    }

    // Draw some circles
    for (var i = 0; i < 3; i++) {
      canvas.drawCircle(
        Offset(size.width * 0.2 + (i * 30), size.height * 0.3),
        8,
        paint,
      );
      canvas.drawCircle(
        Offset(size.width * 0.7 + (i * 25), size.height * 0.7),
        6,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

