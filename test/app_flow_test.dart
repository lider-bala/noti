import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noti_flutter_converted/app/app_language.dart';
import 'package:noti_flutter_converted/app/app_state.dart';
import 'package:noti_flutter_converted/models/school_models.dart';
import 'package:noti_flutter_converted/models/user_role.dart';
import 'package:noti_flutter_converted/screens/admin/admin_main_screen.dart';
import 'package:noti_flutter_converted/screens/login_screen.dart';
import 'package:noti_flutter_converted/screens/parents/parent_main_screen.dart';
import 'package:noti_flutter_converted/screens/register_screen.dart';
import 'package:noti_flutter_converted/screens/student/student_main_screen.dart';
import 'package:noti_flutter_converted/screens/teacher/main_screen.dart';
import 'package:noti_flutter_converted/screens/student/student_classmates_screen.dart';
import 'package:noti_flutter_converted/services/monitoring_service.dart';
import 'package:noti_flutter_converted/services/school_database_service.dart';
import 'package:noti_flutter_converted/widgets/app_select_field.dart';

class _MemoryDatabaseService implements SchoolDatabaseService {
  SchoolDatabaseSnapshot snapshot;
  final deletedHomeworkSubmissionIds = <String>[];
  bool failWrites = false;

  _MemoryDatabaseService(this.snapshot);

  Future<void> _write() async {
    if (failWrites) {
      throw StateError('write failed');
    }
  }

  @override
  Future<SchoolDatabaseSnapshot> loadSnapshot() async => snapshot;

  @override
  Future<void> seedIfEmpty(SchoolDatabaseSnapshot snapshot) async {
    this.snapshot = snapshot;
  }

  @override
  Future<void> setAccount(String id, Map<String, dynamic> data) => _write();

  @override
  Future<void> deleteAccount(String id) => _write();

  @override
  Future<void> setRegistrationRequest(
    String id,
    Map<String, dynamic> data,
  ) =>
      _write();

  @override
  Future<void> setSchoolClass(String id, Map<String, dynamic> data) => _write();

  @override
  Future<void> deleteSchoolClass(String id) => _write();

  @override
  Future<void> setLesson(String id, Map<String, dynamic> data) => _write();

  @override
  Future<void> setTeacherClass(String id, Map<String, dynamic> data) =>
      _write();

  @override
  Future<void> setGrade(String id, Map<String, dynamic> data) => _write();

  @override
  Future<void> deleteGrade(String id) => _write();

  @override
  Future<void> setFile(String id, Map<String, dynamic> data) => _write();

  @override
  Future<void> setAttendanceSession(String id, Map<String, dynamic> data) =>
      _write();

  @override
  Future<void> deleteAttendanceSession(String id) => _write();

  @override
  Future<void> setHomeworkAssignment(String id, Map<String, dynamic> data) =>
      _write();

  @override
  Future<void> setHomeworkSubmission(String id, Map<String, dynamic> data) =>
      _write();

  @override
  Future<void> deleteHomeworkSubmission(String id) async {
    await _write();
    deletedHomeworkSubmissionIds.add(id);
  }

  @override
  Future<void> setParentMeeting(String id, Map<String, dynamic> data) =>
      _write();

  @override
  Future<void> setAuditLog(String id, Map<String, dynamic> data) => _write();

  @override
  Future<void> setParentStudentLink(String id, Map<String, dynamic> data) =>
      _write();

  @override
  Future<void> deleteParentStudentLink(String id) => _write();

  @override
  Future<void> setParentClassLink(String id, Map<String, dynamic> data) =>
      _write();

  @override
  Future<void> deleteParentClassLink(String id) => _write();
}

class _RecordingMonitoringService implements MonitoringService {
  final events = <String>[];

  @override
  Future<void> logEvent(
    String name, {
    Map<String, Object?> parameters = const {},
  }) async {
    events.add(name);
  }

  @override
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    String? reason,
    Map<String, Object?> parameters = const {},
  }) async {}
}

