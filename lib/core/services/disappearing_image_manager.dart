import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hushmate/core/utils/logger.dart';

class DisappearingImageState {
  final String messageId;
  int remainingTime;
  Timer timer; // Made non-final to allow reassignment
  final ValueNotifier<int> timerNotifier;

  DisappearingImageState({
    required this.messageId,
    required this.remainingTime,
    required this.timer,
    required this.timerNotifier,
  });
}

class DisappearingImageManager {
  final Map<String, DisappearingImageState> _disappearingImages = {};
  final Function(String) onImageExpired;
  bool _isDisposed = false;

  DisappearingImageManager({required this.onImageExpired});

  /// Start an active timer for a disappearing image
  void startTimer(String messageId, int disappearingTime) {
    if (_isDisposed) return;
    
    AppLogger.info('🔵 DisappearingImageManager: Starting timer for message: $messageId');
    AppLogger.info('🔵 DisappearingImageManager: Disappearing time: $disappearingTime seconds');
    
    // Cancel existing timer if any
    _cancelExistingTimer(messageId);
    
    // Create ValueNotifier for this message
    final timerNotifier = ValueNotifier<int>(disappearingTime);
    
    // Create new state with active timer
    _disappearingImages[messageId] = DisappearingImageState(
      messageId: messageId,
      remainingTime: disappearingTime,
      timer: Timer.periodic(const Duration(seconds: 1), (timer) {
        final currentState = _disappearingImages[messageId];
        if (currentState != null && !_isDisposed) {
          currentState.remainingTime--;
          currentState.timerNotifier.value = currentState.remainingTime;
          
          if (currentState.remainingTime <= 0) {
            timer.cancel();
            _handleTimerExpired(messageId);
          }
        } else if (_isDisposed) {
          timer.cancel();
        }
      }),
      timerNotifier: timerNotifier,
    );
    
    AppLogger.info('🔵 DisappearingImageManager: Timer started successfully. Active timers: ${_disappearingImages.keys.join(', ')}');
  }

  /// Initialize a display-only timer state (no actual countdown)
  void initializeDisplayTimer(String messageId, int disappearingTime) {
    if (_isDisposed) return;
    
    AppLogger.info('🔵 DisappearingImageManager: Initializing display timer for message: $messageId');
    
    // Only create if it doesn't exist
    if (_disappearingImages[messageId] == null) {
      final displayNotifier = ValueNotifier<int>(disappearingTime);
      
      _disappearingImages[messageId] = DisappearingImageState(
        messageId: messageId,
        remainingTime: disappearingTime,
        timer: Timer.periodic(const Duration(seconds: 1), (timer) {
          // This timer won't actually run since we don't start it
          // It's just a placeholder for the state structure
        }),
        timerNotifier: displayNotifier,
      );
      
      // Immediately cancel the placeholder timer since we don't want it to run
      _disappearingImages[messageId]!.timer.cancel();
      
      AppLogger.info('🔵 DisappearingImageManager: Display timer initialized. Active timers: ${_disappearingImages.keys.join(', ')}');
    }
  }

  /// Convert display-only timer to active timer
  void convertToActiveTimer(String messageId, int disappearingTime) {
    if (_isDisposed) return;
    
    AppLogger.info('🔵 DisappearingImageManager: Converting display timer to active timer for message: $messageId');
    
    final existingState = _disappearingImages[messageId];
    if (existingState != null) {
      AppLogger.info('🔵 DisappearingImageManager: Found existing timer state, converting to active timer');
      
      // Cancel the existing timer (if it was running) but KEEP the existing ValueNotifier
      existingState.timer.cancel();
      
      // Update the existing ValueNotifier to the new disappearing time
      existingState.timerNotifier.value = disappearingTime;
      existingState.remainingTime = disappearingTime;
      
      // Replace only the timer while keeping the same ValueNotifier reference
      existingState.timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        final currentState = _disappearingImages[messageId];
        if (currentState != null && !_isDisposed) {
          currentState.remainingTime--;
          currentState.timerNotifier.value = currentState.remainingTime;
          
          if (currentState.remainingTime <= 0) {
            timer.cancel();
            _handleTimerExpired(messageId);
          }
        } else if (_isDisposed) {
          timer.cancel();
        }
      });
      
      AppLogger.info('🔵 DisappearingImageManager: Converted to active timer successfully');
    } else {
      // If no existing state, start a new timer
      startTimer(messageId, disappearingTime);
    }
  }

  /// Get timer state for UI components
  DisappearingImageState? getTimerState(String messageId) {
    return _disappearingImages[messageId];
  }

  /// Cancel and remove a specific timer
  void cancelTimer(String messageId) {
    final state = _disappearingImages[messageId];
    if (state != null) {
      state.timer.cancel();
      state.timerNotifier.dispose();
      _disappearingImages.remove(messageId);
      AppLogger.info('🔵 DisappearingImageManager: Cancelled timer for message: $messageId');
    }
  }

  /// Handle timer expiration
  void _handleTimerExpired(String messageId) {
    AppLogger.info('🔵 DisappearingImageManager: Timer expired for message: $messageId');
    
    // Remove the timer state
    _disappearingImages.remove(messageId);
    
    // Notify parent about expiration
    onImageExpired(messageId);
  }

  /// Cancel existing timer if any
  void _cancelExistingTimer(String messageId) {
    final existingState = _disappearingImages[messageId];
    if (existingState != null) {
      existingState.timer.cancel();
      existingState.timerNotifier.dispose();
      _disappearingImages.remove(messageId);
    }
  }

  /// Get all active timer IDs
  List<String> getActiveTimerIds() {
    return _disappearingImages.keys.toList();
  }

  /// Check if a timer exists for a message
  bool hasTimer(String messageId) {
    return _disappearingImages.containsKey(messageId);
  }

  /// Dispose all timers and clean up resources
  void dispose() {
    AppLogger.info('🔵 DisappearingImageManager: Disposing all timers');
    _isDisposed = true;
    
    for (final state in _disappearingImages.values) {
      state.timer.cancel();
      state.timerNotifier.dispose();
    }
    _disappearingImages.clear();
    
    AppLogger.info('🔵 DisappearingImageManager: All timers disposed');
  }
} 