# AI Agent核心技术——学习归档（模块2）

- **Source**: G:\quark\Obsidian笔记\学习归档\产品经理_模块2_AI_Agent核心技术_学习归档.md
- **Collected**: 2026-06-20
- **Published**: 2026-06-04

---

## 模块2概述：AI Agent 的三个核心能力
一个完整的 AI Agent = 能查资料(RAG) + 能动手干活(Tool Calling) + 能思考循环(ReAct)

## 第1课：RAG——检索增强生成
核心概念：RAG = 先检索知识库 → 再让AI基于检索结果回答
动手实践：将希尔顿76款产品数据做成RAG知识库，AI能基于知识库回答产品问题（非胡编）

## 第2课：Tool Calling——AI自己调用工具
核心概念：Tool Calling = 给AI工具箱，AI自己决定调哪个函数完成任务
动手实践：交互式Tool Calling，AI自动查价格(get_price)、查库存(check_stock)

## 第3课：ReAct——Agent的思考循环
核心概念：ReAct = Reasoning + Acting = 先想再做，做完再想，循环到任务完成
实战推演：用户"帮我查自助晚餐还有没有，有的话帮我下单2份"——多步骤循环

## 面试常见追问（已准备应答）
- Q: "RAG检索不准怎么办？" → A: 改进知识库质量、优化关键词匹配、加入语义搜索（向量检索）
- Q: "Tool Calling AI选错工具怎么办？" → A: 设计降级策略——工具调用失败时回退到直接对话
- Q: "ReAct循环会不会无限跑下去？" → A: 设置最大步数（如5步），超出自动转人工
- Q: "你理解这些技术，但你会写代码吗？" → A: 我能用Python搭RAG和Tool Calling的Demo

## Demo脚本位置
D:\ProjectManagement\Claude\简历优化\ai-learning\
- 11_ai_agent_demo.py —— RAG + Tool Calling 完整演示
- 11_rag_practice.py —— 交互式RAG问答（76款希尔顿产品知识库）
- 11_tool_calling_interactive.py —— 交互式Tool Calling（5款产品工具库）
