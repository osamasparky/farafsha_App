class ContentCard {
  final int id;
  final String prompt;
  final String answer;
  final List<String> distractors;
  final List<String> forbiddenWords;
  final List<String> hints;
  final String? explanation;

  ContentCard({
    required this.id,
    required this.prompt,
    required this.answer,
    this.distractors = const [],
    this.forbiddenWords = const [],
    this.hints = const [],
    this.explanation,
  });

  factory ContentCard.fromJson(Map<String, dynamic> json) {
    return ContentCard(
      id: json['id'] as int? ?? 0,
      prompt: json['prompt'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
      distractors: (json['distractors'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      forbiddenWords: (json['forbidden_words'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      hints: (json['hints'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      explanation: json['explanation'] as String?,
    );
  }

  /// خلط الخيارات (الإجابة الصحيحة مع المشتتات) عشوائياً
  List<String> get randomizedChoices {
    final list = [answer, ...distractors];
    list.shuffle();
    return list;
  }
}

