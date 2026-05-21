import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../models/school_models.dart';
import '../../widgets/contact_actions.dart';
import '../../widgets/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final formattedDate = MaterialLocalizations.of(context).formatFullDate(now);
    final appState = context.appState;
    final teacher = appState.currentUser;
    final teacherName = teacher?.fullName ?? context.tr('Учитель не найден');
    final teacherId = teacher?.id;
    final classes = teacherId == null
        ? <SchoolClass>[]
        : appState.classesForTeacher(teacherId);
    final classIds = classes.map((item) => item.id).toSet();
    final studentsCount = appState.students
        .where((student) => classIds.contains(student.schoolClass))
        .length;
    final assignments = teacherId == null
        ? <HomeworkAssignment>[]
        : appState.assignmentsForTeacher(teacherId);
    final activeAssignments =
        assignments.where((item) => item.dueAt.isAfter(now)).length;
    final teacherGrades = teacherId == null
        ? <GradeEntry>[]
        : appState.gradesForTeacher(teacherId);
    final nextLesson = teacherId == null
        ? null
        : appState.lessonsForTeacher(teacherId).firstOrNull;

    final upcomingClass = {
      'subject': nextLesson?.subject ?? 'Уроков пока нет',
      'class': nextLesson?.classId ?? '—',
      'time': nextLesson?.timeRange ?? '—',
      'room': nextLesson?.room ?? '—',
    };

    final stats = [
      {
        'label': 'Всего учеников',
        'value': '$studentsCount',
        'color1': const Color(0xFF60A5FA),
        'color2': const Color(0xFF3B82F6),
      },
      {
        'label': 'Активных заданий',
        'value': '$activeAssignments',
        'color1': const Color(0xFF34D399),
        'color2': const Color(0xFF10B981),
      },
      {
        'label': 'Средний балл',
        'value': teacherGrades.isEmpty
            ? '—'
            : appState.averageGrade(teacherGrades).toStringAsFixed(1),
        'color1': const Color(0xFFA855F7),
        'color2': const Color(0xFF8B5CF6),
      },
    ];

    final recentActivity = [
      for (final assignment in assignments.take(2))
        {
          'title': assignment.title,
          'class': assignment.classId,
          'time': MaterialLocalizations.of(context).formatShortDate(
            assignment.createdAt,
          ),
          'bg': const Color(0xFFDCFCE7),
          'fg': const Color(0xFF059669),
          'icon': Icons.menu_book_rounded,
        },
      for (final grade in teacherGrades.take(2))
        {
          'title': '${grade.subject}: ${grade.value}',
          'class': grade.classId,
          'time': MaterialLocalizations.of(context).formatShortDate(
            grade.createdAt,
          ),
          'bg': const Color(0xFFDBEAFE),
          'fg': const Color(0xFF2563EB),
          'icon': Icons.trending_up_rounded,
        },
      if (assignments.isEmpty && teacherGrades.isEmpty)
        {
          'title': 'Активности пока нет',
          'class': classes.isEmpty ? '—' : classes.first.name,
          'time': formattedDate,
          'bg': const Color(0xFFFFEDD5),
          'fg': const Color(0xFFEA580C),
          'icon': Icons.info_outline_rounded,
        },
    ];

    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WelcomeCard(
            formattedDate: formattedDate,
            teacherName: teacherName,
          ),
          SizedBox(height: 24),
          Text(
            context.tr('common.upcomingLesson'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: context.primaryTextColor,
            ),
          ),
          SizedBox(height: 10),
          _UpcomingClassCard(upcomingClass: upcomingClass),
          SizedBox(height: 24),
          Text(
            context.tr('common.stats'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: context.primaryTextColor,
            ),
          ),
          SizedBox(height: 10),
          _StatsGrid(stats: stats),
          SizedBox(height: 24),
          Text(
            context.tr('common.recentActivity'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: context.primaryTextColor,
            ),
          ),
          SizedBox(height: 10),
          Column(
            children: [
              for (final item in recentActivity)
                Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: _ActivityCard(data: item),
                ),
            ],
          ),
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
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                  icon: Icon(Icons.chat_bubble_outline_rounded),
                  label: Text(context.tr('Чат с админом')),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

extension _FirstOrNullX<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class _WelcomeCard extends StatelessWidget {
  final String teacherName;
  final String formattedDate;

  const _WelcomeCard({
    required this.teacherName,
    required this.formattedDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 160),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2ECC71),
            Color(0xFF10B981),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            blurRadius: 32,
            offset: Offset(0, 20),
            color: Color(0x40000000),
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
                color: Colors.white.withOpacity(0.14),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.tr('auth.welcome'),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    teacherName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${context.tr('common.today')}: $formattedDate',
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

class _UpcomingClassCard extends StatelessWidget {
  final Map<String, String> upcomingClass;

  const _UpcomingClassCard({
    required this.upcomingClass,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: context.panelColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.appBorderColor),
        boxShadow: const [
          BoxShadow(
            blurRadius: 24,
            offset: Offset(0, 14),
            color: Color(0x12000000),
          ),
        ],
      ),
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(upcomingClass['subject'] ?? ''),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.primaryTextColor,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      context.trf(
                        'Класс {value}',
                        {'value': upcomingClass['class'] ?? ''},
                      ),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: context.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF2ECC71).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.calendar_today_rounded,
                  color: Color(0xFF2ECC71),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 18,
                    color: context.secondaryTextColor,
                  ),
                  SizedBox(width: 6),
                  Text(
                    upcomingClass['time'] ?? '',
                    style: TextStyle(
                      fontSize: 13,
                      color: context.secondaryTextColor,
                    ),
                  ),
                ],
              ),
              SizedBox(width: 24),
              Row(
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    size: 18,
                    color: context.secondaryTextColor,
                  ),
                  SizedBox(width: 6),
                  Text(
                    context.tr(upcomingClass['room'] ?? ''),
                    style: TextStyle(
                      fontSize: 13,
                      color: context.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final List<Map<String, Object>> stats;

  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final stat in stats) ...[
          Expanded(
            child: _StatCard(
              label: context.tr(stat['label'] as String),
              value: stat['value'] as String,
              color1: stat['color1'] as Color,
              color2: stat['color2'] as Color,
            ),
          ),
          if (stat != stats.last) SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color1;
  final Color color2;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color1,
    required this.color2,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 117,
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [color1, color2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            blurRadius: 20,
            offset: Offset(0, 10),
            color: Color(0x26000000),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.show_chart_rounded,
            color: Colors.white70,
            size: 22,
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final Map<String, Object> data;

  const _ActivityCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final bg = data['bg'] as Color;
    final fg = data['fg'] as Color;
    final icon = data['icon'] as IconData;

    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.panelColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.appBorderColor),
        boxShadow: const [
          BoxShadow(
            blurRadius: 18,
            offset: Offset(0, 10),
            color: Color(0x12000000),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: fg,
              size: 22,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr(data['title'] as String),
                  style: TextStyle(
                    color: context.primaryTextColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '${context.tr(data['class'] as String)} • ${context.tr(data['time'] as String)}',
                  style: TextStyle(
                    color: context.secondaryTextColor,
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
