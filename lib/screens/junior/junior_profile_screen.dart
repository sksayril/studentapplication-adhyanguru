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

class JuniorProfileScreen extends StatefulWidget {
  const JuniorProfileScreen({Key? key}) : super(key: key);

  @override
  State<JuniorProfileScreen> createState() => _JuniorProfileScreenState();
}

class _JuniorProfileScreenState extends State<JuniorProfileScreen> {
  bool _isLoggingOut = false;

  Future<void> _handleLogout(BuildContext context) async {
    if (_isLoggingOut) return; // Prevent multiple calls

    setState(() {
      _isLoggingOut = true;
    });

    try {
      // Get token and call logout API
      final token = await AuthService.getToken();
      
      if (token != null && token.isNotEmpty) {
        final response = await ApiService.logout(token);
        
        if (context.mounted) {
          if (response['success'] == true) {
            // Show success message briefly
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Logged out successfully'),
                backgroundColor: AppColors.successGreen,
                duration: Duration(seconds: 1),
              ),
            );
          } else {
            // Show error but still logout locally
            final message = response['message'] ?? 'Logout failed';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      }
      
      // Clear local auth data regardless of API response
      await AuthService.logout();
      
      // Small delay to show message
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Navigate to login screen
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      // Even if API call fails, clear local data and logout
      await AuthService.logout();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logged out locally. ${e.toString()}'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
        
        // Small delay before navigation
        await Future.delayed(const Duration(milliseconds: 500));
        
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: !_isLoggingOut,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
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
            content: _isLoggingOut
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
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
            actions: _isLoggingOut
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
                        setDialogState(() {
                          _isLoggingOut = true;
                        });
                        Navigator.pop(context); // Close dialog
                        await _handleLogout(context);
                      },
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
                child: Column(
                  children: [
                    // Back Button
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          const CustomBackButton(),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          children: [
                            const SizedBox(height: 10),
                            // Profile Avatar with Camera Icon
                            Stack(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: LevelTheme.getGradientColors(currentLevel),
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
                      child: CachedNetworkImage(
                        imageUrl: 'https://source.unsplash.com/random/200x200/?portrait,child',
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
                      ),
                    ),
                  ),
                  // Camera Icon
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                        // Handle camera tap
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
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Alex Johnson',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('🌟', style: TextStyle(fontSize: 16)),
                              SizedBox(width: 6),
                              Text(
                                'Level 5 Explorer',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Stats Grid
                        Row(
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
                        ),
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
                  ],
                ),
              ),
            ),
          );
        },
      ),
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

