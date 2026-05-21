import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../models/school_models.dart';
import '../../models/user_role.dart';
import '../../widgets/app_theme.dart';

class StudentScheduleScreen extends StatefulWidget {
  const StudentScheduleScreen({super.key});

  @override
  State<StudentScheduleScreen> createState() => _StudentScheduleScreenState();
}

class _StudentScheduleScreenState extends State<StudentScheduleScreen> {
  int _selectedDay = 0;

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

    final classId = student.schoolClass;
    final lessons = classId == null
        ? <LessonAssignment>[]
        : appState
            .lessonsForClass(classId)
            .where((lesson) => lesson.weekdayIndex == _selectedDay)
            .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeaderCard(student: student),
          const SizedBox(height: 20),
          _DaySelector(
            selectedIndex: _selectedDay,
            onSelected: (index) => setState(() => _selectedDay = index),
          ),
          const SizedBox(height: 16),
          if (lessons.isEmpty)
            _EmptyState(
              title: context.tr('На этот день уроков нет'),
              subtitle: context.tr('Расписание формируется администратором.'),
            )
          else
            Column(
              children: [
                for (int i = 0; i < lessons.length; i++) ...[
                  if (i != 0) const SizedBox(height: 8),
                  _LessonCard(lesson: lessons[i]),
                ],
              ],
            ),
        ],
      ),
    );
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
          colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
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
            context.tr('Моё расписание'),
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

class _DaySelector extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _DaySelector({
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final appState = context.appState;

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = index == selectedIndex;
          return InkWell(
            onTap: () => onSelected(index),
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: isSelected ? const Color(0xFF3B82F6) : context.cardColor,
                border: Border.all(
                  color:
                      isSelected ? Colors.transparent : context.appBorderColor,
                ),
                boxShadow: isSelected
                    ? const [
                        BoxShadow(
                          blurRadius: 16,
                          offset: Offset(0, 10),
                          color: Color(0x26000000),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  context.tr(appState.weekdayLabel(index)),
                  style: TextStyle(
                    color: isSelected ? Colors.white : context.secondaryTextColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  final LessonAssignment lesson;

  const _LessonCard({required this.lesson});

  @override
  Widget build(BuildContext context) {
    final teacher = context.appState.userById(lesson.teacherId);

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
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
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(lesson.subject),
                      style: TextStyle(
                        color: context.primaryTextColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      teacher?.fullName ?? context.tr('Учитель не назначен'),
                      style: TextStyle(
                        color: context.secondaryTextColor,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    size: 16,
                    color: Color(0xFF3B82F6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    lesson.timeRange,
                    style: const TextStyle(
                      color: Color(0xFF3B82F6),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 16,
                color: context.secondaryTextColor,
              ),
              const SizedBox(width: 4),
              Text(
                context.tr(lesson.room),
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
      padding: EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: context.panelColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.appBorderColor),
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_note_rounded,
            color: Color(0xFF8B5CF6),
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
