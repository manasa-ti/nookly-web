import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hushmate/core/di/injection_container.dart';
import 'package:hushmate/presentation/bloc/recommended_profiles/recommended_profiles_bloc.dart';
import 'package:hushmate/presentation/widgets/profile_card.dart';
import 'package:hushmate/presentation/widgets/profile_detail_dialog.dart';
import 'package:hushmate/presentation/widgets/filter_dialog.dart';

class RecommendedProfilesPage extends StatefulWidget {
  const RecommendedProfilesPage({super.key});

  @override
  State<RecommendedProfilesPage> createState() => _RecommendedProfilesPageState();
}

class _RecommendedProfilesPageState extends State<RecommendedProfilesPage> {
  @override
  void initState() {
    super.initState();
    context.read<RecommendedProfilesBloc>().add(LoadRecommendedProfiles());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RecommendedProfilesBloc, RecommendedProfilesState>(
      listener: (context, state) {
        if (state is RecommendedProfilesError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is RecommendedProfilesLoading) {
          return const Center(
            child: CircularProgressIndicator(),
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
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Check back later for new recommendations',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.profiles.length,
            itemBuilder: (context, index) {
              final profile = state.profiles[index];
              return ProfileCard(
                profile: {
                  'id': profile.id,
                  'name': profile.name,
                  'age': profile.age,
                  'gender': profile.gender,
                  'distance': profile.distance,
                  'bio': profile.bio,
                  'interests': profile.interests,
                  'profilePicture': profile.profilePicture,
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
                  showDialog(
                    context: context,
                    builder: (context) => ProfileDetailDialog(
                      profile: {
                        'id': profile.id,
                        'name': profile.name,
                        'age': profile.age,
                        'gender': profile.gender,
                        'distance': profile.distance,
                        'bio': profile.bio,
                        'interests': profile.interests,
                        'profilePicture': profile.profilePicture,
                      },
                    ),
                  );
                },
              );
            },
          );
        }
        
        return const Center(
          child: Text('Something went wrong. Please try again.'),
        );
      },
    );
  }
} 