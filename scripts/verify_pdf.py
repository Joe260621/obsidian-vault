import fitz, sys
sys.stdout.reconfigure(encoding='utf-8')

dst = r'C:\Users\YU\Desktop\数据整理\简历\作品集_运营相关实战案例_清晰版.pdf'
doc = fitz.open(dst)

# 检验文字是否仍然可选（说明是矢量文字而非图片）
page = doc[0]
text = page.get_text().strip()
print(f"第1页文字长度: {len(text)} 字符")
print(f"前100字: {text[:100]}")

# 查看字号
print("\n验证新PDF中的字号（应约为原版的1.5倍）：")
sizes_found = {}
for i in [0, 5, 10]:
    page = doc[i]
    for b in page.get_text("dict")["blocks"]:
        if "lines" in b:
            for l in b["lines"]:
                for s in l["spans"]:
                    sz = round(s.get("size", 0), 1)
                    text = s.get("text", "").strip()
                    if text:
                        sizes_found[sz] = sizes_found.get(sz, 0) + 1

for sz in sorted(sizes_found.keys())[:10]:
    print(f"  {sz}pt: {sizes_found[sz]}次")

# 检查是否还有图片（show_pdf_page是否栅格化了）
images = page.get_images()
print(f"\n第1页图片数: {len(images)}")
if images:
    for img in images[:3]:
        xref = img[0]
        pix = fitz.Pixmap(doc, xref)
        print(f"  图片: {pix.width}x{pix.height}px")
doc.close()
