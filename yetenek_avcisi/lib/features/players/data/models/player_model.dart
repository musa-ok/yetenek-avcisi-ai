class PlayerModel {
  final String id;
  final String userId;
  final String name;
  final int age;
  final String position;
  final int overallRating;
  final int? pace;
  final int? shooting;
  final int? passing;
  final int? dribbling;
  final int? defending;
  final int? physical;
  final String? aiScoutReport;
  final String? videoUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PlayerModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.age,
    required this.position,
    required this.overallRating,
    this.pace,
    this.shooting,
    this.passing,
    this.dribbling,
    this.defending,
    this.physical,
    this.aiScoutReport,
    this.videoUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory PlayerModel.fromJson(Map<String, dynamic> json) {
    return PlayerModel(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      name: json['name'] ?? '',
      age: json['age'] ?? 0,
      position: json['position'] ?? '',
      overallRating: json['overall_rating'] ?? 50,
      pace: json['pace'],
      shooting: json['finishing'], // API'da finishing olarak geliyor
      passing: json['passing'],
      dribbling: json['dribbling'],
      defending: json['tackling'],
      physical: json['strength'],
      aiScoutReport: json['ai_scout_report'],
      videoUrl: json['video_url'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'age': age,
      'position': position,
      'overall_rating': overallRating,
      'pace': pace,
      'finishing': shooting,
      'passing': passing,
      'dribbling': dribbling,
      'tackling': defending,
      'strength': physical,
      'ai_scout_report': aiScoutReport,
      'video_url': videoUrl,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  PlayerModel copyWith({
    String? id,
    String? userId,
    String? name,
    int? age,
    String? position,
    int? overallRating,
    int? pace,
    int? shooting,
    int? passing,
    int? dribbling,
    int? defending,
    int? physical,
    String? aiScoutReport,
    String? videoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PlayerModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      age: age ?? this.age,
      position: position ?? this.position,
      overallRating: overallRating ?? this.overallRating,
      pace: pace ?? this.pace,
      shooting: shooting ?? this.shooting,
      passing: passing ?? this.passing,
      dribbling: dribbling ?? this.dribbling,
      defending: defending ?? this.defending,
      physical: physical ?? this.physical,
      aiScoutReport: aiScoutReport ?? this.aiScoutReport,
      videoUrl: videoUrl ?? this.videoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlayerModel &&
        other.id == id &&
        other.userId == userId &&
        other.name == name &&
        other.age == age &&
        other.position == position &&
        other.overallRating == overallRating;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        name.hashCode ^
        age.hashCode ^
        position.hashCode ^
        overallRating.hashCode;
  }

  @override
  String toString() {
    return 'PlayerModel(id: $id, name: $name, position: $position, rating: $overallRating)';
  }
}
