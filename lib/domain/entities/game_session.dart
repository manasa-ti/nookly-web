import 'package:equatable/equatable.dart';
import 'package:nookly/domain/entities/game_prompt.dart';

enum GameType {
  truthOrThrill,
  memorySparks,
  wouldYouRather,
  guessMe;

  String get displayName {
    switch (this) {
      case GameType.truthOrThrill:
        return 'Truth or Thrill';
      case GameType.memorySparks:
        return 'Memory Sparks';
      case GameType.wouldYouRather:
        return 'Would You Rather';
      case GameType.guessMe:
        return 'Guess Me';
    }
  }

  String get apiValue {
    switch (this) {
      case GameType.truthOrThrill:
        return 'truth_or_thrill';
      case GameType.memorySparks:
        return 'memory_sparks';
      case GameType.wouldYouRather:
        return 'would_you_rather';
      case GameType.guessMe:
        return 'guess_me';
    }
  }

  static GameType fromApiValue(String value) {
    switch (value) {
      case 'truth_or_thrill':
        return GameType.truthOrThrill;
      case 'memory_sparks':
        return GameType.memorySparks;
      case 'would_you_rather':
        return GameType.wouldYouRather;
      case 'guess_me':
        return GameType.guessMe;
      default:
        throw ArgumentError('Invalid game type: $value');
    }
  }
}

class Turn extends Equatable {
  final String userId;
  final int turnNumber;

  const Turn({
    required this.userId,
    required this.turnNumber,
  });

  @override
  List<Object?> get props => [userId, turnNumber];

  factory Turn.fromJson(Map<String, dynamic> json) {
    return Turn(
      userId: json['userId'] as String,
      turnNumber: json['turnNumber'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'turnNumber': turnNumber,
    };
  }
}

class Player extends Equatable {
  final String userId;
  final bool isActive;

  const Player({
    required this.userId,
    required this.isActive,
  });

  @override
  List<Object?> get props => [userId, isActive];

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      userId: json['userId'] as String,
      isActive: json['isActive'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'isActive': isActive,
    };
  }
}

class GameProgress extends Equatable {
  final int totalTurns;
  final int completedTurns;

  const GameProgress({
    required this.totalTurns,
    required this.completedTurns,
  });

  @override
  List<Object?> get props => [totalTurns, completedTurns];

  factory GameProgress.fromJson(Map<String, dynamic> json) {
    return GameProgress(
      totalTurns: json['totalTurns'] as int,
      completedTurns: json['completedTurns'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalTurns': totalTurns,
      'completedTurns': completedTurns,
    };
  }
}

class GameSession extends Equatable {
  final String sessionId;
  final GameType gameType;
  final Turn currentTurn;
  final GamePrompt currentPrompt;
  final String? selectedChoice; // For truth or thrill
  final List<Player> players;
  final GameProgress? gameProgress;
  final DateTime? startedAt;
  final DateTime? lastActivityAt;

  const GameSession({
    required this.sessionId,
    required this.gameType,
    required this.currentTurn,
    required this.currentPrompt,
    this.selectedChoice,
    required this.players,
    this.gameProgress,
    this.startedAt,
    this.lastActivityAt,
  });

  @override
  List<Object?> get props => [
        sessionId,
        gameType,
        currentTurn,
        currentPrompt,
        selectedChoice,
        players,
        gameProgress,
        startedAt,
        lastActivityAt,
      ];

  GameSession copyWith({
    String? sessionId,
    GameType? gameType,
    Turn? currentTurn,
    GamePrompt? currentPrompt,
    String? selectedChoice,
    List<Player>? players,
    GameProgress? gameProgress,
    DateTime? startedAt,
    DateTime? lastActivityAt,
  }) {
    return GameSession(
      sessionId: sessionId ?? this.sessionId,
      gameType: gameType ?? this.gameType,
      currentTurn: currentTurn ?? this.currentTurn,
      currentPrompt: currentPrompt ?? this.currentPrompt,
      selectedChoice: selectedChoice ?? this.selectedChoice,
      players: players ?? this.players,
      gameProgress: gameProgress ?? this.gameProgress,
      startedAt: startedAt ?? this.startedAt,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
    );
  }

  bool isCurrentUserTurn(String currentUserId) {
    return currentTurn.userId == currentUserId;
  }

  Player? getCurrentPlayer() {
    return players.firstWhere(
      (player) => player.userId == currentTurn.userId,
      orElse: () => players.first,
    );
  }
}
