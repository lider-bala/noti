import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/theme_mode_selector.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.appState.currentUser;

    final sections = <_SettingsSection>[
      _SettingsSection(
        title: context.tr('settings.account'),
        items: [
          _SettingsItem(
            icon: Icons.person_outline_rounded,
            label: context.tr('settings.profile'),
            title: context.tr('Профиль'),
            description: context.tr(
              'Здесь отображаются имя, email, телефон, роль и статус аккаунта. Изменение этих данных выполняет администратор школы.',
            ),
          ),
          _SettingsItem(
            icon: Icons.lock_outline_rounded,
            label: context.tr('settings.security'),
            title: context.tr('Безопасность'),
            description: context.tr(
              'Для входа используется защищенная авторизация. Не передавайте пароль другим людям. Если доступ потерян, обратитесь к администратору для сброса.',
            ),
          ),
          _SettingsItem(
            icon: Icons.shield_outlined,
            label: context.tr('settings.privacy'),
            title: context.tr('Приватность'),
            description: context.tr(
              'Учителя видят только свои классы, уроки, оценки и посещаемость. Личные данные учеников и родителей доступны только по назначенным связям.',
            ),
          ),
        ],
      ),
      _SettingsSection(
        title: context.tr('settings.preferences'),
        items: [
          _SettingsItem.toggle(
            icon: Icons.notifications_none_rounded,
            label: context.tr('settings.notifications'),
            value: _notifications,
            onChanged: (value) {
              setState(() => _notifications = value);
            },
          ),
          _SettingsItem(
            icon: Icons.palette_outlined,
            label: context.tr('settings.appearance'),
            title: context.tr('Внешний вид'),
            description: context.tr(
              'Тему приложения можно изменить ниже. Выбранный режим применяется ко всем разделам текущего устройства.',
            ),
          ),
          _SettingsItem(
            icon: Icons.language_rounded,
            label: context.tr('settings.language'),
            badge: context.strings.languageLabel(context.appState.language),
            title: context.tr('Язык'),
            description: context.tr(
              'Для текущей версии Noti KG интерфейс закреплен на русском языке.',
            ),
          ),
        ],
      ),
      _SettingsSection(
        title: context.tr('settings.support'),
        items: [
          _SettingsItem(
            icon: Icons.help_outline_rounded,
            label: context.tr('settings.help'),
            title: context.tr('Помощь'),
            description: context.tr(
              'По вопросам расписания, оценок, домашних заданий и файлов обращайтесь к администратору школы.',
            ),
          ),
          _SettingsItem(
            icon: Icons.support_agent_rounded,
            label: context.tr('settings.contact'),
            title: context.tr('Связаться с нами'),
            description: context.tr(
              'Поддержка Noti KG принимает обращения через администратора школы. Передайте описание проблемы, роль аккаунта и экран, где она возникла.',
            ),
          ),
        ],
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF94A3B8),
                Color(0xFF64748B),
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
                context.tr('section.settings'),
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 8),
              Text(
                context.tr('admin.settings.subtitle'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: context.panelColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: context.appBorderColor),
            boxShadow: const [
              BoxShadow(
                blurRadius: 24,
                offset: Offset(0, 14),
                color: Color(0x14000000),
              ),
            ],
          ),
          padding: EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF2ECC71),
                      Color(0xFF10B981),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Text(
                  user?.initials ?? 'NT',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.fullName ?? context.tr('dashboard.teacher'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: context.primaryTextColor,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      user?.email ?? 'teacher@noti.kg',
                      style: TextStyle(
                        fontSize: 13,
                        color: context.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: context.secondaryTextColor,
              ),
            ],
          ),
        ),
        SizedBox(height: 20),
        for (var sectionIndex = 0;
            sectionIndex < sections.length;
            sectionIndex++) ...[
          Text(
            sections[sectionIndex].title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: context.primaryTextColor,
            ),
          ),
          SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: context.panelColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: context.appBorderColor),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 24,
                  offset: Offset(0, 14),
                  color: Color(0x14000000),
                ),
              ],
            ),
            child: Column(
              children: [
                for (var i = 0; i < sections[sectionIndex].items.length; i++)
                  _SettingsTile(
                    item: sections[sectionIndex].items[i],
                    isLast: i == sections[sectionIndex].items.length - 1,
                  ),
              ],
            ),
          ),
          SizedBox(height: 16),
        ],
        const ThemeModeSelector(),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: context.panelMutedColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.appBorderColor),
          ),
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Column(
            children: [
              Text(
                context.tr('app.tagline'),
                style: TextStyle(
                  fontSize: 13,
                  color: context.secondaryTextColor,
                ),
              ),
              SizedBox(height: 4),
              Text(
                context.tr('Версия 1.0.0'),
                style: TextStyle(
                  fontSize: 11,
                  color: context.secondaryTextColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsSection {
  final String title;
  final List<_SettingsItem> items;

  _SettingsSection({
    required this.title,
    required this.items,
  });
}

class _SettingsItem {
  final IconData icon;
  final String label;
  final bool isToggle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? badge;
  final String? title;
  final String? description;

  _SettingsItem({
    required this.icon,
    required this.label,
    this.isToggle = false,
    this.value = false,
    this.onChanged,
    this.badge,
    this.title,
    this.description,
  });

  _SettingsItem.toggle({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) : this(
          icon: icon,
          label: label,
          isToggle: true,
          value: value,
          onChanged: onChanged,
        );
}

class _SettingsTile extends StatelessWidget {
  final _SettingsItem item;
  final bool isLast;

  const _SettingsTile({
    required this.item,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.isToggle && item.onChanged != null
          ? () => item.onChanged!(!item.value)
          : item.description == null
              ? null
              : () => _showSettingsDetails(context, item),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(
                    color: context.appBorderColor,
                  ),
                ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: context.panelMutedColor,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Icon(
                item.icon,
                size: 20,
                color: context.secondaryTextColor,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  fontSize: 15,
                  color: context.primaryTextColor,
                ),
              ),
            ),
            if (item.isToggle)
              _SettingsSwitch(value: item.value)
            else if (item.badge != null)
              Text(
                item.badge!,
                style: TextStyle(
                  fontSize: 13,
                  color: context.secondaryTextColor,
                ),
              )
            else
              Icon(
                Icons.chevron_right_rounded,
                color: context.secondaryTextColor,
              ),
          ],
        ),
      ),
    );
  }
}

void _showSettingsDetails(BuildContext context, _SettingsItem item) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: context.panelColor,
    builder: (sheetContext) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: sheetContext.panelMutedColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child:
                      Icon(item.icon, color: sheetContext.secondaryTextColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.title ?? item.label,
                    style: TextStyle(
                      color: sheetContext.primaryTextColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              item.description ?? '',
              style: TextStyle(
                color: sheetContext.secondaryTextColor,
                fontSize: 15,
                height: 1.45,
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _SettingsSwitch extends StatelessWidget {
  final bool value;

  const _SettingsSwitch({required this.value});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: 48,
      height: 24,
      padding: EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: value ? const Color(0xFF2ECC71) : const Color(0xFFD1D5DB),
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: value ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: context.panelColor,
          borderRadius: BorderRadius.circular(999),
          boxShadow: const [
            BoxShadow(
              blurRadius: 4,
              offset: Offset(0, 2),
              color: Color(0x33000000),
            ),
          ],
        ),
      ),
    );
  }
}
