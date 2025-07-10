class ReportReasonsResponse {
  final List<String> reasons;

  const ReportReasonsResponse({required this.reasons});

  factory ReportReasonsResponse.fromJson(Map<String, dynamic> json) {
    return ReportReasonsResponse(
      reasons: List<String>.from(json['reasons'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reasons': reasons,
    };
  }
} 