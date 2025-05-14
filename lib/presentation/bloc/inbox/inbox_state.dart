part of 'inbox_bloc.dart';

abstract class InboxState {
  const InboxState();
  // Equatable props will be handled by the main bloc which imports Equatable
  List<Object> get props => []; 
}

class InboxInitial extends InboxState {}

class InboxLoading extends InboxState {}

class InboxLoaded extends InboxState {
  final List<Conversation> conversations;

  const InboxLoaded(this.conversations);

  @override
  List<Object> get props => [conversations];
}

class InboxError extends InboxState {
  final String message;

  const InboxError(this.message);

  @override
  List<Object> get props => [message];
} 