import 'package:flutter/material.dart';
import 'package:hushmate/core/config/app_config.dart';
import 'package:hushmate/domain/repositories/auth_repository.dart';
import 'package:hushmate/domain/entities/user.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_svg/flutter_svg.dart';

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

  Widget _buildProfileImage() {
    if (_user!.profilePic == null || _user!.profilePic!.isEmpty) {
      print('No profile picture URL available');
      return const Icon(Icons.person, size: 50);
    }

    final imageUrl = _user!.profilePic!;
    print('Loading profile image from URL: $imageUrl');
    
    if (imageUrl.toLowerCase().contains('dicebear') || imageUrl.toLowerCase().endsWith('.svg')) {
      print('Loading SVG image');
      return SvgPicture.network(
        imageUrl,
        fit: BoxFit.cover,
        placeholderBuilder: (context) => const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    } else {
      print('Loading regular image');
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('Error loading image: $error');
          return const Icon(Icons.person, size: 50);
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          print('Loading progress: ${loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : 'unknown'}');
          return const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : _user == null
                  ? const Center(child: Text('No profile data available'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(AppConfig.defaultPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.pink[100],
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(50),
                              child: _buildProfileImage(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _user!.name ?? '',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _user!.email,
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'About Me',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(_user!.bio ?? 'No bio available'),
                          const SizedBox(height: 24),
                          const Text(
                            'Interests',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: (_user!.interests ?? []).map((interest) => Chip(
                              label: Text(interest),
                              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                            )).toList(),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Seeking',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: (_user!.objectives ?? [])
                                .map((objective) => Chip(
                                      label: Text(objective),
                                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                                    ))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
    );
  }
} 