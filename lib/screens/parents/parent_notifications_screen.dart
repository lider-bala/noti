import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../models/school_models.dart';
import '../../widgets/app_theme.dart';

class ParentNotificationsScreen extends StatefulWidget {
  const ParentNotificationsScreen({super.key});

  @override
  State<ParentNotificationsScreen> createState() =>
      _ParentNotificationsScreenState();
}

class _ParentNotificationsScreenState extends State<ParentNotificationsScreen> {
  final Set<int> _readNotificationIds = {};
  _NotificationFilter _selectedFilter = _NotificationFilter.all;

  void _markRead(int notificationId) {
    setState(() => _readNotificationIds.add(notificationId));
  }

  void _markAllRead(List<_ParentNotification> notifications) {
    setState(() {
      _readNotificationIds.addAll(
        notifications.map((notification) => notification.id),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.appState;
    final child = appState.studentForParent(appState.currentUser);
    final meetings = child?.schoolClass == null
        ? []
        : appState.meetingsForClass(child!.schoolClass!);
    final assignments =
        child == null ? [] : appState.assignmentsForStudent(child.id);
    final grades = child == null ? [] : appState.gradesForStudent(child.id);
    final attendance = child == null
        ? <AttendanceSession>[]
        : appState.attendanceSessionsForStudent(child.id);
    final notifications = <_ParentNotification>[
      for (var i = 0; i < grades.length; i++)
        _ParentNotification(
          id: 5000 + i,
          type: NotificationKind.grade,
          title: context.tr('Новая оценка'),
          message:
              '${grades[i].subject}: ${grades[i].value} • ${grades[i].category}',
          time: _dateTimeLabel(grades[i].createdAt),
          read: _readNotificationIds.contains(5000 + i),
          color: _NotificationColor.emerald,
        ),
      for (var i = 0; i < attendance.length; i++)
        if (_entryForStudent(attendance[i], child?.id)?.status ==
            AttendanceStatusType.absent)
          _ParentNotification(
            id: 6000 + i,
            type: NotificationKind.absence,
            title: context.tr('Пропуск занятий'),
            message:
                '${_lessonSubject(appState, attendance[i].lessonId)} • ${appState.absenceReasonLabel(_entryForStudent(attendance[i], child!.id)!.reason)}',
            time: _dateTimeLabel(attendance[i].recordedAt),
            read: _readNotificationIds.contains(6000 + i),
            color: _NotificationColor.orange,
          ),
      for (var i = 0; i < meetings.length; i++)
        _ParentNotification(
          id: 1000 + i,
          type: NotificationKind.event,
          title: meetings[i].title,
          message:
              '${meetings[i].agenda.isEmpty ? context.tr('Родительское собрание') : meetings[i].agenda} • ${_dateTimeLabel(meetings[i].meetingAt)} • ${meetings[i].location}',
          time: context.tr('Назначено учителем'),
          read: _readNotificationIds.contains(1000 + i),
          color: _NotificationColor.purple,
        ),
      for (var i = 0; i < assignments.length; i++)
        _ParentNotification(
          id: 2000 + i,
          type: NotificationKind.homework,
          title: assignments[i].kind == AssignmentKind.testWork
              ? context.tr('Назначена контрольная работа')
              : context.tr('Новое домашнее задание'),
          message:
              '${assignments[i].subject}: ${assignments[i].title} • ${_dateTimeLabel(assignments[i].dueAt)}',
          time: context.tr('Назначено учителем'),
          read: _readNotificationIds.contains(2000 + i),
          color: assignments[i].kind == AssignmentKind.testWork
              ? _NotificationColor.orange
              : _NotificationColor.blue,
        ),
    ];

    final resolvedNotifications = notifications
        .map(
          (notification) => notification.copyWith(
            read: notification.read ||
                _readNotificationIds.contains(notification.id),
          ),
        )
        .toList();
    final filteredNotifications = resolvedNotifications
        .where((notification) => _selectedFilter.matches(notification.type))
        .toList();
    final unreadCount = filteredNotifications
        .where((notification) => !notification.read)
        .length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(unreadCount: unreadCount),
          const SizedBox(height: 16),
          _StatsRow(
            unreadCount: unreadCount,
            total: filteredNotifications.length,
          ),
          const SizedBox(height: 16),
          _FilterRow(
            selected: _selectedFilter,
            onChanged: (filter) => setState(() => _selectedFilter = filter),
          ),
          const SizedBox(height: 16),
          if (filteredNotifications.isEmpty)
            _EmptyNotificationsState(
              message: child == null
                  ? context.tr('Ученик не привязан к вашему профилю.')
                  : context.tr('Новых уведомлений пока нет.'),
            )
          else
            Column(
              children: [
                for (int i = 0; i < filteredNotifications.length; i++) ...[
                  if (i != 0) const SizedBox(height: 10),
                  _NotificationCard(
                    notification: filteredNotifications[i],
                    index: i,
                    onMarkRead: () => _markRead(filteredNotifications[i].id),
                  ),
                ],
              ],
            ),
          const SizedBox(height: 16),
          if (unreadCount > 0)
            _MarkAllReadButton(
              onPressed: () => _markAllRead(filteredNotifications),
            ),
        ],
      ),
    );
  }
}

