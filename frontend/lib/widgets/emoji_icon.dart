import 'package:flutter/widgets.dart';

/// Shows an emoji from a PNG in assets/emoji/, named by its code points
class EmojiIcon extends StatelessWidget {
  final String emoji;
  final double size;
  const EmojiIcon({super.key, required this.emoji, this.size = 16});

  static String assetPathFor(String emoji) {
    final codes = emoji.runes
        .where(
          (r) => r != 0xFE0F,
        ) // emoji presentation selector is not in the file name
        .map((r) => r.toRadixString(16))
        .join('-');
    return 'assets/emoji/$codes.png';
  }

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPathFor(emoji),
      width: size,
      height: size,
      errorBuilder: (_, __, ___) =>
          Text(emoji, style: TextStyle(fontSize: size - 2)),
    );
  }
}
