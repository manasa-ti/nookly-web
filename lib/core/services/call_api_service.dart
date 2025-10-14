import 'package:dio/dio.dart';
import 'package:nookly/core/utils/logger.dart';

/// Service for handling call-related API requests
/// Communicates with backend for call initiation, acceptance, rejection, and management
class CallApiService {
  final Dio _dio;

  CallApiService(this._dio);

  /// Initiate a call with another user
  /// Returns call session data and HMS tokens for both caller and receiver
  Future<Map<String, dynamic>> initiateCall({
    required String receiverId,
    required String callType,
  }) async {
    try {
      AppLogger.info('🚀 Initiating $callType call with user: $receiverId');
      
      final response = await _dio.post(
        '/calls/initiate',
        data: {
          'receiverId': receiverId,
          'callType': callType,
        },
      );

      AppLogger.info('✅ Call initiated successfully');
      AppLogger.info('📊 Backend response: ${response.data}');
      return response.data;
    } catch (e) {
      AppLogger.error('❌ Failed to initiate call: $e');
      rethrow;
    }
  }

  /// Accept an incoming call
  /// Returns call session data and HMS token for the receiver
  Future<Map<String, dynamic>> acceptCall({
    required String roomId,
  }) async {
    try {
      AppLogger.info('✅ Accepting call for room: $roomId');
      
      final response = await _dio.post(
        '/calls/accept',
        data: {
          'roomId': roomId,
        },
      );

      AppLogger.info('✅ Call accepted successfully');
      AppLogger.info('📊 Backend response: ${response.data}');
      return response.data;
    } catch (e) {
      AppLogger.error('❌ Failed to accept call: $e');
      rethrow;
    }
  }

  /// End an active call
  /// Notifies backend to cleanup call session and notify other participant
  Future<Map<String, dynamic>> endCall({
    required String roomId,
  }) async {
    try {
      AppLogger.info('🔚 Ending call for room: $roomId');
      
      final response = await _dio.post(
        '/calls/end',
        data: {
          'roomId': roomId,
        },
      );

      AppLogger.info('✅ Call ended successfully');
      return response.data;
    } catch (e) {
      AppLogger.error('❌ Failed to end call: $e');
      rethrow;
    }
  }

  /// Reject an incoming call
  /// Notifies backend to update call status and notify caller
  Future<Map<String, dynamic>> rejectCall({
    required String roomId,
  }) async {
    try {
      AppLogger.info('❌ Rejecting call for room: $roomId');
      
      final response = await _dio.post(
        '/calls/reject',
        data: {
          'roomId': roomId,
        },
      );

      AppLogger.info('✅ Call rejected successfully');
      return response.data;
    } catch (e) {
      AppLogger.error('❌ Failed to reject call: $e');
      rethrow;
    }
  }

  /// Get call history with pagination
  /// Returns list of past calls and pagination info
  Future<Map<String, dynamic>> getCallHistory({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      AppLogger.info('📋 Fetching call history (page: $page, limit: $limit)');
      
      final response = await _dio.get(
        '/calls/history',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      AppLogger.info('✅ Call history retrieved successfully');
      return response.data;
    } catch (e) {
      AppLogger.error('❌ Failed to get call history: $e');
      rethrow;
    }
  }

  /// Get active call session if any
  /// Returns current active call data or null
  Future<Map<String, dynamic>> getActiveCall() async {
    try {
      AppLogger.info('🔍 Checking for active call');
      
      final response = await _dio.get('/calls/active');

      AppLogger.info('✅ Active call status retrieved');
      return response.data;
    } catch (e) {
      AppLogger.error('❌ Failed to get active call: $e');
      rethrow;
    }
  }
}

