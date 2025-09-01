import 'package:flutter/material.dart';
import 'package:nookly/core/services/scam_alert_service.dart';

class ScamAlertPopup extends StatelessWidget {
  final ScamAlertType alertType;
  final VoidCallback? onDismiss;
  final VoidCallback? onReport;
  final VoidCallback? onLearnMore;

  const ScamAlertPopup({
    Key? key,
    required this.alertType,
    this.onDismiss,
    this.onReport,
    this.onLearnMore,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scamAlertService = ScamAlertService();
    final alertMessage = scamAlertService.getAlertMessage(alertType);
    final alertTitle = scamAlertService.getAlertTitle(alertType);
    final alertIcon = scamAlertService.getAlertIcon(alertType);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getAlertColor(alertType),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with icon and title
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getAlertColor(alertType).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Text(
                  alertIcon,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    alertTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: onDismiss,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          
          // Alert message
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              alertMessage,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontFamily: 'Nunito',
                height: 1.4,
              ),
              textAlign: TextAlign.left,
            ),
          ),
          
          // Action buttons
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: onReport,
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Report',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextButton(
                    onPressed: onLearnMore,
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Learn More',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getAlertColor(ScamAlertType type) {
    switch (type) {
      case ScamAlertType.romanceFinancial:
      case ScamAlertType.investmentCrypto:
      case ScamAlertType.loveBombing:
      case ScamAlertType.advanceFee:
        return const Color(0xFFE74C3C); // Red for high-risk scams
      
      case ScamAlertType.catfishing:
      case ScamAlertType.militaryImpersonation:
      case ScamAlertType.personalInfoRequest:
        return const Color(0xFFF39C12); // Orange for medium-risk
      
      case ScamAlertType.offPlatform:
      case ScamAlertType.videoCallVerification:
        return const Color(0xFF3498DB); // Blue for safety tips
    }
  }
}

