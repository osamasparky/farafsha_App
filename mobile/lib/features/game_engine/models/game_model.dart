import 'content_card.dart';

class GameModel {
  final int id;
  final String name;
  final String slug;
  final String subtitle;
  final String description;
  final String icon;
  final String category;
  final String templateType;
  final int minPlayers;
  final int maxPlayers;
  final int defaultRounds;
  final int defaultDurationSeconds;
  final String? badgeText;
  final List<ContentCard> cards;

  GameModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.category,
    required this.templateType,
    this.minPlayers = 2,
    this.maxPlayers = 10,
    this.defaultRounds = 10,
    this.defaultDurationSeconds = 20,
    this.badgeText,
    this.cards = const [],
  });

  factory GameModel.fromJson(Map<String, dynamic> json) {
    return GameModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      description: json['description'] as String? ?? '',
      icon: json['icon'] as String? ?? 'games',
      category: json['category'] as String? ?? 'party',
      templateType: json['template_type'] as String? ?? 'choice',
      minPlayers: json['min_players'] as int? ?? 2,
      maxPlayers: json['max_players'] as int? ?? 10,
      defaultRounds: json['default_rounds'] as int? ?? 10,
      defaultDurationSeconds: json['default_duration_seconds'] as int? ?? 20,
      badgeText: json['badge_text'] as String?,
      cards: (json['cards'] as List<dynamic>?)
              ?.map((e) => ContentCard.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

