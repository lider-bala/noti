import 'package:flutter/material.dart';

class AnimatedSectionSwitcher extends StatelessWidget {
  final Widget child;
  final Object switchKey;

  const AnimatedSectionSwitcher({
    super.key,
    required this.child,
    required this.switchKey,
  });

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: ValueKey<Object>(switchKey),
      child: child,
    );
  }
}
