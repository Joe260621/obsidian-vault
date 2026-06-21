import fitz, sys
sys.stdout.reconfigure(encoding='utf-8')
path = r'C:\Users\YU\Desktop\数据整理\简历\作品集_运营相关实战案例.pdf'
doc = fitz.open(path)

# Check metadata
meta = doc.metadata
print("PDF元数据:")
for k, v in meta.items():
    print(f"  {k}: {v}")

# Check each font's embedding status deeply
print("\n===== 详细字体嵌入分析 =====")
for i in range(min(3, doc.page_count)):
    page = doc[i]
    fonts = page.get_fonts()
    for f in fonts:
        # f = (xref, ext, width, name, ...)
        xref = f[0]
        try:
            # Get font dictionary
            font_dict = doc.xref_get_key(xref, "FontDescriptor")
            print(f"  字体xref={xref}, name={f[3]}, FontDescriptor存在={font_dict[0] != 0}")
        except:
            pass

# Check page dimensions
print("\n===== 页面尺寸 =====")
for i in range(min(3, doc.page_count)):
    page = doc[i]
    rect = page.rect
    print(f"  第{i+1}页: {rect.width:.0f} x {rect.height:.0f} 点 ({(rect.width/72):.1f} x {(rect.height/72):.1f} 英寸)")

# Check if it's a PDF that was created from PPT/Keynote
# Look at the producer/creator
print(f"\n创建者: {meta.get('creator', 'N/A')}")
print(f"生产者: {meta.get('producer', 'N/A')}")
print(f"格式: {meta.get('format', 'N/A')}")

# Check for Type3 fonts specifically (these are often problematic)
print("\n===== Type3字体检查 =====")
for i in range(doc.page_count):
    page = doc[i]
    fonts = page.get_fonts()
    for f in fonts:
        if f[1] == "Type3" or f[1] == "n/a":
            print(f"  第{i+1}页: xref={f[0]}, type={f[1]}, name={f[3]}")
