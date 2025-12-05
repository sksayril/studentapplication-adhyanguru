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
import 'board_selection_screen.dart';
import 'class_selection_screen.dart';
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
  String? _selectedStudentLevel;
  String? _selectedBoardId;
  String? _selectedClassId;
  String? _selectedStreamId;
  String? _selectedDegreeId;
  File? _profileImage;
  double? _currentLatitude;
  double? _currentLongitude;
  final ImagePicker _picker = ImagePicker();
  late PageController _pageController;
  late AnimationController _slideController;
  
  // Intermediate path selection: 'class11-12' or 'graduate'
  String? _intermediatePath;
  
  // Class selection state
  List<Map<String, dynamic>> _availableClasses = [];
  bool _isLoadingClasses = false;
  String? _classesErrorMessage;
  String? _lastLoadedLevel;
  String? _lastLoadedBoard;
  
  // Stream selection state (for Intermediate)
  List<Map<String, dynamic>> _availableStreams = [];
  bool _isLoadingStreams = false;
  String? _streamsErrorMessage;
  
  // Degree selection state (for Senior and Intermediate Graduate)
  List<Map<String, dynamic>> _availableDegrees = [];
  bool _isLoadingDegrees = false;
  String? _degreesErrorMessage;

  final List<String> _studentLevels = ['Junior', 'Intermediate', 'Senior'];

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

  // Helper methods to determine step flow based on level
  int _getTotalSteps() {
    if (_selectedStudentLevel == null) return 5; // Default before level selection
    switch (_selectedStudentLevel!.toLowerCase()) {
      case 'junior':
        return 5; // Personal, Level, Board, Class, Address
      case 'intermediate':
        // Personal, Level, Board, Path Selection, (Class+Stream OR Degree), Address
        if (_intermediatePath == 'class11-12') {
          return 7; // Personal, Level, Board, Path, Class, Stream, Address
        } else if (_intermediatePath == 'graduate') {
          return 6; // Personal, Level, Board, Path, Degree, Address
        }
        return 6; // Default: Personal, Level, Board, Path, (will be class+stream or degree), Address
      case 'senior':
        return 5; // Personal, Level, Board, Degree, Address
      default:
        return 5;
    }
  }

  String _getStepType(int step) {
    if (_selectedStudentLevel == null) {
      // Default flow before level selection
      if (step == 0) return 'personal';
      if (step == 1) return 'level';
      if (step == 2) return 'board';
      if (step == 3) return 'class';
      if (step == 4) return 'address';
      return 'unknown';
    }
    
    switch (_selectedStudentLevel!.toLowerCase()) {
      case 'junior':
        if (step == 0) return 'personal';
        if (step == 1) return 'level';
        if (step == 2) return 'board';
        if (step == 3) return 'class';
        if (step == 4) return 'address';
        break;
      case 'intermediate':
        if (step == 0) return 'personal';
        if (step == 1) return 'level';
        if (step == 2) return 'board';
        if (step == 3) return 'intermediatePath';
        if (step == 4) {
          // Class for Class 11-12 path, Degree for Graduate path
          return _intermediatePath == 'class11-12' ? 'class' : 'degree';
        }
        if (step == 5) {
          // Stream for Class 11-12 path, Address for Graduate path
          return _intermediatePath == 'class11-12' ? 'stream' : 'address';
        }
        if (step == 6) return 'address';
        break;
      case 'senior':
        if (step == 0) return 'personal';
        if (step == 1) return 'level';
        if (step == 2) return 'board';
        if (step == 3) return 'degree';
        if (step == 4) return 'address';
        break;
    }
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
      case 'level':
        if (_selectedStudentLevel == null) {
          _showError('Please select your student level');
          return false;
        }
        return true;
      case 'board':
        // Board is required for Junior, optional for Intermediate/Senior
        if (_selectedStudentLevel?.toLowerCase() == 'junior' && _selectedBoardId == null) {
          _showError('Please select your board');
          return false;
        }
        return true;
      case 'intermediatePath':
        // Path selection is required for Intermediate
        if (_selectedStudentLevel?.toLowerCase() == 'intermediate' && _intermediatePath == null) {
          _showError('Please select Class 11-12 or Graduate');
          return false;
        }
        return true;
      case 'class':
        // Class is required for Junior and Intermediate (Class 11-12 path)
        if ((_selectedStudentLevel?.toLowerCase() == 'junior' || 
             (_selectedStudentLevel?.toLowerCase() == 'intermediate' && _intermediatePath == 'class11-12')) && 
            _selectedClassId == null) {
          _showError('Please select your class');
          return false;
        }
        return true;
      case 'stream':
        // Stream is required for Intermediate (Class 11-12 path)
        if (_selectedStudentLevel?.toLowerCase() == 'intermediate' && 
            _intermediatePath == 'class11-12' && 
            _selectedStreamId == null) {
          _showError('Please select your stream');
          return false;
        }
        return true;
      case 'degree':
        // Degree is required for Senior or Intermediate (Graduate path)
        if ((_selectedStudentLevel?.toLowerCase() == 'senior' ||
             (_selectedStudentLevel?.toLowerCase() == 'intermediate' && _intermediatePath == 'graduate')) &&
            _selectedDegreeId == null) {
          _showError('Please select your degree');
          return false;
        }
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

    // Additional validation: Ensure class is selected for Junior and Intermediate (Class 11-12)
    if ((_selectedStudentLevel?.toLowerCase() == 'junior' ||
         (_selectedStudentLevel?.toLowerCase() == 'intermediate' && _intermediatePath == 'class11-12')) && 
        (_selectedClassId == null || _selectedClassId!.trim().isEmpty)) {
      _showError('Please select your class before signing up');
      return;
    }
    
    // Additional validation: Ensure stream is selected for Intermediate (Class 11-12)
    if (_selectedStudentLevel?.toLowerCase() == 'intermediate' && 
        _intermediatePath == 'class11-12' &&
        (_selectedStreamId == null || _selectedStreamId!.trim().isEmpty)) {
      _showError('Please select your stream before signing up');
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

      // Ensure class ID is passed if selected
      String? classIdToSend = _selectedClassId;
      
      // Debug: Print class ID state before processing
      print('=== CLASS ID PROCESSING ===');
      print('_selectedClassId (raw): $_selectedClassId');
      print('_selectedClassId type: ${_selectedClassId.runtimeType}');
      print('_selectedClassId is null: ${_selectedClassId == null}');
      if (_selectedClassId != null) {
        print('_selectedClassId length: ${_selectedClassId!.length}');
        print('_selectedClassId trimmed: ${_selectedClassId!.trim()}');
      }
      
      // Validate and prepare class ID for sending
      if (classIdToSend != null) {
        classIdToSend = classIdToSend.trim();
        if (classIdToSend.isEmpty) {
          classIdToSend = null; // Don't send empty string
          print('Class ID became null after trimming (was empty)');
        } else {
          print('Class ID after processing: $classIdToSend');
        }
      } else {
        print('Class ID is null, cannot send');
      }
      print('===========================');

      // Debug: Print all signup data being sent
      print('=== SIGNUP DEBUG ===');
      print('Name: ${_nameController.text.trim()}');
      print('Email: ${_emailController.text.trim()}');
      print('Student Level: ${_selectedStudentLevel}');
      print('Board ID: $_selectedBoardId');
      print('Class ID to send: $classIdToSend');
      print('Class ID to send type: ${classIdToSend.runtimeType}');
      print('Class ID to send is null: ${classIdToSend == null}');
      if (classIdToSend != null) {
        print('Class ID to send length: ${classIdToSend.length}');
      }
      print('Stream ID to send: $_selectedStreamId');
      print('Degree ID to send: $_selectedDegreeId');
      print('Has Profile Image: ${_profileImage != null}');
      print('Has Addresses: ${addresses != null && addresses!.isNotEmpty}');
      print('===================');

      // Final validation: Ensure class ID is not lost
      final finalClassId = classIdToSend;
      print('=== FINAL CHECK BEFORE API CALL ===');
      print('Final classId parameter: $finalClassId');
      print('===================================');

      final response = await ApiService.signup(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        studentLevel: _selectedStudentLevel!.toLowerCase(),
        contactNumber: _contactNumberController.text.trim(),
        agentId: _agentIdController.text.trim().isEmpty
            ? null
            : _agentIdController.text.trim(),
        boardId: _selectedBoardId,
        classId: finalClassId, // Send class ID if selected (will be sent as both 'class' and 'classId')
        streamId: _selectedStreamId, // Send stream ID for Intermediate Class 11-12 students
        degreeId: _selectedDegreeId, // Send degree ID for Senior or Intermediate Graduate students
        profileImage: _profileImage,
        addresses: addresses,
      );

      if (mounted) {
        if (response['success'] == true) {
          // Update level provider with selected level (for login screen theme)
          final levelProvider = Provider.of<LevelProvider>(context, listen: false);
          if (_selectedStudentLevel != null) {
            await levelProvider.setLevel(_selectedStudentLevel!);
          }

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
                  key: ValueKey('${_selectedStudentLevel}_${_intermediatePath}_${pages.length}'), // Rebuild when level, path, or page count changes
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
      _buildStudentLevelStep(),
      _buildBoardSelectionStep(),
    ];

    // For Intermediate: Add path selection step (Class 11-12 or Graduate)
    if (_selectedStudentLevel?.toLowerCase() == 'intermediate') {
      print('=== Building Intermediate Path Selection Step ===');
      pages.add(_buildIntermediatePathSelectionStep());
      print('Total pages after adding intermediate path step: ${pages.length}');
    }

    // Add class step for Junior and Intermediate (Class 11-12 path)
    // Intermediate needs class selection to get classId (Class 11 or 12)
    if (_selectedStudentLevel?.toLowerCase() == 'junior' ||
        (_selectedStudentLevel?.toLowerCase() == 'intermediate' && _intermediatePath == 'class11-12')) {
      print('=== Adding Class Selection Step ===');
      pages.add(_buildClassSelectionStep());
      print('Total pages after adding class step: ${pages.length}');
    }

    // Add stream step for Intermediate (Class 11-12 path)
    if (_selectedStudentLevel?.toLowerCase() == 'intermediate' && 
        _intermediatePath == 'class11-12') {
      print('=== Adding Stream Selection Step ===');
      pages.add(_buildStreamSelectionStep());
      print('Total pages after adding stream step: ${pages.length}');
    }

    // Add degree step for Senior or Intermediate (Graduate path)
    if (_selectedStudentLevel?.toLowerCase() == 'senior' ||
        (_selectedStudentLevel?.toLowerCase() == 'intermediate' && _intermediatePath == 'graduate')) {
      pages.add(_buildDegreeSelectionStep());
    }

    // Always add address as last step
    pages.add(_buildAddressStep());

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

  Widget _buildStudentLevelStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Your Level',
            style: AppTextStyles.heading2.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose your education level',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          
          ..._studentLevels.map((level) {
            final isSelected = _selectedStudentLevel == level;
            final colors = _getLevelColors(level);
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: GestureDetector(
                  onTap: () {
                    setState(() {
                      // Clear intermediate path when level changes
                      if (_selectedStudentLevel != level) {
                        _intermediatePath = null;
                        _selectedClassId = null;
                        _selectedStreamId = null;
                        _selectedDegreeId = null;
                        _availableClasses = [];
                        _availableStreams = [];
                        _availableDegrees = [];
                        _lastLoadedLevel = null;
                        _lastLoadedBoard = null;
                      }
                      _selectedStudentLevel = level;
                      print('=== Student Level Selected: $level ===');
                      print('Current step: $_currentStep');
                    });
                    // Force PageView rebuild by jumping to current page after rebuild
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        final pages = _buildStepPages();
                        print('Pages after level selection: ${pages.length}');
                        print('Current step: $_currentStep');
                        if (_pageController.hasClients && _currentStep < pages.length) {
                          _pageController.jumpToPage(_currentStep);
                        }
                      }
                    });
                  },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isSelected
                          ? [colors[0], colors[1]]
                          : [Colors.white, Colors.white],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? colors[0] : Colors.grey.shade300,
                      width: isSelected ? 2.5 : 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? colors[0].withOpacity(0.3)
                            : Colors.black.withOpacity(0.05),
                        blurRadius: isSelected ? 20 : 10,
                        offset: Offset(0, isSelected ? 8 : 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withOpacity(0.3)
                              : colors[0].withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _getLevelEmoji(level),
                          style: const TextStyle(fontSize: 36),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              level,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getLevelDescription(level),
                              style: TextStyle(
                                fontSize: 14,
                                color: isSelected
                                    ? Colors.white.withOpacity(0.9)
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.check_rounded,
                            color: colors[0],
                            size: 24,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildIntermediatePathSelectionStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Your Path',
            style: AppTextStyles.heading2.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose Class 11-12 or Graduate',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          // Class 11-12 Option
          GestureDetector(
            onTap: () {
              setState(() {
                _intermediatePath = 'class11-12';
                // Clear previous selections when path changes
                _selectedClassId = null;
                _selectedStreamId = null;
                _selectedDegreeId = null;
                _availableClasses = [];
                _availableStreams = [];
                _availableDegrees = [];
                // Reset last loaded to force reload
                _lastLoadedLevel = null;
                _lastLoadedBoard = null;
                print('=== Class 11-12 Path Selected ===');
                print('Intermediate path: $_intermediatePath');
              });
              // The PageView will rebuild due to key change
              // After rebuild, ensure we stay on current step or navigate to next
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  final pages = _buildStepPages();
                  print('Pages after Class 11-12 selection: ${pages.length}');
                  print('Current step: $_currentStep');
                  // If we're on path selection step (step 3), move to class selection (step 4)
                  // Intermediate Class 11-12 path requires class selection before streams
                  if (_currentStep == 3 && pages.length > 4) {
                    setState(() {
                      _currentStep = 4; // Class selection step
                    });
                    if (_pageController.hasClients) {
                      _pageController.jumpToPage(4);
                    }
                  } else if (_pageController.hasClients && _currentStep < pages.length) {
                    _pageController.jumpToPage(_currentStep);
                  }
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _intermediatePath == 'class11-12'
                    ? AppColors.primary.withOpacity(0.1)
                    : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _intermediatePath == 'class11-12'
                      ? AppColors.primary
                      : Colors.grey.shade300,
                  width: _intermediatePath == 'class11-12' ? 2.5 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _intermediatePath == 'class11-12'
                        ? AppColors.primary.withOpacity(0.2)
                        : Colors.black.withOpacity(0.05),
                    blurRadius: _intermediatePath == 'class11-12' ? 15 : 10,
                    offset: Offset(0, _intermediatePath == 'class11-12' ? 6 : 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: _intermediatePath == 'class11-12'
                          ? AppColors.primary
                          : AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        '11-12',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _intermediatePath == 'class11-12'
                              ? Colors.white
                              : AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Class 11-12',
                          style: AppTextStyles.heading3.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: _intermediatePath == 'class11-12'
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Select this if you are in Class 11 or 12. You will need to choose a stream.',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_intermediatePath == 'class11-12')
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Graduate Option
          GestureDetector(
            onTap: () {
              setState(() {
                _intermediatePath = 'graduate';
                // Clear previous selections when path changes
                _selectedClassId = null;
                _selectedStreamId = null;
                _selectedDegreeId = null;
                _availableClasses = [];
                _availableStreams = [];
                _availableDegrees = [];
                _lastLoadedLevel = null;
                _lastLoadedBoard = null;
                print('=== Graduate Path Selected ===');
                print('Intermediate path: $_intermediatePath');
              });
              // The PageView will rebuild due to key change
              // After rebuild, ensure we stay on current step or navigate to next
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  final pages = _buildStepPages();
                  print('Pages after Graduate selection: ${pages.length}');
                  print('Current step: $_currentStep');
                  // If we're on path selection step (step 3), move to degree selection (step 4)
                  if (_currentStep == 3 && pages.length > 4) {
                    setState(() {
                      _currentStep = 4;
                    });
                    if (_pageController.hasClients) {
                      _pageController.jumpToPage(4);
                    }
                  } else if (_pageController.hasClients && _currentStep < pages.length) {
                    _pageController.jumpToPage(_currentStep);
                  }
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _intermediatePath == 'graduate'
                    ? AppColors.primary.withOpacity(0.1)
                    : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _intermediatePath == 'graduate'
                      ? AppColors.primary
                      : Colors.grey.shade300,
                  width: _intermediatePath == 'graduate' ? 2.5 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _intermediatePath == 'graduate'
                        ? AppColors.primary.withOpacity(0.2)
                        : Colors.black.withOpacity(0.05),
                    blurRadius: _intermediatePath == 'graduate' ? 15 : 10,
                    offset: Offset(0, _intermediatePath == 'graduate' ? 6 : 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: _intermediatePath == 'graduate'
                          ? AppColors.primary
                          : AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.school,
                        size: 32,
                        color: _intermediatePath == 'graduate'
                            ? Colors.white
                            : AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Graduate',
                          style: AppTextStyles.heading3.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: _intermediatePath == 'graduate'
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Select this if you are pursuing graduation. You will need to choose a degree.',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_intermediatePath == 'graduate')
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (_intermediatePath != null) ...[
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
                      _intermediatePath == 'class11-12'
                          ? 'Class 11-12 selected. Continue to select your class and stream.'
                          : 'Graduate selected. Continue to select your degree.',
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

  Widget _buildBoardSelectionStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Your Board',
            style: AppTextStyles.heading2.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose your education board',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: ElevatedButton.icon(
              onPressed: () async {
                if (_selectedStudentLevel == null) {
                  _showError('Please select your level first');
                  return;
                }
                
                final boardId = await Navigator.push<String>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BoardSelectionScreen(
                      selectedLevel: _selectedStudentLevel!,
                    ),
                  ),
                );
                
                if (boardId != null && mounted) {
                  setState(() {
                    _selectedBoardId = boardId;
                  });
                }
              },
              icon: Icon(
                _selectedBoardId != null ? Icons.check_circle : Icons.school,
                color: Colors.white,
              ),
              label: Text(
                _selectedBoardId != null
                    ? 'Board Selected'
                    : 'Select Board',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          if (_selectedBoardId != null) ...[
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
                      'Board has been selected. You can continue to the next step.',
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

  Widget _buildClassSelectionStep() {
    // Load classes when step is shown (only need studentLevel, board is optional)
    // Only reload if level or board changed
    // For Intermediate, also check that path is selected
    final shouldLoad = _selectedStudentLevel != null && 
        !_isLoadingClasses &&
        (_lastLoadedLevel != _selectedStudentLevel || _lastLoadedBoard != _selectedBoardId) &&
        (_selectedStudentLevel!.toLowerCase() != 'intermediate' || _intermediatePath == 'class11-12');
    
    if (shouldLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadClassesForSignup();
      });
    }

    // Only use classes from API, no fallback data
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Your Class',
            style: AppTextStyles.heading2.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose your class',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          if (_isLoadingClasses)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_classesErrorMessage != null)
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
                      _classesErrorMessage!,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else if (_availableClasses.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(
                      Icons.school_outlined,
                      size: 64,
                      color: AppColors.textSecondary.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No classes available',
                      style: AppTextStyles.heading3,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedStudentLevel?.toLowerCase() == 'intermediate' && _intermediatePath == null
                          ? 'Please select Class 11-12 or Graduate first'
                          : 'Please select your level and board first',
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
            ..._availableClasses.map((classData) {
              // Handle both API response format (_id) and fallback format (id)
              // Prioritize _id over id, and ensure we get a valid ID
              final rawId = classData['_id'] as String?;
              final rawId2 = classData['id'] as String?;
              final classId = (rawId?.trim().isNotEmpty == true) 
                  ? rawId!.trim() 
                  : ((rawId2?.trim().isNotEmpty == true) ? rawId2!.trim() : null);
              final className = classData['name'] as String? ?? '';
              final classNumber = classData['number'] as int? ?? 0;
              final isSelected = _selectedClassId == classId;

              // Debug: Print class data extraction
              print('=== CLASS DATA EXTRACTION ===');
              print('Class Name: $className');
              print('Raw _id: $rawId');
              print('Raw id: $rawId2');
              print('Extracted classId: $classId');
              print('ClassId is null: ${classId == null}');
              print('ClassId isEmpty: ${classId?.isEmpty ?? true}');
              print('============================');

              // Skip if no valid class ID
              if (classId == null || classId.isEmpty) {
                print('Skipping class card - no valid ID');
                return const SizedBox.shrink();
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedClassId = classId;
                      // Clear stream selection when class changes
                      _selectedStreamId = null;
                      _availableStreams = [];
                      print('=== CLASS SELECTED ===');
                      print('Class Name: $className');
                      print('Class ID: $classId');
                      print('Class Number: $classNumber');
                      print('Class ID Type: ${classId.runtimeType}');
                      print('Class ID Length: ${classId.length}');
                      print('====================');
                    });
                    // If Intermediate level with Class 11-12 path and class is 11 or 12, load streams
                    if (_selectedStudentLevel?.toLowerCase() == 'intermediate' &&
                        _intermediatePath == 'class11-12' &&
                        (classNumber == 11 || classNumber == 12)) {
                      print('=== Triggering Stream Load ===');
                      print('Class Number: $classNumber');
                      print('Intermediate Path: $_intermediatePath');
                      _loadStreams();
                    }
                  },
                  child: Container(
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
                              classNumber > 0 ? classNumber.toString() : (className.isNotEmpty ? className.substring(0, 1) : '?'),
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
                          child: Text(
                            className,
                            style: AppTextStyles.heading3.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                            ),
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
                ),
              );
            }).toList(),
          if (_selectedClassId != null) ...[
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
                      'Class has been selected. You can continue to the next step.',
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

  Future<void> _loadStreams() async {
    setState(() {
      _isLoadingStreams = true;
      _streamsErrorMessage = null;
    });

    try {
      // Get class number from selected class to filter streams (if class is selected)
      // For Intermediate, we can call streams API without class number
      int? classNumber;
      if (_selectedClassId != null && _availableClasses.isNotEmpty) {
        final selectedClass = _availableClasses.firstWhere(
          (c) => (c['_id'] as String? ?? c['id'] as String?) == _selectedClassId,
          orElse: () => {},
        );
        classNumber = selectedClass['number'] as int?;
      }
      // For Intermediate Class 11-12, we don't need class number - API returns all streams for 11-12
      // If no class selected, API will return all streams applicable for classes 11 and 12

      print('=== Calling Streams API ===');
      print('Class number: $classNumber');
      print('Intermediate path: $_intermediatePath');
      final response = await ApiService.getStreams(classNumber: classNumber);

      if (mounted) {
        if (response['success'] == true && response['data'] != null) {
          final data = response['data'] as Map<String, dynamic>;
          final streams = data['streams'] as List? ?? [];
          setState(() {
            // Map all streams (API doesn't include isActive field, all streams are active)
            _availableStreams = streams
                .map((s) => s as Map<String, dynamic>)
                .toList();
            _isLoadingStreams = false;
            _streamsErrorMessage = null;
            
            // Debug: Print loaded streams
            print('=== Streams Loaded from API ===');
            print('Total streams: ${_availableStreams.length}');
            for (var stream in _availableStreams) {
              print('Stream: ${stream['name']}, ID: ${stream['_id']}, Code: ${stream['code']}');
            }
            print('==============================');
          });
        } else {
          setState(() {
            _streamsErrorMessage = response['message'] ?? 'Failed to load streams';
            _isLoadingStreams = false;
            _availableStreams = [];
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _streamsErrorMessage = 'Error loading streams: ${e.toString()}';
          _isLoadingStreams = false;
          _availableStreams = [];
        });
      }
    }
  }

  Future<void> _loadDegrees() async {
    setState(() {
      _isLoadingDegrees = true;
      _degreesErrorMessage = null;
    });

    try {
      final response = await ApiService.getDegrees();

      if (mounted) {
        if (response['success'] == true && response['data'] != null) {
          final data = response['data'] as Map<String, dynamic>;
          final degrees = data['degrees'] as List? ?? [];
          setState(() {
            _availableDegrees = degrees
                .map((d) => d as Map<String, dynamic>)
                .where((d) => d['isActive'] == true)
                .toList();
            _isLoadingDegrees = false;
            _degreesErrorMessage = null;
          });
        } else {
          setState(() {
            _degreesErrorMessage = response['message'] ?? 'Failed to load degrees';
            _isLoadingDegrees = false;
            _availableDegrees = [];
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _degreesErrorMessage = 'Error loading degrees: ${e.toString()}';
          _isLoadingDegrees = false;
          _availableDegrees = [];
        });
      }
    }
  }

  Future<void> _loadClassesForSignup() async {
    if (_selectedStudentLevel == null) {
      return;
    }

    setState(() {
      _isLoadingClasses = true;
      _classesErrorMessage = null;
    });

    try {
      final response = await ApiService.getClasses(
        studentLevel: _selectedStudentLevel!.toLowerCase(),
        board: _selectedBoardId,
      );

      if (mounted) {
        if (response['success'] == true && response['data'] != null) {
          final classes = response['data'] as List;
          setState(() {
            _availableClasses = classes
                .map((c) {
                  final classMap = c as Map<String, dynamic>;
                  // Ensure both _id and id are present for consistency
                  // API returns _id, but we also set id for compatibility
                  if (classMap['_id'] != null) {
                    classMap['id'] = classMap['_id'];
                  } else if (classMap['id'] != null) {
                    classMap['_id'] = classMap['id'];
                  }
                  return classMap;
                })
                .where((c) {
                  // Filter active classes
                  if (c['isActive'] != true) return false;
                  
                  // For Intermediate Class 11-12 path, only show classes 11 and 12
                  if (_selectedStudentLevel?.toLowerCase() == 'intermediate' && 
                      _intermediatePath == 'class11-12') {
                    final classNumber = c['number'] as int?;
                    return classNumber == 11 || classNumber == 12;
                  }
                  
                  return true;
                })
                .toList();
            _isLoadingClasses = false;
            _classesErrorMessage = null;
            _lastLoadedLevel = _selectedStudentLevel;
            _lastLoadedBoard = _selectedBoardId;
          });
          
          // Debug: Print loaded classes
          print('=== Classes Loaded from API ===');
          print('Total classes: ${_availableClasses.length}');
          for (var cls in _availableClasses) {
            final classId = cls['_id'] as String? ?? cls['id'] as String? ?? 'N/A';
            print('Class: ${cls['name']}, ID: $classId, Number: ${cls['number']}');
          }
          print('==============================');
        } else {
          setState(() {
            _classesErrorMessage = response['message'] ?? 'Failed to load classes';
            _isLoadingClasses = false;
            _lastLoadedLevel = _selectedStudentLevel;
            _lastLoadedBoard = _selectedBoardId;
            _availableClasses = []; // Clear classes on error
          });
        }
      }
    } catch (e) {
      // Show error, no fallback data
      if (mounted) {
        setState(() {
          _classesErrorMessage = 'Error loading classes: ${e.toString()}';
          _isLoadingClasses = false;
          _lastLoadedLevel = _selectedStudentLevel;
          _lastLoadedBoard = _selectedBoardId;
          _availableClasses = []; // Clear classes on error
        });
      }
    }
  }

  Widget _buildStreamSelectionStep() {
    // Load streams when step is shown (only for Intermediate Class 11-12 path)
    // For Intermediate, we don't need class selection - load streams directly
    final shouldLoad = _selectedStudentLevel?.toLowerCase() == 'intermediate' &&
        _intermediatePath == 'class11-12' &&
        !_isLoadingStreams &&
        _availableStreams.isEmpty &&
        _streamsErrorMessage == null;
    
    if (shouldLoad) {
      print('=== Loading Streams for Intermediate (no class selection needed) ===');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadStreams();
      });
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Your Stream',
            style: AppTextStyles.heading2.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose your stream (Class 11-12)',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          if (_isLoadingStreams)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_streamsErrorMessage != null)
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
                      _streamsErrorMessage!,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadStreams,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else if (_availableStreams.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(
                      Icons.school_outlined,
                      size: 64,
                      color: AppColors.textSecondary.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No streams available',
                      style: AppTextStyles.heading3,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please select your class first',
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
            ..._availableStreams.map((streamData) {
              final streamId = streamData['_id'] as String? ?? streamData['id'] as String? ?? '';
              final streamName = streamData['name'] as String? ?? '';
              final streamCode = streamData['code'] as String? ?? '';
              final streamDescription = streamData['description'] as String? ?? '';
              final isSelected = _selectedStreamId == streamId;

              if (streamId.isEmpty) {
                return const SizedBox.shrink();
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedStreamId = streamId;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.successGreen
                            : Colors.grey.shade300,
                        width: isSelected ? 2.5 : 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected
                              ? AppColors.successGreen.withOpacity(0.2)
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
                                ? AppColors.successGreen
                                : AppColors.successGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              streamCode.isNotEmpty ? streamCode : (streamName.isNotEmpty ? streamName.substring(0, 1) : '?'),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.successGreen,
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
                                streamName,
                                style: AppTextStyles.heading3.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? AppColors.successGreen
                                      : AppColors.textPrimary,
                                ),
                              ),
                              if (streamDescription.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  streamDescription,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (isSelected)
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.successGreen,
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
                ),
              );
            }).toList(),
          if (_selectedStreamId != null) ...[
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
                      'Stream has been selected. You can continue to the next step.',
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

  Widget _buildDegreeSelectionStep() {
    // Load degrees when step is shown (for Senior or Intermediate Graduate path)
    final shouldLoad = (_selectedStudentLevel?.toLowerCase() == 'senior' ||
        (_selectedStudentLevel?.toLowerCase() == 'intermediate' && _intermediatePath == 'graduate')) &&
        !_isLoadingDegrees &&
        _availableDegrees.isEmpty &&
        _degreesErrorMessage == null;
    
    if (shouldLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadDegrees();
      });
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Your Degree',
            style: AppTextStyles.heading2.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose your degree program',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          if (_isLoadingDegrees)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_degreesErrorMessage != null)
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
                      _degreesErrorMessage!,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadDegrees,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else if (_availableDegrees.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(
                      Icons.school_outlined,
                      size: 64,
                      color: AppColors.textSecondary.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No degrees available',
                      style: AppTextStyles.heading3,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please try again later',
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
            ..._availableDegrees.map((degreeData) {
              final degreeId = degreeData['_id'] as String? ?? degreeData['id'] as String? ?? '';
              final degreeName = degreeData['name'] as String? ?? '';
              final degreeCode = degreeData['code'] as String? ?? '';
              final degreeDescription = degreeData['description'] as String? ?? '';
              final degreeType = degreeData['degreeType'] as String? ?? '';
              final duration = degreeData['duration'] as int?;
              final isSelected = _selectedDegreeId == degreeId;

              if (degreeId.isEmpty) {
                return const SizedBox.shrink();
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDegreeId = degreeId;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.secondary
                            : Colors.grey.shade300,
                        width: isSelected ? 2.5 : 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected
                              ? AppColors.secondary.withOpacity(0.2)
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
                                ? AppColors.secondary
                                : AppColors.secondary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              degreeCode.isNotEmpty ? degreeCode : (degreeName.isNotEmpty ? degreeName.substring(0, 1) : '?'),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.secondary,
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
                                degreeName,
                                style: AppTextStyles.heading3.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? AppColors.secondary
                                      : AppColors.textPrimary,
                                ),
                              ),
                              if (degreeDescription.isNotEmpty || degreeType.isNotEmpty || duration != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  [
                                    if (degreeType.isNotEmpty) degreeType,
                                    if (duration != null) '${duration} years',
                                  ].join(' • '),
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                if (degreeDescription.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    degreeDescription,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ],
                          ),
                        ),
                        if (isSelected)
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.secondary,
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
                ),
              );
            }).toList(),
          if (_selectedDegreeId != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.secondary,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Degree has been selected. You can continue to the next step.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.secondary,
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

  List<Color> _getLevelColors(String level) {
    switch (level) {
      case 'Junior':
        return [const Color(0xFF6C5CE7), const Color(0xFF6C5CE7).withOpacity(0.7)];
      case 'Intermediate':
        return [const Color(0xFF00B894), const Color(0xFF00B894).withOpacity(0.7)];
      case 'Senior':
        return [const Color(0xFFFF9F43), const Color(0xFFFF9F43).withOpacity(0.7)];
      default:
        return [AppColors.primary, AppColors.primary.withOpacity(0.7)];
    }
  }

  String _getLevelEmoji(String level) {
    switch (level) {
      case 'Junior':
        return '🎒';
      case 'Intermediate':
        return '🎓';
      case 'Senior':
        return '👨‍🎓';
      default:
        return '📚';
    }
  }

  String _getLevelDescription(String level) {
    switch (level) {
      case 'Junior':
        return 'Class 5 to 10';
      case 'Intermediate':
        return 'Class 11 to Graduation';
      case 'Senior':
        return 'Masters to PhD';
      default:
        return '';
    }
  }
}

