import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nookly/core/services/onboarding_service.dart';

void main() {
  group('OnboardingService', () {
    setUp(() async {
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    });

    test('shouldShowWelcomeTour should return true for fresh install', () async {
      final shouldShow = await OnboardingService.shouldShowWelcomeTour();
      expect(shouldShow, isTrue);
    });

    test('shouldShowWelcomeTour should return false after completion', () async {
      // Mark welcome tour as completed
      await OnboardingService.markWelcomeTourCompleted();
      
      final shouldShow = await OnboardingService.shouldShowWelcomeTour();
      expect(shouldShow, isFalse);
    });

    test('resetWelcomeTour should reset the welcome tour status', () async {
      // Mark welcome tour as completed
      await OnboardingService.markWelcomeTourCompleted();
      expect(await OnboardingService.shouldShowWelcomeTour(), isFalse);
      
      // Reset welcome tour
      await OnboardingService.resetWelcomeTour();
      expect(await OnboardingService.shouldShowWelcomeTour(), isTrue);
    });

    test('shouldShowMatchingTutorial should return true for fresh install', () async {
      final shouldShow = await OnboardingService.shouldShowMatchingTutorial();
      expect(shouldShow, isTrue);
    });

    test('shouldShowMatchingTutorial should return false after completion', () async {
      // Mark matching tutorial as completed
      await OnboardingService.markMatchingTutorialCompleted();
      
      final shouldShow = await OnboardingService.shouldShowMatchingTutorial();
      expect(shouldShow, isFalse);
    });

    test('resetAllTutorials should reset all tutorial statuses', () async {
      // Mark all tutorials as completed
      await OnboardingService.markWelcomeTourCompleted();
      await OnboardingService.markMatchingTutorialCompleted();
      await OnboardingService.markMessagingTutorialCompleted();
      await OnboardingService.markGamesTutorialCompleted();
      
      // Verify all are completed
      expect(await OnboardingService.shouldShowWelcomeTour(), isFalse);
      expect(await OnboardingService.shouldShowMatchingTutorial(), isFalse);
      expect(await OnboardingService.shouldShowMessagingTutorial(), isFalse);
      expect(await OnboardingService.shouldShowGamesTutorial(), isFalse);
      
      // Reset all tutorials
      await OnboardingService.resetAllTutorials();
      
      // Verify all are reset
      expect(await OnboardingService.shouldShowWelcomeTour(), isTrue);
      expect(await OnboardingService.shouldShowMatchingTutorial(), isTrue);
      expect(await OnboardingService.shouldShowMessagingTutorial(), isTrue);
      expect(await OnboardingService.shouldShowGamesTutorial(), isTrue);
    });
  });
}
