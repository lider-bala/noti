import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../models/school_models.dart';
import '../../widgets/admin_panel.dart';
import '../../widgets/app_select_field.dart';
import '../../widgets/app_theme.dart';

class AdminClassScheduleScreen extends StatefulWidget {
  const AdminClassScheduleScreen({super.key});

  @override
  State<AdminClassScheduleScreen> createState() =>
      _AdminClassScheduleScreenState();
}

class _AdminClassScheduleScreenState extends State<AdminClassScheduleScreen> {
  String? _selectedClassId;
  int _selectedDay = 0;
  String _subjectFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final appState = context.appState;
    final classes = appState.schoolClasses;
    final selectedClass = classes.any((item) => item.id == _selectedClassId)
        ? _selectedClassId
        : classes.isEmpty
            ? null
            : classes.first.id;
    final lessons = selectedClass == null
        ? <LessonAssignment>[]
        : appState.lessonsForClass(selectedClass);

    return _ScheduleScaffold(
      title: context.tr('Расписание классов'),
      subtitle:
          context.tr('Выберите класс, день и предмет для просмотра уроков.'),
      emptyTitle: context.tr('Классов пока нет'),
      selectorLabel: context.tr('Класс'),
      selectedId: selectedClass,
      options: [
        for (final item in classes)
          _ScheduleOption(id: item.id, label: item.name),
      ],
      lessons: lessons,
      selectedDay: _selectedDay,
      subjectFilter: _subjectFilter,
      onSelectedIdChanged: (value) => setState(() {
        _selectedClassId = value;
        _subjectFilter = 'all';
      }),
      onDayChanged: (value) => setState(() => _selectedDay = value),
      onSubjectChanged: (value) => setState(() => _subjectFilter = value),
    );
  }
}

class AdminTeacherScheduleScreen extends StatefulWidget {
  const AdminTeacherScheduleScreen({super.key});

  @override
  State<AdminTeacherScheduleScreen> createState() =>
      _AdminTeacherScheduleScreenState();
}

class _AdminTeacherScheduleScreenState
    extends State<AdminTeacherScheduleScreen> {
  String? _selectedTeacherId;
  int _selectedDay = 0;
  String _subjectFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final appState = context.appState;
    final teachers = appState.teachers;
    final selectedTeacher =
        teachers.any((item) => item.id == _selectedTeacherId)
            ? _selectedTeacherId
            : teachers.isEmpty
                ? null
                : teachers.first.id;
    final lessons = selectedTeacher == null
        ? <LessonAssignment>[]
        : appState.lessonsForTeacher(selectedTeacher);

    return _ScheduleScaffold(
      title: context.tr('Расписание учителей'),
      subtitle: context
          .tr('Выберите учителя, день и предмет для просмотра нагрузки.'),
      emptyTitle: context.tr('Учителей пока нет'),
      selectorLabel: context.tr('Учитель'),
      selectedId: selectedTeacher,
      options: [
        for (final item in teachers)
          _ScheduleOption(id: item.id, label: item.fullName),
      ],
      lessons: lessons,
      selectedDay: _selectedDay,
      subjectFilter: _subjectFilter,
      onSelectedIdChanged: (value) => setState(() {
        _selectedTeacherId = value;
        _subjectFilter = 'all';
      }),
      onDayChanged: (value) => setState(() => _selectedDay = value),
      onSubjectChanged: (value) => setState(() => _subjectFilter = value),
    );
  }
}

