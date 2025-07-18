import 'package:nookly/core/utils/logger.dart';

class ContentModerationService {
  static final ContentModerationService _instance = ContentModerationService._internal();
  factory ContentModerationService() => _instance;
  ContentModerationService._internal();

  // Prohibited keywords for dating apps
  static const List<String> _prohibitedKeywords = [
    // Spam and scams
    'spam', 'scam', 'money', 'bitcoin', 'investment', 'crypto', 'forex', 'trading',
    'earn money', 'make money', 'quick cash', 'get rich', 'millionaire',
    
    // Harassment and threats
    'kill', 'murder', 'threat', 'harass', 'stalk', 'bully', 'abuse',
    'hate', 'racist', 'sexist', 'discriminate',
    
    // Violence
    'violence', 'fight', 'attack', 'weapon', 'gun', 'knife', 'bomb',
    'terrorist', 'extremist',
    
    // Drugs and illegal activities
    'drugs', 'cocaine', 'heroin', 'marijuana', 'weed', 'pills', 'illegal',
    'smuggling', 'trafficking',
    
    // Sexual content (inappropriate for dating apps)
    'porn', 'nude', 'naked', 'sex', 'sexual', 'adult content', 'explicit',
    'escort', 'prostitute', 'hooker',
    
    // Underage content
    'underage', 'minor', 'teen', 'child', 'pedo', 'pedophile',
    
    // Personal information
    'phone number', 'address', 'social security', 'credit card', 'bank account',
    'password', 'email address',
    
    // Dating app specific violations
    'fake profile', 'catfish', 'scam profile', 'bot', 'automated',
    'commercial', 'business', 'advertisement', 'promote',
  ];

  // Suspicious patterns that might indicate spam
  static const List<String> _suspiciousPatterns = [
    r'\b\d{10,}\b', // Long numbers (phone numbers, etc.)
    r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b', // Email addresses
    r'\bhttps?://\S+\b', // URLs
    r'\b\d{4}[- ]?\d{4}[- ]?\d{4}[- ]?\d{4}\b', // Credit card patterns
  ];

  /// Check if text contains prohibited content
  bool containsProhibitedContent(String text) {
    if (text.isEmpty) return false;
    
    final lowerText = text.toLowerCase();
    
    // Check for prohibited keywords
    for (final keyword in _prohibitedKeywords) {
      if (lowerText.contains(keyword.toLowerCase())) {
        AppLogger.warning('Content moderation: Prohibited keyword detected: $keyword');
        return true;
      }
    }
    
    // Check for suspicious patterns
    for (final pattern in _suspiciousPatterns) {
      final regex = RegExp(pattern, caseSensitive: false);
      if (regex.hasMatch(text)) {
        AppLogger.warning('Content moderation: Suspicious pattern detected: $pattern');
        return true;
      }
    }
    
    return false;
  }

  /// Filter text by replacing prohibited words with asterisks
  String filterText(String text) {
    if (text.isEmpty) return text;
    
    String filteredText = text;
    
    // Replace prohibited keywords with asterisks
    for (final keyword in _prohibitedKeywords) {
      final regex = RegExp(keyword, caseSensitive: false);
      filteredText = filteredText.replaceAll(regex, '*' * keyword.length);
    }
    
    return filteredText;
  }

  /// Check if text is appropriate for profile bio
  bool isAppropriateBio(String text) {
    if (text.isEmpty) return true;
    
    // Additional checks for profile bios
    final lowerText = text.toLowerCase();
    
    // Check for excessive personal information
    final personalInfoPatterns = [
      r'\b\d{3}[-.]?\d{3}[-.]?\d{4}\b', // Phone numbers
      r'\b\d{5}[- ]?\d{4}\b', // ZIP codes
      r'\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b', // IP addresses
    ];
    
    for (final pattern in personalInfoPatterns) {
      final regex = RegExp(pattern);
      if (regex.hasMatch(text)) {
        AppLogger.warning('Content moderation: Personal information detected in bio');
        return false;
      }
    }
    
    // Check for commercial content
    final commercialKeywords = [
      'buy', 'sell', 'promote', 'advertisement', 'commercial', 'business',
      'company', 'website', 'link', 'click here', 'visit', 'check out',
    ];
    
    for (final keyword in commercialKeywords) {
      if (lowerText.contains(keyword)) {
        AppLogger.warning('Content moderation: Commercial content detected in bio');
        return false;
      }
    }
    
    return !containsProhibitedContent(text);
  }

  /// Check if text is appropriate for chat messages
  bool isAppropriateMessage(String text) {
    if (text.isEmpty) return true;
    
    // Additional checks for chat messages
    final lowerText = text.toLowerCase();
    
    // Check for spam patterns
    final spamPatterns = [
      r'\b(hi|hello|hey)\s+(hi|hello|hey)\s+(hi|hello|hey)\b', // Repeated greetings
      r'\b(.)\1{10,}\b', // Repeated characters
      r'\b\w+\s+\w+\s+\w+\s+\w+\s+\w+\s+\w+\s+\w+\s+\w+\s+\w+\s+\w+\b', // Very long words
    ];
    
    for (final pattern in spamPatterns) {
      final regex = RegExp(pattern, caseSensitive: false);
      if (regex.hasMatch(text)) {
        AppLogger.warning('Content moderation: Spam pattern detected in message');
        return false;
      }
    }
    
    // Check for excessive caps
    final capsCount = text.replaceAll(RegExp(r'[^A-Z]'), '').length;
    final totalChars = text.replaceAll(RegExp(r'[^a-zA-Z]'), '').length;
    if (totalChars > 0 && (capsCount / totalChars) > 0.7) {
      AppLogger.warning('Content moderation: Excessive caps detected in message');
      return false;
    }
    
    return !containsProhibitedContent(text);
  }

  /// Get moderation result with details
  ModerationResult moderateContent(String text, ContentType type) {
    if (text.isEmpty) {
      return ModerationResult(
        isAppropriate: true,
        filteredText: text,
        reason: null,
      );
    }

    bool isAppropriate = false;
    String? reason;

    switch (type) {
      case ContentType.message:
        isAppropriate = isAppropriateMessage(text);
        if (!isAppropriate) {
          reason = 'Message contains inappropriate content';
        }
        break;
      case ContentType.bio:
        isAppropriate = isAppropriateBio(text);
        if (!isAppropriate) {
          reason = 'Bio contains inappropriate content';
        }
        break;
      case ContentType.name:
        isAppropriate = !containsProhibitedContent(text);
        if (!isAppropriate) {
          reason = 'Name contains inappropriate content';
        }
        break;
    }

    final filteredText = isAppropriate ? text : filterText(text);

    return ModerationResult(
      isAppropriate: isAppropriate,
      filteredText: filteredText,
      reason: reason,
    );
  }

  /// Report inappropriate content (for logging and analytics)
  void reportInappropriateContent(String text, ContentType type, String userId) {
    AppLogger.warning('Content moderation: Inappropriate content reported');
    AppLogger.warning('User ID: $userId');
    AppLogger.warning('Content type: $type');
    AppLogger.warning('Content: $text');
    
    // TODO: Send to backend for analysis and potential user action
    // This could trigger manual review or automatic user suspension
  }
}

/// Types of content that can be moderated
enum ContentType {
  message,
  bio,
  name,
}

/// Result of content moderation
class ModerationResult {
  final bool isAppropriate;
  final String filteredText;
  final String? reason;

  const ModerationResult({
    required this.isAppropriate,
    required this.filteredText,
    this.reason,
  });
} 