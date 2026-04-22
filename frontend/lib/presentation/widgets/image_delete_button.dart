import 'package:flutter/material.dart';

class PositionImageDeleteButton extends StatelessWidget {
  final VoidCallback onDelete;
  const PositionImageDeleteButton({super.key, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 0,
      top: 0,
      child: GestureDetector(
        onTap: onDelete,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(4),
          child: const Icon(Icons.close, color: Colors.white, size: 16),
        ),
      ),
    );
  }
}
