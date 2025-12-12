import 'package:flutter/material.dart';
import 'dart:ui' as ui;
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
import 'math_quiz_game_screen.dart';

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
  
  // Category and Subcategory information
  String? _categoryName;
  String? _subcategoryName;
  
  // Subscription state
  bool _hasActiveSubscription = false;
  bool _isLoadingSubscription = true;

  // Courses state (My courses with progress)
  List<Map<String, dynamic>> _courses = [];
  bool _isLoadingCourses = false;
  String? _coursesErrorMessage;
  String? _selectedLevelFilter; // null = all, 'junior', 'intermediate', 'senior'
  
  // All courses state (for Play tab with filters)
  List<Map<String, dynamic>> _allCourses = [];
  bool _isLoadingAllCourses = false;
  String? _allCoursesErrorMessage;
  String? _selectedAllCoursesFilter; // null = all, 'junior', 'intermediate', 'senior'
  
  // Dashboard state
  Map<String, dynamic>? _dashboardData;
  bool _isLoadingDashboard = false;
  String? _dashboardErrorMessage;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    // Load subscription status, subjects, profile data, and courses after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSubscriptionStatus();
      _loadMySubjects();
      _loadProfileData();
      _loadCourses(); // My courses with progress
      _loadAllCourses(); // All courses with filters
      _loadDashboard(); // Dashboard data
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
            _buildAllCoursesContent(), // All courses with filters (beginner, intermediate, senior)
            _buildMyCoursesContent(), // My courses with progress
            const ProfileScreen(), // Changed from ChatScreen to ProfileScreen
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
          await Future.wait([
            _loadMySubjects(),
            _loadDashboard(),
            _loadCourses(),
          ]);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 28),
              _buildDashboardSection(), // Dashboard with API data
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
              mainAxisSize: MainAxisSize.min,
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
          const SizedBox(height: 20),
          Expanded(
            child: _isLoadingCourses
                ? _buildCoursesSkeletonLoader()
                : _coursesErrorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 48,
                                color: Colors.red.withOpacity(0.7),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _coursesErrorMessage!,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _loadCourses,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _courses.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.school_outlined,
                                    size: 48,
                                    color: AppColors.textSecondary.withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No courses available',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadCourses,
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ..._courses.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final item = entry.value;
                                    
                                    // Extract nested course object
                                    final course = item['course'] as Map<String, dynamic>? ?? {};
                                    final courseTitle = course['title'] as String? ?? 'Course';
                                    final shortDescription = course['shortDescription'] as String? ?? '';
                                    final rating = course['rating'] as Map<String, dynamic>?;
                                    final averageRating = rating?['average'] as double? ?? 0.0;
                                    final lessonsCount = course['lessonsCount'] as int? ?? 0;
                                    final level = course['level'] as String? ?? '';
                                    final price = course['price'] as int? ?? 0;
                                    final currency = course['currency'] as String? ?? 'INR';
                                    
                                    // Extract nested progress object
                                    final progress = item['progress'] as Map<String, dynamic>? ?? {};
                                    final progressPercentage = progress['percentage'] as int? ?? 0;
                                    final lessonsCompleted = progress['lessonsCompleted'] as int? ?? 0;
                                    final totalLessons = progress['totalLessons'] as int? ?? lessonsCount;
                                    
                                    // Get courseId from nested course object
                                    final courseId = course['_id'] as String? ?? '';
                                    
                                    // Get color based on index
                                    final colors = [
                                      const Color(0xFF3B82F6),
                                      const Color(0xFFF97316),
                                      const Color(0xFF9333EA),
                                      const Color(0xFFEF4444),
                                      const Color(0xFF10B981),
                                      const Color(0xFFF59E0B),
                                    ];
                                    final progressColor = colors[index % colors.length];
                                    
                                    return Padding(
                                      padding: EdgeInsets.only(
                                        bottom: index < _courses.length - 1 ? 16 : 0,
                                      ),
                                      child: MyCourseCard(
                                        courseName: courseTitle,
                                        subtitle: shortDescription.isNotEmpty 
                                            ? shortDescription 
                                            : '${lessonsCompleted}/${totalLessons} lessons completed • ${averageRating.toStringAsFixed(1)} ⭐',
                                        progressPercentage: progressPercentage,
                                        progressColor: progressColor,
                                        onTap: () {
                                          // Navigate to course details
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => CourseDetailsScreen(
                                                courseName: courseTitle,
                                                price: price == 0 
                                                    ? 'Free' 
                                                    : '$price $currency',
                                                isFree: price == 0,
                                                courseId: courseId,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  }).toList(),
                                  const SizedBox(height: 100),
                                ],
                              ),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoursesSkeletonLoader() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...List.generate(4, (index) {
            return Padding(
              padding: EdgeInsets.only(bottom: index < 3 ? 16 : 0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Circular progress skeleton
                    SkeletonLoader(
                      width: 60,
                      height: 60,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    const SizedBox(width: 16),
                    // Course info skeleton
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonLoader(
                            width: double.infinity,
                            height: 18,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          const SizedBox(height: 8),
                          SkeletonLoader(
                            width: 200,
                            height: 14,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Arrow icon skeleton
                    SkeletonLoader(
                      width: 24,
                      height: 24,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildAllCoursesContent() {
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
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'All Courses',
                  style: AppTextStyles.heading1.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Explore courses by level',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Filter buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildAllCoursesFilterChip('All', null),
                  const SizedBox(width: 8),
                  _buildAllCoursesFilterChip('Junior', 'junior'),
                  const SizedBox(width: 8),
                  _buildAllCoursesFilterChip('Intermediate', 'intermediate'),
                  const SizedBox(width: 8),
                  _buildAllCoursesFilterChip('Senior', 'senior'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _isLoadingAllCourses
                ? _buildCoursesSkeletonLoader()
                : _allCoursesErrorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 48,
                                color: Colors.red.withOpacity(0.7),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _allCoursesErrorMessage!,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _loadAllCourses,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _allCourses.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.school_outlined,
                                    size: 48,
                                    color: AppColors.textSecondary.withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No courses available',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadAllCourses,
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ..._allCourses.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final course = entry.value;
                                    final courseTitle = course['title'] as String? ?? 'Course';
                                    final shortDescription = course['shortDescription'] as String? ?? '';
                                    final rating = course['rating'] as Map<String, dynamic>?;
                                    final averageRating = rating?['average'] as double? ?? 0.0;
                                    final lessonsCount = course['lessonsCount'] as int? ?? 0;
                                    
                                    // Get color based on index
                                    final colors = [
                                      const Color(0xFF3B82F6),
                                      const Color(0xFFF97316),
                                      const Color(0xFF9333EA),
                                      const Color(0xFFEF4444),
                                      const Color(0xFF10B981),
                                      const Color(0xFFF59E0B),
                                    ];
                                    final progressColor = colors[index % colors.length];
                                    
                                    // For all courses, show 0% progress (not enrolled yet)
                                    final progressPercentage = 0;
                                    
                                    return Padding(
                                      padding: EdgeInsets.only(
                                        bottom: index < _allCourses.length - 1 ? 16 : 0,
                                      ),
                                      child: MyCourseCard(
                                        courseName: courseTitle,
                                        subtitle: shortDescription.isNotEmpty 
                                            ? shortDescription 
                                            : '${lessonsCount} lessons • ${averageRating.toStringAsFixed(1)} ⭐',
                                        progressPercentage: progressPercentage,
                                        progressColor: progressColor,
                                        onTap: () {
                                          // Navigate to course details
                                          final courseId = course['_id'] as String? ?? '';
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => CourseDetailsScreen(
                                                courseName: courseTitle,
                                                price: course['price'] == 0 
                                                    ? 'Free' 
                                                    : '${course['price']} ${course['currency'] ?? 'INR'}',
                                                isFree: course['price'] == 0,
                                                courseId: courseId,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  }).toList(),
                                  const SizedBox(height: 100),
                                ],
                              ),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? level) {
    final isSelected = _selectedLevelFilter == level;
    final levelProvider = Provider.of<LevelProvider>(context);
    final currentLevel = levelProvider.currentLevel;
    final primaryColor = LevelTheme.getPrimaryColor(currentLevel);
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedLevelFilter = selected ? level : null;
        });
        _loadCourses();
      },
      selectedColor: primaryColor.withOpacity(0.2),
      checkmarkColor: primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? primaryColor : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? primaryColor : Colors.grey.withOpacity(0.3),
        width: isSelected ? 2 : 1,
      ),
    );
  }

  Widget _buildAllCoursesFilterChip(String label, String? level) {
    final isSelected = _selectedAllCoursesFilter == level;
    final levelProvider = Provider.of<LevelProvider>(context);
    final currentLevel = levelProvider.currentLevel;
    final primaryColor = LevelTheme.getPrimaryColor(currentLevel);
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedAllCoursesFilter = selected ? level : null;
        });
        _loadAllCourses();
      },
      selectedColor: primaryColor.withOpacity(0.2),
      checkmarkColor: primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? primaryColor : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? primaryColor : Colors.grey.withOpacity(0.3),
        width: isSelected ? 2 : 1,
      ),
    );
  }

  Widget _buildDashboardSection() {
    if (_isLoadingDashboard) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (_dashboardErrorMessage != null || _dashboardData == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.red.withOpacity(0.7),
                ),
                const SizedBox(height: 12),
                Text(
                  _dashboardErrorMessage ?? 'Failed to load dashboard',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _loadDashboard,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final overview = _dashboardData!['overview'] as Map<String, dynamic>? ?? {};
    final progress = _dashboardData!['progress'] as Map<String, dynamic>? ?? {};
    final enrolledCourses = _dashboardData!['enrolledCourses'] as List? ?? [];
    
    final totalCourses = overview['totalCourses'] as int? ?? 0;
    final activeCourses = overview['activeCourses'] as int? ?? 0;
    final completedCourses = overview['completedCourses'] as int? ?? 0;
    final totalLessons = overview['totalLessons'] as int? ?? 0;
    final completedLessons = overview['completedLessons'] as int? ?? 0;
    final overallCompletion = progress['overallCompletion'] as int? ?? 0;
    final quizCompletion = progress['quizCompletion'] as int? ?? 0;
    final assignmentCompletion = progress['assignmentCompletion'] as int? ?? 0;
    
    // Calculate streak (mock for now - you can add actual streak logic)
    final streak = 12; // This should come from API if available
    
    // Determine level based on completion
    String level = 'Beginner';
    if (overallCompletion >= 80) {
      level = 'Expert';
    } else if (overallCompletion >= 50) {
      level = 'Intermediate';
    } else if (overallCompletion >= 25) {
      level = 'Advanced';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF9333EA).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.trending_up,
                  color: Color(0xFF9333EA),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'My Learning Path',
                      style: AppTextStyles.heading2.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Track your progress',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Progress Graph (Simplified visual representation)
          Container(
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF9333EA).withOpacity(0.1),
                  const Color(0xFF9333EA).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                // Progress line visualization
                CustomPaint(
                  size: Size.infinite,
                  painter: ProgressLinePainter(
                    progress: overallCompletion / 100.0,
                    color: const Color(0xFF9333EA),
                  ),
                ),
                // Progress percentage text
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$overallCompletion%',
                        style: AppTextStyles.heading1.copyWith(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF9333EA),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Overall Progress',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Key Metrics
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  icon: Icons.local_fire_department,
                  iconColor: Colors.red,
                  value: '$streak days',
                  label: 'Streak',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  icon: Icons.emoji_events,
                  iconColor: const Color(0xFF10B981),
                  value: '$overallCompletion%',
                  label: 'Progress',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  icon: Icons.star,
                  iconColor: Colors.amber,
                  value: level,
                  label: 'Level',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Overview Stats
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Overview',
                  style: AppTextStyles.heading3.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        'Courses',
                        '$activeCourses Active',
                        Icons.book,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'Lessons',
                        '$completedLessons/$totalLessons',
                        Icons.play_circle_outline,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        'Quizzes',
                        '$quizCompletion% Complete',
                        Icons.quiz,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'Assignments',
                        '$assignmentCompletion% Complete',
                        Icons.assignment,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.heading3.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
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
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      'Welcome',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Container(
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
                          Flexible(
                            child: Text(
                              LevelTheme.getLevelName(currentLevel),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
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
              // Category and Subcategory Information
              if (_categoryName != null || _subcategoryName != null) ...[
                const SizedBox(height: 8),
                Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (_categoryName != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: primaryColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.category,
                                size: 14,
                                color: primaryColor,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  _categoryName!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: primaryColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (_subcategoryName != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.secondary.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.label,
                                size: 14,
                                color: AppColors.secondary,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  _subcategoryName!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.secondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
              ],
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
              _buildNavItem(Icons.book_rounded, Icons.book_outlined, 2, currentLevel), // Changed from calendar to book icon for My Courses
              _buildNavItem(Icons.person_rounded, Icons.person_outline_rounded, 3, currentLevel), // Changed from chat to profile icon
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
      mainAxisSize: MainAxisSize.min,
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MathQuizGameScreen(
                            difficulty: 'intermediate',
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
                    title: 'Advanced Math',
                    description: 'Class 11+ level problems',
                    players: '1.5K playing',
                    backgroundColor: const Color(0xFF00B894),
                    iconColor: const Color(0xFF00B894),
                    icon: Icons.functions,
                    onTap: _hasActiveSubscription ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MathQuizGameScreen(
                            difficulty: 'advanced',
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
                    title: 'Physics Challenge',
                    description: 'Advanced physics problems',
                    players: '850 playing',
                    backgroundColor: const Color(0xFF9B59B6),
                    iconColor: const Color(0xFF9B59B6),
                    icon: Icons.science,
                    onTap: _hasActiveSubscription ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MathQuizGameScreen(
                            difficulty: 'expert',
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

  Future<void> _loadProfileData() async {
    try {
      final token = await AuthService.getToken();
      if (token != null && token.isNotEmpty) {
        final response = await ApiService.getProfile(token);
        if (response['success'] == true && response['data'] != null) {
          final profileData = response['data'] as Map<String, dynamic>;
          if (mounted) {
            setState(() {
              // Extract category and subcategory information
              if (profileData['levelCategory'] != null) {
                final levelCategory = profileData['levelCategory'] as Map<String, dynamic>;
                _categoryName = levelCategory['categoryname'] as String?;
              }
              if (profileData['subcategory'] != null) {
                final subcategory = profileData['subcategory'] as Map<String, dynamic>;
                _subcategoryName = subcategory['subcategoryname'] as String?;
              }
            });
            // Save updated profile data
            await AuthService.saveUserData(profileData);
          }
        }
      } else {
        // Try to load from cached data
        final cachedData = await AuthService.getUserData();
        if (cachedData != null && mounted) {
          setState(() {
            if (cachedData['levelCategory'] != null) {
              final levelCategory = cachedData['levelCategory'] as Map<String, dynamic>;
              _categoryName = levelCategory['categoryname'] as String?;
            }
            if (cachedData['subcategory'] != null) {
              final subcategory = cachedData['subcategory'] as Map<String, dynamic>;
              _subcategoryName = subcategory['subcategoryname'] as String?;
            }
          });
        }
      }
    } catch (e) {
      print('Error loading profile data: $e');
      // Try to load from cached data on error
      final cachedData = await AuthService.getUserData();
      if (cachedData != null && mounted) {
        setState(() {
          if (cachedData['levelCategory'] != null) {
            final levelCategory = cachedData['levelCategory'] as Map<String, dynamic>;
            _categoryName = levelCategory['categoryname'] as String?;
          }
          if (cachedData['subcategory'] != null) {
            final subcategory = cachedData['subcategory'] as Map<String, dynamic>;
            _subcategoryName = subcategory['subcategoryname'] as String?;
          }
        });
      }
    }
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

  Future<void> _loadCourses() async {
    setState(() {
      _isLoadingCourses = true;
      _coursesErrorMessage = null;
    });

    try {
      final token = await AuthService.getToken();
      if (token != null && token.isNotEmpty) {
        // Use with-progress API for "My courses"
        final response = await ApiService.getCoursesWithProgress(
          token,
          page: 1,
          limit: 10,
        );
        
        if (mounted) {
          if (response['success'] == true && response['data'] != null) {
            final data = response['data'] as Map<String, dynamic>;
            final items = data['items'] as List? ?? [];
            
            // Store the full nested structure from API
            setState(() {
              _courses = items
                  .map((item) => item as Map<String, dynamic>)
                  .toList();
              _isLoadingCourses = false;
              _coursesErrorMessage = null;
            });
          } else {
            setState(() {
              _coursesErrorMessage = response['message'] ?? 'Failed to load courses';
              _isLoadingCourses = false;
              _courses = [];
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _coursesErrorMessage = 'Not authenticated';
            _isLoadingCourses = false;
            _courses = [];
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _coursesErrorMessage = 'Error loading courses: ${e.toString()}';
          _isLoadingCourses = false;
          _courses = [];
        });
      }
    }
  }

  Future<void> _loadAllCourses() async {
    setState(() {
      _isLoadingAllCourses = true;
      _allCoursesErrorMessage = null;
    });

    try {
      final token = await AuthService.getToken();
      if (token != null && token.isNotEmpty) {
        // Map filter level to API format
        String? apiLevel;
        if (_selectedAllCoursesFilter != null) {
          switch (_selectedAllCoursesFilter!.toLowerCase()) {
            case 'junior':
              apiLevel = 'beginner';
              break;
            case 'intermediate':
              apiLevel = 'intermediate';
              break;
            case 'senior':
              apiLevel = 'advanced';
              break;
            default:
              apiLevel = null;
          }
        }
        
        final response = await ApiService.getCoursesWithFilters(
          token,
          page: 1,
          limit: 12,
          sort: 'rating',
          level: apiLevel,
        );
        
        if (mounted) {
          if (response['success'] == true && response['data'] != null) {
            final data = response['data'] as Map<String, dynamic>;
            final items = data['items'] as List? ?? [];
            
            setState(() {
              _allCourses = items
                  .map((item) => item as Map<String, dynamic>)
                  .toList();
              _isLoadingAllCourses = false;
              _allCoursesErrorMessage = null;
            });
          } else {
            setState(() {
              _allCoursesErrorMessage = response['message'] ?? 'Failed to load courses';
              _isLoadingAllCourses = false;
              _allCourses = [];
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _allCoursesErrorMessage = 'Not authenticated';
            _isLoadingAllCourses = false;
            _allCourses = [];
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _allCoursesErrorMessage = 'Error loading courses: ${e.toString()}';
          _isLoadingAllCourses = false;
          _allCourses = [];
        });
      }
    }
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoadingDashboard = true;
      _dashboardErrorMessage = null;
    });

    try {
      final token = await AuthService.getToken();
      if (token != null && token.isNotEmpty) {
        final response = await ApiService.getDashboard(token);
        
        if (mounted) {
          if (response['success'] == true && response['data'] != null) {
            setState(() {
              _dashboardData = response['data'] as Map<String, dynamic>;
              _isLoadingDashboard = false;
              _dashboardErrorMessage = null;
            });
          } else {
            setState(() {
              _dashboardErrorMessage = response['message'] ?? 'Failed to load dashboard data';
              _isLoadingDashboard = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _dashboardErrorMessage = 'Not authenticated';
            _isLoadingDashboard = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _dashboardErrorMessage = 'Error loading dashboard: ${e.toString()}';
          _isLoadingDashboard = false;
        });
      }
    }
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
        // Get selected board ID from storage
        String? selectedBoardId = await AuthService.getSelectedBoardId();
        
        // Get student ID for board storage
        final userData = await AuthService.getUserData();
        final studentId = userData?['studentId'] as String?;
        
        print('Calling API: GET /api/students/my-subjects-list');
        print('Selected Board ID: $selectedBoardId');
        print('Authorization: Bearer ${token.substring(0, token.length > 20 ? 20 : token.length)}...');
        
        // Call API with boardId filter if available
        final response = await ApiService.getMySubjects(
          token,
          boardId: selectedBoardId,
        );
        print('API Response received: success=${response['success']}');
        
        if (mounted) {
          if (response['success'] == true && response['data'] != null) {
            final data = response['data'] as Map<String, dynamic>;
            // New API returns 'items' instead of 'subjects'
            final subjects = data['items'] as List? ?? [];
            
            // Auto-detect board from API response if not already selected
            String? detectedBoardId = selectedBoardId;
            if (detectedBoardId == null && subjects.isNotEmpty) {
              // Try to get board from first subject
              final firstSubject = subjects[0] as Map<String, dynamic>?;
              if (firstSubject != null && firstSubject['board'] != null) {
                final board = firstSubject['board'] as Map<String, dynamic>?;
                detectedBoardId = board?['_id'] as String?;
                if (detectedBoardId != null && detectedBoardId.isNotEmpty) {
                  print('Auto-detected board ID from first subject: $detectedBoardId');
                  // Save detected board
                  await AuthService.saveSelectedBoardId(detectedBoardId);
                  if (studentId != null) {
                    await AuthService.saveBoardForStudent(studentId, detectedBoardId);
                  }
                }
              }
            }
            
            setState(() {
              // Map and filter subjects
              List<Map<String, dynamic>> mappedSubjects = subjects
                  .map((s) => s as Map<String, dynamic>)
                  .where((s) => s['isActive'] == true)
                  .toList();
              
              // Filter by board if board ID is available
              if (detectedBoardId != null && detectedBoardId.isNotEmpty) {
                mappedSubjects = mappedSubjects.where((subject) {
                  final board = subject['board'] as Map<String, dynamic>?;
                  final boardId = board?['_id'] as String?;
                  return boardId == detectedBoardId;
                }).toList();
                print('Filtered subjects by board ID $detectedBoardId: ${mappedSubjects.length} subjects');
              }
              
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
              print('Total subjects before filtering: ${subjects.length}');
              print('Total subjects after board filter: ${mappedSubjects.length}');
              print('Total subjects after deduplication and chapter filter: ${_subjects.length}');
              print('Selected Board ID: $detectedBoardId');
              for (var subject in _subjects) {
                final chapters = subject['chapters'] as List?;
                final chapterCount = subject['chapterCount'] as int?;
                final subjectId = subject['_id'] as String? ?? subject['id'] as String? ?? '';
                final actualChapterCount = chapters?.length ?? chapterCount ?? 0;
                final board = subject['board'] as Map<String, dynamic>?;
                final boardName = board?['name'] as String? ?? 'Unknown';
                print('Subject: ${subject['name']}, ID: $subjectId, Board: $boardName, Chapters: $actualChapterCount');
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
      mainAxisSize: MainAxisSize.min,
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
                mainAxisSize: MainAxisSize.min,
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
                mainAxisSize: MainAxisSize.min,
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
                                            mainAxisSize: MainAxisSize.min,
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
      mainAxisSize: MainAxisSize.min,
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
      mainAxisSize: MainAxisSize.min,
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

// Custom painter for progress line graph
class ProgressLinePainter extends CustomPainter {
  final double progress;
  final Color color;

  ProgressLinePainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    // Create a simple upward trending line
    final path = Path();
    final points = 8;
    final stepX = size.width / (points - 1);
    final baseY = size.height * 0.8;
    final maxHeight = size.height * 0.6;

    path.moveTo(0, baseY);

    for (int i = 0; i < points; i++) {
      final x = i * stepX;
      final progressFactor = (i / (points - 1)) * progress;
      final y = baseY - (maxHeight * progressFactor);
      path.lineTo(x, y);
    }

    // Create fill path
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    // Draw fill
    canvas.drawPath(fillPath, fillPaint);

    // Draw line
    canvas.drawPath(path, paint);

    // Draw points
    final pointPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (int i = 0; i < points; i++) {
      final x = i * stepX;
      final progressFactor = (i / (points - 1)) * progress;
      final y = baseY - (maxHeight * progressFactor);
      canvas.drawCircle(Offset(x, y), 4, pointPaint);
      canvas.drawCircle(Offset(x, y), 4, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2);
    }
  }

  @override
  bool shouldRepaint(ProgressLinePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

