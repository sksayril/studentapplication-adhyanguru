import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';
import '../utils/navigation_helper.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _isLoggingOut = false;
  String? _errorMessage;

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
      // First try to get from API
      final token = await AuthService.getToken();
      print('Loading profile data. Token available: ${token != null && token.isNotEmpty}');
      
      if (token != null && token.isNotEmpty) {
        print('Calling profile API...');
        final response = await ApiService.getProfile(token);
        
        print('Profile API Response status: ${response['success']}');
        print('Profile API Response message: ${response['message']}');
        print('Has data: ${response['data'] != null}');
        
        if (mounted) {
          if (response['success'] == true && response['data'] != null) {
            final profileData = response['data'] as Map<String, dynamic>;
            
            // Debug: Print profile data keys
            print('Profile data loaded successfully!');
            print('Profile data keys: ${profileData.keys.toList()}');
            print('Profile name: ${profileData['name']}');
            print('Profile email: ${profileData['email']}');
            print('Has board: ${profileData['board'] != null}');
            print('Has agent: ${profileData['agent'] != null}');
            print('Has addresses: ${profileData['addresses'] != null}');
            
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
            // API returned error
            final errorMsg = response['message'] ?? 'Failed to load profile';
            if (mounted) {
              // Try to use cached data as fallback
              final cachedData = await AuthService.getUserData();
              if (cachedData != null) {
                setState(() {
                  _userData = cachedData;
                  _isLoading = false;
                  _errorMessage = 'Using cached data. $errorMsg';
                });
                
                // Show error snackbar
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
      
      // Fallback to cached data
      final userData = await AuthService.getUserData();
      if (mounted) {
        setState(() {
          _userData = userData;
          _isLoading = false;
          if (userData == null) {
            _errorMessage = 'No profile data available';
          }
        });
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
        
        // Show error message
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
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null && _userData == null
                  ? _buildErrorState()
                  : RefreshIndicator(
                      onRefresh: _loadUserData,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          children: [
                            _buildHeader(context),
                            if (_errorMessage != null && _userData != null)
                              _buildErrorMessageBanner(),
                            _buildProfileInfo(),
                            const SizedBox(height: 24),
                            _buildUserDetails(),
                            const SizedBox(height: 24),
                            _buildStatsCards(),
                            const SizedBox(height: 24),
                            _buildMenuItems(context),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
        ),
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

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const CustomBackButton(),
          const SizedBox(width: 12),
          Text(
            'Profile',
            style: AppTextStyles.heading2.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.primary),
            onPressed: _loadUserData,
            tooltip: 'Refresh Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo() {
    if (_userData == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: const Center(
          child: Text('No profile data available'),
        ),
      );
    }

    final profileImage = _userData?['profileImage'] as String?;
    final name = _userData?['name'] as String? ?? 'User';
    final email = _userData?['email'] as String? ?? '';
    final studentId = _userData?['studentId'] as String? ?? '';

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Profile Image
          Hero(
            tag: 'profile_image',
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary,
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
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
                          color: AppColors.primary.withOpacity(0.1),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: AppColors.secondary,
                          child: const Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : Container(
                        color: AppColors.secondary,
                        child: const Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Name
          Text(
            name,
            style: AppTextStyles.heading1.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          // Student ID
          if (studentId.isNotEmpty)
            Text(
              studentId,
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 14,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          const SizedBox(height: 8),
          // Email
          Text(
            email,
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 15,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          // Edit Profile Button
          ElevatedButton.icon(
            onPressed: () {
              // Handle edit profile
            },
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('Edit Profile'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserDetails() {
    if (_userData == null) {
      return const SizedBox.shrink();
    }

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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Account Information
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Account Information',
                  style: AppTextStyles.heading3.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                if (levelName.isNotEmpty)
                  _buildDetailRow(
                    Icons.school,
                    'Education Level',
                    levelName,
                    subtitle: levelDescription.isNotEmpty ? levelDescription : null,
                  ),
                if (levelName.isNotEmpty) const SizedBox(height: 12),
                if (boardName.isNotEmpty)
                  _buildDetailRow(
                    Icons.account_balance,
                    'Board',
                    boardCode.isNotEmpty ? '$boardName ($boardCode)' : boardName,
                    subtitle: boardDescription.isNotEmpty ? boardDescription : null,
                  ),
                if (boardName.isNotEmpty) const SizedBox(height: 12),
                if (contactNumber.isNotEmpty)
                  _buildDetailRow(
                    Icons.phone,
                    'Contact Number',
                    contactNumber,
                  ),
                if (contactNumber.isNotEmpty) const SizedBox(height: 12),
                if (role.isNotEmpty)
                  _buildDetailRow(
                    Icons.person_outline,
                    'Role',
                    role.toUpperCase(),
                  ),
                if (role.isNotEmpty) const SizedBox(height: 12),
                _buildDetailRow(
                  isActive ? Icons.check_circle : Icons.cancel,
                  'Status',
                  isActive ? 'Active' : 'Inactive',
                ),
              ],
            ),
          ),
          
          // Agent Information (if available)
          if (agentName.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person_add, color: AppColors.primary, size: 20),
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
                  _buildDetailRow(
                    Icons.person,
                    'Agent Name',
                    agentName,
                  ),
                  if (agentEmail.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      Icons.email,
                      'Agent Email',
                      agentEmail,
                    ),
                  ],
                  if (agentContact.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      Icons.phone,
                      'Agent Contact',
                      agentContact,
                    ),
                  ],
                ],
              ),
            ),
          ],
          
          // Addresses (if available)
          if (addresses != null && addresses.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on, color: AppColors.primary, size: 20),
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
          
          // Account Timestamps (if available)
          if (lastLogin != null || createdAt != null || updatedAt != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.access_time, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Account Timestamps',
                        style: AppTextStyles.heading3.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (lastLogin != null)
                    _buildDetailRow(
                      Icons.login,
                      'Last Login',
                      _formatDateTime(lastLogin),
                    ),
                  if (lastLogin != null) const SizedBox(height: 12),
                  if (createdAt != null)
                    _buildDetailRow(
                      Icons.calendar_today,
                      'Account Created',
                      _formatDateTime(createdAt),
                    ),
                  if (createdAt != null) const SizedBox(height: 12),
                  if (updatedAt != null)
                    _buildDetailRow(
                      Icons.update,
                      'Last Updated',
                      _formatDateTime(updatedAt),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
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

  Widget _buildDetailRow(IconData icon, String label, String value, {String? subtitle}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
              if (subtitle != null && subtitle.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard('Courses', '12', Icons.book, const Color(0xFF4A9DEC)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard('Tests', '45', Icons.assignment, const Color(0xFFFF9800)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard('Score', '85%', Icons.star, const Color(0xFF4CAF50)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTextStyles.heading2.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItems(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.person_outline,
            title: 'Account Settings',
            subtitle: 'Manage your account',
            onTap: () {},
          ),
          const SizedBox(height: 12),
          _buildMenuItem(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Alerts and reminders',
            onTap: () {},
          ),
          const SizedBox(height: 12),
          _buildMenuItem(
            icon: Icons.security_outlined,
            title: 'Privacy & Security',
            subtitle: 'Control your privacy',
            onTap: () {},
          ),
          const SizedBox(height: 12),
          _buildMenuItem(
            icon: Icons.help_outline,
            title: 'Help & Support',
            subtitle: 'Get help and support',
            onTap: () {},
          ),
          const SizedBox(height: 12),
          _buildMenuItem(
            icon: Icons.info_outline,
            title: 'About',
            subtitle: 'Version 1.0.0',
            onTap: () {},
          ),
          const SizedBox(height: 12),
          _buildMenuItem(
            icon: Icons.logout,
            title: 'Logout',
            subtitle: 'Sign out of your account',
            isLogout: true,
            onTap: () {
              _showLogoutDialog(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isLogout
                    ? Colors.red.withOpacity(0.1)
                    : AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isLogout ? Colors.red : AppColors.primary,
                size: 24,
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
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isLogout ? Colors.red : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
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
}

