import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../models/school_models.dart';
import 'parent_side_menu.dart';

class ParentHomeScreen extends StatelessWidget {
  final ValueChanged<ParentSection>? onNavigate;

  const ParentHomeScreen({
    super.key,
    this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final appState = context.appState;
    final parentName = appState.currentUser?.fullName ?? 'Токтосунова Гульмира';
    final child = appState.studentForParent(appState.currentUser);
    final grades =
        child == null ? <GradeEntry>[] : appState.gradesForStudent(child.id);
    final attendance = child == null
        ? <AttendanceSession>[]
        : appState.attendanceSessionsForStudent(child.id);
    final attended = child == null
        ? 0
        : attendance.where((session) {
            final entry = appState.attendanceEntryForStudent(
              session: session,
              studentId: child.id,
            );
            return entry?.status == AttendanceStatusType.present ||
                entry?.status == AttendanceStatusType.late;
          }).length;
    final attendancePercent =
        attendance.isEmpty ? 0 : (attended / attendance.length * 100).round();
    final assignments = child == null
        ? <HomeworkAssignment>[]
        : appState.assignmentsForStudent(child.id);
    final pendingHomework = child == null
        ? 0
        : assignments
            .where(
              (assignment) =>
                  assignment.requiresFile &&
                  appState.submissionForAssignment(
                        assignmentId: assignment.id,
                        studentId: child.id,
                      ) ==
                      null,
            )
            .length;

    final children = [
      _ChildInfo(
        name: child?.fullName ?? context.tr('Ученик не найден'),
        klass: child?.schoolClass ?? context.tr('Класс не указан'),
        avgGrade: appState.averageGrade(grades),
        attendance: attendancePercent,
        pendingHomework: pendingHomework,
      ),
    ];

    final stats = [
      _StatItem(
        label: context.tr('Средний балл'),
        value: grades.isEmpty
            ? '—'
            : appState.averageGrade(grades).toStringAsFixed(1),
        icon: Icons.trending_up_rounded,
        color1: Color(0xFF34D399),
        color2: Color(0xFF10B981),
      ),
      _StatItem(
        label: context.tr('Посещаемость'),
        value: attendance.isEmpty ? '—' : '$attendancePercent%',
        icon: Icons.check_circle_rounded,
        color1: Color(0xFF60A5FA),
        color2: Color(0xFF3B82F6),
      ),
      _StatItem(
        label: context.tr('Не сданных ДЗ'),
        value: '$pendingHomework',
        icon: Icons.error_outline_rounded,
        color1: Color(0xFFF97316),
        color2: Color(0xFFFB923C),
      ),
    ];

    final upcomingEvents = [
      if (child?.schoolClass != null)
        ...appState.meetingsForClass(child!.schoolClass!).map(
              (meeting) => _UpcomingEvent(
                title: meeting.title,
                date: _dateLabel(meeting.meetingAt),
                time: _timeLabel(meeting.meetingAt),
                location: meeting.location,
                type: _EventType.meeting,
              ),
            ),
      ...assignments
          .where((assignment) => assignment.kind == AssignmentKind.testWork)
          .map(
            (assignment) => _UpcomingEvent(
              title: assignment.title,
              date: _dateLabel(assignment.dueAt),
              time: _timeLabel(assignment.dueAt),
              location: assignment.subject,
              type: _EventType.exam,
            ),
          ),
    ];

    final recentGrades = grades
        .take(3)
        .map(
          (grade) => _RecentGrade(
            subject: grade.subject,
            grade: grade.value,
            date: MaterialLocalizations.of(context).formatShortDate(
              grade.createdAt,
            ),
          ),
        )
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WelcomeCard(parentName: parentName),
          const SizedBox(height: 16),
          for (int i = 0; i < children.length; i++) ...[
            if (i != 0) const SizedBox(height: 12),
            _ChildCard(child: children[i]),
          ],
          const SizedBox(height: 16),
          _QuickStatsRow(stats: stats),
          const SizedBox(height: 20),
          Text(
            context.tr('common.upcomingEvents'),
            style: TextStyle(
              color: Color(0xFF111827),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Column(
            children: [
              for (int i = 0; i < upcomingEvents.length; i++) ...[
                if (i != 0) const SizedBox(height: 10),
                _UpcomingEventCard(event: upcomingEvents[i]),
              ],
            ],
          ),
          const SizedBox(height: 20),
          Text(
            context.tr('common.recentGrades'),
            style: TextStyle(
              color: Color(0xFF111827),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          _RecentGradesCard(grades: recentGrades),
          const SizedBox(height: 20),
          _QuickActionsRow(onNavigate: onNavigate),
        ],
      ),
    );
  }
}

String _dateLabel(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day.$month.${date.year}';
}

String _timeLabel(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

class _WelcomeCard extends StatelessWidget {
  final String parentName;

  const _WelcomeCard({required this.parentName});

  @override
  Widget build(BuildContext context) {
    final formattedDate = MaterialLocalizations.of(context).formatFullDate(
      DateTime.now(),
    );

    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFF97316),
            Color(0xFFF59E0B),
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
            right: -60,
            top: -60,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Align(
              alignment: Alignment.bottomLeft,
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
                  const SizedBox(height: 4),
                  Text(
                    parentName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${context.tr('common.today')}: $formattedDate',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
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

class _ChildInfo {
  final String name;
  final String klass;
  final double avgGrade;
  final int attendance;
  final int pendingHomework;

  const _ChildInfo({
    required this.name,
    required this.klass,
    required this.avgGrade,
    required this.attendance,
    required this.pendingHomework,
  });
}

class _ChildCard extends StatelessWidget {
  final _ChildInfo child;

  const _ChildCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 18,
            offset: Offset(0, 10),
            color: Color(0x14000000),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFF97316),
                      Color(0xFFF59E0B),
                    ],
                  ),
                ),
                child: Center(
                  child: Text(
                    child.name
                        .split(' ')
                        .where((p) => p.isNotEmpty)
                        .map((p) => p[0])
                        .join(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    child.name,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.trf('Класс {value}', {'value': child.klass}),
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _ChildStatBox(
                value: child.avgGrade.toStringAsFixed(1),
                label: context.tr('Средний балл'),
                bg: const Color(0xFFD1FAE5),
                text: const Color(0xFF059669),
              ),
              const SizedBox(width: 8),
              _ChildStatBox(
                value: '${child.attendance}%',
                label: context.tr('Посещаемость'),
                bg: const Color(0xFFDBEAFE),
                text: const Color(0xFF2563EB),
              ),
              const SizedBox(width: 8),
              _ChildStatBox(
                value: '${child.pendingHomework}',
                label: context.tr('Не сдано ДЗ'),
                bg: const Color(0xFFFFEDD5),
                text: const Color(0xFFF97316),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChildStatBox extends StatelessWidget {
  final String value;
  final String label;
  final Color bg;
  final Color text;

  const _ChildStatBox({
    required this.value,
    required this.label,
    required this.bg,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: text,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: text.withOpacity(0.9),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color1;
  final Color color2;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color1,
    required this.color2,
  });
}

class _QuickStatsRow extends StatelessWidget {
  final List<_StatItem> stats;

  const _QuickStatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < stats.length; i++) ...[
          if (i != 0) const SizedBox(width: 8),
          Expanded(child: _StatCard(item: stats[i])),
        ],
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final _StatItem item;

  const _StatCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [item.color1, item.color2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            blurRadius: 18,
            offset: Offset(0, 10),
            color: Color(0x33000000),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            item.icon,
            color: Colors.white.withOpacity(0.9),
            size: 24,
          ),
          const SizedBox(height: 10),
          Text(
            item.value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

enum _EventType { meeting, exam, event }

class _UpcomingEvent {
  final String title;
  final String date;
  final String time;
  final String location;
  final _EventType type;

  const _UpcomingEvent({
    required this.title,
    required this.date,
    required this.time,
    required this.location,
    required this.type,
  });
}

class _UpcomingEventCard extends StatelessWidget {
  final _UpcomingEvent event;

  const _UpcomingEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    Color borderColor;
    Color bgColor;
    IconData icon;

    switch (event.type) {
      case _EventType.meeting:
        borderColor = const Color(0xFFE9D5FF);
        bgColor = const Color(0xFFF3E8FF);
        icon = Icons.person_outline;
        break;
      case _EventType.exam:
        borderColor = const Color(0xFFFCD34D);
        bgColor = const Color(0xFFFFEDD5);
        icon = Icons.menu_book_rounded;
        break;
      case _EventType.event:
        borderColor = const Color(0xFFBFDBFE);
        bgColor = const Color(0xFFDBEAFE);
        icon = Icons.notifications_active_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: const [
          BoxShadow(
            blurRadius: 14,
            offset: Offset(0, 8),
            color: Color(0x14000000),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 18,
              color: borderColor.withOpacity(0.9),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr(event.title),
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_month_rounded,
                      size: 14,
                      color: Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${context.tr(event.date)} • ${event.time}',
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  context.tr(event.location),
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

class _RecentGrade {
  final String subject;
  final int grade;
  final String date;

  const _RecentGrade({
    required this.subject,
    required this.grade,
    required this.date,
  });
}

class _RecentGradesCard extends StatelessWidget {
  final List<_RecentGrade> grades;

  const _RecentGradesCard({required this.grades});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 18,
            offset: Offset(0, 10),
            color: Color(0x14000000),
          ),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < grades.length; i++) ...[
            if (i != 0) const SizedBox(height: 10),
            _RecentGradeRow(grade: grades[i]),
          ],
        ],
      ),
    );
  }
}

class _RecentGradeRow extends StatelessWidget {
  final _RecentGrade grade;

  const _RecentGradeRow({required this.grade});

  @override
  Widget build(BuildContext context) {
    final bool isFive = grade.grade == 5;
    final Color bg = isFive ? const Color(0xFFD1FAE5) : const Color(0xFFDBEAFE);
    final Color textColor =
        isFive ? const Color(0xFF059669) : const Color(0xFF2563EB);

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              '${grade.grade}',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr(grade.subject),
              style: const TextStyle(
                color: Color(0xFF111827),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              context.tr(grade.date),
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  final ValueChanged<ParentSection>? onNavigate;

  const _QuickActionsRow({this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionCard(
            title: context.tr('Связаться с учителем'),
            icon: Icons.phone_in_talk_rounded,
            color1: Color(0xFFF97316),
            color2: Color(0xFFF59E0B),
            onTap: () => onNavigate?.call(ParentSection.teachers),
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _QuickActionCard(
            title: context.tr('Расписание'),
            icon: Icons.calendar_month_rounded,
            color1: Color(0xFF8B5CF6),
            color2: Color(0xFF6366F1),
            onTap: () => onNavigate?.call(ParentSection.schedule),
          ),
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color1;
  final Color color2;
  final VoidCallback? onTap;

  const _QuickActionCard({
    required this.title,
    required this.icon,
    required this.color1,
    required this.color2,
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
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [color1, color2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: const [
              BoxShadow(
                blurRadius: 18,
                offset: Offset(0, 10),
                color: Color(0x33000000),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: Colors.white.withOpacity(0.9),
                size: 26,
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
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
