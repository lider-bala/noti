import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app/auth_gate.dart';
import 'app/app_state.dart';
import 'firebase_options.dart';
import 'models/user_role.dart';
import 'screens/admin/admin_main_screen.dart' as admin;
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/parents/parent_main_screen.dart' as parent;
import 'screens/student/student_main_screen.dart' as student;
import 'screens/teacher/main_screen.dart' as teacher;
import 'services/school_database_service.dart';
import 'services/auth_service.dart';
import 'services/monitoring_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const NotiApp());
}

class NotiApp extends StatefulWidget {
  const NotiApp({super.key});

  @override
  State<NotiApp> createState() => _NotiAppState();
}

class _NotiAppState extends State<NotiApp> {
  static const bool _useFirebaseAuth =
      bool.fromEnvironment('USE_FIREBASE_AUTH', defaultValue: true);
  static const bool _enableDemoData = false;
  static const bool _forceFirestore =
      bool.fromEnvironment('USE_FIRESTORE', defaultValue: true);
  late final AppState _state;

  @override
  void initState() {
    super.initState();
    final useFirestore =
        !_enableDemoData && (_useFirebaseAuth || _forceFirestore);
    _state = AppState(
      database: useFirestore ? FirestoreSchoolDatabaseService() : null,
      enableDemoData: _enableDemoData,
      enableBootstrapAdmin: !_enableDemoData && !_useFirebaseAuth,
      monitoringService: _enableDemoData
          ? const DebugMonitoringService()
          : const NoopMonitoringService(),
      authService: _useFirebaseAuth
          ? FirebaseAuthAdapter()
          : (_enableDemoData
              ? MockAuthService.withDemoCredentials()
              : MockAuthService.withBootstrapAdmin()),
    );
  }

  String _routeForRole(UserRole role) {
    switch (role) {
      case UserRole.teacher:
        return '/teacher';
      case UserRole.student:
        return '/student';
      case UserRole.parent:
        return '/parent';
      case UserRole.admin:
        return '/admin';
    }
  }

  void _goToRole(BuildContext context, AppUser user) {
    final appState = AppStateScope.of(context);
    if (!user.isActive) {
      appState.setUser(null);
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }
    Navigator.pushReplacementNamed(context, _routeForRole(user.role));
  }

  void _handleLogout(BuildContext context) {
    final appState = AppStateScope.of(context);
    unawaited(appState.signOut());
    Navigator.pushReplacementNamed(context, '/login');
  }

  Route<dynamic> _onGenerateRoute(RouteSettings settings) {
    return MaterialPageRoute(
      settings: settings,
      builder: (context) {
        switch (settings.name) {
          case '/':
            return StartupGate(onAuthenticated: _goToRole);
          case '/login':
            return LoginScreen(
              onRegister: () =>
                  Navigator.pushReplacementNamed(context, '/register'),
              onLogin: (user) => _goToRole(context, user),
            );
          case '/register':
            return RegisterScreen(
              onRegistered: (user) => _goToRole(context, user),
              onLoginTap: () =>
                  Navigator.pushReplacementNamed(context, '/login'),
            );
          case '/teacher':
            return RoleGuard(
              requiredRole: UserRole.teacher,
              child: teacher.MainScreen(
                onLogout: () => _handleLogout(context),
              ),
            );
          case '/student':
            return RoleGuard(
              requiredRole: UserRole.student,
              child: student.StudentMainScreen(
                onLogout: () => _handleLogout(context),
              ),
            );
          case '/parent':
            return RoleGuard(
              requiredRole: UserRole.parent,
              child: parent.ParentMainScreen(
                onLogout: () => _handleLogout(context),
              ),
            );
          case '/admin':
            return RoleGuard(
              requiredRole: UserRole.admin,
              child: admin.AdminMainScreen(
                onLogout: () => _handleLogout(context),
              ),
            );
          default:
            return LoginScreen(
              onRegister: () =>
                  Navigator.pushReplacementNamed(context, '/register'),
              onLogin: (user) => _goToRole(context, user),
            );
        }
      },
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final base = ThemeData(
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF10B981),
        brightness: brightness,
      ),
      useMaterial3: true,
    );
    final textTheme = GoogleFonts.notoSansTextTheme(base.textTheme);

    return base.copyWith(
      scaffoldBackgroundColor:
          isDark ? const Color(0xFF111827) : const Color(0xFFF9FAFB),
      textTheme: textTheme.apply(
        bodyColor: isDark ? const Color(0xFFE5E7EB) : const Color(0xFF111827),
        displayColor:
            isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827),
      ),
      primaryTextTheme: textTheme.apply(
        bodyColor: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827),
        displayColor:
            isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827),
      ),
      cardColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      canvasColor: isDark ? const Color(0xFF111827) : Colors.white,
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        titleTextStyle: TextStyle(
          color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827),
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: TextStyle(
          color: isDark ? const Color(0xFFE5E7EB) : const Color(0xFF111827),
        ),
      ),
      dividerColor: isDark ? const Color(0xFF475569) : const Color(0xFFE5E7EB),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        foregroundColor:
            isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827),
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF10B981);
          }
          return isDark ? const Color(0xFFCBD5E1) : null;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF10B981).withOpacity(0.35);
          }
          return isDark ? const Color(0xFF334155) : null;
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        hintStyle: TextStyle(
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF9CA3AF),
        ),
        labelStyle: TextStyle(
          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF4B5563),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.4),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: TextStyle(
          color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827),
        ),
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(
            isDark ? const Color(0xFF1E293B) : Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppStateScope(
      state: _state,
      child: ScreenUtilInit(
        designSize: const Size(1440, 900),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          final appState = AppStateScope.of(context);

          return MaterialApp(
            title: appState.strings.t('app.name'),
            debugShowCheckedModeBanner: false,
            locale: appState.language.locale,
            supportedLocales: const [
              Locale('ru', 'KG'),
              Locale('ky', 'KG'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: _buildTheme(Brightness.light),
            darkTheme: _buildTheme(Brightness.dark),
            themeMode: appState.themeMode,
            builder: (context, widget) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(
                    ScreenUtil().textScaleFactor,
                  ),
                ),
                child: widget ?? const SizedBox.shrink(),
              );
            },
            initialRoute: '/',
            onGenerateRoute: _onGenerateRoute,
          );
        },
      ),
    );
  }
}

class StartupGate extends StatefulWidget {
  final void Function(BuildContext context, AppUser user) onAuthenticated;

  const StartupGate({
    super.key,
    required this.onAuthenticated,
  });

  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  bool _routed = false;

  @override
  Widget build(BuildContext context) {
    final appState = context.appState;
    final user = appState.currentUser;
    if (!_routed && user != null && user.isActive) {
      _routed = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onAuthenticated(context, user);
        }
      });
    }

    if (appState.isDatabaseSyncing && user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return LoginScreen(
      onRegister: () => Navigator.pushReplacementNamed(context, '/register'),
      onLogin: (user) => widget.onAuthenticated(context, user),
    );
  }
}
