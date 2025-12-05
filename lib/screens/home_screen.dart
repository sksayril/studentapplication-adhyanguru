import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';
import '../utils/level_theme.dart';
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
import '../providers/level_provider.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import 'package:provider/provider.dart';
import 'subject_selection_screen.dart';
import 'profile_screen.dart';
import 'course_details_screen.dart';
import 'all_courses_screen.dart';
import 'chat_screen.dart';
import 'calendar_screen.dart';
import 'games_screen.dart';
import 'ai_features_screen.dart';
import 'junior/subject_details_screen.dart';
import 'doubt_solver_screen.dart';
import 'ai_tutor_coming_soon_screen.dart';
import 'smart_study_plan_screen.dart';
import 'ai_exam_coming_soon_screen.dart';
import 'subscriptions_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late PageController _pageController;
  
  // Subjects state for Intermediate students
  List<Map<String, dynamic>> _subjects = [];
  bool _isLoadingSubjects = false;
  String? _subjectsErrorMessage;
  
  // Subscription state
  bool _hasActiveSubscription = false;
  bool _isLoadingSubscription = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    // Load subscription status and subjects after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSubscriptionStatus();
      _loadMySubjects();
    });
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
    final levelProvider = Provider.of<LevelProvider>(context);
    final currentLevel = levelProvider.currentLevel;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: LevelTheme.getBackgroundGradient(currentLevel),
        ),
        child: SafeArea(
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
      ),
      bottomNavigationBar: _buildBottomNavBar(context, currentLevel),
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
      child: RefreshIndicator(
        onRefresh: () async {
          await _loadMySubjects();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          physics: const AlwaysScrollableScrollPhysics(),
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
    final levelProvider = Provider.of<LevelProvider>(context);
    final currentLevel = levelProvider.currentLevel;
    final primaryColor = LevelTheme.getPrimaryColor(currentLevel);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Welcome',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: LevelTheme.getGradientColors(currentLevel),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          LevelTheme.getLevelEmoji(currentLevel),
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          LevelTheme.getLevelName(currentLevel),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
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

  Widget _buildBottomNavBar(BuildContext context, String? currentLevel) {
    final primaryColor = LevelTheme.getPrimaryColor(currentLevel);
    return Container(
      height: 70,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: LevelTheme.getGradientColors(currentLevel),
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
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
              _buildNavItem(Icons.home_rounded, Icons.home_outlined, 0, currentLevel),
              _buildNavItem(Icons.play_circle, Icons.play_circle_outline, 1, currentLevel),
              _buildNavItem(Icons.calendar_today_rounded, Icons.calendar_today_outlined, 2, currentLevel),
              _buildNavItem(Icons.chat_bubble_rounded, Icons.chat_bubble_outline_rounded, 3, currentLevel),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData selectedIcon, IconData unselectedIcon, int index, String? currentLevel) {
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
              ? Colors.white.withOpacity(0.2)
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
              onPressed: _hasActiveSubscription ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GamesScreen(),
                  ),
                );
              } : _handleLockedFeatureTap,
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
              Stack(
                children: [
                  GameCard(
                    title: 'Math Quiz',
                    description: 'Test your math skills',
                    players: '1.2K playing',
                    backgroundColor: const Color(0xFF6C5CE7),
                    iconColor: const Color(0xFF6C5CE7),
                    icon: Icons.calculate_outlined,
                    onTap: _hasActiveSubscription ? () {
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
                    } : _handleLockedFeatureTap,
                  ),
                  if (!_hasActiveSubscription)
                    Positioned.fill(
                      child: GestureDetector(
                        onTap: _handleLockedFeatureTap,
                        child: Container(
                          margin: const EdgeInsets.only(right: 16),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.lock,
                                  color: Colors.white,
                                  size: 32,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Subscribe',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Stack(
                children: [
                  GameCard(
                    title: 'Word Puzzle',
                    description: 'Improve vocabulary',
                    players: '890 playing',
                    backgroundColor: const Color(0xFFFF9F43),
                    iconColor: const Color(0xFFFF9F43),
                    icon: Icons.text_fields,
                    onTap: _hasActiveSubscription ? () {
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
                    } : _handleLockedFeatureTap,
                  ),
                  if (!_hasActiveSubscription)
                    Positioned.fill(
                      child: GestureDetector(
                        onTap: _handleLockedFeatureTap,
                        child: Container(
                          margin: const EdgeInsets.only(right: 16),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.lock,
                                  color: Colors.white,
                                  size: 32,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Subscribe',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Stack(
                children: [
                  GameCard(
                    title: 'Science Lab',
                    description: 'Interactive experiments',
                    players: '650 playing',
                    backgroundColor: const Color(0xFF00B894),
                    iconColor: const Color(0xFF00B894),
                    icon: Icons.science_outlined,
                    onTap: _hasActiveSubscription ? () {
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
                    } : _handleLockedFeatureTap,
                  ),
                  if (!_hasActiveSubscription)
                    Positioned.fill(
                      child: GestureDetector(
                        onTap: _handleLockedFeatureTap,
                        child: Container(
                          margin: const EdgeInsets.only(right: 16),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.lock,
                                  color: Colors.white,
                                  size: 32,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Subscribe',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Stack(
                children: [
                  GameCard(
                    title: 'Geography Quest',
                    description: 'Explore the world',
                    players: '540 playing',
                    backgroundColor: const Color(0xFFE17055),
                    iconColor: const Color(0xFFE17055),
                    icon: Icons.public,
                    onTap: _hasActiveSubscription ? () {
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
                    } : _handleLockedFeatureTap,
                  ),
                  if (!_hasActiveSubscription)
                    Positioned.fill(
                      child: GestureDetector(
                        onTap: _handleLockedFeatureTap,
                        child: Container(
                          margin: const EdgeInsets.only(right: 16),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.lock,
                                  color: Colors.white,
                                  size: 32,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Subscribe',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _loadSubscriptionStatus() async {
    setState(() {
      _isLoadingSubscription = true;
    });

    try {
      final token = await AuthService.getToken();
      if (token != null && token.isNotEmpty) {
        final response = await ApiService.getActiveSubscription(token);
        
        if (mounted) {
          if (response['success'] == true && response['data'] != null) {
            final data = response['data'] as Map<String, dynamic>;
            final hasActive = data['hasActiveSubscription'] as bool? ?? false;
            
            setState(() {
              _hasActiveSubscription = hasActive;
              _isLoadingSubscription = false;
            });
          } else {
            setState(() {
              _hasActiveSubscription = false;
              _isLoadingSubscription = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _hasActiveSubscription = false;
            _isLoadingSubscription = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasActiveSubscription = false;
          _isLoadingSubscription = false;
        });
      }
    }
  }

  void _navigateToSubscriptionScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SubscriptionsScreen(),
      ),
    ).then((_) {
      // Reload subscription status when returning from subscription screen
      _loadSubscriptionStatus();
    });
  }

  void _handleLockedFeatureTap() {
    _navigateToSubscriptionScreen();
  }

  Future<void> _loadMySubjects() async {
    final levelProvider = Provider.of<LevelProvider>(context, listen: false);
    final currentLevel = levelProvider.currentLevel;
    
    // Also check from AuthService as fallback
    String? levelFromAuth;
    try {
      final userData = await AuthService.getUserData();
      if (userData != null && userData['studentLevel'] != null) {
        final level = userData['studentLevel'];
        if (level is Map && level['name'] != null) {
          levelFromAuth = level['name'].toString();
        } else if (level is String) {
          levelFromAuth = level;
        }
      }
    } catch (e) {
      print('Error getting level from AuthService: $e');
    }
    
    final finalLevel = currentLevel ?? levelFromAuth;
    
    print('=== Loading My Subjects ===');
    print('Current Level (Provider): $currentLevel');
    print('Level from AuthService: $levelFromAuth');
    print('Final Level: $finalLevel');
    
    // Only load subjects for Intermediate students
    // Check multiple variations of "intermediate"
    final levelLower = finalLevel?.toLowerCase() ?? '';
    final isIntermediate = levelLower == 'intermediate' || 
                          levelLower.contains('intermediate') ||
                          levelLower == 'inter' ||
                          levelLower == 'class 11' ||
                          levelLower == 'class 12';
    
    if (!isIntermediate) {
      print('Skipping subjects load - not Intermediate level (level: $finalLevel, normalized: $levelLower)');
      return;
    }
    
    print('Level check passed - proceeding to load subjects');

    setState(() {
      _isLoadingSubjects = true;
      _subjectsErrorMessage = null;
    });

    try {
      final token = await AuthService.getToken();
      print('Token available: ${token != null && token.isNotEmpty}');
      if (token != null && token.isNotEmpty) {
        print('Calling API: GET /api/students/my-subjects');
        print('Authorization: Bearer ${token.substring(0, token.length > 20 ? 20 : token.length)}...');
        final response = await ApiService.getMySubjects(token);
        print('API Response received: success=${response['success']}');
        
        if (mounted) {
          if (response['success'] == true && response['data'] != null) {
            final data = response['data'] as Map<String, dynamic>;
            final subjects = data['subjects'] as List? ?? [];
            
            setState(() {
              // Map and filter subjects
              final mappedSubjects = subjects
                  .map((s) => s as Map<String, dynamic>)
                  .where((s) => s['isActive'] == true)
                  .toList();
              
              // Remove duplicates based on subject ID (_id or id) and filter out subjects with 0 chapters
              final seenIds = <String>{};
              _subjects = [];
              
              for (var subject in mappedSubjects) {
                final subjectId = subject['_id'] as String? ?? 
                                 subject['id'] as String? ?? 
                                 '';
                
                // Skip if no valid ID
                if (subjectId.isEmpty) {
                  continue;
                }
                
                // Skip if we've already seen this ID (duplicate)
                if (seenIds.contains(subjectId)) {
                  print('Skipping duplicate subject: ${subject['name']}, ID: $subjectId');
                  continue;
                }
                
                // Check chapter count - skip subjects with 0 chapters
                final chapters = subject['chapters'] as List?;
                final chapterCount = subject['chapterCount'] as int?;
                final actualChapterCount = chapters?.length ?? chapterCount ?? 0;
                
                if (actualChapterCount == 0) {
                  print('Skipping subject with 0 chapters: ${subject['name']}, ID: $subjectId');
                  continue;
                }
                
                seenIds.add(subjectId);
                _subjects.add(subject);
              }
              
              _isLoadingSubjects = false;
              _subjectsErrorMessage = null;
              
              print('=== Subjects Loaded from API ===');
              print('Total subjects before filtering: ${mappedSubjects.length}');
              print('Total subjects after deduplication and chapter filter: ${_subjects.length}');
              for (var subject in _subjects) {
                final chapters = subject['chapters'] as List?;
                final chapterCount = subject['chapterCount'] as int?;
                final subjectId = subject['_id'] as String? ?? subject['id'] as String? ?? '';
                final actualChapterCount = chapters?.length ?? chapterCount ?? 0;
                print('Subject: ${subject['name']}, ID: $subjectId, Chapters: $actualChapterCount');
              }
              print('==============================');
            });
          } else {
            setState(() {
              _subjectsErrorMessage = response['message'] ?? 'Failed to load subjects';
              _isLoadingSubjects = false;
              _subjects = [];
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _subjectsErrorMessage = 'Not authenticated';
            _isLoadingSubjects = false;
            _subjects = [];
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _subjectsErrorMessage = 'Error loading subjects: ${e.toString()}';
          _isLoadingSubjects = false;
          _subjects = [];
        });
      }
    }
  }

  // Get emoji for a subject based on its name
  String _getSubjectEmoji(String subjectName) {
    final name = subjectName.toLowerCase();
    
    if (name.contains('math') || name.contains('mathematics')) {
      return '📐';
    } else if (name.contains('english') || name.contains('language')) {
      return '📚';
    } else if (name.contains('biology') || name.contains('bio')) {
      return '🧬';
    } else if (name.contains('physics')) {
      return '⚛️';
    } else if (name.contains('chemistry')) {
      return '⚗️';
    } else if (name.contains('computer') || name.contains('it') || name.contains('coding')) {
      return '💻';
    } else {
      return '📖';
    }
  }

  // Get color for subject card based on subject name
  Color _getSubjectColor(int index, String subjectName) {
    final name = subjectName.toLowerCase();
    
    // Match colors to the design image
    if (name.contains('biology') || name.contains('bio')) {
      return const Color(0xFFFFF4C4); // Light yellow
    } else if (name.contains('chemistry') || name.contains('chem')) {
      return const Color(0xFFFFE4C4); // Light orange
    } else if (name.contains('computer') || name.contains('it') || name.contains('coding')) {
      return const Color(0xFFE8F5E9); // Light green
    } else if (name.contains('english') || name.contains('language')) {
      return const Color(0xFFD4F1F4); // Light blue
    } else if (name.contains('math') || name.contains('mathematics')) {
      return const Color(0xFFF3E8FF); // Light purple
    } else if (name.contains('physics')) {
      return const Color(0xFFE0E7FF); // Light indigo/purple
    }
    
    // Fallback colors for other subjects
    final colors = [
      const Color(0xFFFFF1F2), // Pink
      const Color(0xFFF0FDF4), // Light Green
      const Color(0xFFFFF8E1), // Light Amber
      const Color(0xFFE3F2FD), // Light Blue
    ];
    return colors[index % colors.length];
  }

  Widget _buildMySubjects() {
    final levelProvider = Provider.of<LevelProvider>(context);
    final currentLevel = levelProvider.currentLevel;
    
    // Only show for Intermediate students
    if (currentLevel?.toLowerCase() != 'intermediate') {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'My Subjects',
              style: AppTextStyles.heading2.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (_isLoadingSubjects)
              const SizedBox(
                width: 20,
                height: 20,
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (_subjects.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadMySubjects,
                tooltip: 'Refresh Subjects',
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (_isLoadingSubjects)
          _buildSubjectsSkeleton()
        else if (_subjectsErrorMessage != null)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red.withOpacity(0.7),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _subjectsErrorMessage!,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _loadMySubjects,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          )
        else if (_subjects.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.school_outlined,
                    size: 48,
                    color: AppColors.textSecondary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No subjects available',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          // Display subjects in a grid (2 columns)
          ...List.generate(
            (_subjects.length / 2).ceil(),
            (rowIndex) {
              final startIndex = rowIndex * 2;
              final endIndex = (startIndex + 2 < _subjects.length) 
                  ? startIndex + 2 
                  : _subjects.length;
              final rowSubjects = _subjects.sublist(startIndex, endIndex);
              
              return Padding(
                padding: EdgeInsets.only(bottom: rowIndex < (_subjects.length / 2).ceil() - 1 ? 12 : 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start, // Changed from stretch to avoid infinite height
                  children: [
                    ...rowSubjects.asMap().entries.map((entry) {
                      final index = entry.key;
                      final subject = entry.value;
                      final subjectName = subject['name'] as String? ?? 'Subject';
                      final subjectId = subject['_id'] as String? ?? subject['id'] as String? ?? '';
                      final subjectDescription = subject['description'] as String? ?? '';
                      final globalIndex = startIndex + index;
                      
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: index < rowSubjects.length - 1 ? 12 : 0),
                          child: SizedBox(
                            height: 160, // Fixed height for all cards
                            child: Stack(
                              children: [
                                SubjectCard(
                                  emoji: _getSubjectEmoji(subjectName),
                                  subjectName: subjectName,
                                  backgroundColor: _getSubjectColor(globalIndex, subjectName),
                                  onTap: _hasActiveSubscription ? () {
                                  // Get chapters from subject data (already in API response)
                                  final chapters = subject['chapters'] as List?;
                                  final chaptersList = chapters != null
                                      ? chapters.map((c) => c as Map<String, dynamic>).toList()
                                      : null;
                                  
                                  print('=== Navigating to Subject Details ===');
                                  print('Subject: $subjectName');
                                  print('Subject ID: $subjectId');
                                  print('Chapters available: ${chaptersList != null ? chaptersList.length : 0}');
                                  
                                  // Navigate to subject details screen with chapters
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SubjectDetailsScreen(
                                        subjectId: subjectId,
                                        subjectName: subjectName,
                                        emoji: _getSubjectEmoji(subjectName),
                                        subjectColor: _getSubjectColor(globalIndex, subjectName),
                                        chapters: chaptersList, // Pass chapters from API response
                                      ),
                                    ),
                                  );
                                  } : _handleLockedFeatureTap,
                                ),
                                if (!_hasActiveSubscription)
                                  Positioned.fill(
                                    child: GestureDetector(
                                      onTap: _handleLockedFeatureTap,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.5),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.lock,
                                                color: Colors.white,
                                                size: 32,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Subscribe to unlock',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildSubjectsSkeleton() {
    // Show 4 skeleton subject cards in a 2x2 grid
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: SkeletonSubjectCard(),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 6),
                child: SkeletonSubjectCard(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: SkeletonSubjectCard(),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 6),
                child: SkeletonSubjectCard(),
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
              onPressed: _hasActiveSubscription ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AIFeaturesScreen(),
                  ),
                );
              } : _handleLockedFeatureTap,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: SizedBox(
                  height: 180, // Fixed height for consistency
                  child: Stack(
                    children: [
                      AIFeatureCard(
                        title: 'AI Tutor',
                        description: 'Get 24/7 learning assistance',
                        icon: Icons.psychology_outlined,
                        backgroundColor: const Color(0xFF6C5CE7),
                        iconColor: const Color(0xFF6C5CE7),
                        onTap: _hasActiveSubscription ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AITutorComingSoonScreen(),
                            ),
                          );
                        } : _handleLockedFeatureTap,
                      ),
                      if (!_hasActiveSubscription)
                        Positioned.fill(
                          child: GestureDetector(
                            onTap: _handleLockedFeatureTap,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.lock,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Subscribe',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 6),
                child: SizedBox(
                  height: 180, // Fixed height for consistency
                  child: Stack(
                    children: [
                      AIFeatureCard(
                        title: 'Smart Study Plan',
                        description: 'Personalized schedule',
                        icon: Icons.calendar_today_outlined,
                        backgroundColor: const Color(0xFF00B894),
                        iconColor: const Color(0xFF00B894),
                        onTap: _hasActiveSubscription ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SmartStudyPlanScreen(),
                            ),
                          );
                        } : _handleLockedFeatureTap,
                      ),
                      if (!_hasActiveSubscription)
                        Positioned.fill(
                          child: GestureDetector(
                            onTap: _handleLockedFeatureTap,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.lock,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Subscribe',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Second row - 2 cards
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: SizedBox(
                  height: 180, // Fixed height for consistency
                  child: Stack(
                    children: [
                      AIFeatureCard(
                        title: 'Doubt Solver',
                        description: 'Instant answers',
                        icon: Icons.question_answer_outlined,
                        backgroundColor: const Color(0xFFFF9F43),
                        iconColor: const Color(0xFFFF9F43),
                        onTap: _hasActiveSubscription ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const DoubtSolverScreen(),
                            ),
                          );
                        } : _handleLockedFeatureTap,
                      ),
                      if (!_hasActiveSubscription)
                        Positioned.fill(
                          child: GestureDetector(
                            onTap: _handleLockedFeatureTap,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.lock,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Subscribe',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 6),
                child: SizedBox(
                  height: 180, // Fixed height for consistency
                  child: Stack(
                    children: [
                      AIFeatureCard(
                        title: 'AI Exam',
                        description: 'Test your knowledge',
                        icon: Icons.quiz_outlined,
                        backgroundColor: const Color(0xFFE74C3C),
                        iconColor: const Color(0xFFE74C3C),
                        onTap: _hasActiveSubscription ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AIExamComingSoonScreen(),
                            ),
                          );
                        } : _handleLockedFeatureTap,
                      ),
                      if (!_hasActiveSubscription)
                        Positioned.fill(
                          child: GestureDetector(
                            onTap: _handleLockedFeatureTap,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.lock,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Subscribe',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

