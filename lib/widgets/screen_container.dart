import 'package:flutter/material.dart';

/// A container for menu screen content with:
/// - 20px padding from top, right, left, and bottom
/// - surface color for the content area (inner pages)
/// - surfaceContainer for the outer area around the content
/// - Rounded corners applied to the content surface
class ScreenContainer extends StatelessWidget {
  const ScreenContainer({
    super.key,
    required this.child,
    this.cornerRadius = 24,
  });

  final Widget child;
  final double cornerRadius;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ColoredBox(
      color: colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.only(top: 12, right: 12, bottom: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(cornerRadius),
          child: ColoredBox(
            color: colorScheme.surface,
            child: child,
          ),
        ),
      ),
    );
  }
}
