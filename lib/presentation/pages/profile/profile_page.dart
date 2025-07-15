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
                        padding: const EdgeInsets.all(20),
                        children: [
                          // Profile Info
                          Center(
                            child: Column(
                              children: [
                                CustomAvatar(
                                  name: _user!.name,
                                  size: 100,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _user!.name ?? '',
                                  style: const TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _user!.email,
                                  style: const TextStyle(
                                    fontFamily: 'Nunito',
                                    color: Color(0xFFD6D9E6),
                                  ),
                                ),
                                const SizedBox(height: 8),
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
                                  child: const Text('Edit Profile', style: TextStyle(fontFamily: 'Nunito', color: Colors.white)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          // Purchased Features Section
                          Card(
                            color: const Color(0xFF3A4A7A),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Premium Features', style: TextStyle(fontFamily: 'Nunito', fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                                  const SizedBox(height: 12),
                                  _buildFeatureTile('See Who Likes You', 'Find out who has liked your profile before you match', Icons.favorite, true),
                                  _buildFeatureTile('Unlimited Likes', 'No daily limit on the number of profiles you can like', Icons.all_inclusive, true),
                                  _buildFeatureTile('Advanced Filters', 'Filter by education, height, and more', Icons.filter_list, false),
                                  _buildFeatureTile('Read Receipts', 'See when your messages are read', Icons.done_all, false),
                                  _buildFeatureTile('Priority Likes', 'Get seen by more people with priority placement', Icons.star, false),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          // Notifications Section
                          Card(
                            color: const Color(0xFF3A4A7A),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            child: ListTile(
                              leading: const Icon(Icons.notifications, color: Colors.white),
                              title: const Text('Notifications', style: TextStyle(fontFamily: 'Nunito', color: Colors.white, fontWeight: FontWeight.bold)),
                              trailing: const Icon(Icons.chevron_right, color: Colors.white),
                              onTap: () {
                                // Navigate to notifications page
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Settings Section
                          Card(
                            color: const Color(0xFF3A4A7A),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            child: Column(
                              children: [
                                _buildSettingsTile(Icons.privacy_tip, 'Privacy', () {}),
                                _buildSettingsTile(Icons.help, 'Help & Support', () {}),
                                _buildSettingsTile(Icons.info, 'About', () {}),
                                _buildSettingsTile(Icons.logout, 'Logout', () {}),
                              ],
                            ),
                          ),
                        ],
                      ),
      ),
    );
  }

  Widget _buildFeatureTile(String title, String description, IconData icon, bool isActive) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF4C5C8A) : Colors.grey.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: isActive ? Colors.white : Colors.grey, size: 24),
      ),
      title: Text(title, style: const TextStyle(fontFamily: 'Nunito', color: Colors.white, fontWeight: FontWeight.bold)),
      subtitle: Text(description, style: const TextStyle(fontFamily: 'Nunito', color: Color(0xFFD6D9E6))),
      trailing: isActive ? const Chip(label: Text('Active', style: TextStyle(color: Colors.white, fontFamily: 'Nunito')), backgroundColor: Color(0xFF4C5C8A)) : null,
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(fontFamily: 'Nunito', color: Colors.white)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white),
      onTap: onTap,
    );
  }
} 