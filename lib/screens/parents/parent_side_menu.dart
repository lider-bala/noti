import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../models/user_role.dart';
import '../../widgets/app_theme.dart';

enum ParentSection {
  home,
  schedule,
  homework,
  grades,
  attendance,
  notifications,
  teachers,
  settings,
}

class ParentSideMenu extends StatelessWidget {
  final AppUser? user;
  final ParentSection current;
  final ValueChanged<ParentSection> onSelect;
  final VoidCallback onLogout;

  const ParentSideMenu({
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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
                    'П',
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
                      user?.fullName ?? context.tr('dashboard.parent'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: context.primaryTextColor,
                      ),
                    ),
                    Text(
                      user?.email ?? context.tr('dashboard.parent'),
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
            isActive: current == ParentSection.home,
            onTap: () => onSelect(ParentSection.home),
          ),
          _MenuTile(
            icon: Icons.calendar_month_outlined,
            label: context.tr('section.schedule'),
            isActive: current == ParentSection.schedule,
            onTap: () => onSelect(ParentSection.schedule),
          ),
          _MenuTile(
            icon: Icons.assignment_turned_in_outlined,
            label: context.tr('section.homework'),
            isActive: current == ParentSection.homework,
            onTap: () => onSelect(ParentSection.homework),
          ),
          _MenuTile(
            icon: Icons.bar_chart_rounded,
            label: context.tr('section.grades'),
            isActive: current == ParentSection.grades,
            onTap: () => onSelect(ParentSection.grades),
          ),
          _MenuTile(
            icon: Icons.fact_check_outlined,
            label: context.tr('section.attendance'),
            isActive: current == ParentSection.attendance,
            onTap: () => onSelect(ParentSection.attendance),
          ),
          _MenuTile(
            icon: Icons.notifications_outlined,
            label: context.tr('section.notifications'),
            isActive: current == ParentSection.notifications,
            onTap: () => onSelect(ParentSection.notifications),
          ),
          _MenuTile(
            icon: Icons.school_outlined,
            label: context.tr('section.teachers'),
            isActive: current == ParentSection.teachers,
            onTap: () => onSelect(ParentSection.teachers),
          ),
          _MenuTile(
            icon: Icons.settings_outlined,
            label: context.tr('section.settings'),
            isActive: current == ParentSection.settings,
            onTap: () => onSelect(ParentSection.settings),
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
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
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
