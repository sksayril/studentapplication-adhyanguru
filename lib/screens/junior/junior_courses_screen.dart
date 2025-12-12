import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/colors.dart';
import '../../utils/level_theme.dart';
import '../../utils/education_level.dart';
import '../../providers/level_provider.dart';
import '../../widgets/skeleton_loader.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import 'subject_details_screen.dart';

class JuniorCoursesScreen extends StatefulWidget {
  const JuniorCoursesScreen({Key? key}) : super(key: key);

  @override
  State<JuniorCoursesScreen> createState() => _JuniorCoursesScreenState();
}

class _JuniorCoursesScreenState extends State<JuniorCoursesScreen> {
  List<Map<String, dynamic>> _subjects = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMySubjects();
  }

  Future<void> _loadMySubjects() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await AuthService.getToken();
      if (token != null && token.isNotEmpty) {
        // Get selected board ID from storage
        String? selectedBoardId = await AuthService.getSelectedBoardId();
        
        // Get student ID for board storage
        final userData = await AuthService.getUserData();
        final studentId = userData?['studentId'] as String?;
        
        print('Loading subjects with board ID: $selectedBoardId');
        
        // Call API with boardId filter if available
        final response = await ApiService.getMySubjects(
          token,
          boardId: selectedBoardId,
        );
        
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
              
              _subjects = mappedSubjects;
              _isLoading = false;
            });
          } else {
            setState(() {
              _errorMessage = response['message'] ?? 'Failed to load subjects';
              _isLoading = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Not authenticated';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading subjects: ${e.toString()}';
          _isLoading = false;
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
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFFF59E0B), // Orange
      const Color(0xFF3B82F6), // Blue
      const Color(0xFF10B981), // Green
      const Color(0xFFEC4899), // Pink
      const Color(0xFFEF4444), // Red
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFF84CC16), // Lime
    ];
    
    // Use subject name hash to consistently assign color
    final hash = subjectName.hashCode;
    final colorIndex = hash.abs() % colors.length;
    return colors[colorIndex];
  }

  // Get background color for subject card
  Color _getSubjectBackgroundColor(Color primaryColor) {
    // Create a lighter version of the primary color
    return primaryColor.withOpacity(0.15);
  }

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
            if (_isLoading)
              ...List.generate(3, (index) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SkeletonLoader(
                  width: double.infinity,
                  height: 120,
                  borderRadius: BorderRadius.circular(24),
                ),
              ))
            else if (_errorMessage != null)
              _buildErrorWidget()
            else if (_subjects.isEmpty)
              _buildEmptyWidget()
            else
              ..._subjects.asMap().entries.map((entry) {
                final index = entry.key;
                final subject = entry.value;
                final subjectName = subject['name'] as String? ?? 'Unknown Subject';
                final emoji = _getSubjectEmoji(subjectName);
                final color = _getSubjectColor(subjectName, index);
                final backgroundColor = _getSubjectBackgroundColor(color);
                
                // Default progress and lessons (can be updated when API provides this data)
                final progress = 0.5; // Default 50% progress
                final completedLessons = 10; // Default completed lessons
                final totalLessons = 20; // Default total lessons
                final lessonsText = '$completedLessons of $totalLessons lessons';
                
                final subjectId = subject['_id'] as String? ?? 
                                 subject['id'] as String? ?? '';
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildCourseCard(
                    emoji: emoji,
                    subject: subjectName,
                    progress: progress,
                    lessons: lessonsText,
                    color: color,
                    backgroundColor: backgroundColor,
                    onTap: () {
                      if (subjectId.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SubjectDetailsScreen(
                              subjectId: subjectId,
                              subjectName: subjectName,
                              emoji: emoji,
                              subjectColor: color,
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Subject ID not available'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                  ),
                );
              }).toList(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.orange.withOpacity(0.7),
          ),
          const SizedBox(height: 12),
          Text(
            _errorMessage ?? 'Failed to load subjects',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _loadMySubjects,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.book_outlined,
            size: 48,
            color: Colors.grey.withOpacity(0.7),
          ),
          const SizedBox(height: 12),
          const Text(
            'No subjects available',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please update your profile to set your class and board',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
        ],
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
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
      ),
    );
  }
}

