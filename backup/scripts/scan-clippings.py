#!/usr/bin/env python3
"""
阶段一：Clippings 资料扫描 + 脏数据过滤
产出：
  1. 完整文件索引 (index.json + index.md)
  2. 过滤建议 (_filter-report.md)
纯本地执行，零 token。
"""
import os, sys, json, hashlib, re
from pathlib import Path
from collections import defaultdict
from datetime import datetime

CLIPPINGS = r"G:\quark\Obsidian笔记\Clippings"
OUTPUT = r"G:\Claude\wiki\考编\_索引"

# --- 推广关键词（文件名匹配）---
AD_KEYWORDS_IN_FILENAME = [
    "公众号", "扫码", "加微信", "加微", "微信扫", "交流群",
    "免费反馈", "免费打印", "包邮", "首单免费", "打印讲义",
    "上岸总站", "上岸村", "客服", "咨询", "报名",
    "ch135s", "二维码", "关注", "扫一扫",
]

# --- 推广关键词（内容匹配，前 3 页）---
AD_KEYWORDS_IN_CONTENT = [
    "扫码关注", "微信公众号", "添加微信", "微信号：", "微信：",
    "客服微信", "咨询电话", "报名热线", "加微信", "交流群",
    "免费资料", "关注公众号", "回复", "领取",
]

# --- 正常内容关键词 ---
CONTENT_KEYWORDS = [
    "行测", "申论", "数量关系", "资料分析", "判断推理", "言语理解",
    "科学推理", "常识判断", "政治理论", "图形推理", "逻辑判断",
    "类比推理", "定义判断", "数学运算", "数字推理", "阅读理解",
    "选词填空", "语句表达", "归纳概括", "综合分析", "贯彻执行",
    "提出对策", "文章写作", "时政", "真题", "解析", "答案",
    "习题", "例题", "考点", "知识点", "公式", "方法", "技巧",
    "广东省考", "国考", "省考", "公务员",
]

os.makedirs(OUTPUT, exist_ok=True)

# ============================================================
def md5_head(path, bytes_to_hash=4096):
    """文件头 MD5，用于识别重复封面"""
    try:
        with open(path, "rb") as f:
            return hashlib.md5(f.read(bytes_to_hash)).hexdigest()
    except:
        return None

def pdf_meta(path):
    """提取 PDF 元数据：页数、前 3 页文本"""
    try:
        from PyPDF2 import PdfReader
        reader = PdfReader(path)
        pages = len(reader.pages)
        # 提取前 3 页文本
        text_parts = []
        for i in range(min(3, pages)):
            try:
                t = reader.pages[i].extract_text()
                if t:
                    text_parts.append(t[:2000])  # 每页最多 2000 字符
            except:
                pass
        preview = "\n".join(text_parts)
        return {"pages": pages, "preview": preview}
    except Exception as e:
        return {"pages": 0, "preview": "", "error": str(e)}

# ============================================================
def classify_file(fpath, meta):
    """给文件打分和分类"""
    fname = os.path.basename(fpath)
    fname_lower = fname.lower()
    ext = Path(fpath).suffix.lower()
    size = os.path.getsize(fpath)
    dir_path = os.path.dirname(fpath).replace(CLIPPINGS, "").strip("\\/")

    flags = []          # 风险标记
    score = 100         # 100 = 完全干净，0 = 确定垃圾

    # --- 规则 1：文件名推广特征 ---
    ad_hits = [kw for kw in AD_KEYWORDS_IN_FILENAME if kw in fname]
    if ad_hits:
        flags.append(f"文件名含推广词: {', '.join(ad_hits)}")
        score -= 25 * len(ad_hits)

    # --- 规则 2：纯图片文件 ---
    if ext in (".jpg", ".jpeg", ".png", ".gif", ".webp", ".bmp"):
        if size < 200 * 1024:  # < 200KB
            flags.append("小图片（疑似宣传海报/二维码）")
            score -= 40
        else:
            flags.append("图片文件（可能是扫描内容）")
            score -= 20

    # --- 规则 3：超短 PDF ---
    if ext == ".pdf" and meta.get("pages", 0):
        pages = meta["pages"]
        if pages <= 2:
            flags.append(f"超短 PDF（仅 {pages} 页）")
            score -= 35
        elif pages <= 5:
            flags.append(f"较短 PDF（{pages} 页）")
            score -= 10

    # --- 规则 4：超小文件 ---
    if size < 10240:  # < 10KB
        flags.append("文件极小 (<10KB)")
        score -= 50
    elif size < 50 * 1024:  # < 50KB
        flags.append("文件较小 (<50KB)")
        score -= 20

    # --- 规则 5：非标准格式 ---
    if ext == ".qkdownloading":
        flags.append("夸克下载碎片（未完成下载）")
        score -= 90
    if ext == ".txt":
        flags.append("文本文件（可能是说明/广告）")
        score -= 15

    # --- 规则 6：内容推广特征（仅 PDF）---
    preview = meta.get("preview", "")
    if preview:
        content_ad_hits = [kw for kw in AD_KEYWORDS_IN_CONTENT if kw in preview]
        if content_ad_hits:
            flags.append(f"内容含推广词: {', '.join(content_ad_hits[:3])}")
            score -= 15 * len(set(content_ad_hits))

        content_hits = [kw for kw in CONTENT_KEYWORDS if kw in preview]
        if content_hits:
            score += min(20, len(set(content_hits)) * 3)

    # --- 规则 7：文件名含正常关键词 ---
    good_hits = [kw for kw in CONTENT_KEYWORDS if kw in fname]
    if good_hits:
        score += min(15, len(set(good_hits)) * 2)

    # 分数钳制
    score = max(0, min(100, score))

    # 分类
    if score >= 80:
        verdict = "✅ 通过"
    elif score >= 50:
        verdict = "⚠️ 待确认"
    else:
        verdict = "❌ 建议跳过"

    return {
        "path": fpath,
        "name": fname,
        "dir": dir_path,
        "ext": ext,
        "size": size,
        "pages": meta.get("pages", 0),
        "preview_head": preview[:300] if preview else "",
        "flags": flags,
        "score": score,
        "verdict": verdict,
        "head_md5": md5_head(fpath),
    }

