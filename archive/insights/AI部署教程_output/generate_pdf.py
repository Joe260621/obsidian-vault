#!/usr/bin/env python3
"""PDF 生成器 - 使用 fpdf2 纯 Python 库"""

import os
from pathlib import Path
from fpdf import FPDF

OUTPUT_DIR = Path(__file__).parent
IMG_DIR = OUTPUT_DIR / "images"

# 配色
C_PRIMARY = (79, 70, 229)
C_DARK = (30, 41, 59)
C_GRAY = (100, 116, 139)
C_LIGHT_BG = (248, 250, 252)
C_WHITE = (255, 255, 255)
C_GREEN = (5, 150, 105)
C_RED = (220, 38, 38)
C_WARN = (217, 119, 6)
C_BLUE_BG = (239, 246, 255)

class PDF(FPDF):
    def __init__(self):
        super().__init__("P", "mm", "A4")
        # 注册中文字体
        font_dir = "C:/Windows/Fonts"
        for fname in ["msyh.ttc", "msyh.ttf", "simhei.ttf", "simsun.ttc"]:
            fp = os.path.join(font_dir, fname)
            if os.path.exists(fp):
                self.add_font("CJK", "", fp, uni=True)
                self.add_font("CJK", "B", fp, uni=True)
                break
        self.set_auto_page_break(True, 18)

    def header(self):
        if self.page_no() == 1:
            return
        self.set_font("CJK", "", 8)
        self.set_text_color(*C_GRAY)
        self.cell(0, 5, "AI 工具部署教程 · 小白版", align="L")
        self.cell(0, 5, f"第 {self.page_no()} 页", align="R", new_x="LMARGIN", new_y="NEXT")
        self.line(self.l_margin, self.get_y(), self.w - self.r_margin, self.get_y())
        self.ln(4)

    def footer(self):
        self.set_y(-15)
        self.set_font("CJK", "", 7)
        self.set_text_color(*C_GRAY)
        self.cell(0, 10, f"v1.0 · 2026-06-22", align="C")

    def title1(self, txt):
        self.ln(4)
        self.set_fill_color(*C_PRIMARY)
        self.set_draw_color(*C_PRIMARY)
        r, g, b = C_PRIMARY
        # 左侧色条
        self.rect(self.l_margin, self.get_y(), 3, 10, "F")
        self.set_font("CJK", "B", 20)
        self.set_text_color(*C_PRIMARY)
        self.set_x(self.l_margin + 6)
        self.cell(0, 10, txt, new_x="LMARGIN", new_y="NEXT")
        self.ln(4)

    def title2(self, txt):
        self.ln(2)
        self.set_font("CJK", "B", 14)
        self.set_text_color(*C_DARK)
        self.set_draw_color(226, 232, 240)
        self.cell(0, 8, txt, new_x="LMARGIN", new_y="NEXT")
        y = self.get_y()
        self.line(self.l_margin, y, self.w - self.r_margin, y)
        self.ln(3)

    def title3(self, txt):
        self.set_font("CJK", "B", 12)
        self.set_text_color(51, 65, 85)
        self.cell(0, 7, txt, new_x="LMARGIN", new_y="NEXT")
        self.ln(1)

    def body(self, txt):
        self.set_font("CJK", "", 10)
        self.set_text_color(*C_DARK)
        self.multi_cell(0, 5.5, txt, align="L")
        self.ln(1)

    def tip_box(self, txt, color=C_BLUE_BG, border_color=(59, 130, 246)):
        self.set_fill_color(*color)
        self.set_draw_color(*border_color)
        self.set_font("CJK", "", 9.5)
        self.set_text_color(*C_DARK)
        y0 = self.get_y()
        self.set_x(self.l_margin + 2)
        self.multi_cell(self.w - self.l_margin - self.r_margin - 4, 5, txt, fill=True)
        self.ln(2)

    def code_block(self, txt):
        self.set_fill_color(30, 41, 59)
        self.set_text_color(226, 232, 240)
        self.set_font("CJK", "", 8.5)
        y0 = self.get_y()
        self.set_x(self.l_margin + 2)
        self.multi_cell(self.w - self.l_margin - self.r_margin - 4, 4.5, txt, fill=True)
        self.set_text_color(*C_DARK)
        self.ln(2)

    def add_image_centered(self, path, max_w=170):
        if path.exists():
            self.image(str(path), x=self.l_margin + 5, w=max_w)
            self.ln(3)

    def table(self, headers, rows, col_widths=None):
        if col_widths is None:
            col_widths = [self.w - self.l_margin - self.r_margin] / len(headers)
        # Header
        self.set_fill_color(*C_PRIMARY)
        self.set_text_color(*C_WHITE)
        self.set_font("CJK", "B", 9)
        for h, w in zip(headers, col_widths):
            self.cell(w, 7, h, border=0, fill=True, align="L")
        self.ln()
        # Rows
        for i, row in enumerate(rows):
            if i % 2 == 0:
                self.set_fill_color(*C_LIGHT_BG)
            else:
                self.set_fill_color(*C_WHITE)
            self.set_text_color(*C_DARK)
            self.set_font("CJK", "", 9)
            for cell, w in zip(row, col_widths):
                self.cell(w, 6.5, str(cell), border=0, fill=True, align="L")
            self.ln()
        self.ln(3)


