import fitz, sys, os
sys.stdout.reconfigure(encoding='utf-8')

src = r'C:\Users\YU\Desktop\数据整理\简历\作品集_运营相关实战案例.pdf'
doc = fitz.open(src)

print("PDF创建来源（通过Chrome/Skia导出）")
print(f"页面尺寸: {doc[0].rect.width:.0f} x {doc[0].rect.height:.0f} pt")
print()

# 统计各字号使用情况
size_counts = {}
for i in range(doc.page_count):
    page = doc[i]
    for b in page.get_text("dict")["blocks"]:
        if "lines" in b:
            for l in b["lines"]:
                for s in l["spans"]:
                    sz = round(s.get("size", 0), 1)
                    text = s.get("text", "").strip()
                    if text:
                        size_counts[sz] = size_counts.get(sz, 0) + 1

print("各字号使用频次（判断小标题字号范围）：")
for sz in sorted(size_counts.keys()):
    bar = "█" * min(size_counts[sz] // 5, 40)
    print(f"  {sz:5.1f}pt: {size_counts[sz]:3d}次 {bar}")

# 诊断结论
print("\n" + "="*60)
print("诊断结论")
print("="*60)
print("""
问题分析:
1. 该PDF由 Chrome (Skia/PDF m125) 导出，原内容可能来自网页或PPT
2. 小标题字号为 6.0~7.5pt（Microsoft YaHei / SegoeUI 字体）
3. 6~7pt 对于中文字体（笔画复杂）来说极小，渲染时会出现模糊/锯齿
4. Skia渲染器在小字号下的抗锯齿效果不佳
5. 字体虽已嵌入子集，但物理尺寸太小是根本原因

建议修复方案:
- 方案A（推荐）: 将PDF内容整体放大1.5倍，使小字从6pt→9pt，提升可读性
- 方案B: 将PDF页面转为高分辨率图片再生成PDF（会丢失文字可选性）
- 方案C: 重新从源文件导出（如PPT/Word）,调大字号后重导
""")
