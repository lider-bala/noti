import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../models/school_models.dart';
import '../../models/user_role.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/app_select_field.dart';
import '../../widgets/app_theme.dart';

class GradesScreen extends StatefulWidget {
  const GradesScreen({super.key});

  @override
  State<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends State<GradesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _categoryController = TextEditingController(text: 'Оценка за урок');
  final _commentController = TextEditingController();

  String? _selectedClassId;
  String? _selectedLessonId;
  final Map<String, int> _selectedGrades = {};

  int _selectedQuarter = 1;
  String? _historySubjectFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncSelection();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _categoryController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _syncSelection() {
    final appState = context.appState;
    final teacher = appState.currentUser;
    if (teacher == null || teacher.role != UserRole.teacher) {
      return;
    }

    final classes = appState.classesForTeacher(teacher.id);
    if (classes.isEmpty) {
      _selectedClassId = null;
      _selectedLessonId = null;
      _selectedGrades.clear();
      return;
    }

    final classId = classes.any((item) => item.id == _selectedClassId)
        ? _selectedClassId!
        : classes.first.id;
    final lessons = appState
        .lessonsForTeacher(teacher.id)
        .where((lesson) => lesson.classId == classId)
        .toList();
    final lessonId = lessons.any((item) => item.id == _selectedLessonId)
        ? _selectedLessonId
        : (lessons.isNotEmpty ? lessons.first.id : null);

    final changed =
        classId != _selectedClassId || lessonId != _selectedLessonId;
    _selectedClassId = classId;
    _selectedLessonId = lessonId;
    if (changed || _selectedGrades.isEmpty) {
      _seedGrades(classId: classId, lessonId: lessonId);
    }
  }

  void _seedGrades({
    required String classId,
    required String? lessonId,
  }) {
    final appState = context.appState;
    final students = appState.studentsForClass(classId);
    _selectedGrades.clear();
    if (lessonId == null) {
      return;
    }
    for (final student in students) {
      final latest = appState.latestGradeForStudentLesson(
        studentId: student.id,
        lessonId: lessonId,
      );
      if (latest != null) {
        _selectedGrades[student.id] = latest.value;
      }
    }
  }

  void _changeClass(String? classId) {
    if (classId == null) {
      return;
    }
    setState(() {
      _selectedClassId = classId;
      _selectedLessonId = null;
      _seedGrades(classId: classId, lessonId: null);
      _syncSelection();
    });
  }

  void _changeLesson(String? lessonId) {
    setState(() {
      _selectedLessonId = lessonId;
      if (_selectedClassId != null) {
        _seedGrades(classId: _selectedClassId!, lessonId: lessonId);
      }
    });
  }

