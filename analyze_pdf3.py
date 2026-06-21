import fitz, sys
sys.stdout.reconfigure(encoding='utf-8')
path = r'C:\Users\YU\Desktop\数据整理\简历\作品集_运营相关实战案例.pdf'
doc = fitz.open(path)

# Get all unique font info across all pages
fonts_seen = set()
for i in range(doc.page_count):
    page = doc[i]
    for b in page.get_text("dict")["blocks"]:
        if "lines" in b:
            for l in b["lines"]:
                for s in l["spans"]:
                    font = s.get("font", "?")
                    size = round(s.get("size", 0), 2)
                    flags = s.get("flags", 0)
                    font_key = (font, size, flags)
                    if font_key not in fonts_seen:
                        fonts_seen.add(font_key)

print("PDF中使用的字体和字号：")
for f, sz, fl in sorted(fonts_seen):
    print(f"  字体={f}, 大小={sz}pt, flags={fl}")

# Now check font embedding via page.get_fonts() 
print("\n--- 字体嵌入信息 ---")
all_fonts = set()
for i in range(doc.page_count):
    page = doc[i]
    font_info = page.get_fonts()
    for fi in font_info:
        key = (fi[0], fi[1], fi[3], fi[4])
        if key not in all_fonts:
            all_fonts.add(key)
            print(f"  字体={fi[0]}, 类型={fi[1]}, 编码={fi[2]}, 嵌入={fi[3]}, 子集={fi[4]}")

# Check if text is selectable/copyable
print("\n--- 文字可选性检验 ---")
page0 = doc[0]
text0 = page0.get_text()
print(f"第1页文字: \"{text0[:100]}...\"")

