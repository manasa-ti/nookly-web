part of 'inbox_bloc.dart';

abstract class InboxEvent {
  const InboxEvent();
  // Equatable props will be handled by the main bloc which imports Equatable
  List<Object> get props => [];
}

class LoadInbox extends InboxEvent {} 

class RefreshInbox extends InboxEvent {}

class MarkConversationAsRead extends InboxEvent {
  final String conversationId;
  
  const MarkConversationAsRead(this.conversationId);
  
  @override
  List<Object> get props => [conversationId];
}

class InboxUpdated extends InboxEvent {
  final List<Conversation> conversations;
  
  const InboxUpdated({required this.conversations});
  
  @override
  List<Object> get props => [conversations];
} 