def build_pdf():
    pdf = PDF()
    img = lambda n: IMG_DIR / n

    # ====== 封面 ======
    pdf.add_page()
    pdf.set_fill_color(*C_PRIMARY)
    pdf.rect(0, 0, 210, 297, "F")
    pdf.set_y(70)
    pdf.set_font("CJK", "B", 36)
    pdf.set_text_color(*C_WHITE)
    pdf.cell(0, 15, "AI 工具部署教程", align="C", new_x="LMARGIN", new_y="NEXT")
    pdf.set_font("CJK", "", 18)
    pdf.set_text_color(199, 210, 254)
    pdf.cell(0, 10, "从零开始 · 小白也能学会的 AI 工具安装指南", align="C", new_x="LMARGIN", new_y="NEXT")
    pdf.ln(10)
    pdf.set_draw_color(129, 140, 248)
    pdf.set_line_width(0.6)
    pdf.line(70, pdf.get_y(), 140, pdf.get_y())
    pdf.ln(10)
    pdf.set_font("CJK", "", 12)
    pdf.set_text_color(165, 180, 252)
    pdf.cell(0, 8, "Claude Code 命令行版 · 实战教程", align="C", new_x="LMARGIN", new_y="NEXT")
    pdf.cell(0, 8, "版本 1.0  |  2026-06-22  |  基于实战经验编写", align="C", new_x="LMARGIN", new_y="NEXT")

    # ====== 第1章：认识AI部署 ======
    pdf.add_page()
    pdf.title1("一、认识 AI 工具部署")

    pdf.title2("1.1 什么是 AI 工具部署？")
    pdf.body("AI 工具部署就是把人工智能软件安装到你的电脑上，让它能正常运行。")
    pdf.body("类比：就像给手机安装微信、抖音一样 —— 只不过 AI 工具的安装稍微复杂一点，需要一些命令行操作。本教程就是帮你完成这一步。")

    pdf.title2("1.2 部署后能做什么？")
    pdf.table(
        ["场景", "例子"],
        [["编程辅助", "写代码、修Bug、解释代码逻辑"],
         ["文档处理", "写报告、翻译、润色文章"],
         ["数据分析", "处理Excel、生成图表、分析趋势"],
         ["学习助手", "解答问题、整理笔记、生成练习题"],
         ["自动化工作流", "自动发邮件、整理文件、定时任务"]],
        [50, 120]
    )

    pdf.tip_box("关键认知：AI 工具是你的「智能助手」，不是替代你，而是帮你省时间。安装好之后，你就拥有了一个 24 小时在线的 AI 帮手。")

    pdf.title2("1.3 部署路线图一览")
    pdf.add_image_centered(img("deployment_roadmap.png"), 170)

    # ====== 第2章：部署前的准备 ======
    pdf.add_page()
    pdf.title1("二、部署前的准备")

    pdf.title2("2.1 环境检查清单")
    pdf.add_image_centered(img("env_checklist.png"), 170)

    pdf.tip_box("安装前必读：请逐项核对以上清单。如果某项不满足，先解决再继续。", border_color=(245, 158, 11))

    pdf.title2("2.2 AI 工具选哪个？")
    pdf.body("市面上有多种 AI 工具可选，以下是适合新手的对比：")
    pdf.add_image_centered(img("tool_comparison.png"), 160)

    pdf.table(
        ["工具", "合适人群", "难度", "推荐"],
        [["Claude Code (IDE插件)", "会用 VSCode 的", "极简", "★★★★★"],
         ["Claude Code (命令行)", "不介意敲命令", "简单", "★★★★★"],
         ["OpenClaw (龙虾)", "需要多功能集成", "中等", "★★★★"],
         ["Stable Diffusion", "需要 AI 绘画", "较难", "★★★"]],
        [42, 42, 22, 64]
    )

    pdf.tip_box("推荐：本教程以 Claude Code 命令行版为主线 —— 功能最强、适用最广、步骤最清晰。")

    # ====== 第3章：手把手安装 ======
    pdf.add_page()
    pdf.title1("三、手把手安装教程")

    pdf.title2("3.1 总览：四步完成部署")
    pdf.add_image_centered(img("install_steps.png"), 180)

    pdf.add_page()
    pdf.title2("3.2 第一步：安装 Node.js 环境")
    pdf.body("Claude Code 基于 Node.js 运行，所以需要先安装它。")

    pdf.title3("Windows 用户")
    pdf.code_block(
        "1. 浏览器打开 https://nodejs.org\n"
        "2. 点击左侧绿色按钮 \"LTS\" 下载 .msi 文件\n"
        "3. 双击运行，一路点 Next\n"
        "4. ⚠️ 关键一步：确保勾选 \"Add to PATH\"！\n"
        "5. 安装完成后，重启终端\n"
        "\n"
        "# 验证安装：\n"
        "node --version\n"
        "npm --version"
    )

    pdf.title3("macOS 用户")
    pdf.code_block(
        "# 方法一：官网下载（推荐）\n"
        "浏览器打开 https://nodejs.org → 下载 LTS → 双击安装\n"
        "\n"
        "# 方法二：Homebrew（如果你装了）\n"
        "brew install node@20"
    )

    pdf.tip_box("看到版本号 = Node.js 安装成功！继续下一步。", border_color=(34, 197, 94))

    pdf.title2("3.3 第二步：获取 Anthropic API Key")
    pdf.code_block(
        "1. 浏览器打开 https://console.anthropic.com\n"
        "2. 注册账号（用邮箱即可）\n"
        "3. 登录后，左侧菜单点击 \"API Keys\"\n"
        "4. 点击 \"Create Key\" 按钮\n"
        "5. 复制生成的 Key（sk-ant-... 开头）\n"
        "6. ⚠️ 这个 Key 只显示一次，务必保存好！\n"
        "7. 在 Billing 页面充值（最低 $5，约 ¥36）"
    )

    pdf.tip_box("安全警告：API Key 就像你的银行卡密码 —— 不要发给任何人，不要截图发朋友圈，不要提交到 GitHub！",
                border_color=(239, 68, 68))

    pdf.title2("3.4 第三步：安装 Claude Code")
    pdf.code_block(
        "# 在终端中运行（Windows 用管理员模式）：\n"
        "npm install -g @anthropic-ai/claude-code\n"
        "\n"
        "# 等待约 2-5 分钟，看到类似输出就成功了：\n"
        "# + @anthropic-ai/claude-code@1.x.x\n"
        "\n"
        "# 验证安装：\n"
        "claude --version"
    )

    pdf.tip_box("Windows 用户注意：如果报权限错误 (EACCES/EPERM)，请用管理员身份运行终端：Win+X → 终端(管理员)。",
                border_color=(217, 119, 6))

    pdf.title2("3.5 第四步：配置登录")
    pdf.code_block(
        "# 交互式登录（推荐）：\n"
        "claude login\n"
        "# 按提示粘贴你的 API Key，看到 ✓ 即完成\n"
        "\n"
        "# 最终验证：\n"
        "claude \"你好，请用一句中文介绍你自己\"\n"
        "# 如果看到 AI 的回复 → 部署成功！"
    )

    pdf.tip_box("恭喜！你已经完成了 AI 工具的部署。现在你拥有一个可以通过命令行随时调用的 AI 助手。",
                border_color=(34, 197, 94))

    # ====== 第4章：配置与验证 ======
    pdf.add_page()
    pdf.title1("四、配置与验证")

    pdf.title2("4.1 常用命令速查表")
    pdf.table(
        ["命令", "作用", "示例"],
        [["claude", "进入交互对话模式", "直接在终端输入"],
         ["claude \"问题\"", "单次提问", "claude \"1+1=?\""],
         ["claude --version", "查看版本", "检查是否需要更新"],
         ["claude login", "重新登录/换Key", "Key 过期时使用"],
         ["npm update -g @anthropic-ai/claude-code", "更新到最新版", "建议每周检查"],
         ["npm uninstall -g @anthropic-ai/claude-code", "卸载", "不想用了就删"]],
        [55, 55, 60]
    )

    pdf.title2("4.2 进阶：VSCode 插件版")
    pdf.body("如果你使用 VSCode 编辑器，还有更简单的方式：")
    pdf.code_block(
        "1. 打开 VSCode\n"
        "2. 左侧点击「扩展」(Ctrl+Shift+X)\n"
        "3. 搜索 \"Claude Code\"\n"
        "4. 点击「安装」\n"
        "5. 安装后按提示登录 → 直接在编辑器里用 AI"
    )
    pdf.tip_box("插件版 vs 命令行版：插件版集成在编辑器里，写代码更方便；命令行版可以在任何地方使用，更灵活。两个可以同时安装。")

    # ====== 第5章：问题排查 ======
    pdf.add_page()
    pdf.title1("五、常见问题排查")
    pdf.add_image_centered(img("troubleshooting.png"), 175)

    pdf.title2("5.1 详细解决方案")

    pdf.title3("问题1：npm: command not found")
    pdf.tip_box("原因：Node.js 没有正确安装，或未添加到系统 PATH。\n解决：重新从 nodejs.org 下载 LTS 版本，安装时确保勾选「Add to PATH」。安装后重新打开终端再试。",
                border_color=(239, 68, 68))

    pdf.title3("问题2：权限错误 (EACCES / EPERM)")
    pdf.tip_box("原因：当前用户没有写入系统目录的权限。\n解决：Mac/Linux 命令前加 sudo；Windows 用管理员身份运行终端（Win+X → 终端(管理员)）。",
                border_color=(217, 119, 6))

    pdf.title3("问题3：claude: command not found")
    pdf.tip_box("原因：npm 全局包的 bin 目录不在 PATH 中。\n解决：① 运行 npm list -g --depth=0 确认已安装；② 重启终端；③ 如仍不行，用 npx @anthropic-ai/claude-code 代替。",
                border_color=(217, 119, 6))

    pdf.title3("问题4：API 返回 401 错误")
    pdf.tip_box("原因：API Key 无效、过期或账户欠费。\n解决：① 去 console.anthropic.com → API Keys 检查 Key 状态；② 如 Key 被删/过期，创建新 Key 并重新 claude login；③ 检查 Billing 页面确认账户有余额。",
                border_color=(239, 68, 68))

    pdf.title3("问题5：网络超时 / 连接失败")
    pdf.tip_box("原因：网络问题或防火墙拦截。\n解决：① 检查网络是否正常（打开网页试试）；② 关闭 VPN/代理软件再试；③ 切换手机热点测试（排除宽带问题）；④ Windows：检查防火墙是否拦截了 Node.js。",
                border_color=(217, 119, 6))

    # ====== 第6章：使用指南 ======
    pdf.add_page()
    pdf.title1("六、安装后使用指南")

    pdf.title2("6.1 你的第一次 AI 对话")
    pdf.code_block(
        "# 简单问答\n"
        "claude \"今天天气怎么样？\"\n"
        "\n"
        "# 让它帮你做事\n"
        "claude \"帮我写一段 Python 代码，读取 CSV 文件并画折线图\"\n"
        "\n"
        "# 翻译\n"
        "claude \"把这段话翻译成英文：人工智能正在改变世界\"\n"
        "\n"
        "# 解释概念\n"
        "claude \"什么是机器学习？用简单的例子解释\""
    )

    pdf.title2("6.2 高效使用技巧")
    pdf.table(
        ["技巧", "说明", "例子"],
        [["越具体越好", "模糊的问题得到模糊的答案", "✗\"写个方案\" → ✓\"写奶茶店抖音运营方案\""],
         ["给上下文", "告诉 AI 你的背景和目的", "\"我是新手，请用小学生能懂的话解释\""],
         ["可以追问", "不满意就让它改", "\"太长了，压缩到200字\""],
         ["处理文件", "能读写你的本地文件", "\"分析这个CSV的销售趋势\""],
         ["定期更新", "保持工具最新", "npm update -g @anthropic-ai/claude-code"]],
        [30, 48, 92]
    )

    pdf.title2("6.3 费用说明")
    pdf.table(
        ["项目", "费用", "说明"],
        [["Claude Code 软件", "完全免费", "开源工具，永久免费使用"],
         ["Anthropic API", "按量付费", "月均约 ¥30-200（日常使用）"],
         ["API 最低充值", "$5 (约¥36)", "够试用 1-2 周"]],
        [42, 42, 86]
    )
    pdf.tip_box("省钱技巧：日常使用选 claude-haiku-4-5 模型（便宜、够用），重任务时才用 claude-sonnet-4-6。在配置文件里设置默认模型即可。")

    # ====== 第7章：附录 ======
    pdf.add_page()
    pdf.title1("七、附录")

    pdf.title2("7.1 部署流程速查表")
    pdf.table(
        ["步骤", "做什么", "关键命令", "时间"],
        [["1", "装 Node.js", "去 nodejs.org 下载", "5分钟"],
         ["2", "获取 API Key", "console.anthropic.com", "5分钟"],
         ["3", "安装 Claude Code", "npm install -g @anthropic-ai/claude-code", "3分钟"],
         ["4", "配置登录", "claude login", "1分钟"],
         ["5", "验证", "claude \"你好\"", "1分钟"],
         ["", "", "总计", "约15分钟"]],
        [12, 42, 78, 38]
    )

    pdf.title2("7.2 重要链接")
    pdf.table(
        ["资源", "链接"],
        [["Node.js 下载", "https://nodejs.org"],
         ["Anthropic 控制台", "https://console.anthropic.com"],
         ["Claude Code 文档", "https://docs.anthropic.com/en/docs/claude-code"],
         ["VSCode 下载", "https://code.visualstudio.com"]],
        [58, 112]
    )

    pdf.title2("7.3 环境变量配置（可选）")
    pdf.body("如果你不想每次都用 claude login，可以设置系统环境变量：")
    pdf.title3("Windows")
    pdf.code_block(
        "# PowerShell (仅当前用户)\n"
        '[Environment]::SetEnvironmentVariable(\n'
        '    "ANTHROPIC_API_KEY",\n'
        '    "sk-ant-你的key",\n'
        '    "User"\n'
        ')\n'
        '\n'
        "# 或通过图形界面：\n"
        "# 设置 → 系统 → 关于 → 高级系统设置 → 环境变量 → 新建"
    )
    pdf.title3("macOS / Linux")
    pdf.code_block(
        "# 添加到 ~/.zshrc 或 ~/.bashrc\n"
        'echo \'export ANTHROPIC_API_KEY="sk-ant-你的key"\' >> ~/.zshrc\n'
        "source ~/.zshrc"
    )
    pdf.tip_box("提醒：不要在共享电脑上存 API Key！不要在公开的脚本里写 Key！", border_color=(239, 68, 68))

    # 保存
    pdf_path = OUTPUT_DIR / "AI工具部署教程_小白版.pdf"
    pdf.output(str(pdf_path))
    print(f"✅ PDF 已生成: {pdf_path}")
    return pdf_path


if __name__ == "__main__":
    build_pdf()
