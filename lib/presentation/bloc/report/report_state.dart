import 'package:equatable/equatable.dart';

abstract class ReportState extends Equatable {
  const ReportState();

  @override
  List<Object?> get props => [];
}

class ReportInitial extends ReportState {}

class ReportLoading extends ReportState {}

class ReportReasonsLoaded extends ReportState {
  final List<String> reasons;

  const ReportReasonsLoaded(this.reasons);

  @override
  List<Object?> get props => [reasons];
}

class ReportSubmitting extends ReportState {
  final List<String> reasons;

  const ReportSubmitting(this.reasons);

  @override
  List<Object?> get props => [reasons];
}

class ReportSubmitted extends ReportState {
  final String message;
  final int uniqueReporters;
  final bool isBanned;

  const ReportSubmitted({
    required this.message,
    required this.uniqueReporters,
    required this.isBanned,
  });

  @override
  List<Object?> get props => [message, uniqueReporters, isBanned];
}

class ReportError extends ReportState {
  final String message;

  const ReportError(this.message);

  @override
  List<Object?> get props => [message];
} 