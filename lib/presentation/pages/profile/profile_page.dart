import 'package:flutter/material.dart';
import 'package:nookly/core/config/app_config.dart';
import 'package:nookly/domain/repositories/auth_repository.dart';
import 'package:nookly/domain/entities/user.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nookly/presentation/widgets/custom_avatar.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _authRepository = GetIt.instance<AuthRepository>();
  bool _isLoading = true;
  String? _error;
  User? _user;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final user = await _authRepository.getCurrentUser();
      
      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Container(
      color: const Color(0xFF232B5D),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text('Error: $_error', style: TextStyle(color: Colors.white)))
                : _user == null
                    ? const Center(child: Text('No profile data available', style: TextStyle(color: Colors.white)))
                    : ListView(
                        padding: const EdgeInsets.all(12),
                        children: [
                          // Profile Info
                          Center(
                            child: Column(
                              children: [
                                CustomAvatar(
                                  name: _user!.name,
                                  size: 60,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _user!.name ?? '',
                                  style: TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: (size.width * 0.05).clamp(16.0, 20.0),
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _user!.email,
                                  style: TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: (size.width * 0.035).clamp(12.0, 15.0),
                                    color: Color(0xFFD6D9E6),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4C5C8A),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  onPressed: () {
                                    // Navigate to edit profile
                                  },
                                  child: Text('Edit Profile', style: TextStyle(fontFamily: 'Nunito', color: Colors.white, fontSize: (size.width * 0.035).clamp(12.0, 15.0), fontWeight: FontWeight.w500)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Purchased Features Section
                          Card(
                            color: const Color(0xFF3A4A7A),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Premium Features', style: TextStyle(fontFamily: 'Nunito', fontSize: (size.width * 0.045).clamp(14.0, 18.0), fontWeight: FontWeight.w500, color: Colors.white)),
                                  const SizedBox(height: 8),
                                  _buildFeatureTile('See Who Likes You', 'Find out who has liked your profile before you match', Icons.favorite, true, size),
                                  _buildFeatureTile('Unlimited Likes', 'No daily limit on the number of profiles you can like', Icons.all_inclusive, true, size),
                                  _buildFeatureTile('Advanced Filters', 'Filter by education, height, and more', Icons.filter_list, false, size),
                                  _buildFeatureTile('Read Receipts', 'See when your messages are read', Icons.done_all, false, size),
                                  _buildFeatureTile('Priority Likes', 'Get seen by more people with priority placement', Icons.star, false, size),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Notifications Section
                          Card(
                            color: const Color(0xFF3A4A7A),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              leading: const Icon(Icons.notifications, color: Colors.white, size: 20),
                              title: Text('Notifications', style: TextStyle(fontFamily: 'Nunito', fontSize: (size.width * 0.04).clamp(13.0, 16.0), color: Colors.white, fontWeight: FontWeight.w500)),
                              trailing: const Icon(Icons.chevron_right, color: Colors.white, size: 20),
                              onTap: () {
                                // Navigate to notifications page
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Settings Section
                          Card(
                            color: const Color(0xFF3A4A7A),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Column(
                              children: [
                                _buildSettingsTile(Icons.privacy_tip, 'Privacy', () {}, size),
                                _buildSettingsTile(Icons.help, 'Help & Support', () {}, size),
                                _buildSettingsTile(Icons.info, 'About', () {}, size),
                                _buildSettingsTile(Icons.logout, 'Logout', () {}, size),
                              ],
                            ),
                          ),
                        ],
                      ),
      ),
    );
  }

  Widget _buildFeatureTile(String title, String description, IconData icon, bool isActive, Size size) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF4C5C8A) : Colors.grey.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: isActive ? Colors.white : Colors.grey, size: 18),
      ),
      title: Text(title, style: TextStyle(fontFamily: 'Nunito', fontSize: (size.width * 0.04).clamp(13.0, 16.0), color: Colors.white, fontWeight: FontWeight.w500)),
      subtitle: Text(description, style: TextStyle(fontFamily: 'Nunito', fontSize: (size.width * 0.032).clamp(11.0, 14.0), color: Color(0xFFD6D9E6))),
      trailing: isActive ? Chip(label: Text('Active', style: TextStyle(color: Colors.white, fontFamily: 'Nunito', fontSize: (size.width * 0.03).clamp(10.0, 13.0))), backgroundColor: Color(0xFF4C5C8A)) : null,
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, VoidCallback onTap, Size size) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      leading: Icon(icon, color: Colors.white, size: 20),
      title: Text(title, style: TextStyle(fontFamily: 'Nunito', fontSize: (size.width * 0.04).clamp(13.0, 16.0), color: Colors.white, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white, size: 20),
      onTap: onTap,
    );
  }
} 