import 'package:nookly/core/utils/logger.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nookly/domain/entities/recommended_profile.dart';
import 'package:nookly/domain/repositories/recommended_profiles_repository.dart';

// Events
abstract class RecommendedProfilesEvent {}

class LoadRecommendedProfiles extends RecommendedProfilesEvent {
  final double? radius;
  final int? limit;
  final int? skip;
  final List<String>? physicalActiveness;
  final List<String>? availability;

  LoadRecommendedProfiles({
    this.radius,
    this.limit,
    this.skip,
    this.physicalActiveness,
    this.availability,
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

class ResetPagination extends RecommendedProfilesEvent {}

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
    on<ResetPagination>(_onResetPagination);
  }

  Future<void> _onLoadRecommendedProfiles(
    LoadRecommendedProfiles event,
    Emitter<RecommendedProfilesState> emit,
  ) async {
    try {
      // If skip is 0 or explicitly set to 0, it's a fresh load, otherwise it's pagination
      final isFreshLoad = event.skip == 0 || (event.skip == null && _currentSkip == 0);
      
      AppLogger.info('🔵 DEBUG: LoadRecommendedProfiles event - skip: ${event.skip}, isFreshLoad: $isFreshLoad, currentSkip: $_currentSkip');
      
      if (isFreshLoad) {
        AppLogger.info('🔵 DEBUG: Emitting loading state for fresh load');
        emit(RecommendedProfilesLoading());
        _currentSkip = 0;
      }
      
      final skip = event.skip ?? _currentSkip;
      AppLogger.info('🔵 PAGINATION: Loading profiles with skip: $skip, limit: ${event.limit ?? _defaultLimit}');
      
      final profiles = await repository.getRecommendedProfiles(
        radius: event.radius,
        limit: event.limit ?? _defaultLimit,
        skip: skip,
        physicalActiveness: event.physicalActiveness,
        availability: event.availability,
      );

      // Update skip counter for next pagination
      _currentSkip = skip + (event.limit ?? _defaultLimit);
      final hasMore = profiles.length == (event.limit ?? _defaultLimit);
      AppLogger.info('🔵 PAGINATION: Received ${profiles.length} profiles, hasMore: $hasMore, next skip: $_currentSkip');
      AppLogger.info('🔵 DEBUG: Profile IDs received: ${profiles.map((p) => p.id).toList()}');
      
      if (isFreshLoad) {
        // Fresh load - replace all profiles
        AppLogger.info('🔵 DEBUG: Emitting fresh load with ${profiles.length} profiles');
        emit(RecommendedProfilesLoaded(profiles, hasMore: hasMore));
      } else {
        // Pagination - append to existing profiles
        final currentState = state;
        if (currentState is RecommendedProfilesLoaded) {
          final updatedProfiles = [...currentState.profiles, ...profiles];
          AppLogger.info('🔵 DEBUG: Appending ${profiles.length} profiles to existing ${currentState.profiles.length} profiles');
          AppLogger.info('🔵 DEBUG: Updated profile IDs: ${updatedProfiles.map((p) => p.id).toList()}');
          emit(RecommendedProfilesLoaded(updatedProfiles, hasMore: hasMore));
        } else {
          AppLogger.info('🔵 DEBUG: Current state is not loaded, emitting new state with ${profiles.length} profiles');
          emit(RecommendedProfilesLoaded(profiles, hasMore: hasMore));
        }
      }
    } catch (e) {
      AppLogger.info('🔵 DEBUG: Error loading profiles: $e');
      emit(RecommendedProfilesError(e.toString()));
    }
  }

  Future<void> _onLikeProfile(
    LikeProfile event,
    Emitter<RecommendedProfilesState> emit,
  ) async {
    try {
      // Get current state
      final currentState = state;
      if (currentState is RecommendedProfilesLoaded) {
        // Remove the profile from the UI immediately
        final updatedProfiles = currentState.profiles
            .where((profile) => profile.id != event.profileId)
            .toList();
        
        // Emit updated state immediately for smooth UX
        emit(RecommendedProfilesLoaded(updatedProfiles, hasMore: currentState.hasMore));
        
        // Handle the backend call in the background
        await repository.likeProfile(event.profileId);
        
        // Reset pagination counter since backend list has changed
        AppLogger.info('🔵 PAGINATION: Resetting skip counter from $_currentSkip to 0 due to like');
        _currentSkip = 0;
        
        // Only refresh if we have 0 profiles left (empty state)
        if (updatedProfiles.isEmpty) {
          add(LoadRecommendedProfiles(skip: 0)); // Reset pagination for fresh start
        }
      }
    } catch (e) {
      // If backend call fails, we could optionally reload the list
      // For now, we'll just log the error to avoid blocking the user
      AppLogger.info('Error liking profile: $e');
      // Optionally show a subtle error message without blocking
      emit(RecommendedProfilesError('Failed to like profile, but you can continue browsing'));
    }
  }

  Future<void> _onDislikeProfile(
    DislikeProfile event,
    Emitter<RecommendedProfilesState> emit,
  ) async {
    try {
      // Get current state
      final currentState = state;
      if (currentState is RecommendedProfilesLoaded) {
        // Remove the profile from the UI immediately
        final updatedProfiles = currentState.profiles
            .where((profile) => profile.id != event.profileId)
            .toList();
        
        // Emit updated state immediately for smooth UX
        emit(RecommendedProfilesLoaded(updatedProfiles, hasMore: currentState.hasMore));
        
        // Handle the backend call in the background
        await repository.dislikeProfile(event.profileId);
        
        // Reset pagination counter since backend list has changed
        AppLogger.info('🔵 PAGINATION: Resetting skip counter from $_currentSkip to 0 due to dislike');
        _currentSkip = 0;
        
        // Only refresh if we have 0 profiles left (empty state)
        if (updatedProfiles.isEmpty) {
          add(LoadRecommendedProfiles(skip: 0)); // Reset pagination for fresh start
        }
      }
    } catch (e) {
      // If backend call fails, we could optionally reload the list
      // For now, we'll just log the error to avoid blocking the user
      AppLogger.info('Error disliking profile: $e');
      // Optionally show a subtle error message without blocking
      emit(RecommendedProfilesError('Failed to dislike profile, but you can continue browsing'));
    }
  }

  Future<void> _onResetPagination(
    ResetPagination event,
    Emitter<RecommendedProfilesState> emit,
  ) async {
    AppLogger.info('🔵 DEBUG: ResetPagination event received');
    _currentSkip = 0;
  }

  void resetPagination() {
    _currentSkip = 0;
  }
} 