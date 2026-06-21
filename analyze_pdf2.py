import fitz, sys
sys.stdout.reconfigure(encoding='utf-8')
path = r'C:\Users\YU\Desktop\数据整理\简历\作品集_运营相关实战案例.pdf'
doc = fitz.open(path)
print(f'总页数: {doc.page_count}')
# Check each page for images vs text
for i, page in enumerate(doc):
    # Check images on page
    image_list = page.get_images()
    text = page.get_text()
    print(f'\n第{i+1}页: 图片数={len(image_list)}, 文字长度={len(text.strip())}')
    if image_list:
        for idx, img in enumerate(image_list[:3]):
            xref = img[0]
            pix = fitz.Pixmap(doc, xref)
            print(f'  图片{idx}: {pix.width}x{pix.height}, colorspace={pix.n}')
    # Check font embedding info
    for b in page.get_text("dict")["blocks"]:
        if "lines" in b:
            for l in b["lines"]:
                for s in l["spans"]:
                    # Check flags for embedded fonts
                    font = s.get("font", "?")
                    size = s.get("size", 0)
                    if 6 < size < 9:  # small subtitle range
                        text = s.get("text", "")[:80]
                        if text.strip():
                            print(f'  小字: font={font}, size={size}pt, text="{text}"')
                        break
                break
        break
