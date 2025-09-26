import 'package:nookly/domain/entities/game_session.dart';
import 'package:nookly/domain/entities/game_prompt.dart';

class GameSessionModel extends GameSession {
  const GameSessionModel({
    required super.sessionId,
    required super.gameType,
    required super.currentTurn,
    required super.currentPrompt,
    super.selectedChoice,
    required super.players,
    super.gameProgress,
    super.startedAt,
    super.lastActivityAt,
  });

  factory GameSessionModel.fromJson(Map<String, dynamic> json) {
    // Infer game type from prompt type if gameType is null
    String gameTypeString = json['gameType'] as String? ?? 'truth_or_thrill';
    if (gameTypeString == 'truth_or_thrill' && json['currentPrompt'] != null) {
      final promptType = json['currentPrompt']['type'] as String?;
      if (promptType == 'memory') {
        gameTypeString = 'memory_sparks';
      } else if (promptType == 'question') {
        gameTypeString = 'would_you_rather';
      } else if (promptType == 'guess') {
        gameTypeString = 'guess_me';
      }
    }
    
    return GameSessionModel(
      sessionId: json['sessionId'] as String,
      gameType: GameType.fromApiValue(gameTypeString),
      currentTurn: Turn.fromJson(json['currentTurn'] as Map<String, dynamic>),
      currentPrompt: GamePrompt.fromJson(
        json['currentPrompt'] as Map<String, dynamic>,
        gameTypeString,
      ),
      selectedChoice: json['selectedChoice'] as String?,
      players: (json['players'] as List)
          .map((player) => Player.fromJson(player as Map<String, dynamic>))
          .toList(),
      gameProgress: json['gameProgress'] != null
          ? GameProgress.fromJson(json['gameProgress'] as Map<String, dynamic>)
          : null,
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : null,
      lastActivityAt: json['lastActivityAt'] != null
          ? DateTime.parse(json['lastActivityAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'gameType': gameType.apiValue,
      'currentTurn': currentTurn.toJson(),
      'currentPrompt': currentPrompt.toJson(),
      'selectedChoice': selectedChoice,
      'players': players.map((player) => player.toJson()).toList(),
      'gameProgress': gameProgress?.toJson(),
      'startedAt': startedAt?.toIso8601String(),
      'lastActivityAt': lastActivityAt?.toIso8601String(),
    };
  }

  factory GameSessionModel.fromEntity(GameSession entity) {
    return GameSessionModel(
      sessionId: entity.sessionId,
      gameType: entity.gameType,
      currentTurn: entity.currentTurn,
      currentPrompt: entity.currentPrompt,
      selectedChoice: entity.selectedChoice,
      players: entity.players,
      gameProgress: entity.gameProgress,
      startedAt: entity.startedAt,
      lastActivityAt: entity.lastActivityAt,
    );
  }
}





