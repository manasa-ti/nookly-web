import 'package:nookly/core/utils/logger.dart';

/// Service for managing mock game prompts and answers in demo mode
class DemoGameDataService {
  static final DemoGameDataService _instance = DemoGameDataService._internal();
  factory DemoGameDataService() => _instance;
  DemoGameDataService._internal();

  // Track current prompt index per game type
  final Map<String, int> _currentPromptIndices = {};
  int _currentAnswerIndex = 0;

  // Mock prompts for Truth or Thrill game (10 prompts)
  final List<Map<String, dynamic>> _truthOrThrillPrompts = [
    {
      'type': 'truth_or_thrill',
      'truthOrThrill': {
        'truth': {
          'id': 1,
          'type': 'truth',
          'stage': 1,
          'text': 'What\'s a fear you\'ve never told anyone about?',
        },
        'thrill': {
          'id': 81,
          'type': 'thrill',
          'stage': 1,
          'text': 'Send the most random emoji combo you can think of.',
        },
      },
    },
    {
      'type': 'truth_or_thrill',
      'truthOrThrill': {
        'truth': {
          'id': 2,
          'type': 'truth',
          'stage': 1,
          'text': 'What\'s the biggest lesson a past relationship taught you?',
        },
        'thrill': {
          'id': 82,
          'type': 'thrill',
          'stage': 1,
          'text': 'Describe your day so far using only emojis.',
        },
      },
    },
    {
      'type': 'truth_or_thrill',
      'truthOrThrill': {
        'truth': {
          'id': 3,
          'type': 'truth',
          'stage': 1,
          'text': 'What\'s something you\'re working on improving about yourself?',
        },
        'thrill': {
          'id': 83,
          'type': 'thrill',
          'stage': 1,
          'text': 'Send a selfie making your funniest face.',
        },
      },
    },
    {
      'type': 'truth_or_thrill',
      'truthOrThrill': {
        'truth': {
          'id': 4,
          'type': 'truth',
          'stage': 1,
          'text': 'What\'s a dream you gave up on, and do you ever regret it?',
        },
        'thrill': {
          'id': 84,
          'type': 'thrill',
          'stage': 1,
          'text': 'React to your partner\'s last message with three exaggerated emojis.',
        },
      },
    },
    {
      'type': 'truth_or_thrill',
      'truthOrThrill': {
        'truth': {
          'id': 5,
          'type': 'truth',
          'stage': 1,
          'text': 'What\'s the most vulnerable you\'ve ever been with someone?',
        },
        'thrill': {
          'id': 85,
          'type': 'thrill',
          'stage': 1,
          'text': 'Send a voice note saying the alphabet backwards.',
        },
      },
    },
    {
      'type': 'truth_or_thrill',
      'truthOrThrill': {
        'truth': {
          'id': 6,
          'type': 'truth',
          'stage': 1,
          'text': 'What\'s something about your family that shaped who you are today?',
        },
        'thrill': {
          'id': 86,
          'type': 'thrill',
          'stage': 1,
          'text': 'Type a message without using the spacebar.',
        },
      },
    },
    {
      'type': 'truth_or_thrill',
      'truthOrThrill': {
        'truth': {
          'id': 7,
          'type': 'truth',
          'stage': 1,
          'text': 'What\'s a mistake you made that you\'re grateful for now?',
        },
        'thrill': {
          'id': 87,
          'type': 'thrill',
          'stage': 1,
          'text': 'Reply with only GIFs for the next 2 turns.',
        },
      },
    },
    {
      'type': 'truth_or_thrill',
      'truthOrThrill': {
        'truth': {
          'id': 8,
          'type': 'truth',
          'stage': 1,
          'text': 'What do you think is your biggest weakness in relationships?',
        },
        'thrill': {
          'id': 88,
          'type': 'thrill',
          'stage': 1,
          'text': 'Send the last photo you took (if comfortable).',
        },
      },
    },
    {
      'type': 'truth_or_thrill',
      'truthOrThrill': {
        'truth': {
          'id': 9,
          'type': 'truth',
          'stage': 1,
          'text': 'What\'s something you\'re insecure about that most people don\'t notice?',
        },
        'thrill': {
          'id': 89,
          'type': 'thrill',
          'stage': 1,
          'text': 'Write a compliment for your partner in rhyming words.',
        },
      },
    },
    {
      'type': 'truth_or_thrill',
      'truthOrThrill': {
        'truth': {
          'id': 10,
          'type': 'truth',
          'stage': 1,
          'text': 'What\'s a value you refuse to compromise on in life?',
        },
        'thrill': {
          'id': 90,
          'type': 'thrill',
          'stage': 1,
          'text': 'Send your partner three random facts about yourself right now.',
        },
      },
    },
  ];

