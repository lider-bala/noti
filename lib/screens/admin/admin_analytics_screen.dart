import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../models/user_role.dart';
import '../../widgets/app_theme.dart';

class AdminAnalyticsScreen extends StatelessWidget {
  const AdminAnalyticsScreen({super.key});

  int _completedScenarioCount(BuildContext context) {
    final state = context.appState;
    return [
      state.accounts.isNotEmpty,
      state.registrationRequests.isNotEmpty,
      state.lessons.isNotEmpty,
      state.attendanceSessions.isNotEmpty,
      state.homeworkAssignments.isNotEmpty,
    ].where((item) => item).length;
  }

  @override
  Widget build(BuildContext context) {
    final accounts = context.appState.accounts;
    final roleCounts = {
      for (final role in UserRole.values)
        role: accounts.where((account) => account.user.role == role).length,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(
          title: context.tr('admin.analytics.title'),
          subtitle: context.tr('admin.analytics.subtitle'),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _Metric(
              title: context.tr('admin.analytics.activity'),
              value: '${_completedScenarioCount(context)}/5',
              subtitle: context.tr(
                'Вход, регистрация, смена языка и выход работают стабильно',
              ),
            ),
            _Metric(
              title: context.tr('admin.analytics.roleBreakdown'),
              value: '${accounts.length}',
              subtitle: context.tr(
                'Учителя, ученики, родители и администраторы в едином реестре',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.panelColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: context.appBorderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('admin.analytics.roleBreakdown'),
                style: TextStyle(
                  color: context.primaryTextColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              for (final role in UserRole.values) ...[
                _RoleProgress(
                  label: context.strings.role(role),
                  count: roleCounts[role] ?? 0,
                  total: accounts.length,
                ),
                if (role != UserRole.values.last) const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final String subtitle;

  const _Header({
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
          colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
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
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;

  const _Metric({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      child: Container(
        padding: EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: context.panelColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: context.appBorderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: context.secondaryTextColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                color: context.primaryTextColor,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                color: context.secondaryTextColor,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleProgress extends StatelessWidget {
  final String label;
  final int count;
  final int total;

  const _RoleProgress({
    required this.label,
    required this.count,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final factor = total == 0 ? 0.0 : count / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: context.primaryTextColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '$count',
              style: TextStyle(
                color: context.secondaryTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: factor,
            minHeight: 10,
            backgroundColor: context.appBorderColor,
            color: const Color(0xFF2563EB),
          ),
        ),
      ],
    );
  }
}
