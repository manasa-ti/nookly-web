import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hushmate/domain/entities/recommended_profile.dart';
import 'package:hushmate/domain/repositories/recommended_profiles_repository.dart';

// Events
abstract class RecommendedProfilesEvent {}

class LoadRecommendedProfiles extends RecommendedProfilesEvent {}

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
  RecommendedProfilesLoaded(this.profiles);
}

class RecommendedProfilesError extends RecommendedProfilesState {
  final String message;
  RecommendedProfilesError(this.message);
}

// Bloc
class RecommendedProfilesBloc extends Bloc<RecommendedProfilesEvent, RecommendedProfilesState> {
  final RecommendedProfilesRepository repository;

  RecommendedProfilesBloc({required this.repository}) : super(RecommendedProfilesInitial()) {
    on<LoadRecommendedProfiles>(_onLoadRecommendedProfiles);
    on<LikeProfile>(_onLikeProfile);
    on<DislikeProfile>(_onDislikeProfile);
  }

  Future<void> _onLoadRecommendedProfiles(
    LoadRecommendedProfiles event,
    Emitter<RecommendedProfilesState> emit,
  ) async {
    emit(RecommendedProfilesLoading());
    try {
      final profiles = await repository.getRecommendedProfiles();
      emit(RecommendedProfilesLoaded(profiles));
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
      // Optionally refresh the profiles list after liking
      add(LoadRecommendedProfiles());
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
      // Optionally refresh the profiles list after disliking
      add(LoadRecommendedProfiles());
    } catch (e) {
      emit(RecommendedProfilesError(e.toString()));
    }
  }
} 