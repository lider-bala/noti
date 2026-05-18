import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../models/user_role.dart';
import '../../widgets/contact_actions.dart';
import '../../widgets/app_theme.dart';

class ParentTeachersScreen extends StatelessWidget {
  const ParentTeachersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.appState;
    final child = appState.studentForParent(appState.currentUser);
    final lessons = child?.schoolClass == null
        ? []
        : appState.lessonsForClass(child!.schoolClass!);
    final teachers = <_Teacher>[];
    final seenTeacherIds = <String>{};
    for (final lesson in lessons) {
      if (!seenTeacherIds.add(lesson.teacherId)) {
        continue;
      }
      final teacher = appState.userById(lesson.teacherId);
      if (teacher == null) {
        continue;
      }
      teachers.add(
        _Teacher(
          id: teacher.id,
          name: teacher.fullName,
          subject: lesson.subject,
          email: teacher.email ?? '',
          phone: teacher.phone ?? '',
          consultationHours: 'По договорённости',
          room: lesson.room,
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Header(),
          const SizedBox(height: 16),
          _ChildInfoCard(child: child),
          const SizedBox(height: 16),
          Column(
            children: [
              for (int i = 0; i < teachers.length; i++) ...[
                if (i != 0) const SizedBox(height: 12),
                _TeacherCard(teacher: teachers[i]),
              ],
            ],
          ),
          const SizedBox(height: 16),
          const _InfoCard(),
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
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF3B82F6)],
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('Учителя'),
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6),
          Text(
            context.tr('Контакты учителей вашего ребёнка'),
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

class _ChildInfoCard extends StatelessWidget {
  final AppUser? child;

  const _ChildInfoCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.panelColor,
        borderRadius: BorderRadius.circular(24),
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
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF97316), Color(0xFFFBBF24)],
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
    );
  }
}

class _TeacherCard extends StatelessWidget {
  final _Teacher teacher;

  const _TeacherCard({required this.teacher});

  Color _subjectStartColor(String subject, BuildContext context) {
    switch (subject) {
      case 'Математика':
        return const Color(0xFF60A5FA);
      case 'Физика':
        return const Color(0xFFA855F7);
      case 'Русский язык':
        return const Color(0xFFF472B6);
      case 'История':
        return const Color(0xFFF59E0B);
      default:
        return context.secondaryTextColor;
    }
  }

  Color _subjectEndColor(String subject, BuildContext context) {
    switch (subject) {
      case 'Математика':
        return const Color(0xFF3B82F6);
      case 'Физика':
        return const Color(0xFF7C3AED);
      case 'Русский язык':
        return const Color(0xFFEC4899);
      case 'История':
        return const Color(0xFFD97706);
      default:
        return context.secondaryTextColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final start = _subjectStartColor(teacher.subject, context);
    final end = _subjectEndColor(teacher.subject, context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.panelColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.appBorderColor),
        boxShadow: const [
          BoxShadow(
            blurRadius: 16,
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
              _TeacherAvatar(
                name: teacher.name,
                start: start,
                end: end,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      teacher.name,
                      style: TextStyle(
                        color: context.primaryTextColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.tr(teacher.subject),
                      style: TextStyle(
                        color: context.secondaryTextColor,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          Icons.mail_outline_rounded,
                          size: 16,
                          color: context.secondaryTextColor,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            teacher.email,
                            style: TextStyle(
                              color: context.secondaryTextColor,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.phone_outlined,
                          size: 16,
                          color: context.secondaryTextColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          teacher.phone,
                          style: TextStyle(
                            color: context.secondaryTextColor,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 16,
                          color: context.secondaryTextColor,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            context.tr(teacher.consultationHours),
                            style: TextStyle(
                              color: context.secondaryTextColor,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: context.appBorderColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            context.tr(teacher.room),
                            style: TextStyle(
                              color: context.primaryTextColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
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
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: 'Написать',
                  icon: Icons.chat_bubble_outline_rounded,
                  bgColor: const Color(0xFFE0F2FE),
                  textColor: const Color(0xFF2563EB),
                  onTap: () => openContactChat(
                    context: context,
                    contactId: teacher.id,
                    name: teacher.name,
                    subtitle: context.tr(teacher.subject),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  label: context.tr('Позвонить'),
                  icon: Icons.phone_in_talk_outlined,
                  bgColor: const Color(0xFFD1FAE5),
                  textColor: const Color(0xFF059669),
                  onTap: () => openPhoneDialer(context, teacher.phone),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TeacherAvatar extends StatelessWidget {
  final String name;
  final Color start;
  final Color end;

  const _TeacherAvatar({
    required this.name,
    required this.start,
    required this.end,
  });

  String get _initials {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return (parts[0].isNotEmpty ? parts[0][0] : '') +
          (parts[1].isNotEmpty ? parts[1][0] : '');
    }
    if (name.length >= 2) return name.substring(0, 2);
    return name;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [start, end],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              _initials.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
          ),
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: context.panelColor,
              borderRadius: BorderRadius.circular(999),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 8,
                  offset: Offset(0, 4),
                  color: Color(0x19000000),
                ),
              ],
            ),
            child: Icon(
              Icons.menu_book_rounded,
              size: 14,
              color: context.secondaryTextColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color bgColor;
  final Color textColor;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.bgColor,
    required this.textColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 10,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: textColor,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
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

class _InfoCard extends StatelessWidget {
  const _InfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.access_time_filled_rounded,
            size: 20,
            color: Color(0xFFEA580C),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('Консультации'),
                  style: TextStyle(
                    color: Color(0xFF92400E),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  context.tr(
                    'Для личной встречи с учителем лучше заранее договориться о времени по телефону или через сообщение.',
                  ),
                  style: TextStyle(
                    color: Color(0xFFB45309),
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
