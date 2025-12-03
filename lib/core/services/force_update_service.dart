import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:nookly/core/services/remote_config_service.dart';
import 'package:nookly/core/utils/version_utils.dart';
import 'package:nookly/core/utils/logger.dart';
import 'package:nookly/domain/entities/user.dart';
import 'package:nookly/presentation/widgets/force_update_dialog.dart';

/// Service to check app version and show force update dialog if needed
class ForceUpdateService {
  final RemoteConfigService _remoteConfigService;

  ForceUpdateService(this._remoteConfigService);

  /// Check if force update is needed and show dialog if required
  /// 
  /// [context] - BuildContext to show dialog
  /// [user] - User object containing minAppVersion
  /// Returns true if force update is required (dialog shown), false otherwise
  Future<bool> checkAndShowForceUpdateIfNeeded(
    BuildContext context,
    User? user,
  ) async {
    // If user is null or minAppVersion is null/empty, no force update needed
    if (user == null || user.minAppVersion == null || user.minAppVersion!.isEmpty) {
      AppLogger.info('No force update required: user or minAppVersion is null/empty');
      return false;
    }

    try {
      // Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
      final minimumVersion = user.minAppVersion!;

      AppLogger.info('Checking app version: current=$currentVersion, minimum=$minimumVersion');

      // Check if current version is sufficient
      final isSufficient = VersionUtils.isVersionSufficient(currentVersion, minimumVersion);

      if (!isSufficient) {
        AppLogger.warning('Force update required: current version $currentVersion is less than minimum $minimumVersion');
        
        // Get store links from Remote Config
        final androidLink = _remoteConfigService.getAndroidAppLink();
        final iosLink = _remoteConfigService.getIosAppLink();

        AppLogger.info('Store links - Android: $androidLink, iOS: $iosLink');

        // Show force update dialog
        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => ForceUpdateDialog(
              androidAppLink: androidLink,
              iosAppLink: iosLink,
            ),
          );
        }

        return true; // Force update is required
      } else {
        AppLogger.info('App version is sufficient, no force update needed');
        return false; // No force update needed
      }
    } catch (e) {
      AppLogger.error('Error checking force update', e);
      // On error, allow app to continue (graceful degradation)
      return false;
    }
  }
}

