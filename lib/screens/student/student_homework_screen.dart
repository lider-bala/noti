import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../models/school_models.dart';
import '../../services/file_upload_service.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/app_theme.dart';

class StudentHomeworkScreen extends StatefulWidget {
  const StudentHomeworkScreen({super.key});

  @override
  State<StudentHomeworkScreen> createState() => _StudentHomeworkScreenState();
}

class _StudentHomeworkScreenState extends State<StudentHomeworkScreen> {
  String? _submittingAssignmentId;

  Future<void> _submitFile(HomeworkAssignment assignment) async {
    final appState = context.appState;
    final user = appState.currentUser;
    if (user == null) {
      return;
    }

    setState(() => _submittingAssignmentId = assignment.id);
    try {
      final uploaded = await FileUploadService().pickAndUpload(
        folder: 'homework-submissions',
        ownerId: user.id,
      );
      if (!mounted) {
        return;
      }
      if (uploaded == null) {
        setState(() => _submittingAssignmentId = null);
        return;
      }
      final submissionResult = await appState.submitHomeworkFile(
        assignmentId: assignment.id,
        fileName: uploaded.fileName,
        sizeLabel: uploaded.sizeLabel,
        storagePath: uploaded.storagePath,
        downloadUrl: uploaded.downloadUrl,
      );
      if (!mounted) {
        return;
      }
      final submission = submissionResult.data;
      setState(() => _submittingAssignmentId = null);
      showAppSnackBar(
        context,
        submission == null
            ? context.tr('Не удалось сдать файл.')
            : context.tr('Файл сдан и сохранён в базе.'),
        backgroundColor: submission == null
            ? const Color(0xFFB91C1C)
            : const Color(0xFF047857),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _submittingAssignmentId = null);
      showAppSnackBar(
        context,
        context.tr('Не удалось загрузить файл. Проверьте Firebase Storage.'),
        backgroundColor: context.errorSnackBg,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.appState;
    final student = appState.currentUser;
    final assignments = student == null
        ? const <HomeworkAssignment>[]
        : appState.assignmentsForStudent(student.id);
    final submitted = assignments
        .where(
          (assignment) =>
              student != null &&
              appState.submissionForAssignment(
                    assignmentId: assignment.id,
                    studentId: student.id,
                  ) !=
                  null,
        )
        .length;
    final pending = assignments.length - submitted;
    final urgent =
        assignments.where((assignment) => _isUrgent(assignment)).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _HeaderCard(),
          const SizedBox(height: 24),
          _StatsRow(
            notSubmitted: pending,
            urgent: urgent,
            completed: submitted,
          ),
          SizedBox(height: 24),
          if (assignments.isEmpty)
            _EmptyState(
              title: context.tr('Заданий пока нет'),
              subtitle: context.tr(
                'Когда учитель назначит домашнее задание или контрольную, оно появится здесь.',
              ),
            )
          else
            Column(
              children: [
                for (int i = 0; i < assignments.length; i++) ...[
                  if (i != 0) const SizedBox(height: 12),
                  _HomeworkCard(
                    item: assignments[i],
                    submission: student == null
                        ? null
                        : appState.submissionForAssignment(
                            assignmentId: assignments[i].id,
                            studentId: student.id,
                          ),
                    isSubmitting: _submittingAssignmentId == assignments[i].id,
                    onSubmit: () => _submitFile(assignments[i]),
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
  const _HeaderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF34D399),
            Color(0xFF14B8A6),
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
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('Домашние задания'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6),
          Text(
            context.tr('Твои задания, контрольные и реальные файлы сдачи'),
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

class _StatsRow extends StatelessWidget {
  final int notSubmitted;
  final int urgent;
  final int completed;

  const _StatsRow({
    required this.notSubmitted,
    required this.urgent,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final crossAxisCount = constraints.maxWidth < 360
            ? 1
            : (constraints.maxWidth < 500 ? 2 : 3);
        final itemWidth =
            (constraints.maxWidth - spacing * (crossAxisCount - 1)) /
                crossAxisCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
              width: itemWidth,
              child: _StatCard(
                value: '$notSubmitted',
                label: context.tr('Не сдано'),
                bgColor: const Color(0xFFFFF7ED),
                borderColor: const Color(0xFFFFEDD5),
                textColor: const Color(0xFFEA580C),
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _StatCard(
                value: '$urgent',
                label: context.tr('Срочные'),
                bgColor: context.blueTintBg,
                borderColor: const Color(0xFFDBEAFE),
                textColor: const Color(0xFF2563EB),
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _StatCard(
                value: '$completed',
                label: context.tr('Выполнено'),
                bgColor: const Color(0xFFECFDF5),
                borderColor: context.greenTintBg,
                textColor: const Color(0xFF059669),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color bgColor;
  final Color borderColor;
  final Color textColor;

  const _StatCard({
    required this.value,
    required this.label,
    required this.bgColor,
    required this.borderColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: textColor,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor.withOpacity(0.9),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeworkCard extends StatelessWidget {
  final HomeworkAssignment item;
  final HomeworkSubmission? submission;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  const _HomeworkCard({
    required this.item,
    required this.submission,
    required this.isSubmitting,
    required this.onSubmit,
  });

  bool get _isSubmitted => submission != null;

  Color get _borderColor {
    if (_isSubmitted) {
      return const Color(0xFFA7F3D0);
    }
    if (_isUrgent(item)) {
      return const Color(0xFFFED7AA);
    }
    return const Color(0xFFF3F4F6);
  }

  Color get _iconBg {
    if (_isSubmitted) {
      return const Color(0xFFDCFCE7);
    }
    if (_isUrgent(item)) {
      return const Color(0xFFFFEDD5);
    }
    return const Color(0xFFDBEAFE);
  }

  Color get _iconColor {
    if (_isSubmitted) {
      return const Color(0xFF059669);
    }
    if (_isUrgent(item)) {
      return const Color(0xFFEA580C);
    }
    return const Color(0xFF2563EB);
  }

  @override
  Widget build(BuildContext context) {
    final teacher = context.appState.userById(item.teacherId);

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _borderColor,
          width: 2,
        ),
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
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  item.kind == AssignmentKind.testWork
                      ? Icons.quiz_rounded
                      : Icons.menu_book_rounded,
                  color: _iconColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 180),
                          child: Text(
                            context.tr(item.subject),
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: context.primaryTextColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (item.kind == AssignmentKind.testWork)
                          _Badge(
                            text: context.tr('Контрольная работа'),
                            color: const Color(0xFF7C3AED),
                          ),
                        if (_isUrgent(item) && !_isSubmitted)
                          Text(
                            context.tr('Срочно!'),
                            style: const TextStyle(
                              color: Color(0xFFEA580C),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      context.tr(item.title),
                      style: TextStyle(
                        color: Color(0xFF374151),
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      context.tr(item.description),
                      style: TextStyle(
                        color: context.secondaryTextColor,
                        fontSize: 12,
                      ),
                    ),
                    if (teacher != null) ...[
                      SizedBox(height: 4),
                      Text(
                        teacher.fullName,
                        style: TextStyle(
                          color: context.secondaryTextColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (_isSubmitted)
                const Icon(
                  Icons.check_circle_rounded,
                  size: 24,
                  color: Color(0xFF10B981),
                )
              else if (_isUrgent(item))
                const Icon(
                  Icons.access_time_rounded,
                  size: 24,
                  color: Color(0xFFF97316),
                ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final left = Wrap(
                spacing: 12,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _InlineInfo(
                    icon: Icons.calendar_month_rounded,
                    text: context.trf(
                      'Сдать до {value}',
                      {'value': _dateLabel(item.dueAt)},
                    ),
                  ),
                  if (item.requiresFile)
                    _InlineInfo(
                      icon: Icons.attach_file,
                      text: context.tr('Файлы'),
                    ),
                  if (_isSubmitted)
                    _InlineInfo(
                      icon: submission!.late
                          ? Icons.schedule_rounded
                          : Icons.check_rounded,
                      text: submission!.late
                          ? '${context.tr('Сдано поздно')}: ${submission!.fileName}'
                          : '${context.tr('Сдано')}: ${submission!.fileName}',
                    ),
                ],
              );

              final submitButton = item.requiresFile && !_isSubmitted
                  ? ElevatedButton.icon(
                      onPressed: isSubmitting ? null : onSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        shadowColor: const Color(0x33000000),
                      ),
                      icon: isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              Icons.upload_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                      label: Text(
                        context.tr('Сдать'),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : null;

              if (constraints.maxWidth < 520) {
                return Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    left,
                    if (submitButton != null) submitButton,
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: left),
                  if (submitButton != null) submitButton,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _InlineInfo extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InlineInfo({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF4B5563)),
        SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: context.tertiaryTextColor,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;

  const _Badge({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
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
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.appBorderColor),
      ),
      child: Column(
        children: [
          Icon(Icons.assignment_outlined, color: context.secondaryTextColor),
          SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: context.primaryTextColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4),
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

bool _isUrgent(HomeworkAssignment assignment) {
  return assignment.urgent ||
      assignment.dueAt.difference(DateTime.now()).inHours <= 48;
}

String _dateLabel(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day.$month.${date.year}';
}
