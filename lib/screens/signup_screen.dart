import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';
import '../utils/level_theme.dart';
import '../providers/level_provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/postal_service.dart';
import '../services/location_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'home_screen.dart';
import 'junior_home_screen.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _agentIdController = TextEditingController();
  final _areaNameController = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _districtController = TextEditingController();
  final _stateController = TextEditingController();
  
  int _currentStep = 0;
  bool _isLoading = false;
  bool _isFetchingPincode = false;
  bool _isGettingLocation = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  File? _profileImage;
  double? _currentLatitude;
  double? _currentLongitude;
  final ImagePicker _picker = ImagePicker();
  late PageController _pageController;
  late AnimationController _slideController;
  
  // Level category selection state
  List<Map<String, dynamic>> _levelCategories = [];
  bool _isLoadingLevelCategories = false;
  String? _levelCategoriesErrorMessage;
  String? _selectedLevelCategoryId;
  Map<String, dynamic>? _selectedLevelCategory;
  
  // Subcategory selection state
  List<Map<String, dynamic>> _availableSubcategories = [];
  String? _selectedSubcategoryId;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    // Add listener to pincode controller for auto-fill
    _pincodeController.addListener(_onPincodeChanged);
    
    // Load level categories
    _loadLevelCategories();
  }
  
  void _onPincodeChanged() {
    final pincode = _pincodeController.text.trim();
    // Fetch details when 6 digits are entered
    if (pincode.length == 6 && RegExp(r'^\d+$').hasMatch(pincode)) {
      _fetchPincodeDetails(pincode);
    }
  }
  
  Future<void> _fetchPincodeDetails(String pincode) async {
    if (_isFetchingPincode) return; // Prevent multiple calls
    
    setState(() {
      _isFetchingPincode = true;
    });
    
    try {
      final response = await PostalService.getDetailsByPincode(pincode);
      
      if (!mounted) return;
      
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;
        
        // Auto-fill the fields
        if (mounted) {
          setState(() {
            _cityController.text = data['city'] ?? '';
            _districtController.text = data['district'] ?? '';
            _stateController.text = data['state'] ?? '';
            
            // If area name is empty, suggest the first post office name
            if (_areaNameController.text.isEmpty && data['postOffices'] != null) {
              final postOffices = data['postOffices'] as List;
              if (postOffices.isNotEmpty) {
                _areaNameController.text = postOffices[0]['name'] ?? '';
              }
            }
          });
        }
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Address details fetched successfully!'),
              backgroundColor: AppColors.successGreen,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Failed to fetch pincode details'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
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
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingPincode = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _contactNumberController.dispose();
    _agentIdController.dispose();
    _areaNameController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    _districtController.dispose();
    _stateController.dispose();
    _pincodeController.removeListener(_onPincodeChanged);
    _pageController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: ${e.toString()}')),
        );
      }
    }
  }

  void _nextStep() {
    if (_validateCurrentStep()) {
      setState(() {
        _currentStep++;
      });
      // Check if we need to rebuild pages (e.g., when intermediate path is selected)
      final pages = _buildStepPages();
      if (_currentStep < pages.length && _pageController.hasClients) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
        );
      } else if (_currentStep < pages.length) {
        // If controller doesn't have clients yet, jump to page
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _pageController.hasClients && _currentStep < pages.length) {
            _pageController.jumpToPage(_currentStep);
          }
        });
      }
    }
  }

  void _previousStep() {
    setState(() {
      _currentStep--;
    });
    _pageController.previousPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  // Helper methods to determine step flow
  int _getTotalSteps() {
    return 4; // Personal, Level Category, Subcategory (optional), Address
  }

  String _getStepType(int step) {
    if (step == 0) return 'personal';
    if (step == 1) return 'levelCategory';
    if (step == 2) return 'subcategory';
    if (step == 3) return 'address';
    return 'unknown';
  }

  bool _validateCurrentStep() {
    final stepType = _getStepType(_currentStep);
    
    switch (stepType) {
      case 'personal':
        if (_nameController.text.isEmpty) {
          _showError('Please enter your name');
          return false;
        }
        if (_emailController.text.isEmpty) {
          _showError('Please enter your email');
          return false;
        }
        if (!_emailController.text.contains('@')) {
          _showError('Please enter a valid email');
          return false;
        }
        if (_passwordController.text.isEmpty) {
          _showError('Please enter a password');
          return false;
        }
        if (_passwordController.text.length < 6) {
          _showError('Password must be at least 6 characters');
          return false;
        }
        if (_confirmPasswordController.text != _passwordController.text) {
          _showError('Passwords do not match');
          return false;
        }
        if (_contactNumberController.text.isEmpty) {
          _showError('Please enter your contact number');
          return false;
        }
        return true;
      case 'levelCategory':
        if (_selectedLevelCategoryId == null) {
          _showError('Please select a level category');
          return false;
        }
        return true;
      case 'subcategory':
        // Subcategory is optional, so always return true
        return true;
      case 'address':
        if (_currentLatitude == null || _currentLongitude == null) {
          _showError('Please get your current location');
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _handleSignup() async {
    if (!_validateCurrentStep()) {
      return;
    }

    // Additional validation: Ensure level category is selected
    if (_selectedLevelCategoryId == null) {
      _showError('Please select a level category before signing up');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Prepare addresses
      List<Map<String, dynamic>>? addresses;
      if (_areaNameController.text.isNotEmpty ||
          _cityController.text.isNotEmpty ||
          _pincodeController.text.isNotEmpty) {
        addresses = [
          {
            'areaname': _areaNameController.text,
            'city': _cityController.text.isNotEmpty 
                ? _cityController.text 
                : _districtController.text,
            'pincode': _pincodeController.text,
            'location': {
              'latitude': _currentLatitude ?? 0.0,
              'longitude': _currentLongitude ?? 0.0,
            },
          }
        ];
      }

      // Get UI value from selected level category (defaults to 1)
      final ui = _selectedLevelCategory?['ui'] as int? ?? 1;

      final response = await ApiService.signup(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        levelCategory: _selectedLevelCategoryId!,
        contactNumber: _contactNumberController.text.trim(),
        agentId: _agentIdController.text.trim().isEmpty
            ? null
            : _agentIdController.text.trim(),
        subcategory: _selectedSubcategoryId,
        ui: ui,
        profileImage: _profileImage,
        addresses: addresses,
      );

      if (mounted) {
        if (response['success'] == true) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Signup successful! Please login to continue.'),
              backgroundColor: AppColors.successGreen,
              duration: Duration(seconds: 3),
            ),
          );

          // Navigate to login screen
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false, // Remove all previous routes
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Signup failed'),
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
          onPressed: () {
            if (_currentStep > 0) {
              _previousStep();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          'Create Account',
          style: AppTextStyles.heading2.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Progress Indicator
          _buildProgressIndicator(),
          
          // Form Content
          Expanded(
            child: Builder(
              builder: (context) {
                final pages = _buildStepPages();
                // Ensure current step is within bounds
                final safeStep = _currentStep < pages.length ? _currentStep : 0;
                
                return PageView(
                  key: ValueKey('${_selectedLevelCategoryId}_${pages.length}'), // Rebuild when category or page count changes
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) {
                    // Sync current step with page index
                    if (index != _currentStep && mounted) {
                      setState(() {
                        _currentStep = index;
                      });
                    }
                  },
                  children: pages,
                );
              },
            ),
          ),
          
          // Navigation Buttons
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  List<Widget> _buildStepPages() {
    final pages = <Widget>[
      _buildPersonalInfoStep(),
      _buildLevelCategorySelectionStep(),
      _buildSubcategorySelectionStep(),
      _buildAddressStep(),
    ];

    return pages;
  }

  Widget _buildProgressIndicator() {
    final totalSteps = _getTotalSteps();
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: List.generate(totalSteps, (index) {
          final isActive = index <= _currentStep;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.primary
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (index < totalSteps - 1) const SizedBox(width: 8),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPersonalInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Information',
            style: AppTextStyles.heading2.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tell us about yourself',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          
          // Profile Image Picker
          Center(
            child: GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.shade200,
                      border: Border.all(
                        color: AppColors.primary,
                        width: 3,
                      ),
                    ),
                    child: _profileImage != null
                        ? ClipOval(
                            child: Image.file(
                              _profileImage!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Icon(
                            Icons.person,
                            size: 60,
                            color: AppColors.textSecondary,
                          ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          
          _buildTextField(
            controller: _nameController,
            label: 'Full Name',
            hint: 'Enter your full name',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _emailController,
            label: 'Email',
            hint: 'Enter your email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          _buildPasswordField(
            controller: _passwordController,
            label: 'Password',
            hint: 'Enter password',
            obscureText: _obscurePassword,
            onToggleVisibility: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
          const SizedBox(height: 16),
          _buildPasswordField(
            controller: _confirmPasswordController,
            label: 'Confirm Password',
            hint: 'Confirm your password',
            obscureText: _obscureConfirmPassword,
            onToggleVisibility: () {
              setState(() {
                _obscureConfirmPassword = !_obscureConfirmPassword;
              });
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _contactNumberController,
            label: 'Contact Number',
            hint: 'Enter your contact number',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
    );
  }


  Future<void> _loadLevelCategories() async {
    setState(() {
      _isLoadingLevelCategories = true;
      _levelCategoriesErrorMessage = null;
    });

    try {
      final response = await ApiService.getLevelCategories();

      if (mounted) {
        if (response['success'] == true && response['data'] != null) {
          final categories = response['data'] as List;
          setState(() {
            _levelCategories = categories
                .where((c) => c['isActive'] == true)
                .map((c) => c as Map<String, dynamic>)
                .toList();
            _isLoadingLevelCategories = false;
            _levelCategoriesErrorMessage = null;
          });
        } else {
          setState(() {
            _levelCategoriesErrorMessage = response['message'] ?? 'Failed to load level categories';
            _isLoadingLevelCategories = false;
            _levelCategories = [];
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _levelCategoriesErrorMessage = 'Error loading level categories: ${e.toString()}';
          _isLoadingLevelCategories = false;
          _levelCategories = [];
        });
      }
    }
  }

  Widget _buildLevelCategorySelectionStep() {
    // Load categories if not already loaded
    if (!_isLoadingLevelCategories && _levelCategories.isEmpty && _levelCategoriesErrorMessage == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadLevelCategories();
      });
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Level Category',
            style: AppTextStyles.heading2.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose your education level category',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          if (_isLoadingLevelCategories)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_levelCategoriesErrorMessage != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red.withOpacity(0.7),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _levelCategoriesErrorMessage!,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadLevelCategories,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else if (_levelCategories.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(
                      Icons.category_outlined,
                      size: 64,
                      color: AppColors.textSecondary.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No level categories available',
                      style: AppTextStyles.heading3,
                    ),
                  ],
                ),
              ),
            )
          else
            ..._levelCategories.map((category) {
              final categoryId = category['_id'] as String? ?? '';
              final categoryName = category['categoryname'] as String? ?? '';
              final isSelected = _selectedLevelCategoryId == categoryId;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedLevelCategoryId = categoryId;
                      _selectedLevelCategory = category;
                      // Clear subcategory when category changes
                      _selectedSubcategoryId = null;
                      _availableSubcategories = (category['subcategories'] as List?)
                          ?.where((s) => s['isActive'] == true)
                          .map((s) => s as Map<String, dynamic>)
                          .toList() ?? [];
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.1)
                          : Colors.white,
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
                        Expanded(
                          child: Text(
                            categoryName,
                            style: AppTextStyles.heading3.copyWith(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: AppColors.primary,
                            size: 24,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          if (_selectedLevelCategoryId != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.successGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.successGreen,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: AppColors.successGreen,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Level category selected. Continue to select subcategory (optional).',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.successGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubcategorySelectionStep() {
    // Update available subcategories when level category is selected
    if (_selectedLevelCategory != null) {
      final subcategories = _selectedLevelCategory!['subcategories'] as List?;
      if (subcategories != null && _availableSubcategories.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            _availableSubcategories = subcategories
                .where((s) => s['isActive'] == true)
                .map((s) => s as Map<String, dynamic>)
                .toList();
          });
        });
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Subcategory (Optional)',
            style: AppTextStyles.heading2.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a subcategory if applicable',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          if (_selectedLevelCategoryId == null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 64,
                      color: AppColors.textSecondary.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Please select a level category first',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else if (_availableSubcategories.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(
                      Icons.category_outlined,
                      size: 64,
                      color: AppColors.textSecondary.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No subcategories available for this category',
                      style: AppTextStyles.heading3,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You can skip this step and continue',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ..._availableSubcategories.map((subcategory) {
              final subcategoryId = subcategory['_id'] as String? ?? '';
              final subcategoryName = subcategory['subcategoryname'] as String? ?? '';
              final isSelected = _selectedSubcategoryId == subcategoryId;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedSubcategoryId = subcategoryId;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.1)
                          : Colors.white,
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
                        Expanded(
                          child: Text(
                            subcategoryName,
                            style: AppTextStyles.heading3.copyWith(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: AppColors.primary,
                            size: 24,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          if (_selectedSubcategoryId != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.successGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.successGreen,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: AppColors.successGreen,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Subcategory selected. You can continue to the next step.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.successGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAddressStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Address Information',
            style: AppTextStyles.heading2.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your address details',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          
          // Location Access Button - Moved to top
          _buildLocationAccessButton(),
          const SizedBox(height: 32),
          
          _buildTextField(
            controller: _areaNameController,
            label: 'Area Name',
            hint: 'Enter area name',
            icon: Icons.location_on_outlined,
            isRequired: false,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _cityController,
            label: 'City',
            hint: 'Enter city',
            icon: Icons.location_city_outlined,
            isRequired: false,
          ),
          const SizedBox(height: 16),
          _buildPincodeField(),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _districtController,
            label: 'District',
            hint: 'Auto-filled from pincode',
            icon: Icons.map_outlined,
            isRequired: false,
            isReadOnly: true,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _stateController,
            label: 'State',
            hint: 'Auto-filled from pincode',
            icon: Icons.public_outlined,
            isRequired: false,
            isReadOnly: true,
          ),
          const SizedBox(height: 24),
          _buildTextField(
            controller: _agentIdController,
            label: 'Agent ID (Optional)',
            hint: 'Enter agent ID if referred',
            icon: Icons.person_add_outlined,
            isRequired: false,
          ),
        ],
      ),
    );
  }
  
  Widget _buildLocationAccessButton() {
    final hasLocation = _currentLatitude != null && _currentLongitude != null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Current Location',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              '*',
              style: TextStyle(
                color: Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _getCurrentLocation,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: hasLocation
                  ? LinearGradient(
                      colors: [
                        AppColors.successGreen.withOpacity(0.1),
                        AppColors.successGreen.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.1),
                        AppColors.primary.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: hasLocation 
                    ? AppColors.successGreen
                    : AppColors.primary,
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: (hasLocation ? AppColors.successGreen : AppColors.primary)
                      .withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: hasLocation
                        ? AppColors.successGreen.withOpacity(0.15)
                        : AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: (hasLocation ? AppColors.successGreen : AppColors.primary)
                            .withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    hasLocation ? Icons.my_location : Icons.location_searching,
                    color: hasLocation 
                        ? AppColors.successGreen
                        : AppColors.primary,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasLocation ? 'Location Captured ✓' : 'Get Current Location',
                        style: AppTextStyles.heading3.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (hasLocation) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.successGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.gps_fixed,
                                size: 14,
                                color: AppColors.successGreen,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Lat: ${_currentLatitude!.toStringAsFixed(6)}',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.successGreen,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Lng: ${_currentLongitude!.toStringAsFixed(6)}',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.successGreen,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        Text(
                          'Tap to capture your GPS coordinates',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: _showManualLocationDialog,
                          icon: Icon(
                            Icons.edit_location_alt,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          label: Text(
                            'Enter coordinates manually',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (_isGettingLocation)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: hasLocation
                          ? AppColors.successGreen.withOpacity(0.1)
                          : AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      hasLocation 
                          ? Icons.check_circle_rounded
                          : Icons.arrow_forward_ios_rounded,
                      color: hasLocation 
                          ? AppColors.successGreen
                          : AppColors.primary,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
    });

    try {
      final locationResult = await LocationService.getCurrentLocation();

      if (mounted) {
        if (locationResult != null && locationResult['success'] == true) {
          setState(() {
            _currentLatitude = locationResult['latitude'] as double;
            _currentLongitude = locationResult['longitude'] as double;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location captured successfully!'),
              backgroundColor: AppColors.successGreen,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          final shouldOpenSettings = locationResult?['openSettings'] == true;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(locationResult?['message'] ?? 'Failed to get location'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: shouldOpenSettings ? 'Open Settings' : 'Retry',
                textColor: Colors.white,
                onPressed: () async {
                  if (shouldOpenSettings) {
                    await openAppSettings();
                  } else {
                    // Request permission again
                    await Permission.location.request();
                    // Retry getting location
                    _getCurrentLocation();
                  }
                },
              ),
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
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGettingLocation = false;
        });
      }
    }
  }

  void _showManualLocationDialog() {
    final latController = TextEditingController();
    final lngController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Row(
                  children: [
                    Icon(Icons.edit_location_alt, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Enter Coordinates Manually',
                        style: AppTextStyles.heading3.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Content
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: latController,
                      decoration: InputDecoration(
                        labelText: 'Latitude',
                        hintText: 'e.g., 28.6139',
                        prefixIcon: const Icon(Icons.north),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: lngController,
                      decoration: InputDecoration(
                        labelText: 'Longitude',
                        hintText: 'e.g., 77.2090',
                        prefixIcon: const Icon(Icons.east),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Enter coordinates if GPS is unavailable',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        final lat = double.tryParse(latController.text.trim());
                        final lng = double.tryParse(lngController.text.trim());
                        
                        if (lat == null || lng == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter valid coordinates'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        
                        if (lat < -90 || lat > 90) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Latitude must be between -90 and 90'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        
                        if (lng < -180 || lng > 180) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Longitude must be between -180 and 180'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        
                        setState(() {
                          _currentLatitude = lat;
                          _currentLongitude = lng;
                        });
                        
                        Navigator.pop(context);
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Coordinates saved successfully!'),
                            backgroundColor: AppColors.successGreen,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Save'),
                    ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool isRequired = true,
    bool isReadOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: isReadOnly,
          maxLength: keyboardType == TextInputType.number ? 6 : null,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.primary),
            suffixIcon: isReadOnly
                ? const Icon(Icons.auto_awesome, color: AppColors.primary, size: 20)
                : null,
            filled: true,
            fillColor: isReadOnly ? Colors.grey.shade50 : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            counterText: '',
          ),
        ),
      ],
    );
  }
  
  Widget _buildPincodeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Pincode',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            if (_isFetchingPincode)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _pincodeController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: InputDecoration(
            hintText: 'Enter 6-digit pincode',
            prefixIcon: const Icon(Icons.pin_outlined, color: AppColors.primary),
            suffixIcon: _pincodeController.text.length == 6 && !_isFetchingPincode
                ? const Icon(Icons.check_circle, color: AppColors.successGreen, size: 20)
                : null,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            counterText: '',
            helperText: _pincodeController.text.length == 6 
                ? 'Address will be auto-filled' 
                : 'Enter 6 digits to auto-fill address',
            helperMaxLines: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
  }) {
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
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: const Icon(Icons.lock_outlined, color: AppColors.primary),
            suffixIcon: IconButton(
              icon: Icon(
                obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: AppColors.textSecondary,
              ),
              onPressed: onToggleVisibility,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
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
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _previousStep,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Previous',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 12),
            Expanded(
              flex: _currentStep == 0 ? 1 : 2,
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : (_currentStep < _getTotalSteps() - 1 ? _nextStep : _handleSignup),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  shadowColor: AppColors.primary.withOpacity(0.3),
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
                        _currentStep < _getTotalSteps() - 1 ? 'Next' : 'Sign Up',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}

