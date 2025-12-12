import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://7cvccltb-3023.inc1.devtunnels.ms';
  
  // Get Level Categories (Public - for signup)
  static Future<Map<String, dynamic>> getLevelCategories() async {
    try {
      final uri = Uri.parse('$baseUrl/api/level-categories');
      
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
          'message': responseBody['message'] ?? 'Failed to load level categories',
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

  // Student Signup
  static Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String password,
    required String levelCategory,
    required String contactNumber,
    String? agentId,
    String? subcategory,
    int? ui,
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
        request.fields['levelCategory'] = levelCategory;
        request.fields['levelCategoryId'] = levelCategory; // Alias for levelCategory
        request.fields['contactNumber'] = contactNumber;
        
        if (agentId != null && agentId.isNotEmpty) {
          request.fields['agentId'] = agentId;
        }
        
        if (subcategory != null && subcategory.isNotEmpty) {
          request.fields['subcategory'] = subcategory;
          request.fields['subcategoryId'] = subcategory; // Alias for subcategory
        }
        
        if (ui != null) {
          request.fields['ui'] = ui.toString();
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
        final requestBody = <String, dynamic>{
          'name': name,
          'email': email,
          'password': password,
          'levelCategory': levelCategory,
          'levelCategoryId': levelCategory, // Alias for levelCategory
          'contactNumber': contactNumber,
          if (agentId != null && agentId.isNotEmpty) 'agentId': agentId,
          if (subcategory != null && subcategory.isNotEmpty) 'subcategory': subcategory,
          if (subcategory != null && subcategory.isNotEmpty) 'subcategoryId': subcategory, // Alias
          if (ui != null) 'ui': ui,
          if (addresses != null && addresses.isNotEmpty) 'addresses': addresses,
        };
        
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
      
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      
      // Include status code in response for error handling
      responseData['statusCode'] = response.statusCode;
      
      return responseData;
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'statusCode': 0,
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
  // URL: /api/students/my-subjects-list
  // Authentication required - Bearer token in Authorization header
  // Query Parameters: page, limit, isActive, subcategoryId, boardId
  static Future<Map<String, dynamic>> getMySubjects(
    String token, {
    int? page,
    int? limit,
    bool? isActive,
    String? subcategoryId,
    String? boardId,
  }) async {
    try {
      // Build query parameters
      final queryParams = <String, String>{};
      if (page != null) queryParams['page'] = page.toString();
      if (limit != null) queryParams['limit'] = limit.toString();
      if (isActive != null) queryParams['isActive'] = isActive.toString();
      if (subcategoryId != null) queryParams['subcategoryId'] = subcategoryId;
      if (boardId != null) queryParams['boardId'] = boardId;

      final uri = Uri.parse('$baseUrl/api/students/my-subjects-list')
          .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
      
      print('=== API Service: getMySubjects ===');
      print('URL: $uri');
      print('Method: GET');
      print('Query Parameters: $queryParams');
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
          'data': {
            'items': [],
            'student': null,
            'pagination': {
              'page': 1,
              'limit': 20,
              'total': 0,
              'pages': 0,
            },
          },
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'data': {
          'items': [],
          'student': null,
          'pagination': {
            'page': 1,
            'limit': 20,
            'total': 0,
            'pages': 0,
          },
        },
      };
    }
  }

  // Get Subject Full Data by ID (Protected - Token Based)
  // Method: GET
  // URL: /api/students/subjects/:subjectId
  // Authentication required - Bearer token in Authorization header
  // Returns complete subject information including all chapters, syllabi, and completion status
  static Future<Map<String, dynamic>> getSubjectById(String token, String subjectId) async {
    try {
      final uri = Uri.parse('$baseUrl/api/students/subjects/$subjectId');
      
      print('=== API Service: getSubjectById ===');
      print('URL: $uri');
      print('Method: GET');
      print('Subject ID: $subjectId');
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
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Subject not found',
        };
      } else {
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Failed to load subject',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
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

  // Enroll in Course (Protected)
  // Method: POST
  // URL: /api/student/courses/{courseId}/enroll
  // Authentication required - Bearer token in Authorization header
  static Future<Map<String, dynamic>> enrollInCourse(
    String token,
    String courseId,
  ) async {
    try {
      final uri = Uri.parse('$baseUrl/api/student/courses/$courseId/enroll');
      
      print('=== API Service: enrollInCourse ===');
      print('URL: $uri');
      print('Method: POST');
      print('Course ID: $courseId');
      
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
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
      } else if (response.statusCode == 400 || response.statusCode == 403) {
        // Handle subscription requirement
        final requiresSubscription = responseBody['requiresSubscription'] as bool? ?? false;
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Invalid request. You may already be enrolled.',
          'requiresSubscription': requiresSubscription,
          'details': responseBody['details'] as String?,
        };
      } else {
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Failed to enroll in course',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get Courses with Filters (Protected)
  // Method: GET
  // URL: /api/student/courses/filters
  // Authentication required - Bearer token in Authorization header
  // Query Parameters: page, limit, sort, level (junior/intermediate/senior)
  static Future<Map<String, dynamic>> getCoursesWithFilters(
    String token, {
    int page = 1,
    int limit = 12,
    String sort = 'rating',
    String? level,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        'sort': sort,
      };
      
      if (level != null && level.isNotEmpty) {
        queryParams['level'] = level;
      }
      
      final uri = Uri.parse('$baseUrl/api/student/courses/filters').replace(
        queryParameters: queryParams,
      );
      
      print('=== API Service: getCoursesWithFilters ===');
      print('URL: $uri');
      print('Method: GET');
      print('Level filter: $level');
      
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
          'data': {'items': [], 'pagination': {}},
        };
      } else {
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Failed to load courses',
          'data': {'items': [], 'pagination': {}},
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'data': {'items': [], 'pagination': {}},
      };
    }
  }

  // Get Courses with Progress (Protected)
  // Method: GET
  // URL: /api/student/courses/with-progress
  // Authentication required - Bearer token in Authorization header
  // Query Parameters: page, limit
  static Future<Map<String, dynamic>> getCoursesWithProgress(
    String token, {
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/student/courses/with-progress').replace(
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
        },
      );
      
      print('=== API Service: getCoursesWithProgress ===');
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
          'data': {'items': [], 'pagination': {}},
        };
      } else {
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Failed to load courses',
          'data': {'items': [], 'pagination': {}},
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'data': {'items': [], 'pagination': {}},
      };
    }
  }

  // Get Course Details (Protected)
  // Method: GET
  // URL: /api/student/courses/{courseId}
  // Authentication required - Bearer token in Authorization header
  static Future<Map<String, dynamic>> getCourseDetails(
    String token,
    String courseId,
  ) async {
    try {
      final uri = Uri.parse('$baseUrl/api/student/courses/$courseId');
      
      print('=== API Service: getCourseDetails ===');
      print('URL: $uri');
      print('Method: GET');
      print('Course ID: $courseId');
      
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
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Course not found',
        };
      } else {
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Failed to load course details',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get Course Progress (Protected)
  // Method: GET
  // URL: /api/student/courses/{courseId}/progress
  // Authentication required - Bearer token in Authorization header
  static Future<Map<String, dynamic>> getCourseProgress(
    String token,
    String courseId,
  ) async {
    try {
      final uri = Uri.parse('$baseUrl/api/student/courses/$courseId/progress');
      
      print('=== API Service: getCourseProgress ===');
      print('URL: $uri');
      print('Method: GET');
      print('Course ID: $courseId');
      
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
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Course progress not found',
        };
      } else {
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Failed to load course progress',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Mark Lesson as Complete (Protected)
  // Method: POST
  // URL: /api/student/courses/{courseId}/progress
  // Authentication required - Bearer token in Authorization header
  // Body: { "lessonId": "...", "completed": true }
  static Future<Map<String, dynamic>> markLessonComplete(
    String token,
    String courseId,
    String lessonId,
    bool completed,
  ) async {
    try {
      final uri = Uri.parse('$baseUrl/api/student/courses/$courseId/progress');
      
      print('=== API Service: markLessonComplete ===');
      print('URL: $uri');
      print('Method: POST');
      print('Course ID: $courseId');
      print('Lesson ID: $lessonId');
      print('Completed: $completed');
      
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'lessonId': lessonId,
          'completed': completed,
        }),
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
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Course or lesson not found',
        };
      } else {
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Failed to mark lesson as complete',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get Dashboard Data (Protected)
  // Method: GET
  // URL: /api/student/courses/dashboard
  // Authentication required - Bearer token in Authorization header
  static Future<Map<String, dynamic>> getDashboard(String token) async {
    try {
      final uri = Uri.parse('$baseUrl/api/student/courses/dashboard');
      
      print('=== API Service: getDashboard ===');
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
          'message': responseBody['message'] ?? 'Failed to load dashboard data',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }
}

