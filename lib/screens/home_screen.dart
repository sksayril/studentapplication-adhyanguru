import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';
import '../widgets/upcoming_class_card.dart';
import '../widgets/live_class_card.dart';
import '../widgets/test_exam_card.dart';
import '../widgets/premium_course_card.dart';
import '../widgets/live_course_card.dart';
import '../widgets/free_course_card.dart';
import '../widgets/my_course_card.dart';
import '../widgets/game_card.dart';
import '../widgets/ai_feature_card.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/learning_path_card.dart';
import '../widgets/subject_card.dart';
import '../utils/theme_provider.dart';
import 'package:provider/provider.dart';
import 'subject_selection_screen.dart';
import 'profile_screen.dart';
import 'course_details_screen.dart';
import 'all_courses_screen.dart';
import 'chat_screen.dart';
import 'calendar_screen.dart';
import 'games_screen.dart';
import 'ai_features_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNavItemTapped(int index) {
    if (_selectedIndex == index) return; // Already on this page
    
    setState(() {
      _selectedIndex = index;
    });
    
    // Jump directly to the page without animation to avoid glitch
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          children: [
            _buildHomeContent(),
            _buildMyCoursesContent(),
            const CalendarScreen(),
            const ChatScreen(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildPlaceholderContent(String title) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction,
            size: 64,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: AppTextStyles.heading2,
          ),
          const SizedBox(height: 8),
          Text(
            'Coming soon...',
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 400),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 28),
            const LearningPathCard(),
            const SizedBox(height: 36),
            _buildMySubjects(),
            const SizedBox(height: 36),
            _buildAISection(),
            const SizedBox(height: 36),
            _buildGamesSection(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildMyCoursesContent() {
    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 400),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My courses',
                  style: AppTextStyles.heading1.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Track your learning progress',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              physics: const BouncingScrollPhysics(),
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
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Row(
              children: [
                Text(
                  'Harry!',
                  style: AppTextStyles.heading1,
                ),
                const SizedBox(width: 8),
                const Text(
                  '👋',
                  style: TextStyle(fontSize: 24),
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            // Theme toggle button
            GestureDetector(
              onTap: () {
                Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Theme.of(context).brightness == Brightness.dark
                      ? Icons.light_mode
                      : Icons.dark_mode,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.amber
                      : AppColors.textPrimary,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.search,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70
                    : AppColors.textPrimary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        const ProfileScreen(),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      const begin = Offset(1.0, 0.0);
                      const end = Offset.zero;
                      const curve = Curves.easeInOutCubic;

                      var tween = Tween(begin: begin, end: end).chain(
                        CurveTween(curve: curve),
                      );

                      return SlideTransition(
                        position: animation.drive(tween),
                        child: FadeTransition(
                          opacity: animation,
                          child: child,
                        ),
                      );
                    },
                    transitionDuration: const Duration(milliseconds: 400),
                  ),
                );
              },
              child: Hero(
                tag: 'profile_image',
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                      imageUrl: 'https://source.unsplash.com/random/200x200/?portrait,person',
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const SkeletonCircle(size: 48),
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.secondary,
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUpcomingClass() {
    return UpcomingClassCard(
      subject: 'Math class',
      status: 'starting soon',
      studentAvatars: const ['👨', '👩', '👦', '👧'],
      onJoinTap: () {
        // Handle join class
      },
    );
  }

  Widget _buildTodaysClass() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: 'Todays ',
            style: AppTextStyles.heading2,
            children: const [
              TextSpan(
                text: 'Class',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 220,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            children: [
              LiveClassCard(
                subject: 'Biology',
                duration: '1.00h',
                imageUrl: '',
                backgroundColor: AppColors.biologyCardBg,
                onTap: () {
                  // Handle tap
                },
              ),
              LiveClassCard(
                subject: 'Biology',
                duration: '1.45h',
                imageUrl: '',
                backgroundColor: AppColors.biologyCardBg2,
                onTap: () {
                  // Handle tap
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTestExam() {
    return TestExamCard(
      title: 'Test Exam',
      description: "Let's check your preparation",
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const SubjectSelectionScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeInOutCubic;

              var tween = Tween(begin: begin, end: end).chain(
                CurveTween(curve: curve),
              );

              return SlideTransition(
                position: animation.drive(tween),
                child: FadeTransition(
                  opacity: animation,
                  child: child,
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      },
    );
  }

  Widget _buildPremiumCourses() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            RichText(
              text: TextSpan(
                text: 'Premium ',
                style: AppTextStyles.heading2,
                children: const [
                  TextSpan(
                    text: 'Courses',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AllCoursesScreen(
                      courseType: 'premium',
                      title: 'Premium Courses',
                    ),
                  ),
                );
              },
              child: Text(
                'See all',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              PremiumCourseCard(
                title: 'English speaking',
                lessons: '24',
                price: '\$45.00',
                rating: 4.8,
                imageUrl: '',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CourseDetailsScreen(
                        courseName: 'English Speaking Course',
                        price: '\$45.00',
                        isFree: false,
                      ),
                    ),
                  );
                },
              ),
              PremiumCourseCard(
                title: 'Spanish basics',
                lessons: '18',
                price: '\$35.00',
                rating: 4.5,
                imageUrl: '',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CourseDetailsScreen(
                        courseName: 'Spanish Basics Course',
                        price: '\$35.00',
                        isFree: false,
                      ),
                    ),
                  );
                },
              ),
              PremiumCourseCard(
                title: 'French speaking',
                lessons: '20',
                price: '\$40.00',
                rating: 4.7,
                imageUrl: '',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CourseDetailsScreen(
                        courseName: 'French Speaking Course',
                        price: '\$40.00',
                        isFree: false,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLiveCourses() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            RichText(
              text: TextSpan(
                text: 'Live ',
                style: AppTextStyles.heading2,
                children: const [
                  TextSpan(
                    text: 'Courses',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AllCoursesScreen(
                      courseType: 'live',
                      title: 'Live courses',
                    ),
                  ),
                );
              },
              child: Text(
                'See all',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 240,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              LiveCourseCard(
                className: 'Class 9',
                price: '\$454.00',
                lessons: '12',
                duration: '6 months',
                backgroundColor: Colors.grey[800]!,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CourseDetailsScreen(
                        courseName: 'Class 9 Full Course',
                        price: '\$454.00',
                        isFree: false,
                      ),
                    ),
                  );
                },
              ),
              LiveCourseCard(
                className: 'Class 10',
                price: '\$499.00',
                lessons: '15',
                duration: '8 months',
                backgroundColor: Colors.grey[800]!,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CourseDetailsScreen(
                        courseName: 'Class 10 Complete Course',
                        price: '\$499.00',
                        isFree: false,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFreeCourses() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            RichText(
              text: TextSpan(
                text: 'Free ',
                style: AppTextStyles.heading2,
                children: const [
                  TextSpan(
                    text: 'courses',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AllCoursesScreen(
                      courseType: 'free',
                      title: 'Free courses',
                    ),
                  ),
                );
              },
              child: Text(
                'See all',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              FreeCourseCard(
                title: 'Chemistry',
                lessons: '14',
                backgroundColor: const Color(0xFFFFF4C4),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CourseDetailsScreen(
                        courseName: 'Chemistry Fundamentals',
                        price: 'Free',
                        isFree: true,
                      ),
                    ),
                  );
                },
              ),
              FreeCourseCard(
                title: 'Physics',
                lessons: '18',
                backgroundColor: const Color(0xFFFFE4C4),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CourseDetailsScreen(
                        courseName: 'Physics Basics',
                        price: 'Free',
                        isFree: true,
                      ),
                    ),
                  );
                },
              ),
              FreeCourseCard(
                title: 'Mathematics',
                lessons: '20',
                backgroundColor: const Color(0xFFE8F5E9),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CourseDetailsScreen(
                        courseName: 'Mathematics Foundation',
                        price: 'Free',
                        isFree: true,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      height: 70,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.navBarBg,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_rounded, Icons.home_outlined, 0),
              _buildNavItem(Icons.play_circle, Icons.play_circle_outline, 1),
              _buildNavItem(Icons.calendar_today_rounded, Icons.calendar_today_outlined, 2),
              _buildNavItem(Icons.chat_bubble_rounded, Icons.chat_bubble_outline_rounded, 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData selectedIcon, IconData unselectedIcon, int index) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => _onNavItemTapped(index),
      borderRadius: BorderRadius.circular(14),
      splashColor: Colors.white.withOpacity(0.1),
      highlightColor: Colors.white.withOpacity(0.05),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) {
            return ScaleTransition(
              scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutBack,
                ),
              ),
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          child: Icon(
            isSelected ? selectedIcon : unselectedIcon,
            key: ValueKey<bool>(isSelected),
            color: isSelected ? Colors.white : AppColors.navBarUnselected,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildGamesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            RichText(
              text: TextSpan(
                text: 'Educational ',
                style: AppTextStyles.heading2,
                children: const [
                  TextSpan(
                    text: 'Games',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GamesScreen(),
                  ),
                );
              },
              child: Text(
                'See all',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            children: [
              GameCard(
                title: 'Math Quiz',
                description: 'Test your math skills',
                players: '1.2K playing',
                backgroundColor: const Color(0xFF6C5CE7),
                iconColor: const Color(0xFF6C5CE7),
                icon: Icons.calculate_outlined,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Math Quiz - Coming Soon!'),
                      backgroundColor: const Color(0xFF6C5CE7),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
              ),
              GameCard(
                title: 'Word Puzzle',
                description: 'Improve vocabulary',
                players: '890 playing',
                backgroundColor: const Color(0xFFFF9F43),
                iconColor: const Color(0xFFFF9F43),
                icon: Icons.text_fields,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Word Puzzle - Coming Soon!'),
                      backgroundColor: const Color(0xFFFF9F43),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
              ),
              GameCard(
                title: 'Science Lab',
                description: 'Interactive experiments',
                players: '650 playing',
                backgroundColor: const Color(0xFF00B894),
                iconColor: const Color(0xFF00B894),
                icon: Icons.science_outlined,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Science Lab - Coming Soon!'),
                      backgroundColor: const Color(0xFF00B894),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
              ),
              GameCard(
                title: 'Geography Quest',
                description: 'Explore the world',
                players: '540 playing',
                backgroundColor: const Color(0xFFE17055),
                iconColor: const Color(0xFFE17055),
                icon: Icons.public,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Geography Quest - Coming Soon!'),
                      backgroundColor: const Color(0xFFE17055),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMySubjects() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Subjects',
          style: AppTextStyles.heading2.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        // First row - 2 subjects
        Row(
          children: [
            Expanded(
              child: SubjectCard(
                emoji: '⚗️',
                subjectName: 'Chemistry',
                backgroundColor: const Color(0xFFFFF4C4),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Chemistry lessons - Coming Soon!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SubjectCard(
                emoji: '⚛️',
                subjectName: 'Physics',
                backgroundColor: const Color(0xFFFFE4C4),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Physics lessons - Coming Soon!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Second row - 2 subjects
        Row(
          children: [
            Expanded(
              child: SubjectCard(
                emoji: '📐',
                subjectName: 'Mathematics',
                backgroundColor: const Color(0xFFE8F5E9),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Mathematics lessons - Coming Soon!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SubjectCard(
                emoji: '🧬',
                subjectName: 'Biology',
                backgroundColor: const Color(0xFFD4F1F4),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Biology lessons - Coming Soon!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAISection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 24,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                RichText(
                  text: TextSpan(
                    text: 'AI ',
                    style: AppTextStyles.heading2.copyWith(
                      color: AppColors.primary,
                    ),
                    children: const [
                      TextSpan(
                        text: 'Features',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AIFeaturesScreen(),
                  ),
                );
              },
              child: Text(
                'See all',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // First row - 2 cards
        Row(
          children: [
            Expanded(
              child: AIFeatureCard(
                title: 'AI Tutor',
                description: 'Get 24/7 learning assistance',
                icon: Icons.psychology_outlined,
                backgroundColor: const Color(0xFF6C5CE7),
                iconColor: const Color(0xFF6C5CE7),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('AI Tutor - Coming Soon!'),
                      backgroundColor: const Color(0xFF6C5CE7),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AIFeatureCard(
                title: 'Smart Study Plan',
                description: 'Personalized schedule',
                icon: Icons.calendar_today_outlined,
                backgroundColor: const Color(0xFF00B894),
                iconColor: const Color(0xFF00B894),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Smart Study Plan - Coming Soon!'),
                      backgroundColor: const Color(0xFF00B894),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Second row - 2 cards
        Row(
          children: [
            Expanded(
              child: AIFeatureCard(
                title: 'Doubt Solver',
                description: 'Instant answers',
                icon: Icons.question_answer_outlined,
                backgroundColor: const Color(0xFFFF9F43),
                iconColor: const Color(0xFFFF9F43),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Doubt Solver - Coming Soon!'),
                      backgroundColor: const Color(0xFFFF9F43),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AIFeatureCard(
                title: 'AI Exam',
                description: 'Test your knowledge',
                icon: Icons.quiz_outlined,
                backgroundColor: const Color(0xFFE74C3C),
                iconColor: const Color(0xFFE74C3C),
                onTap: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          const SubjectSelectionScreen(),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        const begin = Offset(1.0, 0.0);
                        const end = Offset.zero;
                        const curve = Curves.easeInOutCubic;

                        var tween = Tween(begin: begin, end: end).chain(
                          CurveTween(curve: curve),
                        );

                        return SlideTransition(
                          position: animation.drive(tween),
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        );
                      },
                      transitionDuration: const Duration(milliseconds: 400),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

