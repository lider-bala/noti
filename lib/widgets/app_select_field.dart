import 'package:flutter/material.dart';

import 'app_theme.dart';

class AppSelectOption<T> {
  final T value;
  final String label;
  final String? subtitle;

  const AppSelectOption({
    required this.value,
    required this.label,
    this.subtitle,
  });
}

class AppSelectField<T> extends StatelessWidget {
  final T? value;
  final String label;
  final IconData? icon;
  final List<AppSelectOption<T>> options;
  final ValueChanged<T?> onChanged;
  final bool enabled;

  const AppSelectField({
    super.key,
    required this.value,
    required this.label,
    required this.options,
    required this.onChanged,
    this.icon,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final selected = _selectedOption;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: enabled ? () => _openPicker(context) : null,
      child: InputDecorator(
        isEmpty: selected == null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: context.secondaryTextColor),
          prefixIcon: icon == null
              ? null
              : Icon(icon, color: context.secondaryTextColor, size: 20),
          suffixIcon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: context.secondaryTextColor,
          ),
          filled: true,
          fillColor: context.panelMutedColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: context.appBorderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: context.appBorderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFF0F766E),
              width: 1.4,
            ),
          ),
        ),
        child: Text(
          selected?.label ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color:
                enabled ? context.primaryTextColor : context.secondaryTextColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  AppSelectOption<T>? get _selectedOption {
    for (final option in options) {
      if (option.value == value) {
        return option;
      }
    }
    return null;
  }

  Future<void> _openPicker(BuildContext context) async {
    if (options.isEmpty) {
      return;
    }

    final picked = await showModalBottomSheet<_PickedSelectValue<T>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(context.isDarkTheme ? 0.45 : 0.22),
      builder: (sheetContext) {
        return _SelectSheet<T>(
          title: label,
          value: value,
          options: options,
        );
      },
    );

    if (picked != null) {
      onChanged(picked.value);
    }
  }
}

class _SelectSheet<T> extends StatelessWidget {
  final String title;
  final T? value;
  final List<AppSelectOption<T>> options;

  const _SelectSheet({
    required this.title,
    required this.value,
    required this.options,
  });

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.68;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: BoxDecoration(
          color: context.panelColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: context.appBorderColor),
          boxShadow: const [
            BoxShadow(
              blurRadius: 28,
              offset: Offset(0, -8),
              color: Color(0x33000000),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 10, 8),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.appBorderColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close_rounded,
                      color: context.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  style: TextStyle(
                    color: context.primaryTextColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                itemCount: options.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final option = options[index];
                  final selected = option.value == value;

                  return Material(
                    color: selected
                        ? const Color(0xFF0F766E).withOpacity(0.16)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Navigator.of(context).pop(
                        _PickedSelectValue<T>(option.value),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 13,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    option.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: context.primaryTextColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (option.subtitle != null) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      option.subtitle!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: context.secondaryTextColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (selected)
                              const Icon(
                                Icons.check_circle_rounded,
                                color: Color(0xFF10B981),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickedSelectValue<T> {
  final T? value;

  const _PickedSelectValue(this.value);
}
