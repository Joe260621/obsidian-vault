import fitz, sys
sys.stdout.reconfigure(encoding='utf-8')

dst = r'C:\Users\YU\Desktop\数据整理\简历\作品集_运营相关实战案例_清晰版.pdf'
doc = fitz.open(dst)

print("字体嵌入检查：")
fonts = doc[0].get_fonts()
for f in fonts:
    print(f"  字体={f[3]}, 类型={f[1]}, 嵌入前缀={f[3][:8]}")

print(f"\n文件大小: {fitz.open(dst).metadata}")
doc.close()

import os
size_kb = os.path.getsize(dst) / 1024
orig_kb = os.path.getsize(r'C:\Users\YU\Desktop\数据整理\简历\作品集_运营相关实战案例.pdf') / 1024
print(f"原文件: {orig_kb:.0f} KB → 新文件: {size_kb:.0f} KB")
