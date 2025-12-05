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
    String? classId,
    String? streamId,
    String? degreeId,
    File? profileImage,
    List<Map<String, dynamic>>? addresses,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/students/signup');
      
      // Debug logging
      print('=== API SERVICE SIGNUP CALLED ===');
      print('Signup API - Class ID received: $classId');
      print('Signup API - Class ID type: ${classId.runtimeType}');
      print('Signup API - Class ID is null: ${classId == null}');
      if (classId != null) {
        print('Signup API - Class ID length: ${classId.length}');
        print('Signup API - Class ID trimmed: ${classId.trim()}');
        print('Signup API - Class ID trimmed isEmpty: ${classId.trim().isEmpty}');
      }
      print('Signup API - Board ID received: $boardId');
      print('Signup API - Has profile image: ${profileImage != null}');
      print('==================================');
      
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
        
        // Send board as both 'board' and 'boardId' for compatibility
        if (boardId != null && boardId.isNotEmpty) {
          request.fields['board'] = boardId;
          request.fields['boardId'] = boardId; // Also send as boardId for compatibility
        }
        
        // Send class ID as both 'class' and 'classId' for compatibility
        // Always send if provided and not empty
        if (classId != null && classId.trim().isNotEmpty) {
          final trimmedClassId = classId.trim();
          request.fields['class'] = trimmedClassId;
          request.fields['classId'] = trimmedClassId; // Also send as classId for compatibility
          print('Signup API (Multipart) - Added class ID to form fields: $trimmedClassId');
        } else {
          print('Signup API (Multipart) - Class ID is null or empty: $classId');
        }
        
        // Send stream ID as both 'stream' and 'streamId' for compatibility (Intermediate)
        if (streamId != null && streamId.trim().isNotEmpty) {
          final trimmedStreamId = streamId.trim();
          request.fields['stream'] = trimmedStreamId;
          request.fields['streamId'] = trimmedStreamId;
          print('Signup API (Multipart) - Added stream ID to form fields: $trimmedStreamId');
        }
        
        // Send degree ID as both 'degree' and 'degreeId' for compatibility (Senior)
        if (degreeId != null && degreeId.trim().isNotEmpty) {
          final trimmedDegreeId = degreeId.trim();
          request.fields['degree'] = trimmedDegreeId;
          request.fields['degreeId'] = trimmedDegreeId;
          print('Signup API (Multipart) - Added degree ID to form fields: $trimmedDegreeId');
        }
        
        if (addresses != null && addresses.isNotEmpty) {
          request.fields['addresses'] = jsonEncode(addresses);
        }
        
        // Debug: Print all form fields before sending
        print('=== MULTIPART REQUEST FIELDS ===');
        print('Form fields keys: ${request.fields.keys.toList()}');
        print('Form fields: ${request.fields}');
        if (request.fields.containsKey('class')) {
          print('class field value: ${request.fields['class']}');
        } else {
          print('class field: NOT FOUND');
        }
        if (request.fields.containsKey('classId')) {
          print('classId field value: ${request.fields['classId']}');
        } else {
          print('classId field: NOT FOUND');
        }
        print('===============================');
        
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
        // Build request body
        final requestBody = <String, dynamic>{
          'name': name,
          'email': email,
          'password': password,
          'studentLevel': studentLevel,
          'contactNumber': contactNumber,
          if (agentId != null && agentId.isNotEmpty) 'agentId': agentId,
          // Send board as both 'board' and 'boardId' for compatibility
          if (boardId != null && boardId.isNotEmpty) 'board': boardId,
          if (boardId != null && boardId.isNotEmpty) 'boardId': boardId,
          // Send class ID as both 'class' and 'classId' for compatibility
          if (classId != null && classId.trim().isNotEmpty) 'class': classId.trim(),
          if (classId != null && classId.trim().isNotEmpty) 'classId': classId.trim(),
          // Send stream ID as both 'stream' and 'streamId' for compatibility (Intermediate)
          if (streamId != null && streamId.trim().isNotEmpty) 'stream': streamId.trim(),
          if (streamId != null && streamId.trim().isNotEmpty) 'streamId': streamId.trim(),
          // Send degree ID as both 'degree' and 'degreeId' for compatibility (Senior)
          if (degreeId != null && degreeId.trim().isNotEmpty) 'degree': degreeId.trim(),
          if (degreeId != null && degreeId.trim().isNotEmpty) 'degreeId': degreeId.trim(),
          if (addresses != null && addresses.isNotEmpty) 'addresses': addresses,
        };
        
        // Debug: Print request body
        print('Signup API (JSON) - Request body keys: ${requestBody.keys.toList()}');
        if (classId != null && classId.trim().isNotEmpty) {
          print('Signup API (JSON) - Sending class ID: ${classId.trim()}');
        } else {
          print('Signup API (JSON) - Class ID is null or empty: $classId');
        }
        
        final response = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestBody),
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
  
  // Student Logout (Protected)
  // Method: POST
  // URL: /api/students/logout
  // Authentication required - Bearer token in Authorization header
  static Future<Map<String, dynamic>> logout(String token) async {
    try {
      final uri = Uri.parse('$baseUrl/api/students/logout');
      
      print('=== API SERVICE LOGOUT ===');
      print('URL: $uri');
      print('Token length: ${token.length}');
      print('Token preview: ${token.substring(0, token.length > 20 ? 20 : token.length)}...');
      
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
      
      // Handle different status codes according to API documentation
      if (response.statusCode == 200) {
        // Success 200
        print('Logout API success: ${responseBody['success']}');
        print('Logout API message: ${responseBody['message']}');
        return responseBody;
      } else if (response.statusCode == 401) {
        // Error 401 (Not authenticated or Invalid token)
        print('Logout API error 401: ${responseBody['message']}');
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Invalid or expired token',
        };
      } else if (response.statusCode == 403) {
        // Error 403 (Forbidden: not a Student)
        print('Logout API error 403: ${responseBody['message']}');
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Forbidden: not a Student',
        };
      } else {
        // Other errors
        print('Logout API error ${response.statusCode}: ${responseBody['message']}');
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Logout failed',
        };
      }
    } catch (e, stackTrace) {
      print('=== LOGOUT API EXCEPTION ===');
      print('Error: $e');
      print('Error type: ${e.runtimeType}');
      print('Stack trace: $stackTrace');
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
  
  // Get Competitive Exams
  static Future<Map<String, dynamic>> getCompetitiveExams({String? level}) async {
    try {
      final uri = Uri.parse('$baseUrl/api/competitive-exams').replace(
        queryParameters: level != null ? {'level': level} : null,
      );
      
      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );
      
      final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
      
      if (response.statusCode == 200) {
        return responseBody;
      } else {
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Failed to load competitive exams',
          'data': [],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'data': [],
      };
    }
  }

  // Get Classes (Public - for signup)
  // Query Parameters: studentLevel (optional), board (optional)
  static Future<Map<String, dynamic>> getClasses({
    String? studentLevel,
    String? board,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (studentLevel != null && studentLevel.isNotEmpty) {
        queryParams['studentLevel'] = studentLevel;
      }
      if (board != null && board.isNotEmpty) {
        queryParams['board'] = board;
      }
      
      final uri = Uri.parse('$baseUrl/api/classes').replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      
      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );
      
      final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
      
      if (response.statusCode == 200) {
        return responseBody;
      } else {
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Failed to load classes',
          'data': [],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'data': [],
      };
    }
  }

  // Get All Streams (Public - for Intermediate signup)
  // Query Parameters: classNumber (optional) - Filter by class number (11 or 12)
  static Future<Map<String, dynamic>> getStreams({int? classNumber}) async {
    try {
      final queryParams = <String, String>{};
      if (classNumber != null) {
        queryParams['classNumber'] = classNumber.toString();
      }
      
      final uri = Uri.parse('$baseUrl/api/streams').replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      
      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );
      
      final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
      
      if (response.statusCode == 200) {
        return responseBody;
      } else {
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Failed to load streams',
          'data': {'streams': []},
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'data': {'streams': []},
      };
    }
  }

  // Get All Degrees (Public - for Senior signup)
  // Query Parameters: degreeType (optional) - Filter by degree type
  static Future<Map<String, dynamic>> getDegrees({String? degreeType}) async {
    try {
      final queryParams = <String, String>{};
      if (degreeType != null && degreeType.isNotEmpty) {
        queryParams['degreeType'] = degreeType;
      }
      
      final uri = Uri.parse('$baseUrl/api/degrees').replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      
      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );
      
      final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
      
      if (response.statusCode == 200) {
        return responseBody;
      } else {
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Failed to load degrees',
          'data': {'degrees': []},
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'data': {'degrees': []},
      };
    }
  }

  // Get Student Classes (Protected)
  static Future<Map<String, dynamic>> getStudentClasses(String token) async {
    try {
      final uri = Uri.parse('$baseUrl/api/students/classes');
      
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
      
      if (response.statusCode == 200) {
        return responseBody;
      } else if (response.statusCode == 400) {
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Student level not set. Please update your profile.',
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Unauthorized. Please login again.',
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Student not found',
        };
      } else {
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Failed to load classes',
          'data': {'classes': []},
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'data': {'classes': []},
      };
    }
  }

  // Get Competitive Exam Syllabus
  static Future<Map<String, dynamic>> getCompetitiveExamSyllabus(String examId) async {
    try {
      final uri = Uri.parse('$baseUrl/api/competitive-exams/$examId/syllabus');
      
      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );
      
      final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
      
      if (response.statusCode == 200) {
        return responseBody;
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Syllabus not found for this exam',
        };
      } else {
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Failed to load syllabus',
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
  // Supports all parameters: name, contactNumber, studentLevel, board/boardId, class/classId, addresses, profileImage
  static Future<Map<String, dynamic>> updateProfile({
    required String token,
    String? name,
    String? contactNumber,
    String? studentLevel,
    String? boardId,
    String? board, // Alias for boardId
    String? classId,
    String? classParam, // Alias for classId (using classParam to avoid keyword conflict)
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
        
        if (name != null && name.isNotEmpty) request.fields['name'] = name;
        if (contactNumber != null && contactNumber.isNotEmpty) request.fields['contactNumber'] = contactNumber;
        if (studentLevel != null && studentLevel.isNotEmpty) request.fields['studentLevel'] = studentLevel;
        
        // Handle board (boardId or board alias)
        final boardValue = boardId ?? board;
        if (boardValue != null && boardValue.isNotEmpty) {
          request.fields['board'] = boardValue;
        }
        
        // Handle class (classId or classParam alias)
        // Can be set to empty string or null to remove class assignment
        final classValue = classId ?? classParam;
        // Always include class field - empty string removes class, value sets it
        request.fields['class'] = classValue ?? '';
        
        if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
          request.fields['profileImage'] = profileImageUrl;
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
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            if (name != null && name.isNotEmpty) 'name': name,
            if (contactNumber != null && contactNumber.isNotEmpty) 'contactNumber': contactNumber,
            if (studentLevel != null && studentLevel.isNotEmpty) 'studentLevel': studentLevel,
            // Handle board (boardId or board alias)
            if ((boardId ?? board) != null && (boardId ?? board)!.isNotEmpty) 'board': (boardId ?? board),
            // Handle class (classId or classParam alias) - always include, empty string removes class
            'class': (classId ?? classParam) ?? '',
            if (profileImageUrl != null && profileImageUrl.isNotEmpty) 'profileImage': profileImageUrl,
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

  // Get My Subjects (Protected)
  // Method: GET
  // URL: /api/students/my-subjects
  // Authentication required - Bearer token in Authorization header
  static Future<Map<String, dynamic>> getMySubjects(String token) async {
    try {
      final uri = Uri.parse('$baseUrl/api/students/my-subjects');
      
      print('=== API Service: getMySubjects ===');
      print('URL: $uri');
      print('Method: GET');
      print('Headers: Authorization: Bearer ${token.substring(0, token.length > 20 ? 20 : token.length)}...');
      
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      
      final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
      
      if (response.statusCode == 200) {
        return responseBody;
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Unauthorized. Please login again.',
        };
      } else if (response.statusCode == 400) {
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Student class or board not set. Please update your profile.',
        };
      } else {
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Failed to load subjects',
          'data': {'subjects': []},
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'data': {'subjects': []},
      };
    }
  }

  // Get Chapters by Subject ID (Public)
  // Method: GET
  // URL: /api/subjects/:subjectId/chapters
  // No authentication required
  static Future<Map<String, dynamic>> getChaptersBySubjectId(String subjectId) async {
    try {
      final uri = Uri.parse('$baseUrl/api/subjects/$subjectId/chapters');
      
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      );
      
      final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
      
      if (response.statusCode == 200) {
        return responseBody;
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Subject not found',
        };
      } else if (response.statusCode == 400) {
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Invalid subject ID',
        };
      } else {
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Failed to load chapters',
          'data': {'chapters': []},
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'data': {'chapters': []},
      };
    }
  }

  // AI Chat API
  // Method: POST
  // URL: https://api.a0.dev/ai/llm
  static Future<Map<String, dynamic>> sendAIChatMessage(List<Map<String, String>> messages) async {
    try {
      final uri = Uri.parse('https://api.a0.dev/ai/llm');
      
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'messages': messages,
        }),
      );
      
      final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'completion': responseBody['completion'] as String? ?? '',
        };
      } else {
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Failed to get AI response',
          'completion': '',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'completion': '',
      };
    }
  }

  // Get Available Subscription Plans (Protected)
  // Method: GET
  // URL: /api/student/subscription/plans?planType=monthly
  // Authentication required - Bearer token in Authorization header
  static Future<Map<String, dynamic>> getSubscriptionPlans(String token, {String planType = 'monthly'}) async {
    try {
      final uri = Uri.parse('$baseUrl/api/student/subscription/plans').replace(
        queryParameters: {'planType': planType},
      );
      
      print('=== API Service: getSubscriptionPlans ===');
      print('URL: $uri');
      print('Method: GET');
      print('Plan Type: $planType');
      print('Headers: Authorization: Bearer ${token.substring(0, token.length > 20 ? 20 : token.length)}...');
      
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      
      final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
      
      if (response.statusCode == 200) {
        return responseBody;
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Unauthorized. Please login again.',
        };
      } else {
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Failed to load subscription plans',
          'data': {'plans': []},
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'data': {'plans': []},
      };
    }
  }

  // Create Razorpay Order (Protected)
  // Method: POST
  // URL: /api/student/subscription/create-order
  // Authentication required - Bearer token in Authorization header
  static Future<Map<String, dynamic>> createSubscriptionOrder(
    String token, {
    required String planId,
    String? couponCode,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/student/subscription/create-order');
      
      print('=== API Service: createSubscriptionOrder ===');
      print('URL: $uri');
      print('Method: POST');
      print('Plan ID: $planId');
      print('Coupon Code: ${couponCode ?? 'None'}');
      
      final requestBody = <String, dynamic>{
        'planId': planId,
      };
      
      if (couponCode != null && couponCode.isNotEmpty) {
        requestBody['couponCode'] = couponCode;
      }
      
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );
      
      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      
      final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return responseBody;
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Unauthorized. Please login again.',
        };
      } else {
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Failed to create order',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Verify Payment and Complete Subscription (Protected)
  // Method: POST
  // URL: /api/student/subscription/verify-payment
  // Authentication required - Bearer token in Authorization header
  // NOTE: razorpaySignature can be empty if Razorpay Flutter SDK doesn't provide it
  static Future<Map<String, dynamic>> verifyPayment(
    String token, {
    required String razorpayOrderId,
    required String razorpayPaymentId,
    String? razorpaySignature, // Made optional since Flutter SDK may not provide it
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/student/subscription/verify-payment');
      
      print('=== API Service: verifyPayment ===');
      print('URL: $uri');
      print('Method: POST');
      print('Order ID: $razorpayOrderId');
      print('Payment ID: $razorpayPaymentId');
      print('Signature: ${razorpaySignature == null || razorpaySignature.isEmpty ? "MISSING (Backend should verify using order_id and payment_id)" : "${razorpaySignature.length > 20 ? "${razorpaySignature.substring(0, 20)}..." : razorpaySignature}"}');
      
      // Note: Razorpay Flutter SDK doesn't provide signature in PaymentSuccessResponse
      // Backend should verify payment using order_id and payment_id when signature is missing
      // IMPORTANT: Backend validation needs to be updated to make razorpaySignature optional
      final requestBody = <String, dynamic>{
        'razorpayOrderId': razorpayOrderId,
        'razorpayPaymentId': razorpayPaymentId,
        // Always include signature field - send null if not provided (JSON null, not empty string)
        // Backend should handle null by verifying via Razorpay API
        'razorpaySignature': razorpaySignature, // Can be null - will be encoded as JSON null
      };
      
      // If signature is null, backend should verify using Razorpay API with order_id and payment_id
      // NOTE: Backend validation currently requires non-empty signature - needs to be updated to:
      // 1. Allow null/empty values in validation
      // 2. Verify payment using Razorpay API when signature is missing
      
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );
      
      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      
      final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return responseBody;
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Unauthorized. Please login again.',
        };
      } else {
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Payment verification failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Check Active Subscription (Protected)
  // Method: GET
  // URL: /api/student/subscription/active
  // Authentication required - Bearer token in Authorization header
  static Future<Map<String, dynamic>> getActiveSubscription(String token) async {
    try {
      final uri = Uri.parse('$baseUrl/api/student/subscription/active');
      
      print('=== API Service: getActiveSubscription ===');
      print('URL: $uri');
      print('Method: GET');
      
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      
      final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
      
      if (response.statusCode == 200) {
        return responseBody;
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Unauthorized. Please login again.',
        };
      } else {
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Failed to check subscription',
          'data': {'hasActiveSubscription': false},
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'data': {'hasActiveSubscription': false},
      };
    }
  }
}

