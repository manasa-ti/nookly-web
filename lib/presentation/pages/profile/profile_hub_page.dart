import 'package:flutter/material.dart';
import 'package:nookly/domain/repositories/auth_repository.dart';
import 'package:nookly/domain/entities/user.dart';
import 'package:get_it/get_it.dart';
import 'package:nookly/presentation/widgets/custom_avatar.dart';
import 'package:nookly/presentation/pages/settings/settings_page.dart';
import 'package:nookly/presentation/pages/notifications/notifications_page.dart';

class ProfileHubPage extends StatefulWidget {
  const ProfileHubPage({super.key});

  @override
  State<ProfileHubPage> createState() => _ProfileHubPageState();
}

class _ProfileHubPageState extends State<ProfileHubPage> {
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

  void _onSettingsPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SettingsPage(),
      ),
    );
  }

  void _onNotificationsPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationsPage(),
      ),
    );
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
                ? Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.white)))
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
                                    color: const Color(0xFFD6D9E6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Quick Actions
                          Card(
                            color: const Color(0xFF3A4A7A),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Column(
                              children: [
                                _buildSettingsTile(Icons.notifications, 'Notifications', _onNotificationsPressed, size),
                                const Divider(color: Color(0xFF4C5C8A), height: 1),
                                _buildSettingsTile(Icons.settings, 'Settings', _onSettingsPressed, size),
                              ],
                            ),
                          ),
                        ],
                      ),
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, VoidCallback onTap, Size size) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title, 
                style: TextStyle(
                  fontFamily: 'Nunito', 
                  fontSize: (size.width * 0.04).clamp(13.0, 16.0), 
                  color: Colors.white, 
                  fontWeight: FontWeight.w500
                )
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}

