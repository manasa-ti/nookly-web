import 'package:nookly/domain/entities/recommended_profile.dart';

class RecommendedProfilesPage {
  final List<RecommendedProfile> profiles;
  final String? cursor;
  final String? nextCursor;
  final bool hasMore;
  final int? limit;
  final int? totalCandidates;

  const RecommendedProfilesPage({
    required this.profiles,
    required this.hasMore,
    this.cursor,
    this.nextCursor,
    this.limit,
    this.totalCandidates,
  });
}

