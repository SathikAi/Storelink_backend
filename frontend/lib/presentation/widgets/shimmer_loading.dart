import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerLoading extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const ShimmerLoading({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class ShimmerListTile extends StatelessWidget {
  const ShimmerListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerLoading(
            width: 60,
            height: 60,
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerLoading(width: double.infinity, height: 16),
                SizedBox(height: 8),
                ShimmerLoading(width: 150, height: 12),
                SizedBox(height: 8),
                Row(
                  children: [
                    ShimmerLoading(width: 60, height: 20),
                    SizedBox(width: 8),
                    ShimmerLoading(width: 60, height: 20),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
