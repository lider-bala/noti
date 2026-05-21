import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../models/school_models.dart';
import '../../models/user_role.dart';
import '../../widgets/app_theme.dart';

class ParentAttendanceScreen extends StatelessWidget {
  const ParentAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.appState;
    final child = appState.studentForParent(appState.currentUser);
    final records = child == null
        ? <_AttendanceRecord>[]
        : appState
            .attendanceSessionsForStudent(child.id)
            .map(
              (session) => _AttendanceRecord(
                session: session,
                entry: appState.attendanceEntryForStudent(
                  session: session,
                  studentId: child.id,
                )!,
              ),
            )
            .toList();

    final present = records
        .where((item) => item.entry.status == AttendanceStatusType.present)
        .length;
    final late = records
        .where((item) => item.entry.status == AttendanceStatusType.late)
        .length;
    final absent = records
        .where((item) => item.entry.status == AttendanceStatusType.absent)
        .length;
    final percent =
        records.isEmpty ? 0 : ((present + late) / records.length * 100).round();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(child: child),
          const SizedBox(height: 12),
          _ChildInfoCard(child: child),
          const SizedBox(height: 16),
          _OverallStatsCard(
            total: records.length,
            present: present,
            late: late,
            absent: absent,
            percent: percent,
          ),
          const SizedBox(height: 20),
          Text(
            context.tr('История посещаемости'),
            style: TextStyle(
              color: context.primaryTextColor,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          if (records.isEmpty)
            _EmptyState(
              title: context.tr('Записей пока нет'),
              subtitle: context.tr('Учитель ещё не сохранил посещаемость.'),
            )
          else
            Column(
              children: [
                for (var i = 0; i < records.length; i++) ...[
                  if (i != 0) const SizedBox(height: 10),
                  _AttendanceCard(record: records[i]),
                ],
              ],
            ),
          if (absent > 0) ...[
            const SizedBox(height: 16),
            _AbsencesAlert(absent: absent),
          ],
        ],
      ),
    );
  }
}

class _AttendanceRecord {
  final AttendanceSession session;
  final AttendanceEntry entry;

  const _AttendanceRecord({
    required this.session,
    required this.entry,
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
          colors: [Color(0xFF34D399), Color(0xFF14B8A6)],
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
            context.tr('Посещаемость'),
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
      decoration: _cardDecoration(context),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFFD1FAE5),
            foregroundColor: const Color(0xFF059669),
            child: Text(child?.initials ?? '—'),
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
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
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

class _OverallStatsCard extends StatelessWidget {
  final int total;
  final int present;
  final int late;
  final int absent;
  final int percent;

  const _OverallStatsCard({
    required this.total,
    required this.present,
    required this.late,
    required this.absent,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(18),
      decoration: _cardDecoration(context),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                context.tr('Общая статистика'),
                style: TextStyle(
                  color: context.primaryTextColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    total == 0 ? '—' : '$percent%',
                    style: TextStyle(
                      color: Color(0xFF059669),
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.tr('Посещаемость'),
                    style: TextStyle(
                      color: context.secondaryTextColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _SmallStatCard(
                  icon: Icons.check_circle_rounded,
                  color: const Color(0xFF059669),
                  value: '$present',
                  label: context.tr('Был'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SmallStatCard(
                  icon: Icons.access_time_rounded,
                  color: const Color(0xFFD97706),
                  value: '$late',
                  label: context.tr('Опоздал'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SmallStatCard(
                  icon: Icons.cancel_rounded,
                  color: const Color(0xFFDC2626),
                  value: '$absent',
                  label: context.tr('НБ'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SmallStatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _SmallStatCard({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  final _AttendanceRecord record;

  const _AttendanceCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final appState = context.appState;
    final lesson = appState.lessonById(record.session.lessonId);
    final status = record.entry.status;
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(context).copyWith(
        border: Border.all(color: color.withOpacity(0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_statusIcon(status), color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lesson == null
                      ? context.tr('Урок')
                      : context.tr(lesson.subject),
                  style: TextStyle(
                    color: context.primaryTextColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    MaterialLocalizations.of(context)
                        .formatShortDate(record.session.recordedAt),
                    lesson?.timeRange ?? '',
                    context.tr(appState.attendanceLabel(status)),
                  ].where((value) => value.isNotEmpty).join(' • '),
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (status == AttendanceStatusType.absent) ...[
                  const SizedBox(height: 6),
                  Text(
                    context.trf(
                      'Причина: {value}',
                      {
                        'value':
                            appState.absenceReasonLabel(record.entry.reason)
                      },
                    ),
                    style: TextStyle(
                      color: context.secondaryTextColor,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AbsencesAlert extends StatelessWidget {
  final int absent;

  const _AbsencesAlert({required this.absent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEFCE8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFCA8A04),
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.trf(
                'За текущий период зафиксировано {value} пропуска. Пожалуйста, следите за посещаемостью ребёнка.',
                {'value': '$absent'},
              ),
              style: const TextStyle(
                color: Color(0xFF854D0E),
                fontSize: 13,
              ),
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
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(context),
      child: Column(
        children: [
          Icon(Icons.inbox_rounded, color: Color(0xFF94A3B8), size: 30),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
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

IconData _statusIcon(AttendanceStatusType status) {
  switch (status) {
    case AttendanceStatusType.present:
      return Icons.check_circle_rounded;
    case AttendanceStatusType.late:
      return Icons.access_time_rounded;
    case AttendanceStatusType.absent:
      return Icons.cancel_rounded;
  }
}

Color _statusColor(AttendanceStatusType status) {
  switch (status) {
    case AttendanceStatusType.present:
      return const Color(0xFF059669);
    case AttendanceStatusType.late:
      return const Color(0xFFD97706);
    case AttendanceStatusType.absent:
      return const Color(0xFFDC2626);
  }
}

BoxDecoration _cardDecoration(BuildContext context) {
  return BoxDecoration(
    color: context.panelColor,
    borderRadius: BorderRadius.circular(22),
    border: Border.all(color: context.appBorderColor),
    boxShadow: const [
      BoxShadow(
        blurRadius: 18,
        offset: Offset(0, 10),
        color: Color(0x12000000),
      ),
    ],
  );
}
