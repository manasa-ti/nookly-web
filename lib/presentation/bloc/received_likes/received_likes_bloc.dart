import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hushmate/domain/entities/received_like.dart';
import 'package:hushmate/domain/repositories/received_likes_repository.dart';

// Events
abstract class ReceivedLikesEvent {}

class LoadReceivedLikes extends ReceivedLikesEvent {}

class AcceptLike extends ReceivedLikesEvent {
  final String likeId;
  AcceptLike(this.likeId);
}

class RejectLike extends ReceivedLikesEvent {
  final String likeId;
  RejectLike(this.likeId);
}

// States
abstract class ReceivedLikesState {}

class ReceivedLikesInitial extends ReceivedLikesState {}

class ReceivedLikesLoading extends ReceivedLikesState {}

class ReceivedLikesLoaded extends ReceivedLikesState {
  final List<ReceivedLike> likes;
  ReceivedLikesLoaded(this.likes);
}

class ReceivedLikesError extends ReceivedLikesState {
  final String message;
  ReceivedLikesError(this.message);
}

// Bloc
class ReceivedLikesBloc extends Bloc<ReceivedLikesEvent, ReceivedLikesState> {
  final ReceivedLikesRepository repository;

  ReceivedLikesBloc({required this.repository}) : super(ReceivedLikesInitial()) {
    on<LoadReceivedLikes>(_onLoadReceivedLikes);
    on<AcceptLike>(_onAcceptLike);
    on<RejectLike>(_onRejectLike);
  }

  Future<void> _onLoadReceivedLikes(
    LoadReceivedLikes event,
    Emitter<ReceivedLikesState> emit,
  ) async {
    emit(ReceivedLikesLoading());
    try {
      final likes = await repository.getReceivedLikes();
      emit(ReceivedLikesLoaded(likes));
    } catch (e) {
      emit(ReceivedLikesError(e.toString()));
    }
  }

  Future<void> _onAcceptLike(
    AcceptLike event,
    Emitter<ReceivedLikesState> emit,
  ) async {
    try {
      await repository.acceptLike(event.likeId);
      // Refresh the likes list after accepting
      add(LoadReceivedLikes());
    } catch (e) {
      emit(ReceivedLikesError(e.toString()));
    }
  }

  Future<void> _onRejectLike(
    RejectLike event,
    Emitter<ReceivedLikesState> emit,
  ) async {
    try {
      await repository.rejectLike(event.likeId);
      // Refresh the likes list after rejecting
      add(LoadReceivedLikes());
    } catch (e) {
      emit(ReceivedLikesError(e.toString()));
    }
  }
} 