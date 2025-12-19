import 'package:nookly/core/utils/logger.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nookly/domain/entities/recommended_profile.dart';
import 'package:nookly/domain/repositories/recommended_profiles_repository.dart';

// Events
abstract class RecommendedProfilesEvent {
  const RecommendedProfilesEvent();
}

class LoadRecommendedProfiles extends RecommendedProfilesEvent {
  final double? radius;
  final int? limit;
  final String? cursor;
  final bool reset;
  final List<String>? physicalActiveness;
  final List<String>? availability;

  const LoadRecommendedProfiles({
    this.radius,
    this.limit,
    this.cursor,
    this.reset = false,
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
  final String? nextCursor;
  final String? currentCursor;
  final int? totalCandidates;

  RecommendedProfilesLoaded(
    this.profiles, {
    this.hasMore = true,
    this.nextCursor,
    this.currentCursor,
    this.totalCandidates,
  });
}

class RecommendedProfilesError extends RecommendedProfilesState {
  final String message;
  RecommendedProfilesError(this.message);
}

// Bloc
class RecommendedProfilesBloc extends Bloc<RecommendedProfilesEvent, RecommendedProfilesState> {
  final RecommendedProfilesRepository repository;
  static const int _defaultLimit = 20;
  String? _nextCursor;
  String? _currentCursor;
  double? _activeRadius;
  int? _activeLimit;
  List<String>? _activePhysicalActiveness;
  List<String>? _activeAvailability;
  bool _isFetching = false;

  RecommendedProfilesBloc({required this.repository}) : super(RecommendedProfilesInitial()) {
    on<LoadRecommendedProfiles>(_onLoadRecommendedProfiles);
    on<LikeProfile>(_onLikeProfile);
    on<DislikeProfile>(_onDislikeProfile);
    on<ResetPagination>(_onResetPagination);
  }

  /// Deduplicates profiles by ID, keeping the first occurrence to maintain order.
  /// This prevents duplicate profile cards from being rendered in the UI.
  /// Time complexity: O(n) where n is the number of profiles.
  List<RecommendedProfile> _deduplicateProfiles(List<RecommendedProfile> profiles) {
    final seen = <String>{};
    final uniqueProfiles = <RecommendedProfile>[];
    
    for (final profile in profiles) {
      if (!seen.contains(profile.id)) {
        seen.add(profile.id);
        uniqueProfiles.add(profile);
      } else {
        AppLogger.warning('🔵 DUPLICATE: Profile ${profile.id} (${profile.name}) already in list, skipping');
      }
    }
    
    if (profiles.length != uniqueProfiles.length) {
      AppLogger.info('🔵 DEDUPLICATION: Removed ${profiles.length - uniqueProfiles.length} duplicate profile(s)');
    }
    
    return uniqueProfiles;
  }

  Future<void> _onLoadRecommendedProfiles(
    LoadRecommendedProfiles event,
    Emitter<RecommendedProfilesState> emit,
  ) async {
    final bool isFreshLoad = event.reset;
    final String? explicitCursor = event.cursor;
    String? requestCursor;

    if (isFreshLoad) {
      requestCursor = null;
    } else {
      requestCursor = explicitCursor ?? _nextCursor;
      if (requestCursor == null) {
        AppLogger.info('🔵 PAGINATION: Load request ignored - no cursor available for next page');
        return;
      }
    }

    if (_isFetching) {
      AppLogger.info('🔵 PAGINATION: Load request ignored because another request is in flight');
      return;
    }

    _isFetching = true;

    try {
      if (isFreshLoad) {
        AppLogger.info('🔵 DEBUG: Emitting loading state for fresh load');
        emit(RecommendedProfilesLoading());
      }

      final double? radius =
          isFreshLoad ? event.radius : event.radius ?? _activeRadius;
      final int limit = isFreshLoad
          ? (event.limit ?? _defaultLimit)
          : (event.limit ?? _activeLimit ?? _defaultLimit);
      final List<String>? physicalActiveness = isFreshLoad
          ? event.physicalActiveness
          : event.physicalActiveness ?? _activePhysicalActiveness;
      final List<String>? availability = isFreshLoad
          ? event.availability
          : event.availability ?? _activeAvailability;

      final List<String>? effectivePhysicalActiveness =
          physicalActiveness?.toList();
      final List<String>? effectiveAvailability = availability?.toList();

      AppLogger.info(
        '🔵 PAGINATION: Loading profiles | cursor: $requestCursor | limit: $limit | fresh: $isFreshLoad',
      );

      final page = await repository.getRecommendedProfiles(
        radius: radius,
        limit: limit,
        cursor: requestCursor,
        physicalActiveness: effectivePhysicalActiveness,
        availability: effectiveAvailability,
      );

      _currentCursor = page.cursor;
      _nextCursor = page.nextCursor;
      _activeRadius = radius;
      _activeLimit = limit;
      _activePhysicalActiveness = effectivePhysicalActiveness;
      _activeAvailability = effectiveAvailability;

      final hasMore = page.hasMore;

      AppLogger.info(
        '🔵 PAGINATION: Received ${page.profiles.length} profiles | hasMore: $hasMore | nextCursor: $_nextCursor',
      );
      AppLogger.info(
        '🔵 DEBUG: Profile IDs received: ${page.profiles.map((p) => p.id).toList()}',
      );

      if (isFreshLoad) {
        // Fresh load: backend always returns unique profiles, no deduplication needed
        emit(
          RecommendedProfilesLoaded(
            page.profiles,
            hasMore: hasMore,
            nextCursor: _nextCursor,
            currentCursor: _currentCursor,
            totalCandidates: page.totalCandidates,
          ),
        );
      } else {
        final currentState = state;
        if (currentState is RecommendedProfilesLoaded) {
          // Pagination: Combine lists and deduplicate once (O(totalProfiles))
          // This single pass handles all race conditions - duplicates in existing list or new list
          final combinedProfiles = [...currentState.profiles, ...page.profiles];
          final uniqueProfiles = _deduplicateProfiles(combinedProfiles);
          
          emit(
            RecommendedProfilesLoaded(
              uniqueProfiles,
              hasMore: hasMore,
              nextCursor: _nextCursor,
              currentCursor: _currentCursor,
              totalCandidates:
                  page.totalCandidates ?? currentState.totalCandidates,
            ),
          );
        } else {
          // State not loaded: backend always returns unique profiles, no deduplication needed
          emit(
            RecommendedProfilesLoaded(
              page.profiles,
              hasMore: hasMore,
              nextCursor: _nextCursor,
              currentCursor: _currentCursor,
              totalCandidates: page.totalCandidates,
            ),
          );
        }
      }
    } catch (e) {
      AppLogger.info('🔵 DEBUG: Error loading profiles: $e');
      emit(RecommendedProfilesError(e.toString()));
    } finally {
      _isFetching = false;
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
        emit(
          RecommendedProfilesLoaded(
            updatedProfiles,
            hasMore: currentState.hasMore,
            nextCursor: currentState.nextCursor,
            currentCursor: currentState.currentCursor,
            totalCandidates: currentState.totalCandidates,
          ),
        );
        
        // Handle the backend call in the background
        await repository.likeProfile(event.profileId);

        // Only refresh if we have 0 profiles left (empty state)
        if (updatedProfiles.isEmpty && currentState.hasMore) {
          AppLogger.info('🔵 PAGINATION: Requesting next page after like');
          add(const LoadRecommendedProfiles());
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
        emit(
          RecommendedProfilesLoaded(
            updatedProfiles,
            hasMore: currentState.hasMore,
            nextCursor: currentState.nextCursor,
            currentCursor: currentState.currentCursor,
            totalCandidates: currentState.totalCandidates,
          ),
        );
        
        // Handle the backend call in the background
        await repository.dislikeProfile(event.profileId);

        // Only refresh if we have 0 profiles left (empty state)
        if (updatedProfiles.isEmpty && currentState.hasMore) {
          AppLogger.info('🔵 PAGINATION: Requesting next page after dislike');
          add(const LoadRecommendedProfiles());
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
    _nextCursor = null;
    _currentCursor = null;
    _activeRadius = null;
    _activeLimit = null;
    _activePhysicalActiveness = null;
    _activeAvailability = null;
    _isFetching = false;
  }

  void resetPagination() {
    _nextCursor = null;
    _currentCursor = null;
    _activeRadius = null;
    _activeLimit = null;
    _activePhysicalActiveness = null;
    _activeAvailability = null;
    _isFetching = false;
  }
} 