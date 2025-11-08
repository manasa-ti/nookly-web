import 'package:geolocator/geolocator.dart';
import 'package:nookly/core/utils/logger.dart';
import 'package:nookly/domain/entities/user.dart';
import 'package:nookly/domain/repositories/auth_repository.dart';

class LocationService {
  final AuthRepository _authRepository;
  
  LocationService(this._authRepository);

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      AppLogger.error('Error checking location service status: $e');
      return false;
    }
  }

  /// Check current location permission status
  Future<LocationPermission> checkLocationPermission() async {
    try {
      return await Geolocator.checkPermission();
    } catch (e) {
      AppLogger.error('Error checking location permission: $e');
      return LocationPermission.denied;
    }
  }

  /// Request location permission
  Future<LocationPermission> requestLocationPermission() async {
    try {
      AppLogger.info('Requesting location permission...');
      
      // Check if location services are enabled
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        AppLogger.warning('Location services are disabled');
        return LocationPermission.denied;
      }

      // Check current permission status
      LocationPermission permission = await checkLocationPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          AppLogger.warning('Location permission denied by user');
          return LocationPermission.denied;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        AppLogger.warning('Location permission permanently denied');
        return LocationPermission.deniedForever;
      }

      AppLogger.info('Location permission granted');
      return permission;
    } catch (e) {
      AppLogger.error('Error requesting location permission: $e');
      return LocationPermission.denied;
    }
  }

  /// Get current location
  Future<Position?> getCurrentLocation() async {
    try {
      AppLogger.info('Getting current location...');
      
      // Check permission first
      final permission = await checkLocationPermission();
      if (permission == LocationPermission.denied || 
          permission == LocationPermission.deniedForever) {
        AppLogger.warning('Location permission not granted');
        return null;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      AppLogger.info('Current location: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      AppLogger.error('Error getting current location: $e');
      return null;
    }
  }

  /// Update user location on server
  Future<void> updateUserLocationOnServer(Position position) async {
    try {
      AppLogger.info('Updating user location on server...');

      final currentUser = await _authRepository.getCurrentUser();
      if (currentUser == null) {
        AppLogger.warning('Cannot update location: current user not available');
        return;
      }

      final updatedUser = User(
        id: currentUser.id,
        email: currentUser.email,
        name: currentUser.name,
        age: currentUser.age,
        sex: currentUser.sex,
        seekingGender: currentUser.seekingGender,
        location: {
          'coordinates': [position.longitude, position.latitude],
        },
        preferredAgeRange: currentUser.preferredAgeRange,
        hometown: currentUser.hometown,
        bio: currentUser.bio,
        interests: currentUser.interests,
        objectives: currentUser.objectives,
        personalityType: currentUser.personalityType,
        physicalActiveness: currentUser.physicalActiveness,
        availability: currentUser.availability,
        profilePic: currentUser.profilePic,
        preferredDistanceRadius: currentUser.preferredDistanceRadius,
        isOnline: currentUser.isOnline,
        lastSeen: currentUser.lastSeen,
        connectionStatus: currentUser.connectionStatus,
        lastActive: currentUser.lastActive,
      );

      await _authRepository.updateUserProfile(updatedUser);
      AppLogger.info('User location updated successfully on server');
    } catch (e) {
      AppLogger.error('Error updating user location on server: $e');
      // Silent failure - don't throw, just log
    }
  }

  /// Get location and update on server (for app launch)
  Future<void> updateLocationOnAppLaunch() async {
    try {
      AppLogger.info('📍 Updating location on app launch...');
      
      // First check permission status
      LocationPermission permission = await checkLocationPermission();
      AppLogger.info('📍 Location permission status: $permission');

      if (permission == LocationPermission.denied) {
        AppLogger.info('📍 Permission currently denied, requesting permission...');
        permission = await requestLocationPermission();
        AppLogger.info('📍 Permission status after request: $permission');
      }

      if (permission != LocationPermission.always && permission != LocationPermission.whileInUse) {
        AppLogger.warning('⚠️ Location permission not granted (status: $permission)');
        return;
      }
      
      // Check if location services are enabled
      final serviceEnabled = await isLocationServiceEnabled();
      AppLogger.info('📍 Location services enabled: $serviceEnabled');
      
      if (!serviceEnabled) {
        AppLogger.warning('⚠️ Location services are disabled on device');
        return;
      }
      
      final position = await getCurrentLocation();
      if (position != null) {
        AppLogger.info('📍 Got location: ${position.latitude}, ${position.longitude}');
        await updateUserLocationOnServer(position);
        AppLogger.info('✅ Location updated successfully on server');
      } else {
        AppLogger.warning('⚠️ Could not get location - permission: $permission, serviceEnabled: $serviceEnabled');
      }
    } catch (e) {
      AppLogger.error('❌ Error updating location on app launch: $e');
      // Silent failure - don't throw, just log
    }
  }

  /// Get location for profile creation (with permission check)
  Future<Position?> getLocationForProfileCreation() async {
    try {
      AppLogger.info('Getting location for profile creation...');
      
      // Request permission first
      final permission = await requestLocationPermission();
      if (permission != LocationPermission.whileInUse && 
          permission != LocationPermission.always) {
        AppLogger.warning('Location permission not granted for profile creation');
        return null;
      }

      // Get current location
      return await getCurrentLocation();
    } catch (e) {
      AppLogger.error('Error getting location for profile creation: $e');
      return null;
    }
  }
}
