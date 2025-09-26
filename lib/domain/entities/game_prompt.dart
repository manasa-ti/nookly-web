import 'package:equatable/equatable.dart';

class Prompt extends Equatable {
  final int id;
  final String type;
  final int stage;
  final String text;

  const Prompt({
    required this.id,
    required this.type,
    required this.stage,
    required this.text,
  });

  @override
  List<Object?> get props => [id, type, stage, text];

  factory Prompt.fromJson(Map<String, dynamic> json) {
    return Prompt(
      id: json['id'] as int,
      type: json['type'] as String,
      stage: json['stage'] as int,
      text: json['text'] as String? ?? 'Prompt text not available',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'stage': stage,
      'text': text,
    };
  }
}

class TruthOrThrillPrompt extends Equatable {
  final Prompt truth;
  final Prompt thrill;

  const TruthOrThrillPrompt({
    required this.truth,
    required this.thrill,
  });

  @override
  List<Object?> get props => [truth, thrill];

  factory TruthOrThrillPrompt.fromJson(Map<String, dynamic> json) {
    return TruthOrThrillPrompt(
      truth: Prompt.fromJson(json['truth'] as Map<String, dynamic>),
      thrill: Prompt.fromJson(json['thrill'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'truth': truth.toJson(),
      'thrill': thrill.toJson(),
    };
  }
}

class GamePrompt extends Equatable {
  // For truth or thrill games
  final TruthOrThrillPrompt? truthOrThrill;
  
  // For other games
  final Prompt? singlePrompt;

  const GamePrompt({
    this.truthOrThrill,
    this.singlePrompt,
  });

  @override
  List<Object?> get props => [truthOrThrill, singlePrompt];

  factory GamePrompt.fromJson(Map<String, dynamic> json, String gameType) {
    if (gameType == 'truth_or_thrill') {
      return GamePrompt(
        truthOrThrill: TruthOrThrillPrompt.fromJson(json),
      );
    } else {
      return GamePrompt(
        singlePrompt: Prompt.fromJson(json),
      );
    }
  }

  Map<String, dynamic> toJson() {
    if (truthOrThrill != null) {
      return truthOrThrill!.toJson();
    } else if (singlePrompt != null) {
      return singlePrompt!.toJson();
    }
    return {};
  }

  // Helper methods
  String? getDisplayText(String? selectedChoice) {
    if (truthOrThrill != null && selectedChoice != null) {
      return selectedChoice == 'truth' 
          ? truthOrThrill!.truth.text 
          : truthOrThrill!.thrill.text;
    } else if (singlePrompt != null) {
      return singlePrompt!.text;
    }
    return null;
  }

  bool get isTruthOrThrill => truthOrThrill != null;
  bool get isSinglePrompt => singlePrompt != null;
}





