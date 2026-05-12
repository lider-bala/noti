import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../models/school_models.dart';
import '../../models/user_role.dart';
import '../../widgets/admin_panel.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/app_select_field.dart';
import '../../widgets/app_theme.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController(text: 'school123');
  final _parentFullNameController = TextEditingController();
  final _parentEmailController = TextEditingController();
  final _parentPhoneController = TextEditingController();
  final _parentPasswordController = TextEditingController(text: 'parent123');

  UserRole _selectedRole = UserRole.teacher;
  String? _selectedClassId;
  String? _selectedLinkedStudentId;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _parentFullNameController.dispose();
    _parentEmailController.dispose();
    _parentPhoneController.dispose();
    _parentPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitCreateAccount() async {
    final appState = context.appState;
    final classId =
        _selectedRole == UserRole.student || _selectedRole == UserRole.parent
            ? _selectedClassId
            : null;

    final creatingStudent = _selectedRole == UserRole.student;
    final creatingParent = _selectedRole == UserRole.parent;

    if (_fullNameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty ||
        (creatingStudent && classId == null) ||
        (creatingParent &&
            (classId == null || _selectedLinkedStudentId == null)) ||
        (creatingStudent &&
            (_parentFullNameController.text.trim().isEmpty ||
                _parentEmailController.text.trim().isEmpty ||
                _parentPhoneController.text.trim().isEmpty ||
                _parentPasswordController.text.trim().isEmpty))) {
      showAppSnackBar(
        context,
        context.tr('Заполните все обязательные поля.'),
        backgroundColor: const Color(0xFFB91C1C),
      );
      return;
    }

    final AppResult<List<AppAccount>> createdResult;
    if (creatingStudent) {
      createdResult = await appState.adminCreateStudentWithParent(
        studentFullName: _fullNameController.text,
        studentEmail: _emailController.text,
        studentPhone: _phoneController.text,
        studentPassword: _passwordController.text,
        classId: classId!,
        parentFullName: _parentFullNameController.text,
        parentEmail: _parentEmailController.text,
        parentPhone: _parentPhoneController.text,
        parentPassword: _parentPasswordController.text,
      );
    } else {
      final accountResult = await appState.adminCreateAccount(
        fullName: _fullNameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        password: _passwordController.text,
        role: _selectedRole,
        schoolClass: classId,
        linkedStudentId: creatingParent ? _selectedLinkedStudentId : null,
        linkedStudentIds: creatingParent && _selectedLinkedStudentId != null
            ? [_selectedLinkedStudentId!]
            : null,
      );
      createdResult = accountResult.isSuccess && accountResult.data != null
          ? AppResult.success([accountResult.data!])
          : AppResult.failure(accountResult.errorKey);
    }

    if (!mounted) {
      return;
    }
    if (!createdResult.isSuccess || (createdResult.data ?? []).isEmpty) {
      showAppSnackBar(
        context,
        context.tr('Аккаунт с таким email или телефоном уже существует.'),
        backgroundColor: const Color(0xFFB91C1C),
      );
      return;
    }

    _fullNameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _passwordController.text = 'school123';
    _parentFullNameController.clear();
    _parentEmailController.clear();
    _parentPhoneController.clear();
    _parentPasswordController.text = 'parent123';
    setState(() {
      _selectedClassId = null;
      _selectedLinkedStudentId = null;
    });

    showAppSnackBar(
      context,
      context.tr(
        creatingStudent
            ? 'Созданы аккаунты ученика и родителя.'
            : 'Аккаунт создан и уже доступен для входа.',
      ),
      backgroundColor: const Color(0xFF047857),
    );
  }

  Future<void> _approveRequest(String requestId) async {
    final result = await context.appState.approveRegistrationRequest(requestId);
    final success = result.isSuccess;
    if (!mounted) {
      return;
    }
    showAppSnackBar(
      context,
      context.tr(
        success
            ? 'Заявка одобрена. Пользователь может войти в систему.'
            : 'Не удалось обработать заявку.',
      ),
      backgroundColor:
          success ? const Color(0xFF047857) : const Color(0xFFB91C1C),
    );
  }

  Future<void> _rejectRequest(String requestId) async {
    final result = await context.appState.rejectRegistrationRequest(
      requestId,
      note: 'Нужно уточнить данные профиля',
    );
    final success = result.isSuccess;
    if (!mounted) {
      return;
    }
    showAppSnackBar(
      context,
      context.tr(
        success
            ? 'Заявка отклонена и отправлена на доработку.'
            : 'Не удалось обработать заявку.',
      ),
      backgroundColor:
          success ? const Color(0xFF92400E) : const Color(0xFFB91C1C),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.appState;
    final accounts = appState.accounts;
    final classes = appState.schoolClasses;
    final pendingRequests = appState.registrationRequests
        .where((item) => item.status == RegistrationStatus.pending)
        .toList();

    final createdToday = accounts.where(_createdToday).length;
    final teachers = _accountsByRole(accounts, UserRole.teacher);
    final students = _accountsByRole(accounts, UserRole.student);
    final parents = _accountsByRole(accounts, UserRole.parent);
    final admins = _accountsByRole(accounts, UserRole.admin);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(
          title: context.tr('Пользователи'),
          subtitle: context.tr(
            'Создание аккаунтов, заявки и списки по ролям разделены на отдельные панели.',
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _MetricTile(
              label: context.tr('Всего аккаунтов'),
              value: '${accounts.length}',
              icon: Icons.groups_rounded,
              color: const Color(0xFF0F766E),
            ),
            _MetricTile(
              label: context.tr('Заявки'),
              value: '${pendingRequests.length}',
              icon: Icons.mark_email_unread_rounded,
              color: const Color(0xFF2563EB),
            ),
            _MetricTile(
              label: context.tr('Создано сегодня'),
              value: '$createdToday',
              icon: Icons.today_rounded,
              color: const Color(0xFF7C3AED),
            ),
            _MetricTile(
              label: context.tr('Ученики'),
              value: '${students.length}',
              icon: Icons.school_rounded,
              color: const Color(0xFFD97706),
            ),
          ],
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 1100;
            final createPanel = _CreateAccountPanel(
              fullNameController: _fullNameController,
              emailController: _emailController,
              phoneController: _phoneController,
              passwordController: _passwordController,
              parentFullNameController: _parentFullNameController,
              parentEmailController: _parentEmailController,
              parentPhoneController: _parentPhoneController,
              parentPasswordController: _parentPasswordController,
              selectedRole: _selectedRole,
              selectedClassId: _selectedClassId,
              selectedLinkedStudentId: _selectedLinkedStudentId,
              classes: classes,
              studentsForSelectedClass: _selectedClassId == null
                  ? const []
                  : appState.studentsForClass(_selectedClassId!),
              onRoleChanged: (value) {
                setState(() {
                  _selectedRole = value;
                  if (value != UserRole.student && value != UserRole.parent) {
                    _selectedClassId = null;
                  }
                  _selectedLinkedStudentId = null;
                });
              },
              onClassChanged: (value) {
                setState(() {
                  _selectedClassId = value;
                  _selectedLinkedStudentId = null;
                });
              },
              onLinkedStudentChanged: (value) =>
                  setState(() => _selectedLinkedStudentId = value),
              onSubmit: _submitCreateAccount,
            );
            final requestsPanel = _RequestsPanel(
              requests: pendingRequests,
              onApprove: _approveRequest,
              onReject: _rejectRequest,
            );

            if (stacked) {
              return Column(
                children: [
                  createPanel,
                  const SizedBox(height: 12),
                  requestsPanel,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: createPanel),
                const SizedBox(width: 12),
                Expanded(child: requestsPanel),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final twoColumns = constraints.maxWidth >= 980;
            final panels = [
              _RoleListPanel(
                title: context.tr('Список учеников'),
                icon: Icons.school_rounded,
                accounts: students,
                emptyTitle: context.tr('Ученики пока не добавлены'),
              ),
              _RoleListPanel(
                title: context.tr('Список учителей'),
                icon: Icons.person_outline_rounded,
                accounts: teachers,
                emptyTitle: context.tr('Учителя пока не добавлены'),
              ),
              _RoleListPanel(
                title: context.tr('Список родителей'),
                icon: Icons.family_restroom_rounded,
                accounts: parents,
                emptyTitle: context.tr('Родители пока не добавлены'),
              ),
              _RoleListPanel(
                title: context.tr('Администраторы'),
                icon: Icons.admin_panel_settings_rounded,
                accounts: admins,
                emptyTitle: context.tr('Администраторы пока не добавлены'),
              ),
            ];

            if (!twoColumns) {
              return Column(
                children: [
                  for (var i = 0; i < panels.length; i++) ...[
                    if (i != 0) const SizedBox(height: 12),
                    panels[i],
                  ],
                ],
              );
            }

            return Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: panels[0]),
                    const SizedBox(width: 12),
                    Expanded(child: panels[1]),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: panels[2]),
                    const SizedBox(width: 12),
                    Expanded(child: panels[3]),
                  ],
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        _AllAccountsPanel(accounts: accounts),
      ],
    );
  }

  static List<AppAccount> _accountsByRole(
    List<AppAccount> accounts,
    UserRole role,
  ) {
    return accounts.where((account) => account.user.role == role).toList()
      ..sort((a, b) => a.user.fullName.compareTo(b.user.fullName));
  }

  static bool _createdToday(AppAccount account) {
    final now = DateTime.now();
    return account.createdAt.year == now.year &&
        account.createdAt.month == now.month &&
        account.createdAt.day == now.day;
  }
}

