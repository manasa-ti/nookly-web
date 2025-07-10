abstract class ReportRepository {
  /// Get list of predefined report reasons from the API
  Future<List<String>> getReportReasons();
  
  /// Report a user for inappropriate conduct
  Future<Map<String, dynamic>> reportUser({
    required String reportedUserId,
    required String reason,
    String? details,
  });
} 