class _ScheduleScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final String emptyTitle;
  final String selectorLabel;
  final String? selectedId;
  final List<_ScheduleOption> options;
  final List<LessonAssignment> lessons;
  final int selectedDay;
  final String subjectFilter;
  final ValueChanged<String?> onSelectedIdChanged;
  final ValueChanged<int> onDayChanged;
  final ValueChanged<String> onSubjectChanged;

  const _ScheduleScaffold({
    required this.title,
    required this.subtitle,
    required this.emptyTitle,
    required this.selectorLabel,
    required this.selectedId,
    required this.options,
    required this.lessons,
    required this.selectedDay,
    required this.subjectFilter,
    required this.onSelectedIdChanged,
    required this.onDayChanged,
    required this.onSubjectChanged,
  });

  @override
  Widget build(BuildContext context) {
    final dayLessons =
        lessons.where((lesson) => lesson.weekdayIndex == selectedDay).toList();
    final subjects = dayLessons.map((lesson) => lesson.subject).toSet().toList()
      ..sort();
    final filtered = subjectFilter == 'all'
        ? dayLessons
        : dayLessons
            .where((lesson) => lesson.subject == subjectFilter)
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(title: title, subtitle: subtitle),
        const SizedBox(height: 16),
        if (options.isEmpty)
          _EmptyState(title: emptyTitle)
        else ...[
          AdminPanel(
            title: context.tr('Фильтр расписания'),
            icon: Icons.filter_alt_rounded,
            children: [
              AppSelectField<String>(
                value: selectedId,
                label: selectorLabel,
                icon: Icons.meeting_room_rounded,
                options: [
                  for (final option in options)
                    AppSelectOption<String>(
                      value: option.id,
                      label: option.label,
                    ),
                ],
                onChanged: onSelectedIdChanged,
              ),
              const SizedBox(height: 12),
              _DaySelector(
                selectedDay: selectedDay,
                onChanged: onDayChanged,
              ),
              const SizedBox(height: 12),
              AppSelectField<String>(
                value: subjects.contains(subjectFilter) ? subjectFilter : 'all',
                label: context.tr('Предмет'),
                icon: Icons.book_rounded,
                options: [
                  AppSelectOption<String>(
                    value: 'all',
                    label: context.tr('Все уроки'),
                  ),
                  for (final subject in subjects)
                    AppSelectOption<String>(
                      value: subject,
                      label: subject,
                    ),
                ],
                onChanged: (value) => onSubjectChanged(value ?? 'all'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AdminPanel(
            title:
                '${context.tr(context.appState.weekdayLabel(selectedDay))} • ${context.tr('Уроки')} (${filtered.length})',
            icon: Icons.event_note_rounded,
            children: [_LessonsTable(lessons: filtered)],
          ),
        ],
      ],
    );
  }
}

class _DaySelector extends StatelessWidget {
  final int selectedDay;
  final ValueChanged<int> onChanged;

  const _DaySelector({
    required this.selectedDay,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var index = 0; index < 5; index++)
          ChoiceChip(
            label: Text(context.tr(context.appState.weekdayLabel(index))),
            selected: selectedDay == index,
            onSelected: (_) => onChanged(index),
            selectedColor: const Color(0xFF0F766E),
            backgroundColor: context.panelMutedColor,
            side: BorderSide.none,
            labelStyle: TextStyle(
              color: selectedDay == index
                  ? Colors.white
                  : context.primaryTextColor,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }
}

class _LessonsTable extends StatelessWidget {
  final List<LessonAssignment> lessons;

  const _LessonsTable({required this.lessons});

  @override
  Widget build(BuildContext context) {
    if (lessons.isEmpty) {
      return _EmptyState(title: context.tr('На выбранный день уроков нет'));
    }

    return Column(
      children: [
        for (var i = 0; i < lessons.length; i++) ...[
          if (i != 0) Divider(height: 22, color: context.appBorderColor),
          _LessonRow(lesson: lessons[i]),
        ],
      ],
    );
  }
}

class _LessonRow extends StatelessWidget {
  final LessonAssignment lesson;

  const _LessonRow({required this.lesson});

  @override
  Widget build(BuildContext context) {
    final appState = context.appState;
    final teacher = appState.userById(lesson.teacherId);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 64,
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: context.isDarkTheme
                ? const Color(0xFF1E3A8A)
                : const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            lesson.timeRange.split(' ').first,
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
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${lesson.classId} • ${lesson.timeRange} • ${lesson.room}',
                style: TextStyle(color: context.secondaryTextColor),
              ),
              if (teacher != null) ...[
                const SizedBox(height: 4),
                Text(
                  teacher.fullName,
                  style: TextStyle(
                    color: context.secondaryTextColor,
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

class _ScheduleOption {
  final String id;
  final String label;

  const _ScheduleOption({
    required this.id,
    required this.label,
  });
}

class _Header extends StatelessWidget {
  final String title;
  final String subtitle;

  const _Header({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF1D4ED8), Color(0xFF0F766E)],
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
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white70, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;

  const _EmptyState({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.panelMutedColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.appBorderColor),
      ),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: context.primaryTextColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
