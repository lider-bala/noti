import 'package:flutter/material.dart';

import '../app/app_state.dart';
import '../models/user_role.dart';
import 'app_theme.dart';

enum MainSection {
  home,
  schedule,
  attendance,
  homework,
  students,
  teachers,
  grades,
  files,
  settings,
}

class SideMenu extends StatelessWidget {
  final AppUser? user;
  final MainSection current;
  final ValueChanged<MainSection> onSelect;
  final VoidCallback onLogout;

  const SideMenu({
    super.key,
    required this.user,
    required this.current,
    required this.onSelect,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: const Color(0xFFECFEFF),
                ),
                child: Icon(
                  Icons.notifications_active_outlined,
                  color: const Color(0xFF0EA5E9),
                  size: 22,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.fullName ?? context.tr('app.name'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    Text(
                      user?.email ?? context.tr('dashboard.teacher'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: context.secondaryTextColor,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _MenuTile(
                    icon: Icons.home_filled,
                    label: context.tr('section.home'),
                    isActive: current == MainSection.home,
                    onTap: () => onSelect(MainSection.home),
                  ),
                  _MenuTile(
                    icon: Icons.calendar_month_outlined,
                    label: context.tr('section.schedule'),
                    isActive: current == MainSection.schedule,
                    onTap: () => onSelect(MainSection.schedule),
                  ),
                  _MenuTile(
                    icon: Icons.assignment_outlined,
                    label: context.tr('section.homework'),
                    isActive: current == MainSection.homework,
                    onTap: () => onSelect(MainSection.homework),
                  ),
                  _MenuTile(
                    icon: Icons.group_outlined,
                    label: context.tr('section.students'),
                    isActive: current == MainSection.students,
                    onTap: () => onSelect(MainSection.students),
                  ),
                  _MenuTile(
                    icon: Icons.school_outlined,
                    label: context.tr('section.teachers'),
                    isActive: current == MainSection.teachers,
                    onTap: () => onSelect(MainSection.teachers),
                  ),
                  _MenuTile(
                    icon: Icons.bar_chart_rounded,
                    label: context.tr('section.grades'),
                    isActive: current == MainSection.grades,
                    onTap: () => onSelect(MainSection.grades),
                  ),
                  _MenuTile(
                    icon: Icons.folder_open_outlined,
                    label: context.tr('section.files'),
                    isActive: current == MainSection.files,
                    onTap: () => onSelect(MainSection.files),
                  ),
                  _MenuTile(
                    icon: Icons.settings_outlined,
                    label: context.tr('section.settings'),
                    isActive: current == MainSection.settings,
                    onTap: () => onSelect(MainSection.settings),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onLogout,
            icon: Icon(Icons.logout, size: 18),
            label: Text(
              context.tr('common.logout'),
              style: TextStyle(fontSize: 14),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: Size.fromHeight(46),
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
      padding: EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isActive
                        ? theme.colorScheme.primary
                        : context.secondaryTextColor,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
              if (isActive)
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.primary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
