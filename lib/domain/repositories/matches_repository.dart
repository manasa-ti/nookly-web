import 'package:hushmate/domain/entities/matched_profile.dart';

abstract class MatchesRepository {
  Future<List<MatchedProfile>> getMatchedProfiles();
} 