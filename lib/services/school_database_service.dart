import 'package:cloud_firestore/cloud_firestore.dart';

class SchoolDatabaseSnapshot {
  final List<Map<String, dynamic>> accounts;
  final List<Map<String, dynamic>> registrationRequests;
  final List<Map<String, dynamic>> schoolClasses;
  final List<Map<String, dynamic>> teacherClasses;
  final List<Map<String, dynamic>> lessons;
  final List<Map<String, dynamic>> grades;
  final List<Map<String, dynamic>> files;
  final List<Map<String, dynamic>> attendanceSessions;
  final List<Map<String, dynamic>> homeworkAssignments;
  final List<Map<String, dynamic>> homeworkSubmissions;
  final List<Map<String, dynamic>> parentMeetings;
  final List<Map<String, dynamic>> auditLogs;
  final List<Map<String, dynamic>> parentStudentLinks;
  final List<Map<String, dynamic>> parentClassLinks;

  const SchoolDatabaseSnapshot({
    this.accounts = const [],
    this.registrationRequests = const [],
    this.schoolClasses = const [],
    this.teacherClasses = const [],
    this.lessons = const [],
    this.grades = const [],
    this.files = const [],
    this.attendanceSessions = const [],
    this.homeworkAssignments = const [],
    this.homeworkSubmissions = const [],
    this.parentMeetings = const [],
    this.auditLogs = const [],
    this.parentStudentLinks = const [],
    this.parentClassLinks = const [],
  });

  bool get isEmpty =>
      accounts.isEmpty &&
      registrationRequests.isEmpty &&
      schoolClasses.isEmpty &&
      teacherClasses.isEmpty &&
      lessons.isEmpty &&
      grades.isEmpty &&
      files.isEmpty &&
      attendanceSessions.isEmpty &&
      homeworkAssignments.isEmpty &&
      homeworkSubmissions.isEmpty &&
      parentMeetings.isEmpty &&
      auditLogs.isEmpty &&
      parentStudentLinks.isEmpty &&
      parentClassLinks.isEmpty;
}

abstract class SchoolDatabaseService {
  Future<SchoolDatabaseSnapshot> loadSnapshot();
  Future<void> seedIfEmpty(SchoolDatabaseSnapshot snapshot);
  Future<void> setAccount(String id, Map<String, dynamic> data);
  Future<void> deleteAccount(String id);
  Future<void> setRegistrationRequest(String id, Map<String, dynamic> data);
  Future<void> setSchoolClass(String id, Map<String, dynamic> data);
  Future<void> deleteSchoolClass(String id);
  Future<void> setLesson(String id, Map<String, dynamic> data);
  Future<void> setTeacherClass(String id, Map<String, dynamic> data);
  Future<void> setGrade(String id, Map<String, dynamic> data);
  Future<void> deleteGrade(String id);
  Future<void> setFile(String id, Map<String, dynamic> data);
  Future<void> setAttendanceSession(String id, Map<String, dynamic> data);
  Future<void> deleteAttendanceSession(String id);
  Future<void> setHomeworkAssignment(String id, Map<String, dynamic> data);
  Future<void> setHomeworkSubmission(String id, Map<String, dynamic> data);
  Future<void> deleteHomeworkSubmission(String id);
  Future<void> setParentMeeting(String id, Map<String, dynamic> data);
  Future<void> setAuditLog(String id, Map<String, dynamic> data);
  Future<void> setParentStudentLink(String id, Map<String, dynamic> data);
  Future<void> deleteParentStudentLink(String id);
  Future<void> setParentClassLink(String id, Map<String, dynamic> data);
  Future<void> deleteParentClassLink(String id);
}

class FirestoreSchoolDatabaseService implements SchoolDatabaseService {
  final FirebaseFirestore _firestore;
  final String schoolId;

