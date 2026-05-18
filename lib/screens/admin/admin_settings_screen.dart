import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/language_menu_button.dart';
import '../../widgets/theme_mode_selector.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  bool _securityAlerts = true;
  bool _regionalDefaults = true;
  bool _manualApproval = true;

  @override
  Widget build(BuildContext context) {
    final appState = context.appState;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(
          title: context.tr('admin.settings.title'),
          subtitle: context.tr(
            'Язык, регион и правила доступа отделены от списков пользователей и уроков.',
          ),
        ),
        SizedBox(height: 16),
        _SettingTile(
          icon: Icons.cloud_done_outlined,
          title: context.tr('admin.database.title'),
          subtitle: appState.databaseStatusLabel,
          trailing: appState.isDatabaseSyncing
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : IconButton(
                  tooltip: context.tr('admin.database.action'),
                  onPressed: appState.synchronizeDatabase,
                  icon: Icon(Icons.sync_rounded),
                ),
        ),
        SizedBox(height: 12),
        _SettingTile(
          icon: Icons.translate_rounded,
          title: context.tr('settings.language'),
          subtitle: context.strings.languageLabel(appState.language),
          trailing: const LanguageMenuButton(),
        ),
        SizedBox(height: 12),
        const ThemeModeSelector(),
        SizedBox(height: 12),
        _SettingTile(
          icon: Icons.public_rounded,
          title: context.tr('admin.settings.kgRegion'),
          subtitle: 'Bishkek, Kyrgyzstan • +996',
          trailing: Switch(
            value: _regionalDefaults,
            activeColor: const Color(0xFF10B981),
            onChanged: (value) {
              setState(() => _regionalDefaults = value);
            },
          ),
        ),
        SizedBox(height: 12),
        _SettingTile(
          icon: Icons.verified_user_rounded,
          title: context.tr('Ручное подтверждение регистраций'),
          subtitle: context.tr('Новые заявки проверяет администратор.'),
          trailing: Switch(
            value: _manualApproval,
            activeColor: const Color(0xFF10B981),
            onChanged: (value) {
              setState(() => _manualApproval = value);
            },
          ),
        ),
        SizedBox(height: 12),
        _SettingTile(
          icon: Icons.lock_outline_rounded,
          title: context.tr('settings.security'),
          subtitle: context.tr('Вход по email, паролю и выбранной роли.'),
          trailing: Switch(
            value: _securityAlerts,
            activeColor: const Color(0xFF10B981),
            onChanged: (value) {
              setState(() => _securityAlerts = value);
            },
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
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF111827), Color(0xFF374151)],
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
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.panelColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appBorderColor),
        boxShadow: const [
          BoxShadow(
            blurRadius: 18,
            offset: Offset(0, 10),
            color: Color(0x10000000),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: context.panelMutedColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: context.secondaryTextColor),
          ),
          const SizedBox(width: 14),
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
                SizedBox(height: 4),
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
          const SizedBox(width: 12),
          trailing,
        ],
      ),
    );
  }
}
