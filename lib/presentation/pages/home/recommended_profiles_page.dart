import 'package:nookly/core/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nookly/presentation/bloc/recommended_profiles/recommended_profiles_bloc.dart';
import 'package:nookly/presentation/widgets/profile_card.dart';
import 'package:nookly/presentation/widgets/matching_tutorial_dialog.dart';
import 'package:nookly/presentation/pages/profile/profile_view_page.dart';
import 'package:nookly/core/services/filter_preferences_service.dart';
import 'package:nookly/core/services/onboarding_service.dart';

class RecommendedProfilesPage extends StatefulWidget {
  const RecommendedProfilesPage({super.key});

  @override
  State<RecommendedProfilesPage> createState() => _RecommendedProfilesPageState();
}

class _RecommendedProfilesPageState extends State<RecommendedProfilesPage> {
  final ScrollController _scrollController = ScrollController();
  bool _isPrefetching = false;
  bool _isInitialLoad = false;
  bool _tutorialDialogShown = false; // Prevent duplicate dialogs

  @override
  void initState() {
    super.initState();
    AppLogger.info('🔵 DEBUG: RecommendedProfilesPage initState called');
    _loadProfiles();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final state = context.read<RecommendedProfilesBloc>().state;
    if (state is RecommendedProfilesLoaded && 
        state.hasMore && 
        !_isPrefetching &&
        _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 400) {
      AppLogger.info('🔵 PAGINATION: Scroll triggered pagination at position: ${_scrollController.position.pixels}');
      _prefetchNextBatch();
    }
  }

  void _prefetchNextBatch() async {
    if (_isPrefetching) return;

    final bloc = context.read<RecommendedProfilesBloc>();
    final state = bloc.state;
    if (state is! RecommendedProfilesLoaded || !state.hasMore) return;

    AppLogger.info('🔵 DEBUG: _prefetchNextBatch requested');
    if (!mounted) return;
    setState(() {
      _isPrefetching = true;
    });

    try {
      // Load filter preferences for pagination
      final physicalActivenessFilters = await FilterPreferencesService.getPhysicalActivenessFilters();
      final availabilityFilters = await FilterPreferencesService.getAvailabilityFilters();

      if (!mounted) return;

      bloc.add(LoadRecommendedProfiles(
        physicalActiveness: physicalActivenessFilters.isNotEmpty ? physicalActivenessFilters : null,
        availability: availabilityFilters.isNotEmpty ? availabilityFilters : null,
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isPrefetching = false;
      });
      AppLogger.info('🔵 DEBUG: Prefetch failed to initiate: $e');
    }
  }

  void _loadProfiles() async {
    if (_isInitialLoad) {
      AppLogger.info('🔵 DEBUG: _loadProfiles called but already loading, skipping');
      return;
    }
    
    final bloc = context.read<RecommendedProfilesBloc>();
    final currentState = bloc.state;
    if (currentState is RecommendedProfilesLoaded && currentState.profiles.isNotEmpty) {
      AppLogger.info('🔵 DEBUG: _loadProfiles called but profiles already loaded, skipping');
      return;
    }
    
    AppLogger.info('🔵 DEBUG: _loadProfiles called');
    _isInitialLoad = true;
    
    // Load filter preferences
    final physicalActivenessFilters = await FilterPreferencesService.getPhysicalActivenessFilters();
    final availabilityFilters = await FilterPreferencesService.getAvailabilityFilters();
    
    AppLogger.info('🔵 DEBUG: Loaded filters - Physical Activeness: $physicalActivenessFilters, Availability: $availabilityFilters');
    
    if (!mounted) return;
    
    bloc.add(LoadRecommendedProfiles(
      reset: true, // Explicitly reset for initial load
      physicalActiveness: physicalActivenessFilters.isNotEmpty ? physicalActivenessFilters : null,
      availability: availabilityFilters.isNotEmpty ? availabilityFilters : null,
    ));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This will be called when the page is rebuilt, including after navigation
    // We don't need to reload here as it would cause infinite loops
  }

