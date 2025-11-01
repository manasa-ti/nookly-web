import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nookly/presentation/bloc/received_likes/received_likes_bloc.dart';
import 'package:nookly/presentation/widgets/profile_card.dart';
import 'package:nookly/presentation/pages/profile/profile_view_page.dart';

class ReceivedLikesPage extends StatefulWidget {
  const ReceivedLikesPage({super.key});

  @override
  State<ReceivedLikesPage> createState() => _ReceivedLikesPageState();
}

class _ReceivedLikesPageState extends State<ReceivedLikesPage> {
  @override
  void initState() {
    super.initState();
    context.read<ReceivedLikesBloc>().add(LoadReceivedLikes());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ReceivedLikesBloc, ReceivedLikesState>(
        listener: (context, state) {
          if (state is ReceivedLikesError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ReceivedLikesLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            );
          }
          
          if (state is ReceivedLikesLoaded) {
            if (state.likes.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite_border,
                      size: 80,
                      color: Color(0xFFD6D9E6),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No likes yet',
                      style: TextStyle(
                        fontSize: (MediaQuery.of(context).size.width * 0.05).clamp(18.0, 22.0),
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        fontFamily: 'Nunito',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'When someone likes your profile, they\'ll appear here',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFD6D9E6),
                      ),
                    ),
                  ],
                ),
              );
            }
            
            // Adaptive padding for different screen sizes
            final isTablet = MediaQuery.of(context).size.width > 600;
            final listPadding = isTablet ? EdgeInsets.all(32.0) : EdgeInsets.all(MediaQuery.of(context).size.width * 0.04);
            
            return ListView.builder(
              padding: listPadding,
              itemCount: state.likes.length,
              itemBuilder: (context, index) {
                final like = state.likes[index];
                return ProfileCard(
                  key: ValueKey(like.id), // Add unique key based on like ID
                  profile: {
                    'id': like.id,
                    'name': like.name,
                    'age': like.age,
                    'gender': like.gender,
                    'distance': like.distance,
                    'bio': like.bio,
                    'interests': like.interests,
                    'profilePicture': like.profilePicture,
                  },
                  onSwipeRight: () {
                    context.read<ReceivedLikesBloc>().add(
                      AcceptLike(like.id),
                    );
                  },
                  onSwipeLeft: () {
                    context.read<ReceivedLikesBloc>().add(
                      RejectLike(like.id),
                    );
                  },
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileViewPage(userId: like.id),
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

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }
} 