# ============================================================
def detect_duplicates(files):
    """检测重复封面（相同 head_md5 的文件）"""
    by_md5 = defaultdict(list)
    for f in files:
        if f["head_md5"]:
            by_md5[f["head_md5"]].append(f["name"])
    duplicates = {}
    for md5, names in by_md5.items():
        if len(names) > 1:
            duplicates[md5] = names
    return duplicates

def detect_pathological_patterns(files):
    """检测病态模式"""
    patterns = []

    # 同一目录下大量 ≤2 页 PDF
    dir_small_pdfs = defaultdict(list)
    for f in files:
        if f["ext"] == ".pdf" and f["pages"] <= 2:
            dir_small_pdfs[f["dir"]].append(f["name"])
    for d, names in dir_small_pdfs.items():
        if len(names) >= 3:
            patterns.append(f"目录 [{d}] 有 {len(names)} 个超短 PDF：{', '.join(names[:5])}")

    # 同一目录下大量 JPG
    dir_jpgs = defaultdict(list)
    for f in files:
        if f["ext"] in (".jpg", ".jpeg", ".png") and f["size"] < 500 * 1024:
            dir_jpgs[f["dir"]].append(f["name"])
    for d, names in dir_jpgs.items():
        if len(names) >= 5:
            patterns.append(f"目录 [{d}] 有 {len(names)} 个小图片：{', '.join(names[:5])}")

    return patterns

# ============================================================
def generate_markdown(files, duplicates, patterns):
    """生成过滤报告"""
    passed = [f for f in files if f["verdict"] == "✅ 通过"]
    maybe  = [f for f in files if f["verdict"] == "⚠️ 待确认"]
    skip   = [f for f in files if f["verdict"] == "❌ 建议跳过"]

    total_size = sum(f["size"] for f in files)
    passed_size = sum(f["size"] for f in passed)
    skip_size = sum(f["size"] for f in skip)

    lines = []
    lines.append("# 资料索引 & 过滤报告")
    lines.append(f"> 生成时间：{datetime.now().strftime('%Y-%m-%d %H:%M')}")
    lines.append(f"> 总文件：{len(files)} | 总大小：{total_size/1024/1024:.1f} MB")
    lines.append(f"> ✅ 通过：{len(passed)} | ⚠️ 待确认：{len(maybe)} | ❌ 跳过：{len(skip)}")
    lines.append("")

    # === 目录结构 ===
    lines.append("## 📁 模块全景")
    lines.append("")
    by_dir = defaultdict(list)
    for f in files:
        top = f["dir"].split("\\")[0] if f["dir"] else "根目录"
        by_dir[top].append(f)

    dirs_sorted = sorted(by_dir.keys())
    for d in dirs_sorted:
        fs = by_dir[d]
        p_count = len([f for f in fs if f["verdict"] == "✅ 通过"])
        m_count = len([f for f in fs if f["verdict"] == "⚠️ 待确认"])
        s_count = len([f for f in fs if f["verdict"] == "❌ 建议跳过"])
        dir_size = sum(f["size"] for f in fs)
        lines.append(f"| {d} | {len(fs)} 文件 | {dir_size/1024/1024:.0f} MB | ✅{p_count} ⚠️{m_count} ❌{s_count} |")
    lines.append("")

    # === 重复封面 ===
    if duplicates:
        lines.append("## 🔄 疑似重复封面（相同文件头 MD5）")
        lines.append("")
        for md5, names in duplicates.items():
            lines.append(f"- **{names[0]}** ←→ {', '.join(names[1:])}")
        lines.append("")

    # === 病态模式 ===
    if patterns:
        lines.append("## ⚡ 病态模式")
        lines.append("")
        for p in patterns:
            lines.append(f"- {p}")
        lines.append("")

    # === 待确认列表 ===
    lines.append("## ⚠️ 待人工确认（{len(maybe)} 个）")
    lines.append("")
    lines.append("| 文件名 | 目录 | 页数 | 大小 | 风险标记 |")
    lines.append("|--------|------|------|------|----------|")
    for f in sorted(maybe, key=lambda x: x["score"]):
        size_kb = f["size"] // 1024
        flags_str = "; ".join(f["flags"][:2])
        lines.append(f"| {f['name']} | {f['dir']} | {f['pages']}p | {size_kb}KB | {flags_str} |")
    lines.append("")

    # === 建议跳过列表 ===
    lines.append(f"## ❌ 建议跳过（{len(skip)} 个）")
    lines.append("")
    lines.append("| 文件名 | 目录 | 页数 | 大小 | 原因 |")
    lines.append("|--------|------|------|------|------|")
    for f in sorted(skip, key=lambda x: x["score"]):
        size_kb = f["size"] // 1024
        flags_str = "; ".join(f["flags"][:3])
        lines.append(f"| {f['name']} | {f['dir']} | {f['pages']}p | {size_kb}KB | {flags_str} |")
    lines.append("")

    # === 通过列表（按模块分组） ===
    lines.append(f"## ✅ 自动通过（{len(passed)} 个）")
    lines.append("")
    passed_by_dir = defaultdict(list)
    for f in passed:
        top = f["dir"].split("\\")[0] if f["dir"] else "根目录"
        passed_by_dir[top].append(f)
    for d in dirs_sorted:
        fs = passed_by_dir.get(d, [])
        if not fs:
            continue
        lines.append(f"### {d}（{len(fs)} 文件，{sum(f['size'] for f in fs)/1024/1024:.0f} MB）")
        lines.append("")
        lines.append("| 文件名 | 页数 | 大小 |")
        lines.append("|--------|------|------|")
        for f in sorted(fs, key=lambda x: -x["size"]):
            size_str = f"{f['size']/1024/1024:.1f}MB" if f["size"] > 1024*1024 else f"{f['size']//1024}KB"
            lines.append(f"| {f['name']} | {f['pages']}p | {size_str} |")
        lines.append("")

    # === 成本预估 ===
    lines.append("## 💰 处理成本预估")
    lines.append("")
    total_pages = sum(f["pages"] for f in passed if f["pages"] > 0)
    lines.append(f"- 通过文件：{len(passed)} 个，约 {total_pages} 页")
    lines.append(f"- 预估 token：{total_pages * 200} ~ {total_pages * 500}（纯文本提取后）")
    lines.append(f"- 若分 {max(1, len(passed)//8)} 个会话处理，每会话约 {total_pages//max(1, len(passed)//8)} 页")
    lines.append("")

    return "\n".join(lines)

