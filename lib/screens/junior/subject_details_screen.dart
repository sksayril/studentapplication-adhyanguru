import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/colors.dart';
import '../../utils/text_styles.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/skeleton_loader.dart';

class SubjectDetailsScreen extends StatefulWidget {
  final String subjectId;
  final String subjectName;
  final String emoji;
  final Color subjectColor;
  final List<Map<String, dynamic>>? chapters; // Optional: chapters from API response

  const SubjectDetailsScreen({
    Key? key,
    required this.subjectId,
    required this.subjectName,
    required this.emoji,
    required this.subjectColor,
    this.chapters, // If provided, use these chapters instead of fetching
  }) : super(key: key);

  @override
  State<SubjectDetailsScreen> createState() => _SubjectDetailsScreenState();
}

class _SubjectDetailsScreenState extends State<SubjectDetailsScreen> {
  List<Map<String, dynamic>> _chapters = [];
  List<Map<String, dynamic>> _syllabi = [];
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _subjectInfo;
  Map<String, dynamic>? _completionInfo;

  @override
  void initState() {
    super.initState();
    // Always fetch full subject data using the protected API
    _loadSubjectData();
  }

  Future<void> _loadSubjectData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Not authenticated. Please login again.';
            _isLoading = false;
          });
        }
        return;
      }

      print('Loading full subject data for ID: ${widget.subjectId}');
      final response = await ApiService.getSubjectById(token, widget.subjectId);
      
      if (mounted) {
        if (response['success'] == true && response['data'] != null) {
          final data = response['data'] as Map<String, dynamic>;
          final subject = data['subject'] as Map<String, dynamic>?;
          final completion = data['completion'] as Map<String, dynamic>?;
          
          if (subject != null) {
            final chapters = subject['chapters'] as List? ?? [];
            final syllabi = subject['syllabi'] as List? ?? [];
            
            setState(() {
              _subjectInfo = subject;
              _completionInfo = completion;
              
              // Sort chapters by order if available
              _chapters = chapters
                  .map((c) => c as Map<String, dynamic>)
                  .toList()
                ..sort((a, b) {
                  final orderA = a['order'] as int? ?? 0;
                  final orderB = b['order'] as int? ?? 0;
                  return orderA.compareTo(orderB);
                });
              
              // Sort syllabi by order if available
              _syllabi = syllabi
                  .map((s) => s as Map<String, dynamic>)
                  .toList()
                ..sort((a, b) {
                  final orderA = a['order'] as int? ?? 0;
                  final orderB = b['order'] as int? ?? 0;
                  return orderA.compareTo(orderB);
                });
              
              _isLoading = false;
            });
            
            print('Subject data loaded: ${_chapters.length} chapters, ${_syllabi.length} syllabi');
          } else {
            setState(() {
              _errorMessage = 'Subject data not found';
              _isLoading = false;
            });
          }
        } else {
          setState(() {
            _errorMessage = response['message'] ?? 'Failed to load subject data';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading subject data: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }
  
  // Keep old method name for backward compatibility with RefreshIndicator
  Future<void> _loadChapters() async {
    await _loadSubjectData();
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
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.subjectName,
          style: AppTextStyles.heading2.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          if (_chapters.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${_chapters.length} ${_chapters.length == 1 ? 'Chapter' : 'Chapters'}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
            ),
        ],
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: RefreshIndicator(
        onRefresh: _loadSubjectData,
        child: _isLoading
            ? _buildLoadingState()
            : _errorMessage != null
                ? _buildErrorState()
                : _chapters.isEmpty && _syllabi.isEmpty
                    ? _buildEmptyState()
                    : _buildContent(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSubjectHeader(),
          const SizedBox(height: 24),
          ...List.generate(3, (index) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SkeletonLoader(
                  width: double.infinity,
                  height: 180,
                  borderRadius: BorderRadius.circular(20),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildSubjectHeader(),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
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
                  _errorMessage ?? 'Failed to load chapters',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _loadSubjectData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.subjectColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildSubjectHeader(),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  Icons.book_outlined,
                  size: 48,
                  color: Colors.grey.withOpacity(0.7),
                ),
                const SizedBox(height: 12),
                Text(
                  'No chapters available',
                  style: AppTextStyles.heading3,
                ),
                const SizedBox(height: 8),
                Text(
                  'Chapters will be added soon',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.subjectColor.withOpacity(0.15),
            widget.subjectColor.withOpacity(0.05),
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: widget.subjectColor.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.subjectColor,
                  widget.subjectColor.withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: widget.subjectColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                widget.emoji,
                style: const TextStyle(fontSize: 48),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.subjectName,
                  style: AppTextStyles.heading2.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1F2937),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: widget.subjectColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_chapters.length} ${_chapters.length == 1 ? 'Chapter' : 'Chapters'}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: const Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSubjectHeader(),
          
          // Completion Status Card
          if (_completionInfo != null) ...[
            const SizedBox(height: 24),
            _buildCompletionCard(),
          ],
          
          // Chapters Section
          if (_chapters.isNotEmpty) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: widget.subjectColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Chapters (${_chapters.length})',
                  style: AppTextStyles.heading2.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1F2937),
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._chapters.asMap().entries.map((entry) {
              final index = entry.key;
              final chapter = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildChapterCard(chapter, index + 1),
              );
            }).toList(),
          ],
          
          // Syllabi Section
          if (_syllabi.isNotEmpty) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: widget.subjectColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Syllabi (${_syllabi.length})',
                  style: AppTextStyles.heading2.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1F2937),
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._syllabi.asMap().entries.map((entry) {
              final index = entry.key;
              final syllabus = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildSyllabusCard(syllabus, index + 1),
              );
            }).toList(),
          ],
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }
  
  Widget _buildCompletionCard() {
    final progressPercentage = _completionInfo?['progressPercentage'] as int? ?? 0;
    final isCompleted = _completionInfo?['isCompleted'] as bool? ?? false;
    final completedChapters = _completionInfo?['completedChapters'] as int? ?? 0;
    final totalChapters = _completionInfo?['totalChapters'] as int? ?? 0;
    final completedSyllabi = _completionInfo?['completedSyllabi'] as int? ?? 0;
    final totalSyllabi = _completionInfo?['totalSyllabi'] as int? ?? 0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.subjectColor.withOpacity(0.1),
            widget.subjectColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.subjectColor.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress',
                style: AppTextStyles.heading3.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Completed',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progressPercentage / 100,
              minHeight: 12,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(widget.subjectColor),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$progressPercentage% Complete',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: widget.subjectColor,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Chapters',
                  '$completedChapters / $totalChapters',
                  Icons.book_outlined,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  'Syllabi',
                  '$completedSyllabi / $totalSyllabi',
                  Icons.description_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.subjectColor.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: widget.subjectColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                Text(
                  value,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSyllabusCard(Map<String, dynamic> syllabus, int syllabusNumber) {
    final title = syllabus['title'] as String? ?? 'Untitled Syllabus';
    final description = syllabus['description'] as String?;
    final content = syllabus['content'] as String?;
    final isCompleted = syllabus['isCompleted'] as bool? ?? false;
    
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isCompleted 
              ? Colors.green.withOpacity(0.3)
              : widget.subjectColor.withOpacity(0.1),
          width: isCompleted ? 2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.subjectColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      isCompleted ? Colors.green : _getDeeperColor(widget.subjectColor),
                      isCompleted ? Colors.green.withOpacity(0.8) : _getDeeperColor(widget.subjectColor).withOpacity(0.9),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, color: Colors.white, size: 24)
                      : Text(
                          '$syllabusNumber',
                          style: const TextStyle(
                            fontSize: 20,
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
                      style: AppTextStyles.heading3.copyWith(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    if (description != null && description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: const Color(0xFF6B7280),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (content != null && content.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    widget.subjectColor.withOpacity(0.08),
                    widget.subjectColor.withOpacity(0.03),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                content.length > 200 ? '${content.substring(0, 200)}...' : content,
                style: AppTextStyles.bodySmall.copyWith(
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Get a deeper, more visible color from the subject color
  Color _getDeeperColor(Color baseColor) {
    // Convert to HSL to adjust saturation and lightness
    final hsl = HSLColor.fromColor(baseColor);
    // Increase saturation and decrease lightness for deeper color
    final deeperHsl = hsl.withSaturation((hsl.saturation + 0.3).clamp(0.0, 1.0))
                           .withLightness((hsl.lightness * 0.7).clamp(0.0, 1.0));
    return deeperHsl.toColor();
  }

  Widget _buildChapterCard(Map<String, dynamic> chapter, int chapterNumber) {
    final title = chapter['title'] as String? ?? 'Untitled Chapter';
    final description = chapter['description'] as String?;
    final pdfUrl = chapter['pdfUrl'] as String?;
    final videoUrl = chapter['videoUrl'] as String?;
    final textContent = chapter['textContent'] as String?;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: widget.subjectColor.withOpacity(0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.subjectColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chapter Number and Title
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _getDeeperColor(widget.subjectColor),
                      _getDeeperColor(widget.subjectColor).withOpacity(0.9),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: _getDeeperColor(widget.subjectColor).withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '$chapterNumber',
                    style: const TextStyle(
                      fontSize: 20,
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
                      style: AppTextStyles.heading3.copyWith(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1F2937),
                        letterSpacing: -0.3,
                        height: 1.2,
                      ),
                    ),
                    // Description
                    if (description != null && description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: const Color(0xFF6B7280),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          // Text Content Preview
          if (textContent != null && textContent.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    widget.subjectColor.withOpacity(0.08),
                    widget.subjectColor.withOpacity(0.03),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.subjectColor.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Text(
                textContent.length > 150 
                    ? '${textContent.substring(0, 150)}...' 
                    : textContent,
                style: AppTextStyles.bodySmall.copyWith(
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],

          // Action Buttons
          if (pdfUrl != null || videoUrl != null) ...[
            const SizedBox(height: 18),
            Row(
              children: [
                if (videoUrl != null)
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.play_circle_filled,
                      label: 'Watch Video',
                      color: widget.subjectColor,
                      onTap: () => _launchUrl(videoUrl!),
                    ),
                  ),
                if (videoUrl != null && pdfUrl != null)
                  const SizedBox(width: 12),
                if (pdfUrl != null)
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.picture_as_pdf_rounded,
                      label: 'View PDF',
                      color: widget.subjectColor,
                      onTap: () => _launchUrl(pdfUrl!),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    // Use a deeper, more visible color
    final buttonColor = _getDeeperColor(color);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                buttonColor,
                buttonColor.withOpacity(0.9),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: buttonColor.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

