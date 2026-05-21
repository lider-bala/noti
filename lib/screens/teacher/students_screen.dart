import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../models/school_models.dart';
import '../../models/user_role.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/contact_actions.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  String? _selectedClassId;
  String _searchQuery = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final teacher = context.appState.currentUser;
    if (teacher == null || teacher.role != UserRole.teacher) {
      return;
    }
    final classes = context.appState.classesForTeacher(teacher.id);
    if (classes.isEmpty) {
      _selectedClassId = null;
      return;
    }
    if (!classes.any((item) => item.id == _selectedClassId)) {
      _selectedClassId = classes.first.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.appState;
    final teacher = appState.currentUser;

    if (teacher == null || teacher.role != UserRole.teacher) {
      return _EmptyState(
        title: context.tr('Учитель не найден'),
        subtitle: context.tr(
          'Сначала войдите под аккаунтом учителя, чтобы увидеть учеников.',
        ),
      );
    }

    final classes = appState.classesForTeacher(teacher.id);
    if (classes.isEmpty) {
      return _EmptyState(
        title: context.tr('Классы пока не назначены'),
        subtitle: context.tr(
          'Администратор должен сначала прикрепить к вам классы и уроки.',
        ),
      );
    }

    final selectedClass = classes.firstWhere(
      (item) => item.id == _selectedClassId,
      orElse: () => classes.first,
    );
    final students = appState.studentsForClass(selectedClass.id);
    final filteredStudents = students.where((student) {
      final query = _searchQuery.trim().toLowerCase();
      if (query.isEmpty) {
        return true;
      }
      return student.fullName.toLowerCase().contains(query) ||
          (student.email ?? '').toLowerCase().contains(query) ||
          (student.phone ?? '').toLowerCase().contains(query);
    }).toList();
    final lessons = appState.lessonsForClass(selectedClass.id);
    final classTeachers = {
      for (final lesson in lessons)
        if (lesson.teacherId != teacher.id &&
            appState.userById(lesson.teacherId) != null)
          lesson.teacherId: appState.userById(lesson.teacherId)!,
    }.values.toList()
      ..sort((a, b) => a.fullName.compareTo(b.fullName));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeaderCard(
          classesCount: classes.length,
          studentsCount: students.length,
          teachersCount: classTeachers.length,
        ),
        const SizedBox(height: 18),
        _ClassSelector(
          classes: classes,
          selectedClassId: selectedClass.id,
          onSelected: (classId) {
            setState(() {
              _selectedClassId = classId;
              _searchQuery = '';
            });
          },
        ),
        const SizedBox(height: 16),
        TextField(
          onChanged: (value) => setState(() => _searchQuery = value),
          decoration: InputDecoration(
            labelText: context.tr('Поиск учеников...'),
            prefixIcon: Icon(Icons.search_rounded),
            filled: true,
            fillColor: context.panelMutedColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: context.appBorderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: context.appBorderColor),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _ClassTeachersCard(
          selectedClass: selectedClass,
          lessons: lessons,
          teachers: classTeachers,
        ),
        const SizedBox(height: 16),
        if (filteredStudents.isEmpty)
          _EmptyState(
            title: context.tr('Ученики не найдены'),
            subtitle: context.tr(
              'В выбранном классе нет учеников или поиск не дал результатов.',
            ),
          )
        else
          Column(
            children: [
              for (final student in filteredStudents)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _StudentDirectoryCard(student: student),
                ),
            ],
          ),
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final int classesCount;
  final int studentsCount;
  final int teachersCount;

  const _HeaderCard({
    required this.classesCount,
    required this.studentsCount,
    required this.teachersCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF10B981)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            blurRadius: 32,
            offset: Offset(0, 20),
            color: Color(0x33000000),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('Ученики и классы'),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr(
              'Выберите класс, посмотрите список учеников и контакты учителей этого класса.',
            ),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeaderMetric(
                  label: context.tr('Классы'), value: '$classesCount'),
              _HeaderMetric(
                label: context.tr('Ученики'),
                value: '$studentsCount',
              ),
              _HeaderMetric(
                label: context.tr('Учителя'),
                value: '$teachersCount',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderMetric extends StatelessWidget {
  final String label;
  final String value;

  const _HeaderMetric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _ClassSelector extends StatelessWidget {
  final List<SchoolClass> classes;
  final String selectedClassId;
  final ValueChanged<String> onSelected;

  const _ClassSelector({
    required this.classes,
    required this.selectedClassId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final schoolClass in classes)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(schoolClass.name),
                selected: schoolClass.id == selectedClassId,
                onSelected: (_) => onSelected(schoolClass.id),
                selectedColor: const Color(0xFF2ECC71),
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: schoolClass.id == selectedClassId
                      ? Colors.white
                      : context.secondaryTextColor,
                  fontWeight: FontWeight.w700,
                ),
                side: BorderSide(color: context.appBorderColor),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ClassTeachersCard extends StatelessWidget {
  final SchoolClass selectedClass;
  final List<LessonAssignment> lessons;
  final List<AppUser> teachers;

  const _ClassTeachersCard({
    required this.selectedClass,
    required this.lessons,
    required this.teachers,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.trf(
              'Учителя класса {value}',
              {'value': selectedClass.name},
            ),
            style: TextStyle(
              color: context.primaryTextColor,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          if (teachers.isEmpty)
            Text(
              context.tr('Учителя для этого класса пока не назначены.'),
              style: TextStyle(color: context.secondaryTextColor),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final teacher in teachers)
                  _ContactChip(
                    icon: Icons.school_rounded,
                    title: teacher.fullName,
                    subtitle: _teacherSubjects(context, lessons, teacher.id),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _StudentDirectoryCard extends StatelessWidget {
  final AppUser student;

  const _StudentDirectoryCard({required this.student});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(context),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 620;
          final avatar = CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFFEEF2FF),
            foregroundColor: const Color(0xFF4338CA),
            child: Text(
              student.initials,
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          );
          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                student.fullName,
                style: TextStyle(
                  color: context.primaryTextColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                [
                  if ((student.schoolClass ?? '').isNotEmpty)
                    context
                        .trf('Класс {value}', {'value': student.schoolClass!}),
                  if ((student.email ?? '').isNotEmpty) student.email!,
                  if ((student.phone ?? '').isNotEmpty) student.phone!,
                ].join(' • '),
                style: TextStyle(color: context.secondaryTextColor),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ContactActionChip(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: context.tr('Написать'),
                    subtitle: student.email ?? context.tr('Чат с учеником'),
                    color: const Color(0xFF2563EB),
                    background: const Color(0xFFE0F2FE),
                    onTap: () => openContactChat(
                      context: context,
                      contactId: student.id,
                      name: student.fullName,
                      subtitle: context.tr('Ученик'),
                    ),
                  ),
                  _ContactActionChip(
                    icon: Icons.phone_outlined,
                    title: context.tr('Позвонить'),
                    subtitle: student.phone ?? context.tr('Телефон не указан'),
                    color: const Color(0xFF059669),
                    background: const Color(0xFFD1FAE5),
                    onTap: () => openPhoneDialer(context, student.phone ?? ''),
                  ),
                ],
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                avatar,
                const SizedBox(height: 12),
                details,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              avatar,
              const SizedBox(width: 14),
              Expanded(child: details),
            ],
          );
        },
      ),
    );
  }
}

class _ContactChip extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _ContactChip({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 180, maxWidth: 320),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appBorderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF2563EB)),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.primaryTextColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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

class _ContactActionChip extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  const _ContactActionChip({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.background,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minWidth: 180, maxWidth: 320),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(context),
      child: Column(
        children: [
          Icon(
            Icons.groups_rounded,
            color: Color(0xFF2563EB),
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
            style: TextStyle(color: context.secondaryTextColor),
          ),
        ],
      ),
    );
  }
}

String _teacherSubjects(
  BuildContext context,
  List<LessonAssignment> lessons,
  String teacherId,
) {
  final subjects = lessons
      .where((lesson) => lesson.teacherId == teacherId)
      .map((lesson) => context.tr(lesson.subject))
      .toSet()
      .toList()
    ..sort();
  return subjects.isEmpty
      ? context.tr('Предметы не указаны')
      : subjects.join(', ');
}

BoxDecoration _cardDecoration(BuildContext context) {
  return BoxDecoration(
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
  );
}