void main() {
  AppState demoState({
    SchoolDatabaseService? database,
    bool allowLateHomeworkSubmissions = true,
    MonitoringService? monitoringService,
  }) {
    return AppState(
      database: database,
      enableDemoData: true,
      allowLateHomeworkSubmissions: allowLateHomeworkSubmissions,
      monitoringService: monitoringService,
    );
  }

  Future<void> waitForUi(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump(const Duration(milliseconds: 350));
  }

  Future<void> pumpScoped(
    WidgetTester tester, {
    required AppState state,
    required Widget child,
    Size size = const Size(1440, 900),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      AppStateScope(
        state: state,
        child: AnimatedBuilder(
          animation: state,
          builder: (context, _) {
            return MaterialApp(
              locale: state.language.locale,
              supportedLocales: const [
                Locale('ru', 'KG'),
                Locale('ky', 'KG'),
              ],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              theme: ThemeData(
                brightness: Brightness.light,
                useMaterial3: true,
              ),
              darkTheme: ThemeData(
                brightness: Brightness.dark,
                useMaterial3: true,
              ),
              themeMode: state.themeMode,
              home: child,
            );
          },
        ),
      ),
    );
    await waitForUi(tester);
  }

  test('app state requires admin approval before authentication', () async {
    final state = demoState();

    final registration = await state.registerUser(
      fullName: 'Тестовый Администратор',
      email: 'qa-admin@noti.kg',
      phone: '+996555777999',
      password: 'admin999',
      role: UserRole.admin,
    );

    expect(registration.isSuccess, isTrue);
    expect(registration.isPendingApproval, isTrue);
    expect(registration.user, isNull);

    final pendingAuth = state.authenticate(
      role: UserRole.admin,
      email: 'qa-admin@noti.kg',
      password: 'admin999',
    );

    expect(pendingAuth.isSuccess, isFalse);
    expect(
      pendingAuth.errorKey,
      'Заявка ещё на рассмотрении администратора.',
    );

    final approved = await state.approveRegistrationRequest(
      registration.request!.id,
    );
    expect(approved.isSuccess, isTrue);

    final auth = state.authenticate(
      role: UserRole.admin,
      email: 'qa-admin@noti.kg',
      password: 'admin999',
    );

    expect(auth.isSuccess, isTrue);
    expect(auth.user?.fullName, 'Тестовый Администратор');
  });

  test('database snapshot can clear seeded local collections', () async {
    final database = _MemoryDatabaseService(
      SchoolDatabaseSnapshot(
        accounts: [
          {
            'id': 'admin-only',
            'fullName': 'Only Admin',
            'email': 'only-admin@noti.kg',
            'phone': '+996700100100',
            'role': 'admin',
            'passwordHash': '',
            'createdAt': DateTime(2026),
          },
        ],
        schoolClasses: [],
        lessons: [],
      ),
    );
    final state = demoState(database: database);

    await state.synchronizeDatabase();

    expect(state.accounts.length, 1);
    expect(state.schoolClasses, isEmpty);
    expect(state.lessons, isEmpty);
  });

  test('default app state starts without demo accounts unless enabled', () {
    final productionState = AppState();
    expect(productionState.accounts, isEmpty);
    expect(productionState.schoolClasses, isEmpty);

    final bootstrapState = AppState(enableBootstrapAdmin: true);
    expect(bootstrapState.accounts.length, 1);
    expect(bootstrapState.accounts.single.user.role, UserRole.admin);
    final bootstrapAuth = bootstrapState.authenticate(
      role: UserRole.admin,
      email: 'admin@noti.kg',
      password: 'admin123',
    );
    expect(bootstrapAuth.isSuccess, isTrue);

    final devState = demoState();
    expect(devState.accounts, isNotEmpty);
    expect(devState.schoolClasses, isNotEmpty);
  });

  test('failed database writes rollback local class creation', () async {
    final database = _MemoryDatabaseService(const SchoolDatabaseSnapshot())
      ..failWrites = true;
    final state = demoState(database: database);

    final before = state.schoolClasses.length;
    final result = await state.createSchoolClass('12А');

    expect(result.isSuccess, isFalse);
    expect(state.schoolClasses.length, before);
    expect(state.schoolClasses.any((item) => item.id == '12А'), isFalse);
    expect(state.databaseError, contains('write failed'));
  });

  test('blocked and deleted users cannot authenticate', () async {
    final blockedState = AppState(
      database: _MemoryDatabaseService(
        SchoolDatabaseSnapshot(
          accounts: [
            {
              'id': 'student-demo',
              'fullName': 'Blocked Student',
              'email': 'student@noti.kg',
              'phone': '+996555000222',
              'role': 'student',
              'status': 'blocked',
              'schoolClass': '10А',
              'createdAt': DateTime(2026),
            },
          ],
        ),
      ),
    );
    await blockedState.synchronizeDatabase();
    final blockedAuth = blockedState.authenticate(
      role: UserRole.student,
      email: 'student@noti.kg',
      password: 'student123',
    );
    expect(blockedAuth.isSuccess, isFalse);
    blockedState.setUser(blockedState.accounts.first.user);
    expect(blockedState.currentUser, isNull);

    final deletedState = AppState(
      database: _MemoryDatabaseService(
        SchoolDatabaseSnapshot(
          accounts: [
            {
              'id': 'student-demo',
              'fullName': 'Deleted Student',
              'email': 'student@noti.kg',
              'phone': '+996555000222',
              'role': 'student',
              'status': 'deleted',
              'schoolClass': '10А',
              'createdAt': DateTime(2026),
            },
          ],
        ),
      ),
    );
    await deletedState.synchronizeDatabase();
    final auth = deletedState.authenticate(
      role: UserRole.student,
      email: 'student@noti.kg',
      password: 'student123',
    );
    expect(auth.isSuccess, isFalse);
  });

  test('parent without linkedStudentId does not see class fallback student',
      () async {
    final state = AppState(
      enableDemoData: false,
      database: _MemoryDatabaseService(
        SchoolDatabaseSnapshot(
          accounts: [
            {
              'id': 'student-x',
              'fullName': 'Exact Student',
              'email': 'student-x@noti.kg',
              'phone': '+996700200001',
              'role': 'student',
              'status': 'active',
              'schoolClass': '10А',
              'createdAt': DateTime(2026),
            },
            {
              'id': 'parent-without-link',
              'fullName': 'Unlinked Parent',
              'email': 'parent-x@noti.kg',
              'phone': '+996700200002',
              'role': 'parent',
              'status': 'active',
              'schoolClass': '10А',
              'createdAt': DateTime(2026),
            },
          ],
        ),
      ),
    );
    await state.synchronizeDatabase();

    final parent = state.userById('parent-without-link');
    expect(parent, isNotNull);
    expect(state.childrenForParent(parent).isEmpty, isTrue);
  });

  test('homework submission marks late and can reject late submissions',
      () async {
    final state = demoState();
    final teacherAuth = state.authenticate(
      role: UserRole.teacher,
      email: 'teacher@noti.kg',
      password: 'teacher123',
    );
    state.setUser(teacherAuth.user);

    final assignment = await state.createHomeworkAssignment(
      classId: '10А',
      subject: 'Математика',
      title: 'Просроченное задание',
      description: 'Проверка late flag',
      dueAt: DateTime.now().subtract(const Duration(days: 1)),
      kind: AssignmentKind.homework,
      requiresFile: true,
    );
    expect(assignment.isSuccess, isTrue);

    final studentAuth = state.authenticate(
      role: UserRole.student,
      email: 'student@noti.kg',
      password: 'student123',
    );
    state.setUser(studentAuth.user);

    final submission = await state.submitHomeworkFile(
      assignmentId: assignment.data!.id,
      fileName: 'late.pdf',
      sizeLabel: '1 КБ',
      storagePath: 'schools/default/homework-submissions/student-demo/late.pdf',
      downloadUrl: 'https://example.com/late.pdf',
    );
    expect(submission.isSuccess, isTrue);
    expect(submission.data?.late, isTrue);

    final strictState = demoState(allowLateHomeworkSubmissions: false);
    final strictTeacherAuth = strictState.authenticate(
      role: UserRole.teacher,
      email: 'teacher@noti.kg',
      password: 'teacher123',
    );
    strictState.setUser(strictTeacherAuth.user);
    final strictAssignment = await strictState.createHomeworkAssignment(
      classId: '10А',
      subject: 'Математика',
      title: 'Запрещенная поздняя сдача',
      description: 'Проверка reject policy',
      dueAt: DateTime.now().subtract(const Duration(days: 1)),
      kind: AssignmentKind.homework,
      requiresFile: true,
    );
    final strictStudentAuth = strictState.authenticate(
      role: UserRole.student,
      email: 'student@noti.kg',
      password: 'student123',
    );
    strictState.setUser(strictStudentAuth.user);
    final rejected = await strictState.submitHomeworkFile(
      assignmentId: strictAssignment.data!.id,
      fileName: 'late.pdf',
      sizeLabel: '1 КБ',
      storagePath: 'schools/default/homework-submissions/student-demo/late.pdf',
      downloadUrl: 'https://example.com/late.pdf',
    );
    expect(rejected.isSuccess, isFalse);
    expect(rejected.errorKey, 'homework.lateSubmissionRejected');
  });

  test('admin writes create audit log entries and monitoring event', () async {
    final monitoring = _RecordingMonitoringService();
    final state = demoState(monitoringService: monitoring);
    final auth = state.authenticate(
      role: UserRole.admin,
      email: 'admin@noti.kg',
      password: 'admin123',
    );
    state.setUser(auth.user);

    final created = await state.createSchoolClass('12Б');

    expect(created.isSuccess, isTrue);
    expect(state.auditLogs, isNotEmpty);
    expect(state.auditLogs.first.action, 'class.create');
    expect(state.auditLogs.first.actorId, auth.user!.id);
    expect(monitoring.events, contains(MonitoringEvents.adminAction));
  });

  test('monitoring records key write events', () async {
    final monitoring = _RecordingMonitoringService();
    final state = demoState(monitoringService: monitoring);
    final teacherAuth = state.authenticate(
      role: UserRole.teacher,
      email: 'teacher@noti.kg',
      password: 'teacher123',
    );
    state.setUser(teacherAuth.user);

    final lesson = state.lessonsForTeacher(teacherAuth.user!.id).first;
    await state.recordGrades(
      lessonId: lesson.id,
      grades: {'student-demo': 5},
      category: 'QA',
    );
    await state.recordAttendance(
      classId: lesson.classId,
      lessonId: lesson.id,
      statuses: {'student-demo': AttendanceStatusType.present},
      reasons: const {},
    );

    expect(monitoring.events, contains(MonitoringEvents.gradeCreated));
    expect(monitoring.events, contains(MonitoringEvents.attendanceSaved));
  });

  test('admin-created parent is linked to the exact student', () async {
    final state = demoState();

    final created = await state.adminCreateStudentWithParent(
      studentFullName: 'Новый Ученик',
      studentEmail: 'new-student@noti.kg',
      studentPhone: '+996700000001',
      studentPassword: 'student123',
      classId: '10А',
      parentFullName: 'Родитель Ученика',
      parentEmail: 'new-parent@noti.kg',
      parentPhone: '+996700000002',
      parentPassword: 'parent123',
    );

    expect(created.isSuccess, isTrue);
    final student = created.data!.first.user;
    final parent = created.data!.last.user;

    expect(parent.linkedStudentIds.contains(student.id), isTrue);
    expect(parent.linkedStudentId, student.id); // Check backwards compatibility
    expect(state.childrenForParent(parent).first.id, student.id);
  });

  test('student resubmission deletes previous homework submission remotely',
      () async {
    final database = _MemoryDatabaseService(const SchoolDatabaseSnapshot());
    final state = demoState(database: database);
    final auth = state.authenticate(
      role: UserRole.student,
      email: 'student@noti.kg',
      password: 'student123',
    );
    state.setUser(auth.user);

    final first = await state.submitHomeworkFile(
      assignmentId: 'assignment-10a-math-homework',
      fileName: 'first.pdf',
      sizeLabel: '1 КБ',
    );
    final second = await state.submitHomeworkFile(
      assignmentId: 'assignment-10a-math-homework',
      fileName: 'second.pdf',
      sizeLabel: '2 КБ',
    );

    await Future<void>.delayed(Duration.zero);

    expect(first.isSuccess, isTrue);
    expect(second.isSuccess, isTrue);
    expect(database.deletedHomeworkSubmissionIds, contains(first.data!.id));
  });

  test('student registration approval creates linked parent account', () async {
    final state = demoState();

    final registration = await state.registerUser(
      fullName: 'Регистрация Ученика',
      email: 'student-register@noti.kg',
      phone: '+996700010001',
      password: 'student123',
      role: UserRole.student,
      schoolClass: '10А',
      parentFullName: 'Родитель Регистрации',
      parentEmail: 'parent-register@noti.kg',
      parentPhone: '+996700010002',
      parentPassword: 'parent123',
    );

    expect(registration.isPendingApproval, isTrue);
    final approved = await state.approveRegistrationRequest(
      registration.request!.id,
    );
    expect(approved.isSuccess, isTrue);

    final studentAuth = state.authenticate(
      role: UserRole.student,
      email: 'student-register@noti.kg',
      password: 'student123',
    );
    final parentAuth = state.authenticate(
      role: UserRole.parent,
      email: 'parent-register@noti.kg',
      password: 'parent123',
    );

    expect(studentAuth.isSuccess, isTrue);
    expect(parentAuth.isSuccess, isTrue);
    expect(
      state.childrenForParent(parentAuth.user!).first.id,
      studentAuth.user!.id,
    );
  });

  test('schedule conflicts and foreign attendance entries are rejected',
      () async {
    final state = demoState();
    final teacherAuth = state.authenticate(
      role: UserRole.teacher,
      email: 'teacher@noti.kg',
      password: 'teacher123',
    );
    state.setUser(teacherAuth.user);

    expect(
      (await state.createLessonAssignment(
        classId: '10А',
        teacherId: 'teacher-demo',
        subject: 'Дубликат',
        weekdayIndex: 0,
        timeRange: '08:30 - 09:15',
        room: '999',
      ))
          .isSuccess,
      isFalse,
    );

    final saved = await state.recordAttendance(
      classId: '10А',
      lessonId: 'lesson-10a-math-1',
      statuses: {
        'student-10b-1': AttendanceStatusType.absent,
      },
      reasons: {
        'student-10b-1': AbsenceReason.unexcused,
      },
    );

    expect(saved.isSuccess, isFalse);
  });

  test('teacher records attendance reasons and grades consistently', () async {
    final state = demoState();
    final auth = state.authenticate(
      role: UserRole.teacher,
      email: 'teacher@noti.kg',
      password: 'teacher123',
    );
    state.setUser(auth.user);

    final attendanceSaved = await state.recordAttendance(
      classId: '10А',
      lessonId: 'lesson-10a-math-1',
      statuses: {
        'student-demo': AttendanceStatusType.absent,
        'student-10a-1': AttendanceStatusType.present,
      },
      reasons: {
        'student-demo': AbsenceReason.excused,
      },
    );

    expect(attendanceSaved.isSuccess, isTrue);
    final attendance = state.latestAttendanceForLesson('lesson-10a-math-1');
    final entry = state.attendanceEntryForStudent(
      session: attendance!,
      studentId: 'student-demo',
    );
    expect(entry?.status, AttendanceStatusType.absent);
    expect(entry?.reason, AbsenceReason.excused);

    final gradesSaved = await state.recordGrades(
      lessonId: 'lesson-10a-math-1',
      grades: {
        'student-demo': 5,
        'student-10a-1': 4,
      },
      category: 'Самостоятельная работа',
      comment: 'Проверено',
    );

    expect(gradesSaved.isSuccess, isTrue);
    expect(
      state.gradesForStudent('student-demo').any(
            (grade) =>
                grade.lessonId == 'lesson-10a-math-1' &&
                grade.value == 5 &&
                grade.category == 'Самостоятельная работа',
          ),
      isTrue,
    );
    expect(state.gradesForTeacher('teacher-demo').length, greaterThan(0));
  });

  test('app state maps theme preferences to Flutter theme modes', () {
    final state = demoState();

    expect(state.themePreference, AppThemePreference.system);
    expect(state.themeMode, ThemeMode.system);

    state.setThemePreference(AppThemePreference.dark);
    expect(state.themePreference, AppThemePreference.dark);
    expect(state.themeMode, ThemeMode.dark);

    state.setThemePreference(AppThemePreference.light);
    expect(state.themePreference, AppThemePreference.light);
    expect(state.themeMode, ThemeMode.light);
  });

  test('teacher creates assignments meetings and student submits file metadata',
      () async {
    final state = demoState();
    final teacherAuth = state.authenticate(
      role: UserRole.teacher,
      email: 'teacher@noti.kg',
      password: 'teacher123',
    );
    state.setUser(teacherAuth.user);

    final assignment = await state.createHomeworkAssignment(
      classId: '10А',
      subject: 'Математика',
      title: 'Контрольная работа по функциям',
      description: 'Повторить графики и свойства функций',
      dueAt: DateTime.now().add(const Duration(days: 4)),
      kind: AssignmentKind.testWork,
      urgent: true,
      requiresFile: true,
    );
    final meeting = state.createParentMeeting(
      classId: '10А',
      title: 'Родительское собрание 10А',
      agenda: 'Контрольные работы и посещаемость',
      location: 'Каб. 205',
      meetingAt: DateTime.now().add(const Duration(days: 5)),
    );

    expect(assignment.isSuccess, isTrue);
    expect(assignment.data?.kind, AssignmentKind.testWork);
    expect(meeting, isNotNull);
    expect(state.meetingsForClass('10А'), contains(meeting));

    final studentAuth = state.authenticate(
      role: UserRole.student,
      email: 'student@noti.kg',
      password: 'student123',
    );
    state.setUser(studentAuth.user);

    final submission = await state.submitHomeworkFile(
      assignmentId: assignment.data!.id,
      fileName: 'functions.pdf',
      sizeLabel: '320 КБ',
      storagePath: 'schools/default/test/functions.pdf',
      downloadUrl: 'https://example.com/functions.pdf',
    );

    expect(submission.isSuccess, isTrue);
    expect(
      state
          .submissionForAssignment(
            assignmentId: assignment.data!.id,
            studentId: studentAuth.user!.id,
          )
          ?.fileName,
      'functions.pdf',
    );
  });

  test('app state rejects empty create payloads consistently', () async {
    final state = demoState();

    expect(
      (await state.adminCreateAccount(
        fullName: '',
        email: 'empty-user@noti.kg',
        phone: '+996555111222',
        password: 'school123',
        role: UserRole.teacher,
      ))
          .isSuccess,
      isFalse,
    );
    expect(
      (await state.createLessonAssignment(
        classId: '10А',
        teacherId: 'teacher-demo',
        subject: '',
        weekdayIndex: 0,
        timeRange: '08:00 - 08:45',
        room: '205',
      ))
          .isSuccess,
      isFalse,
    );

    final teacherAuth = state.authenticate(
      role: UserRole.teacher,
      email: 'teacher@noti.kg',
      password: 'teacher123',
    );
    state.setUser(teacherAuth.user);

    expect(
      (await state.createManagedFile(
        name: '',
        category: 'Документы',
        sizeLabel: '1 МБ',
      ))
          .isSuccess,
      isFalse,
    );
    expect(
      (await state.createManagedFile(
        name: 'Учебный план',
        category: '',
        sizeLabel: '1 МБ',
      ))
          .isSuccess,
      isFalse,
    );
  });

  testWidgets('login screen authenticates teacher and keeps russian language',
      (tester) async {
    final state = demoState();
    AppUser? loggedInUser;

    await pumpScoped(
      tester,
      state: state,
      child: LoginScreen(
        onRegister: () {},
        onLogin: (user) => loggedInUser = user,
      ),
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'teacher@noti.kg');
    await tester.enterText(find.byType(TextFormField).at(1), 'teacher123');
    await tester.tap(find.text('Войти').first);
    await waitForUi(tester);

    expect(loggedInUser?.role, UserRole.teacher);

    state.setLanguage(AppLanguage.kyrgyz);
    await waitForUi(tester);

    expect(state.language, AppLanguage.russian);
    expect(find.text('Войти'), findsWidgets);
  });

  testWidgets('register screen creates pending admin request', (tester) async {
    final state = demoState();
    AppUser? registeredUser;
    var switchedToLogin = false;

    await pumpScoped(
      tester,
      state: state,
      child: RegisterScreen(
        onRegistered: (user) => registeredUser = user,
        onLoginTap: () => switchedToLogin = true,
      ),
    );

    await tester.ensureVisible(find.text('Админ').first);
    await tester.tap(find.text('Админ').first);
    await waitForUi(tester);

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'Тестовый Администратор',
    );
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'qa-admin@noti.kg',
    );
    await tester.enterText(
      find.byType(TextFormField).at(2),
      '+996555777999',
    );
    await tester.enterText(find.byType(TextFormField).at(3), 'admin999');
    await tester.enterText(find.byType(TextFormField).at(4), 'admin999');

    await tester.tap(find.text('Зарегистрироваться').last);
    await waitForUi(tester);

    expect(registeredUser, isNull);
    expect(switchedToLogin, isTrue);
    expect(
      state.registrationRequests
          .any((request) => request.email == 'qa-admin@noti.kg'),
      isTrue,
    );
  });

  testWidgets('teacher main screen navigates and keeps russian language',
      (tester) async {
    final state = demoState();
    final auth = state.authenticate(
      role: UserRole.teacher,
      email: 'teacher@noti.kg',
      password: 'teacher123',
    );
    state.setUser(auth.user);

    var didLogout = false;

    await pumpScoped(
      tester,
      state: state,
      child: MainScreen(
        onLogout: () => didLogout = true,
      ),
    );

    expect(find.text('Ближайший урок'), findsOneWidget);

    await tester.tap(find.text('Настройки').first);
    await waitForUi(tester);
    expect(find.text('Тема приложения'), findsOneWidget);
    await tester.ensureVisible(find.text('Тёмная'));
    await waitForUi(tester);
    await tester.tap(find.text('Тёмная'));
    await waitForUi(tester);
    expect(state.themePreference, AppThemePreference.dark);

    await tester.tap(find.text('Домашние задания').first);
    await waitForUi(tester);
    await tester.ensureVisible(find.text('+ Создать новое задание'));
    await tester.tap(find.text('+ Создать новое задание'));
    await waitForUi(tester);
    expect(find.text('Новое задание или контрольная'), findsOneWidget);
    await tester.tap(find.text('Отмена'));
    await waitForUi(tester);

    state.setLanguage(AppLanguage.kyrgyz);
    await waitForUi(tester);
    expect(state.language, AppLanguage.russian);
    expect(find.text('Домашние задания'), findsWidgets);

    await tester.tap(find.text('Выйти'));
    await waitForUi(tester);
    expect(didLogout, isTrue);
  });

  testWidgets(
      'teacher opens students directory and schedule attendance workflow',
      (tester) async {
    final state = demoState();
    final auth = state.authenticate(
      role: UserRole.teacher,
      email: 'teacher@noti.kg',
      password: 'teacher123',
    );
    state.setUser(auth.user);

    await pumpScoped(
      tester,
      state: state,
      child: MainScreen(
        onLogout: () {},
      ),
    );

    await tester.tap(find.text('Ученики').first);
    await waitForUi(tester);
    expect(find.text('Ученики и классы'), findsOneWidget);
    expect(find.text('Учителя класса 10А'), findsOneWidget);

    await tester.tap(find.text('Расписание').first);
    await waitForUi(tester);
    await tester.tap(find.text('Проверить посещаемость').first);
    await waitForUi(tester);
    expect(find.text('Журнал посещаемости'), findsOneWidget);
    await tester.ensureVisible(find.text('Сохранить посещаемость'));
    await waitForUi(tester);
    await tester.tap(find.text('Сохранить посещаемость'));
    await waitForUi(tester);
    expect(find.text('Расписание'), findsWidgets);
    expect(find.text('Журнал посещаемости'), findsNothing);

    await tester.tap(find.text('Оценки').first);
    await waitForUi(tester);
    expect(find.text('Журнал оценок'), findsOneWidget);
    expect(find.text('Сохранить оценки'), findsOneWidget);
  });

  testWidgets('teacher students screen renders on mobile width',
      (tester) async {
    final state = demoState();
    final auth = state.authenticate(
      role: UserRole.teacher,
      email: 'teacher@noti.kg',
      password: 'teacher123',
    );
    state.setUser(auth.user);

    await pumpScoped(
      tester,
      state: state,
      child: MainScreen(
        onLogout: () {},
      ),
      size: const Size(515, 900),
    );

    await tester.tap(find.byIcon(Icons.menu_rounded).first);
    await waitForUi(tester);
    await tester.tap(find.text('Ученики').first);
    await waitForUi(tester);

    expect(find.text('Ученики и классы'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('student main screen handles submit action', (tester) async {
    final state = demoState();
    final auth = state.authenticate(
      role: UserRole.student,
      email: 'student@noti.kg',
      password: 'student123',
    );
    state.setUser(auth.user);

    await pumpScoped(
      tester,
      state: state,
      child: StudentMainScreen(
        onLogout: () {},
      ),
    );

    expect(find.text('Ближайший урок'), findsOneWidget);

    await tester.tap(find.text('Домашние задания').first);
    await waitForUi(tester);
    await tester.ensureVisible(find.text('Сдать').first);
    expect(find.text('Сдать'), findsWidgets);

    await tester.tap(find.text('Оценки').first);
    await waitForUi(tester);
    expect(find.text('Мои оценки'), findsOneWidget);

    await tester.tap(find.text('Расписание').first);
    await waitForUi(tester);
    expect(find.text('Моё расписание'), findsOneWidget);

    await tester.tap(find.text('Настройки').first);
    await waitForUi(tester);
    expect(find.text('Тема приложения'), findsOneWidget);
  });

  testWidgets('student classmates screen renders at 320px without fake data',
      (tester) async {
    final state = demoState();
    final auth = state.authenticate(
      role: UserRole.student,
      email: 'student@noti.kg',
      password: 'student123',
    );
    state.setUser(auth.user);

    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      AppStateScope(
        state: state,
        child: MaterialApp(
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('ru', 'KG'),
            Locale('ky', 'KG'),
          ],
          home: const Scaffold(
            body: StudentClassmatesScreen(),
          ),
        ),
      ),
    );
    await waitForUi(tester);

    expect(find.text('alex@student.com'), findsNothing);
    expect(find.text('alex@noti.kg'), findsOneWidget);
    expect(find.textContaining('Класс 10А'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('parent main screen opens notifications', (tester) async {
    final state = demoState();
    final auth = state.authenticate(
      role: UserRole.parent,
      email: 'parent@noti.kg',
      password: 'parent123',
    );
    state.setUser(auth.user);

    await pumpScoped(
      tester,
      state: state,
      child: ParentMainScreen(
        onLogout: () {},
      ),
    );

    expect(find.text('Предстоящие события'), findsOneWidget);

    await tester.ensureVisible(find.text('Связаться с учителем'));
    await tester.tap(find.text('Связаться с учителем'));
    await waitForUi(tester);
    expect(find.text('Учителя'), findsWidgets);

    await tester.tap(find.text('Главная').first);
    await waitForUi(tester);
    await tester.ensureVisible(find.text('Связаться с учителем'));
    await tester.tap(find.text('Расписание').last);
    await waitForUi(tester);
    expect(find.text('Расписание ребенка'), findsOneWidget);

    await tester.tap(find.text('Оценки').first);
    await waitForUi(tester);
    expect(find.text('Успеваемость'), findsOneWidget);

    await tester.tap(find.text('Посещаемость').first);
    await waitForUi(tester);
    expect(find.text('История посещаемости'), findsOneWidget);

    await tester.tap(find.text('Уведомления').first);
    await waitForUi(tester);
    expect(find.text('Все новости и события'), findsOneWidget);
    expect(find.text('Отметить прочитанным'), findsWidgets);

    await tester.tap(find.text('Задания').first);
    await waitForUi(tester);
    expect(find.text('Новая оценка'), findsNothing);
    expect(find.text('Новое домашнее задание'), findsWidgets);

    await tester.tap(find.text('События').first);
    await waitForUi(tester);
    expect(find.text('Новое домашнее задание'), findsNothing);
    expect(find.text('Родительское собрание'), findsWidgets);

    await tester.tap(find.text('Все').first);
    await waitForUi(tester);
    expect(find.text('Новая оценка'), findsWidgets);

    await tester.tap(find.text('Отметить прочитанным').first);
    await waitForUi(tester);
    expect(find.text('Отметить все как прочитанные'), findsOneWidget);

    await tester.ensureVisible(find.text('Отметить все как прочитанные'));
    await tester.tap(find.text('Отметить все как прочитанные'));
    await waitForUi(tester);
    expect(find.text('Отметить прочитанным'), findsNothing);
    expect(find.text('Отметить все как прочитанные'), findsNothing);

    await tester.tap(find.text('Настройки').first);
    await waitForUi(tester);
    expect(find.text('Тема приложения'), findsOneWidget);
  });

  testWidgets('admin screen exposes unified user registry', (tester) async {
    final state = demoState();
    final auth = state.authenticate(
      role: UserRole.admin,
      email: 'admin@noti.kg',
      password: 'admin123',
    );
    state.setUser(auth.user);

    await pumpScoped(
      tester,
      state: state,
      child: AdminMainScreen(
        onLogout: () {},
      ),
    );

    expect(find.text('Операционный центр школы'), findsOneWidget);

    await tester.tap(find.text('Пользователи'));
    await waitForUi(tester);
    expect(find.text('Всего аккаунтов'), findsWidgets);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Родитель').first);
    await waitForUi(tester);
    expect(find.text('Класс ученика'), findsOneWidget);
    expect(find.text('Ученик'), findsWidgets);

    final classSelect = find.byWidgetPredicate(
      (widget) =>
          widget is AppSelectField<String> && widget.label == 'Класс ученика',
    );
    final studentSelect = find.byWidgetPredicate(
      (widget) => widget is AppSelectField<String> && widget.label == 'Ученик',
    );

    await tester.ensureVisible(classSelect);
    await tester.tap(classSelect);
    await waitForUi(tester);
    await tester.tap(find.text('10А').last);
    await waitForUi(tester);
    await tester.ensureVisible(studentSelect);
    await tester.tap(studentSelect);
    await waitForUi(tester);
    expect(find.textContaining('Токтосунов Нурсултан'), findsWidgets);
    await tester.tap(find.byIcon(Icons.close_rounded).last);
    await waitForUi(tester);

    await tester.tap(find.text('Аналитика'));
    await waitForUi(tester);
    expect(find.text('Проверенные сценарии'), findsOneWidget);

    await tester.tap(find.text('Настройки'));
    await waitForUi(tester);
    expect(find.text('Тема приложения'), findsOneWidget);
  });

  test('AppAccount parses linkedStudentIds and migrates linkedStudentId',
      () async {
    final state = AppState(
        database: _MemoryDatabaseService(SchoolDatabaseSnapshot(
      accounts: [
        {
          'id': 'parent-migration',
          'fullName': 'Migrated Parent',
          'email': 'migrated@noti.kg',
          'phone': '+996555111111',
          'role': 'parent',
          'status': 'active',
          'linkedStudentId': 'student-1',
          'createdAt': DateTime(2026),
        },
        {
          'id': 'parent-new',
          'fullName': 'New Parent',
          'email': 'new@noti.kg',
          'phone': '+996555111112',
          'role': 'parent',
          'status': 'active',
          'linkedStudentIds': ['student-2', 'student-3'],
          'createdAt': DateTime(2026),
        }
      ],
    )));
    await state.synchronizeDatabase();

    final p1 = state.userById('parent-migration')!;
    expect(p1.linkedStudentIds, contains('student-1'));

    final p2 = state.userById('parent-new')!;
    expect(p2.linkedStudentIds, containsAll(['student-2', 'student-3']));
  });

  test('childrenForParent via ParentStudentLink and unrelated access',
      () async {
    final state = demoState();
    final created = await state.adminCreateStudentWithParent(
      studentFullName: 'Child One',
      studentEmail: 'child1@noti.kg',
      studentPhone: '+996555111113',
      studentPassword: 'pw',
      classId: '10А',
      parentFullName: 'Parent Multi',
      parentEmail: 'parent-multi@noti.kg',
      parentPhone: '+996555111114',
      parentPassword: 'pw',
    );
    final student1 = created.data!.first.user;
    final parent = created.data!.last.user;

    final student2Result = await state.adminCreateAccount(
      fullName: 'Child Two',
      email: 'child2@noti.kg',
      phone: '+996555111115',
      password: 'pw',
      role: UserRole.student,
      schoolClass: '10Б',
    );
    final student2 = student2Result.data!.user;

    await state.linkParentToStudent(parent.id, student2.id);

    final children = state.childrenForParent(parent);
    expect(children.length, 2);
    expect(children.map((c) => c.id), containsAll([student1.id, student2.id]));

    expect(state.parentCanAccessStudent(parent.id, student1.id), isTrue);
    expect(
        state.parentCanAccessStudentForClientMigration(parent.id, student1.id),
        isTrue);
    expect(
        state.parentCanAccessClassForClientMigration(parent.id, '10А'), isTrue);
    expect(
        state.parentCanAccessClassForClientMigration(parent.id, '10Б'), isTrue);

    expect(state.parentCanAccessStudent(parent.id, 'some-unrelated-student'),
        isFalse);
    expect(state.parentCanAccessClassForClientMigration(parent.id, '11А'),
        isFalse);
  });

  test('admin parent creation requires linked student', () async {
    final state = demoState();
    final pResult = await state.adminCreateAccount(
      fullName: 'Empty Parent',
      email: 'empty-p@noti.kg',
      phone: '+996555111116',
      password: 'pw',
      role: UserRole.parent,
    );

    expect(pResult.isSuccess, isFalse);
  });

  test('student class change updates parentClassLink', () async {
    final state = demoState();
    final created = await state.adminCreateStudentWithParent(
      studentFullName: 'Moving Student',
      studentEmail: 'moving@noti.kg',
      studentPhone: '+996555111117',
      studentPassword: 'pw',
      classId: '10А',
      parentFullName: 'Moving Parent',
      parentEmail: 'moving-p@noti.kg',
      parentPhone: '+996555111118',
      parentPassword: 'pw',
    );
    final student = created.data!.first.user;
    final parent = created.data!.last.user;

    expect(
        state.parentCanAccessClassForClientMigration(parent.id, '10А'), isTrue);

    await state.adminUpdateAccount(
      userId: student.id,
      fullName: student.fullName,
      email: student.email!,
      phone: student.phone!,
      schoolClass: '10Б',
    );

    expect(
        state.parentCanAccessClassForClientMigration(parent.id, '10Б'), isTrue);
  });

  testWidgets('parent linked student and multi-child selector logic updates',
      (tester) async {
    final state = demoState();
    final student1 = (await state.adminCreateAccount(
      fullName: 'UI Child 1',
      email: 'c1@noti.kg',
      phone: '+996555111120',
      password: 'pw',
      role: UserRole.student,
      schoolClass: '10А',
    ))
        .data!
        .user;
    final parent = (await state.adminCreateAccount(
      fullName: 'UI Parent',
      email: 'ui-p@noti.kg',
      phone: '+996555111119',
      password: 'pw',
      role: UserRole.parent,
      schoolClass: '10А',
      linkedStudentId: student1.id,
      linkedStudentIds: [student1.id],
    ))
        .data!
        .user;
    final student2 = (await state.adminCreateAccount(
      fullName: 'UI Child 2',
      email: 'c2@noti.kg',
      phone: '+996555111121',
      password: 'pw',
      role: UserRole.student,
      schoolClass: '10Б',
    ))
        .data!
        .user;

    await state.linkParentToStudent(parent.id, student2.id);

    final children = state.childrenForParent(parent);
    expect(children.length, 2);
  });
}
