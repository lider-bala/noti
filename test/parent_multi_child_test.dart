import 'package:flutter_test/flutter_test.dart';
import 'package:noti_flutter_converted/app/app_state.dart';
import 'package:noti_flutter_converted/services/school_database_service.dart';

class _TestDatabaseService implements SchoolDatabaseService {
  final SchoolDatabaseSnapshot snapshot;
  _TestDatabaseService(this.snapshot);

  @override
  Future<SchoolDatabaseSnapshot> loadSnapshot() async => snapshot;
  @override
  Future<void> seedIfEmpty(SchoolDatabaseSnapshot snapshot) async {}
  @override
  Future<void> setAccount(String id, Map<String, dynamic> data) async {}
  @override
  Future<void> deleteAccount(String id) async {}
  @override
  Future<void> setRegistrationRequest(
      String id, Map<String, dynamic> data) async {}
  @override
  Future<void> setSchoolClass(String id, Map<String, dynamic> data) async {}
  @override
  Future<void> deleteSchoolClass(String id) async {}
  @override
  Future<void> setLesson(String id, Map<String, dynamic> data) async {}
  @override
  Future<void> setTeacherClass(String id, Map<String, dynamic> data) async {}
  @override
  Future<void> setGrade(String id, Map<String, dynamic> data) async {}
  @override
  Future<void> deleteGrade(String id) async {}
  @override
  Future<void> setFile(String id, Map<String, dynamic> data) async {}
  @override
  Future<void> setAttendanceSession(
      String id, Map<String, dynamic> data) async {}
  @override
  Future<void> deleteAttendanceSession(String id) async {}
  @override
  Future<void> setHomeworkAssignment(
      String id, Map<String, dynamic> data) async {}
  @override
  Future<void> setHomeworkSubmission(
      String id, Map<String, dynamic> data) async {}
  @override
  Future<void> deleteHomeworkSubmission(String id) async {}
  @override
  Future<void> setParentMeeting(String id, Map<String, dynamic> data) async {}
  @override
  Future<void> setAuditLog(String id, Map<String, dynamic> data) async {}
  @override
  Future<void> setParentStudentLink(
      String id, Map<String, dynamic> data) async {}
  @override
  Future<void> deleteParentStudentLink(String id) async {}
  @override
  Future<void> setParentClassLink(String id, Map<String, dynamic> data) async {}
  @override
  Future<void> deleteParentClassLink(String id) async {}
}

void main() {
  group('Real AppState Parent-Child Logic', () {
    test('parent with two children in index sees two', () async {
      final snapshot = SchoolDatabaseSnapshot(
        accounts: [
          {
            'id': 'parent1',
            'role': 'parent',
            'status': 'active',
          },
          {
            'id': 'child1',
            'role': 'student',
            'status': 'active',
            'schoolClass': 'classA'
          },
          {
            'id': 'child2',
            'role': 'student',
            'status': 'active',
            'schoolClass': 'classB'
          },
        ],
        parentStudentLinks: [
          {
            'id': 'parent1_child1',
            'parentId': 'parent1',
            'studentId': 'child1'
          },
          {
            'id': 'parent1_child2',
            'parentId': 'parent1',
            'studentId': 'child2'
          },
        ],
        parentClassLinks: [
          {'id': 'parent1_classA', 'parentId': 'parent1', 'classId': 'classA'},
          {'id': 'parent1_classB', 'parentId': 'parent1', 'classId': 'classB'},
        ],
      );

      final state = AppState(
        enableDemoData: false,
        database: _TestDatabaseService(snapshot),
      );
      await state.synchronizeDatabase();

      final parent = state.userById('parent1')!;
      final children = state.childrenForParent(parent);

      expect(children.length, 2);
      expect(children.any((c) => c.id == 'child1'), isTrue);
      expect(children.any((c) => c.id == 'child2'), isTrue);

      expect(state.parentCanAccessClass(parent.id, 'classA'), isTrue);
      expect(state.parentCanAccessClass(parent.id, 'classB'), isTrue);
      expect(state.parentCanAccessClass(parent.id, 'classC'), isFalse);
    });

    test('parent without links sees zero children', () async {
      final snapshot = SchoolDatabaseSnapshot(
        accounts: [
          {'id': 'parent_empty', 'role': 'parent', 'status': 'active'},
        ],
      );
      final state = AppState(
        enableDemoData: false,
        database: _TestDatabaseService(snapshot),
      );
      await state.synchronizeDatabase();

      final parent = state.userById('parent_empty')!;
      expect(state.childrenForParent(parent).isEmpty, isTrue);
    });

    test('fallback linkedStudentId works in client migration', () async {
      final snapshot = SchoolDatabaseSnapshot(
        accounts: [
          {
            'id': 'parent1',
            'role': 'parent',
            'status': 'active',
            'linkedStudentId': 'old_child'
          },
        ],
      );
      final state = AppState(
        enableDemoData: false,
        database: _TestDatabaseService(snapshot),
      );
      await state.synchronizeDatabase();
      final parent = state.userById('parent1')!;

      expect(parent.linkedStudentIds.contains('old_child'), isTrue);
    });
  });
}
