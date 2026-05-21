import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../models/school_models.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/app_select_field.dart';
import '../../widgets/app_theme.dart';

class HomeworkScreen extends StatefulWidget {
  const HomeworkScreen({super.key});

  @override
  State<HomeworkScreen> createState() => _HomeworkScreenState();
}

class _HomeworkScreenState extends State<HomeworkScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _subjectController = TextEditingController();
  final _meetingTitleController =
      TextEditingController(text: 'Родительское собрание');
  final _meetingAgendaController = TextEditingController();
  final _meetingLocationController = TextEditingController(text: 'Каб. 205');

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _subjectController.dispose();
    _meetingTitleController.dispose();
    _meetingAgendaController.dispose();
    _meetingLocationController.dispose();
    super.dispose();
  }

  void _openAssignmentDialog() {
    final appState = context.appState;
    final user = appState.currentUser;
    final classes = user == null
        ? appState.schoolClasses
        : appState.classesForTeacher(user.id);
    if (classes.isEmpty) {
      showAppSnackBar(
        context,
        context.tr('Сначала назначьте учителю класс и урок.'),
        backgroundColor: context.errorSnackBg,
      );
      return;
    }

    var selectedClassId = classes.first.id;
    var selectedKind = AssignmentKind.homework;
    var dueAt = DateTime.now().add(const Duration(days: 2));
    var urgent = false;
    var requiresFile = true;
    var titleText = '';
    var descriptionText = '';
    var subjectText = _subjectForClass(appState, selectedClassId);
    _titleController.clear();
    _descriptionController.clear();
    _subjectController.text = subjectText;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Text(context.tr('Новое задание или контрольная')),
              content: SizedBox(
                width: 460,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppSelectField<String>(
                        value: selectedClassId,
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
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setDialogState(() {
                            selectedClassId = value;
                            subjectText = _subjectForClass(appState, value);
                            _subjectController.text = subjectText;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      AppSelectField<AssignmentKind>(
                        value: selectedKind,
                        label: context.tr('Тип'),
                        icon: Icons.assignment_rounded,
                        options: [
                          AppSelectOption<AssignmentKind>(
                            value: AssignmentKind.homework,
                            label: context.tr('Домашнее задание'),
                          ),
                          AppSelectOption<AssignmentKind>(
                            value: AssignmentKind.testWork,
                            label: context.tr('Контрольная работа'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => selectedKind = value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _subjectController,
                        onChanged: (value) => subjectText = value,
                        decoration:
                            _inputDecoration(context, context.tr('Предмет')),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _titleController,
                        onChanged: (value) => titleText = value,
                        decoration:
                            _inputDecoration(context, context.tr('Название')),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _descriptionController,
                        onChanged: (value) => descriptionText = value,
                        minLines: 2,
                        maxLines: 3,
                        decoration:
                            _inputDecoration(context, context.tr('Описание')),
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.event_rounded),
                        title: Text(context.tr('Срок сдачи')),
                        subtitle: Text(_dateTimeLabel(dueAt)),
                        trailing: TextButton(
                          onPressed: () async {
                            final picked = await _pickDateTime(dueAt);
                            if (picked != null) {
                              setDialogState(() => dueAt = picked);
                            }
                          },
                          child: Text(context.tr('Изменить')),
                        ),
                      ),
                      SwitchListTile(
                        value: urgent,
                        contentPadding: EdgeInsets.zero,
                        title: Text(context.tr('Срочно')),
                        onChanged: (value) {
                          setDialogState(() => urgent = value);
                        },
                      ),
                      SwitchListTile(
                        value: requiresFile,
                        contentPadding: EdgeInsets.zero,
                        title: Text(context.tr('Нужно прикрепить файл')),
                        onChanged: (value) {
                          setDialogState(() => requiresFile = value);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(context.tr('Отмена')),
                ),
                FilledButton(
                  onPressed: () async {
                    final normalizedTitle = (titleText.isNotEmpty
                            ? titleText
                            : _titleController.text)
                        .trim();
                    final normalizedSubject = (subjectText.isNotEmpty
                            ? subjectText
                            : _subjectController.text)
                        .trim();
                    final normalizedDescription = (descriptionText.isNotEmpty
                            ? descriptionText
                            : _descriptionController.text)
                        .trim();

                    if (normalizedTitle.isEmpty) {
                      showAppSnackBar(
                        context,
                        context.tr('Заполните название задания.'),
                        backgroundColor: context.errorSnackBg,
                      );
                      return;
                    }

                    final assignmentResult =
                        await appState.createHomeworkAssignment(
                      classId: selectedClassId,
                      subject: normalizedSubject,
                      title: normalizedTitle,
                      description: normalizedDescription,
                      dueAt: dueAt,
                      kind: selectedKind,
                      urgent: urgent,
                      requiresFile: requiresFile,
                    );
                    if (!mounted || !dialogContext.mounted) {
                      return;
                    }
                    final assignment = assignmentResult.data;
                    if (assignment == null) {
                      showAppSnackBar(
                        context,
                        context.tr(
                          'Не удалось создать задание. Проверьте класс и роль учителя.',
                        ),
                        backgroundColor: context.errorSnackBg,
                      );
                      return;
                    }
                    Navigator.of(dialogContext).pop();
                    showAppSnackBar(
                      context,
                      selectedKind == AssignmentKind.testWork
                          ? context.tr('Контрольная работа назначена классу.')
                          : context.tr('Задание назначено классу.'),
                      backgroundColor: context.successSnackBg,
                    );
                  },
                  child: Text(context.tr('Создать')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openMeetingDialog() {
    final appState = context.appState;
    final user = appState.currentUser;
    final classes = user == null
        ? appState.schoolClasses
        : appState.classesForTeacher(user.id);
    if (classes.isEmpty) {
      showAppSnackBar(
        context,
        context.tr('Сначала назначьте учителю класс и урок.'),
        backgroundColor: context.errorSnackBg,
      );
      return;
    }

    var selectedClassId = classes.first.id;
    var meetingAt = DateTime.now().add(const Duration(days: 3, hours: 18));
    _meetingTitleController.text = 'Родительское собрание';
    _meetingAgendaController.clear();
    _meetingLocationController.text = 'Каб. 205';
    var meetingTitleText = _meetingTitleController.text;
    var meetingAgendaText = _meetingAgendaController.text;
    var meetingLocationText = _meetingLocationController.text;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Text(context.tr('Назначить родительское собрание')),
              content: SizedBox(
                width: 460,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppSelectField<String>(
                      value: selectedClassId,
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
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => selectedClassId = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _meetingTitleController,
                      decoration:
                          _inputDecoration(context, context.tr('Название')),
                      onChanged: (value) => meetingTitleText = value,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _meetingAgendaController,
                      minLines: 2,
                      maxLines: 3,
                      decoration:
                          _inputDecoration(context, context.tr('Повестка')),
                      onChanged: (value) => meetingAgendaText = value,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _meetingLocationController,
                      decoration:
                          _inputDecoration(context, context.tr('Место')),
                      onChanged: (value) => meetingLocationText = value,
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.event_available_rounded),
                      title: Text(context.tr('Дата и время')),
                      subtitle: Text(_dateTimeLabel(meetingAt)),
                      trailing: TextButton(
                        onPressed: () async {
                          final picked = await _pickDateTime(meetingAt);
                          if (picked != null) {
                            setDialogState(() => meetingAt = picked);
                          }
                        },
                        child: Text(context.tr('Изменить')),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(context.tr('Отмена')),
                ),
                FilledButton(
                  onPressed: () {
                    final meeting = appState.createParentMeeting(
                      classId: selectedClassId,
                      title: meetingTitleText,
                      agenda: meetingAgendaText,
                      location: meetingLocationText,
                      meetingAt: meetingAt,
                    );
                    if (meeting == null) {
                      showAppSnackBar(
                        context,
                        context.tr('Не удалось создать собрание.'),
                        backgroundColor: context.errorSnackBg,
                      );
                      return;
                    }
                    Navigator.of(dialogContext).pop();
                    showAppSnackBar(
                      context,
                      context.tr('Родительское собрание назначено.'),
                      backgroundColor: context.successSnackBg,
                    );
                  },
                  child: Text(context.tr('Назначить')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<DateTime?> _pickDateTime(DateTime initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) {
      return null;
    }
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) {
      return null;
    }
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  String _subjectForClass(AppState appState, String classId) {
    final teacherId = appState.currentUser?.id;
    if (teacherId == null) {
      return '';
    }
    final lessons = appState
        .lessonsForTeacher(teacherId)
        .where((lesson) => lesson.classId == classId)
        .toList();
    return lessons.isEmpty ? '' : lessons.first.subject;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = context.appState;
    final user = appState.currentUser;
    final assignments = user == null
        ? const <HomeworkAssignment>[]
        : appState.assignmentsForTeacher(user.id);
    final active = assignments
        .where((assignment) => assignment.dueAt.isAfter(DateTime.now()))
        .length;
    final urgent = assignments.where(_isUrgent).length;
    final completed = assignments.where((assignment) {
      final total = appState.studentsForClass(assignment.classId).length;
      if (total == 0 || !assignment.requiresFile) {
        return false;
      }
      return appState.submissionsCountForAssignment(assignment.id) >= total;
    }).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFA855F7),
                Color(0xFF60A5FA),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                blurRadius: 32,
                offset: Offset(0, 20),
                color: Color(0x33000000),
              ),
            ],
          ),
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('Домашние задания'),
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.tr(
                  'Назначайте задания, контрольные работы и родительские собрания.',
                ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                value: '$active',
                label: context.tr('Активных'),
                bg: const Color(0xFFECFDF5),
                border: const Color(0xFFD1FAE5),
                valueColor: const Color(0xFF059669),
                labelColor: const Color(0xFF047857),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                value: '$urgent',
                label: context.tr('Срочных'),
                bg: const Color(0xFFFFF7ED),
                border: const Color(0xFFFEE2C5),
                valueColor: const Color(0xFFEA580C),
                labelColor: const Color(0xFFC2410C),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                value: '$completed',
                label: context.tr('Завершено'),
                bg: const Color(0xFFEFF6FF),
                border: const Color(0xFFDBEAFE),
                valueColor: const Color(0xFF2563EB),
                labelColor: const Color(0xFF1D4ED8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (assignments.isEmpty)
          _EmptyState(
            title: context.tr('Заданий пока нет'),
            subtitle: context.tr(
              'Создайте домашнее задание или контрольную для класса.',
            ),
          )
        else
          Column(
            children: [
              for (var i = 0; i < assignments.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _HomeworkCard(item: assignments[i]),
                ),
            ],
          ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: _openAssignmentDialog,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2ECC71),
                foregroundColor: Colors.white,
                padding:
                    EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              icon: Icon(Icons.add_task_rounded),
              label: Text(context.tr('+ Создать новое задание')),
            ),
            FilledButton.icon(
              onPressed: _openMeetingDialog,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                padding:
                    EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              icon: Icon(Icons.groups_rounded),
              label: Text(context.tr('Назначить собрание')),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color bg;
  final Color border;
  final Color valueColor;
  final Color labelColor;

  const _StatCard({
    required this.value,
    required this.label,
    required this.bg,
    required this.border,
    required this.valueColor,
    required this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: labelColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeworkCard extends StatefulWidget {
  final HomeworkAssignment item;

  const _HomeworkCard({required this.item});

  @override
  State<_HomeworkCard> createState() => _HomeworkCardState();
}

class _HomeworkCardState extends State<_HomeworkCard> {
  HomeworkAssignment get item => widget.item;
  bool _showSubmissions = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = context.appState;
    final submitted = appState.submissionsCountForAssignment(item.id);
    final total = appState.studentsForClass(item.classId).length;
    final progress = total == 0 ? 0.0 : submitted / total.toDouble();

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.panelColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _isUrgent(item)
              ? const Color(0xFFF97316).withOpacity(0.3)
              : context.appBorderColor,
          width: 2,
        ),
        boxShadow: const [
          BoxShadow(
            blurRadius: 24,
            offset: Offset(0, 14),
            color: Color(0x14000000),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: item.kind == AssignmentKind.testWork
                      ? const Color(0xFFF3E8FF)
                      : const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  item.kind == AssignmentKind.testWork
                      ? Icons.quiz_rounded
                      : Icons.menu_book_rounded,
                  color: item.kind == AssignmentKind.testWork
                      ? const Color(0xFF7C3AED)
                      : const Color(0xFF2563EB),
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          context.tr(item.subject),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: context.primaryTextColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (item.kind == AssignmentKind.testWork)
                          _Badge(
                            text: context.tr('Контрольная работа'),
                            color: const Color(0xFF7C3AED),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.trf('Класс {value}', {'value': item.classId}),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: context.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isUrgent(item))
                const Icon(
                  Icons.access_time_filled_rounded,
                  color: Color(0xFFF97316),
                  size: 24,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              context.tr(item.title),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: context.primaryTextColor,
              ),
            ),
          ),
          if (item.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                context.tr(item.description),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: context.secondaryTextColor,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Wrap(
                spacing: 14,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _InlineInfo(
                    icon: Icons.calendar_today_rounded,
                    text: _dateTimeLabel(item.dueAt),
                  ),
                  if (item.requiresFile)
                    _InlineInfo(
                      icon: Icons.attach_file_rounded,
                      text: context.tr('Файлы'),
                    ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    item.requiresFile
                        ? context.trf(
                            '{value} сдали',
                            {'value': '$submitted/$total'},
                          )
                        : context.tr('Без сдачи файла'),
                    style: TextStyle(
                      fontSize: 13,
                      color: context.secondaryTextColor,
                    ),
                  ),
                  if (item.requiresFile) ...[
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 80,
                      height: 6,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: const Color(0xFFE5E7EB),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF3B82F6),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => setState(() => _showSubmissions = !_showSubmissions),
            icon: Icon(
              _showSubmissions ? Icons.expand_less : Icons.expand_more,
              size: 20,
            ),
            label: Text(context.tr(_showSubmissions ? 'Скрыть работы' : 'Показать работы')),
          ),
          if (_showSubmissions)
            _SubmissionsList(
              assignmentId: item.id,
              classId: item.classId,
            ),
        ],
      ),
    );
  }
}

class _SubmissionsList extends StatelessWidget {
  final String assignmentId;
  final String classId;

  const _SubmissionsList({
    required this.assignmentId,
    required this.classId,
  });

  @override
  Widget build(BuildContext context) {
    final appState = context.appState;
    final students = appState.studentsForClass(classId);
    final submissions = appState.submissionsForAssignment(assignmentId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: context.appBorderColor),
        for (final student in students) ...[
          Builder(
            builder: (context) {
              final submission = submissions
                  .where((s) => s.studentId == student.id)
                  .toList();
              final sub = submission.isNotEmpty ? submission.first : null;
              return Container(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: context.activityOrangeBg,
                      foregroundColor: context.orangeTintFg,
                      child: Text(student.initials,
                          style: const TextStyle(fontSize: 10)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(student.fullName,
                              style:
                                  TextStyle(fontWeight: FontWeight.w600)),
                          if (sub != null) ...[
                            Text(
                              'Файл: ${sub.fileName} • ${sub.sizeLabel}',
                              style: TextStyle(
                                  fontSize: 12, color: context.secondaryTextColor),
                            ),
                            if (sub.grade != null)
                              Text(
                                'Оценка: ${sub.grade}${(sub.gradeComment ?? "").isNotEmpty ? " • ${sub.gradeComment}" : ""}',
                                style: TextStyle(
                                    fontSize: 12, color: Color(0xFF059669)),
                              ),
                          ] else
                            Text(context.tr('Не сдано'),
                                style: TextStyle(
                                    fontSize: 12, color: Color(0xFFDC2626))),
                        ],
                      ),
                    ),
                    if (sub != null && sub.grade == null)
                      PopupMenuButton<int>(
                        icon: Icon(Icons.grade_rounded, size: 20),
                        tooltip: context.tr('Поставить оценку'),
                        onSelected: (value) async {
                          await appState.gradeHomeworkSubmission(
                            submissionId: sub.id,
                            grade: value,
                          );
                        },
                        itemBuilder: (_) => [
                          for (final v in [5, 4, 3, 2])
                            PopupMenuItem(value: v, child: Text('$v')),
                        ],
                      ),
                    if (sub != null)
                      Icon(
                        Icons.check_circle_rounded,
                        color: const Color(0xFF10B981),
                        size: 20,
                      )
                    else
                      Icon(
                        Icons.cancel_rounded,
                        color: const Color(0xFFDC2626),
                        size: 20,
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}

class _InlineInfo extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InlineInfo({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: context.secondaryTextColor),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(fontSize: 13, color: context.secondaryTextColor),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;

  const _Badge({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.panelColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.appBorderColor),
      ),
      child: Column(
        children: [
          Icon(Icons.assignment_outlined, color: context.secondaryTextColor),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: context.primaryTextColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.secondaryTextColor),
          ),
        ],
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
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: context.appBorderColor),
    ),
  );
}

bool _isUrgent(HomeworkAssignment assignment) {
  return assignment.urgent ||
      assignment.dueAt.difference(DateTime.now()).inHours <= 48;
}

String _dateTimeLabel(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$day.$month.${date.year} $hour:$minute';
}
