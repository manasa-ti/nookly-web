import 'package:equatable/equatable.dart';

class Report extends Equatable {
  final String reportedUserId;
  final String reason;
  final String? details;
  final DateTime timestamp;

  const Report({
    required this.reportedUserId,
    required this.reason,
    this.details,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [reportedUserId, reason, details, timestamp];
} 