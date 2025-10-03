import 'package:shared_preferences/shared_preferences.dart';
import 'package:nookly/core/utils/logger.dart';

class OnboardingService {
  static const String _welcomeTourKey = 'welcome_tour_completed';
  static const String _matchingTutorialKey = 'matching_tutorial_completed';
  static const String _messagingTutorialKey = 'messaging_tutorial_completed';
  static const String _gamesTutorialKey = 'games_tutorial_completed';
  static const String _conversationStarterTutorialKey = 'conversation_starter_tutorial_completed';

  static Future<bool> shouldShowWelcomeTour() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isCompleted = prefs.getBool(_welcomeTourKey);
      print('🔵 ONBOARDING: shouldShowWelcomeTour - isCompleted: $isCompleted');
      print('🔵 ONBOARDING: shouldShowWelcomeTour - returning: ${isCompleted != true}');
      return isCompleted != true;
    } catch (e) {
      AppLogger.error('Error checking welcome tour status: $e');
      print('🔵 ONBOARDING: Error occurred, returning true to show tour');
      return true; // Show tour if error
    }
  }

  static Future<bool> shouldShowMatchingTutorial() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isCompleted = prefs.getBool(_matchingTutorialKey);
      print('🔵 ONBOARDING: shouldShowMatchingTutorial - isCompleted: $isCompleted');
      print('🔵 ONBOARDING: shouldShowMatchingTutorial - returning: ${isCompleted != true}');
      return isCompleted != true;
    } catch (e) {
      AppLogger.error('Error checking matching tutorial status: $e');
      print('🔵 ONBOARDING: Error occurred, returning true to show tutorial');
      return true; // Show tutorial if error
    }
  }

  static Future<bool> shouldShowMessagingTutorial() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isCompleted = prefs.getBool(_messagingTutorialKey);
      return isCompleted != true;
    } catch (e) {
      AppLogger.error('Error checking messaging tutorial status: $e');
      return true; // Show tutorial if error
    }
  }

  static Future<bool> shouldShowGamesTutorial() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isCompleted = prefs.getBool(_gamesTutorialKey);
      return isCompleted != true;
    } catch (e) {
      AppLogger.error('Error checking games tutorial status: $e');
      return true; // Show tutorial if error
    }
  }

  static Future<bool> shouldShowConversationStarterTutorial() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isCompleted = prefs.getBool(_conversationStarterTutorialKey);
      return isCompleted != true;
    } catch (e) {
      AppLogger.error('Error checking conversation starter tutorial status: $e');
      return true; // Show tutorial if error
    }
  }

  static Future<bool> isConversationStarterTutorialCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isCompleted = prefs.getBool(_conversationStarterTutorialKey);
      return isCompleted == true;
    } catch (e) {
      AppLogger.error('Error checking conversation starter tutorial completion status: $e');
      return false; // Assume not completed if error
    }
  }

  static Future<void> markWelcomeTourCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_welcomeTourKey, true);
      AppLogger.info('Welcome tour marked as completed');
    } catch (e) {
      AppLogger.error('Error marking welcome tour as completed: $e');
    }
  }

  static Future<void> markMatchingTutorialCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_matchingTutorialKey, true);
      AppLogger.info('Matching tutorial marked as completed');
    } catch (e) {
      AppLogger.error('Error marking matching tutorial as completed: $e');
    }
  }

  static Future<void> markMessagingTutorialCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_messagingTutorialKey, true);
      AppLogger.info('Messaging tutorial marked as completed');
    } catch (e) {
      AppLogger.error('Error marking messaging tutorial as completed: $e');
    }
  }

  static Future<void> markGamesTutorialCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_gamesTutorialKey, true);
      AppLogger.info('Games tutorial marked as completed');
    } catch (e) {
      AppLogger.error('Error marking games tutorial as completed: $e');
    }
  }

  static Future<void> markConversationStarterTutorialCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_conversationStarterTutorialKey, true);
      AppLogger.info('Conversation starter tutorial marked as completed');
    } catch (e) {
      AppLogger.error('Error marking conversation starter tutorial as completed: $e');
    }
  }

  // For testing purposes - reset all tutorials
  static Future<void> resetAllTutorials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_welcomeTourKey);
      await prefs.remove(_matchingTutorialKey);
      await prefs.remove(_messagingTutorialKey);
      await prefs.remove(_gamesTutorialKey);
      await prefs.remove(_conversationStarterTutorialKey);
      AppLogger.info('All tutorials reset');
      print('🔵 ONBOARDING: All tutorials reset successfully');
    } catch (e) {
      AppLogger.error('Error resetting tutorials: $e');
      print('🔵 ONBOARDING: Error resetting tutorials: $e');
    }
  }

  // For testing purposes - reset only welcome tour
  static Future<void> resetWelcomeTour() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_welcomeTourKey);
      AppLogger.info('Welcome tour reset');
      print('🔵 ONBOARDING: Welcome tour reset successfully');
    } catch (e) {
      AppLogger.error('Error resetting welcome tour: $e');
      print('🔵 ONBOARDING: Error resetting welcome tour: $e');
    }
  }
}
