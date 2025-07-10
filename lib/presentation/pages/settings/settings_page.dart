import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nookly/core/config/app_config.dart';
import 'package:nookly/core/utils/logger.dart';
import 'package:nookly/presentation/bloc/auth/auth_bloc.dart';
import 'package:nookly/presentation/bloc/auth/auth_event.dart';
import 'package:nookly/presentation/bloc/auth/auth_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nookly/domain/repositories/auth_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:nookly/presentation/pages/profile/edit_profile_page.dart';
import 'package:nookly/presentation/pages/auth/login_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          _SettingsItem(
            icon: Icons.edit,
            title: 'Edit Profile',
            onTap: () async {
              final authRepository = GetIt.instance<AuthRepository>();
              final user = await authRepository.getCurrentUser();
              if (user != null && context.mounted) {
                AppLogger.debug("User in Settings : $user.toString()");
                final updated = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProfilePage(user: user),
                  ),
                );
                if (updated == true && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile updated successfully')),
                  );
                }
              }
            },
          ),
          _SettingsItem(
            icon: Icons.notifications,
            title: 'Notifications',
            onTap: () {
              // TODO: Implement notifications settings
            },
          ),
          _SettingsItem(
            icon: Icons.privacy_tip,
            title: 'Privacy',
            onTap: () {
              // TODO: Implement privacy settings
            },
          ),
          _SettingsItem(
            icon: Icons.help,
            title: 'Help & Support',
            onTap: () {
              // TODO: Implement help & support
            },
          ),
          _SettingsItem(
            icon: Icons.info,
            title: 'About',
            onTap: () {
              // TODO: Implement about page
            },
          ),
          _SettingsItem(
            icon: Icons.logout,
            title: 'Logout',
            onTap: () async {
              final authRepository = GetIt.instance<AuthRepository>();
              await authRepository.logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginPage(),
                  ),
                  (route) => false, // Remove all previous routes
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
} 