class User {
  final int id;
  final String email;
  final String? name;
  final String? gender;
  final int? age;
  final double? height;
  final double? weight;
  final String? activityLevel;
  final String? goal;
  final double? targetWeight;
  final int? durationWeeks;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.email,
    this.name,
    this.gender,
    this.age,
    this.height,
    this.weight,
    this.activityLevel,
    this.goal,
    this.targetWeight,
    this.durationWeeks,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      gender: json['gender'],
      age: json['age'],
      height: (json['height'] != null) ? json['height'].toDouble() : null,
      weight: (json['weight'] != null) ? json['weight'].toDouble() : null,
      activityLevel: json['activity_level'],
      goal: json['goal'],
      targetWeight:
          (json['target_weight'] != null)
              ? json['target_weight'].toDouble()
              : null,
      durationWeeks: json['duration_weeks'],
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'gender': gender,
      'age': age,
      'height': height,
      'weight': weight,
      'activity_level': activityLevel,
      'goal': goal,
      'target_weight': targetWeight,
      'duration_weeks': durationWeeks,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

class Meal {
  final String name;
  final int grams;
  final int kcal;
  final String type;

  Meal({
    required this.name,
    required this.grams,
    required this.kcal,
    required this.type,
  });

  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      name: json['name'],
      grams: json['grams'],
      kcal: json['kcal'],
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'grams': grams,
    'kcal': kcal,
    'type': type,
  };
}
