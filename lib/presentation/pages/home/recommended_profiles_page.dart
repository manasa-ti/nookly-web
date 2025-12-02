import 'package:nookly/core/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nookly/presentation/bloc/recommended_profiles/recommended_profiles_bloc.dart';
import 'package:nookly/presentation/widgets/profile_card.dart';
import 'package:nookly/presentation/widgets/matching_tutorial_dialog.dart';
import 'package:nookly/presentation/pages/profile/profile_view_page.dart';
import 'package:nookly/core/services/filter_preferences_service.dart';
import 'package:nookly/core/services/onboarding_service.dart';
import 'package:nookly/core/theme/app_colors.dart';

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
            
            // Show empty state if there are no profiles
            if (state.profiles.isEmpty) {
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
                        color: AppColors.white85,
                        fontFamily: 'Nunito',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Check back later for new recommendations',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.onSurfaceVariant,
                        fontFamily: 'Nunito',
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
                itemCount: state.profiles.length,
                itemBuilder: (context, index) {
                  if (index < 0 || index >= state.profiles.length) {
                    // This shouldn't happen, but return empty widget as fallback
                    AppLogger.warning('🔵 WARNING: Invalid index $index for profiles list length ${state.profiles.length}');
                    return const SizedBox.shrink();
                  }
                  final profile = state.profiles[index];
                  _maybePrefetch(state, index);
                  AppLogger.info('🔵 DEBUG: Rendering profile ${index + 1}/${state.profiles.length}: ID=${profile.id}, Name=${profile.name}, Distance=${profile.distance}');
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
          
          return Center(
            child: Text(
              'Something went wrong. Please try again.',
              style: TextStyle(
                color: AppColors.onSurface,
                fontFamily: 'Nunito',
              ),
            ),
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