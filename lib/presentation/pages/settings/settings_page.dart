import 'package:flutter/material.dart';
import 'package:hushmate/core/config/app_config.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppConfig.defaultPadding),
        children: [
          _buildSection(
            context,
            title: 'Account',
            items: [
              _SettingsItem(
                icon: Icons.person,
                title: 'Edit Profile',
                onTap: () {
                  // TODO: Navigate to edit profile
                },
              ),
              _SettingsItem(
                icon: Icons.notifications,
                title: 'Notifications',
                onTap: () {
                  // TODO: Navigate to notifications settings
                },
              ),
              _SettingsItem(
                icon: Icons.privacy_tip,
                title: 'Privacy',
                onTap: () {
                  // TODO: Navigate to privacy settings
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            title: 'Preferences',
            items: [
              _SettingsItem(
                icon: Icons.location_on,
                title: 'Location',
                onTap: () {
                  // TODO: Navigate to location settings
                },
              ),
              _SettingsItem(
                icon: Icons.language,
                title: 'Language',
                onTap: () {
                  // TODO: Navigate to language settings
                },
              ),
              _SettingsItem(
                icon: Icons.dark_mode,
                title: 'Theme',
                onTap: () {
                  // TODO: Navigate to theme settings
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            title: 'Support',
            items: [
              _SettingsItem(
                icon: Icons.help,
                title: 'Help Center',
                onTap: () {
                  // TODO: Navigate to help center
                },
              ),
              _SettingsItem(
                icon: Icons.info,
                title: 'About',
                onTap: () {
                  // TODO: Navigate to about page
                },
              ),
              _SettingsItem(
                icon: Icons.logout,
                title: 'Logout',
                onTap: () {
                  // TODO: Implement logout
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: items,
          ),
        ),
      ],
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