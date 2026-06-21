#!/usr/bin/env python3
"""
Phase 2: Extract text from all approved PDFs.
- Text-based PDFs → extract full text → .txt
- Image-based PDFs → log for OCR queue
- Mixed → extract what's available + flag image pages
Pure local, zero LLM token.
"""
import json, os, sys, re
from pathlib import Path
from datetime import datetime
from collections import defaultdict

CLIPPINGS = r"G:\quark\Obsidian笔记\Clippings"
INDEX = r"G:\Claude\wiki\考编\_索引\index.json"
OUTDIR = r"G:\Claude\wiki\考编\_extracted"

os.makedirs(OUTDIR, exist_ok=True)

with open(INDEX, "r", encoding="utf-8") as f:
    data = json.load(f)

passed = [f for f in data["files"] if f["verdict"] == "✅ 通过"]
pdfs = [f for f in passed if f["path"].endswith(".pdf")]
non_pdfs = [f for f in passed if not f["path"].endswith(".pdf")]

print(f"Phase 2: {len(pdfs)} PDFs to extract, {len(non_pdfs)} non-PDFs to note")

# ============================================================
def sanitize_filename(name):
    """Remove chars that break filenames."""
    return re.sub(r'[\\/*?:"<>|]', '_', name)

def extract_pdf(file_info):
    """Extract text page by page. Returns (full_text, image_pages, stats)."""
    from PyPDF2 import PdfReader
    path = file_info["path"]
    try:
        reader = PdfReader(path)
    except Exception as e:
        return None, [], {"error": str(e)}

    pages_text = []
    image_pages = []
    total_chars = 0

    for i, page in enumerate(reader.pages):
        try:
            t = page.extract_text() or ""
        except:
            t = ""
        chars = len(t)
        total_chars += chars
        pages_text.append((i + 1, chars, t))
        if chars < 100:
            image_pages.append(i + 1)

    return pages_text, image_pages, {
        "total_pages": len(reader.pages),
        "total_chars": total_chars,
        "image_page_pct": len(image_pages) / max(1, len(reader.pages)) * 100,
    }

# ============================================================
def get_module_dir(file_info):
    """Get top-level module name for output grouping."""
    dir_path = file_info.get("dir", "")
    if not dir_path:
        return "_root"
    return dir_path.split("\\")[0]

def get_subdir(file_info):
    """Get subdirectory path within module."""
    dir_path = file_info.get("dir", "")
    parts = dir_path.split("\\")
    if len(parts) <= 1:
        return ""
    return "\\".join(parts[1:])

# ============================================================
# Process
img_heavy_pdfs = []  # > 80% image pages → OCR queue
mixed_pdfs = []      # 20-80% image pages
text_pdfs = []       # < 20% image pages
extracted = []
errors = []

for i, finfo in enumerate(pdfs):
    if (i + 1) % 20 == 0:
        print(f"  Extracting: {i+1}/{len(pdfs)}")

    pages_text, image_pages, stats = extract_pdf(finfo)

    if pages_text is None:
        errors.append((finfo["name"], stats.get("error", "unknown")))
        continue

    img_pct = stats["image_page_pct"]
    if img_pct > 80:
        img_heavy_pdfs.append((finfo, image_pages, stats))
    elif img_pct > 20:
        mixed_pdfs.append((finfo, image_pages, stats))
    else:
        text_pdfs.append((finfo, image_pages, stats))

    # Build output
    module = sanitize_filename(get_module_dir(finfo))
    subdir = sanitize_filename(get_subdir(finfo))
    out_name = sanitize_filename(finfo["name"]).replace(".pdf", ".txt")
    out_subdir = os.path.join(OUTDIR, module, subdir) if subdir else os.path.join(OUTDIR, module)
    os.makedirs(out_subdir, exist_ok=True)
    out_path = os.path.join(out_subdir, out_name)

    # Write extracted text
    lines = []
    lines.append(f"# {finfo['name']}")
    lines.append(f"# Source: {finfo['path']}")
    lines.append(f"# Pages: {stats['total_pages']} | Chars: {stats['total_chars']} | Image pages: {len(image_pages)}")
    lines.append("")

    for page_num, chars, text in pages_text:
        lines.append(f"## Page {page_num}")
        lines.append("")
        if chars < 100:
            lines.append(f"[IMAGE PAGE — {chars} chars extracted, needs OCR]")
        else:
            lines.append(text.strip())
        lines.append("")

    with open(out_path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))

    extracted.append({
        "name": finfo["name"],
        "output": out_path,
        "pages": stats["total_pages"],
        "chars": stats["total_chars"],
        "image_pages": len(image_pages),
        "img_pct": img_pct,
    })

# ============================================================
# Generate Phase 2 Report
report_lines = []
report_lines.append("# Phase 2 — 文本提取报告")
report_lines.append(f"> 完成时间: {datetime.now().strftime('%Y-%m-%d %H:%M')}")
report_lines.append(f"> 处理 PDF: {len(extracted)} | 错误: {len(errors)}")
report_lines.append("")

