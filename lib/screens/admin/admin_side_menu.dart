import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../widgets/app_theme.dart';

enum AdminSection {
  overview,
  users,
  academics,
  classSchedule,
  teacherSchedule,
  chat,
  analytics,
  settings,
}

class AdminSideMenu extends StatelessWidget {
  final AdminSection current;
  final ValueChanged<AdminSection> onSelect;
  final VoidCallback onLogout;

  const AdminSideMenu({
    super.key,
    required this.current,
    required this.onSelect,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.appState.currentUser;

    return Container(
      width: 280,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: context.panelColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            blurRadius: 30,
            offset: Offset(0, 16),
            color: Color(0x14000000),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF111827),
                      Color(0xFF374151),
                    ],
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  user?.initials ?? 'AD',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.fullName ?? context.tr('role.admin'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: context.primaryTextColor,
                      ),
                    ),
                    Text(
                      context.tr('dashboard.admin'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: context.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _MenuTile(
            icon: Icons.space_dashboard_rounded,
            label: context.tr('section.overview'),
            isActive: current == AdminSection.overview,
            onTap: () => onSelect(AdminSection.overview),
          ),
          _MenuTile(
            icon: Icons.manage_accounts_rounded,
            label: context.tr('section.users'),
            isActive: current == AdminSection.users,
            onTap: () => onSelect(AdminSection.users),
          ),
          _MenuTile(
            icon: Icons.school_rounded,
            label: context.tr('section.academics'),
            isActive: current == AdminSection.academics,
            onTap: () => onSelect(AdminSection.academics),
          ),
          _MenuTile(
            icon: Icons.calendar_month_rounded,
            label: context.tr('Расписание классов'),
            isActive: current == AdminSection.classSchedule,
            onTap: () => onSelect(AdminSection.classSchedule),
          ),
          _MenuTile(
            icon: Icons.assignment_ind_rounded,
            label: context.tr('Расписание учителей'),
            isActive: current == AdminSection.teacherSchedule,
            onTap: () => onSelect(AdminSection.teacherSchedule),
          ),
          _MenuTile(
            icon: Icons.chat_rounded,
            label: context.tr('Чат'),
            isActive: current == AdminSection.chat,
            onTap: () => onSelect(AdminSection.chat),
          ),
          _MenuTile(
            icon: Icons.insights_rounded,
            label: context.tr('section.analytics'),
            isActive: current == AdminSection.analytics,
            onTap: () => onSelect(AdminSection.analytics),
          ),
          _MenuTile(
            icon: Icons.settings_outlined,
            label: context.tr('section.settings'),
            isActive: current == AdminSection.settings,
            onTap: () => onSelect(AdminSection.settings),
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: onLogout,
            icon: Icon(Icons.logout_rounded, size: 18),
            label: Text(context.tr('common.logout')),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(46),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isActive
                ? theme.colorScheme.primary.withOpacity(0.08)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isActive
                    ? theme.colorScheme.primary
                    : context.secondaryTextColor,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isActive
                        ? theme.colorScheme.primary
                        : context.secondaryTextColor,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
