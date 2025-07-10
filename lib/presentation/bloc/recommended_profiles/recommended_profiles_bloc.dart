import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nookly/domain/entities/recommended_profile.dart';
import 'package:nookly/domain/repositories/recommended_profiles_repository.dart';

// Events
abstract class RecommendedProfilesEvent {}

class LoadRecommendedProfiles extends RecommendedProfilesEvent {
  final double? radius;
  final int? limit;
  final int? skip;

  LoadRecommendedProfiles({
    this.radius,
    this.limit,
    this.skip,
  });
}

class LikeProfile extends RecommendedProfilesEvent {
  final String profileId;
  LikeProfile(this.profileId);
}

class DislikeProfile extends RecommendedProfilesEvent {
  final String profileId;
  DislikeProfile(this.profileId);
}

// States
abstract class RecommendedProfilesState {}

class RecommendedProfilesInitial extends RecommendedProfilesState {}

class RecommendedProfilesLoading extends RecommendedProfilesState {}

class RecommendedProfilesLoaded extends RecommendedProfilesState {
  final List<RecommendedProfile> profiles;
  final bool hasMore;
  RecommendedProfilesLoaded(this.profiles, {this.hasMore = true});
}

class RecommendedProfilesError extends RecommendedProfilesState {
  final String message;
  RecommendedProfilesError(this.message);
}

// Bloc
class RecommendedProfilesBloc extends Bloc<RecommendedProfilesEvent, RecommendedProfilesState> {
  final RecommendedProfilesRepository repository;
  int _currentSkip = 0;
  static const int _defaultLimit = 20;

  RecommendedProfilesBloc({required this.repository}) : super(RecommendedProfilesInitial()) {
    on<LoadRecommendedProfiles>(_onLoadRecommendedProfiles);
    on<LikeProfile>(_onLikeProfile);
    on<DislikeProfile>(_onDislikeProfile);
  }

  Future<void> _onLoadRecommendedProfiles(
    LoadRecommendedProfiles event,
    Emitter<RecommendedProfilesState> emit,
  ) async {
    try {
      emit(RecommendedProfilesLoading());
      
      final skip = event.skip ?? _currentSkip;
      final profiles = await repository.getRecommendedProfiles(
        radius: event.radius,
        limit: event.limit ?? _defaultLimit,
        skip: skip,
      );

      _currentSkip = skip + (event.limit ?? _defaultLimit);
      final hasMore = profiles.length == (event.limit ?? _defaultLimit);
      
      emit(RecommendedProfilesLoaded(profiles, hasMore: hasMore));
    } catch (e) {
      emit(RecommendedProfilesError(e.toString()));
    }
  }

  Future<void> _onLikeProfile(
    LikeProfile event,
    Emitter<RecommendedProfilesState> emit,
  ) async {
    try {
      await repository.likeProfile(event.profileId);
      // Refresh the profiles list after liking
      add(LoadRecommendedProfiles(skip: 0)); // Reset pagination
    } catch (e) {
      emit(RecommendedProfilesError(e.toString()));
    }
  }

  Future<void> _onDislikeProfile(
    DislikeProfile event,
    Emitter<RecommendedProfilesState> emit,
  ) async {
    try {
      await repository.dislikeProfile(event.profileId);
      // Refresh the profiles list after disliking
      add(LoadRecommendedProfiles(skip: 0)); // Reset pagination
    } catch (e) {
      emit(RecommendedProfilesError(e.toString()));
    }
  }

  void resetPagination() {
    _currentSkip = 0;
  }
} 