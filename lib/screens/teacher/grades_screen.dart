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
  final _categoryController = TextEditingController(text: 'Оценка за урок');
  final _commentController = TextEditingController();
  late final TabController _tabController;

  String? _selectedClassId;
  String? _selectedLessonId;
  final Map<String, int> _selectedGrades = {};
  int _selectedQuarter = _currentQuarter();

  static int _currentQuarter() {
    final month = DateTime.now().month;
    if (month >= 9 && month <= 11) return 1;
    if (month >= 12 || month <= 2) return 2;
    if (month >= 3 && month <= 5) return 3;
    return 4;
  }

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
    _categoryController.dispose();
    _commentController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _syncSelection() {
    final appState = context.appState;
    final teacher = appState.currentUser;
    if (teacher == null || teacher.role != UserRole.teacher) return;

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

  void _seedGrades({required String classId, required String? lessonId}) {
    final appState = context.appState;
    final students = appState.studentsForClass(classId);
    _selectedGrades.clear();
    if (lessonId == null) return;
    for (final student in students) {
      final latest = appState.latestGradeForStudentLesson(
        studentId: student.id,
        lessonId: lessonId,
      );
      if (latest != null) _selectedGrades[student.id] = latest.value;
    }
  }

  void _changeClass(String? classId) {
    if (classId == null) return;
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
      showAppSnackBar(context, context.tr('Сначала выберите урок.'),
          backgroundColor: const Color(0xFFB91C1C));
      return;
    }
    if (_selectedGrades.isEmpty) {
      showAppSnackBar(context, context.tr('Выберите хотя бы одну оценку.'),
          backgroundColor: const Color(0xFFB91C1C));
      return;
    }
    final result = await context.appState.recordGrades(
      lessonId: lessonId,
      grades: Map<String, int>.from(_selectedGrades),
      category: _categoryController.text,
      comment: _commentController.text,
    );
    if (!mounted) return;
    showAppSnackBar(
      context,
      context.tr(
          result.isSuccess ? 'Оценки сохранены.' : 'Не удалось сохранить оценки.'),
      backgroundColor:
          result.isSuccess ? const Color(0xFF047857) : const Color(0xFFB91C1C),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.appState;
    final teacher = appState.currentUser;
    if (teacher == null || teacher.role != UserRole.teacher) {
      return _EmptyState(
        title: context.tr('Учитель не найден'),
        subtitle: context.tr('Войдите под аккаунтом учителя.'),
      );
    }
    final classes = appState.classesForTeacher(teacher.id);
    if (classes.isEmpty) {
      return _EmptyState(
        title: context.tr('Классы пока не назначены'),
        subtitle: context.tr('Администратор должен назначить вам уроки.'),
      );
    }

    final selectedClass =
        classes.firstWhere((item) => item.id == _selectedClassId);
    final lessons = appState
        .lessonsForTeacher(teacher.id)
        .where((lesson) => lesson.classId == selectedClass.id)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(
          title: context.tr('Журнал оценок'),
          subtitle: context.tr('Оценки, четверти, история и посещаемость.'),
        ),
        const SizedBox(height: 20),
        _buildClassLessonSelectors(classes, lessons),
        const SizedBox(height: 12),
        TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFF97316),
          unselectedLabelColor: context.secondaryTextColor,
          indicatorColor: const Color(0xFFF97316),
          isScrollable: true,
          tabs: [
            Tab(text: context.tr('Оценки')),
            Tab(text: context.tr('История')),
            Tab(text: context.tr('Четверти')),
            Tab(text: context.tr('Посещаемость')),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 600,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildGradingTab(appState, teacher, selectedClass, lessons),
              _buildHistoryTab(appState, teacher),
              _buildQuarterTab(appState, teacher, selectedClass),
              _buildAttendanceTab(appState, selectedClass),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClassLessonSelectors(
      List<SchoolClass> classes, List<LessonAssignment> lessons) {
    final selectedLesson = lessons.isEmpty
        ? null
        : lessons.firstWhere(
            (item) => item.id == _selectedLessonId,
            orElse: () => lessons.first,
          );
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 980;
        final classField = AppSelectField<String>(
          value: _selectedClassId,
          label: context.tr('Класс'),
          icon: Icons.meeting_room_rounded,
          options: classes
              .map((item) =>
                  AppSelectOption<String>(value: item.id, label: item.name))
              .toList(),
          onChanged: _changeClass,
        );
        final lessonField = AppSelectField<String>(
          value: selectedLesson?.id,
          label: context.tr('Урок'),
          icon: Icons.event_note_rounded,
          options: lessons
              .map((lesson) => AppSelectOption<String>(
                    value: lesson.id,
                    label:
                        '${context.tr(lesson.subject)} • ${lesson.timeRange}',
                  ))
              .toList(),
          onChanged: _changeLesson,
        );
        if (stacked) {
          return Column(children: [classField, const SizedBox(height: 12), lessonField]);
        }
        return Row(children: [
          Expanded(child: classField),
          const SizedBox(width: 12),
          Expanded(child: lessonField),
        ]);
      },
    );
  }

  Widget _buildGradingTab(AppState appState, AppUser teacher,
      SchoolClass selectedClass, List<LessonAssignment> lessons) {
    final students = appState.studentsForClass(selectedClass.id);
    final selectedLesson = lessons.isEmpty
        ? null
        : lessons.firstWhere(
            (item) => item.id == _selectedLessonId,
            orElse: () => lessons.first,
          );

    return SingleChildScrollView(
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 760;
              final categoryField = TextField(
                controller: _categoryController,
                decoration:
                    _inputDecoration(context, context.tr('Тип оценки')),
              );
              final commentField = TextField(
                controller: _commentController,
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
          const SizedBox(height: 16),
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
                value: '${_selectedGrades.length}',
                color: const Color(0xFF0F766E),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (selectedLesson == null)
            _EmptyState(
              title: context.tr('Нет уроков'),
              subtitle: context.tr('Добавьте уроки в админ-панели.'),
            )
          else
            _GradebookPanel(
              students: students,
              selectedGrades: _selectedGrades,
              onGradeChanged: (studentId, grade) {
                setState(() {
                  if (grade == null) {
                    _selectedGrades.remove(studentId);
                  } else {
                    _selectedGrades[studentId] = grade;
                  }
                });
              },
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _saveGrades,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
              ),
              icon: Icon(Icons.save_rounded),
              label: Text(context.tr('Сохранить оценки')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(AppState appState, AppUser teacher) {
    final teacherGrades = appState.gradesForTeacher(teacher.id);
    return SingleChildScrollView(
      child: _RecentGradesPanel(grades: teacherGrades),
    );
  }

  Widget _buildQuarterTab(
      AppState appState, AppUser teacher, SchoolClass selectedClass) {
    final students = appState.studentsForClass(selectedClass.id);
    final subjects = appState
        .lessonsForTeacher(teacher.id)
        .where((l) => l.classId == selectedClass.id)
        .map((l) => l.subject)
        .toSet()
        .toList()
      ..sort();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(context.tr('Четверть:'),
                  style: TextStyle(fontWeight: FontWeight.w600, color: context.primaryTextColor)),
              const SizedBox(width: 12),
              for (int q = 1; q <= 4; q++) ...[
                ChoiceChip(
                  label: Text('$q'),
                  selected: _selectedQuarter == q,
                  onSelected: (_) => setState(() => _selectedQuarter = q),
                  selectedColor: const Color(0xFFF97316),
                  labelStyle: TextStyle(
                    color: _selectedQuarter == q
                        ? Colors.white
                        : context.primaryTextColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
              ],
            ],
          ),
          const SizedBox(height: 16),
          if (subjects.isEmpty)
            _EmptyState(
              title: context.tr('Нет предметов'),
              subtitle: context.tr('Назначьте уроки для этого класса.'),
            )
          else
            for (final subject in subjects) ...[
              _QuarterSubjectCard(
                subject: subject,
                students: students,
                quarter: _selectedQuarter,
                classId: selectedClass.id,
                appState: appState,
                onGradeSet: () => setState(() {}),
              ),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }

  Widget _buildAttendanceTab(AppState appState, SchoolClass selectedClass) {
    final students = appState.studentsForClass(selectedClass.id);
    final sessions = appState.attendanceSessions
        .where((s) => s.classId == selectedClass.id)
        .toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('История посещаемости'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: context.primaryTextColor,
            ),
          ),
          const SizedBox(height: 12),
          if (students.isEmpty || sessions.isEmpty)
            _EmptyState(
              title: context.tr('Нет данных'),
              subtitle: context.tr('Сохраните посещаемость для класса.'),
            )
          else
            for (final student in students) ...[
              _StudentAttendanceCard(
                student: student,
                sessions: sessions,
              ),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _QuarterSubjectCard extends StatelessWidget {
  final String subject;
  final List<AppUser> students;
  final int quarter;
  final String classId;
  final AppState appState;
  final VoidCallback onGradeSet;

  const _QuarterSubjectCard({
    required this.subject,
    required this.students,
    required this.quarter,
    required this.classId,
    required this.appState,
    required this.onGradeSet,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.panelColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.appBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr(subject),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: context.primaryTextColor,
            ),
          ),
          const SizedBox(height: 12),
          for (final student in students) ...[
            _QuarterStudentRow(
              student: student,
              subject: subject,
              quarter: quarter,
              classId: classId,
              appState: appState,
              onGradeSet: onGradeSet,
            ),
            Divider(height: 16, color: context.appBorderColor),
          ],
        ],
      ),
    );
  }
}

class _QuarterStudentRow extends StatelessWidget {
  final AppUser student;
  final String subject;
  final int quarter;
  final String classId;
  final AppState appState;
  final VoidCallback onGradeSet;

  const _QuarterStudentRow({
    required this.student,
    required this.subject,
    required this.quarter,
    required this.classId,
    required this.appState,
    required this.onGradeSet,
  });

  @override
  Widget build(BuildContext context) {
    final studentGrades = appState
        .gradesForStudent(student.id)
        .where((g) => g.subject == subject)
        .toList();
    final avg = appState.averageGrade(studentGrades);
    final suggested = appState.suggestedQuarterGrade(avg);
    final existingQg = appState
        .quarterGradesForStudent(student.id)
        .where((qg) => qg.subject == subject && qg.quarter == quarter)
        .toList();
    final currentQuarterGrade =
        existingQg.isNotEmpty ? existingQg.first.value : null;

    // Include homework grades
    final hwSubmissions = appState.submissionsForStudent(student.id);
    final hwGrades = hwSubmissions
        .where((s) => s.grade != null)
        .map((s) => s.grade!)
        .toList();
    final allGradeValues = [
      ...studentGrades.map((g) => g.value),
      ...hwGrades,
    ];
    final totalAvg = allGradeValues.isEmpty
        ? 0.0
        : allGradeValues.fold<int>(0, (s, v) => s + v) / allGradeValues.length;

    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: const Color(0xFFFFEDD5),
          foregroundColor: const Color(0xFFEA580C),
          child: Text(student.initials, style: const TextStyle(fontSize: 12)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(student.fullName,
                  style: TextStyle(fontWeight: FontWeight.w600)),
              Text(
                '${context.tr("Ср. балл")}: ${totalAvg > 0 ? totalAvg.toStringAsFixed(1) : "—"}'
                '  ${context.tr("Подсказка")}: $suggested',
                style:
                    TextStyle(fontSize: 12, color: context.secondaryTextColor),
              ),
            ],
          ),
        ),
        if (currentQuarterGrade != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _gradeColor(currentQuarterGrade).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$currentQuarterGrade',
              style: TextStyle(
                color: _gradeColor(currentQuarterGrade),
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ),
        const SizedBox(width: 8),
        PopupMenuButton<int>(
          icon: Icon(Icons.edit_rounded, size: 20),
          tooltip: context.tr('Поставить четвертную оценку'),
          onSelected: (value) async {
            await appState.setQuarterGrade(
              studentId: student.id,
              classId: classId,
              subject: subject,
              quarter: quarter,
              value: value,
              averageGradeValue: totalAvg,
            );
            onGradeSet();
          },
          itemBuilder: (_) => [
            for (final v in [5, 4, 3, 2])
              PopupMenuItem(value: v, child: Text('$v')),
          ],
        ),
      ],
    );
  }
}

