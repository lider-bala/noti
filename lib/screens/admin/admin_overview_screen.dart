import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../models/school_models.dart';
import '../../models/user_role.dart';
import '../../widgets/admin_panel.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/app_theme.dart';

class AdminOverviewScreen extends StatelessWidget {
  final VoidCallback? onShowAllRequests;

  const AdminOverviewScreen({
    super.key,
    this.onShowAllRequests,
  });

  @override
  Widget build(BuildContext context) {
    final appState = context.appState;
    final requests = appState.registrationRequests
        .where((item) => item.status == RegistrationStatus.pending)
        .take(3)
        .toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Приветственная карточка
          _HeroCard(
            title: context.tr('Операционный центр школы'),
            subtitle: context.tr(
              'Управляйте доступом, академической структурой, уроками, файлами и ключевыми сценариями работы школы.',
            ),
          ),
          const SizedBox(height: 24),

          // Панель метрик
          _MetricsPanel(appState: appState),
          const SizedBox(height: 24),

          // Две колонки: состояние и заявки
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 900) {
                // Мобильный вид - один столбец
                return Column(
                  children: [
                    _StatusPanel(
                      filesCount: appState.managedFiles.length,
                      attendanceCount: appState.attendanceSessions.length,
                    ),
                    const SizedBox(height: 24),
                    _RequestsPanel(
                      requests: requests,
                      onShowAllRequests: onShowAllRequests,
                    ),
                  ],
                );
              } else {
                // Десктопный вид - два столбца
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _StatusPanel(
                        filesCount: appState.managedFiles.length,
                        attendanceCount: appState.attendanceSessions.length,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _RequestsPanel(
                        requests: requests,
                        onShowAllRequests: onShowAllRequests,
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _MetricsPanel extends StatelessWidget {
  final AppState appState;

  const _MetricsPanel({required this.appState});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: _getGridColumns(context),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        MetricCard(
          title: context.tr('Активные аккаунты'),
          value: '${appState.accounts.length}',
          icon: Icons.groups_rounded,
          gradient: const [Color(0xFF10B981), Color(0xFF059669)],
        ),
        MetricCard(
          title: context.tr('Заявки на доступ'),
          value: '${appState.pendingRequestsCount}',
          icon: Icons.mark_email_unread_rounded,
          gradient: const [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
        ),
        MetricCard(
          title: context.tr('Классы'),
          value: '${appState.schoolClasses.length}',
          icon: Icons.meeting_room_rounded,
          gradient: const [Color(0xFFF59E0B), Color(0xFFD97706)],
        ),
        MetricCard(
          title: context.tr('Уроки в системе'),
          value: '${appState.lessons.length}',
          icon: Icons.event_note_rounded,
          gradient: const [Color(0xFFA855F7), Color(0xFF7C3AED)],
        ),
      ],
    );
  }

  int _getGridColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 400) return 1;
    if (width < 600) return 2;
    if (width < 1200) return 2;
    return 4;
  }
}

class _HeroCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _HeroCard({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF0F766E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            blurRadius: 28,
            offset: Offset(0, 18),
            color: Color(0x33000000),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  final int filesCount;
  final int attendanceCount;

  const _StatusPanel({
    required this.filesCount,
    required this.attendanceCount,
  });

  @override
  Widget build(BuildContext context) {
    return AdminPanel(
      title: context.tr('Состояние системы'),
      icon: Icons.info_rounded,
      children: [
        Text(
          context.tr(
            'Все основные процессы работают на едином контуре данных: регистрация, уроки, посещаемость и школьные файлы.',
          ),
          style: TextStyle(
            color: context.secondaryTextColor,
            height: 1.4,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 24),
        _StatusRow(
          label: context.tr('Файлы в каталоге'),
          value: '$filesCount',
          badgeColor: const Color(0xFFDBEAFE),
          textColor: const Color(0xFF1D4ED8),
        ),
        const SizedBox(height: 12),
        _StatusRow(
          label: context.tr('Сохранённые сессии посещаемости'),
          value: '$attendanceCount',
          badgeColor: const Color(0xFFDCFCE7),
          textColor: const Color(0xFF047857),
        ),
      ],
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final String value;
  final Color badgeColor;
  final Color textColor;

  const _StatusRow({
    required this.label,
    required this.value,
    required this.badgeColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: context.secondaryTextColor,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: badgeColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

class _RequestsPanel extends StatelessWidget {
  final List<RegistrationRequest> requests;
  final VoidCallback? onShowAllRequests;

  const _RequestsPanel({
    required this.requests,
    this.onShowAllRequests,
  });

  @override
  Widget build(BuildContext context) {
    return AdminPanel(
      title: context.tr('Очередь заявок'),
      icon: Icons.mail_rounded,
      children: [
        if (requests.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFDCFCE7)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.tr(
                      'Новых запросов нет. Доступы и структура школы синхронизированы.',
                    ),
                    style: const TextStyle(
                      color: Color(0xFF047857),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Column(
            children: [
              for (int i = 0; i < requests.length; i++) ...[
                if (i != 0) ...[
                  const SizedBox(height: 12),
                  Container(height: 1, color: context.appBorderColor),
                  const SizedBox(height: 12),
                ],
                _RequestCard(request: requests[i]),
              ],
            ],
          ),
        if (requests.isNotEmpty) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: Material(
              color: context.panelMutedColor,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: onShowAllRequests,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        context.tr('Показать все заявки'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: Color(0xFF6366F1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _RequestCard extends StatelessWidget {
  final RegistrationRequest request;

  const _RequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final appState = context.appState;

    return Row(
      children: [
        CircleAvatar(
          backgroundColor: const Color(0xFFECFDF5),
          foregroundColor: const Color(0xFF047857),
          radius: 24,
          child: Text(
            request.fullName.substring(0, 1).toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                request.fullName,
                style: TextStyle(
                  color: context.primaryTextColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                [
                  _roleLabel(request.role, context),
                  if ((request.schoolClass ?? '').isNotEmpty)
                    request.schoolClass!,
                ].join(' • '),
                style: TextStyle(
                  color: context.secondaryTextColor,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                request.email,
                style: TextStyle(
                  color: context.secondaryTextColor.withOpacity(0.82),
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        IconButton(
          icon:
              const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981)),
          onPressed: () async {
            final result =
                await appState.approveRegistrationRequest(request.id);
            if (!context.mounted) {
              return;
            }
            final success = result.isSuccess;
            showAppSnackBar(
              context,
              context.tr(
                success ? 'Заявка одобрена.' : 'Не удалось обработать заявку.',
              ),
              backgroundColor:
                  success ? const Color(0xFF047857) : const Color(0xFFB91C1C),
            );
          },
          tooltip: 'Одобрить',
        ),
      ],
    );
  }

  String _roleLabel(UserRole role, BuildContext context) {
    switch (role) {
      case UserRole.student:
        return context.tr('Ученик');
      case UserRole.teacher:
        return context.tr('Учитель');
      case UserRole.parent:
        return context.tr('Родитель');
      case UserRole.admin:
        return context.tr('Администратор');
    }
  }
}

class AppStringsHelper {
  final BuildContext context;
  AppStringsHelper(this.context);

  String role(UserRole role) {
    switch (role) {
      case UserRole.student:
        return context.tr('Ученик');
      case UserRole.teacher:
        return context.tr('Учитель');
      case UserRole.parent:
        return context.tr('Родитель');
      case UserRole.admin:
        return context.tr('Администратор');
    }
  }
}
