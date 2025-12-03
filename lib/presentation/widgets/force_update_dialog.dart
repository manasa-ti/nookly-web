import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:nookly/core/theme/app_colors.dart';
import 'package:nookly/core/utils/logger.dart';

/// Non-dismissible dialog that forces user to update the app
/// Blocks all navigation until user updates the app
class ForceUpdateDialog extends StatelessWidget {
  final String androidAppLink;
  final String iosAppLink;

  const ForceUpdateDialog({
    super.key,
    required this.androidAppLink,
    required this.iosAppLink,
  });

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Prevent dialog from being dismissed
        return false;
      },
      child: AlertDialog(
        title: const Text(
          'Update Required',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
        ),
        content: const Text(
          'A new version of the app is available. Please update to continue using the app.',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => _openAppStore(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Update App',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openAppStore(BuildContext context) async {
    try {
      String? storeUrl;
      
      if (Platform.isAndroid) {
        storeUrl = androidAppLink.isNotEmpty ? androidAppLink : null;
      } else if (Platform.isIOS) {
        storeUrl = iosAppLink.isNotEmpty ? iosAppLink : null;
      }

      if (storeUrl == null || storeUrl.isEmpty) {
        AppLogger.warning('Store URL not available for platform: ${Platform.operatingSystem}');
        _showErrorDialog(context);
        return;
      }

      final uri = Uri.parse(storeUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        AppLogger.info('Opened app store: $storeUrl');
      } else {
        AppLogger.error('Could not launch URL: $storeUrl');
        _showErrorDialog(context);
      }
    } catch (e) {
      AppLogger.error('Error opening app store', e);
      _showErrorDialog(context);
    }
  }

  void _showErrorDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: const Text(
          'Unable to open app store. Please update the app manually from your device\'s app store.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