  Future<void> _showMatchingTutorialIfNeeded() async {
    if (_tutorialDialogShown) return;
    
    try {
      final shouldShow = await OnboardingService.shouldShowMatchingTutorial();
      if (shouldShow && mounted) {
        _tutorialDialogShown = true;
        
        // Use post frame callback to ensure the dialog shows after the UI is built
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false, // Prevent dismissing by tapping outside
              builder: (context) => MatchingTutorialDialog(
                onComplete: () {
                  AppLogger.info('🔵 MATCHING TUTORIAL: Dialog completed');
                },
              ),
            );
          }
        });
      }
    } catch (e) {
      AppLogger.info('🔵 MATCHING TUTORIAL: Error showing tutorial: $e');
    }
  }

  // TODO: TEMPORARY - Remove these mocked profiles later
  List<Map<String, dynamic>> _getMockedProfiles() {
    return [
      {
        'id': 'mock_profile_1',
        'name': 'Alex',
        'age': 28,
        'sex': 'Male',
        'distance': 2.5,
        'bio': 'Love traveling and exploring new places. Coffee enthusiast and bookworm.',
        'interests': ['Travel', 'Reading', 'Coffee', 'Photography'],
        'profilePicture': null,
        'hometown': 'San Francisco, CA',
        'objectives': ['Friendship', 'Dating'],
        'commonInterests': ['Travel', 'Reading'],
        'commonObjectives': ['Friendship'],
      },
      {
        'id': 'mock_profile_2',
        'name': 'Sam',
        'age': 25,
        'sex': 'Female',
        'distance': 5.0,
        'bio': 'Fitness enthusiast and foodie. Always up for trying new restaurants and outdoor adventures.',
        'interests': ['Fitness', 'Food', 'Hiking', 'Yoga'],
        'profilePicture': null,
        'hometown': 'Los Angeles, CA',
        'objectives': ['Dating', 'Friendship'],
        'commonInterests': ['Fitness', 'Food'],
        'commonObjectives': ['Dating'],
      },
      {
        'id': 'mock_profile_3',
        'name': 'Jordan',
        'age': 30,
        'sex': 'Non-binary',
        'distance': 3.2,
        'bio': 'Artist and music lover. Passionate about creativity and meaningful conversations.',
        'interests': ['Art', 'Music', 'Photography', 'Writing'],
        'profilePicture': null,
        'hometown': 'New York, NY',
        'objectives': ['Friendship', 'Networking'],
        'commonInterests': ['Photography', 'Music'],
        'commonObjectives': ['Friendship'],
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return BlocConsumer<RecommendedProfilesBloc, RecommendedProfilesState>(
        listener: (context, state) {
          if (state is RecommendedProfilesError) {
            if (_isPrefetching) {
              setState(() {
                _isPrefetching = false;
              });
              AppLogger.info('🔵 DEBUG: Reset _isPrefetching flag after error');
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
          
          // Reset loading state when bloc state changes
          if (state is RecommendedProfilesLoaded) {
            if (_isPrefetching) {
              setState(() {
                _isPrefetching = false;
              });
              AppLogger.info('🔵 DEBUG: Reset _isPrefetching flag');
            }
            if (_isInitialLoad) {
              setState(() {
                _isInitialLoad = false;
              });
              AppLogger.info('🔵 DEBUG: Reset _isInitialLoad flag');
              
              // Show matching tutorial dialog after initial load
              _showMatchingTutorialIfNeeded();
            }
          }
        },
        builder: (context, state) {
          if (state is RecommendedProfilesLoading || _isInitialLoad) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white)
              ),
            );
          }
          
          if (state is RecommendedProfilesLoaded) {
            AppLogger.info('🔵 DEBUG: Building ListView with ${state.profiles.length} profiles, _isPrefetching: $_isPrefetching');
            
            // TODO: TEMPORARY - Remove mocked profiles later
            final mockedProfiles = _getMockedProfiles();
            final totalItemCount = mockedProfiles.length + state.profiles.length;
            
            // Show empty state only if there are no mocked profiles AND no real profiles
            if (state.profiles.isEmpty && mockedProfiles.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No profiles found',
                      style: TextStyle(
                        fontSize: (size.width * 0.05).clamp(16.0, 20.0),
                        fontWeight: FontWeight.w500,
                        color: Colors.white
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Check back later for new recommendations',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              );
            }
            
            // Adaptive padding for different screen sizes
            final isTablet = MediaQuery.of(context).size.width > 600;
            final listPadding = isTablet ? const EdgeInsets.all(32.0) : EdgeInsets.all(MediaQuery.of(context).size.width * 0.04);
            
            return RefreshIndicator(
              onRefresh: () async {
                AppLogger.info('🔵 DEBUG: Pull to refresh triggered');
                final bloc = context.read<RecommendedProfilesBloc>();
                
                // Load filter preferences for refresh
                final physicalActivenessFilters = await FilterPreferencesService.getPhysicalActivenessFilters();
                final availabilityFilters = await FilterPreferencesService.getAvailabilityFilters();
                
                // Force fresh load by explicitly setting skip to 0
                if (!mounted) return;
                bloc.add(LoadRecommendedProfiles(
                  reset: true, // Explicitly set reset for fresh load
                  physicalActiveness: physicalActivenessFilters.isNotEmpty ? physicalActivenessFilters : null,
                  availability: availabilityFilters.isNotEmpty ? availabilityFilters : null,
                ));
              },
              child: ListView.builder(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()), // Fix iOS pull-to-refresh for short lists
                padding: listPadding,
                itemCount: totalItemCount,
                itemBuilder: (context, index) {
                  // TODO: TEMPORARY - Handle mocked profiles (first 3 items)
                  if (index < mockedProfiles.length) {
                    final mockProfile = mockedProfiles[index];
                    AppLogger.info('🔵 DEBUG: Rendering MOCKED profile ${index + 1}: ID=${mockProfile['id']}, Name=${mockProfile['name']}');
                    return ProfileCard(
                      key: ValueKey('mock_${mockProfile['id']}'),
                      profile: mockProfile,
                      onSwipeRight: () {
                        AppLogger.info('🔵 MOCK: Swiped right on ${mockProfile['name']}');
                        // No action for mocked profiles
                      },
                      onSwipeLeft: () {
                        AppLogger.info('🔵 MOCK: Swiped left on ${mockProfile['name']}');
                        // No action for mocked profiles
                      },
                      onTap: () {
                        AppLogger.info('🔵 MOCK: Tapped on ${mockProfile['name']}');
                        // No navigation for mocked profiles
                      },
                    );
                  }
                  
                  // Real profiles (offset by mocked profiles count)
                  final realIndex = index - mockedProfiles.length;
                  if (realIndex < 0 || realIndex >= state.profiles.length) {
                    // This shouldn't happen, but return empty widget as fallback
                    AppLogger.warning('🔵 WARNING: Invalid realIndex $realIndex for profiles list length ${state.profiles.length}');
                    return const SizedBox.shrink();
                  }
                  final profile = state.profiles[realIndex];
                  _maybePrefetch(state, realIndex);
                  AppLogger.info('🔵 DEBUG: Rendering profile ${realIndex + 1}/${state.profiles.length}: ID=${profile.id}, Name=${profile.name}, Distance=${profile.distance}');
                  return ProfileCard(
                    key: ValueKey(profile.id), // Add unique key based on profile ID
                    profile: {
                      'id': profile.id,
                      'name': profile.name,
                      'age': profile.age,
                      'sex': profile.sex,
                      'distance': profile.distance,
                      'bio': profile.bio,
                      'interests': profile.interests,
                      'profilePicture': profile.profilePic,
                      'hometown': profile.hometown,
                      'objectives': profile.objectives,
                      'commonInterests': profile.commonInterests,
                      'commonObjectives': profile.commonObjectives,
                    },
                    onSwipeRight: () {
                      context.read<RecommendedProfilesBloc>().add(
                        LikeProfile(profile.id),
                      );
                    },
                    onSwipeLeft: () {
                      context.read<RecommendedProfilesBloc>().add(
                        DislikeProfile(profile.id),
                      );
                    },
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileViewPage(userId: profile.id),
                        ),
                      );
                    },
                  );
                },
              ),
            );
          }
          
          return const Center(
            child: Text('Something went wrong. Please try again.', style: TextStyle(color: Colors.white)),
          );
        },
      );
  }

  void _maybePrefetch(RecommendedProfilesLoaded state, int index) {
    if (!state.hasMore || _isPrefetching) return;

    const prefetchThreshold = 3;
    if (state.profiles.length - index <= prefetchThreshold) {
      AppLogger.info('🔵 PAGINATION: Prefetch triggered from builder at index $index');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _prefetchNextBatch();
        }
      });
    }
  }
} 