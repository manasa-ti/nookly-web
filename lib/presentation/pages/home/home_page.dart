import 'package:flutter/material.dart';
import 'package:hushmate/presentation/pages/home/recommended_profiles_page.dart';
import 'package:hushmate/presentation/pages/home/received_likes_page.dart';
import 'package:hushmate/presentation/pages/home/chat_inbox_page.dart';
import 'package:hushmate/presentation/pages/home/purchased_features_page.dart';
import 'package:hushmate/presentation/pages/profile/profile_page.dart';
import 'package:hushmate/presentation/pages/settings/settings_page.dart';
import 'package:hushmate/presentation/pages/notifications/notifications_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const RecommendedProfilesPage(),
    const ReceivedLikesPage(),
    const ChatInboxPage(),
    const PurchasedFeaturesPage(),
  ];

  void _onProfilePressed() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProfilePage(),
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

  void _onSettingsPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SettingsPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HushMate'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: _onProfilePressed,
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: _onNotificationsPressed,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _onSettingsPressed,
          ),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Discover',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            selectedIcon: Icon(Icons.favorite),
            label: 'Likes',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_outlined),
            selectedIcon: Icon(Icons.chat),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.star_outline),
            selectedIcon: Icon(Icons.star),
            label: 'Features',
          ),
        ],
      ),
    );
  }
} 