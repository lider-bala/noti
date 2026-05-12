import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../models/school_models.dart';
import '../../models/user_role.dart';
import '../../widgets/admin_panel.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/app_select_field.dart';
import '../../widgets/app_theme.dart';

class AdminAcademicsScreen extends StatefulWidget {
  const AdminAcademicsScreen({super.key});

  @override
  State<AdminAcademicsScreen> createState() => _AdminAcademicsScreenState();
}

class _AdminAcademicsScreenState extends State<AdminAcademicsScreen> {
  final _classController = TextEditingController();
  final _subjectController = TextEditingController();
  final _roomController = TextEditingController();
  final _scheduleSearchController = TextEditingController();
  final _teacherSearchController = TextEditingController();

  _AcademicsTab _tab = _AcademicsTab.classes;
  String? _selectedClassId;
  String? _selectedTeacherId;
  String? _selectedTimeRange;
  int _selectedWeekdayIndex = 0;

  @override
  void dispose() {
    _classController.dispose();
    _subjectController.dispose();
    _roomController.dispose();
    _scheduleSearchController.dispose();
    _teacherSearchController.dispose();
    super.dispose();
  }

  Future<void> _createClass() async {
    final result = await context.appState.createSchoolClass(
      _classController.text,
    );
    final success = result.isSuccess;
    if (!mounted) {
      return;
    }
    showAppSnackBar(
      context,
      context.tr(
        success
            ? 'Класс добавлен в структуру школы.'
            : _classErrorMessage(result.errorKey),
      ),
      backgroundColor:
          success ? const Color(0xFF047857) : const Color(0xFFB91C1C),
    );

    if (success) {
      _classController.clear();
    }
  }

  Future<void> _createLesson() async {
    final classId = _selectedClassId;
    final teacherId = _selectedTeacherId;
    final timeRange = _selectedTimeRange;

    if (classId == null ||
        teacherId == null ||
        timeRange == null ||
        _subjectController.text.trim().isEmpty ||
        _roomController.text.trim().isEmpty) {
      showAppSnackBar(
        context,
        context.tr('Заполните все обязательные поля.'),
        backgroundColor: const Color(0xFFB91C1C),
      );
      return;
    }

    final result = await context.appState.createLessonAssignment(
      classId: classId,
      teacherId: teacherId,
      subject: _subjectController.text,
      weekdayIndex: _selectedWeekdayIndex,
      timeRange: timeRange,
      room: _roomController.text,
    );
    final success = result.isSuccess;
    if (!mounted) {
      return;
    }

    showAppSnackBar(
      context,
      context.tr(success
          ? 'Урок добавлен в расписание.'
          : _lessonErrorMessage(result.errorKey)),
      backgroundColor:
          success ? const Color(0xFF047857) : const Color(0xFFB91C1C),
    );

    if (success) {
      _subjectController.clear();
      _roomController.clear();
      setState(() => _selectedTimeRange = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.appState;
    final classes = appState.schoolClasses;
    final teachers = appState.teachers;
    final lessons = appState.lessons;

    final classValue = classes.any((item) => item.id == _selectedClassId)
        ? _selectedClassId
        : null;
    final teacherValue = teachers.any((item) => item.id == _selectedTeacherId)
        ? _selectedTeacherId
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(
          title: context.tr('Академическая структура'),
          subtitle: context.tr(
            'Классы, добавление уроков, расписание и нагрузка учителей разделены по вкладкам.',
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth < 720 ? 2 : 4;
            const spacing = 12.0;
            final itemWidth =
                (constraints.maxWidth - spacing * (columns - 1)) / columns;
            final metrics = [
              _MetricTile(
                label: context.tr('Классы'),
                value: '${classes.length}',
                icon: Icons.meeting_room_rounded,
                color: const Color(0xFF0F766E),
              ),
              _MetricTile(
                label: context.tr('Уроки'),
                value: '${lessons.length}',
                icon: Icons.event_note_rounded,
                color: const Color(0xFF2563EB),
              ),
              _MetricTile(
                label: context.tr('Учителя'),
                value: '${teachers.length}',
                icon: Icons.person_outline_rounded,
                color: const Color(0xFF7C3AED),
              ),
              _MetricTile(
                label: context.tr('Ученики'),
                value: '${appState.students.length}',
                icon: Icons.school_rounded,
                color: const Color(0xFFD97706),
              ),
            ];

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final metric in metrics)
                  SizedBox(width: itemWidth, child: metric),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        _AcademicsTabs(
          current: _tab,
          onChanged: (value) => setState(() => _tab = value),
        ),
        const SizedBox(height: 16),
        _buildTabContent(
          classes: classes,
          teachers: teachers,
          lessons: lessons,
          classValue: classValue,
          teacherValue: teacherValue,
        ),
      ],
    );
  }

  Widget _buildTabContent({
    required List<SchoolClass> classes,
    required List<AppUser> teachers,
    required List<LessonAssignment> lessons,
    required String? classValue,
    required String? teacherValue,
  }) {
    final createClassPanel = _CreateClassPanel(
      controller: _classController,
      onCreate: _createClass,
    );
    final classesPanel = _ClassesListPanel(classes: classes);
    final lessonBuilder = _CreateLessonPanel(
      classValue: classValue,
      teacherValue: teacherValue,
      selectedTimeRange: _selectedTimeRange,
      selectedWeekdayIndex: _selectedWeekdayIndex,
      classes: classes,
      teachers: teachers,
      subjectController: _subjectController,
      roomController: _roomController,
      onClassChanged: (value) => setState(() => _selectedClassId = value),
      onTeacherChanged: (value) => setState(() => _selectedTeacherId = value),
      onWeekdayChanged: (value) {
        setState(() => _selectedWeekdayIndex = value ?? 0);
      },
      onTimeChanged: (value) => setState(() => _selectedTimeRange = value),
      onCreate: _createLesson,
    );

    switch (_tab) {
      case _AcademicsTab.classes:
        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 1000) {
              return Column(
                children: [
                  createClassPanel,
                  const SizedBox(height: 12),
                  classesPanel,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: createClassPanel),
                const SizedBox(width: 12),
                Expanded(child: classesPanel),
              ],
            );
          },
        );
      case _AcademicsTab.addLesson:
        return lessonBuilder;
      case _AcademicsTab.schedule:
        return _LessonsListPanel(
          lessons: lessons,
          searchController: _scheduleSearchController,
          onSearchChanged: () => setState(() {}),
        );
      case _AcademicsTab.teachers:
        return _TeachingLoadPanel(
          teachers: teachers,
          searchController: _teacherSearchController,
          onSearchChanged: () => setState(() {}),
        );
    }
  }
}

