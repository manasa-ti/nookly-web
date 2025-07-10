import 'package:equatable/equatable.dart';

abstract class ReportEvent extends Equatable {
  const ReportEvent();

  @override
  List<Object?> get props => [];
}

class LoadReportReasons extends ReportEvent {}

class ReportUser extends ReportEvent {
  final String reportedUserId;
  final String reason;
  final String? details;

  const ReportUser({
    required this.reportedUserId,
    required this.reason,
    this.details,
  });

  @override
  List<Object?> get props => [reportedUserId, reason, details];
} 