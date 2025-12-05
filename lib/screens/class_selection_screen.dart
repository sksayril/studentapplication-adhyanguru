import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/skeleton_loader.dart';

class ClassSelectionScreen extends StatefulWidget {
  final String selectedLevel;
  final String? boardId;
  final bool isSignupFlow; // If true, we'll need a different API or approach
  
  const ClassSelectionScreen({
    Key? key,
    required this.selectedLevel,
    this.boardId,
    this.isSignupFlow = false,
  }) : super(key: key);

  @override
  State<ClassSelectionScreen> createState() => _ClassSelectionScreenState();
}

class _ClassSelectionScreenState extends State<ClassSelectionScreen> {
  List<Map<String, dynamic>> _classes = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _selectedClassId;
  Map<String, dynamic>? _studentInfo;

  @override
  void initState() {
    super.initState();
    if (widget.isSignupFlow) {
      // During signup, we can't use the protected endpoint
      // We'll need to show a message or use a different approach
      setState(() {
        _isLoading = false;
        _errorMessage = 'Class selection will be available after signup';
      });
    } else {
      _loadClasses();
    }
  }

  Future<void> _loadClasses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await AuthService.getToken();
      
      if (token == null || token.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Please login to view classes';
        });
        return;
      }

      final response = await ApiService.getStudentClasses(token);
      
      if (mounted) {
        if (response['success'] == true && response['data'] != null) {
          final data = response['data'] as Map<String, dynamic>;
          setState(() {
            _studentInfo = data['student'] as Map<String, dynamic>?;
            _classes = (data['classes'] as List?)
                    ?.map((c) => c as Map<String, dynamic>)
                    .where((c) => c['isActive'] == true)
                    .toList() ?? [];
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = response['message'] ?? 'Failed to load classes';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error loading classes: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
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
            child: const Icon(
              Icons.arrow_back_ios_rounded,
              size: 16,
              color: AppColors.textPrimary,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Select Class',
          style: AppTextStyles.heading2.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _errorMessage != null
              ? _buildErrorState()
              : _buildClassList(),
      bottomNavigationBar: _selectedClassId != null
          ? Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
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
                  onPressed: () {
                    Navigator.pop(context, _selectedClassId);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Select Class',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildLoadingState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: List.generate(6, (index) => _buildSkeletonClassCard()),
      ),
    );
  }

  Widget _buildSkeletonClassCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
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
          SkeletonLoader(
            width: 60,
            height: 60,
            borderRadius: BorderRadius.circular(12),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(
                  width: double.infinity,
                  height: 20,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),
                SkeletonLoader(
                  width: 150,
                  height: 14,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
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
              'Failed to Load Classes',
              style: AppTextStyles.heading2.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unable to fetch classes',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadClasses,
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

  Widget _buildClassList() {
    if (_classes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.school_outlined,
                size: 64,
                color: AppColors.textSecondary.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No Classes Available',
                style: AppTextStyles.heading2.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'No classes found for your level and board',
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_studentInfo != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Level: ${_studentInfo!['studentLevel']?['name'] ?? widget.selectedLevel}',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        if (_studentInfo!['board'] != null)
                          Text(
                            'Board: ${_studentInfo!['board']?['name'] ?? ''}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          Text(
            'Available Classes',
            style: AppTextStyles.heading2.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          ..._classes.map((classData) {
            final classId = classData['id'] as String?;
            final className = classData['name'] as String? ?? '';
            final classNumber = classData['number'] as int?;
            final description = classData['description'] as String?;
            final hasSubjects = classData['hasSubjectsForBoard'] as bool? ?? false;
            final subjectCount = classData['subjectCount'] as int? ?? 0;
            final isSelected = _selectedClassId == classId;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedClassId = classId;
                });
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : Colors.grey.shade300,
                    width: isSelected ? 2.5 : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.2)
                          : Colors.black.withOpacity(0.05),
                      blurRadius: isSelected ? 15 : 10,
                      offset: Offset(0, isSelected ? 6 : 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          classNumber?.toString() ?? className,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: isSelected
                                ? Colors.white
                                : AppColors.primary,
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
                            className,
                            style: AppTextStyles.heading3.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          if (description != null && description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              description,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                          if (hasSubjects) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.book_outlined,
                                  size: 14,
                                  color: AppColors.successGreen,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$subjectCount subjects available',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.successGreen,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

