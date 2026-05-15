import 'user_role.dart';

enum RegistrationStatus {
  pending,
  approved,
  rejected,
}

enum AttendanceStatusType {
  present,
  late,
  absent,
}

enum AbsenceReason {
  none,
  unexcused,
  sickLeave,
  excused,
}

enum AssignmentKind {
  homework,
  testWork,
}

const List<String> standardLessonTimeRanges = [
  '08:30 - 09:15',
  '09:30 - 10:15',
  '10:30 - 11:15',
  '11:30 - 12:15',
  '13:00 - 13:45',
  '14:00 - 14:45',
];

class RegistrationRequest {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final UserRole role;
  final String? schoolClass;
  final String? parentFullName;
  final String? parentEmail;
  final String? parentPhone;
  final DateTime requestedAt;
  final RegistrationStatus status;
  final DateTime? reviewedAt;
  final String? reviewNote;

  const RegistrationRequest({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    required this.requestedAt,
    this.schoolClass,
    this.parentFullName,
    this.parentEmail,
    this.parentPhone,
    this.status = RegistrationStatus.pending,
    this.reviewedAt,
    this.reviewNote,
  });

  RegistrationRequest copyWith({
    RegistrationStatus? status,
    DateTime? reviewedAt,
    String? reviewNote,
  }) {
    return RegistrationRequest(
      id: id,
      fullName: fullName,
      email: email,
      phone: phone,
      role: role,
      schoolClass: schoolClass,
      parentFullName: parentFullName,
      parentEmail: parentEmail,
      parentPhone: parentPhone,
      requestedAt: requestedAt,
      status: status ?? this.status,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewNote: reviewNote ?? this.reviewNote,
    );
  }
}

class SchoolClass {
  final String id;
  final String name;

  const SchoolClass({
    required this.id,
    required this.name,
  });
}

class LessonAssignment {
  final String id;
  final String classId;
  final String teacherId;
  final String subject;
  final int weekdayIndex;
  final String timeRange;
  final String room;

  const LessonAssignment({
    required this.id,
    required this.classId,
    required this.teacherId,
    required this.subject,
    required this.weekdayIndex,
    required this.timeRange,
    required this.room,
  });
}

class AttendanceEntry {
  final String studentId;
  final AttendanceStatusType status;
  final AbsenceReason reason;

  const AttendanceEntry({
    required this.studentId,
    required this.status,
    this.reason = AbsenceReason.none,
  });
}

class AttendanceSession {
  final String id;
  final String classId;
  final String lessonId;
  final String teacherId;
  final DateTime recordedAt;
  final List<AttendanceEntry> entries;

  const AttendanceSession({
    required this.id,
    required this.classId,
    required this.lessonId,
    required this.teacherId,
    required this.recordedAt,
    required this.entries,
  });
}

class GradeEntry {
  final String id;
  final String studentId;
  final String lessonId;
  final String classId;
  final String teacherId;
  final String subject;
  final int value;
  final String category;
  final String comment;
  final DateTime createdAt;

  const GradeEntry({
    required this.id,
    required this.studentId,
    required this.lessonId,
    required this.classId,
    required this.teacherId,
    required this.subject,
    required this.value,
    required this.category,
    required this.comment,
    required this.createdAt,
  });
}

class ManagedSchoolFile {
  final String id;
  final String name;
  final String category;
  final String? classId;
  final String uploadedByUserId;
  final DateTime uploadedAt;
  final String sizeLabel;
  final String? storagePath;
  final String? downloadUrl;
  final String? contentType;
  final String? topic;
  final String? description;

  const ManagedSchoolFile({
    required this.id,
    required this.name,
    required this.category,
    required this.uploadedByUserId,
    required this.uploadedAt,
    required this.sizeLabel,
    this.classId,
    this.storagePath,
    this.downloadUrl,
    this.contentType,
    this.topic,
    this.description,
  });
}

class HomeworkAssignment {
  final String id;
  final String classId;
  final String teacherId;
  final String subject;
  final String title;
  final String description;
  final DateTime dueAt;
  final AssignmentKind kind;
  final bool urgent;
  final bool requiresFile;
  final DateTime createdAt;

  const HomeworkAssignment({
    required this.id,
    required this.classId,
    required this.teacherId,
    required this.subject,
    required this.title,
    required this.description,
    required this.dueAt,
    required this.kind,
    required this.urgent,
    required this.requiresFile,
    required this.createdAt,
  });
}

class HomeworkSubmission {
  final String id;
  final String assignmentId;
  final String studentId;
  final String fileName;
  final String sizeLabel;
  final String? storagePath;
  final String? downloadUrl;
  final bool late;
  final DateTime submittedAt;
  final int? grade;
  final String? gradeComment;

  const HomeworkSubmission({
    required this.id,
    required this.assignmentId,
    required this.studentId,
    required this.fileName,
    required this.sizeLabel,
    required this.late,
    required this.submittedAt,
    this.storagePath,
    this.downloadUrl,
    this.grade,
    this.gradeComment,
  });

  HomeworkSubmission copyWith({
    int? grade,
    String? gradeComment,
  }) {
    return HomeworkSubmission(
      id: id,
      assignmentId: assignmentId,
      studentId: studentId,
      fileName: fileName,
      sizeLabel: sizeLabel,
      late: late,
      submittedAt: submittedAt,
      storagePath: storagePath,
      downloadUrl: downloadUrl,
      grade: grade ?? this.grade,
      gradeComment: gradeComment ?? this.gradeComment,
    );
  }
}

class ParentMeeting {
  final String id;
  final String classId;
  final String teacherId;
  final String title;
  final String agenda;
  final String location;
  final DateTime meetingAt;
  final DateTime createdAt;

  const ParentMeeting({
    required this.id,
    required this.classId,
    required this.teacherId,
    required this.title,
    required this.agenda,
    required this.location,
    required this.meetingAt,
    required this.createdAt,
  });
}

class AuditLogEntry {
  final String id;
  final String actorId;
  final UserRole actorRole;
  final String action;
  final String targetType;
  final String targetId;
  final DateTime createdAt;
  final Map<String, Object?> metadata;

  const AuditLogEntry({
    required this.id,
    required this.actorId,
    required this.actorRole,
    required this.action,
    required this.targetType,
    required this.targetId,
    required this.createdAt,
    this.metadata = const {},
  });
}

class QuarterGrade {
  final String id;
  final String studentId;
  final String classId;
  final String subject;
  final int quarter;
  final int value;
  final double averageGrade;
  final String teacherId;
  final DateTime createdAt;

  const QuarterGrade({
    required this.id,
    required this.studentId,
    required this.classId,
    required this.subject,
    required this.quarter,
    required this.value,
    required this.averageGrade,
    required this.teacherId,
    required this.createdAt,
  });
}

class ChatMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.createdAt,
  });
}

class ParentStudentLink {
  final String id;
  final String parentId;
  final String studentId;
  final DateTime createdAt;

  const ParentStudentLink({
    required this.id,
    required this.parentId,
    required this.studentId,
    required this.createdAt,
  });
}

class ParentClassLink {
  final String id;
  final String parentId;
  final String classId;
  final DateTime createdAt;

  const ParentClassLink({
    required this.id,
    required this.parentId,
    required this.classId,
    required this.createdAt,
  });
}
