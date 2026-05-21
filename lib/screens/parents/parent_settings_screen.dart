import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/theme_mode_selector.dart';

class ParentSettingsScreen extends StatefulWidget {
  const ParentSettingsScreen({super.key});

  @override
  State<ParentSettingsScreen> createState() => _ParentSettingsScreenState();
}

class _ParentSettingsScreenState extends State<ParentSettingsScreen> {
  bool _notifications = true;
  bool _weeklyReport = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('section.settings'),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: context.primaryTextColor,
              ),
        ),
        const SizedBox(height: 12),
        _InfoTile(
          icon: Icons.person_outline_rounded,
          title: context.tr('Профиль'),
          subtitle: context.tr('Данные родителя'),
          description: context.tr(
            'В профиле родителя хранятся имя, email, телефон и связь с учеником. Привязку к ребенку выполняет администратор.',
          ),
        ),
        const SizedBox(height: 8),
        _InfoTile(
          icon: Icons.lock_outline_rounded,
          title: context.tr('Безопасность'),
          subtitle: context.tr('Доступ к аккаунту'),
          description: context.tr(
            'Вход выполняется по email, паролю и роли родителя. Если пароль потерян, обратитесь к администратору школы.',
          ),
        ),
        const SizedBox(height: 8),
        _InfoTile(
          icon: Icons.shield_outlined,
          title: context.tr('Приватность'),
          subtitle: context.tr('Данные ребенка'),
          description: context.tr(
            'Родитель видит только данные точно привязанного ученика: оценки, посещаемость, домашние задания, файлы и уведомления.',
          ),
        ),
        const SizedBox(height: 12),
        const ThemeModeSelector(),
        const SizedBox(height: 8),
        _SettingTile(
          title: context.tr('settings.push'),
          subtitle: context.tr('settings.pushSubtitle'),
          value: _notifications,
          onChanged: (value) => setState(() => _notifications = value),
        ),
        const SizedBox(height: 8),
        _SettingTile(
          title: context.tr('settings.weeklyReport'),
          subtitle: context.tr('settings.weeklyReportSubtitle'),
          value: _weeklyReport,
          onChanged: (value) => setState(() => _weeklyReport = value),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String description;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _showInfo(context),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.panelColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.appBorderColor),
        ),
        child: Row(
          children: [
            Icon(icon, color: context.secondaryTextColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: context.primaryTextColor,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style: TextStyle(
                          color: context.secondaryTextColor, fontSize: 13)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: context.secondaryTextColor),
          ],
        ),
      ),
    );
  }

  void _showInfo(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: context.panelColor,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                    color: sheetContext.primaryTextColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Text(description,
                style: TextStyle(
                    color: sheetContext.secondaryTextColor,
                    fontSize: 15,
                    height: 1.45)),
          ],
        ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.panelColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.appBorderColor),
        boxShadow: [
          BoxShadow(
            blurRadius: 16,
            offset: const Offset(0, 10),
            color: Colors.black.withOpacity(context.isDarkTheme ? 0.28 : 0.08),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: context.primaryTextColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
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
          Switch(
            value: value,
            activeColor: const Color(0xFF10B981),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
