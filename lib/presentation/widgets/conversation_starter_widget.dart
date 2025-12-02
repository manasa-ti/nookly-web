import 'package:nookly/core/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nookly/core/theme/app_text_styles.dart';
import 'package:nookly/domain/entities/conversation_starter.dart';
import 'package:nookly/presentation/bloc/conversation_starter/conversation_starter_bloc.dart';
import 'package:nookly/presentation/bloc/conversation_starter/conversation_starter_event.dart';
import 'package:nookly/presentation/bloc/conversation_starter/conversation_starter_state.dart';
import 'package:nookly/core/di/injection_container.dart';
import 'package:nookly/core/services/conversation_starter_service.dart';
import 'package:nookly/core/services/analytics_service.dart';
import 'package:nookly/presentation/widgets/contextual_tooltip.dart';
import 'package:nookly/core/services/onboarding_service.dart';

class ConversationStarterWidget extends StatelessWidget {
  final String matchUserId;
  final List<String>? priorMessages;
  final Function(String) onSuggestionSelected;
  final VoidCallback? onTutorialCompleted;

  const ConversationStarterWidget({
    Key? key,
    required this.matchUserId,
    this.priorMessages,
    required this.onSuggestionSelected,
    this.onTutorialCompleted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _ConversationStarterContent(
      matchUserId: matchUserId,
      priorMessages: priorMessages,
      onSuggestionSelected: onSuggestionSelected,
      onTutorialCompleted: onTutorialCompleted,
    );
  }
}

class _ConversationStarterContent extends StatefulWidget {
  final String matchUserId;
  final List<String>? priorMessages;
  final Function(String) onSuggestionSelected;
  final VoidCallback? onTutorialCompleted;

  const _ConversationStarterContent({
    required this.matchUserId,
    this.priorMessages,
    required this.onSuggestionSelected,
    this.onTutorialCompleted,
  });

  @override
  State<_ConversationStarterContent> createState() => _ConversationStarterContentState();
}

class _ConversationStarterContentState extends State<_ConversationStarterContent> {
  bool _showTooltip = false;

  @override
  void initState() {
    super.initState();
    _checkTooltip();
  }

  void _checkTooltip() async {
    final shouldShow = await OnboardingService.shouldShowConversationStarterTutorial();
    if (shouldShow && mounted) {
      setState(() {
        _showTooltip = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final breakIceButton = GestureDetector(
      onTap: () => _showConversationStartersModal(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.ac_unit,
            color: Colors.white.withOpacity(0.8),
            size: 20,
          ),
          const SizedBox(width: 6),
          Text(
            'Open Up',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: AppTextStyles.getChipFontSize(context),
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );

    if (_showTooltip) {
      return ContextualTooltip(
        message: 'Use AI-generated conversation starters to break the ice',
        position: TooltipPosition.bottom,
        onDismiss: () {
          setState(() {
            _showTooltip = false;
          });
          OnboardingService.markConversationStarterTutorialCompleted();
          widget.onTutorialCompleted?.call();
        },
        child: breakIceButton,
      );
    }

    return breakIceButton;
  }

  void _showConversationStartersModal(BuildContext context) {
    AppLogger.info('DEBUGGING STARTERS: Opening modal and triggering API call');
    
    // Track open up clicked
    sl<AnalyticsService>().logOpenUpClicked();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2d457f),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => BlocProvider(
        create: (context) => ConversationStarterBloc(
          conversationStarterService: sl<ConversationStarterService>(),
        )..add(GenerateConversationStarters(
          matchUserId: widget.matchUserId,
          priorMessages: widget.priorMessages,
        )),
        child: _ConversationStartersModal(
          matchUserId: widget.matchUserId,
          priorMessages: widget.priorMessages,
          onSuggestionSelected: widget.onSuggestionSelected,
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
                        Icons.ac_unit,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Open Up',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: AppTextStyles.getSectionHeaderFontSize(context),
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
              const SizedBox(height: 8),
              
              // Description
              Text(
                'Choose a conversation starter by AI as an ice breaker',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: AppTextStyles.getBodyFontSize(context),
                  fontFamily: 'Nunito',
                ),
              ),
              const SizedBox(height: 20),

              // Content based on state
              if (state is ConversationStarterLoading) ...[
                _buildLoadingState(),
              ] else if (state is ConversationStarterLoaded) ...[
                if (state.suggestions.isNotEmpty) ...[
                  _buildSuggestionsList(context, state.suggestions, state.isFallback),
                  const SizedBox(height: 16),
                  _buildUsageInfo(context, state.usage),
                ] else ...[
                  _buildEmptyState(context),
                ],
              ] else if (state is ConversationStarterRateLimited) ...[
                _buildRateLimitState(context, state.usage),
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
                Text(
                  'Using fallback suggestions',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: AppTextStyles.getCaptionFontSize(context),
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
            // Track conversation starter selected
            sl<AnalyticsService>().logConversationStarterSelected();
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
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: AppTextStyles.getBodyFontSize(context),
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

  Widget _buildUsageInfo(BuildContext context, ConversationStarterUsage usage) {
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
              fontSize: AppTextStyles.getCaptionFontSize(context),
              fontFamily: 'Nunito',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRateLimitState(BuildContext context, ConversationStarterUsage usage) {
    return Column(
      children: [
        Icon(
          Icons.schedule,
          color: Colors.white.withOpacity(0.6),
          size: 48,
        ),
        const SizedBox(height: 16),
        Text(
          'You have reached your daily limit of 3 conversation starters.',
          style: TextStyle(
            color: Colors.white,
            fontSize: AppTextStyles.getSectionHeaderFontSize(context),
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
            fontSize: AppTextStyles.getBodyFontSize(context),
            fontFamily: 'Nunito',
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        _buildUsageInfo(context, usage),
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
          style: TextStyle(
            color: Colors.white,
            fontSize: AppTextStyles.getSectionHeaderFontSize(context),
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
        Text(
          'No conversation starters available',
          style: TextStyle(
            color: Colors.white,
            fontSize: AppTextStyles.getSectionHeaderFontSize(context),
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
