import 'package:flutter/material.dart';

import '../core/constants.dart';

class GradientCard extends StatelessWidget {
  const GradientCard({
    super.key,
    required this.child,
    this.colors = const [AppColors.primary, AppColors.secondary],
    this.padding = const EdgeInsets.all(AppPadding.lg),
    this.borderRadius,
  });

  final Widget child;
  final List<Color> colors;
  final EdgeInsets padding;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: borderRadius ?? BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: colors.first.withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: Colors.white),
        child: IconTheme.merge(
          data: const IconThemeData(color: Colors.white),
          child: child,
        ),
      ),
    );
  }
}
