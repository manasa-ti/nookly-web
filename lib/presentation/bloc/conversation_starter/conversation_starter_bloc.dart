import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nookly/core/services/conversation_starter_service.dart';
import 'package:nookly/core/utils/logger.dart';
import 'package:nookly/data/repositories/conversation_starter_repository_impl.dart';
import 'package:nookly/presentation/bloc/conversation_starter/conversation_starter_event.dart';
import 'package:nookly/presentation/bloc/conversation_starter/conversation_starter_state.dart';

class ConversationStarterBloc extends Bloc<ConversationStarterEvent, ConversationStarterState> {
  final ConversationStarterService _conversationStarterService;

  ConversationStarterBloc({
    required ConversationStarterService conversationStarterService,
  }) : _conversationStarterService = conversationStarterService,
       super(const ConversationStarterInitial()) {
    
    on<GenerateConversationStarters>(_onGenerateConversationStarters);
    on<LoadConversationStarterUsage>(_onLoadConversationStarterUsage);
    on<ClearConversationStarters>(_onClearConversationStarters);
    on<RefreshConversationStarters>(_onRefreshConversationStarters);
  }

  Future<void> _onGenerateConversationStarters(
    GenerateConversationStarters event,
    Emitter<ConversationStarterState> emit,
  ) async {
    try {
      AppLogger.info('DEBUGGING STARTERS: BLoC - _onGenerateConversationStarters called');
      AppLogger.info('DEBUGGING STARTERS: BLoC - event.matchUserId: ${event.matchUserId}');
      AppLogger.info('DEBUGGING STARTERS: BLoC - event.priorMessages: ${event.priorMessages}');
      AppLogger.info('🔵 ConversationStarterBloc: Generating conversation starters');
      
      AppLogger.info('DEBUGGING STARTERS: BLoC - Emitting loading state');
      emit(const ConversationStarterLoading());

      AppLogger.info('DEBUGGING STARTERS: BLoC - Calling service.generateConversationStarters');
      final suggestions = await _conversationStarterService.generateConversationStarters(
        matchUserId: event.matchUserId,
        numberOfSuggestions: event.numberOfSuggestions,
        locale: event.locale,
        priorMessages: event.priorMessages,
      );

      AppLogger.info('DEBUGGING STARTERS: BLoC - Service returned ${suggestions.length} suggestions');
      AppLogger.info('DEBUGGING STARTERS: BLoC - Getting usage info');
      final usage = await _conversationStarterService.getUsage();
      final isFallback = suggestions.any((suggestion) => suggestion.isFallback);

      AppLogger.info('DEBUGGING STARTERS: BLoC - Usage remaining: ${usage.remaining}');
      AppLogger.info('DEBUGGING STARTERS: BLoC - Is fallback: $isFallback');
      AppLogger.info('✅ ConversationStarterBloc: Generated ${suggestions.length} suggestions');
      AppLogger.info('🔵 ConversationStarterBloc: Is fallback: $isFallback');
      AppLogger.info('🔵 ConversationStarterBloc: Usage remaining: ${usage.remaining}');

      AppLogger.info('DEBUGGING STARTERS: BLoC - Emitting loaded state with ${suggestions.length} suggestions');
      emit(ConversationStarterLoaded(
        suggestions: suggestions,
        usage: usage,
        isFallback: isFallback,
      ));
    } on ConversationStarterRateLimitException catch (e) {
      AppLogger.warning('⚠️ ConversationStarterBloc: Rate limit exceeded');
      emit(ConversationStarterRateLimited(
        message: e.message,
        usage: e.usage,
      ));
    } on ConversationStarterValidationException catch (e) {
      AppLogger.error('❌ ConversationStarterBloc: Validation error: ${e.message}');
      emit(ConversationStarterError(message: e.message));
    } on ConversationStarterNotFoundException catch (e) {
      AppLogger.error('❌ ConversationStarterBloc: Not found error: ${e.message}');
      emit(ConversationStarterError(message: e.message));
    } on ConversationStarterServiceException catch (e) {
      AppLogger.error('❌ ConversationStarterBloc: Service error: ${e.message}');
      emit(ConversationStarterError(message: e.message));
    } catch (e) {
      AppLogger.error('❌ ConversationStarterBloc: Unexpected error: $e');
      emit(ConversationStarterError(message: 'Failed to generate conversation starters. Please try again.'));
    }
  }

  Future<void> _onLoadConversationStarterUsage(
    LoadConversationStarterUsage event,
    Emitter<ConversationStarterState> emit,
  ) async {
    try {
      AppLogger.info('🔵 ConversationStarterBloc: Loading usage');
      
      final usage = await _conversationStarterService.getUsage();
      
      AppLogger.info('🔵 ConversationStarterBloc: Usage loaded - remaining: ${usage.remaining}');
      
      // If we have existing suggestions, update the state with new usage
      if (state is ConversationStarterLoaded) {
        final currentState = state as ConversationStarterLoaded;
        emit(currentState.copyWith(usage: usage));
      } else {
        // If no suggestions, just emit the usage
        emit(ConversationStarterLoaded(
          suggestions: const [],
          usage: usage,
          isFallback: false,
        ));
      }
    } catch (e) {
      AppLogger.error('❌ ConversationStarterBloc: Error loading usage: $e');
      emit(ConversationStarterError(message: 'Failed to load usage information.'));
    }
  }

  Future<void> _onClearConversationStarters(
    ClearConversationStarters event,
    Emitter<ConversationStarterState> emit,
  ) async {
    AppLogger.info('🔵 ConversationStarterBloc: Clearing conversation starters');
    emit(const ConversationStarterInitial());
  }

  Future<void> _onRefreshConversationStarters(
    RefreshConversationStarters event,
    Emitter<ConversationStarterState> emit,
  ) async {
    AppLogger.info('🔵 ConversationStarterBloc: Refreshing conversation starters');
    
    // Clear current state and generate new suggestions
    add(ClearConversationStarters());
    add(GenerateConversationStarters(
      matchUserId: event.matchUserId,
      numberOfSuggestions: event.numberOfSuggestions,
      locale: event.locale,
      priorMessages: event.priorMessages,
    ));
  }
}