class _StudentAttendanceCard extends StatelessWidget {
  final AppUser student;
  final List<AttendanceSession> sessions;

  const _StudentAttendanceCard({
    required this.student,
    required this.sessions,
  });

  @override
  Widget build(BuildContext context) {
    int present = 0, late = 0, absent = 0;
    for (final session in sessions) {
      for (final entry in session.entries) {
        if (entry.studentId != student.id) continue;
        switch (entry.status) {
          case AttendanceStatusType.present:
            present++;
            break;
          case AttendanceStatusType.late:
            late++;
            break;
          case AttendanceStatusType.absent:
            absent++;
            break;
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.panelColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appBorderColor),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFFFEDD5),
            foregroundColor: const Color(0xFFEA580C),
            child: Text(student.initials, style: TextStyle(fontSize: 13)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(student.fullName,
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          _AttendanceBadge(
              label: context.tr('Был'), count: present, color: const Color(0xFF059669)),
          const SizedBox(width: 6),
          _AttendanceBadge(
              label: context.tr('Опоздал'),
              count: late,
              color: const Color(0xFFD97706)),
          const SizedBox(width: 6),
          _AttendanceBadge(
              label: context.tr('НБ'), count: absent, color: const Color(0xFFDC2626)),
        ],
      ),
    );
  }
}

