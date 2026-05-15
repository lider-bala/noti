import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../models/school_models.dart';
import '../../widgets/contact_actions.dart';
import 'student_side_menu.dart';

class StudentHomeScreen extends StatelessWidget {
  final ValueChanged<StudentSection>? onNavigate;

  const StudentHomeScreen({
    super.key,
    this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final studentName = context.appState.currentUser?.fullName ??
        context.tr('Ученик не найден');
    final studentId = context.appState.currentUser?.id;
    final appState = context.appState;
    final student = appState.currentUser;
    final grades = studentId == null
        ? <GradeEntry>[]
        : appState.gradesForStudent(studentId);
    final assignments = studentId == null
        ? <HomeworkAssignment>[]
        : appState.assignmentsForStudent(studentId);
    final pendingAssignments = assignments
        .where(
          (assignment) =>
              assignment.requiresFile &&
              studentId != null &&
              appState.submissionForAssignment(
                    assignmentId: assignment.id,
                    studentId: studentId,
                  ) ==
                  null,
        )
        .length;
    final attendanceSessions = studentId == null
        ? <AttendanceSession>[]
        : appState.attendanceSessionsForStudent(studentId);
    final attended = attendanceSessions.where((session) {
      final entry = appState.attendanceEntryForStudent(
        session: session,
        studentId: studentId!,
      );
      return entry?.status == AttendanceStatusType.present ||
          entry?.status == AttendanceStatusType.late;
    }).length;
    final attendancePercent = attendanceSessions.isEmpty
        ? null
        : (attended / attendanceSessions.length * 100).round();
    final nextLesson = student?.schoolClass == null
        ? null
        : appState.lessonsForClass(student!.schoolClass!).firstOrNull;
    final upcomingLesson = _UpcomingLesson(
      subject: nextLesson?.subject ?? context.tr('Уроков пока нет'),
      teacher: nextLesson == null
          ? context.tr('Учитель не назначен')
          : appState.userById(nextLesson.teacherId)?.fullName ??
              context.tr('Учитель не назначен'),
      time: nextLesson?.timeRange ?? '—',
      room: nextLesson?.room ?? '—',
    );

    final stats = [
      _StatCardData(
        label: context.tr('Средний балл'),
        value: grades.isEmpty
            ? '—'
            : appState.averageGrade(grades).toStringAsFixed(1),
        icon: Icons.emoji_events_rounded,
        gradient: const [Color(0xFF34D399), Color(0xFF10B981)],
      ),
      _StatCardData(
        label: context.tr('Не сданных ДЗ'),
        value: '$pendingAssignments',
        icon: Icons.menu_book_rounded,
        gradient: const [Color(0xFFF97316), Color(0xFFEA580C)],
      ),
      _StatCardData(
        label: context.tr('Посещаемость'),
        value: attendancePercent == null ? '—' : '$attendancePercent%',
        icon: Icons.check_circle_rounded,
        gradient: const [Color(0xFF60A5FA), Color(0xFF3B82F6)],
      ),
    ];

    final homeworks = [
      for (final assignment in assignments.take(3))
        _HomeworkItem(
          subject: assignment.subject,
          title: assignment.title,
          dueDate: MaterialLocalizations.of(context)
              .formatShortDate(assignment.dueAt),
          status: studentId != null &&
                  context.appState.submissionForAssignment(
                        assignmentId: assignment.id,
                        studentId: studentId,
                      ) !=
                      null
              ? HomeworkStatus.completed
              : HomeworkStatus.pending,
          urgent: assignment.urgent,
        ),
    ];

    final today = MaterialLocalizations.of(context).formatFullDate(
      DateTime.now(),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _WelcomeCard(today: today, studentName: studentName),
        const SizedBox(height: 24),
        _SectionTitle(context.tr('common.stats')),
        const SizedBox(height: 12),
        _StatsGrid(stats: stats),
        const SizedBox(height: 24),
        _SectionTitle(context.tr('common.upcomingLesson')),
        const SizedBox(height: 12),
        _UpcomingLessonCard(lesson: upcomingLesson),
        const SizedBox(height: 24),
        _SectionTitle(context.tr('section.homework')),
        const SizedBox(height: 12),
        Column(
          children: [
            for (int i = 0; i < homeworks.length; i++) ...[
              if (i != 0) const SizedBox(height: 10),
              _HomeworkCard(item: homeworks[i]),
            ],
          ],
        ),
        const SizedBox(height: 24),
        _SectionTitle(context.tr('common.quickActions')),
        const SizedBox(height: 12),
        _QuickActionsRow(onNavigate: onNavigate),
        const SizedBox(height: 24),
        Builder(
          builder: (context) {
            final admin = appState.admins.isNotEmpty ? appState.admins.first : null;
            if (admin == null) return const SizedBox.shrink();
            return SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => openContactChat(
                  context: context,
                  contactId: admin.id,
                  name: admin.fullName,
                  subtitle: context.tr('Администратор'),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                icon: const Icon(Icons.chat_bubble_outline_rounded),
                label: Text(context.tr('Чат с админом')),
              ),
            );
          },
        ),
      ],
    );
  }
}

extension _FirstOrNullX<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class _WelcomeCard extends StatelessWidget {
  final String today;
  final String studentName;

