import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../widgets/app_theme.dart';

class ParentScheduleScreen extends StatefulWidget {
  const ParentScheduleScreen({super.key});

  @override
  State<ParentScheduleScreen> createState() => _ParentScheduleScreenState();
}

class _ParentScheduleScreenState extends State<ParentScheduleScreen> {
  final List<String> days = ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ'];
  int selectedDay = 0;

  @override
  Widget build(BuildContext context) {
    final appState = context.appState;
    final child = appState.studentForParent(appState.currentUser);
    final childLabel = child == null
        ? context.tr('Ученик не найден')
        : [
            child.fullName,
            if ((child.schoolClass ?? '').isNotEmpty)
              context.tr('Класс ${child.schoolClass}'),
          ].join(' • ');
    final schedule = child?.schoolClass == null
        ? <_ScheduleItem>[]
        : appState
            .lessonsForClass(child!.schoolClass!)
            .where((lesson) => lesson.weekdayIndex == selectedDay)
            .map(
              (lesson) => _ScheduleItem(
                time: lesson.timeRange,
                type: _ScheduleItemType.lesson,
                subject: lesson.subject,
                teacher: appState.userById(lesson.teacherId)?.fullName ??
                    context.tr('Учитель не назначен'),
                room: lesson.room,
              ),
            )
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF8B5CF6),
                Color(0xFF6366F1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                blurRadius: 24,
                offset: Offset(0, 16),
                color: Color(0x33000000),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('Расписание ребенка'),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4),
              Text(
                childLabel,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
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
                    colors: [
                      Color(0xFFF97316),
                      Color(0xFFFBBF24),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    child?.initials ?? '—',
                    style: const TextStyle(
                      color: Colors.white,
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
                    child?.fullName ?? context.tr('Ученик не найден'),
                    style: TextStyle(
                      color: context.primaryTextColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 2),
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
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 52,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: days.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final bool isSelected = index == selectedDay;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedDay = index;
                  });
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFF97316) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : context.appBorderColor,
                    ),
                    boxShadow: isSelected
                        ? const [
                            BoxShadow(
                              blurRadius: 14,
                              offset: Offset(0, 8),
                              color: Color(0x22000000),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      context.tr(days[index]),
                      style: TextStyle(
                        color:
                            isSelected ? Colors.white : context.secondaryTextColor,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        if (schedule.isEmpty)
          _EmptyScheduleState(
            title: context.tr('На этот день уроков нет'),
            subtitle: context.tr('Расписание формируется администратором.'),
          )
        else
          Column(
            children: [
              for (int i = 0; i < schedule.length; i++) ...[
                if (i != 0) const SizedBox(height: 10),
                _ScheduleCard(item: schedule[i]),
              ],
            ],
          ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFE0F2FE),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.calendar_month_rounded,
                color: Color(0xFF2563EB),
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('Информация'),
                      style: TextStyle(
                        color: Color(0xFF1D4ED8),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      context.tr(
                        'Расписание может меняться. Проверяйте актуальную информацию в приложении.',
                      ),
                      style: TextStyle(
                        color: Color(0xFF1D4ED8),
                        fontSize: 13,
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
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: context.panelColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.appBorderColor),
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_note_rounded,
            color: Color(0xFFF97316),
            size: 34,
          ),
          const SizedBox(height: 10),
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
            style: TextStyle(color: context.secondaryTextColor),
          ),
        ],
      ),
    );
  }
}

enum _ScheduleItemType { lesson, breakTime, lunch }

class _ScheduleItem {
  final String time;
  final _ScheduleItemType type;
  final String? subject;
  final String? teacher;
  final String? room;

  const _ScheduleItem({
    required this.time,
    required this.type,
    this.subject,
    this.teacher,
    this.room,
  });
}

class _ScheduleCard extends StatelessWidget {
  final _ScheduleItem item;

  const _ScheduleCard({required this.item});

  @override
  Widget build(BuildContext context) {
    switch (item.type) {
      case _ScheduleItemType.lesson:
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
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr(item.subject ?? ''),
                          style: TextStyle(
                            color: context.primaryTextColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline_rounded,
                              size: 16,
                              color: context.secondaryTextColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              item.teacher ?? '',
                              style: TextStyle(
                                color: context.secondaryTextColor,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            size: 16,
                            color: Color(0xFFF97316),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item.time,
                            style: const TextStyle(
                              color: Color(0xFFF97316),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Divider(color: context.appBorderColor, height: 1),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: context.secondaryTextColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    context.tr(item.room ?? ''),
                    style: TextStyle(
                      color: context.secondaryTextColor,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );

      case _ScheduleItemType.lunch:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFFFF7ED),
                Color(0xFFFEF3C7),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFED7AA)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.local_cafe_rounded,
                color: Color(0xFFF97316),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                context.trf('Обед • {time}', {'time': item.time}),
                style: const TextStyle(
                  color: Color(0xFFF97316),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );

      case _ScheduleItemType.breakTime:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.appBorderColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.free_breakfast_outlined,
                color: context.secondaryTextColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                context.trf('Перерыв • {time}', {'time': item.time}),
                style: TextStyle(
                  color: context.secondaryTextColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
    }
  }
}
