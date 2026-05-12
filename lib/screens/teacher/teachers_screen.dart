import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/contact_actions.dart';

class TeachersScreen extends StatefulWidget {
  const TeachersScreen({super.key});

  @override
  State<TeachersScreen> createState() => _TeachersScreenState();
}

class _TeachersScreenState extends State<TeachersScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = context.appState;
    final currentUserId = appState.currentUser?.id;
    final teachers = appState.teachers
        .where((teacher) => teacher.id != currentUserId)
        .map((teacher) {
      final lessons = appState.lessonsForTeacher(teacher.id);
      final subjects = lessons.map((lesson) => lesson.subject).toSet();
      final classes = appState.classesForTeacher(teacher.id);
      return _TeacherItem(
        id: teacher.id,
        name: teacher.fullName,
        subject: subjects.isEmpty
            ? context.tr('Предмет не назначен')
            : subjects.join(', '),
        email: teacher.email ?? '',
        phone: teacher.phone ?? '',
        consultationHours: context.tr('По договорённости'),
        classes: classes.map((item) => item.name).toList(),
      );
    }).toList();

    final filtered = teachers.where((t) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return t.name.toLowerCase().contains(q) ||
          t.subject.toLowerCase().contains(q);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF14B8A6),
                Color(0xFF22D3EE),
              ],
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
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('Учителя'),
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 8),
              Text(
                context.tr('Контакты и информация о преподавателях'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 20),
        TextField(
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
          decoration: InputDecoration(
            hintText: context.tr('Поиск учителей...'),
            hintStyle: TextStyle(color: context.secondaryTextColor),
            filled: true,
            fillColor: context.panelMutedColor,
            prefixIcon: Icon(
              Icons.search_rounded,
              color: context.secondaryTextColor,
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(
                color: context.appBorderColor,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(
                color: context.appBorderColor,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(
                color: const Color(0xFF2ECC71),
                width: 1.5,
              ),
            ),
          ),
        ),
        SizedBox(height: 20),
        Column(
          children: filtered.isEmpty
              ? [
                  _EmptyTeachersState(
                    message: _searchQuery.trim().isEmpty
                        ? context.tr('Учителя пока не добавлены.')
                        : context.tr('По запросу ничего не найдено.'),
                  ),
                ]
              : [
                  for (var i = 0; i < filtered.length; i++)
                    Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: _TeacherCard(item: filtered[i]),
                    ),
                ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _StatBox(
                value: '${teachers.length}',
                label: context.tr('Всего учителей'),
                startColor: Color(0xFFEFF6FF),
                endColor: Color(0xFFDBEAFE),
                borderColor: Color(0xFFBFDBFE),
                valueColor: Color(0xFF2563EB),
                labelColor: Color(0xFF1D4ED8),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _StatBox(
                value:
                    '${teachers.expand((item) => item.subject.split(', ')).where((item) => item.trim().isNotEmpty && item != context.tr('Предмет не назначен')).toSet().length}',
                label: context.tr('Предметов'),
                startColor: Color(0xFFECFDF5),
                endColor: Color(0xFFD1FAE5),
                borderColor: Color(0xFFA7F3D0),
                valueColor: Color(0xFF059669),
                labelColor: Color(0xFF047857),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TeacherItem {
  final String id;
  final String name;
  final String subject;
  final String email;
  final String phone;
  final String consultationHours;
  final List<String> classes;

  const _TeacherItem({
    required this.id,
    required this.name,
    required this.subject,
    required this.email,
    required this.phone,
    required this.consultationHours,
    required this.classes,
  });

  String get initials {
    final parts = name.split(' ').where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first.characters.first;
    return (parts[0].characters.first + parts[1].characters.first)
        .toUpperCase();
  }
}

class _EmptyTeachersState extends StatelessWidget {
  final String message;

  const _EmptyTeachersState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.panelColor,
        borderRadius: BorderRadius.circular(20),
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

class _TeacherCard extends StatelessWidget {
  final _TeacherItem item;

  const _TeacherCard({required this.item});

  List<Color> _subjectGradient() {
    switch (item.subject) {
      case 'Математика':
        return const [Color(0xFF60A5FA), Color(0xFF3B82F6)];
      case 'Физика':
        return const [Color(0xFFA855F7), Color(0xFF7C3AED)];
      case 'Русский язык':
        return const [Color(0xFFF472B6), Color(0xFFEC4899)];
      case 'История':
        return const [Color(0xFFFBBF24), Color(0xFFF59E0B)];
      default:
        return const [Color(0xFF9CA3AF), Color(0xFF6B7280)];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gradient = _subjectGradient();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF3F4F6)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 24,
            offset: Offset(0, 14),
            color: Color(0x14000000),
          ),
        ],
      ),
      padding: EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Text(
                  item.initials,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
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
                        blurRadius: 8,
                        offset: Offset(0, 3),
                        color: Color(0x22000000),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.menu_book_rounded,
                    size: 16,
                    color: Color(0xFF4B5563),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF111827),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  context.tr(item.subject),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF4B5563),
                  ),
                ),
                SizedBox(height: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.mail_outline_rounded,
                          size: 16,
                          color: Color(0xFF6B7280),
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item.email,
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.phone_rounded,
                          size: 16,
                          color: Color(0xFF6B7280),
                        ),
                        SizedBox(width: 6),
                        Text(
                          item.phone,
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 16,
                          color: Color(0xFF6B7280),
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            context.trf(
                              'Консультации: {value}',
                              {'value': item.consultationHours},
                            ),
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Divider(
                      height: 18,
                      color: Color(0xFFF3F4F6),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          context.tr('Классы:'),
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF4B5563),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: item.classes
                                .map(
                                  (cls) => Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF3F4F6),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      cls,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF374151),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () => openContactChat(
                              context: context,
                              contactId: item.id,
                              name: item.name,
                              subtitle: context.tr(item.subject),
                            ),
                            icon: const Icon(
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
                              backgroundColor: const Color(0xFFE0F2FE),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () =>
                                openPhoneDialer(context, item.phone),
                            icon: const Icon(
                              Icons.phone_in_talk_outlined,
                              size: 16,
                              color: Color(0xFF059669),
                            ),
                            label: Text(
                              context.tr('Позвонить'),
                              style: TextStyle(
                                color: Color(0xFF059669),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0xFFD1FAE5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
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

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  final Color startColor;
  final Color endColor;
  final Color borderColor;
  final Color valueColor;
  final Color labelColor;

  const _StatBox({
    required this.value,
    required this.label,
    required this.startColor,
    required this.endColor,
    required this.borderColor,
    required this.valueColor,
    required this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [startColor, endColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: labelColor,
            ),
          ),
        ],
      ),
    );
  }
}
