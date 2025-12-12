import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';
import '../utils/level_theme.dart';
import '../providers/level_provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/education_level.dart';
import 'home_screen.dart';
import 'junior_home_screen.dart';

class BoardSelectionScreen extends StatefulWidget {
  final String selectedLevel;
  
  const BoardSelectionScreen({
    Key? key,
    required this.selectedLevel,
  }) : super(key: key);

  @override
  State<BoardSelectionScreen> createState() => _BoardSelectionScreenState();
}

class _BoardSelectionScreenState extends State<BoardSelectionScreen> {
  String? _selectedBoardId;
  List<Map<String, dynamic>> _boards = [];
  List<Map<String, dynamic>> _filteredBoards = [];
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterBoards);
    _fetchBoards();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterBoards() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredBoards = List.from(_boards);
      } else {
        _filteredBoards = _boards.where((board) {
          final name = (board['name'] as String? ?? '').toLowerCase();
          final code = (board['code'] as String? ?? '').toLowerCase();
          final description = (board['description'] as String? ?? '').toLowerCase();
          return name.contains(query) || 
                 code.contains(query) || 
                 description.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _fetchBoards() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.getBoards();
      
      if (mounted) {
        if (response['success'] == true && response['data'] != null) {
          setState(() {
            _boards = List<Map<String, dynamic>>.from(response['data']);
            _filteredBoards = List.from(_boards);
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = response['message'] ?? 'Failed to load boards';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final levelProvider = Provider.of<LevelProvider>(context);
    final currentLevel = levelProvider.currentLevel ?? widget.selectedLevel;
    final primaryColor = LevelTheme.getPrimaryColor(currentLevel);
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LevelTheme.getBackgroundGradient(currentLevel),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(primaryColor),
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : _errorMessage != null
                        ? _buildErrorState()
                        : _boards.isEmpty
                            ? _buildEmptyState()
                            : Column(
                                children: [
                                  _buildSearchBar(primaryColor),
                                  Expanded(
                                    child: _filteredBoards.isEmpty
                                        ? _buildNoResultsState()
                                        : _buildBoardsList(primaryColor),
                                  ),
                                ],
                              ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomButton(primaryColor),
    );
  }

  Widget _buildHeader(Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios,
                size: 20,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Your Board',
                  style: AppTextStyles.heading2.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose your education board',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
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
        child: ValueListenableBuilder<TextEditingValue>(
          valueListenable: _searchController,
          builder: (context, value, child) {
            return TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search boards...',
                prefixIcon: Icon(
                  Icons.search,
                  color: AppColors.textSecondary,
                ),
                suffixIcon: value.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: primaryColor,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              style: AppTextStyles.bodyMedium,
            );
          },
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.white.withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'No boards found',
              style: AppTextStyles.heading3.copyWith(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching with a different keyword',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading boards...',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white.withOpacity(0.9),
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
              color: Colors.white.withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Failed to load boards',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchBoards,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: 64,
              color: Colors.white.withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'No boards available',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoardsList(Color primaryColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          ..._filteredBoards.map((board) => _buildBoardCard(
                board: board,
                primaryColor: primaryColor,
              )),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildBoardCard({
    required Map<String, dynamic> board,
    required Color primaryColor,
  }) {
    final boardId = board['_id'] as String? ?? '';
    final boardName = board['name'] as String? ?? '';
    final boardCode = board['code'] as String? ?? '';
    final description = board['description'] as String? ?? '';
    final isSelected = _selectedBoardId == boardId;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedBoardId = boardId;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.shade300,
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? primaryColor.withOpacity(0.3)
                  : Colors.black.withOpacity(0.05),
              blurRadius: isSelected ? 20 : 10,
              offset: Offset(0, isSelected ? 8 : 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isSelected
                    ? primaryColor.withOpacity(0.1)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.school,
                color: isSelected ? primaryColor : Colors.grey.shade600,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            // Board info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    boardName,
                    style: AppTextStyles.heading3.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? AppColors.textPrimary : AppColors.textPrimary,
                    ),
                  ),
                  if (boardCode.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      boardCode,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isSelected
                            ? primaryColor
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            // Selection indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? primaryColor
                      : Colors.grey.shade300,
                  width: 2.5,
                ),
                color: Colors.white,
              ),
              child: isSelected
                  ? Center(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutBack,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: primaryColor,
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButton(Color primaryColor) {
    return Container(
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
          onPressed: _selectedBoardId != null
              ? () async {
                  // Save selected board to storage
                  if (_selectedBoardId != null) {
                    await AuthService.saveSelectedBoardId(_selectedBoardId!);
                    
                    // Also save with student ID if available
                    final userData = await AuthService.getUserData();
                    final studentId = userData?['studentId'] as String?;
                    if (studentId != null) {
                      await AuthService.saveBoardForStudent(studentId, _selectedBoardId!);
                    }
                  }
                  
                  // Check if we can pop (if there's a previous route)
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context, _selectedBoardId);
                  } else {
                    // If no previous route, navigate to appropriate home screen
                    final prefs = await SharedPreferences.getInstance();
                    final ui = prefs.getInt('student_ui');
                    final level = prefs.getString('student_level') ?? 
                                prefs.getString('education_level');
                    
                    Widget homeScreen;
                    if (ui == 1) {
                      homeScreen = const JuniorHomeScreen();
                    } else if (ui == 2) {
                      homeScreen = const HomeScreen();
                    } else {
                      // Fallback to level-based navigation
                      if (level?.toLowerCase() == EducationLevel.junior.toLowerCase()) {
                        homeScreen = const JuniorHomeScreen();
                      } else {
                        homeScreen = const HomeScreen();
                      }
                    }
                    
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => homeScreen),
                    );
                  }
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            disabledBackgroundColor: primaryColor.withOpacity(0.5),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
            shadowColor: Colors.transparent,
          ),
          child: Text(
            'Continue',
            style: AppTextStyles.buttonText.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

