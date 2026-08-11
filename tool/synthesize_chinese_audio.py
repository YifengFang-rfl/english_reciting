#!/usr/bin/env python3
"""批量合成中文释义音频（macOS `say` + `afconvert`）。

用法:
    python3 tool/synthesize_chinese_audio.py

说明:
- 读取 assets/vocabulary_rj_s.json，取每个英文单词第一条 chinese 释义
- 朗读时忽略括号（）() 及括号内容，去掉词性前缀（n./vt./adj.），| 转为空格
- 输出到 assets/audio/<英文文件名>_cn.m4a（64kbps AAC）
- 已存在的文件自动跳过；结束后重建 assets/audio/index.txt（含英文+中文全部音频）
"""

import json
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
JSON_PATH = os.path.join(ROOT, "assets", "vocabulary_rj_s.json")
OUT_DIR = os.path.join(ROOT, "assets", "audio")
INDEX_PATH = os.path.join(OUT_DIR, "index.txt")
VOICE = "Lili"  # 中文（普通话）Premium 女声
BITRATE = "64000"


def sanitize(word: str) -> str:
    """与 synthesize_audio.py 一致的文件名规则。"""
    s = re.sub(r"[^A-Za-z0-9'\-]+", "_", word)
    s = s.strip("_")
    return s or "word"


def normalize_chinese(text: str) -> str:
    """朗读归一化：忽略括号及其内容、去掉词性前缀、| 转空格。"""
    text = re.sub(r"[（(][^（）()]*[）)]", "", text)
    text = re.sub(r"[a-zA-Z]+\.\s*", "", text)
    text = text.replace("|", " ")
    text = re.sub(r"\s+", " ", text).strip(" ；;| ")
    return text


def synthesize_one(path: str, text: str) -> bool:
    aiff = path + ".aiff"
    try:
        # 文本经 stdin 传入，避免以 '-' 开头的文本被 say 当作命令行选项
        r1 = subprocess.run(
            ["say", "-v", VOICE, "-o", aiff],
            input=text + "\n",
            capture_output=True,
            text=True,
            errors="replace",
        )
        if r1.returncode != 0 or not os.path.exists(aiff):
            return False
        r2 = subprocess.run(
            ["afconvert", "-f", "m4af", "-d", "aac", "-b", BITRATE, aiff, path],
            capture_output=True,
            text=True,
            errors="replace",
        )
    except Exception:  # noqa: BLE001 - 单个单词失败不应中断整个批次
        if os.path.exists(aiff):
            os.remove(aiff)
        return False
    if r2.returncode != 0 or not os.path.exists(path):
        if os.path.exists(aiff):
            os.remove(aiff)
        return False
    os.remove(aiff)
    return True


def main() -> int:
    os.makedirs(OUT_DIR, exist_ok=True)
    with open(JSON_PATH, encoding="utf-8") as f:
        data = json.load(f)

    # 每个英文单词取第一条释义（英文名唯一，保证文件名唯一）
    first: dict[str, dict] = {}
    for entry in data:
        if entry["english"] not in first:
            first[entry["english"]] = entry

    def build_chinese(entry: dict) -> str:
        """与 App 内 WordEntry.chinese 拼接规则一致：'n. 交换；交流  |  vt. ...'。"""
        parts = []
        for m in entry.get("meanings") or []:
            pos = (m.get("pos") or "").strip()
            cn = (m.get("chinese") or "").strip()
            parts.append(f"{pos} {cn}".strip())
        return "  |  ".join(parts)

    todo: list[tuple[str, str]] = []
    for word, entry in first.items():
        cn = normalize_chinese(build_chinese(entry))
        if cn:
            todo.append((word, cn))

    print(f"中文待合成={len(todo)}", flush=True)
    done = skipped = 0
    failed: list[str] = []

    for i, (word, cn) in enumerate(todo, 1):
        fname = sanitize(word) + "_cn.m4a"
        path = os.path.join(OUT_DIR, fname)
        if os.path.exists(path):
            skipped += 1
            continue
        if synthesize_one(path, cn):
            done += 1
        else:
            failed.append(word)
        if i % 100 == 0:
            print(
                f"中文进度 {i}/{len(todo)} 完成={done} 跳过={skipped} 失败={len(failed)}",
                flush=True,
            )

    files = sorted(f for f in os.listdir(OUT_DIR) if f.endswith(".m4a"))
    with open(INDEX_PATH, "w", encoding="utf-8") as f:
        f.write("\n".join(files) + ("\n" if files else ""))
    print(f"中文完成 完成={done} 跳过={skipped} 失败={len(failed)} 索引共 {len(files)} 个")
    if failed:
        print("失败单词:", failed)
    return 0


if __name__ == "__main__":
    sys.exit(main())
