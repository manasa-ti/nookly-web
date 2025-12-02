import 'package:nookly/core/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:nookly/presentation/pages/home/recommended_profiles_page.dart';
import 'package:nookly/presentation/pages/home/received_likes_page.dart';
import 'package:nookly/presentation/pages/home/chat_inbox_page.dart';
import 'package:nookly/presentation/pages/profile/profile_filters_page.dart';
import 'package:nookly/presentation/pages/settings/settings_page.dart';
import 'package:nookly/presentation/pages/notifications/notifications_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nookly/presentation/bloc/recommended_profiles/recommended_profiles_bloc.dart';
import 'package:nookly/presentation/pages/profile/profile_hub_page.dart';
import 'package:nookly/presentation/pages/profile/profile_page.dart';
import 'package:nookly/presentation/widgets/svg_icons.dart';
import 'package:nookly/core/services/filter_preferences_service.dart';
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

  // Helper method to determine if device is tablet
  bool _isTablet(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.width > 600; // Consider devices wider than 600dp as tablets
  }

  // Helper method to get adaptive sizing
  double _getAdaptiveSize(BuildContext context, double mobileSize, double tabletSize) {
    return _isTablet(context) ? tabletSize : mobileSize;
  }

  // Restore profile navigation helper for toolbar shortcuts/deeplinks
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
      // Refresh the recommended profiles with filter preferences
      AppLogger.info('🔵 DEBUG: Filters updated, refreshing recommended profiles');
      
      // Load filter preferences
      final physicalActivenessFilters = await FilterPreferencesService.getPhysicalActivenessFilters();
      final availabilityFilters = await FilterPreferencesService.getAvailabilityFilters();
      
      final recommendedProfilesBloc = context.read<RecommendedProfilesBloc>();
      recommendedProfilesBloc.add(LoadRecommendedProfiles(
        reset: true, // Force fresh load when filters are applied
        physicalActiveness: physicalActivenessFilters.isNotEmpty ? physicalActivenessFilters : null,
        availability: availabilityFilters.isNotEmpty ? availabilityFilters : null,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = _isTablet(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final safeArea = MediaQuery.of(context).padding;
    
    // Adaptive sizing for different screen sizes
    final appBarHeight = isTablet ? 80.0 : screenHeight * 0.12;
    final bottomNavHeight = isTablet ? 70.0 : screenHeight * 0.08;
    final titleFontSize = isTablet ? 28.0 : screenWidth * 0.07;
    final subtitleFontSize = isTablet ? 16.0 : screenWidth * 0.035;
    final iconSize = isTablet ? 24.0 : screenWidth * 0.1;
    final labelFontSize = isTablet ? 14.0 : screenWidth * 0.03;

    return WillPopScope(
      onWillPop: () async {
        // Allow app to exit when back button is pressed on home screen
        return true;
      },
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1d335f), // #1d335f - solid primary blue
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: _pages[_currentIndex],
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(appBarHeight),
          child: SafeArea(
            top: true, // Exclude status bar from colored background
            bottom: false,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF283d67), // 5% lighter shade of #1d335f
              ),
              child: SizedBox(
                height: appBarHeight,
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: EdgeInsets.only(top: isTablet ? 16.0 : screenHeight * 0.02),
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
                                    fontSize: titleFontSize,
                                  ),
                            ),
                            SizedBox(height: isTablet ? 4.0 : screenHeight * 0.005),
                            Text(
                              'No more lonely',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: subtitleFontSize,
                                color: const Color(0xFFD6D9E6),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_currentIndex == 0)
                      Positioned(
                        top: isTablet ? 16.0 : screenHeight * 0.02,
                        right: isTablet ? 16.0 : screenWidth * 0.03,
                        child: IconButton(
                          icon: Icon(
                            Icons.filter_list, 
                            color: Colors.white,
                            size: iconSize,
                          ),
                          onPressed: _onFiltersPressed,
                          tooltip: 'Filters',
                          iconSize: iconSize,
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
        bottomNavigationBar: SafeArea(
          bottom: true,
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF283d67), // 5% lighter shade of #1d335f
                  borderRadius: BorderRadius.only(
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
                  padding: EdgeInsets.only(
                    bottom: isTablet ? 8.0 : screenHeight * 0.01,
                    top: isTablet ? 8.0 : 0,
                  ),
                  child: NavigationBar(
                    backgroundColor: Colors.transparent,
                    height: bottomNavHeight,
                    selectedIndex: _currentIndex,
                    onDestinationSelected: (index) {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                    indicatorColor: const Color(0xFF3E5076), // 10% lighter shade of #283d67
                    labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                  destinations: [
                    NavigationDestination(
                      icon: Padding(
                        padding: EdgeInsets.symmetric(vertical: isTablet ? 4.0 : screenHeight * 0.002),
                        child: SvgIcons.discoverIcon(size: iconSize),
                      ),
                      selectedIcon: Padding(
                        padding: EdgeInsets.symmetric(vertical: isTablet ? 4.0 : screenHeight * 0.002),
                        child: SvgIcons.discoverIcon(size: iconSize),
                      ),
                      label: 'Discover',
                    ),
                    NavigationDestination(
                      icon: Padding(
                        padding: EdgeInsets.symmetric(vertical: isTablet ? 4.0 : screenHeight * 0.002),
                        child: SvgIcons.likesIcon(size: iconSize),
                      ),
                      selectedIcon: Padding(
                        padding: EdgeInsets.symmetric(vertical: isTablet ? 4.0 : screenHeight * 0.002),
                        child: SvgIcons.likesIcon(size: iconSize),
                      ),
                      label: 'Likes',
                    ),
                    NavigationDestination(
                      icon: Padding(
                        padding: EdgeInsets.symmetric(vertical: isTablet ? 4.0 : screenHeight * 0.002),
                        child: SvgIcons.chatsIcon(size: iconSize),
                      ),
                      selectedIcon: Padding(
                        padding: EdgeInsets.symmetric(vertical: isTablet ? 4.0 : screenHeight * 0.002),
                        child: SvgIcons.chatsIcon(size: iconSize),
                      ),
                      label: 'Chat',
                    ),
                    NavigationDestination(
                      icon: Padding(
                        padding: EdgeInsets.symmetric(vertical: isTablet ? 4.0 : screenHeight * 0.002),
                        child: SvgIcons.profileIcon(size: iconSize),
                      ),
                      selectedIcon: Padding(
                        padding: EdgeInsets.symmetric(vertical: isTablet ? 4.0 : screenHeight * 0.002),
                        child: SvgIcons.profileIcon(size: iconSize),
                      ),
                      label: 'Profile',
                    ),
                  ],
                  labelTextStyle: MaterialStatePropertyAll(
                    TextStyle(
                      fontFamily: 'Nunito',
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: labelFontSize,
                      height: 1.2,
                    ),
                  ),
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