import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:nookly/domain/entities/received_like.dart';
import 'package:nookly/domain/repositories/received_likes_repository.dart';

// Events
abstract class ReceivedLikesEvent extends Equatable {
  const ReceivedLikesEvent();

  @override
  List<Object?> get props => [];
}

class LoadReceivedLikes extends ReceivedLikesEvent {
  const LoadReceivedLikes();
}

class AcceptLike extends ReceivedLikesEvent {
  final String likeId;
  const AcceptLike(this.likeId);

  @override
  List<Object?> get props => [likeId];
}

class RejectLike extends ReceivedLikesEvent {
  final String likeId;
  const RejectLike(this.likeId);

  @override
  List<Object?> get props => [likeId];
}

// States
abstract class ReceivedLikesState extends Equatable {
  const ReceivedLikesState();

  @override
  List<Object?> get props => [];
}

class ReceivedLikesInitial extends ReceivedLikesState {
  const ReceivedLikesInitial();
}

class ReceivedLikesLoading extends ReceivedLikesState {
  const ReceivedLikesLoading();
}

class ReceivedLikesLoaded extends ReceivedLikesState {
  final List<ReceivedLike> likes;
  const ReceivedLikesLoaded(this.likes);

  @override
  List<Object?> get props => [likes];
}

class ReceivedLikesError extends ReceivedLikesState {
  final String message;
  const ReceivedLikesError(this.message);

  @override
  List<Object?> get props => [message];
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