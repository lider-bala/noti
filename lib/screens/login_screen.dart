import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../app/app_state.dart';
import '../models/user_role.dart';
import '../utils/input_formatters.dart';
import '../utils/validators.dart';
import '../widgets/app_feedback.dart';
import '../widgets/app_theme.dart';
import '../widgets/language_menu_button.dart';
import '../widgets/theme_toggle_button.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onRegister;
  final ValueChanged<AppUser> onLogin;

  const LoginScreen({
    super.key,
    required this.onRegister,
    required this.onLogin,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final FocusNode _emailFocusNode;
  late final FocusNode _passwordFocusNode;
  late final AnimationController _backgroundController;

  UserRole _selectedRole = UserRole.teacher;
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _emailFocusNode = FocusNode();
    _passwordFocusNode = FocusNode();
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final result = await context.appState.signIn(
      role: _selectedRole,
      email: _emailController.text,
      password: _passwordController.text,
    );
    if (!mounted) {
      return;
    }

    if (!result.isSuccess) {
      showAppSnackBar(
        context,
        context.tr(result.errorKey!),
        backgroundColor: const Color(0xFFB91C1C),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    widget.onLogin(result.user!);
  }

  void _useDemoAccount(AppAccount account) {
    setState(() {
      _selectedRole = account.user.role;
      _emailController.text = account.user.email ?? '';
      _passwordController.text =
          context.appState.demoPasswordFor(account) ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final accounts = context.appState.accounts;
    final isDark = context.isDarkTheme;
    final gradientColors = isDark
        ? const [
            Color(0xFF0F172A),
            Color(0xFF1E3A8A),
            Color(0xFF134E4A),
          ]
        : const [
            Color(0xFF60A5FA),
            Color(0xFF6EE7B7),
            Color(0xFF2DD4BF),
          ];

    return Scaffold(
      backgroundColor: gradientColors.last,
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _backgroundController,
              builder: (context, _) {
                final t = _backgroundController.value;
                final s1 = 1 + 0.3 * math.sin(t * 2 * math.pi);
                final s2 = 1 + 0.2 * math.cos((t + 0.3) * 2 * math.pi);
                final dx1 = 40 * math.sin(t * 2 * math.pi);
                final dy1 = -20 * math.cos(t * 2 * math.pi);
                final dx2 = -40 * math.cos((t + 0.4) * 2 * math.pi);
                final dy2 = 30 * math.sin((t + 0.4) * 2 * math.pi);

                return Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: gradientColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                    Align(
                      alignment: const Alignment(-1, -0.1),
                      child: Transform.translate(
                        offset: Offset(dx1, dy1),
                        child: Transform.scale(
                          scale: s1,
                          child: _BlurCircle(
                            color: (isDark
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFF93C5FD))
                                .withOpacity(0.3),
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: const Alignment(1, 0.1),
                      child: Transform.translate(
                        offset: Offset(dx2, dy2),
                        child: Transform.scale(
                          scale: s2,
                          child: _BlurCircle(
                            color: (isDark
                                    ? const Color(0xFF14B8A6)
                                    : const Color(0xFF6EE7B7))
                                .withOpacity(0.3),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const Positioned(
            top: 0,
            right: 0,
            child: SafeArea(
              minimum: EdgeInsets.only(top: 12, right: 24),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ThemeToggleButton(light: true),
                  SizedBox(width: 8),
                  LanguageMenuButton(light: true),
                ],
              ),
            ),
          ),
          SafeArea(
            minimum: const EdgeInsets.only(top: 116),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              physics: const BouncingScrollPhysics(),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _LogoHeader(),
                      const SizedBox(height: 24),
                      _RoleSelector(
                        current: _selectedRole,
                        onChanged: (role) {
                          setState(() => _selectedRole = role);
                        },
                      ),
                      const SizedBox(height: 14),
                      _GlassLoginCard(
                        formKey: _formKey,
                        emailController: _emailController,
                        passwordController: _passwordController,
                        emailFocusNode: _emailFocusNode,
                        passwordFocusNode: _passwordFocusNode,
                        showPassword: _showPassword,
                        onTogglePassword: () {
                          setState(() => _showPassword = !_showPassword);
                        },
                        onForgotPassword: () {
                          showAppSnackBar(
                            context,
                            context.tr('auth.resetSoon'),
                          );
                        },
                        onSocialTap: () {
                          showAppSnackBar(
                            context,
                            context.tr('auth.socialSoon'),
                          );
                        },
                        onLogin: _login,
                      ),
                      const SizedBox(height: 16),
                      if (context.appState.isDemoMode) ...[
                        _DemoCredentialsCard(
                          accounts: accounts,
                          onPick: _useDemoAccount,
                        ),
                        const SizedBox(height: 20),
                      ],
                      _RegisterFooter(onRegister: widget.onRegister),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlurCircle extends StatelessWidget {
  final Color color;

  const _BlurCircle({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      height: 260,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _LogoHeader extends StatelessWidget {
  const _LogoHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.8, end: 1),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutBack,
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 40,
                      offset: Offset(0, 20),
                      color: Colors.black26,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.school_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        Text(
          context.tr('auth.welcome'),
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          context.tr('app.tagline'),
          style: TextStyle(
            color: Colors.white.withOpacity(0.82),
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _RoleSelector extends StatelessWidget {
  final UserRole current;
  final ValueChanged<UserRole> onChanged;

  const _RoleSelector({
    required this.current,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const roles = UserRole.values;

    return Row(
      children: [
        for (final role in roles) ...[
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(role),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: current == role
                      ? Colors.white
                      : Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: current == role
                        ? Colors.transparent
                        : Colors.white.withOpacity(0.3),
                  ),
                  boxShadow: current == role
                      ? const [
                          BoxShadow(
                            blurRadius: 18,
                            offset: Offset(0, 8),
                            color: Colors.black26,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    context.strings.role(role),
                    style: TextStyle(
                      color: current == role
                          ? const Color(0xFF2ECC71)
                          : Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (role != roles.last) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _GlassLoginCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final FocusNode emailFocusNode;
  final FocusNode passwordFocusNode;
  final bool showPassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onForgotPassword;
  final VoidCallback onSocialTap;
  final VoidCallback onLogin;

  const _GlassLoginCard({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.emailFocusNode,
    required this.passwordFocusNode,
    required this.showPassword,
    required this.onTogglePassword,
    required this.onForgotPassword,
    required this.onSocialTap,
    required this.onLogin,
  });

  InputDecoration _inputDecoration(BuildContext context, String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIcon: Icon(icon, color: Colors.white70),
      filled: true,
      fillColor: Colors.white.withOpacity(0.2),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Colors.white, width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Color(0xFFFECACA)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Color(0xFFFECACA)),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
            ),
            boxShadow: const [
              BoxShadow(
                blurRadius: 30,
                offset: Offset(0, 18),
                color: Colors.black26,
              ),
            ],
          ),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _AnimatedFieldWrapper(
                  focusNode: emailFocusNode,
                  child: TextFormField(
                    controller: emailController,
                    focusNode: emailFocusNode,
                    cursorColor: Colors.white,
                    style: TextStyle(color: Colors.white),
                    validator: (value) =>
                        InputValidators.validateEmail(context, value),
                    decoration: _inputDecoration(
                      context,
                      context.tr('auth.email'),
                      Icons.email_outlined,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _AnimatedFieldWrapper(
                  focusNode: passwordFocusNode,
                  child: TextFormField(
                    controller: passwordController,
                    focusNode: passwordFocusNode,
                    cursorColor: Colors.white,
                    style: TextStyle(color: Colors.white),
                    inputFormatters: [AppInputFormatters.latinAndNumbersOnly],
                    obscureText: !showPassword,
                    validator: (value) =>
                        InputValidators.validatePassword(context, value),
                    decoration: _inputDecoration(
                      context,
                      context.tr('auth.password'),
                      Icons.lock_outline,
                    ).copyWith(
                      suffixIcon: IconButton(
                        onPressed: onTogglePassword,
                        icon: Icon(
                          showPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: onForgotPassword,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white.withOpacity(0.9),
                    ),
                    child: Text(context.tr('auth.forgotPassword')),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onLogin,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      backgroundColor: Colors.white,
                    ),
                    child: Text(
                      context.tr('auth.login'),
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedFieldWrapper extends StatelessWidget {
  final FocusNode focusNode;
  final Widget child;

  const _AnimatedFieldWrapper({
    required this.focusNode,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: focusNode,
      builder: (context, _) {
        final focused = focusNode.hasFocus;
        return AnimatedScale(
          scale: focused ? 1.02 : 1,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          child: child,
        );
      },
    );
  }
}

class _DemoCredentialsCard extends StatelessWidget {
  final List<AppAccount> accounts;
  final ValueChanged<AppAccount> onPick;

  const _DemoCredentialsCard({
    required this.accounts,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    if (accounts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('auth.demoAccounts'),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          ...accounts.map(
            (account) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => onPick(account),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: Text(
                          account.user.fullName.isNotEmpty
                              ? account.user.fullName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              account.user.fullName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              account.user.email ?? '',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RegisterFooter extends StatelessWidget {
  final VoidCallback onRegister;

  const _RegisterFooter({required this.onRegister});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 4,
        children: [
          Text(
            context.tr('auth.noAccount'),
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          GestureDetector(
            onTap: onRegister,
            child: Text(
              context.tr('auth.register'),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


