import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';
import '../utils/level_theme.dart';
import '../providers/level_provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'signup_screen.dart';
import 'home_screen.dart';
import 'junior_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        if (response['success'] == true) {
          // Save user data and token from login response
          await AuthService.saveUserInfo(response);
          
          // Extract token from login response - check multiple possible locations
          String? token;
          final userData = response['data'] ?? response;
          
          if (response['token'] != null) {
            token = response['token'].toString();
          } else if (userData is Map && userData['token'] != null) {
            token = userData['token'].toString();
          }
          
          print('Login response - has token: ${token != null && token.isNotEmpty}');
          print('Login response structure: ${response.keys.toList()}');
          
          // Save login response data first
          await AuthService.saveUserData(userData);
          
          // Fetch complete profile from API if we have a token
          if (token != null && token.isNotEmpty) {
            try {
              print('Fetching profile after login with token...');
              final profileResponse = await ApiService.getProfile(token);
              
              print('Profile API response: ${profileResponse['success']}');
              
              if (profileResponse['success'] == true && profileResponse['data'] != null) {
                // Save complete profile data
                final profileData = profileResponse['data'] as Map<String, dynamic>;
                print('Profile fetched successfully: ${profileData['name']}');
                await AuthService.saveUserData(profileData);
                await AuthService.saveUserInfo({
                  'token': token,
                  'data': profileData,
                });
              } else {
                print('Profile API failed: ${profileResponse['message']}');
                // Keep login response data but ensure token is saved
                if (token.isNotEmpty) {
                  await AuthService.saveToken(token);
                }
              }
            } catch (e) {
              print('Error fetching profile after login: $e');
              // Keep login response data but ensure token is saved
              if (token.isNotEmpty) {
                await AuthService.saveToken(token);
              }
            }
          } else {
            print('No token found in login response');
          }
          
          // Update level provider
          final levelProvider = Provider.of<LevelProvider>(context, listen: false);
          if (userData['studentLevel'] != null) {
            final level = userData['studentLevel'];
            String levelName = '';
            if (level is Map && level['name'] != null) {
              levelName = level['name'].toString();
            } else if (level is String) {
              levelName = level;
            }
            if (levelName.isNotEmpty) {
              levelName = levelName.substring(0, 1).toUpperCase() + 
                         (levelName.length > 1 ? levelName.substring(1).toLowerCase() : '');
              await levelProvider.setLevel(levelName);
            }
          }
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login successful!'),
              backgroundColor: AppColors.successGreen,
            ),
          );

          // Navigate to appropriate home screen based on level
          final level = levelProvider.currentLevel;
          Widget homeScreen;
          if (level?.toLowerCase() == 'junior') {
            homeScreen = const JuniorHomeScreen();
          } else {
            homeScreen = const HomeScreen();
          }
          
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => homeScreen),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Login failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<LevelProvider>(
        builder: (context, levelProvider, child) {
          final currentLevel = levelProvider.currentLevel;
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LevelTheme.getBackgroundGradient(currentLevel),
            ),
            child: SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final availableHeight = constraints.maxHeight;
                    final minHeight = (availableHeight - 48).clamp(0.0, double.infinity);
                    
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(24.0),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: minHeight,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 40),
                        // Logo
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: LevelTheme.getGradientColors(currentLevel),
                              ),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: LevelTheme.getPrimaryColor(currentLevel).withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Text(
                              LevelTheme.getLevelEmoji(currentLevel),
                              style: const TextStyle(fontSize: 60),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        // Welcome Text
                        Text(
                          'Welcome Back!',
                          style: AppTextStyles.heading1.copyWith(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sign in to continue your learning journey',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 48),
                        // Login Form
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildTextField(
                                controller: _emailController,
                                label: 'Email',
                                hint: 'Enter your email',
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                currentLevel: currentLevel,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  if (!value.contains('@')) {
                                    return 'Please enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              _buildPasswordField(currentLevel),
                              const SizedBox(height: 32),
                              _buildLoginButton(currentLevel),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Sign Up Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SignupScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                'Sign Up',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: LevelTheme.getPrimaryColor(currentLevel),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    String? currentLevel,
  }) {
    final primaryColor = LevelTheme.getPrimaryColor(currentLevel);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: primaryColor),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField(String? currentLevel) {
    final primaryColor = LevelTheme.getPrimaryColor(currentLevel);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Password',
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your password';
            }
            if (value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: 'Enter your password',
            prefixIcon: Icon(Icons.lock_outlined, color: LevelTheme.getPrimaryColor(Provider.of<LevelProvider>(context, listen: false).currentLevel)),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: AppColors.textSecondary,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton(String? currentLevel) {
    final primaryColor = LevelTheme.getPrimaryColor(currentLevel);
    return ElevatedButton(
      onPressed: _isLoading ? null : _handleLogin,
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        shadowColor: primaryColor.withOpacity(0.3),
      ),
      child: _isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(
              'Sign In',
              style: AppTextStyles.buttonText.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
    );
  }
}