  Future<void> _saveGrades() async {
    final lessonId = _selectedLessonId;
    if (lessonId == null) {
      showAppSnackBar(
        context,
        context.tr('Сначала выберите урок.'),
        backgroundColor: context.errorSnackBg,
      );
      return;
    }
    if (_selectedGrades.isEmpty) {
      showAppSnackBar(
        context,
        context.tr('Выберите хотя бы одну оценку.'),
        backgroundColor: context.errorSnackBg,
      );
      return;
    }

    final result = await context.appState.recordGrades(
      lessonId: lessonId,
      grades: Map<String, int>.from(_selectedGrades),
      category: _categoryController.text,
      comment: _commentController.text,
    );
    final success = result.isSuccess;
    if (!mounted) {
      return;
    }

    showAppSnackBar(
      context,
      context.tr(
        success ? 'Оценки сохранены.' : 'Не удалось сохранить оценки.',
      ),
      backgroundColor:
          success ? context.successSnackBg : context.errorSnackBg,
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.appState;
    final teacher = appState.currentUser;

    if (teacher == null || teacher.role != UserRole.teacher) {
      return _EmptyState(
        title: context.tr('Учитель не найден'),
        subtitle: context.tr(
          'Сначала войдите под аккаунтом учителя, чтобы выставлять оценки.',
        ),
      );
    }

    final classes = appState.classesForTeacher(teacher.id);
    if (classes.isEmpty) {
      return _EmptyState(
        title: context.tr('Классы пока не назначены'),
        subtitle: context.tr(
          'Администратор должен сначала назначить вам уроки.',
        ),
      );
    }

    return Column(
      children: [
        _Header(
          title: context.tr('Журнал оценок'),
          subtitle: context.tr(
            'Оценки, история, четвертные оценки и посещаемость учеников.',
          ),
        ),
        const SizedBox(height: 16),
        _ClassLessonSelector(
          classes: classes,
          selectedClassId: _selectedClassId,
          lessons: appState
              .lessonsForTeacher(teacher.id)
              .where((l) => l.classId == _selectedClassId)
              .toList(),
          selectedLessonId: _selectedLessonId,
          onClassChanged: _changeClass,
          onLessonChanged: _changeLesson,
        ),
        SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.appBorderColor),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: context.tabLabelColor,
            unselectedLabelColor: context.tabUnselectedColor,
            indicatorColor: context.tabLabelColor,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            tabs: [
              Tab(text: context.tr('Оценки')),
              Tab(text: context.tr('История')),
              Tab(text: context.tr('Четверти')),
              Tab(text: context.tr('Посещаемость')),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _GradeEntryTab(
                classId: _selectedClassId,
                lessonId: _selectedLessonId,
                selectedGrades: _selectedGrades,
                categoryController: _categoryController,
                commentController: _commentController,
                onGradeChanged: (studentId, grade) {
                  setState(() {
                    if (grade == null) {
                      _selectedGrades.remove(studentId);
                    } else {
                      _selectedGrades[studentId] = grade;
                    }
                  });
                },
                onSave: _saveGrades,
              ),
              _GradeHistoryTab(
                classId: _selectedClassId,
                subjectFilter: _historySubjectFilter,
                onSubjectFilterChanged: (v) =>
                    setState(() => _historySubjectFilter = v),
              ),
              _QuarterGradesTab(
                classId: _selectedClassId,
                selectedQuarter: _selectedQuarter,
                onQuarterChanged: (q) =>
                    setState(() => _selectedQuarter = q),
              ),
              _AttendanceHistoryTab(classId: _selectedClassId),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shared widgets
// ---------------------------------------------------------------------------

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
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFFFB7185), Color(0xFFF97316)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            blurRadius: 28,
            offset: Offset(0, 18),
            color: Color(0x26000000),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
          ),
        ],
      ),
    );
  }
}

class _ClassLessonSelector extends StatelessWidget {
  final List<SchoolClass> classes;
  final String? selectedClassId;
  final List<LessonAssignment> lessons;
  final String? selectedLessonId;
  final ValueChanged<String?> onClassChanged;
  final ValueChanged<String?> onLessonChanged;

