import 'dart:math';

enum CardSuit {
  clubs, // ♣
  spades, // ♠
  hearts, // ♥
  diamonds, // ♦
}

extension CardSuitX on CardSuit {
  String get suitSymbol {
    switch (this) {
      case CardSuit.hearts:
        return '♥';
      case CardSuit.diamonds:
        return '♦';
      case CardSuit.spades:
        return '♠';
      case CardSuit.clubs:
        return '♣';
    }
  }
}

enum CardRank {
  two,
  three,
  four,
  five,
  six,
  seven,
  eight,
  nine,
  ten,
  jack,
  queen,
  king,
  ace,
}

class PlayingCard {
  final CardSuit suit;
  final CardRank rank;

  const PlayingCard({required this.suit, required this.rank});

  String get suitSymbol {
    switch (suit) {
      case CardSuit.hearts:
        return '♥';
      case CardSuit.diamonds:
        return '♦';
      case CardSuit.spades:
        return '♠';
      case CardSuit.clubs:
        return '♣';
    }
  }

  String get suitArabicName {
    switch (suit) {
      case CardSuit.hearts:
        return 'كبة';
      case CardSuit.diamonds:
        return 'ديناري';
      case CardSuit.spades:
        return 'بستوني';
      case CardSuit.clubs:
        return 'سباتي';
    }
  }

  String get suitCode {
    switch (suit) {
      case CardSuit.hearts:
        return 'H';
      case CardSuit.diamonds:
        return 'D';
      case CardSuit.spades:
        return 'S';
      case CardSuit.clubs:
        return 'C';
    }
  }

  /// ترتيب الألوان في الطرنيب والاستميشن: ♣ < ♠ < ♥ < ♦
  int get suitOrder {
    switch (suit) {
      case CardSuit.clubs:
        return 0;
      case CardSuit.spades:
        return 1;
      case CardSuit.hearts:
        return 2;
      case CardSuit.diamonds:
        return 3;
    }
  }

  String get rankLabel {
    switch (rank) {
      case CardRank.two:
        return '2';
      case CardRank.three:
        return '3';
      case CardRank.four:
        return '4';
      case CardRank.five:
        return '5';
      case CardRank.six:
        return '6';
      case CardRank.seven:
        return '7';
      case CardRank.eight:
        return '8';
      case CardRank.nine:
        return '9';
      case CardRank.ten:
        return '10';
      case CardRank.jack:
        return 'J';
      case CardRank.queen:
        return 'Q';
      case CardRank.king:
        return 'K';
      case CardRank.ace:
        return 'A';
    }
  }

  /// قيمة الورقة الرقمية في الكومي (A=1, 2..10=face, J/Q/K=0)
  int get komiValue {
    switch (rank) {
      case CardRank.ace:
        return 1;
      case CardRank.two:
        return 2;
      case CardRank.three:
        return 3;
      case CardRank.four:
        return 4;
      case CardRank.five:
        return 5;
      case CardRank.six:
        return 6;
      case CardRank.seven:
        return 7;
      case CardRank.eight:
        return 8;
      case CardRank.nine:
        return 9;
      case CardRank.ten:
        return 10;
      case CardRank.jack:
      case CardRank.queen:
      case CardRank.king:
        return 0;
    }
  }

  /// قوة الورقة في اللعب (2=2 ... A=14)
  int get trickPower => rank.index + 2;

  bool get isRed => suit == CardSuit.hearts || suit == CardSuit.diamonds;
  bool get isFaceCard => rank == CardRank.jack || rank == CardRank.queen || rank == CardRank.king;
  bool get isShayeb => suit == CardSuit.hearts && rank == CardRank.king;
  bool get isKomiSeven => suit == CardSuit.diamonds && rank == CardRank.seven;

  String get faceAssetPath => 'assets/cards/faces/$rankLabel$suitCode.svg';
  String get id => '$rankLabel$suitCode';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is PlayingCard && other.suit == suit && other.rank == rank);

  @override
  int get hashCode => Object.hash(suit, rank);

  static List<PlayingCard> standardDeck({bool shayeb49 = false}) {
    final deck = <PlayingCard>[];
    for (final s in CardSuit.values) {
      for (final r in CardRank.values) {
        if (shayeb49 && r == CardRank.king && s != CardSuit.hearts) {
          continue; // في الشايب: نحذف K♠ K♦ K♣ ونبقي K♥ فقط
        }
        deck.add(PlayingCard(suit: s, rank: r));
      }
    }
    deck.shuffle(Random.secure());
    return deck;
  }

  static void sortHand(List<PlayingCard> hand) {
    hand.sort((a, b) {
      final suitCmp = a.suitOrder.compareTo(b.suitOrder);
      if (suitCmp != 0) return suitCmp;
      return a.trickPower.compareTo(b.trickPower);
    });
  }
}
