import 'package:flutter/material.dart';

import '../core/colors.dart';

/// One-line text with every match of [query] highlighted (case-insensitive).
class HighlightedText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle style;

  const HighlightedText({
    super.key,
    required this.text,
    required this.query,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      return Text(
        text,
        style: style,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    final lower = text.toLowerCase();
    final spans = <TextSpan>[];
    var start = 0;
    while (true) {
      final i = lower.indexOf(q, start);
      if (i < 0) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (i > start) spans.add(TextSpan(text: text.substring(start, i)));
      spans.add(
        TextSpan(
          text: text.substring(i, i + q.length),
          style: const TextStyle(backgroundColor: AppColors.highlight),
        ),
      );
      start = i + q.length;
    }

    return Text.rich(
      TextSpan(style: style, children: spans),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
