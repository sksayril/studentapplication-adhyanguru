import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../widgets/skeleton_loader.dart';
import '../../utils/colors.dart';
import '../../utils/level_theme.dart';
import '../../utils/education_level.dart';
import '../../providers/level_provider.dart';
import '../../utils/navigation_helper.dart';
import '../../utils/text_styles.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../login_screen.dart';
import 'edit_profile_screen.dart';
import '../../utils/app_navigator.dart';

class JuniorProfileScreen extends StatefulWidget {
  const JuniorProfileScreen({Key? key}) : super(key: key);

  @override
  State<JuniorProfileScreen> createState() => _JuniorProfileScreenState();
}

class _JuniorProfileScreenState extends State<JuniorProfileScreen> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _isLoggingOut = false;
  String? _errorMessage;
  final ValueNotifier<bool> _logoutLoadingNotifier = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get token and call profile API
      final token = await AuthService.getToken();
      
      if (token != null && token.isNotEmpty) {
        final response = await ApiService.getProfile(token);
        
        if (mounted) {
          if (response['success'] == true && response['data'] != null) {
            final profileData = response['data'] as Map<String, dynamic>;
            
            // Save updated profile data
            await AuthService.saveUserData(profileData);
            await AuthService.saveUserInfo({
              'token': token,
              'data': profileData,
            });
            
            setState(() {
              _userData = profileData;
              _isLoading = false;
              _errorMessage = null;
            });
            return;
          } else {
            // API returned error, try cached data
            final errorMsg = response['message'] ?? 'Failed to load profile';
            final cachedData = await AuthService.getUserData();
            if (cachedData != null) {
              setState(() {
                _userData = cachedData;
                _isLoading = false;
                _errorMessage = 'Using cached data. $errorMsg';
              });
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(errorMsg),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 2),
                ),
              );
              return;
            } else {
              setState(() {
                _isLoading = false;
                _errorMessage = errorMsg;
              });
              return;
            }
          }
        }
      } else {
        // No token, use cached data
        final cachedData = await AuthService.getUserData();
        if (mounted) {
          setState(() {
            _userData = cachedData;
            _isLoading = false;
            if (cachedData == null) {
              _errorMessage = 'No profile data available. Please login again.';
            }
          });
        }
        return;
      }
    } catch (e) {
      // On error, use cached data
      if (mounted) {
        final userData = await AuthService.getUserData();
        setState(() {
          _userData = userData;
          _isLoading = false;
          _errorMessage = 'Error loading profile: ${e.toString()}';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load profile: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () {
                _loadUserData();
              },
            ),
          ),
        );
      }
    }
  }

  Future<void> _handleLogout(BuildContext context, {bool closeDialog = true}) async {
    if (_isLoggingOut) return; // Prevent multiple calls

    setState(() {
      _isLoggingOut = true;
    });
    _logoutLoadingNotifier.value = true;

    bool apiLogoutSuccess = false;
    String? apiMessage;

    try {
      // Call logout API and wait for response
      final token = await AuthService.getToken();
      
      if (token != null && token.isNotEmpty) {
        try {
          final response = await ApiService.logout(token);
          apiLogoutSuccess = response['success'] == true;
          apiMessage = response['message'] as String?;
          print('Logout API response: success=${apiLogoutSuccess}, message=$apiMessage');
        } catch (e) {
          print('Logout API error: $e');
          apiLogoutSuccess = false;
          apiMessage = 'API call failed: ${e.toString()}';
        }
      } else {
        print('No token available for logout API call');
      }
    } catch (e) {
      print('Error calling logout API: $e');
      apiLogoutSuccess = false;
    }

    // Always clear local auth data - this is the critical part
    try {
      await AuthService.logout();
      print('Local auth data cleared successfully');
    } catch (e) {
      print('Error clearing local auth data: $e');
    }

    // Close dialog if it's open
    if (closeDialog && context.mounted) {
      try {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      } catch (e) {
        print('Error closing dialog: $e');
      }
    }

    // Small delay to ensure dialog is closed
    await Future.delayed(const Duration(milliseconds: 200));

    // Show success message
    if (context.mounted) {
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    apiLogoutSuccess 
                        ? (apiMessage ?? 'Logout successfully')
                        : 'Logout successfully (local)',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.successGreen,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        print('Error showing snackbar: $e');
      }
    }

    // Wait briefly for message to appear, then navigate
    await Future.delayed(const Duration(milliseconds: 500));

    // Always navigate to login screen - use global navigator key for reliable navigation
    bool navigationSucceeded = false;
    
    // Primary approach: Use global navigator key (most reliable)
    try {
      if (navigatorKey.currentState != null) {
        navigatorKey.currentState!.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false, // Remove all previous routes
        );
        navigationSucceeded = true;
        print('Navigation successful using global navigator key');
      }
    } catch (e) {
      print('Global navigator key error: $e');
    }
    
    // Fallback 1: Try rootNavigator with context
    if (!navigationSucceeded && context.mounted) {
      try {
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false, // Remove all previous routes
        );
        navigationSucceeded = true;
        print('Navigation successful using rootNavigator');
      } catch (e) {
        print('RootNavigator error: $e');
      }
    }
    
    // Fallback 2: Try without rootNavigator
    if (!navigationSucceeded && context.mounted) {
      try {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
        navigationSucceeded = true;
        print('Navigation successful using standard navigator');
      } catch (e) {
        print('Standard navigator error: $e');
      }
    }
    
    // Fallback 3: Try pushReplacement as last resort
    if (!navigationSucceeded && context.mounted) {
      try {
        Navigator.of(context, rootNavigator: true).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
        navigationSucceeded = true;
        print('Navigation successful using pushReplacement');
      } catch (e) {
        print('PushReplacement error: $e');
      }
    }
    
    if (!navigationSucceeded) {
      print('WARNING: All navigation methods failed. User may need to restart app.');
    }
    
    // Reset state
    if (mounted) {
      setState(() {
        _isLoggingOut = false;
      });
      _logoutLoadingNotifier.value = false;
    }
  }
  
  @override
  void dispose() {
    _logoutLoadingNotifier.dispose();
    super.dispose();
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing during logout
      builder: (dialogContext) => ValueListenableBuilder<bool>(
        valueListenable: _logoutLoadingNotifier,
        builder: (context, isLoggingOut, _) {
          return _LogoutDialog(
            isLoggingOut: isLoggingOut,
            onLogout: () async {
              // Call logout - dialog will be closed in _handleLogout
              await _handleLogout(dialogContext, closeDialog: true);
            },
            onCancel: () {
              if (!isLoggingOut) {
                Navigator.pop(dialogContext);
              }
            },
          );
        },
      ),
    );
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
      child: Consumer<LevelProvider>(
        builder: (context, levelProvider, child) {
          final currentLevel = levelProvider.currentLevel ?? EducationLevel.junior;
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Container(
              decoration: BoxDecoration(
                gradient: LevelTheme.getBackgroundGradient(currentLevel),
              ),
              child: SafeArea(
                child: _isLoading
                    ? _buildLoadingSkeleton(currentLevel)
                    : _errorMessage != null && _userData == null
                        ? _buildErrorState()
                        : RefreshIndicator(
                            onRefresh: _loadUserData,
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: Column(
                                children: [
                                  // Back Button
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      children: [
                                        const CustomBackButton(),
                                        const Spacer(),
                                        IconButton(
                                          icon: Icon(
                                            Icons.refresh,
                                            color: LevelTheme.getPrimaryColor(currentLevel),
                                          ),
                                          onPressed: _loadUserData,
                                          tooltip: 'Refresh Profile',
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_errorMessage != null && _userData != null)
                                    _buildErrorMessageBanner(),
                                  const SizedBox(height: 10),
                                  // Profile Avatar with Camera Icon
                                  _buildProfileAvatar(currentLevel),
                                  const SizedBox(height: 20),
                                  _buildProfileName(),
                                  const SizedBox(height: 8),
                                  _buildLevelBadge(currentLevel),
                                  const SizedBox(height: 16),
                                  _buildEditProfileButton(currentLevel),
                                  const SizedBox(height: 32),
                                  // Stats Grid
                                  _buildStatsGrid(currentLevel),
                                  const SizedBox(height: 32),
                                  // Account Information
                                  if (_userData != null) _buildAccountInfo(currentLevel),
                                  const SizedBox(height: 32),
                                  // Achievements
                                  const Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'My Achievements',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1F2937),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildAchievementRow(),
                                  const SizedBox(height: 32),
                                  // Menu Items
                                  _buildMenuItem(
                                    icon: Icons.settings_outlined,
                                    title: 'Settings',
                                    color: const Color(0xFF6B7280),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildMenuItem(
                                    icon: Icons.notifications_outlined,
                                    title: 'Notifications',
                                    color: const Color(0xFF6B7280),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildMenuItem(
                                    icon: Icons.help_outline,
                                    title: 'Help & Support',
                                    color: const Color(0xFF6B7280),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildMenuItem(
                                    icon: Icons.info_outline,
                                    title: 'About',
                                    color: const Color(0xFF6B7280),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildMenuItem(
                                    icon: Icons.logout,
                                    title: 'Logout',
                                    color: Colors.red,
                                    onTap: () => _showLogoutDialog(context),
                                  ),
                                  const SizedBox(height: 100),
                                ],
                              ),
                            ),
                          ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingSkeleton(String? currentLevel) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Header skeleton
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Back button placeholder
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const Spacer(),
                SkeletonLoader(
                  width: 32,
                  height: 32,
                  borderRadius: BorderRadius.circular(16),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Avatar skeleton
          SkeletonCircle(size: 120),
          const SizedBox(height: 20),

          // Name skeleton
          SkeletonLoader(
            width: 160,
            height: 20,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(height: 8),
          SkeletonLoader(
            width: 100,
            height: 14,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(height: 16),

          // Level badge skeleton
          SkeletonLoader(
            width: 140,
            height: 26,
            borderRadius: BorderRadius.circular(20),
          ),
          const SizedBox(height: 32),

          // Stats skeleton row
          Row(
            children: [
              Expanded(
                child: SkeletonLoader(
                  width: double.infinity,
                  height: 80,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SkeletonLoader(
                  width: double.infinity,
                  height: 80,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SkeletonLoader(
                  width: double.infinity,
                  height: 80,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Account info card skeleton
          SkeletonLoader(
            width: double.infinity,
            height: 140,
            borderRadius: BorderRadius.circular(20),
          ),
          const SizedBox(height: 20),

          // Secondary cards skeleton (agent / addresses / timestamps)
          SkeletonLoader(
            width: double.infinity,
            height: 110,
            borderRadius: BorderRadius.circular(20),
          ),
          const SizedBox(height: 16),
          SkeletonLoader(
            width: double.infinity,
            height: 110,
            borderRadius: BorderRadius.circular(20),
          ),
          const SizedBox(height: 40),
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
              'Failed to Load Profile',
              style: AppTextStyles.heading2.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unable to fetch profile data',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadUserData,
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

  Widget _buildErrorMessageBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage ?? 'Using cached data',
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.orange.shade700,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            color: Colors.orange,
            onPressed: () {
              setState(() {
                _errorMessage = null;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(String? currentLevel) {
    final profileImage = _userData?['profileImage'] as String?;
    final gradientColors = LevelTheme.getGradientColors(currentLevel);
    
    return Stack(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B5CF6).withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipOval(
            child: profileImage != null && profileImage.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: profileImage,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: const Color(0xFF8B5CF6),
                      child: const Center(
                        child: Text(
                          '👦',
                          style: TextStyle(fontSize: 60),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: const Color(0xFF8B5CF6),
                      child: const Center(
                        child: Text(
                          '👦',
                          style: TextStyle(fontSize: 60),
                        ),
                      ),
                    ),
                  )
                : Container(
                    color: const Color(0xFF8B5CF6),
                    child: const Center(
                      child: Text(
                        '👦',
                        style: TextStyle(fontSize: 60),
                      ),
                    ),
                  ),
          ),
        ),
        // Camera Icon
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Change profile picture'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  const Center(
                    child: Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileName() {
    final name = _userData?['name'] as String? ?? 'Student';
    final studentId = _userData?['studentId'] as String? ?? '';
    
    return Column(
      children: [
        Text(
          name,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1F2937),
          ),
        ),
        if (studentId.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            studentId,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLevelBadge(String? currentLevel) {
    final studentLevel = _userData?['studentLevel'];
    String levelName = '';
    
    if (studentLevel != null) {
      if (studentLevel is Map) {
        levelName = studentLevel['name']?.toString() ?? '';
      } else if (studentLevel is String) {
        levelName = studentLevel;
      }
    }
    
    // If no level from API, use current level
    if (levelName.isEmpty) {
      levelName = currentLevel ?? 'Junior';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🌟', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(
            levelName,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditProfileButton(String? currentLevel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditProfileScreen(
                userData: _userData,
                onProfileUpdated: () {
                  // Reload profile data after update
                  _loadUserData();
                },
              ),
            ),
          );
        },
        icon: const Icon(Icons.edit, size: 18),
        label: const Text('Edit Profile'),
        style: ElevatedButton.styleFrom(
          backgroundColor: LevelTheme.getPrimaryColor(currentLevel),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildStatsGrid(String? currentLevel) {
    // You can customize these stats based on actual data from API
    // For now, showing placeholder stats
    return Row(
      children: [
        Expanded(
          child: _buildStatBox('24', 'Completed', const Color(0xFF8B5CF6)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatBox('156', 'Points', const Color(0xFF3B82F6)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatBox('12', 'Streak', const Color(0xFFFBBF24)),
        ),
      ],
    );
  }

  Widget _buildAccountInfo(String? currentLevel) {
    if (_userData == null) return const SizedBox.shrink();

    final studentLevel = _userData?['studentLevel'];
    final board = _userData?['board'];
    final agent = _userData?['agent'];
    final addresses = _userData?['addresses'] as List?;
    final contactNumber = _userData?['contactNumber'] as String? ?? '';
    final role = _userData?['role'] as String? ?? '';
    final isActive = _userData?['isActive'] as bool? ?? false;
    final lastLogin = _userData?['lastLogin'] as String?;
    final createdAt = _userData?['createdAt'] as String?;
    final updatedAt = _userData?['updatedAt'] as String?;
    final email = _userData?['email'] as String? ?? '';
    
    String levelName = '';
    String levelDescription = '';
    if (studentLevel != null) {
      if (studentLevel is Map) {
        levelName = studentLevel['name']?.toString() ?? '';
        levelDescription = studentLevel['description']?.toString() ?? '';
      } else if (studentLevel is String) {
        levelName = studentLevel;
      }
    }
    
    String boardName = '';
    String boardCode = '';
    String boardDescription = '';
    if (board != null && board is Map) {
      boardName = board['name']?.toString() ?? '';
      boardCode = board['code']?.toString() ?? '';
      boardDescription = board['description']?.toString() ?? '';
    }

    String agentName = '';
    String agentEmail = '';
    String agentContact = '';
    if (agent != null && agent is Map) {
      agentName = agent['name']?.toString() ?? '';
      agentEmail = agent['email']?.toString() ?? '';
      agentContact = agent['contactNumber']?.toString() ?? '';
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Highlighted Board card (if available)
        if (boardName.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.4),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.account_balance,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Board',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        boardCode.isNotEmpty ? '$boardName ($boardCode)' : boardName,
                        style: AppTextStyles.heading3.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (boardDescription.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          boardDescription,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 11,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        if (boardName.isNotEmpty) const SizedBox(height: 20),

        // Account Information
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Account Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: LevelTheme.getPrimaryColor(currentLevel),
                ),
              ),
              const SizedBox(height: 16),
              if (email.isNotEmpty)
                _buildInfoRow(Icons.email, 'Email', email),
              if (email.isNotEmpty) const SizedBox(height: 12),
              if (contactNumber.isNotEmpty)
                _buildInfoRow(Icons.phone, 'Contact Number', contactNumber),
              if (contactNumber.isNotEmpty) const SizedBox(height: 12),
              if (levelName.isNotEmpty)
                _buildInfoRow(
                  Icons.school,
                  'Education Level',
                  levelName,
                ),
              if (levelDescription.isNotEmpty) const SizedBox(height: 8),
              if (levelDescription.isNotEmpty)
                Text(
                  levelDescription,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              const SizedBox(height: 12),
              if (role.isNotEmpty)
                _buildInfoRow(Icons.person_outline, 'Role', role.toUpperCase()),
              const SizedBox(height: 12),
              _buildInfoRow(
                isActive ? Icons.check_circle : Icons.cancel,
                'Status',
                isActive ? 'Active' : 'Inactive',
              ),
            ],
          ),
        ),

        // Agent Information
        if (agentName.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.person_add, color: LevelTheme.getPrimaryColor(currentLevel), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Referred By',
                      style: AppTextStyles.heading3.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoRow(Icons.person, 'Agent Name', agentName),
                if (agentEmail.isNotEmpty) const SizedBox(height: 12),
                if (agentEmail.isNotEmpty)
                  _buildInfoRow(Icons.email, 'Agent Email', agentEmail),
                if (agentContact.isNotEmpty) const SizedBox(height: 12),
                if (agentContact.isNotEmpty)
                  _buildInfoRow(Icons.phone, 'Agent Contact', agentContact),
              ],
            ),
          ),
        ],

        // Addresses
        if (addresses != null && addresses.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on, color: LevelTheme.getPrimaryColor(currentLevel), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Addresses',
                      style: AppTextStyles.heading3.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...addresses.asMap().entries.map((entry) {
                  final index = entry.key;
                  final address = entry.value as Map<String, dynamic>;
                  return Padding(
                    padding: EdgeInsets.only(bottom: index < addresses.length - 1 ? 16 : 0),
                    child: _buildAddressCard(address),
                  );
                }).toList(),
              ],
            ),
          ),
        ],

        // Account timestamps
        if (lastLogin != null || createdAt != null || updatedAt != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.access_time, color: LevelTheme.getPrimaryColor(currentLevel), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Account Activity',
                      style: AppTextStyles.heading3.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (lastLogin != null)
                  _buildInfoRow(Icons.login, 'Last Login', _formatDateTime(lastLogin)),
                if (lastLogin != null) const SizedBox(height: 12),
                if (createdAt != null)
                  _buildInfoRow(Icons.calendar_today, 'Account Created', _formatDateTime(createdAt)),
                if (createdAt != null) const SizedBox(height: 12),
                if (updatedAt != null)
                  _buildInfoRow(Icons.update, 'Last Updated', _formatDateTime(updatedAt)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _formatDateTime(String? dateTimeString) {
    if (dateTimeString == null || dateTimeString.isEmpty) return 'N/A';
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeString;
    }
  }

  Widget _buildAddressCard(Map<String, dynamic> address) {
    final areaName = address['areaname'] as String? ?? '';
    final city = address['city'] as String? ?? '';
    final pincode = address['pincode'] as String? ?? '';
    final location = address['location'] as Map<String, dynamic>?;
    final lat = location?['latitude'];
    final lng = location?['longitude'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (areaName.isNotEmpty)
            Text(
              areaName,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          if (areaName.isNotEmpty && (city.isNotEmpty || pincode.isNotEmpty))
            const SizedBox(height: 4),
          if (city.isNotEmpty || pincode.isNotEmpty)
            Text(
              [city, pincode].where((s) => s.isNotEmpty).join(', '),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          if ((lat != null || lng != null) && (areaName.isNotEmpty || city.isNotEmpty))
            const SizedBox(height: 8),
          if (lat != null || lng != null)
            Row(
              children: [
                Icon(Icons.gps_fixed, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  'Lat: ${lat?.toStringAsFixed(4) ?? 'N/A'}, Lng: ${lng?.toStringAsFixed(4) ?? 'N/A'}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatBox(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildAchievementBadge('🏆', 'Winner', const Color(0xFFFBBF24)),
        _buildAchievementBadge('⭐', 'Star', const Color(0xFF8B5CF6)),
        _buildAchievementBadge('🎯', 'Target', const Color(0xFF3B82F6)),
        _buildAchievementBadge('🔥', 'Fire', const Color(0xFFEF4444)),
        _buildAchievementBadge('💎', 'Diamond', const Color(0xFF10B981)),
      ],
    );
  }

  Widget _buildAchievementBadge(String emoji, String label, Color color) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 28),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
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
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: title == 'Logout' ? Colors.red : const Color(0xFF1F2937),
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 18,
              color: color.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }
}

// Separate widget for logout dialog to properly handle state updates
class _LogoutDialog extends StatefulWidget {
  final bool isLoggingOut;
  final VoidCallback onLogout;
  final VoidCallback onCancel;

  const _LogoutDialog({
    required this.isLoggingOut,
    required this.onLogout,
    required this.onCancel,
  });

  @override
  State<_LogoutDialog> createState() => _LogoutDialogState();
}

class _LogoutDialogState extends State<_LogoutDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Row(
        children: [
          Icon(Icons.logout, color: Colors.red, size: 24),
          const SizedBox(width: 12),
          const Text('Logout'),
        ],
      ),
      content: widget.isLoggingOut
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                ),
                const SizedBox(height: 16),
                Text(
                  'Logging out...',
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            )
          : Text(
              'Are you sure you want to logout?',
              style: AppTextStyles.bodyMedium,
            ),
      actions: widget.isLoggingOut
          ? [] // No actions during logout
          : [
              TextButton(
                onPressed: widget.onCancel,
                child: Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              ElevatedButton(
                onPressed: widget.onLogout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Logout'),
              ),
            ],
    );
  }
}

