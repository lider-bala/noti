import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../models/school_models.dart';
import '../../models/user_role.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/app_theme.dart';

class AttendanceScreen extends StatefulWidget {
  final String? initialLessonId;
  final VoidCallback? onSaved;

  const AttendanceScreen({
    super.key,
    this.initialLessonId,
    this.onSaved,
  });

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  String? _selectedLessonId;
  final Map<String, AttendanceStatusType> _statuses = {};
  final Map<String, AbsenceReason> _reasons = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncSelection();
  }

  void _syncSelection() {
    final appState = context.appState;
    final teacher = appState.currentUser;
    if (teacher == null || teacher.role != UserRole.teacher) {
      return;
    }

    final teacherLessons = appState.lessonsForTeacher(teacher.id);
    if (teacherLessons.isEmpty) {
      _selectedLessonId = null;
      _statuses.clear();
      _reasons.clear();
      return;
    }

    final requestedLessonId = widget.initialLessonId;
    final lessonId = teacherLessons.any((item) => item.id == _selectedLessonId)
        ? _selectedLessonId!
        : teacherLessons.any((item) => item.id == requestedLessonId)
            ? requestedLessonId!
            : teacherLessons.first.id;

    if (lessonId != _selectedLessonId || _statuses.isEmpty) {
      _selectedLessonId = lessonId;
      _seedRoster(lessonId);
    }
  }

  void _seedRoster(String lessonId) {
    final appState = context.appState;
    final lesson = appState.lessonById(lessonId);
    if (lesson == null) {
      _statuses.clear();
      _reasons.clear();
      return;
    }

    final students = appState.studentsForClass(lesson.classId);
    final latestSession = appState.latestAttendanceForLesson(lessonId);
    _statuses
      ..clear()
      ..addEntries(
        students.map(
          (student) => MapEntry(student.id, AttendanceStatusType.present),
        ),
      );
    _reasons
      ..clear()
      ..addEntries(
        students.map((student) => MapEntry(student.id, AbsenceReason.none)),
      );

    if (latestSession != null) {
      for (final entry in latestSession.entries) {
        if (_statuses.containsKey(entry.studentId)) {
          _statuses[entry.studentId] = entry.status;
          _reasons[entry.studentId] = entry.reason;
        }
      }
    }
  }

  Future<void> _saveAttendance() async {
    final lessonId = _selectedLessonId;
    final lesson =
        lessonId == null ? null : context.appState.lessonById(lessonId);
    if (lesson == null) {
      showAppSnackBar(
        context,
        context.tr('Сначала выберите урок.'),
        backgroundColor: context.errorSnackBg,
      );
      return;
    }

    final result = await context.appState.recordAttendance(
      classId: lesson.classId,
      lessonId: lesson.id,
      statuses: Map<String, AttendanceStatusType>.from(_statuses),
      reasons: Map<String, AbsenceReason>.from(_reasons),
    );
    final success = result.isSuccess;
    if (!mounted) {
      return;
    }

    showAppSnackBar(
      context,
      context.tr(
        success
            ? 'Посещаемость сохранена.'
            : 'Не удалось сохранить посещаемость.',
      ),
      backgroundColor:
          success ? const Color(0xFF047857) : const Color(0xFFB91C1C),
    );

    if (success) {
      widget.onSaved?.call();
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
          'Сначала войдите под аккаунтом учителя, чтобы работать с посещаемостью.',
        ),
      );
    }

    final lessons = appState.lessonsForTeacher(teacher.id);
    if (lessons.isEmpty) {
      return _EmptyState(
        title: context.tr('Уроки пока не назначены'),
        subtitle: context.tr(
          'Посещаемость заполняется из расписания после назначения уроков.',
        ),
      );
    }

    final selectedLesson = lessons.firstWhere(
      (item) => item.id == _selectedLessonId,
      orElse: () => lessons.first,
    );
    final students = appState.studentsForClass(selectedLesson.classId);
    final presentCount = _statuses.values
        .where((status) => status == AttendanceStatusType.present)
        .length;
    final lateCount = _statuses.values
        .where((status) => status == AttendanceStatusType.late)
        .length;
    final absentCount = _statuses.values
        .where((status) => status == AttendanceStatusType.absent)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
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
                context.tr('Журнал посещаемости'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '${context.tr(selectedLesson.subject)} • ${context.trf('Класс {value}', {
                      'value': selectedLesson.classId
                    })} • ${selectedLesson.timeRange}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _MetricChip(
              title: context.tr('Всего учеников'),
              value: '${students.length}',
              color: context.primaryTextColor,
            ),
            _MetricChip(
              title: context.tr('Был'),
              value: '$presentCount',
              color: const Color(0xFF059669),
            ),
            _MetricChip(
              title: context.tr('Опоздал'),
              value: '$lateCount',
              color: const Color(0xFFD97706),
            ),
            _MetricChip(
              title: context.tr('Не был'),
              value: '$absentCount',
              color: const Color(0xFFDC2626),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (students.isEmpty)
          _EmptyState(
            title: context.tr('В классе нет учеников'),
            subtitle: context.tr(
              'Добавьте учеников в класс, чтобы заполнить посещаемость.',
            ),
          )
        else
          Column(
            children: [
              for (final student in students)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _StudentAttendanceCard(
                    student: student,
                    status:
                        _statuses[student.id] ?? AttendanceStatusType.present,
                    reason: _reasons[student.id] ?? AbsenceReason.none,
                    onStatusChanged: (status) {
                      setState(() {
                        _statuses[student.id] = status;
                        if (status != AttendanceStatusType.absent) {
                          _reasons[student.id] = AbsenceReason.none;
                        } else if (_reasons[student.id] == AbsenceReason.none) {
                          _reasons[student.id] = AbsenceReason.unexcused;
                        }
                      });
                    },
                    onReasonChanged: (reason) {
                      setState(() {
                        _reasons[student.id] = reason;
                      });
                    },
                  ),
                ),
            ],
          ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _saveAttendance,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            icon: Icon(Icons.task_alt_rounded),
            label: Text(context.tr('Сохранить посещаемость')),
          ),
        ),
      ],
    );
  }
}