enum _AcademicsTab {
  classes,
  addLesson,
  schedule,
  teachers,
}

class _AcademicsTabs extends StatelessWidget {
  final _AcademicsTab current;
  final ValueChanged<_AcademicsTab> onChanged;

  const _AcademicsTabs({
    required this.current,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _AcademicsTabItem(
        value: _AcademicsTab.classes,
        label: context.tr('Классы'),
        icon: Icons.meeting_room_rounded,
      ),
      _AcademicsTabItem(
        value: _AcademicsTab.addLesson,
        label: context.tr('Добавить урок'),
        icon: Icons.add_task_rounded,
      ),
      _AcademicsTabItem(
        value: _AcademicsTab.schedule,
        label: context.tr('Расписание'),
        icon: Icons.event_note_rounded,
      ),
      _AcademicsTabItem(
        value: _AcademicsTab.teachers,
        label: context.tr('Учителя'),
        icon: Icons.assignment_ind_rounded,
      ),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final item in items)
          _AcademicsTabButton(
            item: item,
            selected: current == item.value,
            onTap: () => onChanged(item.value),
          ),
      ],
    );
  }
}

class _AcademicsTabItem {
  final _AcademicsTab value;
  final String label;
  final IconData icon;

  const _AcademicsTabItem({
    required this.value,
    required this.label,
    required this.icon,
  });
}

class _AcademicsTabButton extends StatelessWidget {
  final _AcademicsTabItem item;
  final bool selected;
  final VoidCallback onTap;

  const _AcademicsTabButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        selected ? const Color(0xFF0F766E) : context.secondaryTextColor;

    return Material(
      color: selected
          ? context.isDarkTheme
              ? const Color(0xFF134E4A)
              : const Color(0xFFE6FFFA)
          : context.panelColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minWidth: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color:
                  selected ? const Color(0xFF99F6E4) : context.appBorderColor,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, size: 18, color: color),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  item.label,
                  style: TextStyle(
                    color: color,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
          colors: [Color(0xFF0F172A), Color(0xFF0F766E)],
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
    return Container(
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
    );
  }
}

