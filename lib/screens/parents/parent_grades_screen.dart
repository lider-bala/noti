import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../models/school_models.dart';
import '../../models/user_role.dart';

class ParentGradesScreen extends StatelessWidget {
  const ParentGradesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.appState;
    final child = appState.studentForParent(appState.currentUser);
    final grades =
        child == null ? <GradeEntry>[] : appState.gradesForStudent(child.id);
    final average = appState.averageGrade(grades);
    final subjects = _groupBySubject(appState, grades);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(child: child),
          const SizedBox(height: 12),
          _ChildInfoCard(child: child),
          const SizedBox(height: 16),
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
          const SizedBox(height: 20),
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
              subtitle: context.tr('Учитель ещё не выставил оценки.'),
            )
          else
            Column(
              children: [
                for (var i = 0; i < subjects.length; i++) ...[
                  if (i != 0) const SizedBox(height: 10),
                  _SubjectCard(subject: subjects[i]),
                ],
              ],
            ),
          const SizedBox(height: 20),
          Text(
            context.tr('Четвертные оценки'),
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Builder(
            builder: (context) {
              if (child == null) return const SizedBox.shrink();
              final quarterGrades = appState.quarterGradesForStudent(child.id);
              if (quarterGrades.isEmpty) {
                return _EmptyState(
                  title: context.tr('Четвертных оценок нет'),
                  subtitle: context.tr('Четвертные оценки появятся после выставления учителем.'),
                );
              }
              return Column(
                children: [
                  for (final qg in quarterGrades)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _gradeColor(qg.value).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${qg.value}',
                              style: TextStyle(
                                color: _gradeColor(qg.value),
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
                                  context.tr(qg.subject),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                Text(
                                  '${context.tr("Четверть")} ${qg.quarter} • ${context.tr("Ср")}. ${qg.averageGrade.toStringAsFixed(1)}',
                                  style: const TextStyle(
                                    color: Color(0xFF6B7280),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          Text(
            context.tr('Последние оценки'),
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          if (grades.isEmpty)
            _EmptyState(
              title: context.tr('Новых оценок нет'),
              subtitle: context
                  .tr('Новые оценки появятся после сохранения учителем.'),
            )
          else
            Column(
              children: [
                for (var i = 0; i < grades.take(8).length; i++) ...[
                  if (i != 0) const SizedBox(height: 10),
                  _RecentGradeCard(item: grades[i]),
                ],
              ],
            ),
        ],
      ),
    );
  }

  List<_SubjectPerformance> _groupBySubject(
    AppState appState,
    List<GradeEntry> grades,
  ) {
    final grouped = <String, List<GradeEntry>>{};
    for (final grade in grades) {
      grouped.putIfAbsent(grade.subject, () => []).add(grade);
    }
    return grouped.entries
        .map(
          (entry) => _SubjectPerformance(
            name: entry.key,
            avgGrade: appState.averageGrade(entry.value),
            grades: entry.value,
          ),
        )
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }
}

class _SubjectPerformance {
  final String name;
  final double avgGrade;
  final List<GradeEntry> grades;

  const _SubjectPerformance({
    required this.name,
    required this.avgGrade,
    required this.grades,
  });
}

class _Header extends StatelessWidget {
  final AppUser? child;

  const _Header({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFFA855F7), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            blurRadius: 22,
            offset: Offset(0, 12),
            color: Color(0x26000000),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('Успеваемость'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _childLabel(context, child),
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _ChildInfoCard extends StatelessWidget {
  final AppUser? child;

  const _ChildInfoCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFFFFEDD5),
            foregroundColor: const Color(0xFFEA580C),
            child: Text(child?.initials ?? '—'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  child?.fullName ?? context.tr('Ученик не найден'),
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  child?.schoolClass == null
                      ? context.tr('Класс не указан')
                      : context.tr('Класс ${child!.schoolClass}'),
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
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final _SubjectPerformance subject;

  const _SubjectCard({required this.subject});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              _AverageBadge(value: subject.avgGrade),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(subject.name),
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.tr('${subject.grades.length} оценок'),
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
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: subject.grades
                .take(8)
                .map((grade) => _GradeBadge(value: grade.value, size: 32))
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
          const SizedBox(width: 10),
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
                const SizedBox(height: 2),
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

class _AverageBadge extends StatelessWidget {
  final double value;

  const _AverageBadge({required this.value});

  @override
  Widget build(BuildContext context) {
    final rounded = value.round();
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _gradeColor(rounded).withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        value.toStringAsFixed(1),
        style: TextStyle(
          color: _gradeColor(rounded),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
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
          fontSize: size > 36 ? 20 : 14,
          fontWeight: FontWeight.w800,
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
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          const Icon(Icons.inbox_rounded, color: Color(0xFF94A3B8), size: 30),
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

String _childLabel(BuildContext context, AppUser? child) {
  if (child == null) {
    return context.tr('Ученик не найден');
  }
  return [
    child.fullName,
    if ((child.schoolClass ?? '').isNotEmpty)
      context.tr('Класс ${child.schoolClass}'),
  ].join(' • ');
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
