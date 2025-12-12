import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';
import '../utils/navigation_helper.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class LessonViewerScreen extends StatefulWidget {
  final Map<String, dynamic> lesson;
  final String courseId;
  final bool isEnrolled;

  const LessonViewerScreen({
    Key? key,
    required this.lesson,
    required this.courseId,
    this.isEnrolled = false,
  }) : super(key: key);

  @override
  State<LessonViewerScreen> createState() => _LessonViewerScreenState();
}

class _LessonViewerScreenState extends State<LessonViewerScreen> {
  bool _isMarkingComplete = false;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _isCompleted = widget.lesson['isCompleted'] as bool? ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final contentType = widget.lesson['contentType'] as String? ?? 'video';
    final title = widget.lesson['title'] as String? ?? 'Lesson';
    final description = widget.lesson['description'] as String? ?? '';
    final contentUrl = widget.lesson['contentUrl'] as String?;
    final resources = widget.lesson['resources'] as List? ?? [];
    final durationMinutes = widget.lesson['durationMinutes'] as int? ?? 0;

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (!didPop) {
          NavigationHelper.goBack(context);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => NavigationHelper.goBack(context),
          ),
          title: Text(
            title,
            style: AppTextStyles.heading2,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Content based on type
                    _buildContent(contentType, contentUrl, title),
                    const SizedBox(height: 24),
                    // Description
                    if (description.isNotEmpty) ...[
                      Text(
                        'Description',
                        style: AppTextStyles.heading3.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        description,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontSize: 15,
                          height: 1.6,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    // Resources
                    if (resources.isNotEmpty) ...[
                      Text(
                        'Resources',
                        style: AppTextStyles.heading3.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...resources.map((resource) {
                        final resourceName = resource['name'] as String? ?? 'Resource';
                        final resourceUrl = resource['url'] as String? ?? '';
                        final resourceType = resource['type'] as String? ?? 'pdf';
                        return _buildResourceCard(resourceName, resourceUrl, resourceType);
                      }).toList(),
                    ],
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
            // Bottom bar with Mark as Done button
            if (widget.isEnrolled)
              Container(
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
                  child: ElevatedButton(
                    onPressed: _isCompleted || _isMarkingComplete
                        ? null
                        : () => _markAsComplete(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isCompleted
                          ? AppColors.successGreen
                          : AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                    child: _isMarkingComplete
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isCompleted ? Icons.check_circle : Icons.done,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isCompleted ? 'Completed' : 'Mark as Done',
                                style: AppTextStyles.buttonText.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(String contentType, String? contentUrl, String title) {
    switch (contentType.toLowerCase()) {
      case 'video':
        return _buildVideoContent(contentUrl, title);
      case 'text':
        return _buildTextContent(contentUrl);
      case 'quiz':
        return _buildQuizContent();
      case 'assignment':
        return _buildAssignmentContent();
      default:
        return _buildDefaultContent(contentType);
    }
  }

  Widget _buildVideoContent(String? videoUrl, String title) {
    return Container(
      width: double.infinity,
      height: 250,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
      ),
      child: videoUrl != null && videoUrl.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  // Video thumbnail or placeholder
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.play_circle_filled,
                          color: Colors.white,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Video Lesson',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        if (videoUrl.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => _launchUrl(videoUrl),
                            child: const Text(
                              'Open Video',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.video_library,
                    color: Colors.white70,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Video content not available',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTextContent(String? textUrl) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.article,
            size: 48,
            color: AppColors.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Reading Material',
            style: AppTextStyles.heading3,
          ),
          if (textUrl != null && textUrl.isNotEmpty) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _launchUrl(textUrl),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open Reading Material'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuizContent() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.quiz,
            size: 48,
            color: AppColors.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Quiz',
            style: AppTextStyles.heading3,
          ),
          const SizedBox(height: 8),
          Text(
            'Complete the quiz to mark this lesson as done',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentContent() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.assignment,
            size: 48,
            color: AppColors.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Assignment',
            style: AppTextStyles.heading3,
          ),
          const SizedBox(height: 8),
          Text(
            'Complete the assignment to mark this lesson as done',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultContent(String contentType) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.description,
            size: 48,
            color: AppColors.primary,
          ),
          const SizedBox(height: 16),
          Text(
            contentType.toUpperCase(),
            style: AppTextStyles.heading3,
          ),
        ],
      ),
    );
  }

  Widget _buildResourceCard(String name, String url, String type) {
    IconData icon;
    switch (type.toLowerCase()) {
      case 'pdf':
        icon = Icons.picture_as_pdf;
        break;
      case 'image':
        icon = Icons.image;
        break;
      default:
        icon = Icons.insert_drive_file;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
        ),
      ),
      child: InkWell(
        onTap: () => _launchUrl(url),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                name,
                style: AppTextStyles.bodyMedium,
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open $url'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markAsComplete() async {
    setState(() {
      _isMarkingComplete = true;
    });

    try {
      final token = await AuthService.getToken();
      if (token != null && token.isNotEmpty) {
        final lessonId = widget.lesson['_id'] as String? ?? '';
        
        final response = await ApiService.markLessonComplete(
          token,
          widget.courseId,
          lessonId,
          true,
        );

        if (mounted) {
          if (response['success'] == true) {
            setState(() {
              _isCompleted = true;
              _isMarkingComplete = false;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Lesson marked as complete!'),
                backgroundColor: AppColors.successGreen,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                duration: const Duration(seconds: 2),
              ),
            );

            // Pop back to course details to refresh
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                Navigator.pop(context, true); // Return true to indicate completion
              }
            });
          } else {
            setState(() {
              _isMarkingComplete = false;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  response['message'] ?? 'Failed to mark lesson as complete',
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
          setState(() {
            _isMarkingComplete = false;
          });
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
        setState(() {
          _isMarkingComplete = false;
        });
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
}