enum _NotificationFilter {
  all,
  grades,
  homework,
  events;

  bool matches(NotificationKind kind) {
    switch (this) {
      case _NotificationFilter.all:
        return true;
      case _NotificationFilter.grades:
        return kind == NotificationKind.grade;
      case _NotificationFilter.homework:
        return kind == NotificationKind.homework;
      case _NotificationFilter.events:
        return kind == NotificationKind.event ||
            kind == NotificationKind.absence;
    }
  }
}

enum NotificationKind {
  grade,
  homework,
  event,
  absence,
}

enum _NotificationColor {
  emerald,
  blue,
  purple,
  orange,
}

class _ParentNotification {
  final int id;
  final NotificationKind type;
  final String title;
  final String message;
  final String time;
  final bool read;
  final _NotificationColor color;

  const _ParentNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.time,
    required this.read,
    required this.color,
  });

  _ParentNotification copyWith({bool? read}) {
    return _ParentNotification(
      id: id,
      type: type,
      title: title,
      message: message,
      time: time,
      read: read ?? this.read,
      color: color,
    );
  }
}

class _Header extends StatelessWidget {
  final int unreadCount;

  const _Header({required this.unreadCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFFF472B6), Color(0xFFFB7185)],
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('Уведомления'),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  context.tr('Все новости и события'),
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (unreadCount > 0)
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int unreadCount;
  final int total;

  const _StatsRow({
    required this.unreadCount,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.panelColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.appBorderColor),
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
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCE7F3),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.notifications_none_rounded,
                    color: Color(0xFFEC4899),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$unreadCount',
                        style: TextStyle(
                          color: context.primaryTextColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.tr('Непрочитанных'),
                        style: TextStyle(
                          color: context.secondaryTextColor,
                          fontSize: 13,
                        ),
                        softWrap: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.panelColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.appBorderColor),
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
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: context.isDarkTheme ? const Color(0xFF1E3A5F) : const Color(0xFFDBEAFE),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.check_circle_outline_rounded,
                    color: Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$total',
                        style: TextStyle(
                          color: context.primaryTextColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.tr('Всего'),
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
          ),
        ),
      ],
    );
  }
}

class _FilterRow extends StatelessWidget {
  final _NotificationFilter selected;
  final ValueChanged<_NotificationFilter> onChanged;

