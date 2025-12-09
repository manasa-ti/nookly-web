import 'package:nookly/core/utils/logger.dart';

class ScamAlertService {
  static final ScamAlertService _instance = ScamAlertService._internal();
  factory ScamAlertService() => _instance;
  ScamAlertService._internal() {
    AppLogger.info('🔧 ScamAlertService initialized');
  }

  // Scam patterns and keywords
  static const Map<String, List<String>> _scamPatterns = {
    'romance_financial': [
      'money', 'emergency', 'hospital', 'medical', 'bills', 'rent', 'loan',
      'gift card', 'western union', 'moneygram', 'bitcoin', 'crypto',
      'need help', 'financial', 'bank account', 'credit card', 'paypal',
      'venmo', 'cash app', 'urgent', 'desperate', 'please help',
      'family emergency', 'sick', 'treatment', 'medicine', 'operation'
    ],
    'investment_crypto': [
      'investment', 'crypto', 'bitcoin', 'ethereum', 'trading', 'profit',
      'opportunity', 'investment platform', 'forex', 'stocks', 'earn money',
      'quick money', 'guaranteed returns', 'trading bot', 'mining',
      'blockchain', 'defi', 'nft', 'token', 'ico', 'airdrop'
    ],
    'off_platform': [
      'whatsapp', 'telegram', 'instagram', 'facebook', 'snapchat', 'kik',
      'line', 'wechat', 'viber', 'signal', 'discord', 'skype',
      'move to', 'add me on', 'contact me on', 'my number is',
      'call me', 'text me', 'my phone', 'personal contact'
    ],
    'military_impersonation': [
      'military', 'army', 'navy', 'air force', 'marine', 'soldier',
      'deployed', 'overseas', 'mission', 'base', 'rank', 'officer',
      'serving', 'veteran', 'combat', 'war zone', 'afghanistan', 'iraq',
      'syria', 'deployment', 'leave', 'discharge'
    ],
    'love_bombing': [
      'love you', 'i love you', 'soulmate', 'destiny', 'meant to be',
      'perfect match', 'love at first sight', 'my everything', 'forever',
      'marry', 'marriage', 'future together', 'our future', 'soul mate',
      'true love', 'perfect for me', 'never felt this way', 'special connection'
    ],
    'personal_info_request': [
      'address', 'workplace', 'job', 'company', 'salary', 'income',
      'social security', 'ssn', 'passport', 'id', 'driver license',
      'bank details', 'account number', 'routing number', 'mother maiden',
      'birth place', 'full name', 'real name', 'phone number'
    ],
    'advance_fee': [
      'inheritance', 'lottery', 'prize', 'winning', 'million', 'fortune',
      'legal fees', 'processing fee', 'tax', 'customs', 'shipping',
      'advance payment', 'upfront', 'deposit', 'escrow', 'lawyer fee',
      'government fee', 'clearance fee', 'transfer fee'
    ]
  };

  // Video call avoidance patterns
  static const List<String> _videoCallAvoidance = [
    'no video', 'camera broken', 'no camera', 'don\'t like video',
    'prefer voice', 'video call later', 'not comfortable with video',
    'my camera doesn\'t work', 'technical issues', 'bad internet',
    'video quality poor', 'rather not video call', 'voice call instead'
  ];

  // Message analysis methods
  ScamAlertType? analyzeMessage(String message, {int messageCount = 0}) {
    final lowerMessage = message.toLowerCase();
    
    AppLogger.info('🔍 Analyzing message: "$message"');
    AppLogger.info('🔍 Lowercase: "$lowerMessage"');
    
    // Check for video call avoidance (catfishing)
    if (_videoCallAvoidance.any((pattern) => lowerMessage.contains(pattern))) {
      AppLogger.info('🚨 Catfishing pattern detected');
      return ScamAlertType.catfishing;
    }

    // Check for romance/financial scams
    for (final pattern in _scamPatterns['romance_financial']!) {
      if (lowerMessage.contains(pattern)) {
        AppLogger.info('🚨 Romance/Financial pattern detected: "$pattern" in "$lowerMessage"');
        return ScamAlertType.romanceFinancial;
      }
    }

    // Check for investment/crypto scams
    if (_scamPatterns['investment_crypto']!.any((pattern) => lowerMessage.contains(pattern))) {
      AppLogger.info('🚨 Investment/Crypto pattern detected');
      return ScamAlertType.investmentCrypto;
    }

    // Check for off-platform communication
    for (final pattern in _scamPatterns['off_platform']!) {
      if (lowerMessage.contains(pattern)) {
        AppLogger.info('🚨 Off-platform pattern detected: "$pattern" in "$lowerMessage"');
        return ScamAlertType.offPlatform;
      }
    }

    // Check for military impersonation
    if (_scamPatterns['military_impersonation']!.any((pattern) => lowerMessage.contains(pattern))) {
      AppLogger.info('🚨 Military impersonation pattern detected');
      return ScamAlertType.militaryImpersonation;
    }

    // Check for love bombing
    if (_scamPatterns['love_bombing']!.any((pattern) => lowerMessage.contains(pattern))) {
      AppLogger.info('🚨 Love bombing pattern detected');
      return ScamAlertType.loveBombing;
    }

    // Check for personal info requests
    if (_scamPatterns['personal_info_request']!.any((pattern) => lowerMessage.contains(pattern))) {
      AppLogger.info('🚨 Personal info request pattern detected');
      return ScamAlertType.personalInfoRequest;
    }

    // Check for advance fee scams
    if (_scamPatterns['advance_fee']!.any((pattern) => lowerMessage.contains(pattern))) {
      AppLogger.info('🚨 Advance fee pattern detected');
      return ScamAlertType.advanceFee;
    }

    // Check for timing-based alerts
    if (messageCount >= 10) {
      AppLogger.info('🚨 Video call verification suggested');
      return ScamAlertType.videoCallVerification;
    }

    AppLogger.info('🔍 No scam pattern detected');
    return null;
  }