  FirestoreSchoolDatabaseService({
    FirebaseFirestore? firestore,
    this.schoolId = 'default',
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> get _schoolDoc =>
      _firestore.collection('schools').doc(schoolId);

  CollectionReference<Map<String, dynamic>> _collection(String name) =>
      _schoolDoc.collection(name);

  @override
  Future<SchoolDatabaseSnapshot> loadSnapshot() async {
    final results = await Future.wait([
      _readCollection('accounts'),
      _readCollection('registrationRequests'),
      _readCollection('classes'),
      _readCollection('teacherClasses'),
      _readCollection('lessons'),
      _readCollection('grades'),
      _readCollection('files'),
      _readCollection('attendanceSessions'),
      _readCollection('homeworkAssignments'),
      _readCollection('homeworkSubmissions'),
      _readCollection('parentMeetings'),
      _readCollection('auditLogs'),
      _readCollection('parentStudents'),
      _readCollection('parentClasses'),
    ]);

    return SchoolDatabaseSnapshot(
      accounts: results[0],
      registrationRequests: results[1],
      schoolClasses: results[2],
      teacherClasses: results[3],
      lessons: results[4],
      grades: results[5],
      files: results[6],
      attendanceSessions: results[7],
      homeworkAssignments: results[8],
      homeworkSubmissions: results[9],
      parentMeetings: results[10],
      auditLogs: results[11],
      parentStudentLinks: results[12],
      parentClassLinks: results[13],
    );
  }

  @override
  Future<void> seedIfEmpty(SchoolDatabaseSnapshot snapshot) async {
    final existing = await Future.wait([
      _collection('accounts').limit(1).get(),
      _collection('classes').limit(1).get(),
      _collection('lessons').limit(1).get(),
    ]);
    if (existing.any((query) => query.docs.isNotEmpty)) {
      return;
    }

    final batch = _firestore.batch();
    _addSnapshotToBatch(batch, 'accounts', snapshot.accounts);
    _addSnapshotToBatch(
      batch,
      'registrationRequests',
      snapshot.registrationRequests,
    );
    _addSnapshotToBatch(batch, 'classes', snapshot.schoolClasses);
    _addSnapshotToBatch(batch, 'teacherClasses', snapshot.teacherClasses);
    _addSnapshotToBatch(batch, 'lessons', snapshot.lessons);
    _addSnapshotToBatch(batch, 'grades', snapshot.grades);
    _addSnapshotToBatch(batch, 'files', snapshot.files);
    _addSnapshotToBatch(
      batch,
      'attendanceSessions',
      snapshot.attendanceSessions,
    );
    _addSnapshotToBatch(
      batch,
      'homeworkAssignments',
      snapshot.homeworkAssignments,
    );
    _addSnapshotToBatch(
      batch,
      'homeworkSubmissions',
      snapshot.homeworkSubmissions,
    );
    _addSnapshotToBatch(batch, 'parentMeetings', snapshot.parentMeetings);
    _addSnapshotToBatch(batch, 'auditLogs', snapshot.auditLogs);
    _addSnapshotToBatch(batch, 'parentStudents', snapshot.parentStudentLinks);
    _addSnapshotToBatch(batch, 'parentClasses', snapshot.parentClassLinks);
    batch.set(
      _schoolDoc.collection('metadata').doc('app'),
      {
        'seededAt': FieldValue.serverTimestamp(),
        'schemaVersion': 1,
      },
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  @override
  Future<void> setAccount(String id, Map<String, dynamic> data) =>
      _setDocument('accounts', id, data);

  @override
  Future<void> deleteAccount(String id) => _deleteDocument('accounts', id);

  @override
  Future<void> setRegistrationRequest(String id, Map<String, dynamic> data) =>
      _setDocument('registrationRequests', id, data);

  @override
  Future<void> setSchoolClass(String id, Map<String, dynamic> data) =>
      _setDocument('classes', id, data);

  @override
  Future<void> deleteSchoolClass(String id) => _deleteDocument('classes', id);

  @override
  Future<void> setLesson(String id, Map<String, dynamic> data) =>
      _setDocument('lessons', id, data);

  @override
  Future<void> setTeacherClass(String id, Map<String, dynamic> data) =>
      _setDocument('teacherClasses', id, data);

  @override
  Future<void> setGrade(String id, Map<String, dynamic> data) =>
      _setDocument('grades', id, data);

  @override
  Future<void> deleteGrade(String id) => _deleteDocument('grades', id);

  @override
  Future<void> setFile(String id, Map<String, dynamic> data) =>
      _setDocument('files', id, data);

  @override
  Future<void> setAttendanceSession(String id, Map<String, dynamic> data) =>
      _setDocument('attendanceSessions', id, data);

  @override
  Future<void> deleteAttendanceSession(String id) =>
      _deleteDocument('attendanceSessions', id);

  @override
  Future<void> setHomeworkAssignment(String id, Map<String, dynamic> data) =>
      _setDocument('homeworkAssignments', id, data);

  @override
  Future<void> setHomeworkSubmission(String id, Map<String, dynamic> data) =>
      _setDocument('homeworkSubmissions', id, data);

  @override
  Future<void> deleteHomeworkSubmission(String id) =>
      _deleteDocument('homeworkSubmissions', id);

  @override
  Future<void> setParentMeeting(String id, Map<String, dynamic> data) =>
      _setDocument('parentMeetings', id, data);

  @override
  Future<void> setAuditLog(String id, Map<String, dynamic> data) =>
      _setDocument('auditLogs', id, data);

  @override
  Future<void> setParentStudentLink(String id, Map<String, dynamic> data) =>
      _setDocument('parentStudents', id, data);

  @override
  Future<void> deleteParentStudentLink(String id) =>
      _deleteDocument('parentStudents', id);

  @override
  Future<void> setParentClassLink(String id, Map<String, dynamic> data) =>
      _setDocument('parentClasses', id, data);

  @override
  Future<void> deleteParentClassLink(String id) =>
      _deleteDocument('parentClasses', id);

  Future<List<Map<String, dynamic>>> _readCollection(String name) async {
    final snapshot = await _collection(name).get();
    return snapshot.docs.map((doc) {
      return _normalizeMap({
        ...doc.data(),
        'id': doc.id,
      });
    }).toList();
  }

  Future<void> _setDocument(
    String collection,
    String id,
    Map<String, dynamic> data,
  ) {
    return _collection(collection).doc(id).set(
      {
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> _deleteDocument(String collection, String id) {
    return _collection(collection).doc(id).delete();
  }

  void _addSnapshotToBatch(
    WriteBatch batch,
    String collection,
    List<Map<String, dynamic>> documents,
  ) {
    for (final data in documents) {
      final id = data['id']?.toString();
      if (id == null || id.isEmpty) {
        continue;
      }
      batch.set(
        _collection(collection).doc(id),
        {
          ...data,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }
  }

  Map<String, dynamic> _normalizeMap(Map<String, dynamic> source) {
    return source.map(
      (key, value) => MapEntry(key, _normalizeValue(value)),
    );
  }

  dynamic _normalizeValue(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is Map) {
      return value.map(
        (key, nestedValue) => MapEntry(
          key.toString(),
          _normalizeValue(nestedValue),
        ),
      );
    }
    if (value is Iterable) {
      return value.map(_normalizeValue).toList();
    }
    return value;
  }
}
