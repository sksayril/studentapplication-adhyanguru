import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';
import '../utils/level_theme.dart';
import '../utils/education_level.dart';
import '../providers/level_provider.dart';
import '../widgets/skeleton_loader.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import 'subject_selection_screen.dart';
import 'junior/junior_courses_screen.dart';
import 'junior/junior_ai_features_screen.dart';
import 'junior/junior_profile_screen.dart';
import 'junior/junior_exam_syllabus_screen.dart';
import 'junior/subject_details_screen.dart';
import 'junior/quiz_history_screen.dart';
import '../services/quiz_database.dart';
import 'subscriptions_screen.dart';

class JuniorHomeScreen extends StatefulWidget {
  const JuniorHomeScreen({Key? key}) : super(key: key);

  @override
  State<JuniorHomeScreen> createState() => _JuniorHomeScreenState();
}

class _JuniorHomeScreenState extends State<JuniorHomeScreen> {
  int _selectedIndex = 0;
  late PageController _pageController;
  String? _profileImageUrl;
  List<Map<String, dynamic>> _competitiveExams = [];
  bool _isLoadingExams = true;
  List<Map<String, dynamic>> _subjects = [];
  bool _isLoadingSubjects = true;
  String? _subjectsErrorMessage;
  Map<String, dynamic>? _classInfo;
  List<Map<String, dynamic>> _recentQuizResults = [];
  bool _isLoadingQuizResults = true;
  Map<String, dynamic>? _quizStatistics;
  final QuizDatabase _quizDb = QuizDatabase.instance;
  