# ============================================================
def main():
    print("[SCAN] Scanning Clippings...")
    all_files = []

    for root, dirs, filenames in os.walk(CLIPPINGS):
        for fn in filenames:
            fpath = os.path.join(root, fn)
            ext = Path(fn).suffix.lower()
            # 跳过视频
            if ext in (".mp4", ".avi", ".mov", ".mkv", ".flv", ".wmv", ".webm"):
                continue
            all_files.append(fpath)

    print(f"   Found {len(all_files)} non-video files")

    # 提取 PDF 元数据
    results = []
    for i, fpath in enumerate(all_files):
        ext = Path(fpath).suffix.lower()
        if ext == ".pdf":
            meta = pdf_meta(fpath)
            if i % 20 == 0:
                print(f"   PDF meta: {i+1}/{len(all_files)}")
        else:
            meta = {"pages": 0, "preview": ""}

        info = classify_file(fpath, meta)
        results.append(info)

    # 全局分析
    duplicates = detect_duplicates(results)
    patterns = detect_pathological_patterns(results)

    # 输出 JSON（机器可读）
    json_path = os.path.join(OUTPUT, "index.json")
    with open(json_path, "w", encoding="utf-8") as f:
        json.dump({
            "generated": datetime.now().isoformat(),
            "total": len(results),
            "passed": len([r for r in results if r["verdict"] == "✅ 通过"]),
            "maybe": len([r for r in results if r["verdict"] == "⚠️ 待确认"]),
            "skip": len([r for r in results if r["verdict"] == "❌ 建议跳过"]),
            "duplicates": duplicates,
            "patterns": patterns,
            "files": results,
        }, f, ensure_ascii=False, indent=2)
    print(f"   JSON index: {json_path}")

    # 输出 Markdown（人可读）
    md_path = os.path.join(OUTPUT, "_filter-report.md")
    md_content = generate_markdown(results, duplicates, patterns)
    with open(md_path, "w", encoding="utf-8") as f:
        f.write(md_content)
    print(f"   Markdown report: {md_path}")

    # 终屏摘要
    passed = len([r for r in results if r["verdict"] == "✅ 通过"])
    maybe  = len([r for r in results if r["verdict"] == "⚠️ 待确认"])
    skip   = len([r for r in results if r["verdict"] == "❌ 建议跳过"])
    print(f"\n{'='*50}")
    print(f"[PASS] {passed} | [MAYBE] {maybe} | [SKIP] {skip}")
    print(f"Dup groups: {len(duplicates)} | Pathological: {len(patterns)}")
    print(f"Output: {OUTPUT}")

if __name__ == "__main__":
    main()
