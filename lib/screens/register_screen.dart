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

class RegisterScreen extends StatefulWidget {
  final ValueChanged<AppUser> onRegistered;
  final VoidCallback onLoginTap;

  const RegisterScreen({
    super.key,
    required this.onRegistered,
    required this.onLoginTap,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _parentFullName = TextEditingController();
  final _parentEmail = TextEditingController();
  final _parentPhone = TextEditingController();
  final _parentPassword = TextEditingController();

  late final FocusNode _fullNameNode;
  late final FocusNode _emailNode;
  late final FocusNode _phoneNode;
  late final FocusNode _passwordNode;
  late final FocusNode _confirmPasswordNode;
  late final FocusNode _classNode;
  late final FocusNode _parentFullNameNode;
  late final FocusNode _parentEmailNode;
  late final FocusNode _parentPhoneNode;
  late final FocusNode _parentPasswordNode;
  late final AnimationController _backgroundController;

  UserRole _selectedRole = UserRole.teacher;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _showParentPassword = false;
  String? _selectedClass;

  late final List<String> _classes;

  @override
  void initState() {
    super.initState();
    _fullNameNode = FocusNode();
    _emailNode = FocusNode();
    _phoneNode = FocusNode();
    _passwordNode = FocusNode();
    _confirmPasswordNode = FocusNode();
    _classNode = FocusNode();
    _parentFullNameNode = FocusNode();
    _parentEmailNode = FocusNode();
    _parentPhoneNode = FocusNode();
    _parentPasswordNode = FocusNode();
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();

    const letters = ['А', 'Б'];
    _classes = [
      for (var grade = 1; grade <= 11; grade++)
        for (final letter in letters) '$grade$letter',
    ];
  }

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _parentFullName.dispose();
    _parentEmail.dispose();
    _parentPhone.dispose();
    _parentPassword.dispose();
    _fullNameNode.dispose();
    _emailNode.dispose();
    _phoneNode.dispose();
    _passwordNode.dispose();
    _confirmPasswordNode.dispose();
    _classNode.dispose();
    _parentFullNameNode.dispose();
    _parentEmailNode.dispose();
    _parentPhoneNode.dispose();
    _parentPasswordNode.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final result = await context.appState.registerUser(
      fullName: _fullName.text,
      email: _email.text,
      phone: _phone.text,
      password: _password.text,
      role: _selectedRole,
      schoolClass: _selectedRole == UserRole.student ? _selectedClass : null,
      parentFullName:
          _selectedRole == UserRole.student ? _parentFullName.text : null,
      parentEmail: _selectedRole == UserRole.student ? _parentEmail.text : null,
      parentPhone: _selectedRole == UserRole.student ? _parentPhone.text : null,
      parentPassword:
          _selectedRole == UserRole.student ? _parentPassword.text : null,
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

    showAppSnackBar(
      context,
      context.tr(
        result.isPendingApproval
            ? 'Заявка отправлена администратору. Вход станет доступен после подтверждения.'
            : 'auth.accountCreated',
      ),
      backgroundColor: const Color(0xFF047857),
    );
    if (result.user != null) {
      widget.onRegistered(result.user!);
      return;
    }
    widget.onLoginTap();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkTheme;
    final availableClasses = context.appState.schoolClasses
        .map((schoolClass) => schoolClass.id)
        .toList();
    final classOptions = availableClasses.isEmpty ? _classes : availableClasses;
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
                      const SizedBox(height: 20),
                      _RoleSelector(
                        current: _selectedRole,
                        onChanged: (role) {
                          setState(() {
                            _selectedRole = role;
                            if (_selectedRole != UserRole.student) {
                              _selectedClass = null;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 14),
                      _GlassRegisterCard(
                        formKey: _formKey,
                        fullName: _fullName,
                        email: _email,
                        phone: _phone,
                        password: _password,
                        confirmPassword: _confirmPassword,
                        parentFullName: _parentFullName,
                        parentEmail: _parentEmail,
                        parentPhone: _parentPhone,
                        parentPassword: _parentPassword,
                        fullNameNode: _fullNameNode,
                        emailNode: _emailNode,
                        phoneNode: _phoneNode,
                        passwordNode: _passwordNode,
                        confirmPasswordNode: _confirmPasswordNode,
                        classNode: _classNode,
                        parentFullNameNode: _parentFullNameNode,
                        parentEmailNode: _parentEmailNode,
                        parentPhoneNode: _parentPhoneNode,
                        parentPasswordNode: _parentPasswordNode,
                        classes: classOptions,
                        selectedClass: _selectedClass,
                        isStudent: _selectedRole == UserRole.student,
                        showPassword: _showPassword,
                        showConfirmPassword: _showConfirmPassword,
                        showParentPassword: _showParentPassword,
                        onClassChanged: (value) {
                          setState(() => _selectedClass = value);
                        },
                        onTogglePassword: () {
                          setState(() => _showPassword = !_showPassword);
                        },
                        onToggleConfirmPassword: () {
                          setState(
                            () => _showConfirmPassword = !_showConfirmPassword,
                          );
                        },
                        onToggleParentPassword: () {
                          setState(
                            () => _showParentPassword = !_showParentPassword,
                          );
                        },
                        onSubmit: _submit,
                      ),
                      const SizedBox(height: 18),
                      _LoginFooter(onLoginTap: widget.onLoginTap),
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
          context.tr('auth.createAccount'),
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

class _GlassRegisterCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController fullName;
  final TextEditingController email;
  final TextEditingController phone;
  final TextEditingController password;
  final TextEditingController confirmPassword;
  final TextEditingController parentFullName;
  final TextEditingController parentEmail;
  final TextEditingController parentPhone;
  final TextEditingController parentPassword;
  final FocusNode fullNameNode;
  final FocusNode emailNode;
  final FocusNode phoneNode;
  final FocusNode passwordNode;
  final FocusNode confirmPasswordNode;
  final FocusNode classNode;
  final FocusNode parentFullNameNode;
  final FocusNode parentEmailNode;
  final FocusNode parentPhoneNode;
  final FocusNode parentPasswordNode;
  final List<String> classes;
  final String? selectedClass;
  final bool isStudent;
  final bool showPassword;
  final bool showConfirmPassword;
  final bool showParentPassword;
  final ValueChanged<String?> onClassChanged;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmPassword;
  final VoidCallback onToggleParentPassword;
  final VoidCallback onSubmit;

  const _GlassRegisterCard({
    required this.formKey,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.password,
    required this.confirmPassword,
    required this.parentFullName,
    required this.parentEmail,
    required this.parentPhone,
    required this.parentPassword,
    required this.fullNameNode,
    required this.emailNode,
    required this.phoneNode,
    required this.passwordNode,
    required this.confirmPasswordNode,
    required this.classNode,
    required this.parentFullNameNode,
    required this.parentEmailNode,
    required this.parentPhoneNode,
    required this.parentPasswordNode,
    required this.classes,
    required this.selectedClass,
    required this.isStudent,
    required this.showPassword,
    required this.showConfirmPassword,
    required this.showParentPassword,
    required this.onClassChanged,
    required this.onTogglePassword,
    required this.onToggleConfirmPassword,
    required this.onToggleParentPassword,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    InputDecoration inputDecoration(String label, IconData icon) {
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
              children: [
                _AnimatedFieldWrapper(
                  focusNode: fullNameNode,
                  child: TextFormField(
                    controller: fullName,
                    focusNode: fullNameNode,
                    style: TextStyle(color: Colors.white),
                    validator: (value) =>
                        InputValidators.validateFullName(context, value),
                    decoration: inputDecoration(
                      context.tr('auth.fullName'),
                      Icons.person_outline,
                    ).copyWith(
                      hintText: context.tr('auth.nameHint'),
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.55),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _AnimatedFieldWrapper(
                  focusNode: emailNode,
                  child: TextFormField(
                    controller: email,
                    focusNode: emailNode,
                    style: TextStyle(color: Colors.white),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) =>
                        InputValidators.validateRequiredEmail(context, value),
                    decoration: inputDecoration(
                      context.tr('auth.email'),
                      Icons.mail_outline,
                    ).copyWith(
                      hintText: context.tr('auth.emailHint'),
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.55),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _AnimatedFieldWrapper(
                  focusNode: phoneNode,
                  child: TextFormField(
                    controller: phone,
                    focusNode: phoneNode,
                    style: TextStyle(color: Colors.white),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [AppInputFormatters.phoneDigitsOnly],
                    validator: (value) =>
                        InputValidators.validatePhone(context, value),
                    decoration: inputDecoration(
                      context.tr('auth.phone'),
                      Icons.phone_outlined,
                    ).copyWith(
                      hintText: context.tr('auth.phoneHint'),
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.55),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (isStudent) ...[
                  _AnimatedFieldWrapper(
                    focusNode: classNode,
                    child: FormField<String>(
                      initialValue: selectedClass,
                      validator: (value) {
                        if (!isStudent) return null;
                        if (selectedClass == null || selectedClass!.isEmpty) {
                          return context.tr('auth.classHint');
                        }
                        return null;
                      },
                      builder: (field) {
                        return _GlassSelectField(
                          label: context.tr('auth.class'),
                          value: selectedClass ?? context.tr('auth.classHint'),
                          hasValue: selectedClass != null,
                          errorText: field.errorText,
                          focusNode: classNode,
                          onTap: () async {
                            classNode.requestFocus();
                            final value = await _showClassPicker(
                              context,
                              classes: classes,
                              selectedClass: selectedClass,
                            );
                            if (value == null) return;
                            onClassChanged(value);
                            field.didChange(value);
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  _StudentParentFields(
                    parentFullName: parentFullName,
                    parentEmail: parentEmail,
                    parentPhone: parentPhone,
                    parentPassword: parentPassword,
                    parentFullNameNode: parentFullNameNode,
                    parentEmailNode: parentEmailNode,
                    parentPhoneNode: parentPhoneNode,
                    parentPasswordNode: parentPasswordNode,
                    showParentPassword: showParentPassword,
                    inputDecoration: inputDecoration,
                    onToggleParentPassword: onToggleParentPassword,
                  ),
                  const SizedBox(height: 12),
                ],
                _AnimatedFieldWrapper(
                  focusNode: passwordNode,
                  child: TextFormField(
                    controller: password,
                    focusNode: passwordNode,
                    style: TextStyle(color: Colors.white),
                    obscureText: !showPassword,
                    inputFormatters: [AppInputFormatters.latinAndNumbersOnly],
                    validator: (value) =>
                        InputValidators.validatePassword(context, value),
                    decoration: inputDecoration(
                      context.tr('auth.password'),
                      Icons.lock_outline,
                    ).copyWith(
                      hintText: '••••••••',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.55),
                      ),
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
                const SizedBox(height: 12),
                _AnimatedFieldWrapper(
                  focusNode: confirmPasswordNode,
                  child: TextFormField(
                    controller: confirmPassword,
                    focusNode: confirmPasswordNode,
                    style: const TextStyle(color: Colors.white),
                    obscureText: !showConfirmPassword,
                    inputFormatters: [AppInputFormatters.latinAndNumbersOnly],
                    validator: (value) =>
                        InputValidators.validatePasswordConfirmation(
                      context,
                      value,
                      password.text,
                    ),
                    decoration: inputDecoration(
                      context.tr('auth.confirmPassword'),
                      Icons.lock_outline,
                    ).copyWith(
                      hintText: '••••••••',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.55),
                      ),
                      suffixIcon: IconButton(
                        onPressed: onToggleConfirmPassword,
                        icon: Icon(
                          showConfirmPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2ECC71),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 8,
                    ),
                    child: Text(
                      context.tr('auth.register'),
                      style: const TextStyle(
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

class _StudentParentFields extends StatelessWidget {
  final TextEditingController parentFullName;
  final TextEditingController parentEmail;
  final TextEditingController parentPhone;
  final TextEditingController parentPassword;
  final FocusNode parentFullNameNode;
  final FocusNode parentEmailNode;
  final FocusNode parentPhoneNode;
  final FocusNode parentPasswordNode;
  final bool showParentPassword;
  final InputDecoration Function(String label, IconData icon) inputDecoration;
  final VoidCallback onToggleParentPassword;

  const _StudentParentFields({
    required this.parentFullName,
    required this.parentEmail,
    required this.parentPhone,
    required this.parentPassword,
    required this.parentFullNameNode,
    required this.parentEmailNode,
    required this.parentPhoneNode,
    required this.parentPasswordNode,
    required this.showParentPassword,
    required this.inputDecoration,
    required this.onToggleParentPassword,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: Colors.white.withOpacity(0.28))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                context.tr('Данные родителя'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            Expanded(child: Divider(color: Colors.white.withOpacity(0.28))),
          ],
        ),
        const SizedBox(height: 12),
        _AnimatedFieldWrapper(
          focusNode: parentFullNameNode,
          child: TextFormField(
            controller: parentFullName,
            focusNode: parentFullNameNode,
            style: TextStyle(color: Colors.white),
            validator: (value) =>
                InputValidators.validateFullName(context, value),
            decoration: inputDecoration(
              context.tr('ФИО родителя'),
              Icons.family_restroom_outlined,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _AnimatedFieldWrapper(
          focusNode: parentEmailNode,
          child: TextFormField(
            controller: parentEmail,
            focusNode: parentEmailNode,
            style: TextStyle(color: Colors.white),
            keyboardType: TextInputType.emailAddress,
            validator: (value) =>
                InputValidators.validateRequiredEmail(context, value),
            decoration: inputDecoration(
              context.tr('Email родителя'),
              Icons.mail_outline,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _AnimatedFieldWrapper(
          focusNode: parentPhoneNode,
          child: TextFormField(
            controller: parentPhone,
            focusNode: parentPhoneNode,
            style: TextStyle(color: Colors.white),
            keyboardType: TextInputType.phone,
            inputFormatters: [AppInputFormatters.phoneDigitsOnly],
            validator: (value) => InputValidators.validatePhone(context, value),
            decoration: inputDecoration(
              context.tr('Телефон родителя'),
              Icons.phone_outlined,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _AnimatedFieldWrapper(
          focusNode: parentPasswordNode,
          child: TextFormField(
            controller: parentPassword,
            focusNode: parentPasswordNode,
            style: TextStyle(color: Colors.white),
            obscureText: !showParentPassword,
            inputFormatters: [AppInputFormatters.latinAndNumbersOnly],
            validator: (value) =>
                InputValidators.validatePassword(context, value),
            decoration: inputDecoration(
              context.tr('Пароль родителя'),
              Icons.lock_outline,
            ).copyWith(
              suffixIcon: IconButton(
                onPressed: onToggleParentPassword,
                icon: Icon(
                  showParentPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.white70,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GlassSelectField extends StatelessWidget {
  final String label;
  final String value;
  final bool hasValue;
  final String? errorText;
  final FocusNode focusNode;
  final VoidCallback onTap;

  const _GlassSelectField({
    required this.label,
    required this.value,
    required this.hasValue,
    required this.errorText,
    required this.focusNode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = errorText == null
        ? Colors.white.withOpacity(0.3)
        : const Color(0xFFFECACA);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            focusNode: focusNode,
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Container(
              constraints: const BoxConstraints(minHeight: 58),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  const Icon(Icons.school_outlined, color: Colors.white70),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          value,
                          style: TextStyle(
                            color: hasValue
                                ? Colors.white
                                : Colors.white.withOpacity(0.75),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Colors.white70,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 14),
            child: Text(
              errorText!,
              style: const TextStyle(
                color: Color(0xFFFECACA),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

Future<String?> _showClassPicker(
  BuildContext context, {
  required List<String> classes,
  required String? selectedClass,
}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.18),
    isScrollControlled: true,
    builder: (sheetContext) {
      return SafeArea(
        minimum: const EdgeInsets.all(20),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420, maxHeight: 420),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.92),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withOpacity(0.7)),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 24,
                  offset: Offset(0, 14),
                  color: Color(0x33000000),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: classes.length,
                separatorBuilder: (_, __) => const Divider(
                  height: 1,
                  color: Color(0xFFE5E7EB),
                ),
                itemBuilder: (context, index) {
                  final item = classes[index];
                  final selected = item == selectedClass;
                  return Material(
                    color:
                        selected ? const Color(0xFFE5E7EB) : Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.of(sheetContext).pop(item),
                      child: SizedBox(
                        height: 56,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 22),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              item,
                              style: const TextStyle(
                                color: Color(0xFF1F2937),
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
    },
  );
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

class _LoginFooter extends StatelessWidget {
  final VoidCallback onLoginTap;

  const _LoginFooter({required this.onLoginTap});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: '${context.tr('auth.haveAccount')} ',
        style: TextStyle(
          color: Colors.white.withOpacity(0.85),
        ),
        children: [
          WidgetSpan(
            child: GestureDetector(
              onTap: onLoginTap,
              child: Text(
                context.tr('auth.login'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