  // Subscription state
  bool _hasActiveSubscription = false;
  bool _isLoadingSubscription = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _loadProfileImage();
    _loadCompetitiveExams();
    _loadMySubjects();
    _loadRecentQuizResults();
    _loadSubscriptionStatus();
  }

  Future<void> _loadProfileImage() async {
    try {
      // First try cached data
      final cachedData = await AuthService.getUserData();
      if (cachedData != null) {
        if (cachedData['profileImage'] != null) {
          setState(() {
            _profileImageUrl = cachedData['profileImage'] as String?;
          });
        }
        // Load class info from cache
        if (cachedData['class'] != null) {
          final classData = cachedData['class'] as Map<String, dynamic>;
          setState(() {
            _classInfo = classData;
          });
        }
      }

      // Then try to get fresh data from API
      final token = await AuthService.getToken();
      if (token != null && token.isNotEmpty) {
        final response = await ApiService.getProfile(token);
        if (response['success'] == true && response['data'] != null) {
          final profileData = response['data'] as Map<String, dynamic>;
          if (mounted) {
            setState(() {
              _profileImageUrl = profileData['profileImage'] as String?;
              // Extract class information
              if (profileData['class'] != null) {
                _classInfo = profileData['class'] as Map<String, dynamic>;
              }
            });
            // Save updated data including class info
            await AuthService.saveUserData(profileData);
            await AuthService.saveUserInfo({
              'token': token,
              'data': profileData,
            });
          }
        }
      }
    } catch (e) {
      // Silently fail - use cached data if available
      print('Error loading profile image: $e');
      // Try to load class info from AuthService
      final classInfo = await AuthService.getClassInfo();
      if (classInfo != null && mounted) {
        setState(() {
          _classInfo = classInfo;
        });
      }
    }
  }

  Future<void> _loadCompetitiveExams() async {
    setState(() {
      _isLoadingExams = true;
    });

    try {
      final response = await ApiService.getCompetitiveExams(level: 'junior');
      
      if (mounted) {
        if (response['success'] == true && response['data'] != null) {
          final exams = response['data'] as List;
          setState(() {
            _competitiveExams = exams
                .map((exam) => exam as Map<String, dynamic>)
                .where((exam) => exam['isActive'] == true)
                .toList();
            _isLoadingExams = false;
          });
        } else {
          setState(() {
            _competitiveExams = [];
            _isLoadingExams = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _competitiveExams = [];
          _isLoadingExams = false;
        });
      }
      print('Error loading competitive exams: $e');
    }
  }

  // Helper function to get emoji and colors based on exam code
  Map<String, dynamic> _getExamStyle(String code, String name) {
    final codeUpper = code.toUpperCase();
    final nameUpper = name.toUpperCase();
    
    // UPSC exams
    if (codeUpper.contains('UPSC') || nameUpper.contains('UPSC') || nameUpper.contains('IAS')) {
      return {
        'emoji': '📚',
        'color': const Color(0xFF8B5CF6),
        'backgroundColor': const Color(0xFFF3E8FF),
      };
    } 
    // SSC exams - different variants
    else if (codeUpper.contains('SSC') || nameUpper.contains('SSC')) {
      if (nameUpper.contains('CHSL')) {
        return {
          'emoji': '📋',
          'color': const Color(0xFF3B82F6),
          'backgroundColor': const Color(0xFFDBEAFE),
        };
      } else if (nameUpper.contains('CPO')) {
        return {
          'emoji': '👮',
          'color': const Color(0xFF3B82F6),
          'backgroundColor': const Color(0xFFDBEAFE),
        };
      } else if (nameUpper.contains('GD') || nameUpper.contains('GENERAL DUTY')) {
        return {
          'emoji': '🛡️',
          'color': const Color(0xFF3B82F6),
          'backgroundColor': const Color(0xFFDBEAFE),
        };
      } else if (nameUpper.contains('MTS')) {
        return {
          'emoji': '🔧',
          'color': const Color(0xFF3B82F6),
          'backgroundColor': const Color(0xFFDBEAFE),
        };
      } else if (nameUpper.contains('STENO')) {
        return {
          'emoji': '⌨️',
          'color': const Color(0xFF3B82F6),
          'backgroundColor': const Color(0xFFDBEAFE),
        };
      } else {
        return {
          'emoji': '🏛️',
          'color': const Color(0xFF3B82F6),
          'backgroundColor': const Color(0xFFDBEAFE),
        };
      }
    } 
    // Railway exams
    else if (codeUpper.contains('RAILWAY') || nameUpper.contains('RAILWAY') || 
             codeUpper.contains('RRB') || nameUpper.contains('RRB')) {
      return {
        'emoji': '🚂',
        'color': const Color(0xFF6366F1),
        'backgroundColor': const Color(0xFFE0E7FF),
      };
    }
    // Banking exams
    else if (codeUpper.contains('BANK') || nameUpper.contains('BANK') || 
             codeUpper.contains('IBPS') || nameUpper.contains('IBPS') ||
             codeUpper.contains('SBI') || nameUpper.contains('SBI')) {
      return {
        'emoji': '💼',
        'color': const Color(0xFFEC4899),
        'backgroundColor': const Color(0xFFFCE7F3),
      };
    }
    // IIT JEE exams
    else if (codeUpper.contains('JEE') || nameUpper.contains('JEE') || nameUpper.contains('IIT')) {
      return {
        'emoji': '🎓',
        'color': const Color(0xFFF59E0B),
        'backgroundColor': const Color(0xFFFEF3C7),
      };
    }
    // NEET exams
    else if (codeUpper.contains('NEET') || nameUpper.contains('NEET')) {
      return {
        'emoji': '⚕️',
        'color': const Color(0xFF10B981),
        'backgroundColor': const Color(0xFFD1FAE5),
      };
    }
    // NDA exams
    else if (codeUpper.contains('NDA') || nameUpper.contains('NDA')) {
      return {
        'emoji': '📖',
        'color': const Color(0xFFEF4444),
        'backgroundColor': const Color(0xFFFEE2E2),
      };
    }
    // Defense exams
    else if (nameUpper.contains('DEFENSE') || nameUpper.contains('DEFENCE')) {
      return {
        'emoji': '🎖️',
        'color': const Color(0xFFEF4444),
        'backgroundColor': const Color(0xFFFEE2E2),
      };
    }
    // Police exams
    else if (nameUpper.contains('POLICE')) {
      return {
        'emoji': '👮',
        'color': const Color(0xFF3B82F6),
        'backgroundColor': const Color(0xFFDBEAFE),
      };
    }
    // Default style
    else {
      return {
        'emoji': '📝',
        'color': const Color(0xFF6B7280),
        'backgroundColor': const Color(0xFFF3F4F6),
      };
    }
  }

  String _getShortName(String name) {
    // First, try to extract text from parentheses (short form/code)
    if (name.contains('(') && name.contains(')')) {
      final match = RegExp(r'\(([^)]+)\)').firstMatch(name);
      if (match != null) {
        final shortForm = match.group(1)?.trim() ?? '';
        if (shortForm.isNotEmpty && shortForm.length <= 20) {
          return shortForm;
        }
      }
    }
    
    // If no parentheses or short form is too long, use the part before parentheses
    if (name.contains('(')) {
      final beforeParentheses = name.split('(').first.trim();
      if (beforeParentheses.isNotEmpty) {
        // Truncate if too long
        if (beforeParentheses.length > 18) {
          return beforeParentheses.substring(0, 15) + '...';
        }
        return beforeParentheses;
      }
    }
    
    // If name is too long, truncate it
    if (name.length > 18) {
      return name.substring(0, 15) + '...';
    }
    
    return name;
  }

  String _getSubtitle(String name, String? description) {
    // Priority 1: Extract text from parentheses (if it's a description, not a code)
    if (name.contains('(') && name.contains(')')) {
      final match = RegExp(r'\(([^)]+)\)').firstMatch(name);
      if (match != null) {
        final textInParentheses = match.group(1)?.trim() ?? '';
        // If it's a short code (like SSC, RRB, IBPS), use the part before parentheses as subtitle
        if (textInParentheses.length <= 5 && textInParentheses == textInParentheses.toUpperCase()) {
          // It's likely a code, so use the main name part as subtitle
          final beforeParentheses = name.split('(').first.trim();
          if (beforeParentheses.isNotEmpty && beforeParentheses.length <= 25) {
            return beforeParentheses;
          }
        } else {
          // It's a description, use it
          if (textInParentheses.length <= 25) {
            return textInParentheses;
          }
        }
      }
    }
    
    // Priority 2: Extract from main name if it contains common patterns
    if (name.contains(' - ')) {
      final parts = name.split(' - ');
      if (parts.length > 1 && parts[1].length <= 25) {
        return parts[1].trim();
      }
    }
    
    // Priority 3: Use description if available and short
    if (description != null && description.isNotEmpty) {
      // Clean up description
      String cleanDesc = description.trim();
      if (cleanDesc.length > 25) {
        cleanDesc = cleanDesc.substring(0, 22) + '...';
      }
      return cleanDesc;
    }
    
    // Priority 4: Extract key words from name
    final nameUpper = name.toUpperCase();
    if (nameUpper.contains('CIVIL SERVICES')) return 'Civil Services';
    if (nameUpper.contains('STAFF SELECTION')) return 'Staff Selection';
    if (nameUpper.contains('COMBINED HIGHER')) return 'Combined Higher...';
    if (nameUpper.contains('CENTRAL POLICE')) return 'Central Police...';
    if (nameUpper.contains('GENERAL DUTY')) return 'General Duty...';
    if (nameUpper.contains('MULTI-TASKING') || nameUpper.contains('MTS')) return 'Multi-Tasking Staff';
    if (nameUpper.contains('STENO')) return 'Stenographer';
    if (nameUpper.contains('ENGINEERING')) return 'Engineering';
    if (nameUpper.contains('MEDICAL')) return 'Medical Entrance';
    if (nameUpper.contains('DEFENSE') || nameUpper.contains('DEFENCE')) return 'Defense Academy';
    if (nameUpper.contains('BANKING')) return 'IBPS, SBI';
    if (nameUpper.contains('RAILWAY')) return 'RRB';
    
    // Priority 5: Use code if available in name
    final codeMatch = RegExp(r'\b([A-Z]{2,5})\b').firstMatch(name);
    if (codeMatch != null) {
      final code = codeMatch.group(1);
      if (code != null && code.length >= 2 && code.length <= 5) {
        return code;
      }
    }
    
    return '';
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
    final currentLevel = levelProvider.currentLevel ?? EducationLevel.junior;
    
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
            const JuniorCoursesScreen(),
            const JuniorAIFeaturesScreen(),
            const JuniorProfileScreen(),
          ],
        ),
      ),
      ),
      bottomNavigationBar: _buildBottomNavBar(currentLevel),
    );
  }

  Future<void> _loadMySubjects() async {
    setState(() {
      _isLoadingSubjects = true;
      _subjectsErrorMessage = null;
    });

    try {
      final token = await AuthService.getToken();
      if (token != null && token.isNotEmpty) {
        final response = await ApiService.getMySubjects(token);
        
        if (mounted) {
          if (response['success'] == true && response['data'] != null) {
            final data = response['data'] as Map<String, dynamic>;
            final subjects = data['subjects'] as List? ?? [];
            
            setState(() {
              _subjects = subjects
                  .map((s) => s as Map<String, dynamic>)
                  .where((s) => s['isActive'] == true)
                  .toList();
              _isLoadingSubjects = false;
            });
          } else {
            setState(() {
              _subjectsErrorMessage = response['message'] ?? 'Failed to load subjects';
              _isLoadingSubjects = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _subjectsErrorMessage = 'Not authenticated';
            _isLoadingSubjects = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _subjectsErrorMessage = 'Error loading subjects: ${e.toString()}';
          _isLoadingSubjects = false;
        });
      }
    }
  }

  // Get random emoji for a subject based on its name
  String _getSubjectEmoji(String subjectName) {
    final name = subjectName.toLowerCase();
    final emojis = <String>[];
    
    // Subject-specific emojis
    if (name.contains('math') || name.contains('mathematics')) {
      emojis.addAll(['🔢', '📐', '📊', '➕', '➖', '✖️', '➗']);
    } else if (name.contains('english') || name.contains('language')) {
      emojis.addAll(['📚', '📖', '✍️', '📝', '📄', '📃']);
    } else if (name.contains('science')) {
      emojis.addAll(['🔬', '⚗️', '🧪', '🔭', '🌡️', '⚛️']);
    } else if (name.contains('biology') || name.contains('bio')) {
      emojis.addAll(['🧬', '🌱', '🦠', '🔬', '🌿', '🌾']);
    } else if (name.contains('physics')) {
      emojis.addAll(['⚛️', '🔋', '💡', '⚡', '🌌', '🔭']);
    } else if (name.contains('chemistry')) {
      emojis.addAll(['⚗️', '🧪', '🔬', '💊', '🧬', '⚛️']);
    } else if (name.contains('history')) {
      emojis.addAll(['📜', '🏛️', '🗿', '⏳', '📚', '🏺']);
    } else if (name.contains('geography') || name.contains('geo')) {
      emojis.addAll(['🌍', '🗺️', '🌎', '🌏', '🏔️', '🌊']);
    } else if (name.contains('social') || name.contains('studies')) {
      emojis.addAll(['🌍', '👥', '🏛️', '🗳️', '📊', '🌐']);
    } else if (name.contains('art') || name.contains('drawing')) {
      emojis.addAll(['🎨', '🖌️', '🖼️', '✏️', '🖍️', '🎭']);
    } else if (name.contains('music')) {
      emojis.addAll(['🎵', '🎶', '🎹', '🎸', '🎤', '🎧']);
    } else if (name.contains('computer') || name.contains('it') || name.contains('coding')) {
      emojis.addAll(['💻', '⌨️', '🖥️', '📱', '🖱️', '💾']);
    } else if (name.contains('physical') || name.contains('pe') || name.contains('sports')) {
      emojis.addAll(['⚽', '🏀', '🏃', '🤸', '🏋️', '🎾']);
    } else if (name.contains('hindi')) {
      emojis.addAll(['📖', '✍️', '📝', '📚', '🇮🇳', '📄']);
    } else if (name.contains('sanskrit')) {
      emojis.addAll(['📜', '📖', '✍️', '📚', '📝', '📄']);
    } else {
      // Random educational emojis
      emojis.addAll(['📚', '📖', '📝', '✏️', '📊', '📋', '📑', '📄', '📃', '📜', '🎓', '📐', '🔖', '📌']);
    }
    
    // Use subject name hash to consistently assign emoji
    final hash = subjectName.hashCode;
    final index = hash.abs() % emojis.length;
    return emojis[index];
  }

  // Get color for subject card
  Color _getSubjectColor(String subjectName, int index) {
    final colors = [
      const Color(0xFFDDD6FE), // Purple
      const Color(0xFFFFEDD5), // Orange
      const Color(0xFFBFDBFE), // Blue
      const Color(0xFFBAE6FD), // Light Blue
      const Color(0xFFDCFCE7), // Green
      const Color(0xFFFED7E2), // Pink
      const Color(0xFFE0E7FF), // Indigo
      const Color(0xFFFFF4E6), // Peach
      const Color(0xFFE0F2FE), // Sky Blue
      const Color(0xFFF0FDF4), // Light Green
    ];
    return colors[index % colors.length];
  }

  Widget _buildHomeContent() {
    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          _loadProfileImage(),
          _loadCompetitiveExams(),
          _loadMySubjects(),
          _loadRecentQuizResults(),
          _loadSubscriptionStatus(),
        ]);
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildPlayBanner(),
            const SizedBox(height: 32),
            _buildFeaturedCategories(),
            const SizedBox(height: 32),
            _buildCompetitiveExams(),
            const SizedBox(height: 32),
            if (_quizStatistics != null) _buildWinningPercentage(),
            if (_quizStatistics != null) const SizedBox(height: 24),
            _buildRecentResults(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }


  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: LevelTheme.getGradientColors(EducationLevel.junior),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.grid_view_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            Row(
              children: [
                // Notification Bell
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      const Icon(
                        Icons.notifications_outlined,
                        color: Color(0xFF1F2937),
                        size: 24,
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Profile Image
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const JuniorProfileScreen(),
                      ),
                    );
                  },
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
                      child: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: _profileImageUrl!,
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
                            )
                          : Container(
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
              ],
            ),
          ],
        ),
        // Class Information Display
        if (_classInfo != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(16),
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
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: LevelTheme.getGradientColors(EducationLevel.junior),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.school,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _classInfo!['name'] as String? ?? 'Class',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      if (_classInfo!['description'] != null)
                        Text(
                          _classInfo!['description'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPlayBanner() {
    final primaryColor = LevelTheme.getPrimaryColor(EducationLevel.junior);
    final gradientColors = LevelTheme.getGradientColors(EducationLevel.junior);
    
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Let's play\ntoogether",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.2,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    'Play now',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Stack(
            children: [
              // Sparkles
              Positioned(
                top: 0,
                right: 40,
                child: _buildSparkle(12),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: _buildSparkle(8),
              ),
              Positioned(
                bottom: 20,
                right: 50,
                child: _buildSparkle(10),
              ),
              // Trophy
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBBF24),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Text(
                  '🏆',
                  style: TextStyle(fontSize: 60),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSparkle(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.yellow.shade300,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildFeaturedCategories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'My Subjects',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 20),
        if (_isLoadingSubjects)
          _buildSubjectsSkeleton()
        else if (_subjectsErrorMessage != null)
          _buildSubjectsError()
        else if (_subjects.isEmpty)
          _buildNoSubjects()
        else
          _buildSubjectsGrid(),
      ],
    );
  }

  Widget _buildSubjectsSkeleton() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: _buildSkeletonCategoryCard()),
            const SizedBox(width: 12),
            Expanded(child: _buildSkeletonCategoryCard()),
            const SizedBox(width: 12),
            Expanded(child: _buildSkeletonCategoryCard()),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: _buildSkeletonCategoryCard()),
            const SizedBox(width: 12),
            Expanded(child: _buildSkeletonCategoryCard()),
            const SizedBox(width: 12),
            Expanded(child: _buildSkeletonCategoryCard()),
          ],
        ),
      ],
    );
  }

  Widget _buildSkeletonCategoryCard() {
    return Column(
      children: [
        SkeletonLoader(
          width: double.infinity,
          height: 100,
          borderRadius: BorderRadius.circular(20),
        ),
        const SizedBox(height: 10),
        SkeletonLoader(
          width: 60,
          height: 14,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildSubjectsError() {
    final isClassNotSet = _subjectsErrorMessage?.toLowerCase().contains('class') == true ||
                          _subjectsErrorMessage?.toLowerCase().contains('not set') == true;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            isClassNotSet ? Icons.school_outlined : Icons.error_outline,
            size: 48,
            color: Colors.orange.withOpacity(0.7),
          ),
          const SizedBox(height: 12),
          Text(
            _subjectsErrorMessage ?? 'Failed to load subjects',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (isClassNotSet) ...[
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to profile screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const JuniorProfileScreen(),
                  ),
                ).then((_) {
                  // Reload subjects after returning from profile
                  _loadMySubjects();
                  _loadProfileImage(); // Also reload profile to get updated class info
                });
              },
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Update Profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          TextButton(
            onPressed: _loadMySubjects,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSubjects() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
      ),
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
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Please update your profile with class and board information',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectsGrid() {
    final rows = <Widget>[];
    
    // Split subjects into rows of 3
    for (int i = 0; i < _subjects.length; i += 3) {
      final rowSubjects = _subjects.skip(i).take(3).toList();
      
      rows.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: rowSubjects.asMap().entries.map((entry) {
            final index = entry.key;
            final subject = entry.value;
            final subjectName = subject['name'] as String? ?? 'Subject';
            final emoji = _getSubjectEmoji(subjectName);
            final color = _getSubjectColor(subjectName, i + index);
            
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: index < rowSubjects.length - 1 ? 12 : 0,
                ),
                child: _buildCategoryCard(emoji, subjectName, color, subject),
              ),
            );
          }).toList(),
        ),
      );
      
      // Add spacing between rows (except after last row)
      if (i + 3 < _subjects.length) {
        rows.add(const SizedBox(height: 12));
      }
    }
    
    return Column(children: rows);
  }

  Widget _buildCategoryCard(String emoji, String title, Color color, [Map<String, dynamic>? subjectData]) {
    return Stack(
      children: [
        GestureDetector(
          onTap: _hasActiveSubscription ? () {
            // Extract subject ID from subjectData
            if (subjectData != null) {
              final subjectId = (subjectData['_id'] as String?)?.trim() ?? 
                               (subjectData['id'] as String?)?.trim() ?? '';
              
              if (subjectId.isNotEmpty) {
                // Navigate to SubjectDetailsScreen with subject ID
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SubjectDetailsScreen(
                      subjectId: subjectId,
                      subjectName: title,
                      emoji: emoji,
                      subjectColor: color,
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Subject ID not available'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Subject data not available'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          } : _handleLockedFeatureTap,
          child: Column(
            children: [
              Container(
                width: double.infinity,
                height: 100,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 48),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
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
                        size: 28,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Subscribe',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
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
    );
  }

  Widget _buildCompetitiveExams() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Competitive Exams',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
                letterSpacing: -0.5,
              ),
            ),
            TextButton(
              onPressed: () {
                // TODO: Navigate to all exams screen
              },
              child: const Text(
                'See all',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF60A5FA),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_isLoadingExams)
          _buildExamSkeletonLoader()
        else if (_competitiveExams.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                'No competitive exams available',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          )
        else
          ..._buildExamRows(),
      ],
    );
  }

  List<Widget> _buildExamRows() {
    final rows = <Widget>[];
    
    // Split exams into rows of 3
    for (int i = 0; i < _competitiveExams.length; i += 3) {
      final rowExams = _competitiveExams.skip(i).take(3).toList();
      
      rows.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: rowExams.map((exam) {
            final name = exam['name'] as String? ?? '';
            final code = exam['code'] as String? ?? '';
            final description = exam['description'] as String?;
            final style = _getExamStyle(code, name);
            
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: rowExams.indexOf(exam) < rowExams.length - 1 ? 12 : 0,
                ),
                child: _buildExamCard(
                  emoji: style['emoji'] as String,
                  title: _getShortName(name),
                  subtitle: _getSubtitle(name, description),
                  color: style['color'] as Color,
                  backgroundColor: style['backgroundColor'] as Color,
                  examData: exam,
                ),
              ),
            );
          }).toList(),
        ),
      );
      
      // Add spacing between rows (except after last row)
      if (i + 3 < _competitiveExams.length) {
        rows.add(const SizedBox(height: 12));
      }
    }
    
    return rows;
  }

  Widget _buildExamCard({
    required String emoji,
    required String title,
    required String subtitle,
    required Color color,
    required Color backgroundColor,
    Map<String, dynamic>? examData,
  }) {
    return Stack(
      children: [
        GestureDetector(
          onTap: _hasActiveSubscription ? () {
            if (examData != null) {
              final examId = examData['_id'] as String?;
              final examName = examData['name'] as String? ?? title;
              final examCode = examData['code'] as String? ?? '';
              
              if (examId != null && examId.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => JuniorExamSyllabusScreen(
                      examId: examId,
                      examName: examName,
                      examCode: examCode,
                    ),
                  ),
                );
              } else {
                // Fallback to subject selection if no exam ID
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SubjectSelectionScreen(),
                  ),
                );
              }
            } else {
              // Fallback to subject selection if no exam data
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SubjectSelectionScreen(),
                ),
              );
            }
          } : _handleLockedFeatureTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 36),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: color.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
            ),
          ),
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
                        size: 28,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Subscribe',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
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
    );
  }

  Widget _buildExamSkeletonLoader() {
    // Show 6 skeleton cards (2 rows of 3)
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: _buildSkeletonExamCard(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSkeletonExamCard(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSkeletonExamCard(),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: _buildSkeletonExamCard(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSkeletonExamCard(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSkeletonExamCard(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSkeletonExamCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Skeleton for icon container
          SkeletonLoader(
            width: 60,
            height: 60,
            borderRadius: BorderRadius.circular(16),
          ),
          const SizedBox(height: 12),
          // Skeleton for title
          SkeletonLoader(
            width: double.infinity,
            height: 14,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 4),
          // Skeleton for subtitle
          SkeletonLoader(
            width: 60,
            height: 11,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Future<void> _loadRecentQuizResults() async {
    setState(() {
      _isLoadingQuizResults = true;
    });

    try {
      final results = await _quizDb.getRecentQuizResults(limit: 3);
      final stats = await _quizDb.getStatistics();

      if (mounted) {
        setState(() {
          _recentQuizResults = results;
          _quizStatistics = stats;
          _isLoadingQuizResults = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingQuizResults = false;
        });
      }
      print('Error loading quiz results: $e');
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

  Widget _buildWinningPercentage() {
    final winningPercentage = _quizStatistics?['winningPercentage'] as double? ?? 0.0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'My Winning Percentage',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${winningPercentage.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.emoji_events,
              color: Colors.white,
              size: 40,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Result',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
                letterSpacing: -0.5,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const QuizHistoryScreen(),
                  ),
                ).then((_) => _loadRecentQuizResults());
              },
              child: const Text(
                'See all',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF60A5FA),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_isLoadingQuizResults)
          const Center(child: CircularProgressIndicator())
        else if (_recentQuizResults.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.quiz_outlined,
                    size: 60,
                    color: Colors.grey.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No quiz results yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.withOpacity(0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Complete some quizzes to see results here!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.withOpacity(0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          ..._recentQuizResults.asMap().entries.map((entry) {
            final index = entry.key;
            final result = entry.value;
            final topicColor = _getColorFromString(result['topic_color'] as String?);
            final percentage = (result['percentage'] as double? ?? 0.0) / 100;
            final correctAnswers = result['correct_answers'] as int? ?? 0;
            final totalQuestions = result['total_questions'] as int? ?? 0;
            final topicName = result['topic_name'] as String? ?? 'Unknown';
            final backgroundColor = topicColor.withOpacity(0.1);

            return Padding(
              padding: EdgeInsets.only(bottom: index < _recentQuizResults.length - 1 ? 12 : 0),
              child: _buildResultCard(
                position: '${index + 1}',
                title: topicName,
                score: '$correctAnswers/$totalQuestions',
                progress: percentage,
                color: topicColor,
                backgroundColor: backgroundColor,
              ),
            );
          }),
      ],
    );
  }

  Color _getColorFromString(String? colorString) {
    if (colorString == null || colorString.isEmpty) {
      return AppColors.primary;
    }
    try {
      return Color(int.parse(colorString, radix: 16));
    } catch (e) {
      return AppColors.primary;
    }
  }

  Widget _buildResultCard({
    required String position,
    required String title,
    required String score,
    required double progress,
    required Color color,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                position,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: color.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white.withOpacity(0.5),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            score,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar(String? currentLevel) {
    final primaryColor = LevelTheme.getPrimaryColor(currentLevel);
    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: LevelTheme.getGradientColors(currentLevel),
        ),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 10),
            spreadRadius: 0,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_rounded, Icons.home_outlined, 0, primaryColor),
              _buildNavItem(Icons.book_rounded, Icons.book_outlined, 1, primaryColor),
              _buildNavItem(Icons.auto_awesome_rounded, Icons.auto_awesome_outlined, 2, primaryColor),
              _buildNavItem(Icons.person_rounded, Icons.person_outline_rounded, 3, primaryColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData selectedIcon, IconData unselectedIcon, int index, Color color) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => _onNavItemTapped(index),
      borderRadius: BorderRadius.circular(30),
      splashColor: color.withOpacity(0.2),
      highlightColor: color.withOpacity(0.1),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
        padding: EdgeInsets.all(isSelected ? 16 : 12),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          shape: BoxShape.circle,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return ScaleTransition(
              scale: Tween<double>(begin: 0.6, end: 1.0).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.elasticOut,
                ),
              ),
              child: RotationTransition(
                turns: Tween<double>(begin: 0.8, end: 1.0).animate(animation),
                child: child,
              ),
            );
          },
          child: Icon(
            isSelected ? selectedIcon : unselectedIcon,
            key: ValueKey<bool>(isSelected),
            color: isSelected ? Colors.white : const Color(0xFF9CA3AF),
            size: isSelected ? 30 : 26,
          ),
        ),
      ),
    );
  }
}

