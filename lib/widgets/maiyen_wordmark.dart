import 'package:flutter/material.dart';

import '../maiyen_theme.dart';

class MaiYenWordmark extends StatelessWidget {
  const MaiYenWordmark({
    super.key,
    required this.suffix,
    required this.fontSize,
    this.fontWeight = FontWeight.w900,
    this.letterSpacing = 0,
    this.leafSize,
  });

  final String suffix;
  final double fontSize;
  final FontWeight fontWeight;
  final double letterSpacing;
  final double? leafSize;

  @override
  Widget build(BuildContext context) {
    final resolvedLeafSize = leafSize ?? fontSize * 0.94;
    final textStyle = TextStyle(
      fontSize: fontSize,
      height: 1,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
    );

    return Semantics(
      label: 'Mai$suffix',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) {
                return const LinearGradient(
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                  colors: [
                    Color(0xFF145B32), // phần gốc tối
                    Color(0xFF218742), // xanh chính
                    Color(0xFF67B943), // phần ngọn sáng
                  ],
                  stops: [0.0, 0.58, 1.0],
                ).createShader(bounds);
              },
              child: Text(
                'Mai',
                style: textStyle.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
            Transform.translate(
              offset: Offset(-fontSize * 0.015, fontSize * 0.015),
              child: SizedBox(
                width: resolvedLeafSize * 1.02,
                height: resolvedLeafSize,
                child: Image.asset(
                  'assets/maiyen_wordmark_leaf_exact.png',
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  isAntiAlias: true,
                ),
              ),
            ),
            Transform.translate(
              offset: Offset(-fontSize * 0.025, 0),
              child: Text(
                suffix,
                style: textStyle.copyWith(color: MaiYenColors.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