class _CreateClassPanel extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onCreate;

  const _CreateClassPanel({
    required this.controller,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return AdminPanel(
      title: context.tr('Создать класс'),
      icon: Icons.add_home_work_rounded,
      children: [
        TextField(
          controller: controller,
          textCapitalization: TextCapitalization.characters,
          style: TextStyle(color: context.primaryTextColor),
          cursorColor: const Color(0xFF0F766E),
          decoration: _inputDecoration(context, context.tr('Название класса')),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onCreate,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0F766E),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.add_rounded),
            label: Text(context.tr('Добавить класс')),
          ),
        ),
      ],
    );
  }
}

class _ClassesListPanel extends StatelessWidget {
  final List<SchoolClass> classes;

  const _ClassesListPanel({required this.classes});

  @override
  Widget build(BuildContext context) {
    return AdminPanel(
      title: context.tr('Список классов'),
      icon: Icons.meeting_room_rounded,
      children: [
        if (classes.isEmpty)
          _EmptyState(
            icon: Icons.meeting_room_outlined,
            title: context.tr('Классов пока нет'),
          )
        else
          Column(
            children: [
              for (var i = 0; i < classes.length; i++) ...[
                if (i != 0) Divider(height: 20, color: context.appBorderColor),
                _ClassRow(schoolClass: classes[i]),
              ],
            ],
          ),
      ],
    );
  }
}

class _ClassRow extends StatelessWidget {
  final SchoolClass schoolClass;

  const _ClassRow({required this.schoolClass});

  @override
  Widget build(BuildContext context) {
    final appState = context.appState;
    final students = appState.studentsForClass(schoolClass.id).length;
    final lessons = appState.lessonsForClass(schoolClass.id).length;

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            schoolClass.name,
            style: const TextStyle(
              color: Color(0xFF047857),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('Класс ${schoolClass.name}'),
                style: TextStyle(
                  color: context.primaryTextColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                context.tr('$students учеников • $lessons уроков'),
                style: TextStyle(
                  color: context.secondaryTextColor,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: context.tr('Редактировать'),
          onPressed: () => _editClass(context),
          icon: const Icon(Icons.edit_rounded),
        ),
        IconButton(
          tooltip: context.tr('Удалить'),
          onPressed: () => _deleteClass(context),
          icon: const Icon(Icons.delete_outline_rounded),
        ),
      ],
    );
  }

