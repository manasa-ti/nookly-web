import 'package:flutter/material.dart';
import 'package:nookly/presentation/pages/home/recommended_profiles_page.dart';
import 'package:nookly/presentation/pages/home/received_likes_page.dart';
import 'package:nookly/presentation/pages/home/chat_inbox_page.dart';
import 'package:nookly/presentation/pages/home/purchased_features_page.dart';
import 'package:nookly/presentation/pages/profile/profile_page.dart';
import 'package:nookly/presentation/pages/profile/profile_filters_page.dart';
import 'package:nookly/presentation/pages/settings/settings_page.dart';
import 'package:nookly/presentation/pages/notifications/notifications_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nookly/presentation/bloc/recommended_profiles/recommended_profiles_bloc.dart';

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

  void _onFiltersPressed() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProfileFiltersPage(),
      ),
    );
    
    // If filters were updated, refresh the recommended profiles
    if (result == true && _currentIndex == 0) {
      // Refresh the recommended profiles
      // We need to access the bloc from the current page
      final recommendedProfilesBloc = context.read<RecommendedProfilesBloc>();
      recommendedProfilesBloc.add(LoadRecommendedProfiles());
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Prevent back navigation from home screen
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false, // Remove back button
          title: const Text('Nookly'),
          actions: [
            // Filter icon - only show on Discover tab
            if (_currentIndex == 0)
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _onFiltersPressed,
              ),
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
      ),
    );
  }
} 