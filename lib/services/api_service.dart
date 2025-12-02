import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://2z669fsq-3000.inc1.devtunnels.ms';
  
  // Student Signup
  static Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String password,
    required String studentLevel,
    required String contactNumber,
    String? agentId,
    String? boardId,
    File? profileImage,
    List<Map<String, dynamic>>? addresses,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/students/signup');
      
      if (profileImage != null) {
        // Multipart request with image
        var request = http.MultipartRequest('POST', uri);
        request.fields['name'] = name;
        request.fields['email'] = email;
        request.fields['password'] = password;
        request.fields['studentLevel'] = studentLevel;
        request.fields['contactNumber'] = contactNumber;
        
        if (agentId != null && agentId.isNotEmpty) {
          request.fields['agentId'] = agentId;
        }
        
        if (boardId != null && boardId.isNotEmpty) {
          request.fields['boardId'] = boardId;
        }
        
        if (addresses != null && addresses.isNotEmpty) {
          request.fields['addresses'] = jsonEncode(addresses);
        }
        
        // Add profile image
        var imageFile = await http.MultipartFile.fromPath(
          'profileImage',
          profileImage.path,
        );
        request.files.add(imageFile);
        
        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);
        
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        // JSON request without image
        final response = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'name': name,
            'email': email,
            'password': password,
            'studentLevel': studentLevel,
            'contactNumber': contactNumber,
            if (agentId != null && agentId.isNotEmpty) 'agentId': agentId,
            if (boardId != null && boardId.isNotEmpty) 'boardId': boardId,
            if (addresses != null && addresses.isNotEmpty) 'addresses': addresses,
          }),
        );
        
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }
  
  // Student Login
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/students/login');
      
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );
      
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }
  
  // Student Logout
  static Future<Map<String, dynamic>> logout(String token) async {
    try {
      final uri = Uri.parse('$baseUrl/api/students/logout');
      
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }
  
  // Get All Boards
  static Future<Map<String, dynamic>> getBoards() async {
    try {
      final uri = Uri.parse('$baseUrl/api/boards');
      
      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );
      
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'data': [],
      };
    }
  }
  
  // Get Student Profile
  static Future<Map<String, dynamic>> getProfile(String token) async {
    try {
      final uri = Uri.parse('$baseUrl/api/students/profile');
      
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
      
      // Check HTTP status code
      if (response.statusCode == 200) {
        return responseBody;
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Unauthorized. Please login again.',
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Profile not found',
        };
      } else {
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Failed to load profile',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }
  
  // Update Student Profile
  static Future<Map<String, dynamic>> updateProfile({
    required String token,
    String? name,
    String? contactNumber,
    String? studentLevel,
    String? boardId,
    File? profileImage,
    List<Map<String, dynamic>>? addresses,
    String? profileImageUrl,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/students/profile');
      
      if (profileImage != null) {
        // Multipart request with image
        var request = http.MultipartRequest('POST', uri);
        request.headers['Authorization'] = 'Bearer $token';
        
        if (name != null) request.fields['name'] = name;
        if (contactNumber != null) request.fields['contactNumber'] = contactNumber;
        if (studentLevel != null) request.fields['studentLevel'] = studentLevel;
        if (boardId != null) request.fields['board'] = boardId;
        if (profileImageUrl != null) request.fields['profileImage'] = profileImageUrl;
        
        if (addresses != null && addresses.isNotEmpty) {
          request.fields['addresses'] = jsonEncode(addresses);
        }
        
        // Add profile image
        var imageFile = await http.MultipartFile.fromPath(
          'profileImage',
          profileImage.path,
        );
        request.files.add(imageFile);
        
        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);
        
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        // JSON request without image
        final response = await http.post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            if (name != null) 'name': name,
            if (contactNumber != null) 'contactNumber': contactNumber,
            if (studentLevel != null) 'studentLevel': studentLevel,
            if (boardId != null) 'board': boardId,
            if (profileImageUrl != null) 'profileImage': profileImageUrl,
            if (addresses != null && addresses.isNotEmpty) 'addresses': addresses,
          }),
        );
        
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }
}

