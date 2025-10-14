import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:nookly/core/network/network_service.dart';
import 'package:nookly/core/utils/logger.dart';

class NotificationRepository {
  NotificationRepository();
  
  /// Register device FCM token with backend
  Future<bool> registerDevice() async {
    try {
      // Get FCM token
      final FirebaseMessaging messaging = FirebaseMessaging.instance;
      final String? fcmToken = await messaging.getToken();
      
      if (fcmToken == null) {
        AppLogger.warning('⚠️ FCM token is null, cannot register device');
        return false;
      }
      
      // Detect platform
      final platform = Platform.isAndroid ? 'android' : Platform.isIOS ? 'ios' : 'web';
      
      AppLogger.info('📱 Registering device: platform=$platform');
      
      // Register with backend
      final response = await NetworkService.dio.post(
        '/notifications/register-device',
        data: {
          'fcmToken': fcmToken,
          'platform': platform,
        },
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        AppLogger.info('✅ Device registered successfully');
        AppLogger.info('Device info: ${response.data['device']}');
        return true;
      }
      
      AppLogger.warning('⚠️ Unexpected status code: ${response.statusCode}');
      return false;
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 409) {
        AppLogger.info('ℹ️ Device already registered');
        return true; // Already registered is still success
        }
        AppLogger.error('❌ Error registering device: ${e.response?.data}');
      } else {
        AppLogger.error('❌ Error registering device: $e');
      }
      return false;
    }
  }
  
  /// Unregister device FCM token (logout)
  Future<bool> unregisterDevice() async {
    try {
      final FirebaseMessaging messaging = FirebaseMessaging.instance;
      final String? fcmToken = await messaging.getToken();
      
      if (fcmToken == null) {
        AppLogger.warning('⚠️ FCM token is null, cannot unregister device');
        return false;
      }
      
      AppLogger.info('📱 Unregistering device');
      
      final response = await NetworkService.dio.post(
        '/notifications/unregister-device',
        data: {
          'fcmToken': fcmToken,
        },
      );
      
      if (response.statusCode == 200) {
        AppLogger.info('✅ Device unregistered successfully');
        
        // Delete FCM token locally
        await messaging.deleteToken();
        AppLogger.info('✅ FCM token deleted locally');
        
        return true;
      }
      
      AppLogger.warning('⚠️ Unexpected status code: ${response.statusCode}');
      return false;
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 404) {
          AppLogger.info('ℹ️ Device not found (already unregistered)');
          return true; // Already unregistered is still success
        }
        AppLogger.error('❌ Error unregistering device: ${e.response?.data}');
      } else {
        AppLogger.error('❌ Error unregistering device: $e');
      }
      return false;
    }
  }
  
  /// Get list of user's registered devices
  Future<List<Map<String, dynamic>>> getUserDevices() async {
    try {
      AppLogger.info('📱 Fetching user devices');
      
      final response = await NetworkService.dio.get('/notifications/devices');
      
      if (response.statusCode == 200) {
        final data = response.data;
        final devices = (data['devices'] as List)
            .map((device) => device as Map<String, dynamic>)
            .toList();
        
        AppLogger.info('✅ Retrieved ${devices.length} devices');
        return devices;
      }
      
      AppLogger.warning('⚠️ Unexpected status code: ${response.statusCode}');
      return [];
    } catch (e) {
      AppLogger.error('❌ Error fetching devices: $e');
      return [];
    }
  }
  
  /// Send test notification
  Future<bool> sendTestNotification({
    String? title,
    String? body,
  }) async {
    try {
      AppLogger.info('📨 Sending test notification');
      
      final response = await NetworkService.dio.post(
        '/notifications/test',
        data: {
          if (title != null) 'title': title,
          if (body != null) 'body': body,
          'type': 'test',
        },
      );
      
      if (response.statusCode == 200) {
        AppLogger.info('✅ Test notification sent successfully');
        AppLogger.info('Result: ${response.data['result']}');
        return true;
      }
      
      AppLogger.warning('⚠️ Unexpected status code: ${response.statusCode}');
      return false;
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 503) {
          AppLogger.error('❌ Push notification service unavailable');
        } else {
          AppLogger.error('❌ Error sending test notification: ${e.response?.data}');
        }
      } else {
        AppLogger.error('❌ Error sending test notification: $e');
      }
      return false;
    }
  }
  
  /// Handle FCM token refresh
  Future<void> onTokenRefresh(String newToken) async {
    AppLogger.info('🔄 FCM token refreshed');
    
    // Re-register device with new token
    final success = await registerDevice();
    
    if (success) {
      AppLogger.info('✅ Device re-registered with new token');
    } else {
      AppLogger.warning('⚠️ Failed to re-register device with new token');
    }
  }
}

