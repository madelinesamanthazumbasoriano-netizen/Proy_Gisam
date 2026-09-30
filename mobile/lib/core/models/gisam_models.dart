class GisamProgress {
  final int level;
  final int xp;
  final int xpRequired;
  final int water;
  final int health;
  final int happiness;

  const GisamProgress({
    this.level = 1,
    this.xp = 0,
    this.xpRequired = 1000,
    this.water = 50,
    this.health = 50,
    this.happiness = 50,
  });

  double get progress => (xp / xpRequired).clamp(0, 1).toDouble();

  GisamProgress copyWith({
    int? level,
    int? xp,
    int? xpRequired,
    int? water,
    int? health,
    int? happiness,
  }) {
    return GisamProgress(
      level: level ?? this.level,
      xp: xp ?? this.xp,
      xpRequired: xpRequired ?? this.xpRequired,
      water: water ?? this.water,
      health: health ?? this.health,
      happiness: happiness ?? this.happiness,
    );
  }

  factory GisamProgress.fromJson(Map<String, dynamic> json) {
    return GisamProgress(
      level: json['level'] ?? 1,
      xp: json['xp'] ?? 0,
      xpRequired: json['xp_required'] ?? 1000,
      water: json['water'] ?? 50,
      health: json['health'] ?? 50,
      happiness: json['happiness'] ?? 50,
    );
  }
}

class GisamMission {
  final String id;
  final String title;
  final int xp;
  final bool completed;

  const GisamMission({
    required this.id,
    required this.title,
    required this.xp,
    this.completed = false,
  });

  GisamMission copyWith({
    String? id,
    String? title,
    int? xp,
    bool? completed,
  }) {
    return GisamMission(
      id: id ?? this.id,
      title: title ?? this.title,
      xp: xp ?? this.xp,
      completed: completed ?? this.completed,
    );
  }

  factory GisamMission.fromJson(Map<String, dynamic> json) {
    return GisamMission(
      id: json['id'],
      title: json['title'],
      xp: json['xp'] ?? 0,
      completed: json['completed'] ?? false,
    );
  }
}