class _Header extends StatelessWidget {
  final String title;
  final String subtitle;

  const _Header({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 210,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: context.panelColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.appBorderColor),
          boxShadow: const [
            BoxShadow(
              blurRadius: 18,
              offset: Offset(0, 10),
              color: Color(0x10000000),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      color: context.primaryTextColor,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      color: context.secondaryTextColor,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateAccountPanel extends StatelessWidget {
  final TextEditingController fullNameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final TextEditingController parentFullNameController;
  final TextEditingController parentEmailController;
  final TextEditingController parentPhoneController;
  final TextEditingController parentPasswordController;
  final UserRole selectedRole;
  final String? selectedClassId;
  final String? selectedLinkedStudentId;
  final List<SchoolClass> classes;
  final List<AppUser> studentsForSelectedClass;
  final ValueChanged<UserRole> onRoleChanged;
  final ValueChanged<String?> onClassChanged;
  final ValueChanged<String?> onLinkedStudentChanged;
  final VoidCallback onSubmit;

  const _CreateAccountPanel({
    required this.fullNameController,
    required this.emailController,
    required this.phoneController,
    required this.passwordController,
    required this.parentFullNameController,
    required this.parentEmailController,
    required this.parentPhoneController,
    required this.parentPasswordController,
    required this.selectedRole,
    required this.selectedClassId,
    required this.selectedLinkedStudentId,
    required this.classes,
    required this.studentsForSelectedClass,
    required this.onRoleChanged,
    required this.onClassChanged,
    required this.onLinkedStudentChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return AdminPanel(
      title: context.tr('Создать аккаунт'),
      icon: Icons.person_add_alt_1_rounded,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: UserRole.values.map((role) {
            final selected = selectedRole == role;
            return ChoiceChip(
              label: Text(context.strings.role(role)),
              selected: selected,
              onSelected: (_) => onRoleChanged(role),
              selectedColor: const Color(0xFF0F766E),
              backgroundColor: context.panelMutedColor,
              side: BorderSide.none,
              labelStyle: TextStyle(
                color: selected ? Colors.white : context.primaryTextColor,
                fontWeight: FontWeight.w700,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        _Field(
          controller: fullNameController,
          label: context.tr('Полное имя'),
          icon: Icons.person_rounded,
        ),
        const SizedBox(height: 12),
        _Field(
          controller: emailController,
          label: context.tr('Email'),
          icon: Icons.email_rounded,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        _Field(
          controller: phoneController,
          label: context.tr('Телефон'),
          icon: Icons.phone_rounded,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 12),
        _Field(
          controller: passwordController,
          label: context.tr('Временный пароль'),
          icon: Icons.lock_rounded,
        ),
        if (selectedRole == UserRole.student ||
            selectedRole == UserRole.parent) ...[
          const SizedBox(height: 12),
          AppSelectField<String>(
            value: selectedClassId,
            label: context.tr(
              selectedRole == UserRole.parent
                  ? 'Класс ученика'
                  : 'Класс ученика',
            ),
            icon: Icons.meeting_room_rounded,
            options: classes
                .map(
                  (item) => AppSelectOption<String>(
                    value: item.id,
                    label: item.name,
                  ),
                )
                .toList(),
            onChanged: onClassChanged,
          ),
        ],
        if (selectedRole == UserRole.parent) ...[
          const SizedBox(height: 12),
          AppSelectField<String>(
            value: studentsForSelectedClass
                    .any((student) => student.id == selectedLinkedStudentId)
                ? selectedLinkedStudentId
                : null,
            label: context.tr('Ученик'),
            icon: Icons.school_rounded,
            options: studentsForSelectedClass
                .map(
                  (student) => AppSelectOption<String>(
                    value: student.id,
                    label: [
                      student.fullName,
                      if ((student.email ?? '').isNotEmpty) student.email!,
                    ].join(' • '),
                  ),
                )
                .toList(),
            enabled: studentsForSelectedClass.isNotEmpty,
            onChanged: onLinkedStudentChanged,
          ),
          if (selectedClassId != null && studentsForSelectedClass.isEmpty) ...[
            const SizedBox(height: 8),
            Text(
              context.tr('В выбранном классе пока нет учеников.'),
              style: const TextStyle(
                color: Color(0xFFB91C1C),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
        if (selectedRole == UserRole.student) ...[
          const SizedBox(height: 16),
          _SectionLabel(text: context.tr('Данные родителя')),
          const SizedBox(height: 12),
          _Field(
            controller: parentFullNameController,
            label: context.tr('ФИО родителя'),
            icon: Icons.family_restroom_rounded,
          ),
          const SizedBox(height: 12),
          _Field(
            controller: parentEmailController,
            label: context.tr('Email родителя'),
            icon: Icons.email_rounded,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          _Field(
            controller: parentPhoneController,
            label: context.tr('Телефон родителя'),
            icon: Icons.phone_rounded,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          _Field(
            controller: parentPasswordController,
            label: context.tr('Пароль родителя'),
            icon: Icons.lock_rounded,
          ),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onSubmit,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0F766E),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.check_rounded),
            label: Text(context.tr('Создать аккаунт')),
          ),
        ),
      ],
    );
  }
}

class _RequestsPanel extends StatelessWidget {
  final List<RegistrationRequest> requests;
  final ValueChanged<String> onApprove;
  final ValueChanged<String> onReject;

  const _RequestsPanel({
    required this.requests,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return _SearchablePanel<RegistrationRequest>(
      title: context.tr('Заявки на доступ'),
      icon: Icons.mark_email_unread_rounded,
      items: requests,
      emptyIcon: Icons.check_circle_outline_rounded,
      emptyTitle: context.tr('Новых заявок нет'),
      noResultsTitle: context.tr('Заявки по запросу не найдены'),
      matches: (request, query) => _requestSearchText(context, request)
          .toLowerCase()
          .contains(query.toLowerCase()),
      itemBuilder: (context, request, index) => _RequestRow(
        request: request,
        onApprove: () => onApprove(request.id),
        onReject: () => onReject(request.id),
      ),
    );
  }
}

class _SearchablePanel<T> extends StatefulWidget {
  final String title;
  final IconData icon;
  final List<T> items;
  final IconData emptyIcon;
  final String emptyTitle;
  final String noResultsTitle;
  final bool Function(T item, String query) matches;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;

  const _SearchablePanel({
    required this.title,
    required this.icon,
    required this.items,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.noResultsTitle,
    required this.matches,
    required this.itemBuilder,
  });

  @override
  State<_SearchablePanel<T>> createState() => _SearchablePanelState<T>();
}

class _SearchablePanelState<T> extends State<_SearchablePanel<T>> {
  final _searchController = TextEditingController();
  bool _searchOpen = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim();
    final filtered = query.isEmpty
        ? widget.items
        : widget.items.where((item) => widget.matches(item, query)).toList();

    return AdminPanel(
      title: '${widget.title} (${filtered.length})',
      icon: widget.icon,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            tooltip: context.tr('Поиск'),
            onPressed: () {
              setState(() {
                _searchOpen = !_searchOpen;
                if (!_searchOpen) {
                  _searchController.clear();
                }
              });
            },
            icon:
                Icon(_searchOpen ? Icons.close_rounded : Icons.search_rounded),
          ),
        ),
        if (_searchOpen) ...[
          TextField(
            controller: _searchController,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            decoration: _inputDecoration(
              context,
              context.tr('Поиск...'),
              Icons.search_rounded,
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (widget.items.isEmpty)
          _EmptyState(icon: widget.emptyIcon, title: widget.emptyTitle)
        else if (filtered.isEmpty)
          _EmptyState(
              icon: Icons.search_off_rounded, title: widget.noResultsTitle)
        else
          Column(
            children: [
              for (var i = 0; i < filtered.length; i++) ...[
                if (i != 0) Divider(height: 24, color: context.appBorderColor),
                widget.itemBuilder(context, filtered[i], i),
              ],
            ],
          ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: context.appBorderColor)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF0F766E),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(child: Divider(color: context.appBorderColor)),
      ],
    );
  }
}

class _RequestRow extends StatelessWidget {
  final RegistrationRequest request;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _RequestRow({
    required this.request,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFFEFF6FF),
              foregroundColor: const Color(0xFF1D4ED8),
              child: Text(_safeInitials(request.fullName)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.fullName,
                    style: TextStyle(
                      color: context.primaryTextColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _requestSubtitle(context, request),
                    style: TextStyle(
                      color: context.secondaryTextColor,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: onApprove,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.check_rounded, size: 18),
              label: Text(context.tr('Одобрить')),
            ),
            OutlinedButton.icon(
              onPressed: onReject,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFB91C1C),
                side: const BorderSide(color: Color(0xFFFCA5A5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.close_rounded, size: 18),
              label: Text(context.tr('Отклонить')),
            ),
          ],
        ),
      ],
    );
  }

  String _requestSubtitle(BuildContext context, RegistrationRequest request) {
    return [
      context.strings.role(request.role),
      if ((request.schoolClass ?? '').isNotEmpty) request.schoolClass!,
      request.email,
      request.phone,
    ].join(' • ');
  }
}

class _RoleListPanel extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<AppAccount> accounts;
  final String emptyTitle;

  const _RoleListPanel({
    required this.title,
    required this.icon,
    required this.accounts,
    required this.emptyTitle,
  });

  @override
  Widget build(BuildContext context) {
    return _SearchablePanel<AppAccount>(
      title: title,
      icon: icon,
      items: accounts,
      emptyIcon: Icons.people_outline_rounded,
      emptyTitle: emptyTitle,
      noResultsTitle: context.tr('Пользователи по запросу не найдены'),
      matches: (account, query) => _accountSearchText(context, account)
          .toLowerCase()
          .contains(query.toLowerCase()),
      itemBuilder: (context, account, index) =>
          _UserRow(account: account, showRole: false),
    );
  }
}

class _AllAccountsPanel extends StatelessWidget {
  final List<AppAccount> accounts;

  const _AllAccountsPanel({required this.accounts});

  @override
  Widget build(BuildContext context) {
    return _SearchablePanel<AppAccount>(
      title: context.tr('Все пользователи'),
      icon: Icons.badge_rounded,
      items: accounts,
      emptyIcon: Icons.people_outline_rounded,
      emptyTitle: context.tr('Пользователей пока нет'),
      noResultsTitle: context.tr('Пользователи по запросу не найдены'),
      matches: (account, query) => _accountSearchText(context, account)
          .toLowerCase()
          .contains(query.toLowerCase()),
      itemBuilder: (context, account, index) =>
          _UserRow(account: account, showRole: true),
    );
  }
}

class _UserRow extends StatelessWidget {
  final AppAccount account;
  final bool showRole;

  const _UserRow({
    required this.account,
    required this.showRole,
  });

  @override
  Widget build(BuildContext context) {
    final user = account.user;
    final roleColor = _roleColor(user.role);

    return Row(
      children: [
        CircleAvatar(
          backgroundColor: roleColor.withOpacity(0.1),
          foregroundColor: roleColor,
          child: Text(user.initials),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.fullName,
                style: TextStyle(
                  color: context.primaryTextColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _userSubtitle(context, user),
                style: TextStyle(
                  color: context.secondaryTextColor,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        if (showRole)
          _RoleBadge(
            label: context.strings.role(user.role),
            color: roleColor,
          )
        else
          Text(
            MaterialLocalizations.of(context)
                .formatShortDate(account.createdAt),
            style: TextStyle(
              color: context.secondaryTextColor.withOpacity(0.82),
              fontSize: 12,
            ),
          ),
        IconButton(
          tooltip: context.tr('Редактировать'),
          onPressed: () => _openEditDialog(context, account),
          icon: const Icon(Icons.edit_rounded, size: 18),
        ),
      ],
    );
  }

  String _userSubtitle(BuildContext context, AppUser user) {
    return [
      if ((user.schoolClass ?? '').isNotEmpty) user.schoolClass!,
      user.email ?? '',
      user.phone ?? '',
    ].where((value) => value.isNotEmpty).join(' • ');
  }

  void _openEditDialog(BuildContext context, AppAccount account) {
    final appState = context.appState;
    final user = account.user;
    final fullNameController = TextEditingController(text: user.fullName);
    final emailController = TextEditingController(text: user.email ?? '');
    final phoneController = TextEditingController(text: user.phone ?? '');
    var selectedClassId = user.schoolClass;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(context.tr('Редактировать пользователя')),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Field(
                      controller: fullNameController,
                      label: context.tr('Полное имя'),
                      icon: Icons.person_rounded,
                    ),
                    const SizedBox(height: 12),
                    _Field(
                      controller: emailController,
                      label: context.tr('Email'),
                      icon: Icons.email_rounded,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    _Field(
                      controller: phoneController,
                      label: context.tr('Телефон'),
                      icon: Icons.phone_rounded,
                      keyboardType: TextInputType.phone,
                    ),
                    if (user.role == UserRole.student ||
                        user.role == UserRole.parent) ...[
                      const SizedBox(height: 12),
                      AppSelectField<String>(
                        value: appState.schoolClasses
                                .any((item) => item.id == selectedClassId)
                            ? selectedClassId
                            : null,
                        label: context.tr('Класс'),
                        icon: Icons.meeting_room_rounded,
                        options: appState.schoolClasses
                            .map(
                              (item) => AppSelectOption<String>(
                                value: item.id,
                                label: item.name,
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setDialogState(() => selectedClassId = value);
                        },
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(context.tr('Отмена')),
                ),
                FilledButton(
                  onPressed: () async {
                    final result = await appState.adminUpdateAccount(
                      userId: user.id,
                      fullName: fullNameController.text,
                      email: emailController.text,
                      phone: phoneController.text,
                      schoolClass: selectedClassId,
                    );
                    if (!context.mounted || !dialogContext.mounted) {
                      return;
                    }
                    final success = result.isSuccess;
                    if (!success) {
                      showAppSnackBar(
                        context,
                        context.tr('Не удалось сохранить изменения.'),
                        backgroundColor: const Color(0xFFB91C1C),
                      );
                      return;
                    }
                    Navigator.of(dialogContext).pop();
                    showAppSnackBar(
                      context,
                      context.tr('Данные пользователя сохранены.'),
                      backgroundColor: const Color(0xFF047857),
                    );
                  },
                  child: Text(context.tr('Сохранить')),
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(() {
      fullNameController.dispose();
      emailController.dispose();
      phoneController.dispose();
    });
  }
}

class _RoleBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _RoleBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;

  const _EmptyState({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.panelMutedColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.appBorderColor),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF94A3B8), size: 28),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.primaryTextColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType keyboardType;

  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: context.primaryTextColor),
      cursorColor: const Color(0xFF0F766E),
      decoration: _inputDecoration(context, label, icon),
    );
  }
}

InputDecoration _inputDecoration(
    BuildContext context, String label, IconData icon) {
  return InputDecoration(
    labelText: label,
    labelStyle: TextStyle(color: context.secondaryTextColor),
    prefixIcon: Icon(icon, color: context.secondaryTextColor, size: 20),
    filled: true,
    fillColor: context.panelMutedColor,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: context.appBorderColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: context.appBorderColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(
        color: Color(0xFF0F766E),
        width: 1.4,
      ),
    ),
  );
}

String _safeInitials(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return 'NA';
  }
  final parts = trimmed.split(RegExp(r'\s+'));
  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }
  return '${parts[0].substring(0, 1)}${parts[1].substring(0, 1)}'.toUpperCase();
}

String _requestSearchText(BuildContext context, RegistrationRequest request) {
  return [
    request.fullName,
    request.email,
    request.phone,
    context.strings.role(request.role),
    request.schoolClass ?? '',
  ].join(' ');
}

String _accountSearchText(BuildContext context, AppAccount account) {
  final user = account.user;
  return [
    user.fullName,
    user.email ?? '',
    user.phone ?? '',
    user.schoolClass ?? '',
    context.strings.role(user.role),
    user.status.name,
  ].join(' ');
}

Color _roleColor(UserRole role) {
  switch (role) {
    case UserRole.teacher:
      return const Color(0xFF0F766E);
    case UserRole.student:
      return const Color(0xFF2563EB);
    case UserRole.parent:
      return const Color(0xFFD97706);
    case UserRole.admin:
      return const Color(0xFF7C3AED);
  }
}
