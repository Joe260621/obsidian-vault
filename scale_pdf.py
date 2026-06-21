import fitz, sys, os
sys.stdout.reconfigure(encoding='utf-8')

src = r'C:\Users\YU\Desktop\数据整理\简历\作品集_运营相关实战案例.pdf'
dst = r'C:\Users\YU\Desktop\数据整理\简历\作品集_运营相关实战案例_清晰版.pdf'

doc = fitz.open(src)
scale = 1.5  # 放大1.5倍

new_doc = fitz.open()  # 创建新PDF

for i in range(doc.page_count):
    page = doc[i]
    
    # 获取原页面尺寸
    rect = page.rect
    w = rect.width
    h = rect.height
    
    # 新页面尺寸（缩放后）
    new_w = w * scale
    new_h = h * scale
    
    # 创建新页面
    new_page = new_doc.new_page(width=new_w, height=new_h)
    
    # 将原页面内容以scale倍渲染到新页面
    # 使用MediaBox + Matrix缩放
    # Show the original page content with a scale transformation
    new_page.show_pdf_page(
        new_page.rect,          # 目标区域（整页）
        doc,                     # 源文档
        i,                       # 源页码
        clip=page.rect,          # 源区域
        rotate=0,                # 不旋转
    )
    
    if (i+1) % 5 == 0:
        print(f"  已完成 {i+1}/{doc.page_count} 页")

print(f"全部 {doc.page_count} 页处理完成")
print(f"保存到: {dst}")

# Save with optimizations
new_doc.save(
    dst,
    garbage=4,        # 彻底清理冗余数据
    deflate=True,     # 压缩
    clean=True,       # 清理
)
new_doc.close()
doc.close()

# 验证
verify = fitz.open(dst)
print(f"\n新PDF: {verify.page_count} 页, 第1页尺寸: {verify[0].rect.width:.0f} x {verify[0].rect.height:.0f} pt")
print(f"文件大小: {os.path.getsize(dst)/1024:.0f} KB")
verify.close()
