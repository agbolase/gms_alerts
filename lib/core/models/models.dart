class GmsUser {
  GmsUser({
    required this.id,
    required this.username,
    required this.name,
    required this.role,
    required this.students,
  });

  final int id;
  final String username;
  final String name;
  final String role;
  final List<GmsStudent> students;

  factory GmsUser.fromJson(Map<String, dynamic> json) {
    final kids = (json['students'] as List<dynamic>? ?? [])
        .map((e) => GmsStudent.fromJson(e as Map<String, dynamic>))
        .toList();
    return GmsUser(
      id: int.tryParse('${json['id']}') ?? 0,
      username: '${json['username'] ?? ''}',
      name: '${json['name'] ?? json['username'] ?? ''}',
      role: '${json['role'] ?? ''}',
      students: kids,
    );
  }
}

class GmsStudent {
  GmsStudent({required this.id, required this.name});
  final int id;
  final String name;

  factory GmsStudent.fromJson(Map<String, dynamic> json) => GmsStudent(
        id: int.tryParse('${json['id']}') ?? 0,
        name: '${json['name'] ?? ''}',
      );
}

class GmsAlert {
  GmsAlert({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
  });

  final int id;
  final String type;
  final String title;
  final String body;
  final String createdAt;

  factory GmsAlert.fromJson(Map<String, dynamic> json) => GmsAlert(
        id: int.tryParse('${json['id']}') ?? 0,
        type: '${json['type'] ?? ''}',
        title: '${json['title'] ?? ''}',
        body: '${json['body'] ?? ''}',
        createdAt: '${json['created_at'] ?? ''}',
      );
}
