import 'dart:async';

import 'package:flutter/material.dart';

import '../models/school_models.dart';
import '../models/user_role.dart';
import '../services/auth_service.dart';
import '../services/monitoring_service.dart';
import '../services/school_database_service.dart';
import 'app_language.dart';
import 'app_localizations.dart';

enum AppThemePreference {
  system,
  light,
  dark,
}

const Set<String> _demoAccountIds = {
  'teacher-demo',
  'teacher-physics',
  'teacher-language',
  'student-demo',
  'student-10a-1',
  'student-10a-2',
  'student-10a-3',
  'student-10b-1',
  'parent-demo',
};

const Set<String> _demoEmails = {
  'teacher@noti.kg',
  'physics@noti.kg',
  'language@noti.kg',
  'student@noti.kg',
  'alex@noti.kg',
  'maria@noti.kg',
  'dmitry@noti.kg',
  'anna@noti.kg',
  'parent@noti.kg',
};

const Set<String> _demoClassIds = {
  '9А',
  '9Б',
  '10А',
  '10Б',
  '11А',
  '11Б',
};

const Set<String> _demoRegistrationRequestIds = {
  'request-seeded-student',
  'request-seeded-teacher',
};

const Set<String> _demoLessonIds = {
  'lesson-10a-math-1',
  'lesson-11b-algebra-1',
  'lesson-10b-geometry-1',
  'lesson-10a-physics-1',
  'lesson-10a-language-1',
};

const Set<String> _demoGradeIds = {
  'grade-seeded-1',
  'grade-seeded-2',
  'grade-seeded-3',
  'grade-seeded-4',
  'grade-seeded-5',
};

const Set<String> _demoHomeworkAssignmentIds = {
  'assignment-10a-math-homework',
  'assignment-10a-physics-lab',
  'assignment-10a-math-test',
};

const Set<String> _demoHomeworkSubmissionIds = {
  'submission-seeded-language',
};

const Set<String> _demoParentMeetingIds = {
  'meeting-10a-december',
};

const Set<String> _demoFileIds = {
  'file-1',
  'file-2',
  'file-3',
};

const Set<String> _demoAttendanceSessionIds = {
  'attendance-seeded',
};

class AppAccount {
  final AppUser user;
  final DateTime createdAt;

  const AppAccount({
    required this.user,
    required this.createdAt,
  });
}

typedef AuthResult = AuthServiceResult;

class AppResult<T> {
  final T? data;
  final String? errorKey;

  const AppResult.success(this.data) : errorKey = null;
  const AppResult.failure(this.errorKey) : data = null;

  bool get isSuccess => errorKey == null;
}

class AppChatMessage {
  final String senderId;
  final String text;
  final DateTime createdAt;

  const AppChatMessage({
    required this.senderId,
    required this.text,
    required this.createdAt,
  });
}

class RegistrationResult {
  final AppUser? user;
  final RegistrationRequest? request;
  final String? errorKey;

  const RegistrationResult.active(this.user)
      : request = null,
        errorKey = null;

  const RegistrationResult.pending(this.request)
      : user = null,
        errorKey = null;

  const RegistrationResult.failure(this.errorKey)
      : user = null,
        request = null;

  bool get isSuccess => errorKey == null;
  bool get isPendingApproval => request != null;
}

class AppState extends ChangeNotifier {
  final SchoolDatabaseService? database;
  final AuthService authService;
  final MonitoringService monitoringService;
  final bool enableDemoData;
  final bool enableBootstrapAdmin;
  final bool allowLateHomeworkSubmissions;

  AppUser? currentUser;
  AppLanguage language = AppLanguage.russian;
  AppThemePreference themePreference = AppThemePreference.system;
  bool isDatabaseReady = false;
  bool isDatabaseSyncing = false;
  String? databaseError;

  final List<AppAccount> _accounts = [];
  final List<RegistrationRequest> _registrationRequests = [];
  final List<SchoolClass> _schoolClasses = [];
  final List<LessonAssignment> _lessons = [];
  final List<GradeEntry> _grades = [];
  final List<ManagedSchoolFile> _files = [];
  final List<AttendanceSession> _attendanceSessions = [];
  final List<HomeworkAssignment> _homeworkAssignments = [];
  final List<HomeworkSubmission> _homeworkSubmissions = [];
  final List<ParentMeeting> _parentMeetings = [];
  final List<AuditLogEntry> _auditLogs = [];
  final List<ParentStudentLink> _parentStudentLinks = [];
  final List<ParentClassLink> _parentClassLinks = [];
  final List<QuarterGrade> _quarterGrades = [];
  final Map<String, List<AppChatMessage>> _chatMessagesByContact = {};

  AppState({
    this.database,
    AuthService? authService,
    MonitoringService? monitoringService,
    this.enableDemoData = false,
    this.enableBootstrapAdmin = false,
    this.allowLateHomeworkSubmissions = true,
  })  : authService = authService ??
            (enableDemoData
                ? MockAuthService.withDemoCredentials()
                : (enableBootstrapAdmin
                    ? MockAuthService.withBootstrapAdmin()
                    : MockAuthService())),
        monitoringService = monitoringService ??
            (enableDemoData
                ? const DebugMonitoringService()
                : const NoopMonitoringService()) {
    if (enableBootstrapAdmin) {
      _seedBootstrapAdmin();
    }
    if (database != null) {
      isDatabaseSyncing = true;
      unawaited(synchronizeDatabase());
    }
  }

  List<AppAccount> get accounts => List.unmodifiable(
        _accounts.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      );

  List<RegistrationRequest> get registrationRequests => List.unmodifiable(
        _registrationRequests.toList()
          ..sort((a, b) => b.requestedAt.compareTo(a.requestedAt)),
      );

  List<SchoolClass> get schoolClasses => List.unmodifiable(
        _schoolClasses.toList()..sort((a, b) => a.name.compareTo(b.name)),
      );

  List<LessonAssignment> get lessons => List.unmodifiable(
        _lessons.toList()
          ..sort((a, b) {
            final day = a.weekdayIndex.compareTo(b.weekdayIndex);
            if (day != 0) {
              return day;
            }
            return a.timeRange.compareTo(b.timeRange);
          }),
      );