  Future<void> _editClass(BuildContext context) async {
    final controller = TextEditingController(text: schoolClass.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(context.tr('Редактировать класс')),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: context.tr('Название класса'),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(context.tr('Отмена')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(controller.text),
              child: Text(context.tr('Сохранить')),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (newName == null || !context.mounted) {
      return;
    }
    final result = await context.appState.updateSchoolClass(
      classId: schoolClass.id,
      name: newName,
    );
    if (!context.mounted) {
      return;
    }
    showAppSnackBar(
      context,
      context.tr(
        result.isSuccess
            ? 'Класс обновлен.'
            : _classErrorMessage(result.errorKey),
      ),
      backgroundColor:
          result.isSuccess ? const Color(0xFF047857) : const Color(0xFFB91C1C),
    );
  }

  Future<void> _deleteClass(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(context.tr('Удалить класс')),
          content: Text(
            context.tr(
              'Класс можно удалить только если в нем нет учеников и уроков.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(context.tr('Отмена')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(context.tr('Удалить')),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    final result = await context.appState.deleteSchoolClass(schoolClass.id);
    if (!context.mounted) {
      return;
    }
    showAppSnackBar(
      context,
      context.tr(
        result.isSuccess
            ? 'Класс удален.'
            : _classErrorMessage(result.errorKey),
      ),
      backgroundColor:
          result.isSuccess ? const Color(0xFF047857) : const Color(0xFFB91C1C),
    );
  }
}

String _lessonErrorMessage(String? errorKey) {
  switch (errorKey) {
    case 'validation.scheduleConflict':
      return 'На это время уже есть урок у выбранного класса или учителя.';
    case 'validation.invalidClass':
      return 'Выбранный класс не найден.';
    case 'validation.invalidTeacher':
      return 'Выбранный учитель не найден.';
    case 'validation.invalidWeekday':
      return 'Выбран некорректный день недели.';
    case 'validation.invalidLesson':
      return 'Заполните предмет, время и кабинет.';
    case null:
      return 'Не удалось добавить урок.';
    default:
      return 'Не удалось добавить урок: $errorKey';
  }
}

String _classErrorMessage(String? errorKey) {
  switch (errorKey) {
    case 'validation.invalidClass':
      return 'Введите название класса.';
    case 'validation.duplicateClass':
      return 'Такой класс уже есть в списке.';
    case 'validation.classNotEmpty':
      return 'Нельзя удалить класс, пока в нем есть ученики или уроки.';
    case 'validation.notFound':
      return 'Класс не найден.';
    case null:
      return 'Не удалось добавить класс.';
    default:
      return 'Не удалось добавить класс: $errorKey';
  }
}

class _CreateLessonPanel extends StatelessWidget {
  final String? classValue;
  final String? teacherValue;
  final String? selectedTimeRange;
  final int selectedWeekdayIndex;
  final List<SchoolClass> classes;
  final List<AppUser> teachers;
  final TextEditingController subjectController;
  final TextEditingController roomController;
  final ValueChanged<String?> onClassChanged;
  final ValueChanged<String?> onTeacherChanged;
  final ValueChanged<int?> onWeekdayChanged;
  final ValueChanged<String?> onTimeChanged;
  final VoidCallback onCreate;

  const _CreateLessonPanel({
    required this.classValue,
    required this.teacherValue,
    required this.selectedTimeRange,
    required this.selectedWeekdayIndex,
    required this.classes,
    required this.teachers,
    required this.subjectController,
    required this.roomController,
    required this.onClassChanged,
    required this.onTeacherChanged,
    required this.onWeekdayChanged,
    required this.onTimeChanged,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return AdminPanel(
      title: context.tr('Создать урок'),
      icon: Icons.add_task_rounded,
      children: [
        AppSelectField<String>(
          value: classValue,
          label: context.tr('Класс'),
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
        const SizedBox(height: 12),
        AppSelectField<String>(
          value: teacherValue,
          label: context.tr('Учитель'),
          icon: Icons.person_rounded,
          options: teachers
              .map(
                (item) => AppSelectOption<String>(
                  value: item.id,
                  label: item.fullName,
                ),
              )
              .toList(),
          onChanged: onTeacherChanged,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: subjectController,
          style: TextStyle(color: context.primaryTextColor),
          cursorColor: const Color(0xFF0F766E),
          decoration: _inputDecoration(context, context.tr('Предмет')),
        ),
        const SizedBox(height: 12),
        AppSelectField<int>(
          value: selectedWeekdayIndex,
          label: context.tr('День недели'),
          icon: Icons.calendar_today_rounded,
          options: List.generate(
            5,
            (index) => AppSelectOption<int>(
              value: index,
              label: context.tr(context.appState.weekdayLabel(index)),
            ),
          ),
          onChanged: onWeekdayChanged,
        ),
        const SizedBox(height: 12),
        AppSelectField<String>(
          value: selectedTimeRange,
          label: context.tr('Время урока'),
          icon: Icons.schedule_rounded,
          options: standardLessonTimeRanges
              .map(
                (item) => AppSelectOption<String>(
                  value: item,
                  label: item,
                ),
              )
              .toList(),
          onChanged: onTimeChanged,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: roomController,
          style: TextStyle(color: context.primaryTextColor),
          cursorColor: const Color(0xFF0F766E),
          decoration: _inputDecoration(context, context.tr('Кабинет')),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onCreate,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.event_available_rounded),
            label: Text(context.tr('Добавить урок')),
          ),
        ),
      ],
    );
  }
}

class _LessonsListPanel extends StatelessWidget {
  final List<LessonAssignment> lessons;
  final TextEditingController searchController;
  final VoidCallback onSearchChanged;

  const _LessonsListPanel({
    required this.lessons,
    required this.searchController,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    final query = searchController.text.trim().toLowerCase();
    final filtered = query.isEmpty
        ? lessons
        : lessons.where((lesson) {
            final teacher = context.appState.userById(lesson.teacherId);
            return [
              lesson.classId,
              lesson.subject,
              lesson.timeRange,
              lesson.room,
              context.tr(context.appState.weekdayLabel(lesson.weekdayIndex)),
              teacher?.fullName ?? '',
            ].join(' ').toLowerCase().contains(query);
          }).toList();

    return AdminPanel(
      title: context.tr('Список уроков'),
      icon: Icons.event_note_rounded,
      children: [
        _SearchField(
          controller: searchController,
          hint: context.tr('Поиск по расписанию...'),
          onChanged: onSearchChanged,
        ),
        const SizedBox(height: 12),
        if (lessons.isEmpty)
          _EmptyState(
            icon: Icons.event_busy_rounded,
            title: context.tr('Уроков пока нет'),
          )
        else if (filtered.isEmpty)
          _EmptyState(
            icon: Icons.search_off_rounded,
            title: context.tr('Уроки по запросу не найдены'),
          )
        else
          Column(
            children: [
              for (var i = 0; i < filtered.length; i++) ...[
                if (i != 0) Divider(height: 22, color: context.appBorderColor),
                _LessonRow(lesson: filtered[i]),
              ],
            ],
          ),
      ],
    );
  }
}

class _LessonRow extends StatelessWidget {
  final LessonAssignment lesson;

  const _LessonRow({required this.lesson});

  @override
  Widget build(BuildContext context) {
    final teacher = context.appState.userById(lesson.teacherId);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: context.isDarkTheme
                ? const Color(0xFF1E3A8A)
                : const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            lesson.classId,
            style: TextStyle(
              color: context.isDarkTheme
                  ? const Color(0xFFBFDBFE)
                  : const Color(0xFF1D4ED8),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lesson.subject,
                style: TextStyle(
                  color: context.primaryTextColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${context.tr(context.appState.weekdayLabel(lesson.weekdayIndex))} • ${lesson.timeRange} • ${lesson.room}',
                style: TextStyle(
                  color: context.secondaryTextColor,
                  fontSize: 13,
                ),
              ),
              if (teacher != null) ...[
                const SizedBox(height: 4),
                Text(
                  teacher.fullName,
                  style: TextStyle(
                    color: context.secondaryTextColor.withOpacity(0.82),
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _TeachingLoadPanel extends StatelessWidget {
  final List<AppUser> teachers;
  final TextEditingController searchController;
  final VoidCallback onSearchChanged;

  const _TeachingLoadPanel({
    required this.teachers,
    required this.searchController,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    final query = searchController.text.trim().toLowerCase();
    final filtered = query.isEmpty
        ? teachers
        : teachers.where((teacher) {
            final lessons = context.appState.lessonsForTeacher(teacher.id);
            return [
              teacher.fullName,
              teacher.email ?? '',
              teacher.phone ?? '',
              ...lessons.expand((lesson) => [
                    lesson.classId,
                    lesson.subject,
                    lesson.room,
                  ]),
            ].join(' ').toLowerCase().contains(query);
          }).toList();

    return AdminPanel(
      title: context.tr('Учителя и назначенные уроки'),
      icon: Icons.assignment_ind_rounded,
      children: [
        _SearchField(
          controller: searchController,
          hint: context.tr('Поиск учителей...'),
          onChanged: onSearchChanged,
        ),
        const SizedBox(height: 12),
        if (teachers.isEmpty)
          _EmptyState(
            icon: Icons.person_off_rounded,
            title: context.tr('Учителей пока нет'),
          )
        else if (filtered.isEmpty)
          _EmptyState(
            icon: Icons.search_off_rounded,
            title: context.tr('Учителя по запросу не найдены'),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final twoColumns = constraints.maxWidth >= 720;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: filtered
                    .map(
                      (teacher) => SizedBox(
                        width: twoColumns
                            ? (constraints.maxWidth - 12) / 2
                            : constraints.maxWidth,
                        child: _TeacherLoadCard(teacher: teacher),
                      ),
                    )
                    .toList(),
              );
            },
          ),
      ],
    );
  }
}

class _TeacherLoadCard extends StatelessWidget {
  final AppUser teacher;

  const _TeacherLoadCard({required this.teacher});

  @override
  Widget build(BuildContext context) {
    final lessons = context.appState.lessonsForTeacher(teacher.id);
    final classes = lessons.map((lesson) => lesson.classId).toSet().toList()
      ..sort();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.panelMutedColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.appBorderColor),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFEDE9FE),
            foregroundColor: const Color(0xFF6D28D9),
            child: Text(teacher.initials),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  teacher.fullName,
                  style: TextStyle(
                    color: context.primaryTextColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  classes.isEmpty
                      ? context.tr('Уроки не назначены')
                      : context.tr(
                          '${lessons.length} уроков • ${classes.join(', ')}'),
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

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final VoidCallback onChanged;

  const _SearchField({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: (_) => onChanged(),
      style: TextStyle(color: context.primaryTextColor),
      decoration: _inputDecoration(context, hint).copyWith(
        prefixIcon:
            Icon(Icons.search_rounded, color: context.secondaryTextColor),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  controller.clear();
                  onChanged();
                },
                icon: const Icon(Icons.close_rounded),
              ),
      ),
    );
  }
}

InputDecoration _inputDecoration(BuildContext context, String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: TextStyle(color: context.secondaryTextColor),
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
