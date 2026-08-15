class GmsUser {
  GmsUser({
    required this.id,
    required this.username,
    required this.name,
    required this.role,
    required this.roleId,
    required this.schoolId,
    required this.students,
    required this.modules,
  });

  final int id;
  final String username;
  final String name;
  final String role;
  final int roleId;
  final int schoolId;
  final List<GmsStudent> students;
  final List<String> modules;

  factory GmsUser.fromJson(Map<String, dynamic> json) {
    final kids = (json['students'] as List<dynamic>? ?? [])
        .map((e) => GmsStudent.fromJson(e as Map<String, dynamic>))
        .toList();
    final mods = (json['modules'] as List<dynamic>? ?? []).map((e) => '$e').toList();
    return GmsUser(
      id: int.tryParse('${json['id']}') ?? 0,
      username: '${json['username'] ?? ''}',
      name: '${json['name'] ?? json['username'] ?? ''}',
      role: '${json['role'] ?? ''}',
      roleId: int.tryParse('${json['role_id']}') ?? 0,
      schoolId: int.tryParse('${json['school_id']}') ?? 0,
      students: kids,
      modules: mods.isEmpty
          ? const [
              'dashboard',
              'alerts',
              'students',
              'teachers',
              'invoices',
              'assignments',
              'exams',
              'liveclasses',
              'attendance',
              'notices',
            ]
          : mods,
    );
  }

  String get roleLabel => role.replaceAll('_', ' ');
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
    this.eventKey = '',
  });

  final int id;
  final String type;
  final String title;
  final String body;
  final String createdAt;
  final String eventKey;

  factory GmsAlert.fromJson(Map<String, dynamic> json) => GmsAlert(
        id: int.tryParse('${json['id']}') ?? 0,
        type: '${json['type'] ?? ''}',
        title: '${json['title'] ?? ''}',
        body: '${json['body'] ?? ''}',
        createdAt: '${json['created_at'] ?? ''}',
        eventKey: '${json['event_key'] ?? json['eventKey'] ?? ''}',
      );

  String get dedupeKey {
    if (eventKey.isNotEmpty) return eventKey;
    return 'id:$id';
  }
}
