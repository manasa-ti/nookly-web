class ReportResponse {
  final String message;
  final int uniqueReporters;
  final bool isBanned;

  const ReportResponse({
    required this.message,
    required this.uniqueReporters,
    required this.isBanned,
  });

  factory ReportResponse.fromJson(Map<String, dynamic> json) {
    return ReportResponse(
      message: json['message'] as String,
      uniqueReporters: json['uniqueReporters'] as int,
      isBanned: json['isBanned'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'uniqueReporters': uniqueReporters,
      'isBanned': isBanned,
    };
  }
} 