#!/usr/bin/env python3
"""
Phase 2b: Render high-value image-heavy PDFs to PNG pages.
Output: _extracted/_ocr_pages/{pdf_name}/page_001.png ...
"""
import fitz  # PyMuPDF
import json
import os
import re
from pathlib import Path

INDEX = r"G:\Claude\wiki\考编\_索引\index.json"
OUTDIR = r"G:\Claude\wiki\考编\_extracted\_ocr_pages"

os.makedirs(OUTDIR, exist_ok=True)

# --- Target: high-value OCR files ---
TARGET_PATTERNS = [
    # 大懒猫 言语笔记 (all 10 files)
    "大懒猫丨26言语理论笔记",
    # 忠政 申论基础
    "忠政·26申论基础理论",
    # 高照 数量关系个人笔记
    "16章完整版）26高照数量关系",
    # 小黑 政治理论笔记 (all)
    "小黑政治理论笔记",
    # 小黑 常识判断笔记 (all)
    "小黑常识判断笔记",
]

with open(INDEX, "r", encoding="utf-8") as f:
    data = json.load(f)

passed = [f for f in data["files"] if f["verdict"] == "✅ 通过"]

# Find matching PDFs
targets = []
for finfo in passed:
    name = finfo["name"]
    if not name.endswith(".pdf"):
        continue
    for pat in TARGET_PATTERNS:
        if pat in name:
            targets.append(finfo)
            break

print(f"Target PDFs: {len(targets)}")
for t in targets:
    print(f"  {t['name']} ({t['pages']} pages)")

# Count existing rendered pages to skip completed PDFs
def count_rendered(pdf_name):
    safe = re.sub(r'[\\/*?:"<>|]', '_', pdf_name)
    d = os.path.join(OUTDIR, safe)
    if not os.path.exists(d):
        return 0
    return len([f for f in os.listdir(d) if f.endswith(".png")])

# Render each PDF
for i, finfo in enumerate(targets):
    safe_name = re.sub(r'[\\/*?:"<>|]', '_', finfo["name"])
    img_dir = os.path.join(OUTDIR, safe_name)

    existing = count_rendered(finfo["name"])
    if existing >= finfo["pages"]:
        print(f"[{i+1}/{len(targets)}] SKIP {finfo['name']} (already rendered {existing}/{finfo['pages']} pages)")
        continue

    os.makedirs(img_dir, exist_ok=True)
    print(f"[{i+1}/{len(targets)}] Rendering {finfo['name']} ({finfo['pages']} pages)...")

    try:
        doc = fitz.open(finfo["path"])
        total_pages = len(doc)
        rendered = 0
        for page_num in range(total_pages):
            out_file = os.path.join(img_dir, f"page_{page_num+1:03d}.png")
            if os.path.exists(out_file):
                continue
            page = doc[page_num]
            # Render at 200 DPI for good OCR quality
            pix = page.get_pixmap(dpi=200)
            pix.save(out_file)
            rendered += 1
        doc.close()
        print(f"  -> {rendered} new + {total_pages - rendered} existing = {total_pages} total pages")
    except Exception as e:
        print(f"  ERROR: {e}")

print(f"\nDone. Output: {OUTDIR}")
print(f"Next: node scripts/ocr-batch-v2.js")
