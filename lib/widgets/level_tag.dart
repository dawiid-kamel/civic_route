/// Small non-interactive label for a level of government (Federal / State /
/// County). A colored dot plus bold text, with no fill or border, so it reads
/// as a label and not as something you can tap.
library;

import 'package:flutter/material.dart';

class LevelTag extends StatelessWidget {
  final String label;
  final Color color;

  const LevelTag({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}