  List<ManagedSchoolFile> get managedFiles => List.unmodifiable(
        _files.toList()..sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt)),
      );

  List<GradeEntry> get gradeEntries => List.unmodifiable(
        _grades.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      );

  List<AttendanceSession> get attendanceSessions => List.unmodifiable(
        _attendanceSessions.toList()
          ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt)),
      );

  List<HomeworkAssignment> get homeworkAssignments => List.unmodifiable(
        _homeworkAssignments.toList()
          ..sort((a, b) => a.dueAt.compareTo(b.dueAt)),
      );

  List<HomeworkSubmission> get homeworkSubmissions => List.unmodifiable(
        _homeworkSubmissions.toList()
          ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt)),
      );

  List<ParentMeeting> get parentMeetings => List.unmodifiable(
        _parentMeetings.toList()
          ..sort((a, b) => a.meetingAt.compareTo(b.meetingAt)),
      );

  List<QuarterGrade> get quarterGrades => List.unmodifiable(
        _quarterGrades.toList()
          ..sort((a, b) {
            final q = a.quarter.compareTo(b.quarter);
            if (q != 0) return q;
            return a.subject.compareTo(b.subject);
          }),
      );

  List<AuditLogEntry> get auditLogs => List.unmodifiable(
        _auditLogs.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      );

  List<AppUser> get teachers => _usersByRole(UserRole.teacher);
  List<AppUser> get students => _usersByRole(UserRole.student);
  List<AppUser> get parents => _usersByRole(UserRole.parent);
  List<AppUser> get admins => _usersByRole(UserRole.admin);

  int get pendingRequestsCount => _registrationRequests
      .where((request) => request.status == RegistrationStatus.pending)
      .length;

  AppLocalizations get strings => AppLocalizations(language);

  bool get isDemoMode => false;

  String? demoPasswordFor(AppAccount account) {
    if (!enableDemoData || authService is! MockAuthService) {
      return null;
    }
    final email = account.user.email;
    if (email == null || email.isEmpty) {
      return null;
    }
    return (authService as MockAuthService).passwordForDemoCredential(
      role: account.user.role,
      email: email,
    );
  }

  String get databaseStatusLabel {
    if (database == null) {
      return _localized('Локальный режим', 'Локалдык режим');
    }
    if (isDatabaseSyncing) {
      return _localized(
        'Синхронизация с Firestore...',
        'Firestore менен шайкештештирүү...',
      );
    }
    if (databaseError != null) {
      return _localized(
        'Firestore недоступен, используется локальный fallback',
        'Firestore жеткиликсиз, локалдык fallback колдонулууда',
      );
    }
    if (isDatabaseReady) {
      return _localized('Firestore подключен', 'Firestore туташты');
    }
    return _localized(
      'Firestore готовится к запуску',
      'Firestore ишке даярдалып жатат',
    );
  }

  ThemeMode get themeMode {
    switch (themePreference) {
      case AppThemePreference.system:
        return ThemeMode.system;
      case AppThemePreference.light:
        return ThemeMode.light;
      case AppThemePreference.dark:
        return ThemeMode.dark;
    }
  }

  void setUser(AppUser? user) {
    currentUser = user != null && user.isActive ? user : null;
    notifyListeners();
  }

  Future<void> signOut() async {
    currentUser = null;
    await authService.signOut();
    notifyListeners();
  }

  void setLanguage(AppLanguage value) {
    if (language == value) {
      return;
    }
    language = value;
    notifyListeners();
  }

  void toggleLanguage() {
    language = language == AppLanguage.russian
        ? AppLanguage.kyrgyz
        : AppLanguage.russian;
    notifyListeners();
  }

  String chatKeyForUsers(String firstUserId, String secondUserId) {
    final ids = [firstUserId, secondUserId]..sort();
    return '${ids[0]}:${ids[1]}';
  }

  List<AppChatMessage> chatMessagesForContact(String contactKey) {
    return List.unmodifiable(_chatMessagesByContact[contactKey] ?? const []);
  }

  void addChatMessage({
    required String contactKey,
    required String message,
  }) {
    final text = message.trim();
    if (text.isEmpty) {
      return;
    }
    final senderId = currentUser?.id;
    if (senderId == null) {
      return;
    }
    _chatMessagesByContact.putIfAbsent(contactKey, () => []).add(
          AppChatMessage(
            senderId: senderId,
            text: text,
            createdAt: DateTime.now(),
          ),
        );
    notifyListeners();
  }

  Map<String, List<AppChatMessage>> get allChatConversations =>
      Map.unmodifiable(_chatMessagesByContact);

  void setThemePreference(AppThemePreference value) {
    if (themePreference == value) {
      return;
    }
    themePreference = value;
    notifyListeners();
  }

  Future<void> synchronizeDatabase() async {
    final db = database;
    if (db == null) {
      return;
    }

    isDatabaseSyncing = true;
    databaseError = null;
    notifyListeners();

    try {
      final snapshot = await db.loadSnapshot();
      if (snapshot.isEmpty) {
        await db.seedIfEmpty(_toDatabaseSnapshot());
      } else {
        _applyDatabaseSnapshot(snapshot);
      }
      currentUser ??= await authService.restoreSignedInUser(
        profiles: _accounts.map((account) => account.user),
      );
      isDatabaseReady = true;
    } catch (error) {
      databaseError = error.toString();
      isDatabaseReady = false;
    } finally {
      isDatabaseSyncing = false;
      notifyListeners();
    }
  }

  Future<AppResult<T>> _commitDatabaseWrite<T>({
    required T data,
    required Future<void> Function(SchoolDatabaseService database) write,
    required VoidCallback rollback,
  }) async {
    final db = database;
    if (db == null) {
      notifyListeners();
      return AppResult.success(data);
    }

    isDatabaseSyncing = true;
    databaseError = null;
    notifyListeners();
    try {
      await write(db);
      isDatabaseReady = true;
      return AppResult.success(data);
    } catch (error) {
      rollback();
      databaseError = error.toString();
      isDatabaseReady = false;
      unawaited(
        monitoringService.recordError(
          error,
          StackTrace.current,
          reason: 'database_write_failed',
        ),
      );
      return AppResult.failure(databaseError);
    } finally {
      isDatabaseSyncing = false;
      notifyListeners();
    }
  }

  AuditLogEntry? _createAuditLog({
    required String action,
    required String targetType,
    required String targetId,
    Map<String, Object?> metadata = const {},
  }) {
    final actor = currentUser;
    if (actor == null || actor.role != UserRole.admin) {
      return null;
    }
    return AuditLogEntry(
      id: _nextId('audit'),
      actorId: actor.id,
      actorRole: actor.role,
      action: action,
      targetType: targetType,
      targetId: targetId,
      createdAt: DateTime.now(),
      metadata: metadata,
    );
  }

  void _addAuditLog(AuditLogEntry? entry) {
    if (entry != null) {
      _auditLogs.add(entry);
      unawaited(
        monitoringService.logEvent(
          MonitoringEvents.adminAction,
          parameters: {
            'actorId': entry.actorId,
            'actorRole': entry.actorRole.name,
            'action': entry.action,
            'targetType': entry.targetType,
            'targetId': entry.targetId,
          },
        ),
      );
    }
  }

  void _removeAuditLog(AuditLogEntry? entry) {
    if (entry != null) {
      _auditLogs.removeWhere((item) => item.id == entry.id);
    }
  }

  Future<void> _writeAuditLog(
    SchoolDatabaseService database,
    AuditLogEntry? entry,
  ) async {
    if (entry != null) {
      await database.setAuditLog(entry.id, _auditLogToMap(entry));
    }
  }

  void _applyDatabaseSnapshot(SchoolDatabaseSnapshot snapshot) {
    final cleanSnapshot =
        enableDemoData ? snapshot : _withoutDemoRecords(snapshot);
    _accounts
      ..clear()
      ..addAll(cleanSnapshot.accounts.map(_accountFromMap));
    _registrationRequests
      ..clear()
      ..addAll(cleanSnapshot.registrationRequests.map(_registrationFromMap));
    _schoolClasses
      ..clear()
      ..addAll(cleanSnapshot.schoolClasses.map(_schoolClassFromMap));
    _lessons
      ..clear()
      ..addAll(cleanSnapshot.lessons.map(_lessonFromMap));
    _grades
      ..clear()
      ..addAll(cleanSnapshot.grades.map(_gradeFromMap));
    _files
      ..clear()
      ..addAll(cleanSnapshot.files.map(_fileFromMap));
    _attendanceSessions
      ..clear()
      ..addAll(cleanSnapshot.attendanceSessions.map(_attendanceFromMap));
    _homeworkAssignments
      ..clear()
      ..addAll(cleanSnapshot.homeworkAssignments.map(_assignmentFromMap));
    _homeworkSubmissions
      ..clear()
      ..addAll(cleanSnapshot.homeworkSubmissions.map(_submissionFromMap));
    _parentMeetings
      ..clear()
      ..addAll(cleanSnapshot.parentMeetings.map(_meetingFromMap));
    _auditLogs
      ..clear()
      ..addAll(cleanSnapshot.auditLogs.map(_auditLogFromMap));
    _parentStudentLinks
      ..clear()
      ..addAll(cleanSnapshot.parentStudentLinks.map(_parentStudentLinkFromMap));
    _parentClassLinks
      ..clear()
      ..addAll(cleanSnapshot.parentClassLinks.map(_parentClassLinkFromMap));

    final user = currentUser;
    if (user != null) {
      final refreshed = userById(user.id);
      currentUser = refreshed != null && refreshed.isActive ? refreshed : null;
    }
  }

  SchoolDatabaseSnapshot _withoutDemoRecords(SchoolDatabaseSnapshot snapshot) {
    final accounts = snapshot.accounts.where((item) {
      final id = _stringValue(item['id']);
      final email = _stringValue(item['email']).toLowerCase();
      return !_demoAccountIds.contains(id) && !_demoEmails.contains(email);
    }).toList();
    final accountIds = accounts.map((item) => _stringValue(item['id'])).toSet();

    bool hasRealAccount(String? id) => id != null && accountIds.contains(id);
    bool hasDemoId(Map<String, dynamic> item, Set<String> ids) {
      return ids.contains(_stringValue(item['id']));
    }

    final lessons = snapshot.lessons.where((item) {
      if (hasDemoId(item, _demoLessonIds)) {
        return false;
      }
      return hasRealAccount(_nullableString(item['teacherId']));
    }).toList();

    final classIdsInUse = <String>{
      ...accounts
          .map((item) => _nullableString(item['schoolClass']))
          .whereType<String>(),
      ...lessons.map((item) => _stringValue(item['classId'])),
    };
    final schoolClasses = snapshot.schoolClasses.where((item) {
      final id = _stringValue(item['id'], fallback: _stringValue(item['name']));
      return !_demoClassIds.contains(id) || classIdsInUse.contains(id);
    }).toList();

    bool hasRealStudent(String? id) => hasRealAccount(id);
    bool hasRealLesson(String? id) {
      return lessons.any((item) => _stringValue(item['id']) == id);
    }

    return SchoolDatabaseSnapshot(
      accounts: accounts,
      registrationRequests: snapshot.registrationRequests
          .where((item) => !hasDemoId(item, _demoRegistrationRequestIds))
          .toList(),
      schoolClasses: schoolClasses,
      teacherClasses: snapshot.teacherClasses.where((item) {
        return hasRealAccount(_nullableString(item['teacherId'])) &&
            classIdsInUse.contains(_stringValue(item['classId']));
      }).toList(),
      lessons: lessons,
      grades: snapshot.grades.where((item) {
        return !hasDemoId(item, _demoGradeIds) &&
            hasRealStudent(_nullableString(item['studentId'])) &&
            hasRealLesson(_nullableString(item['lessonId']));
      }).toList(),
      files: snapshot.files
          .where((item) => !hasDemoId(item, _demoFileIds))
          .toList(),
      attendanceSessions: snapshot.attendanceSessions.where((item) {
        return !hasDemoId(item, _demoAttendanceSessionIds) &&
            hasRealLesson(_nullableString(item['lessonId']));
      }).toList(),
      homeworkAssignments: snapshot.homeworkAssignments.where((item) {
        return !hasDemoId(item, _demoHomeworkAssignmentIds) &&
            hasRealAccount(_nullableString(item['teacherId'])) &&
            classIdsInUse.contains(_stringValue(item['classId']));
      }).toList(),
      homeworkSubmissions: snapshot.homeworkSubmissions.where((item) {
        return !hasDemoId(item, _demoHomeworkSubmissionIds) &&
            hasRealStudent(_nullableString(item['studentId']));
      }).toList(),
      parentMeetings: snapshot.parentMeetings.where((item) {
        return !hasDemoId(item, _demoParentMeetingIds) &&
            hasRealAccount(_nullableString(item['teacherId'])) &&
            classIdsInUse.contains(_stringValue(item['classId']));
      }).toList(),
      auditLogs: snapshot.auditLogs,
      parentStudentLinks: snapshot.parentStudentLinks.where((item) {
        return hasRealAccount(_nullableString(item['parentId'])) &&
            hasRealStudent(_nullableString(item['studentId']));
      }).toList(),
      parentClassLinks: snapshot.parentClassLinks.where((item) {
        return hasRealAccount(_nullableString(item['parentId'])) &&
            classIdsInUse.contains(_stringValue(item['classId']));
      }).toList(),
    );
  }

  SchoolDatabaseSnapshot _toDatabaseSnapshot() {
    return SchoolDatabaseSnapshot(
      accounts: _accounts.map(_accountToMap).toList(),
      registrationRequests:
          _registrationRequests.map(_registrationToMap).toList(),
      schoolClasses: _schoolClasses.map(_schoolClassToMap).toList(),
      teacherClasses: _teacherClassMaps(),
      lessons: _lessons.map(_lessonToMap).toList(),
      grades: _grades.map(_gradeToMap).toList(),
      files: _files.map(_fileToMap).toList(),
      attendanceSessions: _attendanceSessions.map(_attendanceToMap).toList(),
      homeworkAssignments: _homeworkAssignments.map(_assignmentToMap).toList(),
      homeworkSubmissions: _homeworkSubmissions.map(_submissionToMap).toList(),
      parentMeetings: _parentMeetings.map(_meetingToMap).toList(),
      auditLogs: _auditLogs.map(_auditLogToMap).toList(),
      parentStudentLinks:
          _parentStudentLinks.map(_parentStudentLinkToMap).toList(),
      parentClassLinks: _parentClassLinks.map(_parentClassLinkToMap).toList(),
    );
  }

  Future<AuthResult> signIn({
    required UserRole role,
    required String email,
    required String password,
  }) async {
    final result = await authService.signIn(
      role: role,
      email: email,
      password: password,
      profiles: _accounts.map((account) => account.user),
    );
    if (result.isSuccess) {
      currentUser = result.user;
      unawaited(
        monitoringService.logEvent(
          MonitoringEvents.loginSuccess,
          parameters: roleParameter(role),
        ),
      );
      notifyListeners();
    } else {
      unawaited(
        monitoringService.logEvent(
          MonitoringEvents.loginFailure,
          parameters: {
            ...roleParameter(role),
            'error': result.errorKey ?? 'unknown',
          },
        ),
      );
    }
    return result;
  }

  AuthResult authenticate({
    required UserRole role,
    required String email,
    required String password,
  }) {
    final normalizedEmail = email.trim().toLowerCase();
    for (final request in _registrationRequests) {
      if (request.role != role || request.email != normalizedEmail) {
        continue;
      }
      switch (request.status) {
        case RegistrationStatus.pending:
          return const AuthResult.failure(
            'Заявка ещё на рассмотрении администратора.',
          );
        case RegistrationStatus.rejected:
          return const AuthResult.failure(
            'Заявка отклонена администратором.',
          );
        case RegistrationStatus.approved:
          break;
      }
    }

    if (authService is MockAuthService) {
      return (authService as MockAuthService).signInSync(
        role: role,
        email: email,
        password: password,
        profiles: _accounts.map((account) => account.user),
      );
    }
    return const AuthResult.failure('auth.serviceUnavailable');
  }

  Future<RegistrationResult> registerUser({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required UserRole role,
    String? schoolClass,
    String? parentFullName,
    String? parentEmail,
    String? parentPhone,
    String? parentPassword,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedPhone = phone.trim();
    final normalizedClass = schoolClass?.trim();
    final normalizedParentEmail = parentEmail?.trim().toLowerCase();
    final normalizedParentPhone = parentPhone?.trim();
    final normalizedParentPassword = parentPassword?.trim();

    if (_emailExists(normalizedEmail)) {
      return const RegistrationResult.failure('auth.duplicateEmail');
    }
    if (_phoneExists(normalizedPhone)) {
      return const RegistrationResult.failure('auth.duplicatePhone');
    }
    if (role == UserRole.student) {
      if (normalizedClass == null ||
          normalizedClass.isEmpty ||
          !_classExists(normalizedClass)) {
        return const RegistrationResult.failure('auth.classHint');
      }
      if ((parentFullName ?? '').trim().isEmpty ||
          (normalizedParentEmail ?? '').isEmpty ||
          (normalizedParentPhone ?? '').isEmpty ||
          (normalizedParentPassword ?? '').isEmpty) {
        return const RegistrationResult.failure('Заполните данные родителя.');
      }
      if (_emailExists(normalizedParentEmail!) ||
          normalizedParentEmail == normalizedEmail) {
        return const RegistrationResult.failure('auth.duplicateEmail');
      }
      if (_phoneExists(normalizedParentPhone!) ||
          normalizedParentPhone == normalizedPhone) {
        return const RegistrationResult.failure('auth.duplicatePhone');
      }
    }

    final request = RegistrationRequest(
      id: _nextId('request'),
      fullName: fullName.trim(),
      email: normalizedEmail,
      phone: normalizedPhone,
      role: role,
      schoolClass: normalizedClass?.isEmpty == true ? null : normalizedClass,
      parentFullName: parentFullName?.trim(),
      parentEmail: normalizedParentEmail,
      parentPhone: normalizedParentPhone,
      requestedAt: DateTime.now(),
    );

    _registrationRequests.add(request);
    authService.rememberPendingRegistration(
      requestId: request.id,
      role: role,
      email: normalizedEmail,
      password: password.trim(),
    );
    if (role == UserRole.student &&
        normalizedParentEmail != null &&
        normalizedParentPassword != null) {
      authService.rememberPendingRegistration(
        requestId: '${request.id}:parent',
        role: UserRole.parent,
        email: normalizedParentEmail,
        password: normalizedParentPassword,
      );
    }
    final result = await _commitDatabaseWrite(
      data: request,
      write: (db) =>
          db.setRegistrationRequest(request.id, _registrationToMap(request)),
      rollback: () {
        _registrationRequests.removeWhere((item) => item.id == request.id);
      },
    );
    return result.isSuccess
        ? RegistrationResult.pending(request)
        : RegistrationResult.failure(result.errorKey);
  }

  Future<AppResult<AppAccount>> adminCreateAccount({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required UserRole role,
    String? schoolClass,
    String? linkedStudentId,
    List<String>? linkedStudentIds,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedPhone = phone.trim();
    final normalizedFullName = fullName.trim();
    final normalizedPassword = password.trim();

    if (normalizedFullName.isEmpty ||
        normalizedEmail.isEmpty ||
        normalizedPhone.isEmpty ||
        normalizedPassword.isEmpty ||
        (role == UserRole.student && (schoolClass ?? '').trim().isEmpty) ||
        (role == UserRole.parent && (linkedStudentId ?? '').trim().isEmpty)) {
      return const AppResult<AppAccount>.failure('validation.invalidAccount');
    }

    final normalizedClass = schoolClass?.trim();
    if ((role == UserRole.student || role == UserRole.parent) &&
        normalizedClass != null &&
        normalizedClass.isNotEmpty &&
        !_classExists(normalizedClass)) {
      return const AppResult<AppAccount>.failure('validation.invalidClass');
    }

    final normalizedLinkedStudentId = linkedStudentId?.trim();
    final linkedStudent =
        normalizedLinkedStudentId == null || normalizedLinkedStudentId.isEmpty
            ? null
            : userById(normalizedLinkedStudentId);
    if (role == UserRole.parent &&
        (linkedStudent == null ||
            linkedStudent.role != UserRole.student ||
            (normalizedClass != null &&
                normalizedClass.isNotEmpty &&
                linkedStudent.schoolClass != normalizedClass))) {
      return const AppResult<AppAccount>.failure('validation.invalidStudent');
    }

    if (_emailExists(normalizedEmail) || _phoneExists(normalizedPhone)) {
      return const AppResult<AppAccount>.failure('auth.duplicateEmail');
    }

    final normalizedLinkedStudentIds = <String>{
      ...?linkedStudentIds,
      if (role == UserRole.parent &&
          normalizedLinkedStudentId != null &&
          normalizedLinkedStudentId.isNotEmpty)
        normalizedLinkedStudentId,
    }.toList();

    final userId = _nextId('user');
    final authUserId = await authService.ensureManagedUser(
      role: role,
      email: normalizedEmail,
      password: normalizedPassword,
      suggestedUserId: userId,
    );
    if (authUserId == null || authUserId.isEmpty) {
      return const AppResult<AppAccount>.failure('auth.createUserFailed');
    }

    final account = AppAccount(
      user: AppUser(
        id: authUserId,
        fullName: normalizedFullName,
        email: normalizedEmail,
        phone: normalizedPhone,
        role: role,
        status: UserStatus.active,
        schoolClass: normalizedClass?.isEmpty == true ? null : normalizedClass,
        linkedStudentId:
            role == UserRole.parent ? normalizedLinkedStudentId : null,
        linkedStudentIds: normalizedLinkedStudentIds,
      ),
      createdAt: DateTime.now(),
    );

    ParentStudentLink? parentStudentLink;
    ParentClassLink? parentClassLink;
    if (role == UserRole.parent &&
        normalizedLinkedStudentId != null &&
        normalizedLinkedStudentId.isNotEmpty) {
      parentStudentLink = ParentStudentLink(
        id: '${account.user.id}_$normalizedLinkedStudentId',
        parentId: account.user.id,
        studentId: normalizedLinkedStudentId,
        createdAt: DateTime.now(),
      );
      _parentStudentLinks.add(parentStudentLink);

      final linkedClass = linkedStudent?.schoolClass;
      if (linkedClass != null && linkedClass.isNotEmpty) {
        parentClassLink = ParentClassLink(
          id: '${account.user.id}_$linkedClass',
          parentId: account.user.id,
          classId: linkedClass,
          createdAt: DateTime.now(),
        );
        _parentClassLinks.add(parentClassLink);
      }
    }

    _accounts.add(account);
    final audit = _createAuditLog(
      action: 'account.create',
      targetType: 'account',
      targetId: account.user.id,
      metadata: {
        'role': role.name,
        'status': account.user.status.name,
      },
    );
    _addAuditLog(audit);
    return _commitDatabaseWrite(
      data: account,
      write: (db) async {
        await db.setAccount(account.user.id, _accountToMap(account));
        if (parentStudentLink != null) {
          await db.setParentStudentLink(
            parentStudentLink.id,
            _parentStudentLinkToMap(parentStudentLink),
          );
        }
        if (parentClassLink != null) {
          await db.setParentClassLink(
            parentClassLink.id,
            _parentClassLinkToMap(parentClassLink),
          );
        }
        await _writeAuditLog(db, audit);
      },
      rollback: () {
        _accounts.removeWhere((item) => item.user.id == account.user.id);
        if (parentStudentLink != null) {
          _parentStudentLinks
              .removeWhere((link) => link.id == parentStudentLink!.id);
        }
        if (parentClassLink != null) {
          _parentClassLinks
              .removeWhere((link) => link.id == parentClassLink!.id);
        }
        _removeAuditLog(audit);
        authService.removeUserCredential(account.user.id);
      },
    );
  }

  Future<AppResult<List<AppAccount>>> adminCreateStudentWithParent({
    required String studentFullName,
    required String studentEmail,
    required String studentPhone,
    required String studentPassword,
    required String classId,
    required String parentFullName,
    required String parentEmail,
    required String parentPhone,
    required String parentPassword,
  }) async {
    final normalizedClassId = classId.trim();
    if (normalizedClassId.isEmpty ||
        _schoolClasses.every((item) => item.id != normalizedClassId)) {
      return const AppResult<List<AppAccount>>.failure(
        'validation.invalidClass',
      );
    }

    final studentResult = await adminCreateAccount(
      fullName: studentFullName,
      email: studentEmail,
      phone: studentPhone,
      password: studentPassword,
      role: UserRole.student,
      schoolClass: normalizedClassId,
    );
    final student = studentResult.data;
    if (student == null) {
      return AppResult<List<AppAccount>>.failure(studentResult.errorKey);
    }

    final parentResult = await adminCreateAccount(
      fullName: parentFullName,
      email: parentEmail,
      phone: parentPhone,
      password: parentPassword,
      role: UserRole.parent,
      schoolClass: normalizedClassId,
      linkedStudentId: student.user.id,
      linkedStudentIds: [student.user.id],
    );
    final parent = parentResult.data;
    if (parent == null) {
      _accounts.removeWhere((account) => account.user.id == student.user.id);
      authService.removeUserCredential(student.user.id);
      final db = database;
      if (db != null) {
        try {
          await db.deleteAccount(student.user.id);
        } catch (error) {
          databaseError = error.toString();
        }
      }
      notifyListeners();
      return AppResult<List<AppAccount>>.failure(parentResult.errorKey);
    }

    final linkResult =
        await linkParentToStudent(parent.user.id, student.user.id);
    if (!linkResult.isSuccess) {
      _accounts.removeWhere((account) =>
          account.user.id == student.user.id ||
          account.user.id == parent.user.id);
      authService.removeUserCredential(student.user.id);
      authService.removeUserCredential(parent.user.id);
      final db = database;
      if (db != null) {
        try {
          await db.deleteAccount(student.user.id);
          await db.deleteAccount(parent.user.id);
        } catch (error) {
          databaseError = error.toString();
        }
      }
      notifyListeners();
      return AppResult<List<AppAccount>>.failure(linkResult.errorKey);
    }

    return AppResult.success([student, parent]);
  }

  Future<AppResult<bool>> adminUpdateAccount({
    required String userId,
    required String fullName,
    required String email,
    required String phone,
    String? schoolClass,
  }) async {
    final index = _accounts.indexWhere((account) => account.user.id == userId);
    if (index == -1) {
      return const AppResult<bool>.failure('validation.notFound');
    }
    final normalizedFullName = fullName.trim();
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedPhone = phone.trim();
    if (normalizedFullName.isEmpty ||
        normalizedEmail.isEmpty ||
        normalizedPhone.isEmpty) {
      return const AppResult<bool>.failure('validation.invalidAccount');
    }
    if (_accounts.any(
      (account) =>
          account.user.id != userId &&
          ((account.user.email ?? '').toLowerCase() == normalizedEmail ||
              (account.user.phone ?? '').trim() == normalizedPhone),
    )) {
      return const AppResult<bool>.failure('auth.duplicateEmail');
    }

    final account = _accounts[index];
    final normalizedClass = schoolClass?.trim();
    if ((account.user.role == UserRole.student ||
            account.user.role == UserRole.parent) &&
        normalizedClass != null &&
        normalizedClass.isNotEmpty &&
        !_classExists(normalizedClass)) {
      return const AppResult<bool>.failure('validation.invalidClass');
    }
    final updated = AppAccount(
      user: account.user.copyWith(
        fullName: normalizedFullName,
        email: normalizedEmail,
        phone: normalizedPhone,
        schoolClass: normalizedClass?.isEmpty == true ? null : normalizedClass,
      ),
      createdAt: account.createdAt,
    );
    _accounts[index] = updated;

    final classChanged = account.user.role == UserRole.student &&
        account.user.schoolClass != updated.user.schoolClass;
    final newClassLinks = <ParentClassLink>[];
    final removedClassLinks = <ParentClassLink>[];

    if (classChanged) {
      final parents = _parentStudentLinks
          .where((l) => l.studentId == updated.user.id)
          .map((l) => l.parentId)
          .toSet();

      for (final pId in parents) {
        if (updated.user.schoolClass != null) {
          final cLinkId = '${pId}_${updated.user.schoolClass}';
          if (!_parentClassLinks.any((l) => l.id == cLinkId)) {
            final classLink = ParentClassLink(
              id: cLinkId,
              parentId: pId,
              classId: updated.user.schoolClass!,
              createdAt: DateTime.now(),
            );
            newClassLinks.add(classLink);
            _parentClassLinks.add(classLink);
          }
        }

        if (account.user.schoolClass != null) {
          final otherChildrenInOldClass = _parentStudentLinks
              .where((l) => l.parentId == pId && l.studentId != updated.user.id)
              .map((l) => userById(l.studentId))
              .any((s) =>
                  s != null && s.schoolClass == account.user.schoolClass);

          if (!otherChildrenInOldClass) {
            final oldLinkId = '${pId}_${account.user.schoolClass}';
            final oldLinkIndex =
                _parentClassLinks.indexWhere((l) => l.id == oldLinkId);
            if (oldLinkIndex != -1) {
              removedClassLinks.add(_parentClassLinks[oldLinkIndex]);
              _parentClassLinks.removeAt(oldLinkIndex);
            }
          }
        }
      }
    }

    final statusChanged = account.user.status != updated.user.status;
    final audit = _createAuditLog(
      action: statusChanged ? 'account.status_update' : 'account.update',
      targetType: 'account',
      targetId: updated.user.id,
      metadata: {
        'role': updated.user.role.name,
        'previousStatus': account.user.status.name,
        'status': updated.user.status.name,
      },
    );
    _addAuditLog(audit);
    return _commitDatabaseWrite(
      data: true,
      write: (db) async {
        await db.setAccount(updated.user.id, _accountToMap(updated));
        await _writeAuditLog(db, audit);
        for (final cl in newClassLinks) {
          await db.setParentClassLink(cl.id, _parentClassLinkToMap(cl));
        }
        for (final cl in removedClassLinks) {
          await db.deleteParentClassLink(cl.id);
        }
      },
      rollback: () {
        _accounts[index] = account;
        _removeAuditLog(audit);
        for (final cl in newClassLinks) {
          _parentClassLinks.removeWhere((l) => l.id == cl.id);
        }
        _parentClassLinks.addAll(removedClassLinks);
      },
    );
  }

  Future<AppResult<bool>> approveRegistrationRequest(String requestId) async {
    final index =
        _registrationRequests.indexWhere((request) => request.id == requestId);
    if (index == -1) {
      return const AppResult<bool>.failure('validation.notFound');
    }

    final request = _registrationRequests[index];
    if (request.status != RegistrationStatus.pending) {
      return const AppResult<bool>.failure('validation.invalidRequest');
    }

    final account = AppAccount(
      user: AppUser(
        id: _nextId('user'),
        fullName: request.fullName,
        email: request.email,
        phone: request.phone,
        role: request.role,
        status: UserStatus.active,
        schoolClass: request.schoolClass,
      ),
      createdAt: DateTime.now(),
    );

    final updatedRequest = request.copyWith(
      status: RegistrationStatus.approved,
      reviewedAt: DateTime.now(),
    );
    final parentAccount = request.role == UserRole.student &&
            (request.parentEmail ?? '').isNotEmpty &&
            (request.parentPhone ?? '').isNotEmpty &&
            (request.parentFullName ?? '').isNotEmpty
        ? AppAccount(
            user: AppUser(
              id: _nextId('user'),
              fullName: request.parentFullName!,
              email: request.parentEmail,
              phone: request.parentPhone,
              role: UserRole.parent,
              status: UserStatus.active,
              schoolClass: request.schoolClass,
              linkedStudentId: account.user.id,
              linkedStudentIds: [account.user.id],
            ),
            createdAt: DateTime.now(),
          )
        : null;

    _accounts.add(account);
    authService.activatePendingRegistration(
      requestId: request.id,
      userId: account.user.id,
    );
    if (parentAccount != null) {
      _accounts.add(parentAccount);
      authService.activatePendingRegistration(
        requestId: '${request.id}:parent',
        userId: parentAccount.user.id,
      );
    }

    ParentStudentLink? link;
    ParentClassLink? classLink;
    if (parentAccount != null) {
      link = ParentStudentLink(
          id: '${parentAccount.user.id}_${account.user.id}',
          parentId: parentAccount.user.id,
          studentId: account.user.id,
          createdAt: DateTime.now());
      _parentStudentLinks.add(link);
      if (account.user.schoolClass != null) {
        classLink = ParentClassLink(
            id: '${parentAccount.user.id}_${account.user.schoolClass}',
            parentId: parentAccount.user.id,
            classId: account.user.schoolClass!,
            createdAt: DateTime.now());
        _parentClassLinks.add(classLink);
      }
    }
    _registrationRequests[index] = updatedRequest;
    final audit = _createAuditLog(
      action: 'registration.approve',
      targetType: 'registrationRequest',
      targetId: updatedRequest.id,
      metadata: {
        'role': request.role.name,
        'accountId': account.user.id,
        if (parentAccount != null) 'parentAccountId': parentAccount.user.id,
      },
    );
    _addAuditLog(audit);
    return _commitDatabaseWrite(
      data: true,
      write: (db) async {
        await db.setAccount(account.user.id, _accountToMap(account));
        if (parentAccount != null) {
          await db.setAccount(
            parentAccount.user.id,
            _accountToMap(parentAccount),
          );
          if (link != null) {
            await db.setParentStudentLink(
                link.id, _parentStudentLinkToMap(link));
          }
          if (classLink != null) {
            await db.setParentClassLink(
                classLink.id, _parentClassLinkToMap(classLink));
          }
        }
        await db.setRegistrationRequest(
          updatedRequest.id,
          _registrationToMap(updatedRequest),
        );
        await _writeAuditLog(db, audit);
      },
      rollback: () {
        _accounts.removeWhere((item) => item.user.id == account.user.id);
        if (parentAccount != null) {
          _accounts
              .removeWhere((item) => item.user.id == parentAccount.user.id);
          if (link != null) {
            _parentStudentLinks.removeWhere((l) => l.id == link!.id);
          }
          if (classLink != null) {
            _parentClassLinks.removeWhere((l) => l.id == classLink!.id);
          }
        }
        _registrationRequests[index] = request;
        authService.removeUserCredential(account.user.id);
        if (parentAccount != null) {
          authService.removeUserCredential(parentAccount.user.id);
        }
        _removeAuditLog(audit);
      },
    );
  }

  Future<AppResult<bool>> rejectRegistrationRequest(
    String requestId, {
    String? note,
  }) async {
    final index =
        _registrationRequests.indexWhere((request) => request.id == requestId);
    if (index == -1) {
      return const AppResult<bool>.failure('validation.notFound');
    }

    final request = _registrationRequests[index];
    if (request.status != RegistrationStatus.pending) {
      return const AppResult<bool>.failure('validation.invalidRequest');
    }

    final updatedRequest = request.copyWith(
      status: RegistrationStatus.rejected,
      reviewedAt: DateTime.now(),
      reviewNote: note,
    );
    _registrationRequests[index] = updatedRequest;
    final audit = _createAuditLog(
      action: 'registration.reject',
      targetType: 'registrationRequest',
      targetId: updatedRequest.id,
      metadata: {
        'role': request.role.name,
        if ((note ?? '').trim().isNotEmpty) 'hasNote': true,
      },
    );
    _addAuditLog(audit);
    return _commitDatabaseWrite(
      data: true,
      write: (db) async {
        await db.setRegistrationRequest(
          updatedRequest.id,
          _registrationToMap(updatedRequest),
        );
        await _writeAuditLog(db, audit);
      },
      rollback: () {
        _registrationRequests[index] = request;
        _removeAuditLog(audit);
      },
    );
  }

  Future<AppResult<SchoolClass>> createSchoolClass(String name) async {
    final normalized = name.trim().toUpperCase();
    if (normalized.isEmpty) {
      return const AppResult<SchoolClass>.failure('validation.invalidClass');
    }
    if (_schoolClasses.any((item) => item.name.toUpperCase() == normalized)) {
      return const AppResult<SchoolClass>.failure('validation.duplicateClass');
    }

    final schoolClass = SchoolClass(
      id: normalized,
      name: normalized,
    );
    _schoolClasses.add(schoolClass);
    final audit = _createAuditLog(
      action: 'class.create',
      targetType: 'class',
      targetId: schoolClass.id,
      metadata: {'name': schoolClass.name},
    );
    _addAuditLog(audit);
    return _commitDatabaseWrite(
      data: schoolClass,
      write: (db) async {
        await db.setSchoolClass(schoolClass.id, _schoolClassToMap(schoolClass));
        await _writeAuditLog(db, audit);
      },
      rollback: () {
        _schoolClasses.removeWhere((item) => item.id == schoolClass.id);
        _removeAuditLog(audit);
      },
    );
  }

  Future<AppResult<SchoolClass>> updateSchoolClass({
    required String classId,
    required String name,
  }) async {
    final index = _schoolClasses.indexWhere((item) => item.id == classId);
    final normalized = name.trim().toUpperCase();
    if (index == -1) {
      return const AppResult<SchoolClass>.failure('validation.notFound');
    }
    if (normalized.isEmpty) {
      return const AppResult<SchoolClass>.failure('validation.invalidClass');
    }
    if (_schoolClasses.any(
      (item) => item.id != classId && item.name.toUpperCase() == normalized,
    )) {
      return const AppResult<SchoolClass>.failure('validation.duplicateClass');
    }

    final previous = _schoolClasses[index];
    final updated = SchoolClass(id: previous.id, name: normalized);
    _schoolClasses[index] = updated;
    final audit = _createAuditLog(
      action: 'class.update',
      targetType: 'class',
      targetId: updated.id,
      metadata: {'name': updated.name},
    );
    _addAuditLog(audit);
    return _commitDatabaseWrite(
      data: updated,
      write: (db) async {
        await db.setSchoolClass(updated.id, _schoolClassToMap(updated));
        await _writeAuditLog(db, audit);
      },
      rollback: () {
        _schoolClasses[index] = previous;
        _removeAuditLog(audit);
      },
    );
  }

  Future<AppResult<bool>> deleteSchoolClass(String classId) async {
    final index = _schoolClasses.indexWhere((item) => item.id == classId);
    if (index == -1) {
      return const AppResult<bool>.failure('validation.notFound');
    }
    if (studentsForClass(classId).isNotEmpty ||
        lessonsForClass(classId).isNotEmpty) {
      return const AppResult<bool>.failure('validation.classNotEmpty');
    }

    final removed = _schoolClasses.removeAt(index);
    final audit = _createAuditLog(
      action: 'class.delete',
      targetType: 'class',
      targetId: removed.id,
      metadata: {'name': removed.name},
    );
    _addAuditLog(audit);
    return _commitDatabaseWrite(
      data: true,
      write: (db) async {
        await db.deleteSchoolClass(removed.id);
        await _writeAuditLog(db, audit);
      },
      rollback: () {
        _schoolClasses.insert(index, removed);
        _removeAuditLog(audit);
      },
    );
  }

  Future<AppResult<LessonAssignment>> createLessonAssignment({
    required String classId,
    required String teacherId,
    required String subject,
    required int weekdayIndex,
    required String timeRange,
    required String room,
  }) async {
    final normalizedSubject = subject.trim();
    final normalizedTimeRange = timeRange.trim();
    final normalizedRoom = room.trim();
    if (normalizedSubject.isEmpty ||
        normalizedTimeRange.isEmpty ||
        normalizedRoom.isEmpty) {
      return const AppResult<LessonAssignment>.failure(
        'validation.invalidLesson',
      );
    }
    if (_schoolClasses.every((item) => item.id != classId)) {
      return const AppResult<LessonAssignment>.failure(
        'validation.invalidClass',
      );
    }
    if (_accounts.every(
      (account) =>
          account.user.id != teacherId || account.user.role != UserRole.teacher,
    )) {
      return const AppResult<LessonAssignment>.failure(
        'validation.invalidTeacher',
      );
    }
    if (weekdayIndex < 0 || weekdayIndex > 4) {
      return const AppResult<LessonAssignment>.failure(
        'validation.invalidWeekday',
      );
    }
    if (_lessons.any(
      (lesson) =>
          lesson.weekdayIndex == weekdayIndex &&
          lesson.timeRange == normalizedTimeRange &&
          (lesson.classId == classId || lesson.teacherId == teacherId),
    )) {
      return const AppResult<LessonAssignment>.failure(
        'validation.scheduleConflict',
      );
    }

    final lesson = LessonAssignment(
      id: _nextId('lesson'),
      classId: classId,
      teacherId: teacherId,
      subject: normalizedSubject,
      weekdayIndex: weekdayIndex,
      timeRange: normalizedTimeRange,
      room: normalizedRoom,
    );
    _lessons.add(lesson);
    return _commitDatabaseWrite(
      data: lesson,
      write: (db) async {
        await db.setLesson(lesson.id, _lessonToMap(lesson));
        await db.setTeacherClass(
          '${lesson.teacherId}_${lesson.classId}',
          {
            'id': '${lesson.teacherId}_${lesson.classId}',
            'teacherId': lesson.teacherId,
            'classId': lesson.classId,
          },
        );
      },
      rollback: () {
        _lessons.removeWhere((item) => item.id == lesson.id);
      },
    );
  }

  Future<AppResult<bool>> recordGrades({
    required String lessonId,
    required Map<String, int> grades,
    required String category,
    String comment = '',
  }) async {
    final user = currentUser;
    final lesson = lessonById(lessonId);
    if (user == null ||
        user.role != UserRole.teacher ||
        lesson == null ||
        lesson.teacherId != user.id ||
        grades.isEmpty) {
      return const AppResult<bool>.failure('validation.invalidGradePayload');
    }

    final students =
        studentsForClass(lesson.classId).map((item) => item.id).toSet();
    final normalizedCategory =
        category.trim().isEmpty ? 'Оценка за урок' : category.trim();
    final normalizedComment = comment.trim();
    final now = DateTime.now();
    final removedGrades = <GradeEntry>[];
    final createdGrades = <GradeEntry>[];
    var saved = 0;

    for (final entry in grades.entries) {
      final grade = entry.value;
      if (!students.contains(entry.key) || grade < 2 || grade > 5) {
        continue;
      }

      removedGrades.addAll(
        _grades.where(
          (item) =>
              item.studentId == entry.key &&
              item.lessonId == lesson.id &&
              item.category == normalizedCategory &&
              _isSameDay(item.createdAt, now),
        ),
      );
      _grades.removeWhere(
        (item) =>
            item.studentId == entry.key &&
            item.lessonId == lesson.id &&
            item.category == normalizedCategory &&
            _isSameDay(item.createdAt, now),
      );

      final gradeEntry = GradeEntry(
        id: _nextId('grade'),
        studentId: entry.key,
        lessonId: lesson.id,
        classId: lesson.classId,
        teacherId: lesson.teacherId,
        subject: lesson.subject,
        value: grade,
        category: normalizedCategory,
        comment: normalizedComment,
        createdAt: now,
      );
      _grades.add(gradeEntry);
      createdGrades.add(gradeEntry);
      saved++;
    }

    if (saved == 0) {
      return const AppResult<bool>.failure('validation.invalidGradePayload');
    }

    return _commitDatabaseWrite(
      data: true,
      write: (db) async {
        for (final grade in removedGrades) {
          await db.deleteGrade(grade.id);
        }
        for (final grade in createdGrades) {
          await db.setGrade(grade.id, _gradeToMap(grade));
        }
      },
      rollback: () {
        _grades.removeWhere(
          (item) => createdGrades.any((created) => created.id == item.id),
        );
        _grades.addAll(removedGrades);
      },
    ).then((result) {
      if (result.isSuccess) {
        unawaited(
          monitoringService.logEvent(
            MonitoringEvents.gradeCreated,
            parameters: {
              'teacherId': user.id,
              'lessonId': lesson.id,
              'classId': lesson.classId,
              'count': createdGrades.length,
            },
          ),
        );
      }
      return result;
    });
  }

  Future<AppResult<ManagedSchoolFile>> createManagedFile({
    required String name,
    required String category,
    required String sizeLabel,
    String? classId,
    String? storagePath,
    String? downloadUrl,
    String? contentType,
    String? topic,
    String? description,
  }) async {
    final user = currentUser;
    if (user == null) {
      return const AppResult<ManagedSchoolFile>.failure('auth.profileMissing');
    }
    final normalizedName = name.trim();
    final normalizedCategory = category.trim();
    final normalizedSizeLabel = sizeLabel.trim();
    if (normalizedName.isEmpty || normalizedCategory.isEmpty) {
      return const AppResult<ManagedSchoolFile>.failure(
        'validation.invalidFile',
      );
    }
    final normalizedClassId = classId?.trim();
    if (normalizedClassId != null &&
        normalizedClassId.isNotEmpty &&
        !_classExists(normalizedClassId)) {
      return const AppResult<ManagedSchoolFile>.failure(
        'validation.invalidClass',
      );
    }
    if (user.role == UserRole.teacher &&
        normalizedClassId != null &&
        normalizedClassId.isNotEmpty &&
        lessonsForTeacher(user.id)
            .every((lesson) => lesson.classId != normalizedClassId)) {
      return const AppResult<ManagedSchoolFile>.failure('auth.roleMismatch');
    }
    if ((storagePath == null || storagePath.trim().isEmpty) &&
        (downloadUrl == null || downloadUrl.trim().isEmpty)) {
      return const AppResult<ManagedSchoolFile>.failure(
        'validation.invalidFile',
      );
    }

    final file = ManagedSchoolFile(
      id: _nextId('file'),
      name: normalizedName,
      category: normalizedCategory,
      classId: normalizedClassId?.isEmpty == true ? null : normalizedClassId,
      uploadedByUserId: user.id,
      uploadedAt: DateTime.now(),
      sizeLabel: normalizedSizeLabel.isEmpty ? 'Файл' : normalizedSizeLabel,
      storagePath: storagePath,
      downloadUrl: downloadUrl,
      contentType: contentType,
      topic: topic?.trim(),
      description: description?.trim(),
    );

    _files.add(file);
    final result = await _commitDatabaseWrite(
      data: file,
      write: (db) => db.setFile(file.id, _fileToMap(file)),
      rollback: () {
        _files.removeWhere((item) => item.id == file.id);
      },
    );
    if (result.isSuccess) {
      unawaited(
        monitoringService.logEvent(
          MonitoringEvents.fileUploaded,
          parameters: {
            'userId': user.id,
            'role': user.role.name,
            'classId': file.classId ?? '',
            'contentType': file.contentType ?? '',
          },
        ),
      );
    }
    return result;
  }

  Future<AppResult<HomeworkAssignment>> createHomeworkAssignment({
    required String classId,
    required String subject,
    required String title,
    required String description,
    required DateTime dueAt,
    required AssignmentKind kind,
    bool urgent = false,
    bool requiresFile = true,
  }) async {
    final user = currentUser;
    if (user == null || user.role != UserRole.teacher) {
      return const AppResult<HomeworkAssignment>.failure('auth.roleMismatch');
    }
    if (_schoolClasses.every((item) => item.id != classId)) {
      return const AppResult<HomeworkAssignment>.failure(
        'validation.invalidClass',
      );
    }
    if (lessonsForTeacher(user.id)
        .every((lesson) => lesson.classId != classId)) {
      return const AppResult<HomeworkAssignment>.failure('auth.roleMismatch');
    }

    final assignment = HomeworkAssignment(
      id: _nextId('assignment'),
      classId: classId,
      teacherId: user.id,
      subject: subject.trim().isEmpty ? 'Урок' : subject.trim(),
      title: title.trim(),
      description: description.trim(),
      dueAt: dueAt,
      kind: kind,
      urgent: urgent,
      requiresFile: requiresFile,
      createdAt: DateTime.now(),
    );
    if (assignment.title.isEmpty) {
      return const AppResult<HomeworkAssignment>.failure(
        'validation.invalidAssignment',
      );
    }

    _homeworkAssignments.add(assignment);
    return _commitDatabaseWrite(
      data: assignment,
      write: (db) => db.setHomeworkAssignment(
        assignment.id,
        _assignmentToMap(assignment),
      ),
      rollback: () {
        _homeworkAssignments.removeWhere((item) => item.id == assignment.id);
      },
    );
  }

  ParentMeeting? createParentMeeting({
    required String classId,
    required String title,
    required String agenda,
    required String location,
    required DateTime meetingAt,
  }) {
    final user = currentUser;
    if (user == null || user.role != UserRole.teacher) {
      return null;
    }
    if (_schoolClasses.every((item) => item.id != classId)) {
      return null;
    }
    if (lessonsForTeacher(user.id)
        .every((lesson) => lesson.classId != classId)) {
      return null;
    }

    final meeting = ParentMeeting(
      id: _nextId('meeting'),
      classId: classId,
      teacherId: user.id,
      title: title.trim().isEmpty ? 'Родительское собрание' : title.trim(),
      agenda: agenda.trim(),
      location: location.trim().isEmpty ? 'Класс' : location.trim(),
      meetingAt: meetingAt,
      createdAt: DateTime.now(),
    );

    _parentMeetings.add(meeting);
    unawaited(
      _commitDatabaseWrite(
        data: meeting,
        write: (db) => db.setParentMeeting(meeting.id, _meetingToMap(meeting)),
        rollback: () {
          _parentMeetings.removeWhere((item) => item.id == meeting.id);
        },
      ),
    );
    notifyListeners();
    return meeting;
  }

  Future<AppResult<HomeworkSubmission>> submitHomeworkFile({
    required String assignmentId,
    required String fileName,
    required String sizeLabel,
    String? storagePath,
    String? downloadUrl,
  }) async {
    final user = currentUser;
    final assignment = homeworkAssignmentById(assignmentId);
    final normalizedFileName = fileName.trim();
    if (user == null ||
        user.role != UserRole.student ||
        assignment == null ||
        assignment.classId != user.schoolClass ||
        normalizedFileName.isEmpty) {
      return const AppResult<HomeworkSubmission>.failure(
        'validation.invalidSubmission',
      );
    }
    final submittedAt = DateTime.now();
    final late = submittedAt.isAfter(assignment.dueAt);
    if (late && !allowLateHomeworkSubmissions) {
      return const AppResult<HomeworkSubmission>.failure(
        'homework.lateSubmissionRejected',
      );
    }

    final removedSubmissions = _homeworkSubmissions
        .where(
          (submission) =>
              submission.assignmentId == assignmentId &&
              submission.studentId == user.id,
        )
        .toList();
    _homeworkSubmissions.removeWhere(
      (submission) =>
          submission.assignmentId == assignmentId &&
          submission.studentId == user.id,
    );

    final submission = HomeworkSubmission(
      id: _nextId('submission'),
      assignmentId: assignmentId,
      studentId: user.id,
      fileName: normalizedFileName,
      sizeLabel: sizeLabel.trim(),
      storagePath: storagePath,
      downloadUrl: downloadUrl,
      late: late,
      submittedAt: submittedAt,
    );

    _homeworkSubmissions.add(submission);
    final result = await _commitDatabaseWrite(
      data: submission,
      write: (db) async {
        for (final removed in removedSubmissions) {
          await db.deleteHomeworkSubmission(removed.id);
        }
        await db.setHomeworkSubmission(
          submission.id,
          _submissionToMap(submission),
        );
      },
      rollback: () {
        _homeworkSubmissions.removeWhere((item) => item.id == submission.id);
        _homeworkSubmissions.addAll(removedSubmissions);
      },
    );
    if (result.isSuccess) {
      unawaited(
        monitoringService.logEvent(
          MonitoringEvents.homeworkSubmitted,
          parameters: {
            'studentId': user.id,
            'assignmentId': assignmentId,
            'late': late,
          },
        ),
      );
    }
    return result;
  }

  Future<AppResult<bool>> recordAttendance({
    required String classId,
    required String lessonId,
    required Map<String, AttendanceStatusType> statuses,
    required Map<String, AbsenceReason> reasons,
  }) async {
    final user = currentUser;
    final lesson = lessonById(lessonId);
    if (user == null ||
        user.role != UserRole.teacher ||
        lesson == null ||
        lesson.classId != classId ||
        lesson.teacherId != user.id) {
      return const AppResult<bool>.failure('auth.roleMismatch');
    }

    final entries = statuses.entries
        .where((entry) => studentsForClass(classId).any(
              (student) => student.id == entry.key,
            ))
        .map(
          (entry) => AttendanceEntry(
            studentId: entry.key,
            status: entry.value,
            reason: entry.value == AttendanceStatusType.absent
                ? (reasons[entry.key] ?? AbsenceReason.unexcused)
                : AbsenceReason.none,
          ),
        )
        .toList();
    if (entries.isEmpty) {
      return const AppResult<bool>.failure('validation.invalidAttendance');
    }

    final now = DateTime.now();
    final removedSessions = _attendanceSessions
        .where(
          (session) =>
              session.classId == classId &&
              session.lessonId == lessonId &&
              session.recordedAt.year == now.year &&
              session.recordedAt.month == now.month &&
              session.recordedAt.day == now.day,
        )
        .toList();
    _attendanceSessions.removeWhere(
      (session) =>
          session.classId == classId &&
          session.lessonId == lessonId &&
          session.recordedAt.year == now.year &&
          session.recordedAt.month == now.month &&
          session.recordedAt.day == now.day,
    );

    final session = AttendanceSession(
      id: _nextId('attendance'),
      classId: classId,
      lessonId: lessonId,
      teacherId: user.id,
      recordedAt: now,
      entries: entries,
    );
    _attendanceSessions.add(session);
    final result = await _commitDatabaseWrite(
      data: true,
      write: (db) async {
        for (final removedSession in removedSessions) {
          await db.deleteAttendanceSession(removedSession.id);
        }
        await db.setAttendanceSession(session.id, _attendanceToMap(session));
      },
      rollback: () {
        _attendanceSessions.removeWhere((item) => item.id == session.id);
        _attendanceSessions.addAll(removedSessions);
      },
    );
    if (result.isSuccess) {
      unawaited(
        monitoringService.logEvent(
          MonitoringEvents.attendanceSaved,
          parameters: {
            'teacherId': user.id,
            'lessonId': lessonId,
            'classId': classId,
            'count': entries.length,
          },
        ),
      );
    }
    return result;
  }

  List<SchoolClass> classesForTeacher(String teacherId) {
    final classIds = _lessons
        .where((lesson) => lesson.teacherId == teacherId)
        .map((lesson) => lesson.classId)
        .toSet();
    return schoolClasses.where((item) => classIds.contains(item.id)).toList();
  }

  List<LessonAssignment> lessonsForTeacher(String teacherId) {
    return lessons.where((lesson) => lesson.teacherId == teacherId).toList();
  }

  List<LessonAssignment> lessonsForTeacherAndDay(
      String teacherId, int dayIndex) {
    return lessons
        .where(
          (lesson) =>
              lesson.teacherId == teacherId && lesson.weekdayIndex == dayIndex,
        )
        .toList();
  }

  List<LessonAssignment> lessonsForClass(String classId) {
    return lessons.where((lesson) => lesson.classId == classId).toList();
  }

  List<AppUser> studentsForClass(String classId) {
    return students.where((student) => student.schoolClass == classId).toList()
      ..sort((a, b) => a.fullName.compareTo(b.fullName));
  }

  List<GradeEntry> gradesForTeacher(String teacherId) {
    return gradeEntries.where((grade) => grade.teacherId == teacherId).toList();
  }

  List<GradeEntry> gradesForStudent(String studentId) {
    return gradeEntries.where((grade) => grade.studentId == studentId).toList();
  }

  List<GradeEntry> gradesForClass(String classId) {
    return gradeEntries.where((grade) => grade.classId == classId).toList();
  }

  List<GradeEntry> gradesForLesson(String lessonId) {
    return gradeEntries.where((grade) => grade.lessonId == lessonId).toList();
  }

  LessonAssignment? lessonById(String lessonId) {
    for (final lesson in _lessons) {
      if (lesson.id == lessonId) {
        return lesson;
      }
    }
    return null;
  }

  AppUser? userById(String userId) {
    for (final account in _accounts) {
      if (account.user.id == userId) {
        return account.user;
      }
    }
    return null;
  }

  GradeEntry? latestGradeForStudentLesson({
    required String studentId,
    required String lessonId,
  }) {
    final matching = _grades
        .where(
          (grade) => grade.studentId == studentId && grade.lessonId == lessonId,
        )
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return matching.isEmpty ? null : matching.first;
  }

  AttendanceSession? latestAttendanceForLesson(String lessonId) {
    final matching = _attendanceSessions
        .where((session) => session.lessonId == lessonId)
        .toList()
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    return matching.isEmpty ? null : matching.first;
  }

  List<AttendanceSession> attendanceSessionsForStudent(String studentId) {
    return attendanceSessions
        .where(
          (session) =>
              session.entries.any((entry) => entry.studentId == studentId),
        )
        .toList();
  }

  List<HomeworkAssignment> assignmentsForTeacher(String teacherId) {
    return homeworkAssignments
        .where((assignment) => assignment.teacherId == teacherId)
        .toList();
  }

  List<HomeworkAssignment> assignmentsForClass(String classId) {
    return homeworkAssignments
        .where((assignment) => assignment.classId == classId)
        .toList();
  }

  List<HomeworkAssignment> assignmentsForStudent(String studentId) {
    final student = userById(studentId);
    final classId = student?.schoolClass;
    if (classId == null || classId.isEmpty) {
      return const [];
    }
    return assignmentsForClass(classId);
  }

  HomeworkAssignment? homeworkAssignmentById(String assignmentId) {
    for (final assignment in _homeworkAssignments) {
      if (assignment.id == assignmentId) {
        return assignment;
      }
    }
    return null;
  }

  HomeworkSubmission? submissionForAssignment({
    required String assignmentId,
    required String studentId,
  }) {
    for (final submission in _homeworkSubmissions) {
      if (submission.assignmentId == assignmentId &&
          submission.studentId == studentId) {
        return submission;
      }
    }
    return null;
  }

  int submissionsCountForAssignment(String assignmentId) {
    return _homeworkSubmissions
        .where((submission) => submission.assignmentId == assignmentId)
        .length;
  }

  List<ParentMeeting> meetingsForClass(String classId) {
    return parentMeetings
        .where((meeting) => meeting.classId == classId)
        .toList();
  }

  List<AppUser> childrenForParent(AppUser? parent) {
    if (parent == null || parent.role != UserRole.parent) return const [];
    final studentIds = _parentStudentLinks
        .where((link) => link.parentId == parent.id)
        .map((link) => link.studentId)
        .toSet();
    if (parent.linkedStudentIds.isNotEmpty) {
      studentIds.addAll(parent.linkedStudentIds);
    } else if (parent.linkedStudentId != null) {
      studentIds.add(parent.linkedStudentId!);
    }
    return students.where((s) => studentIds.contains(s.id)).toList();
  }

  bool parentCanAccessStudent(String parentId, String studentId) {
    return _parentStudentLinks.any(
        (link) => link.parentId == parentId && link.studentId == studentId);
  }

  bool parentCanAccessStudentForClientMigration(
      String parentId, String studentId) {
    return parentCanAccessStudent(parentId, studentId) ||
        (userById(parentId)?.linkedStudentIds.contains(studentId) ?? false) ||
        (userById(parentId)?.linkedStudentId == studentId);
  }

  bool parentCanAccessClass(String parentId, String classId) {
    return _parentClassLinks
        .any((link) => link.parentId == parentId && link.classId == classId);
  }

  bool parentCanAccessClassForClientMigration(String parentId, String classId) {
    return parentCanAccessClass(parentId, classId) ||
        childrenForParent(userById(parentId))
            .any((student) => student.schoolClass == classId);
  }

  List<SchoolClass> classesForParent(String parentId) {
    final classIds = _parentClassLinks
        .where((link) => link.parentId == parentId)
        .map((link) => link.classId)
        .toSet();
    classIds.addAll(childrenForParent(userById(parentId))
        .map((s) => s.schoolClass)
        .whereType<String>());
    return schoolClasses.where((c) => classIds.contains(c.id)).toList();
  }

  Future<AppResult<bool>> linkParentToStudent(
    String parentId,
    String studentId,
  ) async {
    final parent = userById(parentId);
    final student = userById(studentId);
    if (parent == null || student == null) {
      return const AppResult.failure('validation.notFound');
    }

    final linkId = '${parentId}_$studentId';
    if (_parentStudentLinks.any((l) => l.id == linkId)) {
      return const AppResult.success(true);
    }

    final link = ParentStudentLink(
      id: linkId,
      parentId: parentId,
      studentId: studentId,
      createdAt: DateTime.now(),
    );

    _parentStudentLinks.add(link);
    ParentClassLink? classLink;
    if (student.schoolClass != null && student.schoolClass!.isNotEmpty) {
      final cLinkId = '${parentId}_${student.schoolClass}';
      if (!_parentClassLinks.any((l) => l.id == cLinkId)) {
        classLink = ParentClassLink(
          id: cLinkId,
          parentId: parentId,
          classId: student.schoolClass!,
          createdAt: DateTime.now(),
        );
        _parentClassLinks.add(classLink);
      }
    }

    return _commitDatabaseWrite(
      data: true,
      write: (db) async {
        await db.setParentStudentLink(link.id, _parentStudentLinkToMap(link));
        if (classLink != null) {
          await db.setParentClassLink(
              classLink.id, _parentClassLinkToMap(classLink));
        }
      },
      rollback: () {
        _parentStudentLinks.removeWhere((l) => l.id == link.id);
        if (classLink != null) {
          _parentClassLinks.removeWhere((l) => l.id == classLink!.id);
        }
      },
    );
  }

  AttendanceEntry? attendanceEntryForStudent({
    required AttendanceSession session,
    required String studentId,
  }) {
    for (final entry in session.entries) {
      if (entry.studentId == studentId) {
        return entry;
      }
    }
    return null;
  }

  AppUser? studentForParent(AppUser? parent) {
    final children = childrenForParent(parent);
    return children.isEmpty ? null : children.first;
  }

  double averageGrade(List<GradeEntry> grades) {
    if (grades.isEmpty) {
      return 0;
    }
    final total = grades.fold<int>(0, (sum, grade) => sum + grade.value);
    return total / grades.length;
  }

  int suggestedQuarterGrade(double avg) {
    if (avg >= 4.6) return 5;
    if (avg >= 3.6) return 4;
    if (avg >= 2.6) return 3;
    return 2;
  }

  List<QuarterGrade> quarterGradesForStudent(String studentId) {
    return quarterGrades
        .where((qg) => qg.studentId == studentId)
        .toList();
  }

  List<QuarterGrade> quarterGradesForClass(String classId) {
    return quarterGrades
        .where((qg) => qg.classId == classId)
        .toList();
  }

  Future<AppResult<QuarterGrade>> setQuarterGrade({
    required String studentId,
    required String classId,
    required String subject,
    required int quarter,
    required int value,
    required double averageGradeValue,
  }) async {
    final user = currentUser;
    if (user == null || user.role != UserRole.teacher) {
      return const AppResult<QuarterGrade>.failure('auth.roleMismatch');
    }
    if (value < 2 || value > 5 || quarter < 1 || quarter > 4) {
      return const AppResult<QuarterGrade>.failure('validation.invalidQuarterGrade');
    }
    _quarterGrades.removeWhere(
      (qg) => qg.studentId == studentId && qg.subject == subject && qg.quarter == quarter,
    );
    final qg = QuarterGrade(
      id: _nextId('quarter-grade'),
      studentId: studentId,
      classId: classId,
      subject: subject,
      quarter: quarter,
      value: value,
      averageGrade: averageGradeValue,
      teacherId: user.id,
      createdAt: DateTime.now(),
    );
    _quarterGrades.add(qg);
    notifyListeners();
    return AppResult<QuarterGrade>.success(qg);
  }

  Future<AppResult<HomeworkSubmission>> gradeHomeworkSubmission({
    required String submissionId,
    required int grade,
    String gradeComment = '',
  }) async {
    final user = currentUser;
    if (user == null || user.role != UserRole.teacher) {
      return const AppResult<HomeworkSubmission>.failure('auth.roleMismatch');
    }
    if (grade < 2 || grade > 5) {
      return const AppResult<HomeworkSubmission>.failure('validation.invalidGrade');
    }
    final idx = _homeworkSubmissions.indexWhere((s) => s.id == submissionId);
    if (idx < 0) {
      return const AppResult<HomeworkSubmission>.failure('validation.invalidSubmission');
    }
    final updated = _homeworkSubmissions[idx].copyWith(
      grade: grade,
      gradeComment: gradeComment.trim(),
    );
    _homeworkSubmissions[idx] = updated;
    final result = await _commitDatabaseWrite(
      data: updated,
      write: (db) => db.setHomeworkSubmission(updated.id, _submissionToMap(updated)),
      rollback: () {
        final rollIdx = _homeworkSubmissions.indexWhere((s) => s.id == submissionId);
        if (rollIdx >= 0) {
          _homeworkSubmissions[rollIdx] = _homeworkSubmissions[rollIdx].copyWith(
            grade: null,
            gradeComment: null,
          );
        }
      },
    );
    return result;
  }

  List<HomeworkSubmission> submissionsForAssignment(String assignmentId) {
    return homeworkSubmissions
        .where((s) => s.assignmentId == assignmentId)
        .toList();
  }

  List<HomeworkSubmission> submissionsForStudent(String studentId) {
    return homeworkSubmissions
        .where((s) => s.studentId == studentId)
        .toList();
  }

  String weekdayLabel(int weekdayIndex) {
    const labels = ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ'];
    if (weekdayIndex < 0 || weekdayIndex >= labels.length) {
      return 'ПН';
    }
    return labels[weekdayIndex];
  }

  String attendanceLabel(AttendanceStatusType status) {
    switch (status) {
      case AttendanceStatusType.present:
        return 'Был';
      case AttendanceStatusType.late:
        return 'Опоздал';
      case AttendanceStatusType.absent:
        return 'НБ';
    }
  }

  String absenceReasonLabel(AbsenceReason reason) {
    switch (reason) {
      case AbsenceReason.none:
        return 'Не указано';
      case AbsenceReason.unexcused:
        return 'Без причины';
      case AbsenceReason.sickLeave:
        return 'Больничный';
      case AbsenceReason.excused:
        return 'Уважительная причина';
    }
  }

  Map<String, dynamic> _accountToMap(AppAccount account) {
    final user = account.user;
    return {
      'id': user.id,
      'fullName': user.fullName,
      'email': user.email,
      'phone': user.phone,
      'role': user.role.name,
      'status': user.status.name,
      'schoolClass': user.schoolClass,
      'linkedStudentId': user.linkedStudentId,
      'linkedStudentIds': user.linkedStudentIds,
      'createdAt': account.createdAt,
    };
  }

  AppAccount _accountFromMap(Map<String, dynamic> map) {
    return AppAccount(
      user: AppUser(
        id: _stringValue(map['id'], fallback: _nextId('user')),
        fullName: _stringValue(map['fullName'], fallback: 'Без имени'),
        email: _nullableString(map['email']),
        phone: _nullableString(map['phone']),
        role: _enumValue(UserRole.values, map['role'], UserRole.student),
        status: _enumValue(
          UserStatus.values,
          map['status'],
          UserStatus.active,
        ),
        schoolClass: _nullableString(map['schoolClass']),
        linkedStudentId: _nullableString(map['linkedStudentId']),
        linkedStudentIds: _stringListValue(map['linkedStudentIds']) ??
            (_nullableString(map['linkedStudentId']) != null
                ? [_nullableString(map['linkedStudentId'])!]
                : const []),
      ),
      createdAt: _dateValue(map['createdAt']),
    );
  }

  Map<String, dynamic> _registrationToMap(RegistrationRequest request) {
    return {
      'id': request.id,
      'fullName': request.fullName,
      'email': request.email,
      'phone': request.phone,
      'role': request.role.name,
      'schoolClass': request.schoolClass,
      'parentFullName': request.parentFullName,
      'parentEmail': request.parentEmail,
      'parentPhone': request.parentPhone,
      'requestedAt': request.requestedAt,
      'status': request.status.name,
      'reviewedAt': request.reviewedAt,
      'reviewNote': request.reviewNote,
    };
  }

  RegistrationRequest _registrationFromMap(Map<String, dynamic> map) {
    return RegistrationRequest(
      id: _stringValue(map['id'], fallback: _nextId('request')),
      fullName: _stringValue(map['fullName'], fallback: 'Без имени'),
      email: _stringValue(map['email']),
      phone: _stringValue(map['phone']),
      role: _enumValue(UserRole.values, map['role'], UserRole.student),
      schoolClass: _nullableString(map['schoolClass']),
      parentFullName: _nullableString(map['parentFullName']),
      parentEmail: _nullableString(map['parentEmail']),
      parentPhone: _nullableString(map['parentPhone']),
      requestedAt: _dateValue(map['requestedAt']),
      status: _enumValue(
        RegistrationStatus.values,
        map['status'],
        RegistrationStatus.pending,
      ),
      reviewedAt: _nullableDateValue(map['reviewedAt']),
      reviewNote: _nullableString(map['reviewNote']),
    );
  }

  Map<String, dynamic> _schoolClassToMap(SchoolClass schoolClass) {
    return {
      'id': schoolClass.id,
      'name': schoolClass.name,
    };
  }

  SchoolClass _schoolClassFromMap(Map<String, dynamic> map) {
    final id = _stringValue(map['id'], fallback: _stringValue(map['name']));
    return SchoolClass(
      id: id,
      name: _stringValue(map['name'], fallback: id),
    );
  }

  Map<String, dynamic> _lessonToMap(LessonAssignment lesson) {
    return {
      'id': lesson.id,
      'classId': lesson.classId,
      'teacherId': lesson.teacherId,
      'subject': lesson.subject,
      'weekdayIndex': lesson.weekdayIndex,
      'timeRange': lesson.timeRange,
      'room': lesson.room,
    };
  }

  List<Map<String, dynamic>> _teacherClassMaps() {
    final ids = <String, Map<String, dynamic>>{};
    for (final lesson in _lessons) {
      final id = '${lesson.teacherId}_${lesson.classId}';
      ids[id] = {
        'id': id,
        'teacherId': lesson.teacherId,
        'classId': lesson.classId,
      };
    }
    return ids.values.toList();
  }

  LessonAssignment _lessonFromMap(Map<String, dynamic> map) {
    return LessonAssignment(
      id: _stringValue(map['id'], fallback: _nextId('lesson')),
      classId: _stringValue(map['classId']),
      teacherId: _stringValue(map['teacherId']),
      subject: _stringValue(map['subject'], fallback: 'Урок'),
      weekdayIndex: _intValue(map['weekdayIndex']),
      timeRange: _stringValue(map['timeRange'], fallback: '08:30 - 09:15'),
      room: _stringValue(map['room'], fallback: 'Каб.'),
    );
  }

  Map<String, dynamic> _gradeToMap(GradeEntry grade) {
    return {
      'id': grade.id,
      'studentId': grade.studentId,
      'lessonId': grade.lessonId,
      'classId': grade.classId,
      'teacherId': grade.teacherId,
      'subject': grade.subject,
      'value': grade.value,
      'category': grade.category,
      'comment': grade.comment,
      'createdAt': grade.createdAt,
    };
  }

  GradeEntry _gradeFromMap(Map<String, dynamic> map) {
    return GradeEntry(
      id: _stringValue(map['id'], fallback: _nextId('grade')),
      studentId: _stringValue(map['studentId']),
      lessonId: _stringValue(map['lessonId']),
      classId: _stringValue(map['classId']),
      teacherId: _stringValue(map['teacherId']),
      subject: _stringValue(map['subject'], fallback: 'Урок'),
      value: _intValue(map['value'], fallback: 2),
      category: _stringValue(map['category'], fallback: 'Оценка за урок'),
      comment: _stringValue(map['comment']),
      createdAt: _dateValue(map['createdAt']),
    );
  }

  Map<String, dynamic> _fileToMap(ManagedSchoolFile file) {
    return {
      'id': file.id,
      'name': file.name,
      'category': file.category,
      'classId': file.classId,
      'uploadedByUserId': file.uploadedByUserId,
      'uploadedAt': file.uploadedAt,
      'sizeLabel': file.sizeLabel,
      'storagePath': file.storagePath,
      'downloadUrl': file.downloadUrl,
      'contentType': file.contentType,
      'topic': file.topic,
      'description': file.description,
    };
  }

  ManagedSchoolFile _fileFromMap(Map<String, dynamic> map) {
    return ManagedSchoolFile(
      id: _stringValue(map['id'], fallback: _nextId('file')),
      name: _stringValue(map['name'], fallback: 'Файл'),
      category: _stringValue(map['category'], fallback: 'Документы'),
      classId: _nullableString(map['classId']),
      uploadedByUserId: _stringValue(map['uploadedByUserId']),
      uploadedAt: _dateValue(map['uploadedAt']),
      sizeLabel: _stringValue(map['sizeLabel'], fallback: '0 КБ'),
      storagePath: _nullableString(map['storagePath']),
      downloadUrl: _nullableString(map['downloadUrl']),
      contentType: _nullableString(map['contentType']),
      topic: _nullableString(map['topic']),
      description: _nullableString(map['description']),
    );
  }

  Map<String, dynamic> _attendanceToMap(AttendanceSession session) {
    return {
      'id': session.id,
      'classId': session.classId,
      'lessonId': session.lessonId,
      'teacherId': session.teacherId,
      'recordedAt': session.recordedAt,
      'entries': session.entries
          .map(
            (entry) => {
              'studentId': entry.studentId,
              'status': entry.status.name,
              'reason': entry.reason.name,
            },
          )
          .toList(),
    };
  }

  AttendanceSession _attendanceFromMap(Map<String, dynamic> map) {
    final entries = (map['entries'] is Iterable ? map['entries'] : const [])
        .whereType<Map>()
        .map(
          (entry) => AttendanceEntry(
            studentId: _stringValue(entry['studentId']),
            status: _enumValue(
              AttendanceStatusType.values,
              entry['status'],
              AttendanceStatusType.present,
            ),
            reason: _enumValue(
              AbsenceReason.values,
              entry['reason'],
              AbsenceReason.none,
            ),
          ),
        )
        .toList();

    return AttendanceSession(
      id: _stringValue(map['id'], fallback: _nextId('attendance')),
      classId: _stringValue(map['classId']),
      lessonId: _stringValue(map['lessonId']),
      teacherId: _stringValue(map['teacherId']),
      recordedAt: _dateValue(map['recordedAt']),
      entries: entries,
    );
  }

  Map<String, dynamic> _assignmentToMap(HomeworkAssignment assignment) {
    return {
      'id': assignment.id,
      'classId': assignment.classId,
      'teacherId': assignment.teacherId,
      'subject': assignment.subject,
      'title': assignment.title,
      'description': assignment.description,
      'dueAt': assignment.dueAt,
      'kind': assignment.kind.name,
      'urgent': assignment.urgent,
      'requiresFile': assignment.requiresFile,
      'createdAt': assignment.createdAt,
    };
  }

  HomeworkAssignment _assignmentFromMap(Map<String, dynamic> map) {
    return HomeworkAssignment(
      id: _stringValue(map['id'], fallback: _nextId('assignment')),
      classId: _stringValue(map['classId']),
      teacherId: _stringValue(map['teacherId']),
      subject: _stringValue(map['subject'], fallback: 'Урок'),
      title: _stringValue(map['title'], fallback: 'Задание'),
      description: _stringValue(map['description']),
      dueAt: _dateValue(map['dueAt']),
      kind: _enumValue(
        AssignmentKind.values,
        map['kind'],
        AssignmentKind.homework,
      ),
      urgent: map['urgent'] == true,
      requiresFile: map['requiresFile'] != false,
      createdAt: _dateValue(map['createdAt']),
    );
  }

  Map<String, dynamic> _submissionToMap(HomeworkSubmission submission) {
    return {
      'id': submission.id,
      'assignmentId': submission.assignmentId,
      'studentId': submission.studentId,
      'fileName': submission.fileName,
      'sizeLabel': submission.sizeLabel,
      'storagePath': submission.storagePath,
      'downloadUrl': submission.downloadUrl,
      'late': submission.late,
      'submittedAt': submission.submittedAt,
      'grade': submission.grade,
      'gradeComment': submission.gradeComment,
    };
  }

  HomeworkSubmission _submissionFromMap(Map<String, dynamic> map) {
    return HomeworkSubmission(
      id: _stringValue(map['id'], fallback: _nextId('submission')),
      assignmentId: _stringValue(map['assignmentId']),
      studentId: _stringValue(map['studentId']),
      fileName: _stringValue(map['fileName'], fallback: 'Файл'),
      sizeLabel: _stringValue(map['sizeLabel'], fallback: '0 КБ'),
      storagePath: _nullableString(map['storagePath']),
      downloadUrl: _nullableString(map['downloadUrl']),
      late: map['late'] == true,
      submittedAt: _dateValue(map['submittedAt']),
      grade: map['grade'] is int ? map['grade'] as int : null,
      gradeComment: _nullableString(map['gradeComment']),
    );
  }

  Map<String, dynamic> _meetingToMap(ParentMeeting meeting) {
    return {
      'id': meeting.id,
      'classId': meeting.classId,
      'teacherId': meeting.teacherId,
      'title': meeting.title,
      'agenda': meeting.agenda,
      'location': meeting.location,
      'meetingAt': meeting.meetingAt,
      'createdAt': meeting.createdAt,
    };
  }

  ParentMeeting _meetingFromMap(Map<String, dynamic> map) {
    return ParentMeeting(
      id: _stringValue(map['id'], fallback: _nextId('meeting')),
      classId: _stringValue(map['classId']),
      teacherId: _stringValue(map['teacherId']),
      title: _stringValue(map['title'], fallback: 'Родительское собрание'),
      agenda: _stringValue(map['agenda']),
      location: _stringValue(map['location'], fallback: 'Класс'),
      meetingAt: _dateValue(map['meetingAt']),
      createdAt: _dateValue(map['createdAt']),
    );
  }

  Map<String, dynamic> _auditLogToMap(AuditLogEntry entry) {
    return {
      'id': entry.id,
      'actorId': entry.actorId,
      'actorRole': entry.actorRole.name,
      'action': entry.action,
      'targetType': entry.targetType,
      'targetId': entry.targetId,
      'createdAt': entry.createdAt,
      'metadata': entry.metadata,
    };
  }

  AuditLogEntry _auditLogFromMap(Map<String, dynamic> map) {
    return AuditLogEntry(
      id: _stringValue(map['id'], fallback: _nextId('audit')),
      actorId: _stringValue(map['actorId']),
      actorRole: _enumValue(UserRole.values, map['actorRole'], UserRole.admin),
      action: _stringValue(map['action'], fallback: 'unknown'),
      targetType: _stringValue(map['targetType'], fallback: 'unknown'),
      targetId: _stringValue(map['targetId']),
      createdAt: _dateValue(map['createdAt']),
      metadata: _metadataFromMap(map['metadata']),
    );
  }

  Map<String, dynamic> _parentStudentLinkToMap(ParentStudentLink link) {
    return {
      'id': link.id,
      'parentId': link.parentId,
      'studentId': link.studentId,
      'createdAt': link.createdAt,
    };
  }

  ParentStudentLink _parentStudentLinkFromMap(Map<String, dynamic> map) {
    return ParentStudentLink(
      id: _stringValue(map['id']),
      parentId: _stringValue(map['parentId']),
      studentId: _stringValue(map['studentId']),
      createdAt: _dateValue(map['createdAt']),
    );
  }

  Map<String, dynamic> _parentClassLinkToMap(ParentClassLink link) {
    return {
      'id': link.id,
      'parentId': link.parentId,
      'classId': link.classId,
      'createdAt': link.createdAt,
    };
  }

  ParentClassLink _parentClassLinkFromMap(Map<String, dynamic> map) {
    return ParentClassLink(
      id: _stringValue(map['id']),
      parentId: _stringValue(map['parentId']),
      classId: _stringValue(map['classId']),
      createdAt: _dateValue(map['createdAt']),
    );
  }

  T _enumValue<T extends Enum>(List<T> values, Object? value, T fallback) {
    final name = value?.toString();
    if (name == null || name.isEmpty) {
      return fallback;
    }
    for (final item in values) {
      if (item.name == name) {
        return item;
      }
    }
    return fallback;
  }

  String _stringValue(Object? value, {String fallback = ''}) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return fallback;
    }
    return text;
  }

  String? _nullableString(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return null;
    }
    return text;
  }

  Map<String, Object?> _metadataFromMap(Object? value) {
    if (value is! Map) {
      return const {};
    }
    return value.map((key, item) => MapEntry(key.toString(), item));
  }

  List<String>? _stringListValue(Object? value) {
    if (value is Iterable) {
      final list = value
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();
      return list.isNotEmpty ? list : null;
    }
    return null;
  }

  String _localized(String russian, String kyrgyz) {
    return language == AppLanguage.kyrgyz ? kyrgyz : russian;
  }

  int _intValue(Object? value, {int fallback = 0}) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  void _seedBootstrapAdmin() {
    _accounts.add(
      AppAccount(
        user: const AppUser(
          id: 'admin-bootstrap',
          fullName: 'Bootstrap Admin',
          email: 'admin@noti.kg',
          phone: '+996555000444',
          role: UserRole.admin,
        ),
        createdAt: DateTime.now(),
      ),
    );
  }

  DateTime _dateValue(Object? value) {
    return _nullableDateValue(value) ?? DateTime.now();
  }

  DateTime? _nullableDateValue(Object? value) {
    if (value is DateTime) {
      return value;
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  // ignore: unused_element
  void _seedData() {
    _schoolClasses.addAll(
      const [
        SchoolClass(id: '9А', name: '9А'),
        SchoolClass(id: '9Б', name: '9Б'),
        SchoolClass(id: '10А', name: '10А'),
        SchoolClass(id: '10Б', name: '10Б'),
        SchoolClass(id: '11А', name: '11А'),
        SchoolClass(id: '11Б', name: '11Б'),
      ],
    );

    final now = DateTime.now();

    _accounts.addAll([
      AppAccount(
        user: const AppUser(
          id: 'teacher-demo',
          fullName: 'Сыдыкова Айжан Кубанычбековна',
          email: 'teacher@noti.kg',
          phone: '+996555000111',
          role: UserRole.teacher,
        ),
        createdAt: now.subtract(const Duration(days: 12)),
      ),
      AppAccount(
        user: const AppUser(
          id: 'teacher-physics',
          fullName: 'Петров Сергей Викторович',
          email: 'physics@noti.kg',
          phone: '+996555000555',
          role: UserRole.teacher,
        ),
        createdAt: now.subtract(const Duration(days: 11)),
      ),
      AppAccount(
        user: const AppUser(
          id: 'teacher-language',
          fullName: 'Сидорова Анна Михайловна',
          email: 'language@noti.kg',
          phone: '+996555000666',
          role: UserRole.teacher,
        ),
        createdAt: now.subtract(const Duration(days: 10)),
      ),
      AppAccount(
        user: const AppUser(
          id: 'student-demo',
          fullName: 'Токтосунов Нурсултан',
          email: 'student@noti.kg',
          phone: '+996555000222',
          role: UserRole.student,
          schoolClass: '10А',
        ),
        createdAt: now.subtract(const Duration(days: 9)),
      ),
      AppAccount(
        user: const AppUser(
          id: 'student-10a-1',
          fullName: 'Алексеев Александр',
          email: 'alex@noti.kg',
          phone: '+996555100001',
          role: UserRole.student,
          schoolClass: '10А',
        ),
        createdAt: now.subtract(const Duration(days: 8)),
      ),
      AppAccount(
        user: const AppUser(
          id: 'student-10a-2',
          fullName: 'Борисова Мария',
          email: 'maria@noti.kg',
          phone: '+996555100002',
          role: UserRole.student,
          schoolClass: '10А',
        ),
        createdAt: now.subtract(const Duration(days: 7)),
      ),
      AppAccount(
        user: const AppUser(
          id: 'student-10a-3',
          fullName: 'Васильев Дмитрий',
          email: 'dmitry@noti.kg',
          phone: '+996555100003',
          role: UserRole.student,
          schoolClass: '10А',
        ),
        createdAt: now.subtract(const Duration(days: 6)),
      ),
      AppAccount(
        user: const AppUser(
          id: 'student-10b-1',
          fullName: 'Григорьева Анна',
          email: 'anna@noti.kg',
          phone: '+996555100004',
          role: UserRole.student,
          schoolClass: '10Б',
        ),
        createdAt: now.subtract(const Duration(days: 5)),
      ),
      AppAccount(
        user: const AppUser(
          id: 'parent-demo',
          fullName: 'Токтосунова Гульмира',
          email: 'parent@noti.kg',
          phone: '+996555000333',
          role: UserRole.parent,
          schoolClass: '10А',
          linkedStudentId: 'student-demo',
        ),
        createdAt: now.subtract(const Duration(days: 4)),
      ),
      AppAccount(
        user: const AppUser(
          id: 'admin-demo',
          fullName: 'Админ Noti KG',
          email: 'admin@noti.kg',
          phone: '+996555000444',
          role: UserRole.admin,
        ),
        createdAt: now.subtract(const Duration(days: 3)),
      ),
    ]);

    _registrationRequests.addAll([
      RegistrationRequest(
        id: 'request-seeded-student',
        fullName: 'Жоомартова Айпери',
        email: 'pending-student@noti.kg',
        phone: '+996555200001',
        role: UserRole.student,
        schoolClass: '10Б',
        parentFullName: 'Жоомартова Алина',
        parentEmail: 'pending-parent@noti.kg',
        parentPhone: '+996555200101',
        requestedAt: now.subtract(const Duration(hours: 9)),
      ),
      RegistrationRequest(
        id: 'request-seeded-teacher',
        fullName: 'Иманалиева Нурзат',
        email: 'pending-teacher@noti.kg',
        phone: '+996555200002',
        role: UserRole.teacher,
        requestedAt: now.subtract(const Duration(hours: 3)),
      ),
    ]);

    _lessons.addAll([
      const LessonAssignment(
        id: 'lesson-10a-math-1',
        classId: '10А',
        teacherId: 'teacher-demo',
        subject: 'Математика',
        weekdayIndex: 0,
        timeRange: '08:30 - 09:15',
        room: 'Каб. 205',
      ),
      const LessonAssignment(
        id: 'lesson-11b-algebra-1',
        classId: '11Б',
        teacherId: 'teacher-demo',
        subject: 'Алгебра',
        weekdayIndex: 0,
        timeRange: '09:30 - 10:15',
        room: 'Каб. 205',
      ),
      const LessonAssignment(
        id: 'lesson-10b-geometry-1',
        classId: '10Б',
        teacherId: 'teacher-demo',
        subject: 'Геометрия',
        weekdayIndex: 0,
        timeRange: '10:30 - 11:15',
        room: 'Каб. 207',
      ),
      const LessonAssignment(
        id: 'lesson-10a-physics-1',
        classId: '10А',
        teacherId: 'teacher-physics',
        subject: 'Физика',
        weekdayIndex: 1,
        timeRange: '09:30 - 10:15',
        room: 'Каб. 301',
      ),
      const LessonAssignment(
        id: 'lesson-10a-language-1',
        classId: '10А',
        teacherId: 'teacher-language',
        subject: 'Русский язык',
        weekdayIndex: 2,
        timeRange: '10:30 - 11:15',
        room: 'Каб. 102',
      ),
    ]);

    _grades.addAll([
      GradeEntry(
        id: 'grade-seeded-1',
        studentId: 'student-demo',
        lessonId: 'lesson-10a-math-1',
        classId: '10А',
        teacherId: 'teacher-demo',
        subject: 'Математика',
        value: 5,
        category: 'Контрольная работа',
        comment: 'Отличная работа',
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      GradeEntry(
        id: 'grade-seeded-2',
        studentId: 'student-demo',
        lessonId: 'lesson-10a-physics-1',
        classId: '10А',
        teacherId: 'teacher-physics',
        subject: 'Физика',
        value: 4,
        category: 'Лабораторная работа',
        comment: 'Хорошо выполнено',
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      GradeEntry(
        id: 'grade-seeded-3',
        studentId: 'student-demo',
        lessonId: 'lesson-10a-language-1',
        classId: '10А',
        teacherId: 'teacher-language',
        subject: 'Русский язык',
        value: 5,
        category: 'Сочинение',
        comment: 'Грамотная работа',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      GradeEntry(
        id: 'grade-seeded-4',
        studentId: 'student-10a-1',
        lessonId: 'lesson-10a-math-1',
        classId: '10А',
        teacherId: 'teacher-demo',
        subject: 'Математика',
        value: 4,
        category: 'Контрольная работа',
        comment: '',
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      GradeEntry(
        id: 'grade-seeded-5',
        studentId: 'student-10a-2',
        lessonId: 'lesson-10a-math-1',
        classId: '10А',
        teacherId: 'teacher-demo',
        subject: 'Математика',
        value: 3,
        category: 'Контрольная работа',
        comment: 'Нужно повторить тему',
        createdAt: now.subtract(const Duration(days: 3)),
      ),
    ]);

    _homeworkAssignments.addAll([
      HomeworkAssignment(
        id: 'assignment-10a-math-homework',
        classId: '10А',
        teacherId: 'teacher-demo',
        subject: 'Математика',
        title: 'Решить задачи №124-130',
        description: 'Из учебника Алгебра 10 класс',
        dueAt: now.add(const Duration(days: 2)),
        kind: AssignmentKind.homework,
        urgent: true,
        requiresFile: true,
        createdAt: now.subtract(const Duration(hours: 8)),
      ),
      HomeworkAssignment(
        id: 'assignment-10a-physics-lab',
        classId: '10А',
        teacherId: 'teacher-physics',
        subject: 'Физика',
        title: 'Лабораторная работа №5',
        description: 'Изучение закона Ома',
        dueAt: now.add(const Duration(days: 3)),
        kind: AssignmentKind.homework,
        urgent: false,
        requiresFile: true,
        createdAt: now.subtract(const Duration(hours: 5)),
      ),
      HomeworkAssignment(
        id: 'assignment-10a-math-test',
        classId: '10А',
        teacherId: 'teacher-demo',
        subject: 'Математика',
        title: 'Контрольная работа: квадратные уравнения',
        description: 'Повторить параграфы 12-14 и принести тетрадь.',
        dueAt: now.add(const Duration(days: 5)),
        kind: AssignmentKind.testWork,
        urgent: false,
        requiresFile: false,
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
    ]);

    _homeworkSubmissions.add(
      HomeworkSubmission(
        id: 'submission-seeded-language',
        assignmentId: 'assignment-10a-physics-lab',
        studentId: 'student-demo',
        fileName: 'lab-5.pdf',
        sizeLabel: '240 КБ',
        late: false,
        submittedAt: now.subtract(const Duration(hours: 1)),
      ),
    );

    _parentMeetings.add(
      ParentMeeting(
        id: 'meeting-10a-december',
        classId: '10А',
        teacherId: 'teacher-demo',
        title: 'Родительское собрание',
        agenda: 'Итоги четверти, посещаемость и подготовка к контрольным.',
        location: 'Каб. 205',
        meetingAt: now.add(const Duration(days: 7, hours: 3)),
        createdAt: now.subtract(const Duration(hours: 4)),
      ),
    );

    _files.addAll([
      ManagedSchoolFile(
        id: 'file-1',
        name: 'Контрольная работа - Алгебра 10А.pdf',
        category: 'Контрольные работы',
        classId: '10А',
        uploadedByUserId: 'teacher-demo',
        uploadedAt: now.subtract(const Duration(days: 2)),
        sizeLabel: '2.4 МБ',
      ),
      ManagedSchoolFile(
        id: 'file-2',
        name: 'Таблица успеваемости.xlsx',
        category: 'Методические пособия',
        uploadedByUserId: 'teacher-demo',
        uploadedAt: now.subtract(const Duration(days: 3)),
        sizeLabel: '156 КБ',
      ),
      ManagedSchoolFile(
        id: 'file-3',
        name: 'Презентация - Геометрия.pptx',
        category: 'Презентации',
        classId: '10Б',
        uploadedByUserId: 'teacher-demo',
        uploadedAt: now.subtract(const Duration(days: 4)),
        sizeLabel: '8.2 МБ',
      ),
    ]);

    _attendanceSessions.add(
      AttendanceSession(
        id: 'attendance-seeded',
        classId: '10А',
        lessonId: 'lesson-10a-math-1',
        teacherId: 'teacher-demo',
        recordedAt: now.subtract(const Duration(hours: 2)),
        entries: const [
          AttendanceEntry(
            studentId: 'student-demo',
            status: AttendanceStatusType.present,
          ),
          AttendanceEntry(
            studentId: 'student-10a-1',
            status: AttendanceStatusType.late,
          ),
          AttendanceEntry(
            studentId: 'student-10a-2',
            status: AttendanceStatusType.absent,
            reason: AbsenceReason.sickLeave,
          ),
          AttendanceEntry(
            studentId: 'student-10a-3',
            status: AttendanceStatusType.present,
          ),
        ],
      ),
    );
  }

  List<AppUser> _usersByRole(UserRole role) {
    return _accounts
        .where((account) => account.user.role == role)
        .map((account) => account.user)
        .toList()
      ..sort((a, b) => a.fullName.compareTo(b.fullName));
  }

  bool _emailExists(String email) {
    if (_accounts
        .any((account) => (account.user.email ?? '').toLowerCase() == email)) {
      return true;
    }
    return _registrationRequests.any(
      (request) =>
          request.email.toLowerCase() == email &&
          request.status == RegistrationStatus.pending,
    );
  }

  bool _phoneExists(String phone) {
    if (_accounts
        .any((account) => (account.user.phone ?? '').trim() == phone)) {
      return true;
    }
    return _registrationRequests.any(
      (request) =>
          request.phone.trim() == phone &&
          request.status == RegistrationStatus.pending,
    );
  }

  bool _classExists(String classId) {
    return _schoolClasses.any((item) => item.id == classId);
  }

  bool _isSameDay(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  String _nextId(String prefix) {
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}';
  }
}

class AppStateScope extends InheritedNotifier<AppState> {
  final AppState state;

  const AppStateScope({
    super.key,
    required this.state,
    required super.child,
  }) : super(notifier: state);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    assert(scope != null, 'AppStateScope не найден в дереве');
    return scope!.state;
  }
}

extension AppContextX on BuildContext {
  AppState get appState => AppStateScope.of(this);

  AppLocalizations get strings => appState.strings;

  String tr(String key) => strings.t(key);

  String trf(String key, Map<String, String> values) =>
      strings.format(key, values);
}
