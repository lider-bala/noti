import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../models/school_models.dart';
import '../../models/user_role.dart';
import '../../widgets/app_theme.dart';

class ParentHomeworkScreen extends StatelessWidget {
  const ParentHomeworkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.appState;
    final child = appState.studentForParent(appState.currentUser);
    final homeworks = child == null
        ? const <HomeworkAssignment>[]
        : appState.assignmentsForStudent(child.id);
    final submitted = homeworks
        .where(
          (assignment) =>
              child != null &&
              appState.submissionForAssignment(
                    assignmentId: assignment.id,
                    studentId: child.id,
                  ) !=
                  null,
        )
        .length;
    final pending = homeworks.length - submitted;
    final urgent = homeworks.where(_isUrgent).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(child: child),
          const SizedBox(height: 12),
          _ChildInfoCard(child: child),
          const SizedBox(height: 16),
          _StatsRow(
            pending: pending,
            urgent: urgent,
            submitted: submitted,
          ),
          const SizedBox(height: 16),
          if (homeworks.isEmpty)
            _InfoAlert(
              text: context.tr(
                'Когда учитель назначит задание, контрольную или файл для сдачи, оно появится здесь.',
              ),
            )
          else
            Column(
              children: [
                for (int i = 0; i < homeworks.length; i++) ...[
                  if (i != 0) const SizedBox(height: 10),
                  _HomeworkCard(
                    item: homeworks[i],
                    submission: child == null
                        ? null
                        : appState.submissionForAssignment(
                            assignmentId: homeworks[i].id,
                            studentId: child.id,
                          ),
                  ),
                ],
              ],
            ),
          const SizedBox(height: 16),
          _InfoAlert(
            text: context.tr(
              'Родитель видит те же задания и контрольные, которые учитель назначил классу ребёнка.',
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final AppUser? child;

  const _Header({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF14B8A6), Color(0xFF06B6D4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            blurRadius: 22,
            offset: Offset(0, 12),
            color: Color(0x33000000),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('Домашние задания'),
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
      decoration: BoxDecoration(
        color: context.panelColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.appBorderColor),
        boxShadow: const [
          BoxShadow(
            blurRadius: 18,
            offset: Offset(0, 10),
            color: Color(0x14000000),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF97316), Color(0xFFFBBF24)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                child?.initials ?? '-',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  child?.fullName ?? context.tr('Ученик не найден'),
                  style: TextStyle(
                    color: context.primaryTextColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  child?.schoolClass == null
                      ? context.tr('Класс не указан')
                      : context.tr('Класс ${child!.schoolClass}'),
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

class _StatsRow extends StatelessWidget {
  final int pending;
  final int urgent;
  final int submitted;

  const _StatsRow({
    required this.pending,
    required this.urgent,
    required this.submitted,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            value: '$pending',
            label: context.tr('Не сдано'),
            bgColor: const Color(0xFFFFF7ED),
            borderColor: const Color(0xFFFEECDC),
            textColor: const Color(0xFFEA580C),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            value: '$urgent',
            label: context.tr('Срочные'),
            bgColor: context.isDarkTheme ? const Color(0xFF7F1D1D) : const Color(0xFFFEF2F2),
            borderColor: context.isDarkTheme ? const Color(0xFF991B1B) : const Color(0xFFFECACA),
            textColor: const Color(0xFFDC2626),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            value: '$submitted',
            label: context.tr('Выполнено'),
            bgColor: context.isDarkTheme ? const Color(0xFF14532D) : const Color(0xFFECFDF5),
            borderColor: context.isDarkTheme ? const Color(0xFF065F46) : const Color(0xFFD1FAE5),
            textColor: const Color(0xFF059669),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color bgColor;
  final Color borderColor;
  final Color textColor;

  const _StatCard({
    required this.value,
    required this.label,
    required this.bgColor,
    required this.borderColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: textColor,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeworkCard extends StatelessWidget {
  final HomeworkAssignment item;
  final HomeworkSubmission? submission;

  const _HomeworkCard({
    required this.item,
    required this.submission,
  });

  @override
  Widget build(BuildContext context) {
    final teacher = context.appState.userById(item.teacherId);
    final submitted = submission != null;

    return Container(
      decoration: BoxDecoration(
        color: context.panelColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: submitted
              ? const Color(0xFF10B981).withOpacity(0.35)
              : _isUrgent(item)
                  ? const Color(0xFFF97316).withOpacity(0.35)
                  : context.appBorderColor,
          width: 2,
        ),
        boxShadow: const [
          BoxShadow(
            blurRadius: 18,
            offset: Offset(0, 10),
            color: Color(0x14000000),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
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
                      ? (context.isDarkTheme ? const Color(0xFF3B0764) : const Color(0xFFF3E8FF))
                      : (context.isDarkTheme ? const Color(0xFF1E3A5F) : const Color(0xFFDBEAFE)),
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
                          style: TextStyle(
                            color: context.primaryTextColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        if (item.kind == AssignmentKind.testWork)
                          Text(
                            context.tr('Контрольная работа'),
                            style: const TextStyle(
                              color: Color(0xFF7C3AED),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.tr(item.title),
                      style: TextStyle(
                        color: context.primaryTextColor,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      teacher?.fullName ?? context.tr('Учитель'),
                      style: TextStyle(
                        color: context.secondaryTextColor,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                submitted
                    ? Icons.check_circle_rounded
                    : Icons.access_time_rounded,
                color: submitted
                    ? const Color(0xFF10B981)
                    : const Color(0xFFF97316),
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: context.appBorderColor, height: 1),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _InlineInfo(
                icon: Icons.calendar_today_rounded,
                text: context
                    .trf('Сдать до {value}', {'value': _dateLabel(item.dueAt)}),
              ),
              if (item.requiresFile)
                _InlineInfo(
                  icon: Icons.attach_file_rounded,
                  text: context.tr('Файлы'),
                ),
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: submitted
                      ? (context.isDarkTheme ? const Color(0xFF14532D) : const Color(0xFFD1FAE5))
                      : (context.isDarkTheme ? const Color(0xFF78350F) : const Color(0xFFFFEDD5)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  submitted
                      ? submission!.late
                          ? '${context.tr('Сдано поздно')}: ${submission!.fileName}'
                          : '${context.tr('Сдано')}: ${submission!.fileName}'
                      : context.tr('Не сдано'),
                  style: TextStyle(
                    color: submitted
                        ? const Color(0xFF059669)
                        : const Color(0xFFEA580C),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (submitted && submission!.grade != null)
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: context.isDarkTheme ? const Color(0xFF14532D) : const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${context.tr('Оценка')}: ${submission!.grade}',
                    style: const TextStyle(
                      color: Color(0xFF059669),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              if (submitted && (submission!.gradeComment ?? '').isNotEmpty)
                Text(
                  submission!.gradeComment!,
                  style: TextStyle(
                    color: context.secondaryTextColor,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ],
      ),
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
          style: TextStyle(color: context.secondaryTextColor, fontSize: 13),
        ),
      ],
    );
  }
}

class _InfoAlert extends StatelessWidget {
  final String text;

  const _InfoAlert({required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkTheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E3A5C) : const Color(0xFFE0F2FE),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF2563EB).withOpacity(0.4) : const Color(0xFFBFDBFE),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isDark ? (context.isDarkTheme ? const Color(0xFF1E40AF) : const Color(0xFFBFDBFE)) : const Color(0xFF1E3A8A),
                fontSize: 13,
                height: 1.35,
              ),
            ),
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

bool _isUrgent(HomeworkAssignment assignment) {
  return assignment.urgent ||
      assignment.dueAt.difference(DateTime.now()).inHours <= 48;
}

String _dateLabel(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day.$month.${date.year}';
}
