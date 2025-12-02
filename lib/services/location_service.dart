import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  // Check if location services are enabled
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Check location permission status
  static Future<PermissionStatus> checkLocationPermission() async {
    return await Permission.location.status;
  }

  // Request location permission
  static Future<PermissionStatus> requestLocationPermission() async {
    // Check if location services are enabled
    bool serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      return PermissionStatus.denied;
    }

    // Check permission status
    PermissionStatus status = await Permission.location.status;
    
    if (status.isDenied) {
      // Request permission
      status = await Permission.location.request();
    }
    
    return status;
  }

  // Get current location
  static Future<Map<String, dynamic>?> getCurrentLocation() async {
    try {
      // Check if location services are enabled first
      bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        return {
          'success': false,
          'message': 'Location services are disabled. Please enable location services in your device settings.',
        };
      }

      // Request permission
      PermissionStatus permission = await requestLocationPermission();
      
      if (permission.isPermanentlyDenied) {
        return {
          'success': false,
          'message': 'Location permission is permanently denied. Please enable it in app settings.',
          'openSettings': true,
        };
      }
      
      if (!permission.isGranted) {
        return {
          'success': false,
          'message': 'Location permission denied. Please allow location access to continue.',
        };
      }

      // Try to get last known location first (faster, especially for emulator)
      try {
        Position? lastKnownPosition = await Geolocator.getLastKnownPosition();
        if (lastKnownPosition != null) {
          // For emulator or if last known is recent (within 30 minutes), use it
          final now = DateTime.now();
          final positionTime = lastKnownPosition.timestamp;
          final difference = now.difference(positionTime);
          
          // Use last known if it's within 30 minutes (more lenient for emulator)
          if (difference.inMinutes < 30) {
            return {
              'success': true,
              'latitude': lastKnownPosition.latitude,
              'longitude': lastKnownPosition.longitude,
              'accuracy': lastKnownPosition.accuracy,
              'altitude': lastKnownPosition.altitude,
            };
          }
        }
      } catch (e) {
        // Continue to get current position if last known fails
      }

      // Try to get current position with different accuracy levels
      Position? position;
      
      // First try with high accuracy
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        ).timeout(
          const Duration(seconds: 12),
          onTimeout: () {
            throw TimeoutException('High accuracy timeout');
          },
        );
      } catch (e) {
        // If high accuracy fails, try with medium accuracy
        try {
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 10),
          ).timeout(
            const Duration(seconds: 12),
            onTimeout: () {
              throw TimeoutException('Medium accuracy timeout');
            },
          );
        } catch (e2) {
          // If medium fails, try with low accuracy (works better on emulator)
          try {
            position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.low,
              timeLimit: const Duration(seconds: 10),
            ).timeout(
              const Duration(seconds: 12),
              onTimeout: () {
                throw TimeoutException('Low accuracy timeout');
              },
            );
          } catch (e3) {
            // If all fail, try with best available (works on emulator)
            position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.lowest,
              timeLimit: const Duration(seconds: 15),
            ).timeout(
              const Duration(seconds: 18),
              onTimeout: () {
                throw TimeoutException('Location request timed out. Please check your GPS signal and try again.');
              },
            );
          }
        }
      }

      if (position == null) {
        throw Exception('Failed to get position');
      }

      return {
        'success': true,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'altitude': position.altitude,
      };
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Location request timed out. Please check your GPS signal and try again.',
      };
    } catch (e) {
      String errorMessage = 'Failed to get location';
      if (e.toString().contains('permission')) {
        errorMessage = 'Location permission is required. Please enable it in settings.';
      } else if (e.toString().contains('timeout') || e.toString().contains('timed out')) {
        errorMessage = 'Location request timed out. Please check your GPS signal and try again.';
      } else if (e.toString().contains('disabled')) {
        errorMessage = 'Location services are disabled. Please enable location services.';
      } else {
        errorMessage = 'Failed to get location: ${e.toString()}';
      }
      
      return {
        'success': false,
        'message': errorMessage,
      };
    }
  }

  // Get last known location (faster, but may be outdated)
  static Future<Map<String, dynamic>?> getLastKnownLocation() async {
    try {
      Position? position = await Geolocator.getLastKnownPosition();
      
      if (position == null) {
        return {
          'success': false,
          'message': 'No last known location available',
        };
      }

      return {
        'success': true,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'altitude': position.altitude,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to get last known location: ${e.toString()}',
      };
    }
  }
}