# Summary
total_pages = sum(e["pages"] for e in extracted)
total_chars = sum(e["chars"] for e in extracted)
total_img = sum(e["image_pages"] for e in extracted)
report_lines.append("## 概览")
report_lines.append("")
report_lines.append(f"| 指标 | 数值 |")
report_lines.append(f"|------|------|")
report_lines.append(f"| PDF 总数 | {len(extracted)} |")
report_lines.append(f"| 总页数 | {total_pages} |")
report_lines.append(f"| 总提取字符 | {total_chars:,} |")
report_lines.append(f"| 需要 OCR 的页面 | {total_img} ({total_img/max(1,total_pages)*100:.1f}%) |")
report_lines.append(f"| 纯文本 PDF (<20%图片) | {len(text_pdfs)} |")
report_lines.append(f"| 混合 PDF (20-80%图片) | {len(mixed_pdfs)} |")
report_lines.append(f"| 扫描件 PDF (>80%图片) | {len(img_heavy_pdfs)} |")
report_lines.append("")

# OCR Queue
report_lines.append("## 🔴 OCR 队列（>80% 图片页，必须 OCR）")
report_lines.append("")
report_lines.append("| 文件 | 模块 | 页数 | 图片页 |")
report_lines.append("|------|------|------|--------|")
for finfo, img_pages, stats in sorted(img_heavy_pdfs, key=lambda x: -x[2]["total_pages"]):
    module = get_module_dir(finfo)
    report_lines.append(f"| {finfo['name']} | {module} | {stats['total_pages']}p | {len(img_pages)} |")
report_lines.append("")

# Mixed
report_lines.append("## 🟡 混合 PDF（20-80% 图片页，部分需要 OCR）")
report_lines.append("")
report_lines.append("| 文件 | 模块 | 页数 | 图片页 | 图片% |")
report_lines.append("|------|------|------|--------|-------|")
for finfo, img_pages, stats in sorted(mixed_pdfs, key=lambda x: -x[2]["total_pages"]):
    module = get_module_dir(finfo)
    report_lines.append(f"| {finfo['name']} | {module} | {stats['total_pages']}p | {len(img_pages)} | {stats['image_page_pct']:.0f}% |")
report_lines.append("")

# Text-based
report_lines.append("## 🟢 纯文本 PDF（可直接使用）")
report_lines.append("")
by_module = defaultdict(list)
for finfo, img_pages, stats in text_pdfs:
    module = get_module_dir(finfo)
    by_module[module].append((finfo, img_pages, stats))
for mod in sorted(by_module.keys()):
    items = by_module[mod]
    mod_pages = sum(s["total_pages"] for _, _, s in items)
    mod_chars = sum(s["total_chars"] for _, _, s in items)
    report_lines.append(f"### {mod} — {len(items)} 文件, {mod_pages}p, {mod_chars:,} chars")
    report_lines.append("")
    for finfo, img_pages, stats in sorted(items, key=lambda x: -x[2]["total_chars"]):
        report_lines.append(f"- {finfo['name']} ({stats['total_pages']}p, {stats['total_chars']:,} chars)")
    report_lines.append("")

# Non-PDF files
if non_pdfs:
    report_lines.append("## 📎 非 PDF 文件")
    report_lines.append("")
    for f in non_pdfs:
        report_lines.append(f"- {f['name']} ({f['ext']}, {f['size']//1024}KB) → {f['dir']}")
    report_lines.append("")

# Errors
if errors:
    report_lines.append("## ❌ 提取失败")
    report_lines.append("")
    for name, err in errors:
        report_lines.append(f"- {name}: {err}")
    report_lines.append("")

# Next steps
report_lines.append("## ⏭ 下一步")
report_lines.append("")
report_lines.append(f"1. **OCR 处理**：{len(img_heavy_pdfs)} 个扫描件需要 OCR（约 {sum(s['total_pages'] for _,_,s in img_heavy_pdfs)} 页）")
report_lines.append(f"2. **阶段三准备**：{len(text_pdfs)} 个纯文本 PDF 已可直接进入智能提炼")
report_lines.append(f"3. **输出目录**：`{OUTDIR}`")
report_lines.append("")

# Write report
report_path = os.path.join(OUTDIR, "_phase2-report.md")
with open(report_path, "w", encoding="utf-8") as f:
    f.write("\n".join(report_lines))

# Write OCR queue JSON
ocr_queue = []
for finfo, img_pages, stats in img_heavy_pdfs:
    ocr_queue.append({
        "name": finfo["name"],
        "path": finfo["path"],
        "pages": stats["total_pages"],
        "image_pages": len(img_pages),
        "module": get_module_dir(finfo),
    })
for finfo, img_pages, stats in mixed_pdfs:
    if stats["image_page_pct"] > 50:
        ocr_queue.append({
            "name": finfo["name"],
            "path": finfo["path"],
            "pages": stats["total_pages"],
            "image_pages": len(img_pages),
            "module": get_module_dir(finfo),
        })

ocr_queue_path = os.path.join(OUTDIR, "_ocr-queue.json")
with open(ocr_queue_path, "w", encoding="utf-8") as f:
    json.dump(ocr_queue, f, ensure_ascii=False, indent=2)

print(f"\n{'='*50}")
print(f"Extracted: {len(extracted)} PDFs → {OUTDIR}")
print(f"Text PDFs: {len(text_pdfs)} | Mixed: {len(mixed_pdfs)} | OCR needed: {len(img_heavy_pdfs)}")
print(f"Total chars extracted: {total_chars:,}")
print(f"OCR queue: {len(ocr_queue)} files, ~{sum(q['image_pages'] for q in ocr_queue)} pages")
print(f"Report: {report_path}")
