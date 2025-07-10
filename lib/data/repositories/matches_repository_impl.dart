import 'package:dio/dio.dart';
import 'package:nookly/core/network/network_service.dart'; // Use NetworkService
import 'package:nookly/domain/entities/matched_profile.dart';
import 'package:nookly/domain/repositories/matches_repository.dart';

class MatchesRepositoryImpl implements MatchesRepository {
  // No need for _dio, _authRepository, or _baseUrl here

  MatchesRepositoryImpl(); // Constructor can be empty or take NetworkService if preferred for testing

  @override
  Future<List<MatchedProfile>> getMatchedProfiles() async {
    try {
      // NetworkService interceptor handles token and base URL
      final response = await NetworkService.dio.get('/users/matches'); // Endpoint path

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> jsonData = response.data as List<dynamic>;
        return jsonData.map((json) => MatchedProfile.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Failed to load matched profiles: Status ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('DioError fetching matched profiles: ${e.response?.data ?? e.message}');
      throw Exception('Failed to load matched profiles: ${e.response?.data?['message'] ?? e.message}');
    } catch (e) {
      print('Error fetching matched profiles: $e');
      throw Exception('Failed to load matched profiles: An unexpected error occurred.');
    }
  }
} 