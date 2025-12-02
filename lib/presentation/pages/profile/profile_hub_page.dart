import 'package:flutter/material.dart';
import 'package:nookly/presentation/widgets/custom_avatar.dart';
import 'package:get_it/get_it.dart';
import 'package:nookly/domain/entities/user.dart';
import 'package:nookly/domain/repositories/auth_repository.dart';
import 'package:nookly/presentation/pages/profile/edit_profile_page.dart';
import 'package:nookly/presentation/pages/profile/profile_creation_page.dart';
import 'package:nookly/presentation/pages/auth/login_page.dart';
import 'package:nookly/data/models/auth/delete_account_request_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:nookly/core/services/screen_protection_service.dart';
import 'package:nookly/core/di/injection_container.dart';
import 'package:nookly/core/utils/logger.dart';
import 'package:nookly/core/theme/app_text_styles.dart';
import 'package:nookly/core/theme/app_colors.dart';

class ProfileHubPage extends StatefulWidget {
  const ProfileHubPage({super.key});

  @override
  State<ProfileHubPage> createState() => _ProfileHubPageState();
}

class _ProfileHubPageState extends State<ProfileHubPage> {
  final _authRepository = GetIt.instance<AuthRepository>();
  User? _user;
  bool _isLoading = true;
  late ScreenProtectionService _screenProtectionService;

  @override
  void initState() {
    super.initState();
    _screenProtectionService = sl<ScreenProtectionService>();
    // Enable screenshot protection for profile pages
    _enableScreenProtection();
    _loadUser();
  }

