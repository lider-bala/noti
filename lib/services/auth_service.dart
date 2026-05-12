import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart';

import '../models/user_role.dart';

class AuthServiceResult {
  final AppUser? user;
  final String? errorKey;

  const AuthServiceResult.success(this.user) : errorKey = null;
  const AuthServiceResult.failure(this.errorKey) : user = null;

  bool get isSuccess => user != null;
}

abstract class AuthService {
  Future<AuthServiceResult> signIn({
    required UserRole role,
    required String email,
    required String password,
    required Iterable<AppUser> profiles,
  });

  Future<void> signOut();

  Future<String?> ensureManagedUser({
    required UserRole role,
    required String email,
    required String password,
    required String suggestedUserId,
  }) async {
    return suggestedUserId;
  }

  Future<AppUser?> restoreSignedInUser({
    required Iterable<AppUser> profiles,
  }) async {
    return null;
  }

  void rememberPendingRegistration({
    required String requestId,
    required UserRole role,
    required String email,
    required String password,
  }) {}

  void activatePendingRegistration({
    required String requestId,
    required String userId,
  }) {}

  void rememberCreatedUser({
    required String userId,
    required UserRole role,
    required String email,
    required String password,
  }) {}

  void removeUserCredential(String userId) {}
}

class FirebaseAuthAdapter implements AuthService {
  final firebase_auth.FirebaseAuth _auth;

  FirebaseAuthAdapter({firebase_auth.FirebaseAuth? auth})
      : _auth = auth ?? firebase_auth.FirebaseAuth.instance;

