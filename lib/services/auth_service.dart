import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userDataKey = 'user_data';
  static const String _isLoggedInKey = 'is_logged_in';
  
  // Save authentication token
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setBool(_isLoggedInKey, true);
  }
  
  // Get authentication token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }
  
  // Save user data
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userDataKey, jsonEncode(userData));
  }
  
  // Get user data
  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString(_userDataKey);
    if (userDataString != null) {
      try {
        return jsonDecode(userDataString) as Map<String, dynamic>;
      } catch (e) {
        return null;
      }
    }
    return null;
  }
  
  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
    return token != null && token.isNotEmpty && isLoggedIn;
  }
  
  // Logout - clear all auth data
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userDataKey);
    await prefs.setBool(_isLoggedInKey, false);
  }
  
  // Save user info after login/signup
  static Future<void> saveUserInfo(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Extract token - check multiple possible locations
    String? token;
    if (data['token'] != null) {
      token = data['token'].toString();
    } else if (data['data'] != null && data['data'] is Map) {
      final userData = data['data'] as Map<String, dynamic>;
      if (userData['token'] != null) {
        token = userData['token'].toString();
      }
    }
    
    // Save token
    if (token != null && token.isNotEmpty) {
      await prefs.setString(_tokenKey, token);
    }
    
    // Save user details
    final userData = data['data'] ?? data;
    if (userData['id'] != null) {
      await prefs.setString('user_id', userData['id'].toString());
    }
    if (userData['studentId'] != null) {
      await prefs.setString('student_id', userData['studentId'].toString());
    }
    if (userData['name'] != null) {
      await prefs.setString('user_name', userData['name'].toString());
    }
    if (userData['email'] != null) {
      await prefs.setString('user_email', userData['email'].toString());
    }
    if (userData['contactNumber'] != null) {
      await prefs.setString('user_contact', userData['contactNumber'].toString());
    }
    if (userData['profileImage'] != null) {
      await prefs.setString('user_profile_image', userData['profileImage'].toString());
    }
    if (userData['studentLevel'] != null) {
      final level = userData['studentLevel'];
      String levelName = '';
      if (level is Map && level['name'] != null) {
        levelName = level['name'].toString();
      } else if (level is String) {
        levelName = level;
      }
      
      if (levelName.isNotEmpty) {
        // Capitalize first letter
        levelName = levelName.substring(0, 1).toUpperCase() + 
                   (levelName.length > 1 ? levelName.substring(1).toLowerCase() : '');
        await prefs.setString('student_level', levelName);
        await prefs.setString('education_level', levelName); // Also save for compatibility
      }
    }
    
    // Save board information
    if (userData['board'] != null) {
      final board = userData['board'];
      if (board is Map) {
        if (board['id'] != null) {
          await prefs.setString('board_id', board['id'].toString());
        }
        if (board['name'] != null) {
          await prefs.setString('board_name', board['name'].toString());
        }
        if (board['code'] != null) {
          await prefs.setString('board_code', board['code'].toString());
        }
      }
    }
    
    // Save class information
    if (userData['class'] != null) {
      final classData = userData['class'];
      if (classData is Map) {
        if (classData['id'] != null) {
          await prefs.setString('class_id', classData['id'].toString());
        }
        if (classData['_id'] != null) {
          await prefs.setString('class_id', classData['_id'].toString());
        }
        if (classData['name'] != null) {
          await prefs.setString('class_name', classData['name'].toString());
        }
        if (classData['number'] != null) {
          await prefs.setInt('class_number', classData['number'] as int);
        }
        if (classData['description'] != null) {
          await prefs.setString('class_description', classData['description'].toString());
        }
      }
    }
    
    // Save role and other info
    if (userData['role'] != null) {
      await prefs.setString('user_role', userData['role'].toString());
    }
    if (userData['isActive'] != null) {
      await prefs.setBool('user_is_active', userData['isActive'] as bool);
    }
    if (userData['lastLogin'] != null) {
      await prefs.setString('last_login', userData['lastLogin'].toString());
    }
    
    // Save complete user data as JSON for easy access
    await saveUserData(userData);
    
    await prefs.setBool(_isLoggedInKey, true);
  }
  
  // Get board information
  static Future<Map<String, String>?> getBoardInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final boardId = prefs.getString('board_id');
    final boardName = prefs.getString('board_name');
    final boardCode = prefs.getString('board_code');
    
    if (boardId != null || boardName != null) {
      return {
        'id': boardId ?? '',
        'name': boardName ?? '',
        'code': boardCode ?? '',
      };
    }
    return null;
  }
  
  // Get class information
  static Future<Map<String, dynamic>?> getClassInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final classId = prefs.getString('class_id');
    final className = prefs.getString('class_name');
    final classNumber = prefs.getInt('class_number');
    final classDescription = prefs.getString('class_description');
    
    if (classId != null || className != null) {
      return {
        'id': classId ?? '',
        '_id': classId ?? '',
        'name': className ?? '',
        'number': classNumber,
        'description': classDescription ?? '',
      };
    }
    return null;
  }
  
  // Get class ID
  static Future<String?> getClassId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('class_id');
  }
  
  // Save selected board ID (for filtering subjects)
  static Future<void> saveSelectedBoardId(String boardId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_board_id', boardId);
  }
  
  // Get selected board ID
  static Future<String?> getSelectedBoardId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('selected_board_id');
  }
  
  // Save board ID with student ID for automatic detection
  static Future<void> saveBoardForStudent(String studentId, String boardId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('board_for_student_$studentId', boardId);
  }
  
  // Get board ID for specific student
  static Future<String?> getBoardForStudent(String studentId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('board_for_student_$studentId');
  }
}

