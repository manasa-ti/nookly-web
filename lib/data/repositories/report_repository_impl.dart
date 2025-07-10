import 'package:dio/dio.dart';
import 'package:nookly/core/network/network_service.dart';
import 'package:nookly/core/utils/logger.dart';
import 'package:nookly/data/models/report/report_reasons_response.dart';
import 'package:nookly/data/models/report/report_request.dart';
import 'package:nookly/data/models/report/report_response.dart';
import 'package:nookly/domain/repositories/report_repository.dart';

class ReportRepositoryImpl implements ReportRepository {
  @override
  Future<List<String>> getReportReasons() async {
    try {
      AppLogger.info('🔍 Fetching report reasons from API');
      final response = await NetworkService.dio.get('/reports/reasons');
      
      final reportReasonsResponse = ReportReasonsResponse.fromJson(response.data);
      AppLogger.info('✅ Successfully fetched ${reportReasonsResponse.reasons.length} report reasons');
      
      return reportReasonsResponse.reasons;
    } on DioException catch (e) {
      AppLogger.error(
        '❌ Failed to fetch report reasons: ${e.message}',
        e,
        StackTrace.current,
      );
      throw Exception('Failed to fetch report reasons: ${e.response?.data?['message'] ?? e.message}');
    } catch (e) {
      AppLogger.error(
        '❌ Unexpected error fetching report reasons: $e',
        e,
        StackTrace.current,
      );
      throw Exception('Failed to fetch report reasons: An unexpected error occurred');
    }
  }

  @override
  Future<Map<String, dynamic>> reportUser({
    required String reportedUserId,
    required String reason,
    String? details,
  }) async {
    try {
      AppLogger.info('🚨 Submitting report for user: $reportedUserId');
      AppLogger.info('🚨 Report reason: $reason');
      
      final request = ReportRequest(
        reportedUserId: reportedUserId,
        reason: reason,
        details: details,
      );
      
      final response = await NetworkService.dio.post(
        '/reports/user',
        data: request.toJson(),
      );
      
      final reportResponse = ReportResponse.fromJson(response.data);
      AppLogger.info('✅ Report submitted successfully: ${reportResponse.message}');
      AppLogger.info('✅ Unique reporters: ${reportResponse.uniqueReporters}');
      AppLogger.info('✅ User banned: ${reportResponse.isBanned}');
      
      return {
        'message': reportResponse.message,
        'uniqueReporters': reportResponse.uniqueReporters,
        'isBanned': reportResponse.isBanned,
      };
    } on DioException catch (e) {
      AppLogger.error(
        '❌ Failed to submit report: ${e.message}',
        e,
        StackTrace.current,
      );
      
      // Handle specific error cases based on API documentation
      if (e.response?.statusCode == 400) {
        final errorMessage = e.response?.data?['message'] ?? 'Invalid request';
        throw Exception(errorMessage);
      } else if (e.response?.statusCode == 404) {
        throw Exception('User not found');
      } else if (e.response?.statusCode == 409) {
        throw Exception('You have already reported this user');
      } else if (e.response?.statusCode == 429) {
        throw Exception('Too many reports. Please try again later.');
      } else {
        throw Exception('Failed to submit report: ${e.response?.data?['message'] ?? e.message}');
      }
    } catch (e) {
      AppLogger.error(
        '❌ Unexpected error submitting report: $e',
        e,
        StackTrace.current,
      );
      throw Exception('Failed to submit report: An unexpected error occurred');
    }
  }
} 