  // Mock prompts for Memory Sparks game (10 prompts)
  final List<Map<String, dynamic>> _memorySparksPrompts = [
    {
      'type': 'memory',
      'singlePrompt': {
        'id': 1,
        'type': 'memory',
        'stage': 1,
        'text': 'Share a childhood memory that taught you an important life lesson.',
      },
    },
    {
      'type': 'memory',
      'singlePrompt': {
        'id': 2,
        'type': 'memory',
        'stage': 1,
        'text': 'Tell me about a moment when you felt truly proud of yourself.',
      },
    },
    {
      'type': 'memory',
      'singlePrompt': {
        'id': 3,
        'type': 'memory',
        'stage': 1,
        'text': 'Share a memory of someone who believed in you when you didn\'t believe in yourself.',
      },
    },
    {
      'type': 'memory',
      'singlePrompt': {
        'id': 4,
        'type': 'memory',
        'stage': 1,
        'text': 'Describe a moment that changed your perspective on life forever.',
      },
    },
    {
      'type': 'memory',
      'singlePrompt': {
        'id': 5,
        'type': 'memory',
        'stage': 1,
        'text': 'Tell me about a time when you overcame something you thought was impossible.',
      },
    },
    {
      'type': 'memory',
      'singlePrompt': {
        'id': 6,
        'type': 'memory',
        'stage': 1,
        'text': 'Share a memory that still makes you emotional when you think about it.',
      },
    },
    {
      'type': 'memory',
      'singlePrompt': {
        'id': 7,
        'type': 'memory',
        'stage': 1,
        'text': 'Describe the moment you realized you had to make a major life change.',
      },
    },
    {
      'type': 'memory',
      'singlePrompt': {
        'id': 8,
        'type': 'memory',
        'stage': 1,
        'text': 'Tell me about a time when you disappointed someone important to you.',
      },
    },
    {
      'type': 'memory',
      'singlePrompt': {
        'id': 9,
        'type': 'memory',
        'stage': 1,
        'text': 'Share a memory of when you felt most understood by another person.',
      },
    },
    {
      'type': 'memory',
      'singlePrompt': {
        'id': 10,
        'type': 'memory',
        'stage': 1,
        'text': 'Describe a moment when you discovered something important about yourself.',
      },
    },
  ];

  // Mock prompts for Would You Rather game (10 prompts)
  final List<Map<String, dynamic>> _wouldYouRatherPrompts = [
    {
      'type': 'question',
      'singlePrompt': {
        'id': 1,
        'type': 'question',
        'stage': 1,
        'text': 'Would you rather have a partner who\'s your best friend or your greatest passion?',
      },
    },
    {
      'type': 'question',
      'singlePrompt': {
        'id': 2,
        'type': 'question',
        'stage': 1,
        'text': 'Would you rather know your partner\'s deepest secret or have them never know yours?',
      },
    },
    {
      'type': 'question',
      'singlePrompt': {
        'id': 3,
        'type': 'question',
        'stage': 1,
        'text': 'Would you rather be with someone who makes you laugh or someone who makes you think?',
      },
    },
    {
      'type': 'question',
      'singlePrompt': {
        'id': 4,
        'type': 'question',
        'stage': 1,
        'text': 'Would you rather have perfect communication or perfect chemistry with a partner?',
      },
    },
    {
      'type': 'question',
      'singlePrompt': {
        'id': 5,
        'type': 'question',
        'stage': 1,
        'text': 'Would you rather date someone exactly like you or someone completely opposite?',
      },
    },
    {
      'type': 'question',
      'singlePrompt': {
        'id': 6,
        'type': 'question',
        'stage': 1,
        'text': 'Would you rather be loved intensely for 5 years or moderately for a lifetime?',
      },
    },
    {
      'type': 'question',
      'singlePrompt': {
        'id': 7,
        'type': 'question',
        'stage': 1,
        'text': 'Would you rather have your partner always be honest even if it hurts, or sometimes lie to protect your feelings?',
      },
    },
    {
      'type': 'question',
      'singlePrompt': {
        'id': 8,
        'type': 'question',
        'stage': 1,
        'text': 'Would you rather share all your passwords with your partner or none at all?',
      },
    },
    {
      'type': 'question',
      'singlePrompt': {
        'id': 9,
        'type': 'question',
        'stage': 1,
        'text': 'Would you rather spend every moment with your partner or maintain separate hobbies and friends?',
      },
    },
    {
      'type': 'question',
      'singlePrompt': {
        'id': 10,
        'type': 'question',
        'stage': 1,
        'text': 'Would you rather be with someone who needs constant reassurance or someone who\'s very independent?',
      },
    },
  ];