  @override
  Future<AuthServiceResult> signIn({
    required UserRole role,
    required String email,
    required String password,
    required Iterable<AppUser> profiles,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      final firebaseUser = credential.user;
      final profile = _profileForFirebaseUser(
        profiles: profiles,
        firebaseUid: firebaseUser?.uid,
        email: normalizedEmail,
      );
      if (profile == null) {
        await _auth.signOut();
        return const AuthServiceResult.failure('auth.profileMissing');
      }
      if (!profile.isActive) {
        await _auth.signOut();
        return const AuthServiceResult.failure('auth.accountInactive');
      }
      if (profile.role != role) {
        await _auth.signOut();
        return const AuthServiceResult.failure('auth.roleMismatch');
      }
      return AuthServiceResult.success(profile);
    } on firebase_auth.FirebaseAuthException catch (error) {
      return AuthServiceResult.failure(_errorKey(error.code));
    } catch (_) {
      return const AuthServiceResult.failure('auth.serviceUnavailable');
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<String?> ensureManagedUser({
    required UserRole role,
    required String email,
    required String password,
    required String suggestedUserId,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    firebase_auth.FirebaseAuth? secondaryAuth;
    FirebaseApp? secondaryApp;
    try {
      secondaryApp = await Firebase.initializeApp(
        name: 'managed-user-${DateTime.now().microsecondsSinceEpoch}',
        options: Firebase.app().options,
      );
      secondaryAuth = firebase_auth.FirebaseAuth.instanceFor(app: secondaryApp);
      try {
        final credential = await secondaryAuth.createUserWithEmailAndPassword(
          email: normalizedEmail,
          password: password,
        );
        return credential.user?.uid;
      } on firebase_auth.FirebaseAuthException catch (error) {
        if (error.code != 'email-already-in-use') {
          return null;
        }
        final credential = await secondaryAuth.signInWithEmailAndPassword(
          email: normalizedEmail,
          password: password,
        );
        return credential.user?.uid;
      }
    } catch (_) {
      return null;
    } finally {
      await secondaryAuth?.signOut();
      await secondaryApp?.delete();
    }
  }

  @override
  Future<AppUser?> restoreSignedInUser({
    required Iterable<AppUser> profiles,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      return null;
    }
    final profile = _profileForFirebaseUser(
      profiles: profiles,
      firebaseUid: user.uid,
      email: user.email?.trim().toLowerCase() ?? '',
    );
    if (profile == null || !profile.isActive) {
      await _auth.signOut();
      return null;
    }
    return profile;
  }

  @override
  void rememberPendingRegistration({
    required String requestId,
    required UserRole role,
    required String email,
    required String password,
  }) {}

  @override
  void activatePendingRegistration({
    required String requestId,
    required String userId,
  }) {}

  @override
  void rememberCreatedUser({
    required String userId,
    required UserRole role,
    required String email,
    required String password,
  }) {}

  @override
  void removeUserCredential(String userId) {}

  AppUser? _profileForFirebaseUser({
    required Iterable<AppUser> profiles,
    required String? firebaseUid,
    required String email,
  }) {
    for (final profile in profiles) {
      if (firebaseUid != null && profile.id == firebaseUid) {
        return profile;
      }
    }
    for (final profile in profiles) {
      if ((profile.email ?? '').trim().toLowerCase() == email) {
        return profile;
      }
    }
    return null;
  }

  String _errorKey(String code) {
    switch (code) {
      case 'invalid-email':
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'auth.invalidCredentials';
      case 'user-disabled':
        return 'auth.accountInactive';
      case 'network-request-failed':
        return 'auth.networkFailed';
      default:
        return 'auth.serviceUnavailable';
    }
  }
}

class MockAuthService implements AuthService {
  final Map<String, _MockCredential> _credentials = {};
  final Map<String, _MockCredential> _pendingCredentials = {};

  MockAuthService();

  factory MockAuthService.withBootstrapAdmin() {
    final service = MockAuthService();
    service.rememberCreatedUser(
      userId: 'admin-bootstrap',
      role: UserRole.admin,
      email: 'admin@noti.kg',
      password: 'admin123',
    );
    return service;
  }

  factory MockAuthService.withDemoCredentials() {
    final service = MockAuthService();
    const demo = {
      'teacher-demo': (UserRole.teacher, 'teacher@noti.kg', 'teacher123'),
      'teacher-physics': (UserRole.teacher, 'physics@noti.kg', 'physics123'),
      'teacher-language': (UserRole.teacher, 'language@noti.kg', 'language123'),
      'student-demo': (UserRole.student, 'student@noti.kg', 'student123'),
      'student-10a-1': (UserRole.student, 'alex@noti.kg', 'student123'),
      'student-10a-2': (UserRole.student, 'maria@noti.kg', 'student123'),
      'student-10a-3': (UserRole.student, 'dmitry@noti.kg', 'student123'),
      'student-10b-1': (UserRole.student, 'anna@noti.kg', 'student123'),
      'parent-demo': (UserRole.parent, 'parent@noti.kg', 'parent123'),
      'admin-demo': (UserRole.admin, 'admin@noti.kg', 'admin123'),
    };
    for (final entry in demo.entries) {
      service.rememberCreatedUser(
        userId: entry.key,
        role: entry.value.$1,
        email: entry.value.$2,
        password: entry.value.$3,
      );
    }
    return service;
  }

  @override
  Future<AuthServiceResult> signIn({
    required UserRole role,
    required String email,
    required String password,
    required Iterable<AppUser> profiles,
  }) async {
    return signInSync(
      role: role,
      email: email,
      password: password,
      profiles: profiles,
    );
  }

  AuthServiceResult signInSync({
    required UserRole role,
    required String email,
    required String password,
    required Iterable<AppUser> profiles,
  }) {
    final normalizedEmail = email.trim().toLowerCase();
    final credential = _credentials[_credentialKey(role, normalizedEmail)];
    if (credential == null || credential.password != password.trim()) {
      return const AuthServiceResult.failure('auth.invalidCredentials');
    }
    final profile = profiles.firstWhereOrNull(
      (item) => item.id == credential.userId,
    );
    if (profile == null) {
      return const AuthServiceResult.failure('auth.profileMissing');
    }
    if (!profile.isActive) {
      return const AuthServiceResult.failure('auth.accountInactive');
    }
    if (profile.role != role) {
      return const AuthServiceResult.failure('auth.roleMismatch');
    }
    return AuthServiceResult.success(profile);
  }

  String? passwordForDemoCredential({
    required UserRole role,
    required String email,
  }) {
    return _credentials[_credentialKey(role, email.trim().toLowerCase())]
        ?.password;
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<AppUser?> restoreSignedInUser({
    required Iterable<AppUser> profiles,
  }) async {
    return null;
  }

  @override
  Future<String?> ensureManagedUser({
    required UserRole role,
    required String email,
    required String password,
    required String suggestedUserId,
  }) async {
    rememberCreatedUser(
      userId: suggestedUserId,
      role: role,
      email: email,
      password: password,
    );
    return suggestedUserId;
  }

  @override
  void rememberPendingRegistration({
    required String requestId,
    required UserRole role,
    required String email,
    required String password,
  }) {
    _pendingCredentials[requestId] = _MockCredential(
      userId: requestId,
      role: role,
      email: email,
      password: password,
    );
  }

  @override
  void activatePendingRegistration({
    required String requestId,
    required String userId,
  }) {
    final pending = _pendingCredentials.remove(requestId);
    if (pending == null) {
      return;
    }
    rememberCreatedUser(
      userId: userId,
      role: pending.role,
      email: pending.email,
      password: pending.password,
    );
  }

  @override
  void rememberCreatedUser({
    required String userId,
    required UserRole role,
    required String email,
    required String password,
  }) {
    final normalizedEmail = email.trim().toLowerCase();
    _credentials[_credentialKey(role, normalizedEmail)] = _MockCredential(
      userId: userId,
      role: role,
      email: normalizedEmail,
      password: password.trim(),
    );
  }

  @override
  void removeUserCredential(String userId) {
    _credentials.removeWhere((_, credential) => credential.userId == userId);
    _pendingCredentials.removeWhere((_, credential) {
      return credential.userId == userId;
    });
  }

  String _credentialKey(UserRole role, String email) => '${role.name}:$email';
}

class _MockCredential {
  final String userId;
  final UserRole role;
  final String email;
  final String password;

  const _MockCredential({
    required this.userId,
    required this.role,
    required this.email,
    required this.password,
  });
}

extension _FirstWhereOrNullX<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T item) test) {
    for (final item in this) {
      if (test(item)) {
        return item;
      }
    }
    return null;
  }
}