  /// Enable screenshot and screen recording protection for profile pages
  Future<void> _enableScreenProtection() async {
    if (!mounted) return;
    
    try {
      await _screenProtectionService.enableProtection(
        screenType: 'profile',
        context: context,
      );
      AppLogger.info('🔒 Screen protection enabled for profile hub');
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

  Future<String> _getAppVersion() async {
    try {
      // Lazy import to avoid needing to initialize earlier
      // ignore: avoid_print
      print('🔵 Loading app version');
      final info = await PackageInfo.fromPlatform();
      return '${info.version}+${info.buildNumber}';
    } catch (_) {
      return '';
    }
  }

  Future<void> _loadUser() async {
    setState(() => _isLoading = true);
    try {
      final user = await _authRepository.getCurrentUser();
      print('🔵 ProfileHub: Loaded user: ${user?.name} | ${user?.email}');
      print('🔵 ProfileHub: User object: $user');
      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (e) {
      print('🔵 ProfileHub: Error loading user: $e');
      setState(() {
        _user = null;
        _isLoading = false;
      });
    }
  }

  Future<void> _openPrivacyPolicy() async {
    print('🔵 Privacy button tapped!'); // Debug log
    
    // Show immediate feedback that button was tapped
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Opening privacy policy...'),
          duration: Duration(seconds: 2),
        ),
      );
    }
    
    const url = 'https://privacy-policy.nookly.app/';
    try {
      print('🔵 Attempting to open URL: $url'); // Debug log
      final uri = Uri.parse(url);
      print('🔵 Parsed URI: $uri'); // Debug log
      
      final canLaunch = await canLaunchUrl(uri);
      print('🔵 Can launch URL: $canLaunch'); // Debug log
      
      if (canLaunch) {
        print('🔵 Launching URL...'); // Debug log
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        print('🔵 URL launched successfully'); // Debug log
      } else {
        print('🔵 Cannot launch URL'); // Debug log
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open privacy policy'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('🔵 Error opening privacy policy: $e'); // Debug log
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening privacy policy: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openTermsOfUse() async {
    const url = 'https://terms-of-use.nookly.app/';
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open terms of use'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening terms of use: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1d335f),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'About Nookly',
            style: TextStyle(
              color: AppColors.white85,
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w600,
              fontSize: AppTextStyles.getDialogTitleFontSize(context),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FutureBuilder<String>(
                  future: _getAppVersion(),
                  builder: (context, snapshot) {
                    final text = snapshot.data != null && snapshot.data!.isNotEmpty
                        ? 'Version ${snapshot.data!}'
                        : 'Version';
                    return Text(
                      text,
                      style: TextStyle(
                        color: Colors.white70,
                        fontFamily: 'Nunito',
                        fontSize: AppTextStyles.getSubtitleFontSize(context),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Nookly is a comprehensive dating application designed to help you find meaningful connections.',
                  style: TextStyle(
                    color: AppColors.white85,
                    fontFamily: 'Nunito',
                    fontSize: AppTextStyles.getBodyFontSize(context),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '© 2024 Nookly. All rights reserved.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontFamily: 'Nunito',
                    fontSize: AppTextStyles.getCaptionFontSize(context),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _openPrivacyPolicy();
                        },
                        child: Text(
                          'Privacy Policy',
                          style: TextStyle(
                            color: Colors.blue,
                            fontFamily: 'Nunito',
                            fontSize: AppTextStyles.getBodyFontSize(context),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _openTermsOfUse();
                        },
                        child: Text(
                          'Terms of Use',
                          style: TextStyle(
                            color: Colors.blue,
                            fontFamily: 'Nunito',
                            fontSize: AppTextStyles.getBodyFontSize(context),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: TextStyle(
                  color: AppColors.white85,
                  fontFamily: 'Nunito',
                  fontSize: AppTextStyles.getBodyFontSize(context),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAccountConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1d335f),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Delete Account',
            style: TextStyle(
              color: Colors.red,
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w600,
              fontSize: AppTextStyles.getDialogTitleFontSize(context),
            ),
          ),
          content: Text(
            'Are you sure you want to delete your account? This action cannot be undone and will permanently remove all your data.',
            style: TextStyle(
              color: AppColors.white85,
              fontFamily: 'Nunito',
              fontSize: AppTextStyles.getBodyFontSize(context),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey,
                  fontFamily: 'Nunito',
                  fontSize: AppTextStyles.getBodyFontSize(context),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showDeleteAccountPasswordDialog();
              },
              child: Text(
                'Yes, Delete',
                style: TextStyle(
                  color: Colors.red,
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w600,
                  fontSize: AppTextStyles.getBodyFontSize(context),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAccountPasswordDialog() {
    final passwordController = TextEditingController();
    final confirmationController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            bool isPasswordValid = passwordController.text.isNotEmpty;
            bool isConfirmationValid = confirmationController.text == 'DELETE';
            bool canSubmit = isPasswordValid && isConfirmationValid && !isLoading;

            return AlertDialog(
              backgroundColor: const Color(0xFF1d335f),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                'Confirm Account Deletion',
                style: TextStyle(
                  color: Colors.red,
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w600,
                  fontSize: AppTextStyles.getDialogTitleFontSize(context),
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'To confirm account deletion, please:',
                    style: TextStyle(
                      color: AppColors.white85,
                      fontFamily: 'Nunito',
                      fontSize: AppTextStyles.getBodyFontSize(context),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    style: TextStyle(color: AppColors.white85, fontSize: AppTextStyles.getBodyFontSize(context)),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: TextStyle(color: Colors.white70, fontSize: AppTextStyles.getLabelFontSize(context)),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white30),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red),
                      ),
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: confirmationController,
                    style: TextStyle(color: AppColors.white85, fontSize: AppTextStyles.getBodyFontSize(context)),
                    decoration: InputDecoration(
                      labelText: 'Type "DELETE" to confirm',
                      labelStyle: TextStyle(color: Colors.white70, fontSize: AppTextStyles.getLabelFontSize(context)),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white30),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red),
                      ),
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.grey,
                      fontFamily: 'Nunito',
                      fontSize: AppTextStyles.getBodyFontSize(context),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: canSubmit
                      ? () async {
                          setState(() => isLoading = true);
                          try {
                            final request = DeleteAccountRequestModel(
                              confirmation: 'DELETE',
                              password: passwordController.text,
                            );
                            
                            await _authRepository.deleteAccount(request);
                            
                            if (mounted) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Account deleted successfully'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (context) => const LoginPage()),
                                (route) => false,
                              );
                            }
                          } catch (e) {
                            setState(() => isLoading = false);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to delete account: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        }
                      : null,
                  child: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                          ),
                        )
                      : Text(
                          'Delete Account',
                          style: TextStyle(
                            color: Colors.red,
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w600,
                            fontSize: AppTextStyles.getBodyFontSize(context),
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Container(
      color: const Color(0xFF1d335f),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.white85)))
            : _user == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.white85, size: 48),
                        const SizedBox(height: 16),
                        const Text(
                          'Profile Setup Required',
                          style: TextStyle(color: AppColors.white85, fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Please complete your profile setup',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ProfileCreationPage(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4C5C8A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text(
                            'Complete Profile',
                            style: TextStyle(color: AppColors.white85, fontFamily: 'Nunito'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: _loadUser,
                          child: const Text(
                            'Retry Loading',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  )
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
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: (size.width * 0.05).clamp(16.0, 24.0),
                            fontWeight: FontWeight.w500,
                            color: AppColors.white85,
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
                          child: Text('Edit Profile', style: TextStyle(fontFamily: 'Nunito', color: AppColors.white85, fontSize: (size.width * 0.035).clamp(12.0, 15.0), fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                  ),
                  // TODO: Uncomment Premium Features section when implemented
                  // const SizedBox(height: 32),
                  // // Purchased Features Section (Placeholder)
                  // Card(
                  //   color: const Color(0xFF1d335f),
                  //   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  //   child: Padding(
                  //     padding: const EdgeInsets.all(16),
                  //     child: Column(
                  //       crossAxisAlignment: CrossAxisAlignment.start,
                  //       children: [
                  //         Text('Premium Features', style: TextStyle(fontFamily: 'Nunito', fontSize: (size.width * 0.045).clamp(14.0, 20.0), fontWeight: FontWeight.w500, color: Colors.white)),
                  //         const SizedBox(height: 12),
                  //         Text('Your purchased features will appear here.', style: const TextStyle(fontFamily: 'Nunito', color: Color(0xFFD6D9E6))),
                  //       ],
                  //     ),
                  //   ),
                  // ),
                  // TODO: Uncomment Notifications section when implemented
                  // const SizedBox(height: 32),
                  // // Notifications Section
                  // Card(
                  //   color: const Color(0xFF1d335f),
                  //   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  //   child: ListTile(
                  //     leading: const Icon(Icons.notifications, color: Colors.white),
                  //     title: Text('Notifications', style: TextStyle(fontFamily: 'Nunito', color: Colors.white, fontWeight: FontWeight.w500, fontSize: (size.width * 0.04).clamp(13.0, 16.0))),
                  //     trailing: const Icon(Icons.chevron_right, color: Colors.white),
                  //     onTap: () {
                  //       // Navigate to notifications page
                  //     },
                  //   ),
                  // ),
                  const SizedBox(height: 16),
                  // Settings Section
                  Card(
                    color: const Color(0xFF283d67),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Column(
                      children: [
                        _SettingsTile(icon: Icons.privacy_tip, title: 'Privacy', onTap: _openPrivacyPolicy),
                        // TODO: Uncomment when Help & Support page is implemented
                        // _SettingsTile(icon: Icons.help, title: 'Help & Support', onTap: () {}),
                        _SettingsTile(icon: Icons.info, title: 'About', onTap: _showAboutDialog),
                        _SettingsTile(
                          icon: Icons.delete_forever,
                          title: 'Delete Account',
                          onTap: _showDeleteAccountConfirmation,
                        ),
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
    final size = MediaQuery.of(context).size;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: AppColors.white85),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title, 
                style: TextStyle(
                  fontFamily: 'Nunito', 
                  color: AppColors.white85, 
                  fontWeight: FontWeight.w500, 
                  fontSize: (size.width * 0.04).clamp(13.0, 16.0)
                )
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.white85),
          ],
        ),
      ),
    );
  }
} 