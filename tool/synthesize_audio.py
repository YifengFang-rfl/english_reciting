#!/usr/bin/env python3
"""批量合成词汇音频（macOS `say` + `afconvert`）。

用法:
    python3 tool/synthesize_audio.py

说明:
- 读取 assets/vocabulary_rj_s.json 中的英文单词，去重后逐个合成
- 输出到 assets/audio/<sanitized>.m4a（64kbps AAC）
- 已存在的文件自动跳过（可断点续跑/幂等）
- 结束时生成 assets/audio/index.txt（每行一个文件名），供 App 运行时查询
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
VOICE = "Samantha"
BITRATE = "64000"


def sanitize(word: str) -> str:
    """生成跨平台安全的文件名（保留字母/数字/撇号/连字符）。"""
    s = re.sub(r"[^A-Za-z0-9'\-]+", "_", word)
    s = s.strip("_")
    return s or "word"


def normalize_text(word: str) -> str:
    """把弯引号/弯撇号归一化为 ASCII，压缩空白，便于 TTS 朗读。"""
    for a, b in [("\u2019", "'"), ("\u2018", "'"), ("\u201c", '"'), ("\u201d", '"')]:
        word = word.replace(a, b)
    word = re.sub(r"\s+", " ", word).strip()
    return word


def is_meaningful(word: str) -> bool:
    return bool(re.search(r"[A-Za-z]", word))


def main() -> int:
    os.makedirs(OUT_DIR, exist_ok=True)
    with open(JSON_PATH, encoding="utf-8") as f:
        data = json.load(f)

    words = [entry["english"] for entry in data]
    unique = sorted(set(words))
    todo = [w for w in unique if is_meaningful(w)]

    print(f"总条目={len(words)} 去重后={len(unique)} 待合成={len(todo)}")

    done = 0
    skipped = 0
    failed = []

    for i, word in enumerate(todo, 1):
        fname = sanitize(word) + ".m4a"
        path = os.path.join(OUT_DIR, fname)
        if os.path.exists(path):
            skipped += 1
            continue

        text = normalize_text(word)
        aiff = path + ".aiff"
        try:
            r1 = subprocess.run(
                ["say", "-v", VOICE, "-o", aiff, text],
                capture_output=True,
                text=True,
            )
            if r1.returncode != 0 or not os.path.exists(aiff):
                failed.append(word)
                continue
            r2 = subprocess.run(
                [
                    "afconvert",
                    "-f", "m4af",
                    "-d", "aac",
                    "-b", BITRATE,
                    aiff,
                    path,
                ],
                capture_output=True,
                text=True,
            )
            if r2.returncode != 0 or not os.path.exists(path):
                failed.append(word)
                continue
            os.remove(aiff)
            done += 1
        except Exception as e:  # noqa: BLE001
            failed.append(word)
            print("ERROR:", word, e)

        if i % 50 == 0:
            print(f"进度 {i}/{len(todo)} 完成={done} 跳过={skipped} 失败={len(failed)}", flush=True)

    # 生成索引文件
    if os.path.isdir(OUT_DIR):
        files = sorted(f for f in os.listdir(OUT_DIR) if f.endswith(".m4a"))
        with open(INDEX_PATH, "w", encoding="utf-8") as f:
            f.write("\n".join(files) + ("\n" if files else ""))
        print(f"索引: {len(files)} 个音频已登记到 {INDEX_PATH}")

    print(f"全部完成 完成={done} 跳过={skipped} 失败={len(failed)}")
    if failed:
        print("失败单词:", failed)
    return 0


if __name__ == "__main__":
    sys.exit(main())
