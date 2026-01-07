import 'package:nookly/core/utils/logger.dart';
import 'package:nookly/domain/entities/user.dart';
import 'package:nookly/core/utils/platform_utils.dart';

/// Manages and caches super properties for all analytics events
/// Super properties are automatically included with every event
class AnalyticsSuperProperties {
  String? _platform;
  String? _location; // City name
  String? _gender; // m/f/any
  String? _userId;

  /// Get platform (android/ios)
  String? get platform => _platform;

  /// Get location (city name)
  String? get location => _location;

  /// Get gender (m/f/any)
  String? get gender => _gender;

  /// Get user ID
  String? get userId => _userId;

  /// Get all super properties as a map
  Map<String, Object> get allProperties {
    final properties = <String, Object>{};
    
    if (_platform != null) {
      properties['platform'] = _platform!;
    }
    if (_location != null) {
      properties['location'] = _location!;
    }
    if (_gender != null) {
      properties['gender'] = _gender!;
    }
    if (_userId != null) {
      properties['user_id'] = _userId!;
    }
    
    return properties;
  }

  /// Initialize platform (called once on app start)
  void initializePlatform() {
    if (_platform != null) return; // Already initialized
    
    try {
      _platform = PlatformUtils.platformName;
      AppLogger.info('Analytics super property - Platform: $_platform');
    } catch (e) {
      AppLogger.error('Failed to initialize platform', e);
      _platform = 'unknown';
    }
  }

  /// Update location (city name) from user's coordinates
  /// Uses cached value if available to minimize processing time
  Future<void> updateLocationFromUser(User? user) async {
    if (user?.location == null) {
      _location = null;
      return;
    }

    try {
      // Extract coordinates from user location
      double? latitude;
      double? longitude;

      if (user!.location!.containsKey('coordinates')) {
        final coords = user.location!['coordinates'];
        if (coords is List && coords.length >= 2) {
          // Format: [longitude, latitude]
          longitude = (coords[0] as num).toDouble();
          latitude = (coords[1] as num).toDouble();
        }
      } else if (user.location!.containsKey('latitude') && user.location!.containsKey('longitude')) {
        latitude = (user.location!['latitude'] as num).toDouble();
        longitude = (user.location!['longitude'] as num).toDouble();
      }

      if (latitude == null || longitude == null) {
        AppLogger.warning('Could not extract coordinates from user location');
        return;
      }

      // Use hometown for city name (minimal effort - no geocoding needed)
      if (user.hometown != null && user.hometown!.isNotEmpty) {
        _location = user.hometown;
        AppLogger.info('Analytics super property - Location: $_location');
      } else {
        // If hometown not available, location will remain null
        AppLogger.info('Analytics super property - Location: null (hometown not set)');
      }
    } catch (e) {
      AppLogger.error('Failed to update location from user', e);
    }
  }

  /// Update gender from user's sex field
  /// Maps: m -> 'm', f -> 'f', null/empty -> 'any'
  void updateGenderFromUser(User? user) {
    if (user?.sex == null || user!.sex!.isEmpty) {
      _gender = 'any';
    } else {
      final sex = user.sex!.toLowerCase();
      if (sex == 'm' || sex == 'male') {
        _gender = 'm';
      } else if (sex == 'f' || sex == 'female') {
        _gender = 'f';
      } else {
        _gender = 'any';
      }
    }
    AppLogger.info('Analytics super property - Gender: $_gender');
  }

  /// Update user ID
  void updateUserId(User? user) {
    _userId = user?.id;
    AppLogger.info('Analytics super property - User ID: $_userId');
  }

  /// Update all properties from user
  Future<void> updateFromUser(User? user) async {
    updateUserId(user);
    updateGenderFromUser(user);
    await updateLocationFromUser(user);
  }

  /// Clear all properties (on logout)
  void clear() {
    _platform = null;
    _location = null;
    _gender = null;
    _userId = null;
    AppLogger.info('Analytics super properties cleared');
  }
}

