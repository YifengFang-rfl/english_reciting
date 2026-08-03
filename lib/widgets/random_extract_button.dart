import 'package:flutter/cupertino.dart';

/// 「随机抽取」蓝色胶囊按钮 —— 三处入口（选书页/错词本/自定义词典）样式统一
class RandomExtractButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool compact; // 工具栏里用紧凑小号版

  const RandomExtractButton({
    super.key,
    required this.onPressed,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 14,
          vertical: compact ? 4 : 6,
        ),
        decoration: BoxDecoration(
          color: CupertinoColors.activeBlue,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.shuffle,
              size: compact ? 13 : 15,
              color: CupertinoColors.white,
            ),
            SizedBox(width: compact ? 4 : 5),
            Text(
              '随机抽取',
              style: TextStyle(
                fontSize: compact ? 12 : 14,
                color: CupertinoColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
