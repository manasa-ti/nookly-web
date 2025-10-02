import 'package:flutter_test/flutter_test.dart';
import 'package:nookly/core/services/disappearing_image_manager.dart';
import 'dart:async';

void main() {
  group('DisappearingImageManager Tests', () {
    late DisappearingImageManager manager;
    late List<String> expiredImages;

    setUp(() {
      expiredImages = [];
      manager = DisappearingImageManager(
        onImageExpired: (messageId) {
          expiredImages.add(messageId);
        },
      );
    });

    tearDown(() {
      manager.dispose();
    });

    group('Timer Management', () {
      test('should start timer for disappearing image', () {
        const messageId = 'msg1';
        const disappearingTime = 5;

        manager.startTimer(messageId, disappearingTime);

        final timerState = manager.getTimerState(messageId);
        expect(timerState, isNotNull);
        expect(timerState!.messageId, equals(messageId));
        expect(timerState.remainingTime, equals(disappearingTime));
        expect(timerState.timerNotifier.value, equals(disappearingTime));
      });

      test('should cancel existing timer when starting new one', () {
        const messageId = 'msg1';
        const initialTime = 10;
        const newTime = 5;

        manager.startTimer(messageId, initialTime);
        final initialState = manager.getTimerState(messageId);
        expect(initialState!.remainingTime, equals(initialTime));

        manager.startTimer(messageId, newTime);
        final newState = manager.getTimerState(messageId);
        expect(newState!.remainingTime, equals(newTime));
      });

      test('should convert display timer to active timer', () {
        const messageId = 'msg1';
        const disappearingTime = 5;

        manager.startDisplayTimer(messageId, disappearingTime);
        final displayState = manager.getTimerState(messageId);
        expect(displayState, isNotNull);
        expect(displayState!.remainingTime, equals(disappearingTime));

        manager.convertToActiveTimer(messageId, disappearingTime);
        final activeState = manager.getTimerState(messageId);
        expect(activeState, isNotNull);
        expect(activeState!.remainingTime, equals(disappearingTime));
      });

      test('should cancel specific timer', () {
        const messageId = 'msg1';
        const disappearingTime = 5;

        manager.startTimer(messageId, disappearingTime);
        expect(manager.getTimerState(messageId), isNotNull);

        manager.cancelTimer(messageId);
        expect(manager.getTimerState(messageId), isNull);
      });
    });

    group('Timer Expiration', () {
      test('should trigger onImageExpired when timer expires', () async {
        const messageId = 'msg1';
        const disappearingTime = 1; // 1 second for quick test

        manager.startTimer(messageId, disappearingTime);
        expect(expiredImages, isEmpty);

        // Wait for timer to expire
        await Future.delayed(const Duration(seconds: 2));

        expect(expiredImages, contains(messageId));
        expect(manager.getTimerState(messageId), isNull);
      });

      test('should update remaining time during countdown', () async {
        const messageId = 'msg1';
        const disappearingTime = 3;

        manager.startTimer(messageId, disappearingTime);
        final timerState = manager.getTimerState(messageId);
        expect(timerState!.remainingTime, equals(disappearingTime));

        // Wait for 1 second
        await Future.delayed(const Duration(seconds: 1));
        expect(timerState.remainingTime, equals(disappearingTime - 1));

        // Wait for another second
        await Future.delayed(const Duration(seconds: 1));
        expect(timerState.remainingTime, equals(disappearingTime - 2));
      });

      test('should handle multiple timers independently', () async {
        const messageId1 = 'msg1';
        const messageId2 = 'msg2';
        const disappearingTime = 1;

        manager.startTimer(messageId1, disappearingTime);
        manager.startTimer(messageId2, disappearingTime + 1);

        final state1 = manager.getTimerState(messageId1);
        final state2 = manager.getTimerState(messageId2);

        expect(state1!.remainingTime, equals(disappearingTime));
        expect(state2!.remainingTime, equals(disappearingTime + 1));

        // Wait for first timer to expire
        await Future.delayed(const Duration(seconds: 2));

        expect(expiredImages, contains(messageId1));
        expect(expiredImages, isNot(contains(messageId2)));
        expect(manager.getTimerState(messageId1), isNull);
        expect(manager.getTimerState(messageId2), isNotNull);
      });
    });

    group('State Management', () {
      test('should return null for non-existent timer', () {
        const messageId = 'non_existent';
        expect(manager.getTimerState(messageId), isNull);
      });

      test('should handle disposal correctly', () {
        const messageId = 'msg1';
        const disappearingTime = 5;

        manager.startTimer(messageId, disappearingTime);
        expect(manager.getTimerState(messageId), isNotNull);

        manager.dispose();
        expect(manager.getTimerState(messageId), isNull);
      });

      test('should not start timer after disposal', () {
        manager.dispose();
        const messageId = 'msg1';
        const disappearingTime = 5;

        manager.startTimer(messageId, disappearingTime);
        expect(manager.getTimerState(messageId), isNull);
      });
    });

    group('ValueNotifier Integration', () {
      test('should update ValueNotifier during countdown', () async {
        const messageId = 'msg1';
        const disappearingTime = 3;

        manager.startTimer(messageId, disappearingTime);
        final timerState = manager.getTimerState(messageId);
        final notifier = timerState!.timerNotifier;

        expect(notifier.value, equals(disappearingTime));

        // Wait for 1 second
        await Future.delayed(const Duration(seconds: 1));
        expect(notifier.value, equals(disappearingTime - 1));

        // Wait for another second
        await Future.delayed(const Duration(seconds: 1));
        expect(notifier.value, equals(disappearingTime - 2));
      });

      test('should maintain ValueNotifier reference during conversion', () {
        const messageId = 'msg1';
        const disappearingTime = 5;

        manager.startDisplayTimer(messageId, disappearingTime);
        final displayState = manager.getTimerState(messageId);
        final originalNotifier = displayState!.timerNotifier;

        manager.convertToActiveTimer(messageId, disappearingTime);
        final activeState = manager.getTimerState(messageId);
        final convertedNotifier = activeState!.timerNotifier;

        // Should be the same reference
        expect(originalNotifier, equals(convertedNotifier));
      });
    });

    group('Edge Cases', () {
      test('should handle zero disappearing time', () {
        const messageId = 'msg1';
        const disappearingTime = 0;

        manager.startTimer(messageId, disappearingTime);
        final timerState = manager.getTimerState(messageId);
        expect(timerState!.remainingTime, equals(0));
      });

      test('should handle negative disappearing time', () {
        const messageId = 'msg1';
        const disappearingTime = -1;

        manager.startTimer(messageId, disappearingTime);
        final timerState = manager.getTimerState(messageId);
        expect(timerState!.remainingTime, equals(disappearingTime));
      });

      test('should handle very large disappearing time', () {
        const messageId = 'msg1';
        const disappearingTime = 999999;

        manager.startTimer(messageId, disappearingTime);
        final timerState = manager.getTimerState(messageId);
        expect(timerState!.remainingTime, equals(disappearingTime));
      });

      test('should handle empty message ID', () {
        const messageId = '';
        const disappearingTime = 5;

        manager.startTimer(messageId, disappearingTime);
        final timerState = manager.getTimerState(messageId);
        expect(timerState, isNotNull);
        expect(timerState!.messageId, equals(messageId));
      });
    });

    group('Performance', () {
      test('should handle many concurrent timers', () {
        const timerCount = 100;
        const disappearingTime = 5;

        for (int i = 0; i < timerCount; i++) {
          manager.startTimer('msg$i', disappearingTime);
        }

        // Verify all timers are created
        for (int i = 0; i < timerCount; i++) {
          final timerState = manager.getTimerState('msg$i');
          expect(timerState, isNotNull);
          expect(timerState!.remainingTime, equals(disappearingTime));
        }
      });

      test('should clean up resources on disposal', () {
        const timerCount = 50;
        const disappearingTime = 5;

        for (int i = 0; i < timerCount; i++) {
          manager.startTimer('msg$i', disappearingTime);
        }

        manager.dispose();

        // Verify all timers are cleaned up
        for (int i = 0; i < timerCount; i++) {
          expect(manager.getTimerState('msg$i'), isNull);
        }
      });
    });
  });
}
