import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../models/user_role.dart';
import '../../widgets/side_menu.dart';
import '../../widgets/app_theme.dart';

class ScheduleScreen extends StatefulWidget {
  final ValueChanged<MainSection>? onOpenSection;
  final ValueChanged<String>? onOpenAttendance;

  const ScheduleScreen({
    super.key,
    this.onOpenSection,
    this.onOpenAttendance,
  });

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  int _selectedDay = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = context.appState;
    final teacher = appState.currentUser;

    if (teacher == null || teacher.role != UserRole.teacher) {
      return _EmptyScheduleState(
        title: context.tr('Учитель не найден'),
        subtitle: context.tr(
          'Сначала войдите под аккаунтом учителя, чтобы увидеть расписание.',
        ),
      );
    }

    final lessons = appState.lessonsForTeacherAndDay(teacher.id, _selectedDay);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF60A5FA),
                Color(0xFF10B981),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: const [
              BoxShadow(
                blurRadius: 30,
                offset: Offset(0, 18),
                color: Color(0x33000000),
              ),
            ],
          ),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  color: Colors.black.withOpacity(0.15),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('Расписание'),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        context.tr(
                          'Ваше реальное расписание строится из уроков, назначенных администратором.',
                        ),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: List.generate(5, (index) {
              final isSelected = _selectedDay == index;
              final label = context.tr(appState.weekdayLabel(index));
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDay = index;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected ? const Color(0xFF2ECC71) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : context.appBorderColor,
                      ),
                      boxShadow: isSelected
                          ? const [
                              BoxShadow(
                                blurRadius: 18,
                                offset: Offset(0, 8),
                                color: Color(0x33000000),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        color:
                            isSelected ? Colors.white : context.secondaryTextColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 16),
        if (lessons.isEmpty)
          _EmptyScheduleState(
            title: context.tr('На этот день уроков нет'),
            subtitle: context.tr(
              'Добавьте уроки в админ-панели или выберите другой день.',
            ),
          )
        else
          Column(
            children: [
              for (var i = 0; i < lessons.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ScheduleTile(
                    lessonId: lessons[i].id,
                    onOpenSection: widget.onOpenSection,
                    onOpenAttendance: widget.onOpenAttendance,
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _ScheduleTile extends StatelessWidget {
  final String lessonId;
  final ValueChanged<MainSection>? onOpenSection;
  final ValueChanged<String>? onOpenAttendance;

  const _ScheduleTile({
    required this.lessonId,
    required this.onOpenSection,
    required this.onOpenAttendance,
  });

  @override
  Widget build(BuildContext context) {
    final appState = context.appState;
    final lesson = appState.lessonById(lessonId)!;
    final latestSession = appState.latestAttendanceForLesson(lessonId);
    final studentsCount = appState.studentsForClass(lesson.classId).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.panelColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.appBorderColor),
        boxShadow: const [
          BoxShadow(
            blurRadius: 22,
            offset: Offset(0, 12),
            color: Color(0x14000000),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(lesson.subject),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: context.primaryTextColor,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.trf(
                        'Класс {value}',
                        {'value': lesson.classId},
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: context.secondaryTextColor,
                          ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 18,
                    color: Color(0xFF10B981),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    lesson.timeRange,
                    style: TextStyle(
                      color: context.primaryTextColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _InfoPill(
                icon: Icons.meeting_room_rounded,
                label: lesson.room,
              ),
              const SizedBox(width: 8),
              _InfoPill(
                icon: Icons.groups_rounded,
                label: context
                    .trf('{value} учеников', {'value': '$studentsCount'}),
              ),
              const SizedBox(width: 8),
              _InfoPill(
                icon: Icons.fact_check_rounded,
                label: latestSession == null
                    ? context.tr('Журнал не заполнен')
                    : context.tr('Журнал обновлён'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => onOpenAttendance?.call(lessonId),
                  icon: Icon(Icons.fact_check_rounded, size: 18),
                  label: Text(context.tr('Проверить посещаемость')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F766E),
                    side: const BorderSide(color: Color(0xFF99F6E4)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => onOpenSection?.call(MainSection.grades),
                  icon: Icon(Icons.edit_note_rounded, size: 18),
                  label: Text(context.tr('Поставить оценки')),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoPill({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.appBorderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: context.secondaryTextColor),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.secondaryTextColor,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyScheduleState extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EmptyScheduleState({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.panelColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.appBorderColor),
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_note_rounded,
            color: Color(0xFF10B981),
            size: 36,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: context.primaryTextColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }
}
