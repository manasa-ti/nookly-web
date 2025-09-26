import 'package:nookly/core/utils/logger.dart';

/// Global event bus for centralized event handling across the app
/// This allows multiple pages to listen to the same socket events
/// without conflicts, following the WhatsApp/Telegram architecture
class GlobalEventBus {
  static final GlobalEventBus _instance = GlobalEventBus._internal();
  factory GlobalEventBus() => _instance;
  GlobalEventBus._internal();

  // Map of event names to list of handlers
  final Map<String, List<Function(dynamic)>> _listeners = {};

  /// Subscribe to an event
  void on(String event, Function(dynamic) handler) {
    AppLogger.info('🔔 EventBus: Subscribing to event: $event');
    _listeners.putIfAbsent(event, () => []).add(handler);
    AppLogger.info('🔔 EventBus: Total subscribers for $event: ${_listeners[event]?.length ?? 0}');
  }

  /// Unsubscribe from an event
  void off(String event, Function(dynamic) handler) {
    AppLogger.info('🔔 EventBus: Unsubscribing from event: $event');
    _listeners[event]?.remove(handler);
    if (_listeners[event]?.isEmpty == true) {
      _listeners.remove(event);
    }
    AppLogger.info('🔔 EventBus: Remaining subscribers for $event: ${_listeners[event]?.length ?? 0}');
  }

  /// Emit an event to all subscribers
  void emit(String event, dynamic data) {
    AppLogger.info('🔔 EventBus: Emitting event: $event');
    AppLogger.info('🔔 EventBus: Data: $data');
    AppLogger.info('🔔 EventBus: Subscribers: ${_listeners[event]?.length ?? 0}');
    
    final handlers = _listeners[event];
    if (handlers != null && handlers.isNotEmpty) {
      for (final handler in handlers) {
        try {
          handler(data);
          AppLogger.info('🔔 EventBus: Event $event processed successfully');
        } catch (e) {
          AppLogger.error('🔔 EventBus: Error processing event $event: $e');
        }
      }
    } else {
      AppLogger.warning('🔔 EventBus: No subscribers for event: $event');
    }
  }

  /// Get the number of subscribers for an event
  int getSubscriberCount(String event) {
    return _listeners[event]?.length ?? 0;
  }

  /// Get all registered events
  List<String> getRegisteredEvents() {
    return _listeners.keys.toList();
  }

  /// Clear all listeners (useful for testing or cleanup)
  void clear() {
    AppLogger.info('🔔 EventBus: Clearing all listeners');
    _listeners.clear();
  }
}
