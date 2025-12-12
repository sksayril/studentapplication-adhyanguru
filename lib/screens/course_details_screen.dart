import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';
import '../utils/navigation_helper.dart';
import '../widgets/skeleton_loader.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'subscriptions_screen.dart';
import 'lesson_viewer_screen.dart';

class CourseDetailsScreen extends StatefulWidget {
  final String courseName;
  final String price;
  final bool isFree;
  final String? courseId;

  const CourseDetailsScreen({
    Key? key,
    required this.courseName,
    required this.price,
    this.isFree = false,
    this.courseId,
  }) : super(key: key);

  @override
  State<CourseDetailsScreen> createState() => _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends State<CourseDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTab = 0;
  bool _isExpanded = false;
  bool _isEnrolling = false;
  bool _isEnrolled = false;
  
  // Course data from API
  Map<String, dynamic>? _courseData;
  List<Map<String, dynamic>> _sections = [];
  Map<String, dynamic>? _enrollmentData;
  Map<String, dynamic>? _progressData;
  bool _isLoadingCourse = false;
  String? _courseErrorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTab = _tabController.index;
      });
    });
    
    // Load course details if courseId is provided
    if (widget.courseId != null && widget.courseId!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadCourseDetails();
        _loadCourseProgress();
      });
    }
  }
  
  Future<void> _loadCourseDetails() async {
    if (widget.courseId == null || widget.courseId!.isEmpty) return;
    
    setState(() {
      _isLoadingCourse = true;
      _courseErrorMessage = null;
    });
    
    try {
      final token = await AuthService.getToken();
      if (token != null && token.isNotEmpty) {
        final response = await ApiService.getCourseDetails(token, widget.courseId!);
        
        if (mounted) {
          if (response['success'] == true && response['data'] != null) {
            final data = response['data'] as Map<String, dynamic>;
            final course = data['course'] as Map<String, dynamic>?;
            final sections = data['sections'] as List? ?? [];
            final enrollment = data['enrollment'] as Map<String, dynamic>?;
            
            setState(() {
              _courseData = course;
              _sections = sections.map((s) => s as Map<String, dynamic>).toList();
              _enrollmentData = enrollment;
              _isEnrolled = data['isEnrolled'] as bool? ?? false;
              _isLoadingCourse = false;
              _courseErrorMessage = null;
            });
            
            // Load progress after course details are loaded
            await _loadCourseProgress();
          } else {
            setState(() {
              _courseErrorMessage = response['message'] ?? 'Failed to load course details';
              _isLoadingCourse = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _courseErrorMessage = 'Not authenticated';
            _isLoadingCourse = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _courseErrorMessage = 'Error loading course: ${e.toString()}';
          _isLoadingCourse = false;
        });
      }
    }
  }
  
  Future<void> _loadCourseProgress() async {
    if (widget.courseId == null || widget.courseId!.isEmpty) return;
    
    try {
      final token = await AuthService.getToken();
      if (token != null && token.isNotEmpty) {
        final response = await ApiService.getCourseProgress(token, widget.courseId!);
        
        if (mounted && response['success'] == true && response['data'] != null) {
          setState(() {
            _progressData = response['data'] as Map<String, dynamic>?;
          });
        }
      }
    } catch (e) {
      print('Error loading course progress: $e');
    }
  }

  void _startLearning() {
    // Switch to Subject tab and scroll to first incomplete lesson
    if (_tabController.index != 2) {
      _tabController.animateTo(2);
    }
    // You can add scroll to first incomplete lesson logic here
  }

  Future<void> _openLesson(Map<String, dynamic> lesson) async {
    if (widget.courseId == null || widget.courseId!.isEmpty) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LessonViewerScreen(
          lesson: lesson,
          courseId: widget.courseId!,
          isEnrolled: _isEnrolled,
        ),
      ),
    );

    // If lesson was marked as complete, reload course details and progress
    if (result == true && mounted) {
      await _loadCourseDetails();
      await _loadCourseProgress();
    }
  }

  Future<void> _markLessonComplete(String lessonId, bool completed) async {
    if (widget.courseId == null || widget.courseId!.isEmpty) return;
    
    try {
      final token = await AuthService.getToken();
      if (token != null && token.isNotEmpty) {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Updating progress...'),
              ],
            ),
          ),
        );

        final response = await ApiService.markLessonComplete(
          token,
          widget.courseId!,
          lessonId,
          completed,
        );

        if (mounted) {
          Navigator.pop(context); // Pop loading dialog

          if (response['success'] == true && response['data'] != null) {
            final data = response['data'] as Map<String, dynamic>;
            final progress = data['progress'] as Map<String, dynamic>?;
            
            // Update progress data
            setState(() {
              _progressData = progress;
            });
            
            // Reload course details to get updated lesson completion status
            await _loadCourseDetails();
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  completed 
                      ? 'Lesson marked as complete!'
                      : 'Lesson marked as incomplete',
                ),
                backgroundColor: AppColors.successGreen,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  response['message'] ?? 'Failed to update lesson progress',
                ),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          Navigator.pop(context); // Pop loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Not authenticated'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Pop loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
              child: _isLoadingCourse && widget.courseId != null && widget.courseId!.isNotEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _courseErrorMessage != null && widget.courseId != null && widget.courseId!.isNotEmpty
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
                                  _courseErrorMessage!,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: () {
                                    _loadCourseDetails();
                                    _loadCourseProgress();
                                  },
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildVideoPreview(),
                              const SizedBox(height: 20),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildCourseTitle(),
                                    const SizedBox(height: 12),
                                    _buildCourseInfo(),
                                    const SizedBox(height: 24),
                                    _buildTabs(),
                                    const SizedBox(height: 24),
                                    _buildTabContent(),
                                    const SizedBox(height: 120),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const CustomBackButton(
            backgroundColor: Colors.transparent,
            iconColor: AppColors.textPrimary,
          ),
          Text(
            'Details about course',
            style: AppTextStyles.heading2.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.bookmark_outline,
              size: 24,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPreview() {
    final thumbnailUrl = _courseData?['thumbnailUrl'] as String?;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.pink[100]!,
            Colors.pink[50]!,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Course thumbnail
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: thumbnailUrl != null && thumbnailUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: thumbnailUrl,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => SkeletonLoader(
                        width: double.infinity,
                        height: 200,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.pink[50],
                        child: const Icon(
                          Icons.video_library,
                          size: 80,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : Container(
                      color: Colors.pink[50],
                      child: const Icon(
                        Icons.video_library,
                        size: 80,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          // Controls overlay
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.pause,
                      size: 20,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Preview',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.edit_outlined,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.fullscreen,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseTitle() {
    final title = _courseData?['title'] as String? ?? widget.courseName;
    return Text(
      title,
      style: AppTextStyles.heading1.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildCourseInfo() {
    final lessonsCount = _courseData?['lessonsCount'] as int? ?? 0;
    final durationMinutes = _courseData?['durationMinutes'] as int? ?? 0;
    final durationHours = (durationMinutes / 60).toStringAsFixed(1);
    
    return Row(
      children: [
        _buildInfoChip(Icons.play_circle_outline, '$lessonsCount lessons'),
        const SizedBox(width: 16),
        _buildInfoChip(Icons.access_time, '$durationHours hours'),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
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
          Expanded(child: _buildTabItem('Details', 0)),
          Expanded(child: _buildTabItem('Mentors', 1)),
          Expanded(child: _buildTabItem('Subject', 2)),
        ],
      ),
    );
  }

  Widget _buildTabItem(String title, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        _tabController.animateTo(index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _selectedTab == 0
          ? _buildDetailsTab()
          : _selectedTab == 1
              ? _buildMentorsTab()
              : _buildSubjectTab(),
    );
  }

  Widget _buildDetailsTab() {
    final longDescription = _courseData?['longDescription'] as String? ?? 
                           _courseData?['shortDescription'] as String? ?? 
                           'Course description not available.';
    final lessonsCount = _courseData?['lessonsCount'] as int? ?? 0;
    final durationMinutes = _courseData?['durationMinutes'] as int? ?? 0;
    final durationHours = (durationMinutes / 60).toStringAsFixed(1);
    final rating = _courseData?['rating'] as Map<String, dynamic>?;
    final averageRating = rating?['average'] as double? ?? 0.0;
    final ratingCount = rating?['count'] as int? ?? 0;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Description
        Text(
          longDescription,
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: 15,
            height: 1.6,
            color: AppColors.textSecondary,
          ),
          maxLines: _isExpanded ? null : 3,
          overflow: _isExpanded ? null : TextOverflow.ellipsis,
        ),
        if (longDescription.length > 100)
          GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _isExpanded ? 'See less' : 'See more',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        const SizedBox(height: 24),
        // Features
        _buildFeatureItem(Icons.play_circle_outline, '$lessonsCount lessons'),
        const SizedBox(height: 16),
        _buildFeatureItem(Icons.access_time, '$durationHours hours total duration'),
        const SizedBox(height: 16),
        _buildFeatureItem(Icons.star, '${averageRating.toStringAsFixed(1)} rating ($ratingCount reviews)'),
        const SizedBox(height: 16),
        _buildFeatureItem(Icons.person_outline, 'Expert instructor'),
      ],
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  Widget _buildMentorsTab() {
    final tutor = _courseData?['tutorId'] as Map<String, dynamic>?;
    final tutorName = tutor?['name'] as String? ?? 'Instructor';
    final tutorEmail = tutor?['email'] as String?;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (tutor != null)
          _buildMentorCard(
            tutorName,
            'Course Instructor',
            tutorEmail ?? 'Expert instructor',
          )
        else
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Instructor information not available',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMentorCard(String name, String title, String experience) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
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
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: const Icon(
              Icons.person,
              color: AppColors.primary,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.heading3.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  experience,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectTab() {
    if (_isLoadingCourse) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (_courseErrorMessage != null) {
      return Center(
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
                _courseErrorMessage!,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    if (_sections.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'No sections available',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }
    
    // Get completed lesson IDs from progress
    final completedLessons = <String>{};
    
    // First check progress data from API
    if (_progressData != null) {
      final completed = _progressData!['completedLessons'] as List?;
      if (completed != null) {
        completedLessons.addAll(completed.map((id) => id.toString()));
      }
    }
    
    // Also check enrollment data progress
    if (_enrollmentData != null) {
      final progress = _enrollmentData!['progress'] as Map<String, dynamic>?;
      if (progress != null) {
        final completed = progress['completedLessons'] as List?;
        if (completed != null) {
          completedLessons.addAll(completed.map((id) => id.toString()));
        }
      }
    }
    
    // Also check lessons in sections for completion status
    for (var section in _sections) {
      final lessons = section['lessons'] as List? ?? [];
      for (var lesson in lessons) {
        final lessonMap = lesson as Map<String, dynamic>;
        final lessonId = lessonMap['_id'] as String? ?? '';
        final isCompleted = lessonMap['isCompleted'] as bool? ?? false;
        if (isCompleted && lessonId.isNotEmpty) {
          completedLessons.add(lessonId);
        }
      }
    }
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ..._sections.map((section) {
          final sectionTitle = section['title'] as String? ?? 'Section';
          final sectionDescription = section['description'] as String? ?? '';
          final lessons = section['lessons'] as List? ?? [];
          final lessonsCount = lessons.length;
          
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  sectionTitle,
                  style: AppTextStyles.heading3.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (sectionDescription.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    sectionDescription,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ...lessons.asMap().entries.map((lessonEntry) {
                final lessonIndex = lessonEntry.key;
                final lesson = lessonEntry.value as Map<String, dynamic>;
                final lessonId = lesson['_id'] as String? ?? '';
                final lessonTitle = lesson['title'] as String? ?? 'Lesson';
                final lessonDuration = lesson['durationMinutes'] as int? ?? 0;
                final isCompleted = completedLessons.contains(lessonId) || 
                                   (lesson['isCompleted'] as bool? ?? false);
                final contentType = lesson['contentType'] as String? ?? 'video';
                
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: lessonIndex < lessons.length - 1 ? 12 : 0,
                  ),
                  child: InkWell(
                    onTap: _isEnrolled
                        ? () => _openLesson(lesson)
                        : null,
                    child: _buildSubjectItem(
                      lessonTitle,
                      '${(lessonDuration / 60).toStringAsFixed(1)} min • ${contentType}',
                      isCompleted,
                      lessonId: lessonId,
                      onTap: () => _markLessonComplete(lessonId, !isCompleted),
                    ),
                  ),
                );
              }),
              if (_sections.indexOf(section) < _sections.length - 1)
                const SizedBox(height: 24),
            ],
          );
        }).toList(),
      ],
    );
  }

  Widget _buildSubjectItem(
    String title,
    String lessons,
    bool isCompleted, {
    String? lessonId,
    VoidCallback? onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted ? AppColors.successGreen : Colors.transparent,
          width: 1.5,
        ),
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
          Icon(
            isCompleted ? Icons.check_circle : Icons.play_circle_outline,
            color: isCompleted ? AppColors.successGreen : AppColors.textSecondary,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.heading3.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  lessons,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (_isEnrolled && !isCompleted && lessonId != null)
            TextButton(
              onPressed: onTap,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Mark Complete',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else if (isCompleted)
            const Icon(
              Icons.check_circle,
              color: AppColors.successGreen,
              size: 24,
            )
          else
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textSecondary,
            ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Price',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.isFree ? 'Free' : widget.price,
                  style: AppTextStyles.heading1.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: widget.isFree ? AppColors.successGreen : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 24),
            Expanded(
              child: ElevatedButton(
                onPressed: _isEnrolled 
                    ? () {
                        // Navigate to first lesson or continue from last accessed
                        _startLearning();
                      }
                    : () {
                        _showEnrollDialog();
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                  shadowColor: AppColors.primary.withOpacity(0.3),
                ),
                child: _isEnrolled
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.play_arrow, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Start Learning',
                            style: AppTextStyles.buttonText.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        widget.isFree ? 'Enroll Now' : 'Get admitted',
                        style: AppTextStyles.buttonText.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEnrollDialog() {
    showDialog(
      context: context,
      barrierDismissible: !_isEnrolling,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            widget.isFree ? 'Enroll in Course' : 'Purchase Course',
            style: AppTextStyles.heading2,
          ),
          content: _isEnrolling
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Please wait...',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                )
              : Text(
                  widget.isFree
                      ? 'Do you want to enroll in this free course?'
                      : 'Do you want to purchase this course for ${widget.price}?',
                  style: AppTextStyles.bodyMedium,
                ),
          actions: _isEnrolling
              ? []
              : [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (widget.courseId == null || widget.courseId!.isEmpty) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Course ID is missing'),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                        return;
                      }

                      setDialogState(() {
                        _isEnrolling = true;
                      });

                      try {
                        final token = await AuthService.getToken();
                        if (token == null || token.isEmpty) {
                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Please login to enroll'),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          }
                          return;
                        }

                        final response = await ApiService.enrollInCourse(
                          token,
                          widget.courseId!,
                        );

                        if (mounted) {
                          Navigator.pop(context);
                          
                          if (response['success'] == true) {
                            setState(() {
                              _isEnrolled = true;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  widget.isFree
                                      ? 'Successfully enrolled in course!'
                                      : 'Course purchased successfully!',
                                ),
                                backgroundColor: AppColors.successGreen,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          } else {
                            // Check if subscription is required
                            final requiresSubscription = response['requiresSubscription'] as bool? ?? false;
                            
                            if (requiresSubscription) {
                              // Show dialog with subscription requirement message
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  title: const Text(
                                    'Subscription Required',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  content: Text(
                                    response['details'] as String? ?? 
                                    response['message'] ?? 
                                    'You need an active subscription to enroll in courses. Please purchase a subscription plan to continue.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text(
                                        'Cancel',
                                        style: TextStyle(color: AppColors.textSecondary),
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        // Navigate to subscription screen
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const SubscriptionsScreen(),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: const Text(
                                        'Get Subscription',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              // Show regular error message
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    response['message'] ?? 'Failed to enroll in course',
                                  ),
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            }
                          }
                        }
                      } catch (e) {
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: ${e.toString()}'),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        }
                      } finally {
                        if (mounted) {
                          setState(() {
                            _isEnrolling = false;
                          });
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      widget.isFree ? 'Enroll' : 'Purchase',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
        ),
      ),
    );
  }
}