  const _FilterRow({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          _FilterChip(
            label: context.tr('Все'),
            isPrimary: selected == _NotificationFilter.all,
            onTap: () => onChanged(_NotificationFilter.all),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: context.tr('Оценки'),
            isPrimary: selected == _NotificationFilter.grades,
            onTap: () => onChanged(_NotificationFilter.grades),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: context.tr('Задания'),
            isPrimary: selected == _NotificationFilter.homework,
            onTap: () => onChanged(_NotificationFilter.homework),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: context.tr('События'),
            isPrimary: selected == _NotificationFilter.events,
            onTap: () => onChanged(_NotificationFilter.events),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isPrimary;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isPrimary ? const Color(0xFFEC4899) : context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: isPrimary ? null : Border.all(color: context.appBorderColor),
        boxShadow: isPrimary
            ? const [
                BoxShadow(
                  blurRadius: 14,
                  offset: Offset(0, 8),
                  color: Color(0x26000000),
                ),
              ]
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isPrimary ? Colors.white : context.secondaryTextColor,
          fontSize: 13,
          fontWeight: isPrimary ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: child,
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final _ParentNotification notification;
  final int index;
  final VoidCallback onMarkRead;

  const _NotificationCard({
    required this.notification,
    required this.index,
    required this.onMarkRead,
  });

  Color _bgColor(BuildContext context) {
    final dark = context.isDarkTheme;
    switch (notification.color) {
      case _NotificationColor.emerald:
        return dark ? const Color(0xFF14532D) : const Color(0xFFD1FAE5);
      case _NotificationColor.blue:
        return dark ? const Color(0xFF1E3A5F) : const Color(0xFFDBEAFE);
      case _NotificationColor.purple:
        return dark ? const Color(0xFF3B0764) : const Color(0xFFEDE9FE);
      case _NotificationColor.orange:
        return dark ? const Color(0xFF78350F) : const Color(0xFFFFEDD5);
    }
  }

  Color _textColor(BuildContext context) {
    final dark = context.isDarkTheme;
    switch (notification.color) {
      case _NotificationColor.emerald:
        return dark ? const Color(0xFF6EE7B7) : const Color(0xFF059669);
      case _NotificationColor.blue:
        return dark ? const Color(0xFF93C5FD) : const Color(0xFF2563EB);
      case _NotificationColor.purple:
        return dark ? const Color(0xFFC4B5FD) : const Color(0xFF7C3AED);
      case _NotificationColor.orange:
        return dark ? const Color(0xFFFBBF24) : const Color(0xFFEA580C);
    }
  }

  Color _borderColor(BuildContext context) {
    final dark = context.isDarkTheme;
    switch (notification.color) {
      case _NotificationColor.emerald:
        return dark ? const Color(0xFF065F46) : const Color(0xFFA7F3D0);
      case _NotificationColor.blue:
        return dark ? const Color(0xFF1E40AF) : const Color(0xFFBFDBFE);
      case _NotificationColor.purple:
        return dark ? const Color(0xFF5B21B6) : const Color(0xFFDDD6FE);
      case _NotificationColor.orange:
        return dark ? const Color(0xFF92400E) : const Color(0xFFFCD9BD);
    }
  }

  IconData get _icon {
    switch (notification.type) {
      case NotificationKind.grade:
        return Icons.emoji_events_rounded;
      case NotificationKind.homework:
        return Icons.menu_book_rounded;
      case NotificationKind.event:
        return Icons.event_rounded;
      case NotificationKind.absence:
        return Icons.warning_amber_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderColor =
        notification.read ? context.appBorderColor : _borderColor(context);

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: notification.read ? context.cardColor : context.panelMutedColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1.8),
        boxShadow: const [
          BoxShadow(
            blurRadius: 16,
            offset: Offset(0, 10),
            color: Color(0x14000000),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _bgColor(context),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _icon,
              color: _textColor(context),
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        context.tr(notification.title),
                        style: TextStyle(
                          color: context.primaryTextColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (!notification.read)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(left: 6, top: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEC4899),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  context.tr(notification.message),
                  style: TextStyle(
                    color: context.secondaryTextColor,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      context.tr(notification.time),
                      style: TextStyle(
                        color: context.secondaryTextColor,
                        fontSize: 11,
                      ),
                    ),
                    const Spacer(),
                    if (!notification.read)
                      TextButton(
                        onPressed: onMarkRead,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: const Color(0xFFEC4899),
                        ),
                        child: Text(
                          context.tr('Отметить прочитанным'),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyNotificationsState extends StatelessWidget {
  final String message;

  const _EmptyNotificationsState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.panelColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.appBorderColor),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: context.secondaryTextColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MarkAllReadButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _MarkAllReadButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onPressed,
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Color(0xFFEC4899), Color(0xFFFB7185)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: const [
              BoxShadow(
                blurRadius: 18,
                offset: Offset(0, 10),
                color: Color(0x26000000),
              ),
            ],
          ),
          child: Center(
            child: Text(
              context.tr('Отметить все как прочитанные'),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _dateTimeLabel(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$day.$month.${date.year} $hour:$minute';
}

AttendanceEntry? _entryForStudent(
    AttendanceSession session, String? studentId) {
  if (studentId == null) {
    return null;
  }
  for (final entry in session.entries) {
    if (entry.studentId == studentId) {
      return entry;
    }
  }
  return null;
}

String _lessonSubject(AppState state, String lessonId) {
  return state.lessonById(lessonId)?.subject ?? state.strings.t('Урок');
}
