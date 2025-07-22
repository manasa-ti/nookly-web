import 'package:flutter/material.dart';
import 'package:nookly/presentation/widgets/custom_avatar.dart';
import 'package:get_it/get_it.dart';
import 'package:nookly/domain/entities/user.dart';
import 'package:nookly/domain/repositories/auth_repository.dart';
import 'package:nookly/presentation/pages/profile/edit_profile_page.dart';
import 'package:nookly/presentation/pages/auth/login_page.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ProfileHubPage extends StatefulWidget {
  const ProfileHubPage({super.key});

  @override
  State<ProfileHubPage> createState() => _ProfileHubPageState();
}

class _ProfileHubPageState extends State<ProfileHubPage> {
  final _authRepository = GetIt.instance<AuthRepository>();
  User? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() => _isLoading = true);
    final user = await _authRepository.getCurrentUser();
    setState(() {
      _user = user;
      _isLoading = false;
    });
  }



  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF234481),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Profile Info
                  Center(
                    child: Column(
                      children: [
                        CustomAvatar(
                          name: _user?.name,
                          size: 60,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _user?.name ?? '',
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _user?.email ?? '',
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
                          onPressed: () async {
                            if (_user == null) return;
                            final updated = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditProfilePage(user: _user!),
                              ),
                            );
                            if (updated == true) {
                              _loadUser();
                            }
                          },
                          child: const Text('Edit Profile', style: TextStyle(fontFamily: 'Nunito', color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Purchased Features Section (Placeholder)
                  Card(
                    color: const Color(0xFF35548b),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Premium Features', style: TextStyle(fontFamily: 'Nunito', fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                          SizedBox(height: 12),
                          Text('Your purchased features will appear here.', style: TextStyle(fontFamily: 'Nunito', color: Color(0xFFD6D9E6))),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Notifications Section
                  Card(
                    color: const Color(0xFF35548b),
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
                    color: const Color(0xFF35548b),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Column(
                      children: [
                        _SettingsTile(icon: Icons.privacy_tip, title: 'Privacy', onTap: () {}),
                        _SettingsTile(icon: Icons.help, title: 'Help & Support', onTap: () {}),
                        _SettingsTile(icon: Icons.info, title: 'About', onTap: () {}),
                        _SettingsTile(
                          icon: Icons.logout,
                          title: 'Logout',
                          onTap: () async {
                            await _authRepository.logout();
                            if (mounted) {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (context) => const LoginPage()),
                                (route) => false,
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SettingsTile({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(fontFamily: 'Nunito', color: Colors.white)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white),
      onTap: onTap,
    );
  }
} 