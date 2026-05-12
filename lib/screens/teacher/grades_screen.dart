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

class _GradesScreenState extends State<GradesScreen> {
  final _categoryController = TextEditingController(text: 'Оценка за урок');
  final _commentController = TextEditingController();

  String? _selectedClassId;
  String? _selectedLessonId;
  final Map<String, int> _selectedGrades = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncSelection();
  }

  @override
  void dispose() {
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
        backgroundColor: const Color(0xFFB91C1C),
      );
      return;
    }
    if (_selectedGrades.isEmpty) {
      showAppSnackBar(
        context,
        context.tr('Выберите хотя бы одну оценку.'),
        backgroundColor: const Color(0xFFB91C1C),
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
          success ? const Color(0xFF047857) : const Color(0xFFB91C1C),
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

    final selectedClass =
        classes.firstWhere((item) => item.id == _selectedClassId);
    final lessons = appState
        .lessonsForTeacher(teacher.id)
        .where((lesson) => lesson.classId == selectedClass.id)
        .toList();
    final selectedLesson = lessons.isEmpty
        ? null
        : lessons.firstWhere(
            (item) => item.id == _selectedLessonId,
            orElse: () => lessons.first,
          );
    final students = appState.studentsForClass(selectedClass.id);
    final classGrades = appState.gradesForClass(selectedClass.id);
    final teacherGrades = appState.gradesForTeacher(teacher.id);
    final average = appState.averageGrade(classGrades);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(
          title: context.tr('Журнал оценок'),
          subtitle: context.tr(
            'Выберите класс и урок, поставьте оценки ученикам и сохраните журнал.',
          ),
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 980;
            final classField = AppSelectField<String>(
              value: selectedClass.id,
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
              onChanged: _changeClass,
            );
            final lessonField = AppSelectField<String>(
              value: selectedLesson?.id,
              label: context.tr('Урок'),
              icon: Icons.event_note_rounded,
              options: lessons
                  .map(
                    (lesson) => AppSelectOption<String>(
                      value: lesson.id,
                      label:
                          '${context.tr(lesson.subject)} • ${lesson.timeRange}',
                    ),
                  )
                  .toList(),
              onChanged: _changeLesson,
            );

            if (stacked) {
              return Column(
                children: [
                  classField,
                  const SizedBox(height: 12),
                  lessonField,
                ],
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
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 760;
            final categoryField = TextField(
              controller: _categoryController,
              decoration: _inputDecoration(context, context.tr('Тип оценки')),
            );
            final commentField = TextField(
              controller: _commentController,
              decoration: _inputDecoration(context, context.tr('Комментарий')),
            );
            if (stacked) {
              return Column(
                children: [
                  categoryField,
                  const SizedBox(height: 12),
                  commentField,
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: categoryField),
                const SizedBox(width: 12),
                Expanded(child: commentField),
              ],
            );
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
            _MetricChip(
              title: context.tr('Средний балл класса'),
              value: classGrades.isEmpty ? '—' : average.toStringAsFixed(1),
              color: const Color(0xFF7C3AED),
            ),
            _MetricChip(
              title: context.tr('Мои оценки всего'),
              value: '${teacherGrades.length}',
              color: const Color(0xFFD97706),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (selectedLesson == null)
          _EmptyState(
            title: context.tr('Нет уроков для выбранного класса'),
            subtitle: context.tr('Сначала добавьте уроки в админ-панели.'),
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
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            icon: const Icon(Icons.save_rounded),
            label: Text(context.tr('Сохранить оценки')),
          ),
        ),
        const SizedBox(height: 16),
        _RecentGradesPanel(grades: teacherGrades.take(8).toList()),
      ],
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB)),
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
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < students.length; i++) ...[
            if (i != 0) const Divider(height: 22, color: Color(0xFFF3F4F6)),
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
          backgroundColor: const Color(0xFFFFEDD5),
          foregroundColor: const Color(0xFFEA580C),
          child: Text(student.initials),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                student.fullName,
                style: const TextStyle(
                  color: Color(0xFF111827),
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
                style: const TextStyle(
                  color: Color(0xFF6B7280),
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
                icon: const Icon(Icons.close_rounded),
                color: const Color(0xFF9CA3AF),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('Последние выставленные оценки'),
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          if (grades.isEmpty)
            Text(
              context.tr('Оценки пока не выставлены.'),
              style: const TextStyle(color: Color(0xFF6B7280)),
            )
          else
            Column(
              children: [
                for (var i = 0; i < grades.length; i++) ...[
                  if (i != 0)
                    const Divider(height: 22, color: Color(0xFFF3F4F6)),
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
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                student?.fullName ?? context.tr('Ученик'),
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${context.tr(grade.subject)} • ${context.tr(grade.category)}',
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        Text(
          MaterialLocalizations.of(context).formatShortDate(grade.createdAt),
          style: const TextStyle(
            color: Color(0xFF9CA3AF),
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
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF4B5563),
              fontSize: 13,
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.bar_chart_rounded,
            color: Color(0xFFF97316),
            size: 36,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF6B7280)),
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
