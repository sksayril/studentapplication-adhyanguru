import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/colors.dart';
import '../../utils/text_styles.dart';
import '../../utils/navigation_helper.dart';
import '../../services/api_service.dart';
import '../../widgets/skeleton_loader.dart';

class JuniorExamSyllabusScreen extends StatefulWidget {
  final String examId;
  final String examName;
  final String examCode;

  const JuniorExamSyllabusScreen({
    Key? key,
    required this.examId,
    required this.examName,
    required this.examCode,
  }) : super(key: key);

  @override
  State<JuniorExamSyllabusScreen> createState() => _JuniorExamSyllabusScreenState();
}

class _JuniorExamSyllabusScreenState extends State<JuniorExamSyllabusScreen> {
  Map<String, dynamic>? _syllabusData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSyllabus();
  }

  Future<void> _loadSyllabus() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.getCompetitiveExamSyllabus(widget.examId);
      
      if (mounted) {
        if (response['success'] == true && response['data'] != null) {
          setState(() {
            _syllabusData = response['data'] as Map<String, dynamic>;
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = response['message'] ?? 'Failed to load syllabus';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error loading syllabus: ${e.toString()}';
        });
      }
    }
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
              _buildHeader(),
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : _errorMessage != null
                        ? _buildErrorState()
                        : _buildSyllabusContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
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
          const CustomBackButton(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Syllabus',
                  style: AppTextStyles.heading2.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (!_isLoading && _syllabusData != null)
                  Text(
                    widget.examName,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (!_isLoading && _syllabusData != null)
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.primary),
              onPressed: _loadSyllabus,
              tooltip: 'Refresh',
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title skeleton
          SkeletonLoader(
            width: double.infinity,
            height: 24,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 16),
          // Description skeleton
          SkeletonLoader(
            width: double.infinity,
            height: 16,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          SkeletonLoader(
            width: 200,
            height: 16,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 24),
          // Overview skeleton
          SkeletonLoader(
            width: double.infinity,
            height: 20,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 12),
          SkeletonLoader(
            width: double.infinity,
            height: 16,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          SkeletonLoader(
            width: 150,
            height: 16,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 32),
          // Chapters skeleton
          SkeletonLoader(
            width: 120,
            height: 20,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 16),
          ...List.generate(3, (index) => _buildSkeletonChapter()),
        ],
      ),
    );
  }

  Widget _buildSkeletonChapter() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
      child: Column(
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
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to Load Syllabus',
              style: AppTextStyles.heading2.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unable to fetch syllabus data',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadSyllabus,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyllabusContent() {
    if (_syllabusData == null) return const SizedBox.shrink();

    final title = _syllabusData!['title'] as String? ?? widget.examName;
    final description = _syllabusData!['description'] as String?;
    final overview = _syllabusData!['overview'] as String?;
    final syllabusText = _syllabusData!['syllabusText'] as String?;
    final syllabusPdfUrl = _syllabusData!['syllabusPdfUrl'] as String?;
    final syllabusVideoUrl = _syllabusData!['syllabusVideoUrl'] as String?;
    final chapters = _syllabusData!['chapters'] as List?;

    return RefreshIndicator(
      onRefresh: _loadSyllabus,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              title,
              style: AppTextStyles.heading1.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            
            // Description
            if (description != null && description.isNotEmpty) ...[
              Text(
                description,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Action Buttons
            if (syllabusPdfUrl != null || syllabusVideoUrl != null) ...[
              Row(
                children: [
                  if (syllabusPdfUrl != null)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _launchUrl(syllabusPdfUrl!),
                        icon: const Icon(Icons.picture_as_pdf, size: 20),
                        label: const Text('PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  if (syllabusPdfUrl != null && syllabusVideoUrl != null)
                    const SizedBox(width: 12),
                  if (syllabusVideoUrl != null)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _launchUrl(syllabusVideoUrl!),
                        icon: const Icon(Icons.play_circle_outline, size: 20),
                        label: const Text('Video'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
            ],

            // Overview
            if (overview != null && overview.isNotEmpty) ...[
              Text(
                'Overview',
                style: AppTextStyles.heading2.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  overview,
                  style: AppTextStyles.bodyMedium,
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Syllabus Text
            if (syllabusText != null && syllabusText.isNotEmpty) ...[
              Text(
                'Syllabus Content',
                style: AppTextStyles.heading2.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  syllabusText,
                  style: AppTextStyles.bodyMedium,
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Chapters
            if (chapters != null && chapters.isNotEmpty) ...[
              Text(
                'Chapters',
                style: AppTextStyles.heading2.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              ...chapters.map((chapter) {
                final chapterData = chapter as Map<String, dynamic>;
                return _buildChapterCard(chapterData);
              }).toList(),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildChapterCard(Map<String, dynamic> chapter) {
    final title = chapter['title'] as String? ?? '';
    final description = chapter['description'] as String?;
    final textContent = chapter['textContent'] as String?;
    final pdfUrl = chapter['pdfUrl'] as String?;
    final videoUrl = chapter['videoUrl'] as String?;
    final order = chapter['order'] as int? ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${order + 1}',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.heading3.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (description != null && description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              description,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (textContent != null && textContent.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                textContent,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 13,
                ),
              ),
            ),
          ],
          if (pdfUrl != null || videoUrl != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (pdfUrl != null)
                  TextButton.icon(
                    onPressed: () => _launchUrl(pdfUrl!),
                    icon: const Icon(Icons.picture_as_pdf, size: 16),
                    label: const Text('PDF'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                if (pdfUrl != null && videoUrl != null)
                  const SizedBox(width: 8),
                if (videoUrl != null)
                  TextButton.icon(
                    onPressed: () => _launchUrl(videoUrl!),
                    icon: const Icon(Icons.play_circle_outline, size: 16),
                    label: const Text('Video'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

