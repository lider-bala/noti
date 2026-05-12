import 'package:flutter/material.dart';

import '../app/app_state.dart';
import 'app_theme.dart';

class ThemeModeSelector extends StatelessWidget {
  const ThemeModeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.appState;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.panelMutedColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.dark_mode_outlined,
                  color: context.secondaryTextColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('settings.theme'),
                      style: TextStyle(
                        color: context.primaryTextColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.tr('settings.themeSubtitle'),
                      style: TextStyle(
                        color: context.secondaryTextColor,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SegmentedButton<AppThemePreference>(
            segments: [
              ButtonSegment(
                value: AppThemePreference.system,
                icon: const Icon(Icons.devices_rounded),
                label: Text(context.tr('settings.themeSystem')),
              ),
              ButtonSegment(
                value: AppThemePreference.light,
                icon: const Icon(Icons.light_mode_outlined),
                label: Text(context.tr('settings.themeLight')),
              ),
              ButtonSegment(
                value: AppThemePreference.dark,
                icon: const Icon(Icons.dark_mode_outlined),
                label: Text(context.tr('settings.themeDark')),
              ),
            ],
            selected: {appState.themePreference},
            onSelectionChanged: (selection) {
              appState.setThemePreference(selection.first);
            },
            showSelectedIcon: false,
          ),
        ],
      ),
    );
  }
}
