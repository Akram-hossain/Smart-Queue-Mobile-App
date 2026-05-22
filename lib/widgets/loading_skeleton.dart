import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../core/constants.dart';

class LoadingSkeleton extends StatelessWidget {
  const LoadingSkeleton({super.key, this.height = 120, this.itemCount = 4});

  final double height;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? Colors.white12 : Colors.black12;
    final highlight = isDark ? Colors.white24 : Colors.black.withOpacity(0.04);
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Column(
        children: List.generate(
          itemCount,
          (_) => Container(
            margin: const EdgeInsets.only(bottom: AppPadding.md),
            height: height,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
          ),
        ),
      ),
    );
  }
}
