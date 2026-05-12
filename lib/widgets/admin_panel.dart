import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Основная панель для админ-интерфейса
class AdminPanel extends StatelessWidget {
  final String title;
  final IconData? icon;
  final List<Widget> children;
  final EdgeInsets padding;
  final Color? backgroundColor;
  final bool showDivider;

  const AdminPanel({
    super.key,
    required this.title,
    this.icon,
    required this.children,
    this.padding = const EdgeInsets.all(20),
    this.backgroundColor,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? context.panelColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            blurRadius: 8,
            offset: Offset(0, 2),
            color: Color(0x0A000000),
          ),
        ],
        border: Border.all(
          color: context.appBorderColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(
              padding.left,
              padding.top,
              padding.right,
              showDivider ? 16 : padding.bottom,
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    color: const Color(0xFF6366F1),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: context.primaryTextColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (showDivider)
            Container(
              height: 1,
              color: context.appBorderColor,
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              padding.left,
              showDivider ? 16 : 0,
              padding.right,
              padding.bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

/// Панель с сеткой элементов
class AdminGridPanel extends StatelessWidget {
  final String title;
  final IconData? icon;
  final List<Widget> items;
  final int columnCount;
  final double spacing;
  final EdgeInsets padding;

  const AdminGridPanel({
    super.key,
    required this.title,
    this.icon,
    required this.items,
    this.columnCount = 2,
    this.spacing = 16,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    return AdminPanel(
      title: title,
      icon: icon,
      padding: padding,
      children: [
        GridView.count(
          crossAxisCount: columnCount,
          mainAxisSpacing: spacing,
          crossAxisSpacing: spacing,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: items,
        ),
      ],
    );
  }
}

/// Панель со списком элементов
class AdminListPanel extends StatelessWidget {
  final String title;
  final IconData? icon;
  final List<AdminListItem> items;
  final VoidCallback? onViewAll;
  final EdgeInsets padding;

  const AdminListPanel({
    super.key,
    required this.title,
    this.icon,
    required this.items,
    this.onViewAll,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    return AdminPanel(
      title: title,
      icon: icon,
      padding: padding,
      children: [
        Column(
          children: [
            ...items.map((item) => _buildListItem(context, item)),
            if (onViewAll != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: onViewAll,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Посмотреть всё'),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildListItem(BuildContext context, AdminListItem item) {
    return Column(
      children: [
        Row(
          children: [
            if (item.leading != null) ...[
              item.leading!,
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.primaryTextColor,
                    ),
                  ),
                  if (item.subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        item.subtitle!,
                        style: TextStyle(
                          fontSize: 13,
                          color: context.secondaryTextColor,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (item.trailing != null) item.trailing!,
          ],
        ),
        if (item != items.last) ...[
          const SizedBox(height: 12),
          Container(
            height: 1,
            color: context.appBorderColor,
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class AdminListItem {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;

  AdminListItem({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
  });
}

/// Карточка с метрикой
class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback? onTap;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.gradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: 16,
              offset: const Offset(0, 4),
              color: gradient.first.withOpacity(0.3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Кнопка действия для админ-панели
class AdminActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isPrimary;
  final bool isDangerous;

  const AdminActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isPrimary = false,
    this.isDangerous = false,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;

    if (isDangerous) {
      backgroundColor = const Color(0xFFEF4444);
      textColor = Colors.white;
    } else if (isPrimary) {
      backgroundColor = const Color(0xFF6366F1);
      textColor = Colors.white;
    } else {
      backgroundColor = context.panelMutedColor;
      textColor = context.primaryTextColor;
    }

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: textColor, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
