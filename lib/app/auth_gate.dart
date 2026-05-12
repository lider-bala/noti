import 'package:flutter/material.dart';

import '../models/user_role.dart';
import 'app_state.dart';

class RoleGuard extends StatefulWidget {
  final UserRole requiredRole;
  final Widget child;

  const RoleGuard({
    super.key,
    required this.requiredRole,
    required this.child,
  });

  @override
  State<RoleGuard> createState() => _RoleGuardState();
}

class _RoleGuardState extends State<RoleGuard> {
  bool _redirectScheduled = false;

  @override
  Widget build(BuildContext context) {
    final appState = context.appState;
    final user = appState.currentUser;

    if (user == null) {
      if (appState.isDatabaseSyncing) {
        return const _AuthGateShell();
      }
      _redirectToLogin();
      return const _AuthGateShell();
    }

    if (!user.isActive || user.role != widget.requiredRole) {
      return ForbiddenScreen(
        reason: !user.isActive
            ? context.tr('auth.accountInactive')
            : context.tr('auth.roleMismatch'),
      );
    }

    return widget.child;
  }

  void _redirectToLogin() {
    if (_redirectScheduled) {
      return;
    }
    _redirectScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushReplacementNamed('/login');
    });
  }
}

class ForbiddenScreen extends StatelessWidget {
  final String reason;

  const ForbiddenScreen({
    super.key,
    required this.reason,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_person_rounded,
                  size: 56,
                  color: Color(0xFFB91C1C),
                ),
                const SizedBox(height: 16),
                Text(
                  context.tr('Доступ запрещён'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  reason,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () async {
                    await context.appState.signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushReplacementNamed('/login');
                    }
                  },
                  child: Text(context.tr('Войти заново')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthGateShell extends StatelessWidget {
  const _AuthGateShell();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
