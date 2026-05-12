import 'package:flutter/material.dart';

import '../app/app_state.dart';
import 'app_theme.dart';

class LanguageMenuButton extends StatelessWidget {
  final bool light;

  const LanguageMenuButton({
    super.key,
    this.light = false,
  });

  @override
  Widget build(BuildContext context) {
    final appState = context.appState;
    final color = light ? Colors.white : context.primaryTextColor;
    final background =
        light ? Colors.white.withOpacity(0.18) : context.panelMutedColor;

    return Builder(
      builder: (_) {
        return InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => appState.setLanguage(appState.language),
          child: Container(
            constraints: const BoxConstraints(minHeight: 44, minWidth: 86),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: light
                    ? Colors.white.withOpacity(0.24)
                    : context.appBorderColor,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.language_rounded,
                  size: 18,
                  color: color,
                ),
                const SizedBox(width: 8),
                Text(
                  appState.language.shortLabel,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
