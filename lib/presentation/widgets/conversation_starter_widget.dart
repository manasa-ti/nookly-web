import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nookly/domain/entities/conversation_starter.dart';
import 'package:nookly/presentation/bloc/conversation_starter/conversation_starter_bloc.dart';
import 'package:nookly/presentation/bloc/conversation_starter/conversation_starter_event.dart';
import 'package:nookly/presentation/bloc/conversation_starter/conversation_starter_state.dart';
import 'package:nookly/core/di/injection_container.dart';
import 'package:nookly/core/services/conversation_starter_service.dart';

class ConversationStarterWidget extends StatelessWidget {
  final String matchUserId;
  final List<String>? priorMessages;
  final Function(String) onSuggestionSelected;

  const ConversationStarterWidget({
    Key? key,
    required this.matchUserId,
    this.priorMessages,
    required this.onSuggestionSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _ConversationStarterContent(
      matchUserId: matchUserId,
      priorMessages: priorMessages,
      onSuggestionSelected: onSuggestionSelected,
    );
  }
}

class _ConversationStarterContent extends StatelessWidget {
  final String matchUserId;
  final List<String>? priorMessages;
  final Function(String) onSuggestionSelected;

  const _ConversationStarterContent({
    required this.matchUserId,
    this.priorMessages,
    required this.onSuggestionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.2),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_outline,
            color: Colors.white.withOpacity(0.8),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => _showConversationStartersModal(context),
              child: Text(
                'Get conversation ideas',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showConversationStartersModal(BuildContext context) {
    print('DEBUGGING STARTERS: Opening modal and triggering API call');
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF234481),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => BlocProvider(
        create: (context) => ConversationStarterBloc(
          conversationStarterService: sl<ConversationStarterService>(),
        )..add(GenerateConversationStarters(
          matchUserId: matchUserId,
          priorMessages: priorMessages,
        )),
        child: _ConversationStartersModal(
          matchUserId: matchUserId,
          priorMessages: priorMessages,
          onSuggestionSelected: onSuggestionSelected,
        ),
      ),
    );
  }
}

class _ConversationStartersModal extends StatelessWidget {
  final String matchUserId;
  final List<String>? priorMessages;
  final Function(String) onSuggestionSelected;

  const _ConversationStartersModal({
    required this.matchUserId,
    this.priorMessages,
    required this.onSuggestionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ConversationStarterBloc, ConversationStarterState>(
      listener: (context, state) {
        if (state is ConversationStarterError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
      builder: (context, state) {
        return Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Conversation Starters',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Nunito',
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Content based on state
              if (state is ConversationStarterLoading) ...[
                _buildLoadingState(),
              ] else if (state is ConversationStarterLoaded) ...[
                if (state.suggestions.isNotEmpty) ...[
                  _buildSuggestionsList(context, state.suggestions, state.isFallback),
                  const SizedBox(height: 16),
                  _buildUsageInfo(state.usage),
                ] else ...[
                  _buildEmptyState(context),
                ],
              ] else if (state is ConversationStarterRateLimited) ...[
                _buildRateLimitState(state.usage),
              ] else if (state is ConversationStarterError) ...[
                _buildErrorState(context, state.message),
              ] else ...[
                _buildInitialState(context),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: List.generate(4, (index) => _buildSkeletonCard()),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 16,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 16,
            width: 200, // Fixed width instead of using context
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsList(BuildContext context, List<ConversationStarter> suggestions, bool isFallback) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isFallback) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.orange.withOpacity(0.3),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.orange,
                  size: 16,
                ),
                const SizedBox(width: 6),
                const Text(
                  'Using fallback suggestions',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 12,
                    fontFamily: 'Nunito',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        ...suggestions.map((suggestion) => _buildSuggestionCard(context, suggestion)),
      ],
    );
  }

  Widget _buildSuggestionCard(BuildContext context, ConversationStarter suggestion) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).pop();
            onSuggestionSelected(suggestion.text);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    suggestion.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontFamily: 'Nunito',
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withOpacity(0.6),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUsageInfo(ConversationStarterUsage usage) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.schedule,
            color: Colors.white.withOpacity(0.6),
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            'Requests remaining: ${usage.remaining}/3 today',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
              fontFamily: 'Nunito',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRateLimitState(ConversationStarterUsage usage) {
    return Column(
      children: [
        Icon(
          Icons.schedule,
          color: Colors.white.withOpacity(0.6),
          size: 48,
        ),
        const SizedBox(height: 16),
        const Text(
          'You have reached your daily limit of 3 conversation starters.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Try again tomorrow.',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
            fontFamily: 'Nunito',
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        _buildUsageInfo(usage),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Column(
      children: [
        Icon(
          Icons.error_outline,
          color: Colors.red.withOpacity(0.8),
          size: 48,
        ),
        const SizedBox(height: 16),
        Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            context.read<ConversationStarterBloc>().add(
              GenerateConversationStarters(
                matchUserId: matchUserId,
                priorMessages: priorMessages,
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF35548b),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Try Again',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Nunito',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Column(
      children: [
        Icon(
          Icons.lightbulb_outline,
          color: Colors.white.withOpacity(0.6),
          size: 48,
        ),
        const SizedBox(height: 16),
        const Text(
          'No conversation starters available',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildInitialState(BuildContext context) {
    // Since API call happens automatically, show loading state
    return _buildLoadingState();
  }
}
