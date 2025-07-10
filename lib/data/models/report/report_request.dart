class ReportRequest {
  final String reportedUserId;
  final String reason;
  final String? details;

  const ReportRequest({
    required this.reportedUserId,
    required this.reason,
    this.details,
  });

  Map<String, dynamic> toJson() {
    final json = {
      'reportedUserId': reportedUserId,
      'reason': reason,
    };
    
    if (details != null && details!.isNotEmpty) {
      json['details'] = details!;
    }
    
    return json;
  }
} 