  // Get alert message based on type
  String getAlertMessage(ScamAlertType type) {
    switch (type) {
      case ScamAlertType.romanceFinancial:
        return "🚨 **Scam Alert**: Never send money, gift cards, or personal financial information to someone you've met online. Legitimate connections won't ask for financial help.";
      
      case ScamAlertType.catfishing:
        return "⚠️ **Stay Safe**: Be cautious of connections who avoid video calls. Consider having a video call to verify your connection's identity before meeting.";
      
      case ScamAlertType.offPlatform:
        return "🛡️ **Safety Tip**: Keep conversations on our platform initially. Be wary of connections who immediately want to move to other apps or request personal contact info.";
      
      case ScamAlertType.investmentCrypto:
        return "🚨 **Investment Scam Warning**: Never invest money based on advice from online connections. These are common scams targeting dating app users.";
      
      case ScamAlertType.militaryImpersonation:
        return "⚠️ **Verification Needed**: Be cautious of profiles claiming military service or overseas work. Verify claims and never send money for 'emergencies'.";
      
      case ScamAlertType.loveBombing:
        return "🚨 **Red Flag**: Be cautious of connections who express intense love very quickly or seem 'too good to be true'. Take relationships slow.";
      
      case ScamAlertType.personalInfoRequest:
        return "🔒 **Protect Yourself**: Never share personal information like your address, workplace, financial details, or passwords with online connections.";
      
      case ScamAlertType.advanceFee:
        return "🚨 **Advance Fee Scam**: Be wary of promises of large sums of money requiring upfront payments. These are almost always scams.";
      
      case ScamAlertType.videoCallVerification:
        return "✅ **Verify Your Match**: Consider having a video call before meeting in person to confirm your match is who they claim to be.";
    }
  }

  // Get alert title based on type
  String getAlertTitle(ScamAlertType type) {
    switch (type) {
      case ScamAlertType.romanceFinancial:
        return "Financial Scam Alert";
      case ScamAlertType.catfishing:
        return "Video Call Warning";
      case ScamAlertType.offPlatform:
        return "Platform Safety";
      case ScamAlertType.investmentCrypto:
        return "Investment Scam";
      case ScamAlertType.militaryImpersonation:
        return "Identity Verification";
      case ScamAlertType.loveBombing:
        return "Love Bombing Warning";
      case ScamAlertType.personalInfoRequest:
        return "Privacy Protection";
      case ScamAlertType.advanceFee:
        return "Advance Fee Scam";
      case ScamAlertType.videoCallVerification:
        return "Verification Suggestion";
    }
  }

  // Get alert icon based on type
  String getAlertIcon(ScamAlertType type) {
    switch (type) {
      case ScamAlertType.romanceFinancial:
        return "🚨";
      case ScamAlertType.catfishing:
        return "⚠️";
      case ScamAlertType.offPlatform:
        return "🛡️";
      case ScamAlertType.investmentCrypto:
        return "🚨";
      case ScamAlertType.militaryImpersonation:
        return "⚠️";
      case ScamAlertType.loveBombing:
        return "🚨";
      case ScamAlertType.personalInfoRequest:
        return "🔒";
      case ScamAlertType.advanceFee:
        return "🚨";
      case ScamAlertType.videoCallVerification:
        return "✅";
    }
  }

  // Check if alert should be shown (to avoid spam)
  bool shouldShowAlert(ScamAlertType type, String conversationId, DateTime lastShown) {
    final now = DateTime.now();
    final timeSinceLastShown = now.difference(lastShown);
    
    // Don't show same alert more than once per hour
    if (timeSinceLastShown.inHours < 1) {
      return false;
    }
    
    return true;
  }
}

enum ScamAlertType {
  romanceFinancial,
  catfishing,
  offPlatform,
  investmentCrypto,
  militaryImpersonation,
  loveBombing,
  personalInfoRequest,
  advanceFee,
  videoCallVerification,
}
