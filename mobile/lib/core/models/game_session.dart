import 'package:flutter/material.dart';

class GamePlayer {
  final String id;
  final String name;
  final String teamName;
  final String avatar;
  final Color teamColor;
  int score;
  int correctAnswers;

  GamePlayer({
    required this.id,
    required this.name,
    required this.teamName,
    required this.avatar,
    required this.teamColor,
    this.score = 0,
    this.correctAnswers = 0,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'teamName': teamName,
        'avatar': avatar,
        'score': score,
        'correctAnswers': correctAnswers,
      };
}

class GameQuestion {
  final dynamic id;
  final String prompt;
  final String answer;
  final List<String> options;
  final String? explanation;

  GameQuestion({
    this.id,
    required this.prompt,
    required this.answer,
    required this.options,
    this.explanation,
  });

  factory GameQuestion.fromMap(Map<String, dynamic> map) {
    final prompt = map['prompt']?.toString() ?? '';
    final answer = map['answer']?.toString() ?? '';
    List<String> options = [];

    if (map['options'] is List) {
      options = List<String>.from((map['options'] as List).map((e) => e.toString()));
    } else if (map['distractors'] is List) {
      final distractors = List<String>.from((map['distractors'] as List).map((e) => e.toString()));
      options = [answer, ...distractors]..shuffle();
    } else {
      options = [answer];
    }

    // تأكد من وجود الإجابة الصحيحة داخل الخيارات
    if (!options.contains(answer) && answer.isNotEmpty) {
      options.insert(0, answer);
    }

    return GameQuestion(
      id: map['id'],
      prompt: prompt,
      answer: answer,
      options: options,
      explanation: map['explanation']?.toString(),
    );
  }
}

class GameSession {
  final String gameSlug;
  final String gameTitle;
  final String gameRoute;
  final int totalRounds;
  final List<GamePlayer> players;
  final List<GameQuestion> questions;
  int currentRoundIndex; // 0-based

  GameSession({
    required this.gameSlug,
    required this.gameTitle,
    required this.gameRoute,
    required this.totalRounds,
    required this.players,
    required this.questions,
    this.currentRoundIndex = 0,
  });

  int get currentRoundNumber => currentRoundIndex + 1;
  bool get isLastRound => currentRoundNumber >= totalRounds;

  GamePlayer get activePlayer {
    if (players.isEmpty) {
      return GamePlayer(
        id: '1',
        name: 'اللاعب',
        teamName: 'فريق الأبطال',
        avatar: 'assets/images/av-ahmed.webp',
        teamColor: const Color(0xFF8B42FC),
      );
    }
    return players[currentRoundIndex % players.length];
  }

  GamePlayer get nextPlayer {
    if (players.isEmpty) return activePlayer;
    return players[(currentRoundIndex + 1) % players.length];
  }

  GameQuestion get currentQuestion {
    if (questions.isEmpty) {
      return GameQuestion(
        prompt: 'اللي اختشوا …',
        answer: 'ماتوا',
        options: ['ماتوا', 'هربوا', 'سكتوا'],
      );
    }
    return questions[currentRoundIndex % questions.length];
  }

  void recordAnswer({required bool isCorrect, int points = 3}) {
    if (isCorrect) {
      activePlayer.score += points;
      activePlayer.correctAnswers += 1;
    }
  }

  void advanceToNextRound() {
    currentRoundIndex++;
  }

  /// إحصائيات الفرق
  Map<String, int> get teamScores {
    final Map<String, int> map = {};
    for (final p in players) {
      map[p.teamName] = (map[p.teamName] ?? 0) + p.score;
    }
    return map;
  }

  List<MapEntry<String, int>> get rankedTeams {
    final entries = teamScores.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  List<GamePlayer> get rankedPlayers {
    final list = List<GamePlayer>.from(players);
    list.sort((a, b) => b.score.compareTo(a.score));
    return list;
  }

  GamePlayer? get mvp {
    if (players.isEmpty) return null;
    final sorted = List<GamePlayer>.from(players)
      ..sort((a, b) {
        final cmp = b.correctAnswers.compareTo(a.correctAnswers);
        if (cmp != 0) return cmp;
        return b.score.compareTo(a.score);
      });
    return sorted.first;
  }
}

