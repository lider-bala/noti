import 'package:flutter/widgets.dart';

class ResponsiveBreakpoints {
  static const compact = 375.0;
  static const tablet = 768.0;
  static const desktop = 1024.0;

  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width <= compact;

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tablet;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktop;
}

class ResponsiveWrapRow extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final double minChildWidth;

  const ResponsiveWrapRow({
    super.key,
    required this.children,
    this.spacing = 12,
    this.runSpacing = 12,
    this.minChildWidth = 220,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final canFitRow =
            constraints.maxWidth >= children.length * minChildWidth;
        if (canFitRow) {
          return Row(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                Expanded(child: children[i]),
                if (i != children.length - 1) SizedBox(width: spacing),
              ],
            ],
          );
        }

        return Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              children[i],
              if (i != children.length - 1) SizedBox(height: runSpacing),
            ],
          ],
        );
      },
    );
  }
}
