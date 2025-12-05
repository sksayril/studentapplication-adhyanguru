import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../utils/colors.dart';
import '../../utils/text_styles.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final VoidCallback onProfileUpdated;

  const EditProfileScreen({
    Key? key,
    required this.userData,
    required this.onProfileUpdated,
  }) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactNumberController = TextEditingController();
  
  String? _selectedClassId;
  String? _selectedStudentLevel;
  String? _selectedBoardId;
  File? _profileImage;
  bool _isLoading = false;
  bool _isLoadingClasses = false;
  List<Map<String, dynamic>> _availableClasses = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeForm();
    _loadClasses();
  }

  void _initializeForm() {
    if (widget.userData != null) {
      _nameController.text = widget.userData!['name'] as String? ?? '';
      _contactNumberController.text = widget.userData!['contactNumber'] as String? ?? '';
      
      // Get student level
      final studentLevel = widget.userData!['studentLevel'];
      if (studentLevel is Map) {
        _selectedStudentLevel = studentLevel['name'] as String?;
      } else if (studentLevel is String) {
        _selectedStudentLevel = studentLevel;
      }
      
      // Get board
      final board = widget.userData!['board'];
      if (board is Map && board['id'] != null) {
        _selectedBoardId = board['id'] as String;
      }
      
      // Get class
      final classData = widget.userData!['class'];
      if (classData is Map) {
        _selectedClassId = classData['id'] as String? ?? classData['_id'] as String?;
      }
    }
  }

  Future<void> _loadClasses() async {
    if (_selectedStudentLevel == null || _selectedBoardId == null) {
      return;
    }

    setState(() {
      _isLoadingClasses = true;
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
                .map((c) => c as Map<String, dynamic>)
                .where((c) => c['isActive'] == true)
                .toList();
            _isLoadingClasses = false;
          });
        } else {
          setState(() {
            _availableClasses = [];
            _isLoadingClasses = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _availableClasses = [];
          _isLoadingClasses = false;
        });
      }
    }
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

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Not authenticated');
      }

      // Prepare class value - can be empty string to remove class assignment
      String? classValue = _selectedClassId;
      if (classValue != null && classValue.isEmpty) {
        classValue = null; // Don't send empty string, send null
      }
      
      final response = await ApiService.updateProfile(
        token: token,
        name: _nameController.text.trim(),
        contactNumber: _contactNumberController.text.trim(),
        studentLevel: _selectedStudentLevel,
        boardId: _selectedBoardId,
        classId: classValue, // Can be null to remove class assignment
        profileImage: _profileImage,
      );

      if (mounted) {
        if (response['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: AppColors.successGreen,
            ),
          );
          
          // Call callback to reload profile
          widget.onProfileUpdated();
          
          // Navigate back
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Failed to update profile'),
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
  void dispose() {
    _nameController.dispose();
    _contactNumberController.dispose();
    super.dispose();
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
          'Edit Profile',
          style: AppTextStyles.heading2.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Image
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
                            : widget.userData?['profileImage'] != null
                                ? ClipOval(
                                    child: Image.network(
                                      widget.userData!['profileImage'] as String,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          const Icon(Icons.person, size: 60),
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
              
              // Name Field
              _buildTextField(
                controller: _nameController,
                label: 'Full Name',
                hint: 'Enter your full name',
                icon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  if (value.length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Contact Number Field
              _buildTextField(
                controller: _contactNumberController,
                label: 'Contact Number',
                hint: 'Enter your contact number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your contact number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Class Selection
              if (_selectedStudentLevel != null && _selectedBoardId != null) ...[
                Text(
                  'Class',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                if (_isLoadingClasses)
                  const Center(child: CircularProgressIndicator())
                else
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: _availableClasses.isEmpty
                        ? Text(
                            'No classes available',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          )
                        : DropdownButtonHideUnderline(
                            child: DropdownButton<String?>(
                              value: _selectedClassId,
                              isExpanded: true,
                              hint: Text(
                                'Select your class (optional)',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              items: [
                                // Add option to remove class assignment
                                const DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text('None (Remove class)'),
                                ),
                                // Add available classes
                                ..._availableClasses.map((classData) {
                                  final classId = classData['_id'] as String? ?? classData['id'] as String? ?? '';
                                  final className = classData['name'] as String? ?? '';
                                  return DropdownMenuItem<String?>(
                                    value: classId,
                                    child: Text(className),
                                  );
                                }),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedClassId = value;
                                });
                              },
                            ),
                          ),
                  ),
                const SizedBox(height: 32),
              ],
              
              // Update Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
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
                      : const Text(
                          'Update Profile',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
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
    String? Function(String?)? validator,
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
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.primary),
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
}