  // Mock prompts for Guess Me game (11 prompts)
  final List<Map<String, dynamic>> _guessMePrompts = [
    {
      'type': 'guess',
      'singlePrompt': {
        'id': 200,
        'type': 'guess',
        'stage': 1,
        'text': 'What\'s my go-to comfort food?',
      },
    },
    {
      'type': 'guess',
      'singlePrompt': {
        'id': 201,
        'type': 'guess',
        'stage': 1,
        'text': 'Which city would I love to travel to next?',
      },
    },
    {
      'type': 'guess',
      'singlePrompt': {
        'id': 202,
        'type': 'guess',
        'stage': 1,
        'text': 'Do I prefer mornings or nights?',
      },
    },
    {
      'type': 'guess',
      'singlePrompt': {
        'id': 203,
        'type': 'guess',
        'stage': 1,
        'text': 'What\'s my favorite way to relax after a long day?',
      },
    },
    {
      'type': 'guess',
      'singlePrompt': {
        'id': 204,
        'type': 'guess',
        'stage': 1,
        'text': 'Would I rather watch a movie or read a book?',
      },
    },
    {
      'type': 'guess',
      'singlePrompt': {
        'id': 205,
        'type': 'guess',
        'stage': 1,
        'text': 'What\'s my go-to comfort food?',
      },
    },
    {
      'type': 'guess',
      'singlePrompt': {
        'id': 206,
        'type': 'guess',
        'stage': 1,
        'text': 'Which city would I love to travel to next?',
      },
    },
    {
      'type': 'guess',
      'singlePrompt': {
        'id': 207,
        'type': 'guess',
        'stage': 1,
        'text': 'Do I prefer mornings or nights?',
      },
    },
    {
      'type': 'guess',
      'singlePrompt': {
        'id': 208,
        'type': 'guess',
        'stage': 1,
        'text': 'What\'s my favorite way to relax after a long day?',
      },
    },
    {
      'type': 'guess',
      'singlePrompt': {
        'id': 209,
        'type': 'guess',
        'stage': 1,
        'text': 'Would I rather watch a movie or read a book?',
      },
    },
    {
      'type': 'guess',
      'singlePrompt': {
        'id': 210,
        'type': 'guess',
        'stage': 1,
        'text': 'What\'s my go-to comfort food?',
      },
    },
  ];

  // Mock answers for demo companion
  final List<Map<String, dynamic>> _mockAnswers = [
    {
      'promptId': 1,
      'choice': 'truth',
      'answer': 'I am afraid of heights. It makes me feel dizzy just thinking about it!',
    },
    {
      'promptId': 2,
      'choice': 'thrill',
      'answer': 'Yes, I would love to try skydiving! It sounds like an amazing experience.',
    },
    {
      'promptId': 3,
      'choice': 'truth',
      'answer': 'I once tripped and fell in front of a large crowd. It was so embarrassing!',
    },
    {
      'promptId': 4,
      'choice': 'thrill',
      'answer': 'Absolutely! Bungee jumping is on my bucket list. I\'d do it in a heartbeat.',
    },
    {
      'promptId': 5,
      'choice': 'truth',
      'answer': 'I have a secret talent that I\'ve never shared with anyone before.',
    },
    {
      'promptId': 6,
      'choice': 'thrill',
      'answer': 'Yes! I love spontaneous adventures. Let\'s go right now!',
    },
    {
      'promptId': 7,
      'choice': 'truth',
      'answer': 'I\'m irrationally afraid of butterflies. I know it\'s silly, but they make me nervous.',
    },
    {
      'promptId': 8,
      'choice': 'thrill',
      'answer': 'I\'d try anything once! Extreme sports sound thrilling.',
    },
    {
      'promptId': 9,
      'choice': 'truth',
      'answer': 'I regret not taking more risks when I was younger. I was too cautious.',
    },
    {
      'promptId': 10,
      'choice': 'thrill',
      'answer': 'I\'d be cautious, but if it was safe enough, I\'d consider it for the adventure.',
    },
  ];