  const _ClassLessonSelector({
    required this.classes,
    required this.selectedClassId,
    required this.lessons,
    required this.selectedLessonId,
    required this.onClassChanged,
    required this.onLessonChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 980;
        final classField = AppSelectField<String>(
          value: selectedClassId,
          label: context.tr('Класс'),
          icon: Icons.meeting_room_rounded,
          options: classes
              .map((item) => AppSelectOption<String>(
                    value: item.id,
                    label: item.name,
                  ))
              .toList(),
          onChanged: onClassChanged,
        );
        final lessonField = AppSelectField<String>(
          value: selectedLessonId,
          label: context.tr('Урок'),
          icon: Icons.event_note_rounded,
          options: lessons
              .map((lesson) => AppSelectOption<String>(
                    value: lesson.id,
                    label:
                        '${context.tr(lesson.subject)} • ${lesson.timeRange}',
                  ))
              .toList(),
          onChanged: onLessonChanged,
        );

        if (stacked) {
          return Column(
            children: [classField, const SizedBox(height: 12), lessonField],
          );
        }
        return Row(
          children: [
            Expanded(child: classField),
            const SizedBox(width: 12),
            Expanded(child: lessonField),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 1: Grade Entry
// ---------------------------------------------------------------------------

class _GradeEntryTab extends StatelessWidget {
  final String? classId;
  final String? lessonId;
  final Map<String, int> selectedGrades;
  final TextEditingController categoryController;
  final TextEditingController commentController;
  final void Function(String studentId, int? grade) onGradeChanged;
  final VoidCallback onSave;

  const _GradeEntryTab({
    required this.classId,
    required this.lessonId,
    required this.selectedGrades,
    required this.categoryController,
    required this.commentController,
    required this.onGradeChanged,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    if (classId == null) {
      return _EmptyState(
        title: context.tr('Класс не выбран'),
        subtitle: context.tr('Выберите класс для выставления оценок.'),
      );
    }

    final appState = context.appState;
    final students = appState.studentsForClass(classId!);
    final teacherGrades = appState.currentUser == null
        ? <GradeEntry>[]
        : appState.gradesForTeacher(appState.currentUser!.id);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 760;
              final categoryField = TextField(
                controller: categoryController,
                decoration:
                    _inputDecoration(context, context.tr('Тип оценки')),
              );
              final commentField = TextField(
                controller: commentController,
                decoration:
                    _inputDecoration(context, context.tr('Комментарий')),
              );
              if (stacked) {
                return Column(children: [
                  categoryField,
                  const SizedBox(height: 12),
                  commentField,
                ]);
              }
              return Row(children: [
                Expanded(child: categoryField),
                const SizedBox(width: 12),
                Expanded(child: commentField),
              ]);
            },
          ),
          SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _MetricChip(
                title: context.tr('Учеников в классе'),
                value: '${students.length}',
                color: const Color(0xFF2563EB),
              ),
              _MetricChip(
                title: context.tr('Оценок выбрано'),
                value: '${selectedGrades.length}',
                color: const Color(0xFF0F766E),
              ),
              _MetricChip(
                title: context.tr('Мои оценки всего'),
                value: '${teacherGrades.length}',
                color: const Color(0xFFD97706),
              ),
            ],
          ),
          SizedBox(height: 16),
          if (lessonId == null)
            _EmptyState(
              title: context.tr('Нет уроков для выбранного класса'),
              subtitle:
                  context.tr('Сначала добавьте уроки в админ-панели.'),
            )
          else
            _GradebookPanel(
              students: students,
              selectedGrades: selectedGrades,
              onGradeChanged: onGradeChanged,
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onSave,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              icon: Icon(Icons.save_rounded),
              label: Text(context.tr('Сохранить оценки')),
            ),
          ),
          const SizedBox(height: 16),
          _RecentGradesPanel(grades: teacherGrades.take(8).toList()),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 2: Grade History
// ---------------------------------------------------------------------------

class _GradeHistoryTab extends StatelessWidget {
  final String? classId;
  final String? subjectFilter;
  final ValueChanged<String?> onSubjectFilterChanged;

  const _GradeHistoryTab({
    required this.classId,
    required this.subjectFilter,
    required this.onSubjectFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (classId == null) {
      return _EmptyState(
        title: context.tr('Класс не выбран'),
        subtitle: context.tr('Выберите класс для просмотра истории оценок.'),
      );
    }

    final appState = context.appState;
    final classGrades = appState.gradesForClass(classId!);
    final subjects =
        classGrades.map((g) => g.subject).toSet().toList()..sort();

    final filteredGrades = subjectFilter == null
        ? classGrades
        : classGrades.where((g) => g.subject == subjectFilter).toList();

    final studentMap = <String, List<GradeEntry>>{};
    for (final g in filteredGrades) {
      studentMap.putIfAbsent(g.studentId, () => []).add(g);
    }

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (subjects.isNotEmpty)
            AppSelectField<String?>(
              value: subjectFilter,
              label: context.tr('Фильтр по предмету'),
              icon: Icons.filter_list_rounded,
              options: [
                AppSelectOption<String?>(
                  value: null,
                  label: context.tr('Все предметы'),
                ),
                ...subjects.map((s) => AppSelectOption<String?>(
                      value: s,
                      label: context.tr(s),
                    )),
              ],
              onChanged: onSubjectFilterChanged,
            ),
          SizedBox(height: 16),
          if (filteredGrades.isEmpty)
            _EmptyState(
              title: context.tr('Оценок пока нет'),
              subtitle: context
                  .tr('Оценки появятся здесь после сохранения.'),
            )
          else
            for (final entry in studentMap.entries) ...[
              _StudentGradeHistory(
                studentId: entry.key,
                grades: entry.value,
              ),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}

class _StudentGradeHistory extends StatelessWidget {
  final String studentId;
  final List<GradeEntry> grades;

  const _StudentGradeHistory({
    required this.studentId,
    required this.grades,
  });

  @override
  Widget build(BuildContext context) {
    final appState = context.appState;
    final student = appState.userById(studentId);
    final avg = appState.averageGrade(grades);

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.appBorderColor),
        boxShadow: const [
          BoxShadow(
            blurRadius: 12,
            offset: Offset(0, 6),
            color: Color(0x0E000000),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: context.avatarBg,
                foregroundColor: context.avatarFg,
                child: Text(student?.initials ?? '?'),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student?.fullName ?? context.tr('Ученик'),
                      style: TextStyle(
                        color: context.primaryTextColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${context.tr('Средний балл')}: ${avg.toStringAsFixed(1)} • ${grades.length} ${context.tr('оценок')}',
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
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: grades.map((g) {
              return Tooltip(
                message:
                    '${context.tr(g.subject)} • ${context.tr(g.category)}\n${MaterialLocalizations.of(context).formatShortDate(g.createdAt)}',
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _gradeColor(g.value).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${g.value}',
                    style: TextStyle(
                      color: _gradeColor(g.value),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 3: Quarter Grades
// ---------------------------------------------------------------------------

class _QuarterGradesTab extends StatelessWidget {
  final String? classId;
  final int selectedQuarter;
  final ValueChanged<int> onQuarterChanged;

  const _QuarterGradesTab({
    required this.classId,
    required this.selectedQuarter,
    required this.onQuarterChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (classId == null) {
      return _EmptyState(
        title: context.tr('Класс не выбран'),
        subtitle:
            context.tr('Выберите класс для четвертных оценок.'),
      );
    }

    final appState = context.appState;
    final students = appState.studentsForClass(classId!);
    final classGrades = appState.gradesForClass(classId!);
    final subjects =
        classGrades.map((g) => g.subject).toSet().toList()..sort();

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(4, (i) {
              final q = i + 1;
              final isSelected = q == selectedQuarter;
              return ChoiceChip(
                label: Text('$q ${context.tr('четверть')}'),
                selected: isSelected,
                onSelected: (_) => onQuarterChanged(q),
                selectedColor: context.chipSelectedBg,
                backgroundColor: context.chipUnselectedBg,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : context.chipUnselectedFg,
                  fontWeight: FontWeight.w600,
                ),
                side: BorderSide.none,
              );
            }),
          ),
          SizedBox(height: 16),
          if (subjects.isEmpty)
            _EmptyState(
              title: context.tr('Оценок пока нет'),
              subtitle: context.tr(
                'Четвертные оценки станут доступны после выставления текущих оценок.',
              ),
            )
          else
            for (final subject in subjects) ...[
              _QuarterSubjectCard(
                classId: classId!,
                subject: subject,
                students: students,
                quarter: selectedQuarter,
              ),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}

class _QuarterSubjectCard extends StatelessWidget {
  final String classId;
  final String subject;
  final List<AppUser> students;
  final int quarter;

  const _QuarterSubjectCard({
    required this.classId,
    required this.subject,
    required this.students,
    required this.quarter,
  });

  @override
  Widget build(BuildContext context) {
    final appState = context.appState;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.appBorderColor),
        boxShadow: const [
          BoxShadow(
            blurRadius: 12,
            offset: Offset(0, 6),
            color: Color(0x0E000000),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr(subject),
            style: TextStyle(
              color: context.primaryTextColor,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 12),
          for (var i = 0; i < students.length; i++) ...[
            if (i != 0) Divider(height: 18, color: context.appBorderColor),
            _QuarterStudentRow(
              student: students[i],
              classId: classId,
              subject: subject,
              quarter: quarter,
              appState: appState,
            ),
          ],
        ],
      ),
    );
  }
}

class _QuarterStudentRow extends StatefulWidget {
  final AppUser student;
  final String classId;
  final String subject;
  final int quarter;
  final AppState appState;

  const _QuarterStudentRow({
    required this.student,
    required this.classId,
    required this.subject,
    required this.quarter,
    required this.appState,
  });

  @override
  State<_QuarterStudentRow> createState() => _QuarterStudentRowState();
}

class _QuarterStudentRowState extends State<_QuarterStudentRow> {
  @override
  Widget build(BuildContext context) {
    final grades = widget.appState.gradesForStudentSubject(
      studentId: widget.student.id,
      subject: widget.subject,
    );
    final avg = widget.appState.averageGrade(grades);
    final suggested = widget.appState.suggestedQuarterGrade(avg);
    final existing = widget.appState.quarterGradeFor(
      studentId: widget.student.id,
      subject: widget.subject,
      quarter: widget.quarter,
    );
    final currentValue = existing?.value;

    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: context.activityOrangeBg,
          foregroundColor: context.orangeTintFg,
          child: Text(
            widget.student.initials,
            style: const TextStyle(fontSize: 11),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.student.fullName,
                style: TextStyle(
                  color: context.primaryTextColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                grades.isEmpty
                    ? context.tr('Нет оценок')
                    : '${context.tr('Ср.')}: ${avg.toStringAsFixed(1)} → ${context.tr('рекомендация')}: $suggested',
                style: TextStyle(
                  color: context.secondaryTextColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Wrap(
          spacing: 4,
          children: [
            for (final value in const [5, 4, 3, 2])
              _SmallGradeChip(
                value: value,
                isSelected: currentValue == value,
                isSuggested: grades.isNotEmpty && value == suggested,
                onTap: () async {
                  await widget.appState.recordQuarterGrade(
                    studentId: widget.student.id,
                    classId: widget.classId,
                    subject: widget.subject,
                    quarter: widget.quarter,
                    value: value,
                    suggestedValue: avg,
                  );
                  if (mounted) setState(() {});
                },
              ),
          ],
        ),
      ],
    );
  }
}

class _SmallGradeChip extends StatelessWidget {
  final int value;
  final bool isSelected;
  final bool isSuggested;
  final VoidCallback onTap;

  const _SmallGradeChip({
    required this.value,
    required this.isSelected,
    required this.isSuggested,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _gradeColor(value);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: isSuggested && !isSelected
              ? Border.all(color: color, width: 2)
              : null,
        ),
        child: Text(
          '$value',
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 4: Attendance History
// ---------------------------------------------------------------------------

class _AttendanceHistoryTab extends StatelessWidget {
  final String? classId;

  const _AttendanceHistoryTab({required this.classId});

  @override
  Widget build(BuildContext context) {
    if (classId == null) {
      return _EmptyState(
        title: context.tr('Класс не выбран'),
        subtitle:
            context.tr('Выберите класс для просмотра посещаемости.'),
      );
    }

    final appState = context.appState;
    final students = appState.studentsForClass(classId!);
    final sessions = appState.attendanceSessionsForClass(classId!);

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (sessions.isEmpty)
            _EmptyState(
              title: context.tr('Записей пока нет'),
              subtitle: context
                  .tr('История посещаемости появится после сохранения.'),
            )
          else ...[
            _AttendanceSummaryPanel(
              students: students,
              sessions: sessions,
            ),
            SizedBox(height: 16),
            Text(
              context.tr('Детализация по ученикам'),
              style: TextStyle(
                color: context.primaryTextColor,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            for (final student in students) ...[
              _StudentAttendanceSummary(
                student: student,
                sessions: sessions,
              ),
              const SizedBox(height: 10),
            ],
          ],
        ],
      ),
    );
  }
}

class _AttendanceSummaryPanel extends StatelessWidget {
  final List<AppUser> students;
  final List<AttendanceSession> sessions;

  const _AttendanceSummaryPanel({
    required this.students,
    required this.sessions,
  });

  @override
  Widget build(BuildContext context) {
    int totalPresent = 0;
    int totalLate = 0;
    int totalAbsent = 0;
    for (final session in sessions) {
      for (final entry in session.entries) {
        switch (entry.status) {
          case AttendanceStatusType.present:
            totalPresent++;
          case AttendanceStatusType.late:
            totalLate++;
          case AttendanceStatusType.absent:
            totalAbsent++;
        }
      }
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _MetricChip(
          title: context.tr('Занятий'),
          value: '${sessions.length}',
          color: context.primaryTextColor,
        ),
        _MetricChip(
          title: context.tr('Присутствовали'),
          value: '$totalPresent',
          color: const Color(0xFF059669),
        ),
        _MetricChip(
          title: context.tr('Опоздали'),
          value: '$totalLate',
          color: const Color(0xFFD97706),
        ),
        _MetricChip(
          title: context.tr('Отсутствовали'),
          value: '$totalAbsent',
          color: const Color(0xFFDC2626),
        ),
      ],
    );
  }
}

class _StudentAttendanceSummary extends StatelessWidget {
  final AppUser student;
  final List<AttendanceSession> sessions;

  const _StudentAttendanceSummary({
    required this.student,
    required this.sessions,
  });

  @override
  Widget build(BuildContext context) {
    int present = 0;
    int late = 0;
    int absent = 0;

    for (final session in sessions) {
      for (final entry in session.entries) {
        if (entry.studentId == student.id) {
          switch (entry.status) {
            case AttendanceStatusType.present:
              present++;
            case AttendanceStatusType.late:
              late++;
            case AttendanceStatusType.absent:
              absent++;
          }
        }
      }
    }

    final total = present + late + absent;
    if (total == 0) return const SizedBox.shrink();

    final percent = ((present + late) / total * 100).round();

    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.appBorderColor),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: percent >= 80
                ? context.greenTintBg
                : percent >= 60
                    ? context.orangeTintBg
                    : context.redTintBg,
            foregroundColor: percent >= 80
                ? context.greenTintFg
                : percent >= 60
                    ? context.orangeTintFg
                    : context.redTintFg,
            child: Text(
              student.initials,
              style: const TextStyle(fontSize: 11),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.fullName,
                  style: TextStyle(
                    color: context.primaryTextColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '$percent% • ${context.tr('Был')}: $present  ${context.tr('Опоздал')}: $late  ${context.tr('Не был')}: $absent',
                  style: TextStyle(
                    color: context.secondaryTextColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: percent >= 80
                  ? context.greenTintBg
                  : percent >= 60
                      ? context.orangeTintBg
                      : context.redTintBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$percent%',
              style: TextStyle(
                color: percent >= 80
                    ? context.greenTintFg
                    : percent >= 60
                        ? context.orangeTintFg
                        : context.redTintFg,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared small widgets
// ---------------------------------------------------------------------------

class _GradebookPanel extends StatelessWidget {
  final List<AppUser> students;
  final Map<String, int> selectedGrades;
  final void Function(String studentId, int? grade) onGradeChanged;

  const _GradebookPanel({
    required this.students,
    required this.selectedGrades,
    required this.onGradeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.appBorderColor),
        boxShadow: const [
          BoxShadow(
            blurRadius: 20,
            offset: Offset(0, 12),
            color: Color(0x12000000),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('Оценки учеников'),
            style: TextStyle(
              color: context.primaryTextColor,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 12),
          for (var i = 0; i < students.length; i++) ...[
            if (i != 0) Divider(height: 22, color: context.appBorderColor),
            _StudentGradeRow(
              student: students[i],
              grade: selectedGrades[students[i].id],
              onChanged: (grade) => onGradeChanged(students[i].id, grade),
            ),
          ],
        ],
      ),
    );
  }
}

class _StudentGradeRow extends StatelessWidget {
  final AppUser student;
  final int? grade;
  final ValueChanged<int?> onChanged;

  const _StudentGradeRow({
    required this.student,
    required this.grade,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: context.activityOrangeBg,
          foregroundColor: context.orangeTintFg,
          child: Text(student.initials),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                student.fullName,
                style: TextStyle(
                  color: context.primaryTextColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                [
                  if ((student.schoolClass ?? '').isNotEmpty)
                    student.schoolClass!,
                  student.email ?? '',
                ].where((item) => item.isNotEmpty).join(' • '),
                style: TextStyle(
                  color: context.secondaryTextColor,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final value in const [5, 4, 3, 2])
              ChoiceChip(
                label: Text('$value'),
                selected: grade == value,
                onSelected: (_) => onChanged(value),
                selectedColor: _gradeColor(value),
                backgroundColor: _gradeColor(value).withOpacity(0.12),
                labelStyle: TextStyle(
                  color: grade == value ? Colors.white : _gradeColor(value),
                  fontWeight: FontWeight.w700,
                ),
                side: BorderSide.none,
              ),
            if (grade != null)
              IconButton(
                tooltip: context.tr('Очистить оценку'),
                onPressed: () => onChanged(null),
                icon: Icon(Icons.close_rounded),
                color: context.mutedTextColor,
              ),
          ],
        ),
      ],
    );
  }
}

class _RecentGradesPanel extends StatelessWidget {
  final List<GradeEntry> grades;

  const _RecentGradesPanel({required this.grades});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.appBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('Последние выставленные оценки'),
            style: TextStyle(
              color: context.primaryTextColor,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 12),
          if (grades.isEmpty)
            Text(
              context.tr('Оценки пока не выставлены.'),
              style: TextStyle(color: context.secondaryTextColor),
            )
          else
            Column(
              children: [
                for (var i = 0; i < grades.length; i++) ...[
                  if (i != 0)
                    Divider(height: 22, color: context.appBorderColor),
                  _RecentGradeRow(grade: grades[i]),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _RecentGradeRow extends StatelessWidget {
  final GradeEntry grade;

  const _RecentGradeRow({required this.grade});

  @override
  Widget build(BuildContext context) {
    final student = context.appState.userById(grade.studentId);

    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _gradeColor(grade.value).withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            '${grade.value}',
            style: TextStyle(
              color: _gradeColor(grade.value),
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                student?.fullName ?? context.tr('Ученик'),
                style: TextStyle(
                  color: context.primaryTextColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 3),
              Text(
                '${context.tr(grade.subject)} • ${context.tr(grade.category)}',
                style: TextStyle(
                  color: context.secondaryTextColor,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        Text(
          MaterialLocalizations.of(context).formatShortDate(grade.createdAt),
          style: TextStyle(
            color: context.mutedTextColor,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _MetricChip({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: context.secondaryTextColor,
              fontSize: 12,
            ),
          ),
        ],
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
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.appBorderColor),
      ),
      child: Column(
        children: [
          Icon(
            Icons.bar_chart_rounded,
            color: context.orangeTintFg,
            size: 36,
          ),
          SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: context.primaryTextColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6),
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

Color _gradeColor(int grade) {
  if (grade >= 5) {
    return const Color(0xFF059669);
  }
  if (grade == 4) {
    return const Color(0xFF2563EB);
  }
  if (grade == 3) {
    return const Color(0xFFD97706);
  }
  return const Color(0xFFDC2626);
}

InputDecoration _inputDecoration(BuildContext context, String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: TextStyle(color: context.secondaryTextColor),
    filled: true,
    fillColor: context.panelMutedColor,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: context.appBorderColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: context.appBorderColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(
        color: Color(0xFFF97316),
        width: 1.4,
      ),
    ),
  );
}
