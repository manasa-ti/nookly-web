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
import 'package:nookly/presentation/pages/profile/profile_hub_page.dart';
import 'package:nookly/presentation/widgets/svg_icons.dart';
import 'dart:ui';

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
    const ProfileHubPage(),
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
      print('🔵 DEBUG: Filters updated, refreshing recommended profiles');
      final recommendedProfilesBloc = context.read<RecommendedProfilesBloc>();
      recommendedProfilesBloc.add(LoadRecommendedProfiles());
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Allow app to exit when back button is pressed on home screen
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF234481),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: SafeArea(
            top: true, // Exclude status bar from colored background
            bottom: false,
            child: Container(
              color: const Color(0xFF35548b).withOpacity(0.7), // Match bottom nav bar color and opacity
              child: SizedBox(
                height: 100,
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 18),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'nookly',
                              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                    fontFamily: 'Nunito',
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1.2,
                                    fontSize: 28,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Never be lonely',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 14,
                                color: Color(0xFFD6D9E6),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_currentIndex == 0)
                      Positioned(
                        top: 18,
                        right: 12,
                        child: IconButton(
                          icon: const Icon(Icons.filter_list, color: Colors.white, size: 32),
                          onPressed: _onFiltersPressed,
                          tooltip: 'Filters',
                          iconSize: 32,
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: _pages[_currentIndex],
        bottomNavigationBar: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF35548b).withOpacity(0.7),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 16,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: NavigationBar(
                  backgroundColor: Colors.transparent,
                  height: 72,
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  indicatorColor: const Color(0xFF516b99),
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                destinations: [
                  NavigationDestination(
                    icon: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: SvgIcons.discoverIcon(size: 42),
                    ),
                    selectedIcon: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: SvgIcons.discoverIcon(size: 42),
                    ),
                    label: 'Discover',
                  ),
                  NavigationDestination(
                    icon: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: SvgIcons.likesIcon(size: 42),
                    ),
                    selectedIcon: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: SvgIcons.likesIcon(size: 42),
                    ),
                    label: 'Likes',
                  ),
                  NavigationDestination(
                    icon: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: SvgIcons.chatsIcon(size: 42),
                    ),
                    selectedIcon: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: SvgIcons.chatsIcon(size: 42),
                    ),
                    label: 'Chat',
                  ),
                  NavigationDestination(
                    icon: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: SvgIcons.profileIcon(size: 42),
                    ),
                    selectedIcon: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: SvgIcons.profileIcon(size: 42),
                    ),
                    label: 'Profile',
                  ),
                ],
                labelTextStyle: const MaterialStatePropertyAll(
                  TextStyle(
                    fontFamily: 'Nunito',
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    height: 1.2,
                  ),
                ),
              ),
            ),
            ),
          ),
        ),
      ),
    );
  }
} 