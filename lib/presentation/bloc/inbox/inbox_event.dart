part of 'inbox_bloc.dart';

abstract class InboxEvent {
  const InboxEvent();
  // Equatable props will be handled by the main bloc which imports Equatable
  List<Object> get props => [];
}

class LoadInbox extends InboxEvent {} 