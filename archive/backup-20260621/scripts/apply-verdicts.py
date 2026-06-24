#!/usr/bin/env python3
"""Apply manual verdict overrides and produce final approved manifest."""
import json, os
from datetime import datetime

INDEX = r"G:\Claude\wiki\考编\_索引\index.json"
OUTPUT = r"G:\Claude\wiki\考编\_索引"

with open(INDEX, "r", encoding="utf-8") as f:
    data = json.load(f)

# --- Override rules ---
OVERRIDE_PASS = [
    # All 上岸村 branded files are legitimate study notes
    "上岸村",
    # Early Shenlun papers with ad tails — content is legit
    "2003年广东",
    "2005年广东",
    "2006年广东",
    "2013年广东",
    # Legitimate讲义 with公众号 in filename
    "2025资料分析理论实战讲义（第一周）",
    # Answer key
    "2026国考言语理论课参考答案.pdf",
]

OVERRIDE_SKIP = [
    "微信小程序扫码，购买纸质资料.jpg",
]

for f in data["files"]:
    name = f["name"]
    old_verdict = f["verdict"]

    # Apply overrides
    for pat in OVERRIDE_SKIP:
        if pat in name:
            f["verdict"] = "❌ 建议跳过"
            f["flags"].append("人工判定: 跳过")
            break
    else:
        for pat in OVERRIDE_PASS:
            if pat in name:
                f["verdict"] = "✅ 通过"
                f["flags"].append("人工判定: 放行（品牌名/真题含广告尾页）")
                break

# Save updated index
with open(INDEX, "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

# --- Build final manifest ---
passed = [f for f in data["files"] if f["verdict"] == "✅ 通过"]
skipped = [f for f in data["files"] if f["verdict"] == "❌ 建议跳过"]

# Group by top-level module
from collections import defaultdict
by_module = defaultdict(list)
for f in passed:
    top = f["dir"].split("\\")[0] if f["dir"] else "root"
    by_module[top].append(f)

total_pages = sum(f["pages"] for f in passed if f["pages"] > 0)
total_size = sum(f["size"] for f in passed)

lines = []
lines.append("# 最终处理清单")
lines.append(f"> 确认时间：{datetime.now().strftime('%Y-%m-%d %H:%M')}")
lines.append(f"> ✅ 通过：{len(passed)} 文件 | ❌ 跳过：{len(skipped)} 文件")
lines.append(f"> 📄 总页数：约 {total_pages} 页 | 📦 总大小：{total_size/1024/1024:.0f} MB")
lines.append(f"> 💰 预估 token：{total_pages*200:,} ~ {total_pages*500:,}")
lines.append("")

lines.append("## 模块处理顺序（建议）")
lines.append("")
lines.append("| 优先级 | 模块 | 文件数 | 页数 | 大小 |")
lines.append("|--------|------|--------|------|------|")

priority_order = [
    "【数量关系】拿分稳稳班（3+2）【高照】",
    "【实战班】2025年高照资料分析理论实战班3+2学习法【完结】",
    "【逻辑薛睿】判断推理系统课讲义",
    "【逻辑薛睿】图推24决",
    "【言语】2026国考大懒猫言语理解理论课",
    "广东公务员考试真题——行测04-25",
    "广东公务员考试真题——申论03-24",
    "【申论】2025菜头公考申论热点素材课程",
    "【申论】2026国省考忠政申论小巨人班",
    "（08）小黑",
]

for mod in priority_order:
    fs = by_module.get(mod, [])
    if not fs:
        continue
    mod_pages = sum(f["pages"] for f in fs if f["pages"] > 0)
    mod_size = sum(f["size"] for f in fs)
    lines.append(f"| {mod} | {len(fs)} | {mod_pages}p | {mod_size/1024/1024:.0f}MB |")

# Remaining modules
for mod in sorted(by_module.keys()):
    if mod not in priority_order:
        fs = by_module[mod]
        mod_pages = sum(f["pages"] for f in fs if f["pages"] > 0)
        mod_size = sum(f["size"] for f in fs)
        lines.append(f"| {mod} | {len(fs)} | {mod_pages}p | {mod_size/1024/1024:.0f}MB |")

lines.append("")

lines.append("## 跳过的文件（供查）")
lines.append("")
for f in skipped:
    lines.append(f"- ~~{f['name']}~~ — {', '.join(f['flags'][:2])}")
lines.append("")

lines.append("## 下一步")
lines.append("")
lines.append("阶段二：结构化拆分（纯本地，零 token）")
lines.append("1. 大 PDF 按章节拆小（高照笔记、大懒猫笔记、忠政基础理论等）")
lines.append("2. 真题按年份/题号拆成独立文件")
lines.append("3. PDF 转纯文本（去格式、去广告尾页）")
lines.append("4. 产出：`_extracted/` 目录，每个知识点一个 txt/md 文件")
lines.append("")
lines.append("阶段三：逐模块提炼（开始消耗 token）")
lines.append("按上述优先级逐个模块处理，每个模块约 3-4 个会话。")

manifest_path = os.path.join(OUTPUT, "_final-manifest.md")
with open(manifest_path, "w", encoding="utf-8") as f:
    f.write("\n".join(lines))

print(f"Final manifest: {manifest_path}")
print(f"PASS: {len(passed)} | SKIP: {len(skipped)}")
print(f"Total pages: {total_pages} | Est tokens: {total_pages*200:,} ~ {total_pages*500:,}")
