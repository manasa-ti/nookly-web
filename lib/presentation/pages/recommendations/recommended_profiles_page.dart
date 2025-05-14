import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hushmate/domain/entities/recommended_profile.dart';
import 'package:hushmate/presentation/bloc/recommended_profiles/recommended_profiles_bloc.dart';

class RecommendedProfilesPage extends StatefulWidget {
  const RecommendedProfilesPage({super.key});

  @override
  State<RecommendedProfilesPage> createState() => _RecommendedProfilesPageState();
}

class _RecommendedProfilesPageState extends State<RecommendedProfilesPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    context.read<RecommendedProfilesBloc>().add(LoadRecommendedProfiles());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final state = context.read<RecommendedProfilesBloc>().state;
      if (state is RecommendedProfilesLoaded && state.hasMore) {
        context.read<RecommendedProfilesBloc>().add(LoadRecommendedProfiles());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recommended Profiles'),
      ),
      body: BlocBuilder<RecommendedProfilesBloc, RecommendedProfilesState>(
        builder: (context, state) {
          if (state is RecommendedProfilesInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is RecommendedProfilesError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<RecommendedProfilesBloc>().add(LoadRecommendedProfiles());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is RecommendedProfilesLoaded) {
            if (state.profiles.isEmpty) {
              return const Center(
                child: Text('No profiles found. Try adjusting your preferences.'),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<RecommendedProfilesBloc>().resetPagination();
                context.read<RecommendedProfilesBloc>().add(LoadRecommendedProfiles());
              },
              child: ListView.builder(
                controller: _scrollController,
                itemCount: state.profiles.length + (state.hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == state.profiles.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  return ProfileCard(profile: state.profiles[index]);
                },
              ),
            );
          }

          // Show loading indicator for RecommendedProfilesLoading state
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

class ProfileCard extends StatelessWidget {
  final RecommendedProfile profile;

  const ProfileCard({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Image
          if (profile.profilePic != null)
            AspectRatio(
              aspectRatio: 1,
              child: Image.network(
                profile.profilePic!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: theme.colorScheme.surfaceVariant,
                    child: const Icon(Icons.person, size: 100),
                  );
                },
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Basic Info
                Row(
                  children: [
                    Text(
                      '${profile.age} years',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '• ${profile.distance.toStringAsFixed(1)} km away',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  profile.hometown,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),

                // Bio
                Text(
                  profile.bio,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),

                // Common Interests
                if (profile.commonInterests.isNotEmpty) ...[
                  Text(
                    'Common Interests',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: profile.commonInterests
                        .map((interest) => Chip(label: Text(interest)))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // Common Objectives
                if (profile.commonObjectives.isNotEmpty) ...[
                  Text(
                    'Common Objectives',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: profile.commonObjectives
                        .map((objective) => Chip(label: Text(objective)))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        context.read<RecommendedProfilesBloc>().add(
                              DislikeProfile(profile.id),
                            );
                      },
                      icon: const Icon(Icons.close),
                      label: const Text('Skip'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.surfaceVariant,
                        foregroundColor: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        context.read<RecommendedProfilesBloc>().add(
                              LikeProfile(profile.id),
                            );
                      },
                      icon: const Icon(Icons.favorite),
                      label: const Text('Like'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 