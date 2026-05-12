import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../models/school_models.dart';
import '../../models/user_role.dart';

class StudentGradesScreen extends StatelessWidget {
  const StudentGradesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.appState;
    final student = appState.currentUser;

    if (student == null || student.role != UserRole.student) {
      return _EmptyState(
        title: context.tr('Ученик не найден'),
        subtitle: context.tr('Войдите под аккаунтом ученика.'),
      );
    }

    final grades = appState.gradesForStudent(student.id);
    final subjects = _groupBySubject(appState, grades);
    final average = appState.averageGrade(grades);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeaderCard(student: student),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _StatCard(
                title: context.tr('Средний балл'),
                value: grades.isEmpty ? '—' : average.toStringAsFixed(1),
                icon: Icons.emoji_events_rounded,
                color: const Color(0xFF059669),
              ),
              _StatCard(
                title: context.tr('Предметов'),
                value: '${subjects.length}',
                icon: Icons.menu_book_rounded,
                color: const Color(0xFF2563EB),
              ),
              _StatCard(
                title: context.tr('Всего оценок'),
                value: '${grades.length}',
                icon: Icons.assignment_turned_in_rounded,
                color: const Color(0xFF7C3AED),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            context.tr('По предметам'),
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          if (subjects.isEmpty)
            _EmptyState(
              title: context.tr('Оценок пока нет'),
              subtitle: context
                  .tr('Оценки появятся здесь после сохранения учителем.'),
            )
          else
            Column(
              children: [
                for (var i = 0; i < subjects.length; i++) ...[
                  if (i != 0) const SizedBox(height: 12),
                  _SubjectCard(item: subjects[i]),
                ],
              ],
            ),
          const SizedBox(height: 24),
          Text(
            context.tr('Недавние оценки'),
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          if (grades.isEmpty)
            _EmptyState(
              title: context.tr('Недавних оценок нет'),
              subtitle: context.tr('Новые оценки будут показаны первыми.'),
            )
          else
            Column(
              children: [
                for (var i = 0; i < grades.take(6).length; i++) ...[
                  if (i != 0) const SizedBox(height: 10),
                  _RecentGradeCard(item: grades[i]),
                ],
              ],
            ),
        ],
      ),
    );
  }

  List<_SubjectGrades> _groupBySubject(
    AppState appState,
    List<GradeEntry> grades,
  ) {
    final grouped = <String, List<GradeEntry>>{};
    for (final grade in grades) {
      grouped.putIfAbsent(grade.subject, () => []).add(grade);
    }
    final subjects = grouped.entries
        .map(
          (entry) => _SubjectGrades(
            name: entry.key,
            grades: entry.value,
            average: appState.averageGrade(entry.value),
          ),
        )
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return subjects;
  }
}

class _HeaderCard extends StatelessWidget {
  final AppUser student;

  const _HeaderCard({required this.student});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            blurRadius: 26,
            offset: Offset(0, 18),
            color: Color(0x26000000),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('Мои оценки'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            [
              student.fullName,
              if ((student.schoolClass ?? '').isNotEmpty)
                context.tr('Класс ${student.schoolClass}'),
            ].join(' • '),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectGrades {
  final String name;
  final double average;
  final List<GradeEntry> grades;

  const _SubjectGrades({
    required this.name,
    required this.average,
    required this.grades,
  });
}

class _SubjectCard extends StatelessWidget {
  final _SubjectGrades item;

  const _SubjectCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _gradeColor(item.average.round()).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  item.average.toStringAsFixed(1),
                  style: TextStyle(
                    color: _gradeColor(item.average.round()),
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(item.name),
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      context.tr('${item.grades.length} оценок'),
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: item.grades
                .take(8)
                .map((grade) => _GradeChip(value: grade.value))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _RecentGradeCard extends StatelessWidget {
  final GradeEntry item;

  const _RecentGradeCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final teacher = context.appState.userById(item.teacherId);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GradeBadge(value: item.value),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr(item.subject),
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  context.tr(item.category),
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 13,
                  ),
                ),
                if (item.comment.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    item.comment,
                    style: const TextStyle(
                      color: Color(0xFF1D4ED8),
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  [
                    MaterialLocalizations.of(context)
                        .formatShortDate(item.createdAt),
                    teacher?.fullName ?? '',
                  ].where((value) => value.isNotEmpty).join(' • '),
                  style: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 12,
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

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 210,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
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
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
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

class _GradeChip extends StatelessWidget {
  final int value;

  const _GradeChip({required this.value});

  @override
  Widget build(BuildContext context) {
    return _GradeBadge(value: value, size: 32);
  }
}

class _GradeBadge extends StatelessWidget {
  final int value;
  final double size;

  const _GradeBadge({
    required this.value,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _gradeColor(value).withOpacity(0.12),
        borderRadius: BorderRadius.circular(size > 36 ? 14 : 10),
      ),
      child: Text(
        '$value',
        style: TextStyle(
          color: _gradeColor(value),
          fontWeight: FontWeight.w800,
          fontSize: size > 36 ? 20 : 14,
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
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          const Icon(
            Icons.inbox_rounded,
            color: Color(0xFF94A3B8),
            size: 32,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
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

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(22),
    border: Border.all(color: const Color(0xFFE5E7EB)),
    boxShadow: const [
      BoxShadow(
        blurRadius: 18,
        offset: Offset(0, 10),
        color: Color(0x12000000),
      ),
    ],
  );
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