class _StudentAttendanceCard extends StatelessWidget {
  final AppUser student;
  final AttendanceStatusType status;
  final AbsenceReason reason;
  final ValueChanged<AttendanceStatusType> onStatusChanged;
  final ValueChanged<AbsenceReason> onReasonChanged;

  const _StudentAttendanceCard({
    required this.student,
    required this.status,
    required this.reason,
    required this.onStatusChanged,
    required this.onReasonChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFEEF2FF),
                foregroundColor: const Color(0xFF4338CA),
                child: Text(student.initials),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.fullName,
                      style: TextStyle(
                        color: context.primaryTextColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if ((student.schoolClass ?? '').isNotEmpty)
                          student.schoolClass!,
                        student.email ?? '',
                      ].join(' • '),
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
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AttendanceStatusType.values.map((item) {
              final isSelected = status == item;
              return ChoiceChip(
                label: Text(context.tr(context.appState.attendanceLabel(item))),
                selected: isSelected,
                onSelected: (_) => onStatusChanged(item),
                selectedColor: _statusColor(item),
                backgroundColor: _statusColor(item).withOpacity(0.12),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : _statusColor(item),
                  fontWeight: FontWeight.w600,
                ),
                side: BorderSide.none,
              );
            }).toList(),
          ),
          if (status == AttendanceStatusType.absent) ...[
            const SizedBox(height: 14),
            Text(
              context.tr('Причина отсутствия'),
              style: TextStyle(
                color: context.primaryTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                AbsenceReason.unexcused,
                AbsenceReason.sickLeave,
                AbsenceReason.excused,
              ].map((item) {
                final isSelected = reason == item;
                return ChoiceChip(
                  label: Text(
                    context.tr(context.appState.absenceReasonLabel(item)),
                  ),
                  selected: isSelected,
                  onSelected: (_) => onReasonChanged(item),
                  selectedColor: const Color(0xFFDC2626),
                  backgroundColor: const Color(0xFFFEE2E2),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFFDC2626),
                    fontWeight: FontWeight.w600,
                  ),
                  side: BorderSide.none,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _MetricChip({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: context.secondaryTextColor,
              fontSize: 13,
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
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(context),
      child: Column(
        children: [
          Icon(
            Icons.event_note_rounded,
            color: Color(0xFF6366F1),
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
