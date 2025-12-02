import 'dart:convert';
import 'package:http/http.dart' as http;

class PostalService {
  static const String baseUrl = 'https://api.postalpincode.in';
  
  // Get Post Office details by PIN Code
  static Future<Map<String, dynamic>> getDetailsByPincode(String pincode) async {
    try {
      if (pincode.isEmpty || pincode.length != 6) {
        return {
          'success': false,
          'message': 'Please enter a valid 6-digit pincode',
        };
      }

      final uri = Uri.parse('$baseUrl/pincode/$pincode');
      
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        
        if (data.isNotEmpty && data[0]['Status'] == 'Success') {
          final postOffices = data[0]['PostOffice'] as List<dynamic>?;
          
          if (postOffices != null && postOffices.isNotEmpty) {
            // Get the first post office details
            final firstOffice = postOffices[0] as Map<String, dynamic>;
            
            return {
              'success': true,
              'message': data[0]['Message'] ?? 'Success',
              'data': {
                'district': firstOffice['District'] ?? '',
                'state': firstOffice['State'] ?? '',
                'city': firstOffice['District'] ?? '', // Usually district is the city
                'circle': firstOffice['Circle'] ?? '',
                'division': firstOffice['Division'] ?? '',
                'region': firstOffice['Region'] ?? '',
                'country': firstOffice['Country'] ?? 'India',
                'postOffices': postOffices.map((po) => {
                  'name': po['Name'] ?? '',
                  'branchType': po['BranchType'] ?? '',
                  'deliveryStatus': po['DeliveryStatus'] ?? '',
                }).toList(),
              },
            };
          } else {
            return {
              'success': false,
              'message': 'No post office found for this pincode',
            };
          }
        } else {
          return {
            'success': false,
            'message': data.isNotEmpty ? (data[0]['Message'] ?? 'Error') : 'Invalid pincode',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch pincode details',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }
  
  // Get Post Office details by Post Office name
  static Future<Map<String, dynamic>> getDetailsByPostOfficeName(String postOfficeName) async {
    try {
      if (postOfficeName.isEmpty) {
        return {
          'success': false,
          'message': 'Please enter a post office name',
        };
      }

      final uri = Uri.parse('$baseUrl/postoffice/$postOfficeName');
      
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        
        if (data.isNotEmpty && data[0]['Status'] == 'Success') {
          final postOffices = data[0]['PostOffice'] as List<dynamic>?;
          
          if (postOffices != null && postOffices.isNotEmpty) {
            return {
              'success': true,
              'message': data[0]['Message'] ?? 'Success',
              'data': {
                'postOffices': postOffices.map((po) => {
                  'name': po['Name'] ?? '',
                  'pincode': po['PINCode'] ?? '',
                  'district': po['District'] ?? '',
                  'state': po['State'] ?? '',
                  'branchType': po['BranchType'] ?? '',
                  'deliveryStatus': po['DeliveryStatus'] ?? '',
                  'circle': po['Circle'] ?? '',
                  'division': po['Division'] ?? '',
                  'region': po['Region'] ?? '',
                  'country': po['Country'] ?? 'India',
                }).toList(),
              },
            };
          } else {
            return {
              'success': false,
              'message': 'No post office found',
            };
          }
        } else {
          return {
            'success': false,
            'message': data.isNotEmpty ? (data[0]['Message'] ?? 'Error') : 'Invalid post office name',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch post office details',
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

