import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nookly/presentation/bloc/recommended_profiles/recommended_profiles_bloc.dart';
import 'package:nookly/presentation/widgets/profile_card.dart';
import 'package:nookly/presentation/widgets/profile_detail_dialog.dart';

class RecommendedProfilesPage extends StatefulWidget {
  const RecommendedProfilesPage({super.key});

  @override
  State<RecommendedProfilesPage> createState() => _RecommendedProfilesPageState();
}

class _RecommendedProfilesPageState extends State<RecommendedProfilesPage> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  bool _isInitialLoad = false;

  @override
  void initState() {
    super.initState();
    print('🔵 DEBUG: RecommendedProfilesPage initState called');
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
        _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      print('🔵 PAGINATION: Scroll triggered pagination at position: ${_scrollController.position.pixels}');
      _loadMoreProfiles();
    }
  }

  void _loadMoreProfiles() {
    if (!_isLoadingMore) {
      final state = context.read<RecommendedProfilesBloc>().state;
      if (state is RecommendedProfilesLoaded && state.hasMore) {
        setState(() {
          _isLoadingMore = true;
        });
        
        print('🔵 DEBUG: _loadMoreProfiles called - loading more profiles');
        // Use current skip value for pagination
        context.read<RecommendedProfilesBloc>().add(LoadRecommendedProfiles());
        
        // Don't reset _isLoadingMore here - let the bloc state change handle it
        // The loading state will be reset when the bloc emits a new state
      }
    }
  }

  void _loadProfiles() {
    if (_isInitialLoad) {
      print('🔵 DEBUG: _loadProfiles called but already loading, skipping');
      return;
    }
    
    final currentState = context.read<RecommendedProfilesBloc>().state;
    if (currentState is RecommendedProfilesLoaded && currentState.profiles.isNotEmpty) {
      print('🔵 DEBUG: _loadProfiles called but profiles already loaded, skipping');
      return;
    }
    
    print('🔵 DEBUG: _loadProfiles called');
    _isInitialLoad = true;
    context.read<RecommendedProfilesBloc>().add(LoadRecommendedProfiles());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This will be called when the page is rebuilt, including after navigation
    // We don't need to reload here as it would cause infinite loops
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF234481),
      child: BlocConsumer<RecommendedProfilesBloc, RecommendedProfilesState>(
        listener: (context, state) {
          if (state is RecommendedProfilesError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
          
          // Reset loading state when bloc state changes
          if (state is RecommendedProfilesLoaded) {
            if (_isLoadingMore) {
              setState(() {
                _isLoadingMore = false;
              });
              print('🔵 DEBUG: Reset _isLoadingMore flag');
            }
            if (_isInitialLoad) {
              setState(() {
                _isInitialLoad = false;
              });
              print('🔵 DEBUG: Reset _isInitialLoad flag');
            }
          }
        },
        builder: (context, state) {
          if (state is RecommendedProfilesLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            );
          }
          
          if (state is RecommendedProfilesLoaded) {
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
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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
            
            print('🔵 DEBUG: Building ListView with ${state.profiles.length} profiles, _isLoadingMore: $_isLoadingMore');
            return ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: state.profiles.length + (_isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == state.profiles.length) {
                  if (_isLoadingMore) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }
                
                final profile = state.profiles[index];
                print('🔵 DEBUG: Rendering profile ${index + 1}/${state.profiles.length}: ID=${profile.id}, Name=${profile.name}, Distance=${profile.distance}');
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
                    // Disabled full screen view
                  },
                );
              },
            );
          }
          
          return const Center(
            child: Text('Something went wrong. Please try again.', style: TextStyle(color: Colors.white)),
          );
        },
      ),
    );
  }
} 