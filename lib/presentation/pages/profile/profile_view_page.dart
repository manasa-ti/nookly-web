import 'package:flutter/material.dart';
import 'package:nookly/core/theme/app_colors.dart';
import 'package:nookly/domain/entities/user.dart';
import 'package:nookly/domain/repositories/auth_repository.dart';
import 'package:nookly/presentation/widgets/custom_avatar.dart';
import 'package:nookly/core/utils/logger.dart';
import 'package:get_it/get_it.dart';
import 'package:nookly/core/services/screen_protection_service.dart';
import 'package:nookly/core/services/analytics_service.dart';
import 'package:nookly/core/di/injection_container.dart';
import 'dart:math';

class ProfileViewPage extends StatefulWidget {
  final String userId;

  const ProfileViewPage({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<ProfileViewPage> createState() => _ProfileViewPageState();
}

class _ProfileViewPageState extends State<ProfileViewPage> {
  final AuthRepository _authRepository = GetIt.instance<AuthRepository>();
  User? _user;
  User? _currentUser;
  bool _isLoading = true;
  String? _error;
  late ScreenProtectionService _screenProtectionService;

  @override
  void initState() {
    super.initState();
    _screenProtectionService = sl<ScreenProtectionService>();
    // Enable screenshot protection for profile pages
    _enableScreenProtection();
    _loadUserProfile();
  }

  /// Enable screenshot and screen recording protection for profile pages
  Future<void> _enableScreenProtection() async {
    if (!mounted) return;
    
    try {
      await _screenProtectionService.enableProtection(
        screenType: 'profile',
        context: context,
      );
      AppLogger.info('🔒 Screen protection enabled for profile view');
    } catch (e) {
      AppLogger.error('Failed to enable screen protection', e);
    }
  }

  /// Disable screenshot protection
  Future<void> _disableScreenProtection() async {
    try {
      await _screenProtectionService.disableProtection();
      AppLogger.info('🔓 Screen protection disabled');
    } catch (e) {
      AppLogger.error('Failed to disable screen protection', e);
    }
  }

  @override
  void dispose() {
    _disableScreenProtection();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      AppLogger.info('🔵 Loading profile for user: ${widget.userId}');
      
      // Load both the profile user and current user for distance calculation
      final futures = await Future.wait([
        _authRepository.getUserProfile(widget.userId),
        _authRepository.getCurrentUser(),
      ]);
      
      final user = futures[0];
      final currentUser = futures[1];
      
      if (mounted) {
        setState(() {
          _user = user;
          _currentUser = currentUser;
          _isLoading = false;
        });
        AppLogger.info('✅ Profile loaded successfully for user: ${user?.name}');
        
        // Track profile viewed (only for other users' profiles, not own)
        if (user != null && currentUser != null && user.id != currentUser.id) {
          sl<AnalyticsService>().logProfileViewed();
        }
      }
    } catch (e) {
      AppLogger.error('❌ Failed to load profile: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  /// Calculate distance between two coordinates using Haversine formula
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);
    
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  /// Get formatted distance string
  String _getDistanceString() {
    if (_user?.location == null || _currentUser?.location == null) {
      AppLogger.warning('Location data unavailable for distance calculation');
      return 'Distance unavailable';
    }

    try {
      AppLogger.info('User location data: ${_user!.location}');
      AppLogger.info('Current user location data: ${_currentUser!.location}');
      
      // Handle two different location data structures:
      // 1. Map with 'coordinates' key: {'coordinates': [lon, lat]}
      // 2. Map with 'latitude' and 'longitude' keys: {'latitude': lat, 'longitude': lon}
      
      double? userLat;
      double? userLon;
      double? currentLat;
      double? currentLon;
      
      // Parse user location
      if (_user!.location!.containsKey('coordinates')) {
        final userCoords = _user!.location!['coordinates'];
        if (userCoords != null && userCoords is List && userCoords.length >= 2) {
          userLon = (userCoords[0] as num).toDouble(); // longitude
          userLat = (userCoords[1] as num).toDouble(); // latitude
        }
      } else if (_user!.location!.containsKey('latitude') && _user!.location!.containsKey('longitude')) {
        userLat = (_user!.location!['latitude'] as num).toDouble();
        userLon = (_user!.location!['longitude'] as num).toDouble();
      }
      
      // Parse current user location
      if (_currentUser!.location!.containsKey('coordinates')) {
        final currentUserCoords = _currentUser!.location!['coordinates'];
        if (currentUserCoords != null && currentUserCoords is List && currentUserCoords.length >= 2) {
          currentLon = (currentUserCoords[0] as num).toDouble(); // longitude
          currentLat = (currentUserCoords[1] as num).toDouble(); // latitude
        }
      } else if (_currentUser!.location!.containsKey('latitude') && _currentUser!.location!.containsKey('longitude')) {
        currentLat = (_currentUser!.location!['latitude'] as num).toDouble();
        currentLon = (_currentUser!.location!['longitude'] as num).toDouble();
      }
      
      if (userLat == null || userLon == null || currentLat == null || currentLon == null) {
        AppLogger.warning('Invalid coordinate data: userLat=$userLat, userLon=$userLon, currentLat=$currentLat, currentLon=$currentLon');
        return 'Distance unavailable';
      }

      final distance = _calculateDistance(currentLat, currentLon, userLat, userLon);
      AppLogger.info('Calculated distance: ${distance}km');
      
      if (distance < 1) {
        return '${(distance * 1000).round()}m away';
      } else {
        return '${distance.toStringAsFixed(1)}km away';
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error calculating distance: $e');
      AppLogger.error('Stack trace: $stackTrace');
      return 'Distance unavailable';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1d335f),
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF1d335f),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white)
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load profile',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                fontFamily: 'Nunito',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontFamily: 'Nunito',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadUserProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1d335f),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_user == null) {
      return const Center(
        child: Text(
          'Profile not found',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            fontFamily: 'Nunito',
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 24),
          _buildAboutSection(),
          const SizedBox(height: 24),
          _buildInterestsSection(),
          const SizedBox(height: 24),
          _buildObjectivesSection(),
          const SizedBox(height: 24),
          _buildPersonalitySection(),
          const SizedBox(height: 24),
          _buildLifestyleSection(),
          const SizedBox(height: 24),
          _buildLocationSection(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF3A4A7A),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile Picture
          CustomAvatar(
            name: _user!.name,
            size: 100,
            isOnline: _user!.isOnline ?? false,
            imageUrl: _user!.profilePic,
          ),
          const SizedBox(height: 16),
          
          // Name and Age
          Text(
            _user!.name ?? 'Unknown',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Nunito',
            ),
          ),
          if (_user!.age != null) ...[
            const SizedBox(height: 4),
            Text(
              '${_user!.age} years old',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontFamily: 'Nunito',
              ),
            ),
          ],
          
          const SizedBox(height: 12),
          
          // Online Status
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: (_user!.isOnline ?? false) ? Colors.green : Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                (_user!.isOnline ?? false) ? 'Online' : 'Offline',
                style: TextStyle(
                  color: (_user!.isOnline ?? false) ? Colors.green : Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Nunito',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    if (_user!.bio == null || _user!.bio!.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildSection(
      title: 'About',
      child: Text(
        _user!.bio!,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          height: 1.5,
          fontFamily: 'Nunito',
        ),
      ),
    );
  }