  const _WelcomeCard({
    required this.today,
    required this.studentName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 170,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF3B82F6),
            Color(0xFF4F46E5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            blurRadius: 26,
            offset: Offset(0, 18),
            color: Color(0x33000000),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('auth.welcome'),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    studentName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${context.tr('common.today')}: $today',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF111827),
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _StatCardData {
  final String label;
  final String value;
  final IconData icon;
  final List<Color> gradient;

  const _StatCardData({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
  });
}

class _StatsGrid extends StatelessWidget {
  final List<_StatCardData> stats;

  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 1;
        if (constraints.maxWidth >= 960) {
          crossAxisCount = 3;
        } else if (constraints.maxWidth >= 640) {
          crossAxisCount = 2;
        }

        const spacing = 12.0;
        final itemWidth =
            (constraints.maxWidth - spacing * (crossAxisCount - 1)) /
                crossAxisCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (int i = 0; i < stats.length; i++)
              SizedBox(
                width: itemWidth,
                child: _StatCard(data: stats[i]),
              ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final _StatCardData data;

  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: data.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            blurRadius: 18,
            offset: Offset(0, 10),
            color: Color(0x26000000),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            data.icon,
            size: 22,
            color: Colors.white.withOpacity(0.9),
          ),
          const SizedBox(height: 10),
          Text(
            data.value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _UpcomingLesson {
  final String subject;
  final String teacher;
  final String time;
  final String room;

  const _UpcomingLesson({
    required this.subject,
    required this.teacher,
    required this.time,
    required this.room,
  });
}

class _UpcomingLessonCard extends StatelessWidget {
  final _UpcomingLesson lesson;

  const _UpcomingLessonCard({required this.lesson});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF3B82F6);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 20,
            offset: Offset(0, 10),
            color: Color(0x14000000),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.subject,
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lesson.teacher,
                      style: const TextStyle(
                        color: Color(0xFF4B5563),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: primary,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 16,
                color: Color(0xFF4B5563),
              ),
              const SizedBox(width: 6),
              Text(
                lesson.time,
                style: const TextStyle(
                  color: Color(0xFF4B5563),
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 18),
              const Icon(
                Icons.meeting_room_outlined,
                size: 16,
                color: Color(0xFF4B5563),
              ),
              const SizedBox(width: 6),
              Text(
                lesson.room,
                style: const TextStyle(
                  color: Color(0xFF4B5563),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum HomeworkStatus { pending, completed }

class _HomeworkItem {
  final String subject;
  final String title;
  final String dueDate;
  final HomeworkStatus status;
  final bool urgent;

  const _HomeworkItem({
    required this.subject,
    required this.title,
    required this.dueDate,
    required this.status,
    required this.urgent,
  });
}

class _HomeworkCard extends StatelessWidget {
  final _HomeworkItem item;

  const _HomeworkCard({required this.item});

  @override
  Widget build(BuildContext context) {
    Color borderColor;
    if (item.urgent) {
      borderColor = const Color(0xFFF97316);
    } else if (item.status == HomeworkStatus.completed) {
      borderColor = const Color(0xFF10B981);
    } else {
      borderColor = const Color(0xFFE5E7EB);
    }

    IconData trailingIcon;
    Color trailingColor;

    if (item.status == HomeworkStatus.completed) {
      trailingIcon = Icons.check_circle_rounded;
      trailingColor = const Color(0xFF10B981);
    } else if (item.urgent) {
      trailingIcon = Icons.error_outline_rounded;
      trailingColor = const Color(0xFFF97316);
    } else {
      trailingIcon = Icons.menu_book_rounded;
      trailingColor = const Color(0xFF3B82F6);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor.withOpacity(0.7), width: 2),
        boxShadow: const [
          BoxShadow(
            blurRadius: 16,
            offset: Offset(0, 10),
            color: Color(0x14000000),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      context.tr(item.subject),
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (item.urgent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEDD5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          context.tr('Срочно'),
                          style: TextStyle(
                            color: Color(0xFFF97316),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  context.tr(item.title),
                  style: const TextStyle(
                    color: Color(0xFF4B5563),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_month_rounded,
                      size: 14,
                      color: Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      context.trf('Сдать до {value}', {'value': item.dueDate}),
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Icon(
            trailingIcon,
            size: 24,
            color: trailingColor,
          ),
        ],
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  final ValueChanged<StudentSection>? onNavigate;

  const _QuickActionsRow({this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickActionData(
        title: context.tr('Расписание'),
        icon: Icons.calendar_month_rounded,
        gradient: const [Color(0xFF3B82F6), Color(0xFF4F46E5)],
        target: StudentSection.schedule,
      ),
      _QuickActionData(
        title: context.tr('Мои оценки'),
        icon: Icons.trending_up_rounded,
        gradient: const [Color(0xFF10B981), Color(0xFF14B8A6)],
        target: StudentSection.grades,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth >= 520 ? 2 : 1;
        const spacing = 12.0;
        final itemWidth =
            (constraints.maxWidth - spacing * (crossAxisCount - 1)) /
                crossAxisCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final action in actions)
              SizedBox(
                width: itemWidth,
                child: _QuickActionCard(
                  title: action.title,
                  icon: action.icon,
                  gradient: action.gradient,
                  onTap: () => onNavigate?.call(action.target),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _QuickActionData {
  final String title;
  final IconData icon;
  final List<Color> gradient;
  final StudentSection target;

  const _QuickActionData({
    required this.title,
    required this.icon,
    required this.gradient,
    required this.target,
  });
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback? onTap;

  const _QuickActionCard({
    required this.title,
    required this.icon,
    required this.gradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: const [
              BoxShadow(
                blurRadius: 18,
                offset: Offset(0, 10),
                color: Color(0x26000000),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 24,
                color: Colors.white.withOpacity(0.9),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
