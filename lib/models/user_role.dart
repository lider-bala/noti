enum UserRole {
  teacher,
  student,
  parent,
  admin,
}

enum UserStatus {
  active,
  blocked,
  deleted,
}

class AppUser {
  final String id;
  final String fullName;
  final String? email;
  final String? phone;
  final UserRole role;
  final UserStatus status;
  final String? schoolClass;
  final String? linkedStudentId;
  final List<String> linkedStudentIds;

  const AppUser({
    required this.id,
    required this.fullName,
    this.email,
    this.phone,
    required this.role,
    this.status = UserStatus.active,
    this.schoolClass,
    this.linkedStudentId,
    this.linkedStudentIds = const [],
  });

  bool get isActive => status == UserStatus.active;

  AppUser copyWith({
    String? fullName,
    String? email,
    String? phone,
    UserRole? role,
    UserStatus? status,
    String? schoolClass,
    String? linkedStudentId,
    List<String>? linkedStudentIds,
  }) {
    return AppUser(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      status: status ?? this.status,
      schoolClass: schoolClass ?? this.schoolClass,
      linkedStudentId: linkedStudentId ?? this.linkedStudentId,
      linkedStudentIds: linkedStudentIds ?? this.linkedStudentIds,
    );
  }

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) {
      return 'NA';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first.substring(0, 1)}${parts[1].substring(0, 1)}'
        .toUpperCase();
  }
}