  /// Get the list of prompts for a specific game type
  List<Map<String, dynamic>> _getPromptsForGameType(String gameType) {
    switch (gameType) {
      case 'truth_or_thrill':
        return _truthOrThrillPrompts;
      case 'memory_sparks':
        return _memorySparksPrompts;
      case 'would_you_rather':
        return _wouldYouRatherPrompts;
      case 'guess_me':
        return _guessMePrompts;
      default:
        AppLogger.warning('⚠️ [DEMO_GAME_DATA] Unknown game type: $gameType, defaulting to truth_or_thrill');
        return _truthOrThrillPrompts;
    }
  }

  /// Get the next prompt from the mock list for a specific game type
  Map<String, dynamic>? getNextPrompt(String gameType) {
    final prompts = _getPromptsForGameType(gameType);
    final currentIndex = _currentPromptIndices[gameType] ?? 0;
    
    if (currentIndex >= prompts.length) {
      AppLogger.info('🔄 [DEMO_GAME_DATA] Reached end of prompts for $gameType');
      return null; // No more prompts
    }

    final prompt = prompts[currentIndex];
    AppLogger.info('📝 [DEMO_GAME_DATA] Getting prompt at index $currentIndex for $gameType');
    _currentPromptIndices[gameType] = currentIndex + 1;
    return prompt;
  }

  /// Check if there are more prompts available for a game type
  bool hasMorePrompts(String gameType) {
    final prompts = _getPromptsForGameType(gameType);
    final currentIndex = _currentPromptIndices[gameType] ?? 0;
    return currentIndex < prompts.length;
  }

  /// Get total number of prompts for a game type
  int getTotalPrompts(String gameType) {
    final prompts = _getPromptsForGameType(gameType);
    return prompts.length;
  }

  /// Get an answer for a specific prompt and choice
  String getAnswerForPrompt(int promptId, String choice) {
    AppLogger.info('💬 [DEMO_GAME_DATA] Getting answer for promptId: $promptId, choice: $choice');
    
    // Find matching answer
    final answer = _mockAnswers.firstWhere(
      (a) => a['promptId'] == promptId && a['choice'] == choice,
      orElse: () => {
        'answer': 'That\'s an interesting question! I need to think about that.',
      },
    );

    AppLogger.info('💬 [DEMO_GAME_DATA] Found answer: ${answer['answer']}');
    return answer['answer'] as String;
  }

  /// Get a random answer for any prompt (used when choice is random)
  String getRandomAnswer() {
    if (_currentAnswerIndex >= _mockAnswers.length) {
      _currentAnswerIndex = 0;
    }

    final answer = _mockAnswers[_currentAnswerIndex];
    _currentAnswerIndex++;
    return answer['answer'] as String;
  }

  /// Reset to the beginning of the prompt list for a specific game type
  void reset(String gameType) {
    AppLogger.info('🔄 [DEMO_GAME_DATA] Resetting prompt index for $gameType');
    _currentPromptIndices[gameType] = 0;
  }

  /// Reset all game types
  void resetAll() {
    AppLogger.info('🔄 [DEMO_GAME_DATA] Resetting all prompt and answer indices');
    _currentPromptIndices.clear();
    _currentAnswerIndex = 0;
  }

  /// Get the current prompt index for a game type (for debugging)
  int getCurrentPromptIndex(String gameType) {
    return _currentPromptIndices[gameType] ?? 0;
  }
}

