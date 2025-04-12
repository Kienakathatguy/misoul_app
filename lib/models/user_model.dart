class UserModel {
  final String name;
  final String avatarUrl;
  final String mood;
  final int happinessLevel;
  final int miBotTime;
  final Map<String, dynamic> tasks;

  UserModel({
    required this.name,
    required this.avatarUrl,
    required this.mood,
    required this.happinessLevel,
    required this.miBotTime,
    required this.tasks,
  });

  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      name: data['name'],
      avatarUrl: data['avatarUrl'],
      mood: data['mood'],
      happinessLevel: data['happinessLevel'],
      miBotTime: data['miBot']['remainingTime'],
      tasks: Map<String, dynamic>.from(data['tasks']),
    );
  }
}
