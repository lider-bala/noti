import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../models/user_role.dart';
import '../../widgets/app_theme.dart';

enum StudentSection {
  home,
  schedule,
  homework,
  grades,
  teachers,
  classmates,
  files,
  settings,
}

class StudentSideMenu extends StatelessWidget {
  final AppUser? user;
  final StudentSection current;
  final ValueChanged<StudentSection> onSelect;
  final VoidCallback onLogout;

  const StudentSideMenu({
    super.key,
    required this.user,
    required this.current,
    required this.onSelect,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 260,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: context.panelColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            blurRadius: 28,
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
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF2ECC71),
                      Color(0xFF10B981),
                    ],
                  ),
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 18,
                      offset: Offset(0, 10),
                      color: Color(0x22000000),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'И',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.fullName ?? context.tr('dashboard.student'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: context.primaryTextColor,
                      ),
                    ),
                    Text(
                      user?.schoolClass != null
                          ? '${user!.schoolClass} ${context.tr('auth.class').toLowerCase()}'
                          : context.tr('dashboard.student'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
            icon: Icons.home_filled,
            label: context.tr('section.home'),
            isActive: current == StudentSection.home,
            onTap: () => onSelect(StudentSection.home),
          ),
          _MenuTile(
            icon: Icons.calendar_month_outlined,
            label: context.tr('section.schedule'),
            isActive: current == StudentSection.schedule,
            onTap: () => onSelect(StudentSection.schedule),
          ),
          _MenuTile(
            icon: Icons.assignment_outlined,
            label: context.tr('section.homework'),
            isActive: current == StudentSection.homework,
            onTap: () => onSelect(StudentSection.homework),
          ),
          _MenuTile(
            icon: Icons.bar_chart_rounded,
            label: context.tr('section.grades'),
            isActive: current == StudentSection.grades,
            onTap: () => onSelect(StudentSection.grades),
          ),
          _MenuTile(
            icon: Icons.school_outlined,
            label: context.tr('section.teachers'),
            isActive: current == StudentSection.teachers,
            onTap: () => onSelect(StudentSection.teachers),
          ),
          _MenuTile(
            icon: Icons.group_outlined,
            label: context.tr('section.classmates'),
            isActive: current == StudentSection.classmates,
            onTap: () => onSelect(StudentSection.classmates),
          ),
          _MenuTile(
            icon: Icons.folder_open_outlined,
            label: context.tr('section.files'),
            isActive: current == StudentSection.files,
            onTap: () => onSelect(StudentSection.files),
          ),
          _MenuTile(
            icon: Icons.settings_outlined,
            label: context.tr('section.settings'),
            isActive: current == StudentSection.settings,
            onTap: () => onSelect(StudentSection.settings),
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: onLogout,
            icon: Icon(Icons.logout, size: 18),
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
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
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
                    fontWeight:
                        isActive ? FontWeight.w700 : FontWeight.w500,
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
