import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noti_flutter_converted/app/app_state.dart';
import 'package:noti_flutter_converted/screens/admin/admin_overview_screen.dart';
import 'package:noti_flutter_converted/services/school_database_service.dart';

class _TestDatabaseService implements SchoolDatabaseService {
  @override
  Future<SchoolDatabaseSnapshot> loadSnapshot() async =>
      const SchoolDatabaseSnapshot(accounts: []);
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
  group('Real Widget Responsive Tests', () {
    testWidgets('AdminOverviewScreen renders without overflow on 350px',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(350, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final state = AppState(
        enableDemoData: false,
        database: _TestDatabaseService(),
      );
      await state.synchronizeDatabase();

      await tester.pumpWidget(
        AppStateScope(
          state: state,
          child: const MaterialApp(
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            home: Scaffold(body: AdminOverviewScreen()),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Операционный центр школы'), findsOneWidget);
    });
  });
}