class _AttendanceBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _AttendanceBadge({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
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
              color: Color(0x26000000)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(subtitle,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.white.withValues(alpha: 0.9))),
        ],
      ),
    );
  }
}

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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.panelColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.appBorderColor),
        boxShadow: const [
          BoxShadow(
              blurRadius: 20,
              offset: Offset(0, 12),
              color: Color(0x12000000)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr('Оценки учеников'),
              style: TextStyle(
                  color: context.primaryTextColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
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
    final appState = context.appState;
    final studentGrades = appState.gradesForStudent(student.id);
    final avg = appState.averageGrade(studentGrades);

    return Row(
      children: [
        CircleAvatar(
          backgroundColor: const Color(0xFFFFEDD5),
          foregroundColor: const Color(0xFFEA580C),
          child: Text(student.initials),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(student.fullName,
                  style: TextStyle(
                      color: context.primaryTextColor, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                [
                  if ((student.schoolClass ?? '').isNotEmpty) student.schoolClass!,
                  if (studentGrades.isNotEmpty)
                    '${context.tr("Ср")}: ${avg.toStringAsFixed(1)}',
                ].where((item) => item.isNotEmpty).join(' • '),
                style: TextStyle(color: context.secondaryTextColor, fontSize: 13),
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
                backgroundColor: _gradeColor(value).withValues(alpha: 0.12),
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
                color: context.secondaryTextColor,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.panelColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.appBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr('Все выставленные оценки'),
              style: TextStyle(
                  color: context.primaryTextColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          if (grades.isEmpty)
            Text(context.tr('Оценки пока не выставлены.'),
                style: TextStyle(color: context.secondaryTextColor))
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
            color: _gradeColor(grade.value).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text('${grade.value}',
              style: TextStyle(
                  color: _gradeColor(grade.value),
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(student?.fullName ?? context.tr('Ученик'),
                  style: TextStyle(
                      color: context.primaryTextColor, fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(
                  '${context.tr(grade.subject)} • ${context.tr(grade.category)}',
                  style: TextStyle(
                      color: context.secondaryTextColor, fontSize: 13)),
            ],
          ),
        ),
        Text(MaterialLocalizations.of(context).formatShortDate(grade.createdAt),
            style: TextStyle(color: context.secondaryTextColor, fontSize: 12)),
      ],
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  const _MetricChip(
      {required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 24, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(title,
              style:
                  TextStyle(color: context.secondaryTextColor, fontSize: 13)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  const _EmptyState({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: context.panelColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: context.appBorderColor)),
      child: Column(children: [
        Icon(Icons.bar_chart_rounded, color: Color(0xFFF97316), size: 36),
        const SizedBox(height: 12),
        Text(title,
            style: TextStyle(
                color: context.primaryTextColor, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.secondaryTextColor)),
      ]),
    );
  }
}

Color _gradeColor(int grade) {
  if (grade >= 5) return const Color(0xFF059669);
  if (grade == 4) return const Color(0xFF2563EB);
  if (grade == 3) return const Color(0xFFD97706);
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
        borderSide: BorderSide(color: context.appBorderColor)),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: context.appBorderColor)),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFF97316), width: 1.4)),
  );
}