  Widget _buildInterestsSection() {
    if (_user!.interests == null || _user!.interests!.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildSection(
      title: 'Interests',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _user!.interests!.map((interest) => _buildChip(interest)).toList(),
      ),
    );
  }

  Widget _buildObjectivesSection() {
    if (_user!.objectives == null || _user!.objectives!.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildSection(
      title: 'Objectives',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _user!.objectives!.map((objective) => _buildChip(objective)).toList(),
      ),
    );
  }

  Widget _buildPersonalitySection() {
    if (_user!.personalityType == null || _user!.personalityType!.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildSection(
      title: 'Personality',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _user!.personalityType!.map((type) => _buildChip(type)).toList(),
      ),
    );
  }

  Widget _buildLifestyleSection() {
    final hasPhysicalActiveness = _user!.physicalActiveness != null && _user!.physicalActiveness!.isNotEmpty;
    final hasAvailability = _user!.availability != null && _user!.availability!.isNotEmpty;
    
    if (!hasPhysicalActiveness && !hasAvailability) {
      return const SizedBox.shrink();
    }

    return _buildSection(
      title: 'Lifestyle',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasPhysicalActiveness) ...[
            const Text(
              'Physical Activity:',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Nunito',
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _user!.physicalActiveness!.map((activity) => _buildChip(activity)).toList(),
            ),
          ],
          if (hasPhysicalActiveness && hasAvailability) const SizedBox(height: 16),
          if (hasAvailability) ...[
            const Text(
              'Availability:',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Nunito',
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _user!.availability!.map((availability) => _buildChip(availability)).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    final hasHometown = _user!.hometown != null && _user!.hometown!.isNotEmpty;
    final hasLocation = _user!.location != null;
    
    if (!hasHometown && !hasLocation) {
      return const SizedBox.shrink();
    }

    return _buildSection(
      title: 'Location',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasHometown) ...[
            Row(
              children: [
                const Icon(
                  Icons.location_city,
                  color: Colors.white70,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  _user!.hometown!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'Nunito',
                  ),
                ),
              ],
            ),
          ],
          if (hasHometown && hasLocation) const SizedBox(height: 8),
          if (hasLocation) ...[
            Row(
              children: [
                const Icon(
                  Icons.my_location,
                  color: Colors.white70,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  _getDistanceString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'Nunito',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF3A4A7A),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Nunito',
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      margin: const EdgeInsets.only(right: 6, bottom: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1d335f),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF8FA3C8),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFD6D9E6),
          fontSize: 13,
          fontWeight: FontWeight.w500,
          fontFamily: 'Nunito',
        ),
      ),
    );
  }
}
