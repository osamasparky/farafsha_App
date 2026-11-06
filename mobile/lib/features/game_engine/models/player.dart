class Player {
  final String id;
  final String name;
  final String? avatar;
  int score;
  final bool isHost;

  Player({
    required this.id,
    required this.name,
    this.avatar,
    this.score = 0,
    this.isHost = false,
  });

  Player copyWith({
    String? id,
    String? name,
    String? avatar,
    int? score,
    bool? isHost,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      score: score ?? this.score,
      isHost: isHost ?? this.isHost,
    );
  }
}

