# 英语默写助手

> 人教版高中英语 · 课堂听写工具

基于 Flutter 的跨平台课堂听写工具，支持 **中英双语朗读**，帮助老师快速进行英语课词汇听写。

---

## 功能特色

-   📚 **按课本/单元选词** — 内置人教版高中英语必修 + 选必修共 2569 词
-   🔀 **双方向默写** — 每词可设置「默英文」（听中文→写英文）或「默中文」（听英文→写中文）
-   🎯 **随机抽取** — 从已选单词中随机抽取指定数量进行听写
-   📖 **逐词调整** — 点击单元可进入详情页，逐词开关、切换方向
-   🔊 **原生语音合成** — macOS/iOS 用系统自带语音，Android/Windows 自动切换中英文
-   ⏱ **停顿可调** — 每词读两遍，停顿时间 3/5/8/10 秒可选
-   ❌ **错词本** — 默写完成后可标记错误单词收集到错词本，集中复习
-   🔍 **单词亮出** — 默写时单词默认隐藏，可随时亮出查看
-   📄 **导出默写表 PDF** — 选好的单词一键生成带横线的默写纸（含班级/姓名/日期栏），可直接分享或打印

## 快速开始

```bash
# 克隆仓库
git clone https://github.com/protonode-ai/english_reciting.git

# 进入目录
cd english_reciting

# 安装依赖
flutter pub get

# 运行（macOS）
flutter run -d macos
```

## 环境要求

| 平台 | 要求 |
|------|------|
| Flutter | ^3.12.2 |
| Dart | ^3.12.2 |
| macOS | 12+（运行需关闭 App Sandbox） |
| Android | minSdk 21+ |
| iOS | 15+ |
| Windows | 10+ (build 17763+)，CMake 3.20+，VS 2022 |

## 项目结构

```
lib/
├── main.dart                        # 入口 + 页面协调器
├── models/
│   └── word_pair.dart               # WordPair / WordEntry / DictateDirection
├── services/
│   ├── tts_service.dart             # 跨平台 TTS 封装
│   ├── vocabulary_service.dart      # 词汇表加载与选择管理
│   └── wrong_word_service.dart      # 错词本服务
└── screens/
    ├── home_screen.dart             # 首页
    ├── book_selection_screen.dart   # 课本/单元选择
    ├── unit_detail_screen.dart      # 单元内逐词调整
    ├── player_screen.dart           # 默写播放器
    ├── dictation_result_screen.dart # 默写结果 + 错词勾选
    └── wrong_word_screen.dart       # 错词本查看/管理
```

## 技术栈

-   **框架**: Flutter (Cupertino)
-   **TTS**: `flutter_tts`（macOS/iOS: AVSpeechSynthesizer, Android: TextToSpeech, Windows: SAPI）
-   **词典**: 人教版高中英语词汇表（JSON, 2569 词条）

## 许可

MIT

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
