import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../models/user_role.dart';
import '../../widgets/contact_actions.dart';

class StudentTeachersScreen extends StatelessWidget {
  const StudentTeachersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.appState;
    final classId = appState.currentUser?.schoolClass;
    final lessons =
        classId == null ? const [] : appState.lessonsForClass(classId);
    final seenTeacherIds = <String>{};
    final teachers = <_Teacher>[
      for (final lesson in lessons)
        if (seenTeacherIds.add(lesson.teacherId) &&
            appState.userById(lesson.teacherId) != null)
          _Teacher.fromLesson(
            appState.userById(lesson.teacherId)!,
            subject: lesson.subject,
            consultationHours:
                '${appState.weekdayLabel(lesson.weekdayIndex)} ${lesson.timeRange}',
            room: lesson.room,
          ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _HeaderCard(),
          const SizedBox(height: 24),
          if (teachers.isEmpty)
            _EmptyTeachersState(
              message: classId == null
                  ? context.tr('Класс ученика не назначен.')
                  : context.tr('Учителя для этого класса пока не назначены.'),
            )
          else
            Column(
              children: [
                for (int i = 0; i < teachers.length; i++) ...[
                  if (i != 0) const SizedBox(height: 12),
                  _TeacherCard(teacher: teachers[i]),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _Teacher {
  final String id;
  final String name;
  final String subject;
  final String email;
  final String phone;
  final String consultationHours;
  final String room;

  const _Teacher({
    required this.id,
    required this.name,
    required this.subject,
    required this.email,
    required this.phone,
    required this.consultationHours,
    required this.room,
  });

  factory _Teacher.fromLesson(
    AppUser teacher, {
    required String subject,
    required String consultationHours,
    required String room,
  }) {
    return _Teacher(
      id: teacher.id,
      name: teacher.fullName,
      subject: subject,
      email: teacher.email ?? '',
      phone: teacher.phone ?? '',
      consultationHours: consultationHours,
      room: room,
    );
  }
}

class _EmptyTeachersState extends StatelessWidget {
  final String message;

  const _EmptyTeachersState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.person_off_rounded,
            color: Color(0xFF9CA3AF),
            size: 34,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF4B5563),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF22D3EE),
            Color(0xFF3B82F6),
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
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('Мои учителя'),
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6),
          Text(
            context.tr('Контакты и расписание консультаций'),
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _TeacherCard extends StatelessWidget {
  final _Teacher teacher;

  const _TeacherCard({required this.teacher});

  @override
  Widget build(BuildContext context) {
    final subjectGradient = _subjectGradient(teacher.subject);

    return Container(
      padding: const EdgeInsets.all(16),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: Stack(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: subjectGradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          _initials(teacher.name),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: const [
                            BoxShadow(
                              blurRadius: 6,
                              offset: Offset(0, 2),
                              color: Color(0x33000000),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.menu_book_rounded,
                          size: 16,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      teacher.name,
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.tr(teacher.subject),
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.mail_outline,
                              size: 16,
                              color: Color(0xFF6B7280),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                teacher.email,
                                style: const TextStyle(
                                  color: Color(0xFF4B5563),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.phone_outlined,
                              size: 16,
                              color: Color(0xFF6B7280),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              teacher.phone,
                              style: const TextStyle(
                                color: Color(0xFF4B5563),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.access_time_rounded,
                                size: 16,
                                color: Color(0xFF6B7280),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  context.tr(teacher.consultationHours),
                                  style: const TextStyle(
                                    color: Color(0xFF6B7280),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            context.tr(teacher.room),
                            style: const TextStyle(
                              color: Color(0xFF4B5563),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
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
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () => openContactChat(
                    context: context,
                    contactId: teacher.id,
                    name: teacher.name,
                    subtitle: context.tr(teacher.subject),
                  ),
                  icon: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 18,
                    color: Color(0xFF2563EB),
                  ),
                  label: Text(
                    context.tr('Написать'),
                    style: TextStyle(
                      color: Color(0xFF2563EB),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    backgroundColor: const Color(0xFFE0F2FE),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextButton.icon(
                  onPressed: () => openPhoneDialer(context, teacher.phone),
                  icon: const Icon(
                    Icons.phone_in_talk_outlined,
                    size: 18,
                    color: Color(0xFF059669),
                  ),
                  label: Text(
                    context.tr('Позвонить'),
                    style: TextStyle(
                      color: Color(0xFF059669),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    backgroundColor: const Color(0xFFD1FAE5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
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

  List<Color> _subjectGradient(String subject) {
    switch (subject) {
      case 'Математика':
        return const [
          Color(0xFF60A5FA),
          Color(0xFF3B82F6),
        ];
      case 'Физика':
        return const [
          Color(0xFFA855F7),
          Color(0xFF7C3AED),
        ];
      case 'Русский язык':
        return const [
          Color(0xFFF472B6),
          Color(0xFFEC4899),
        ];
      case 'История':
        return const [
          Color(0xFFFBBF24),
          Color(0xFFF59E0B),
        ];
      default:
        return const [
          Color(0xFF9CA3AF),
          Color(0xFF4B5563),
        ];
    }
  }

  String _initials(String name) {
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) {
      return parts.first.characters.first.toUpperCase();
    }
    final first = parts[0].characters.first.toUpperCase();
    final second = parts[1].characters.first.toUpperCase();
    return '$first$second';
  }
}
