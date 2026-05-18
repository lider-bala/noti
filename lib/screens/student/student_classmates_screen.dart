import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../models/user_role.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/contact_actions.dart';
import '../../widgets/responsive.dart';

class StudentClassmatesScreen extends StatefulWidget {
  const StudentClassmatesScreen({super.key});

  @override
  State<StudentClassmatesScreen> createState() =>
      _StudentClassmatesScreenState();
}

class _StudentClassmatesScreenState extends State<StudentClassmatesScreen> {
  final Set<String> _friendIds = {};

  void _addFriend(_Classmate classmate) {
    setState(() => _friendIds.add(classmate.id));
    showAppSnackBar(
      context,
      context.trf(
        '{name} добавлен в друзья.',
        {'name': classmate.name},
      ),
      backgroundColor: const Color(0xFF047857),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.appState;
    final current = appState.currentUser;
    final classId = current?.schoolClass;
    final students = classId == null
        ? <AppUser>[]
        : appState
            .studentsForClass(classId)
            .where((student) => student.id != current?.id)
            .toList();
    final classmates = students
        .map(
          (student) => _Classmate(
            id: student.id,
            name: student.fullName,
            email: student.email ?? '',
            phone: student.phone ?? '',
            avgGrade: appState.averageGrade(appState.gradesForStudent(
              student.id,
            )),
            isFriend: _friendIds.contains(student.id),
          ),
        )
        .toList();
    final classAverage = appState.averageGrade(
      classId == null ? const [] : appState.gradesForClass(classId),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeaderCard(
            classLabel: classId ?? context.tr('Класс не указан'),
            total:
                students.length + (current?.role == UserRole.student ? 1 : 0),
          ),
          const SizedBox(height: 16),
          _StatsCard(
            total:
                students.length + (current?.role == UserRole.student ? 1 : 0),
            classAverage: classAverage,
          ),
          const SizedBox(height: 24),
          if (classmates.isEmpty)
            _EmptyClassmatesState(
              message: classId == null
                  ? context.tr('Класс не указан.')
                  : context.tr('В классе пока нет других учеников.'),
            )
          else
            Column(
              children: [
                for (int i = 0; i < classmates.length; i++) ...[
                  if (i != 0) const SizedBox(height: 10),
                  _ClassmateCard(
                    classmate: classmates[i],
                    onAddFriend: () => _addFriend(classmates[i]),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final String classLabel;
  final int total;

  const _HeaderCard({
    required this.classLabel,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFB7185),
            Color(0xFFEC4899),
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
            context.tr('Одноклассники'),
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6),
          Text(
            context.trf(
              'Класс {className} • {count} учеников',
              {
                'className': classLabel,
                'count': '$total',
              },
            ),
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

class _StatsCard extends StatelessWidget {
  final int total;
  final double classAverage;

  const _StatsCard({
    required this.total,
    required this.classAverage,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveWrapRow(
      spacing: 10,
      children: [
        _StatTile(
          value: '$total',
          label: context.tr('Всего учеников'),
          valueColor: const Color(0xFF111827),
        ),
        _StatTile(
          value: classAverage == 0 ? '—' : classAverage.toStringAsFixed(1),
          label: context.tr('Средний балл класса'),
          valueColor: const Color(0xFF059669),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final Color valueColor;

  const _StatTile({
    required this.value,
    required this.label,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF4B5563),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _Classmate {
  final String id;
  final String name;
  final String email;
  final String phone;
  final double avgGrade;
  final bool isFriend;

  const _Classmate({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.avgGrade,
    required this.isFriend,
  });
}

class _EmptyClassmatesState extends StatelessWidget {
  final String message;

  const _EmptyClassmatesState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF6B7280),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ClassmateCard extends StatelessWidget {
  final _Classmate classmate;
  final VoidCallback onAddFriend;

  const _ClassmateCard({
    required this.classmate,
    required this.onAddFriend,
  });

  @override
  Widget build(BuildContext context) {
    const avatarGradient = [
      Color(0xFFFB7185),
      Color(0xFFEC4899),
    ];

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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: avatarGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Text(
                _initials(classmate.name),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        classmate.name,
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (classmate.isFriend)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDBEAFE),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          context.tr('Друг'),
                          style: TextStyle(
                            color: Color(0xFF1D4ED8),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
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
                            classmate.email,
                            style: const TextStyle(
                              color: Color(0xFF4B5563),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.phone_outlined,
                          size: 16,
                          color: Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            classmate.phone.isEmpty
                                ? context.tr('Телефон не указан')
                                : classmate.phone,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF4B5563),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () => openContactChat(
                          context: context,
                          contactId: classmate.id,
                          name: classmate.name,
                          subtitle: context.tr('Одноклассник'),
                        ),
                        icon: Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 16,
                          color: Color(0xFF2563EB),
                        ),
                        label: Text(
                          context.tr('Написать'),
                          style: TextStyle(
                            color: Color(0xFF2563EB),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          backgroundColor: const Color(0xFFE0F2FE),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (classmate.phone.isNotEmpty) ...[
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1FAE5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: () =>
                              openPhoneDialer(context, classmate.phone),
                          icon: const Icon(
                            Icons.phone_in_talk_outlined,
                            size: 20,
                            color: Color(0xFF059669),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (!classmate.isFriend)
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1FAE5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: onAddFriend,
                          icon: const Icon(
                            Icons.person_add_alt_1_rounded,
                            size: 20,
                            color: Color(0xFF059669),
                          ),
                          padding: EdgeInsets.zero,
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

  String _initials(String name) {
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    final first = parts[0].substring(0, 1).toUpperCase();
    final second = parts[1].substring(0, 1).toUpperCase();
    return '$first$second';
  }
}
