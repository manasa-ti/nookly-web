import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:nookly/core/utils/logger.dart';
import 'package:nookly/domain/entities/user.dart';
import 'package:nookly/domain/repositories/auth_repository.dart';
import 'package:nookly/presentation/pages/auth/login_page.dart';
import 'package:nookly/presentation/pages/profile/edit_profile_page.dart';
import 'package:nookly/data/models/auth/delete_account_request_model.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _authRepository = GetIt.instance<AuthRepository>();
  User? _user;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final user = await _authRepository.getCurrentUser();
      setState(() {
        _user = user;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _logout() async {
    await _authRepository.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Future<void> _confirmDeleteAccount() async {
    final formKey = GlobalKey<FormState>();
    final confirmationController = TextEditingController();
    final passwordController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Type DELETE to confirm. This action is irreversible.',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmationController,
                decoration: const InputDecoration(labelText: 'Confirmation'),
                validator: (v) => v == 'DELETE' ? null : 'Please type DELETE',
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Password (if required)'),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _authRepository.deleteAccount(DeleteAccountRequestModel(
          confirmation: confirmationController.text,
          password: passwordController.text.isEmpty ? null : passwordController.text,
        ));
        if (!mounted) return;
        await _logout();
      } catch (e, st) {
        AppLogger.error('Delete account failed: $e', e, st);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete account: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : ListView(
                  children: [
                    if (_user != null)
                      ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(_user!.name ?? ''),
                        subtitle: Text(_user!.email),
                      ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.edit),
                      title: const Text('Edit Profile'),
                      onTap: () async {
                        if (_user == null) return;
                        final updated = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(builder: (_) => EditProfilePage(user: _user!)),
                        );
                        if (updated == true) _load();
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.privacy_tip),
                      title: const Text('Privacy Policy'),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => const AlertDialog(
                            title: Text('Privacy Policy'),
                            content: Text('Privacy policy content will appear here.'),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.delete_forever, color: Colors.red),
                      title: const Text('Delete Account'),
                      onTap: _confirmDeleteAccount,
                    ),
                    ListTile(
                      leading: const Icon(Icons.logout),
                      title: const Text('Logout'),
                      onTap: _logout,
                    ),
                  ],
                ),
    );
  }
}


