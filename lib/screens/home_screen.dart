import 'package:flutter/cupertino.dart';

/// 首页 —— 选择内置教材或自定义词典
class HomeScreen extends StatelessWidget {
  final VoidCallback onBuiltIn;
  final VoidCallback onCustom;
  final VoidCallback onWrongWords;
  final VoidCallback onOpenGithub;
  final int wrongWordCount;

  const HomeScreen({
    super.key,
    required this.onBuiltIn,
    required this.onCustom,
    required this.onWrongWords,
    required this.onOpenGithub,
    this.wrongWordCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          const Icon(
            CupertinoIcons.book_fill,
            size: 48,
            color: CupertinoColors.activeBlue,
          ),
          const SizedBox(height: 12),
          const Text(
            '英语默写助手',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text(
            '人教版高中英语 · 课堂听写工具',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: CupertinoColors.secondaryLabel,
            ),
          ),
          const SizedBox(height: 40),

          _OptionCard(
            icon: CupertinoIcons.book,
            title: '人教版教材',
            subtitle: '必修 + 选必修 · 2569 词',
            onTap: onBuiltIn,
          ),
          const SizedBox(height: 16),

          _OptionCard(
            icon: CupertinoIcons.square_stack_3d_up_fill,
            title: '错词本',
            subtitle: wrongWordCount > 0 ? '已收集 $wrongWordCount 个错词' : '暂无错词',
            onTap: onWrongWords,
          ),
          const SizedBox(height: 16),

          _OptionCard(
            icon: CupertinoIcons.doc_text,
            title: '自定义词典',
            subtitle: '手动编入或导入英语单词表',
            onTap: onCustom,
          ),
          const SizedBox(height: 28),
          _GithubFooter(onTap: onOpenGithub),
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: CupertinoColors.secondarySystemBackground.resolveFrom(context),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, size: 36, color: CupertinoColors.activeBlue),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: CupertinoColors.secondaryLabel,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_right,
              color: CupertinoColors.systemGrey3,
            ),
          ],
        ),
      ),
    );
  }
}

class _GithubFooter extends StatelessWidget {
  final VoidCallback onTap;

  const _GithubFooter({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  CupertinoIcons.star_fill,
                  size: 15,
                  color: CupertinoColors.systemOrange,
                ),
                SizedBox(width: 6),
                Text(
                  '如果对您有帮助，希望给我一个 Star',
                  style: TextStyle(
                    fontSize: 13,
                    color: CupertinoColors.secondaryLabel,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  CupertinoIcons.link,
                  size: 13,
                  color: CupertinoColors.activeBlue,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'github.com/YifengFang-rfl/english_reciting',
                    style: const TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.activeBlue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
