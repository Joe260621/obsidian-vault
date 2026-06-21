import fitz
path = r'C:\Users\YU\Desktop\数据整理\简历\作品集_运营相关实战案例.pdf'
doc = fitz.open(path)
print(f'总页数: {doc.page_count}')
for i, page in enumerate(doc):
    print(f'\n=== 第{i+1}页 ===')
    blocks = page.get_text("dict")["blocks"]
    for b in blocks:
        if "lines" in b:
            for l in b["lines"]:
                for s in l["spans"]:
                    font = s.get("font", "?")
                    size = round(s.get("size", 0), 1)
                    flags = s.get("flags", 0)
                    color = s.get("color", 0)
                    text = s.get("text", "")[:60]
                    if text.strip():
                        print(f'  字体={font}, 大小={size}pt, 颜色=#{color:06x}, flags={flags}, 文字="{text}"')
