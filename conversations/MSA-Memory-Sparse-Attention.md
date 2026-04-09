---
uid: MSA-Memory-Sparse-Attention
created: 2026-04-09
updated: 2026-04-09
tags: [paper, memory, attention, long-context, RAG, MSA]
related:
  - "[[2026-04-09]]"
---

# MSA: Memory Sparse Attention

> Paper: [arXiv:2603.23516](https://arxiv.org/abs/2603.23516)
> Authors: Yu Chen, Runkai Chen, Sheng Yi, Xinda Zhao, Xiaohong Li, Jianjin Zhang, Jun Sun, Chuanrui Hu, Yunyun Han, Lidong Bing, Yafeng Deng, Tianqiao Chen
> Institution: EverMind-AI / Shanda Group / Peking University
> Code: https://github.com/EverMind-AI/MSA
> Model: https://huggingface.co/EverMind-AI/MSA-4B

## 核心贡献

**MSA (Memory Sparse Attention)** 是一个端到端可训练的稀疏潜状态记忆框架，能在 **100M token** 上下文上高效运行。

> 人类记忆的功能信息容量约为 10⁹ bits，假设每个 token 有效语义密度为 33-55 bits，则终身记忆容量约为 200-300 百万 token。MSA 实现了接近这个数量级的记忆能力。

---

## 解决的问题

### 现有方案的三大缺陷

| 方案 | 缺陷 |
|------|------|
| **参数化记忆** (LoRA/CPT/Titans) | 参数更新易发生灾难性遗忘，缺乏容量可扩展性 |
| **外部存储记忆** (RAG/MemAgent) | 非端到端训练，检索与生成解耦，精度受限 |
| **潜状态记忆** (线性注意力/DSA) | 稀疏注意力计算成本高；线性注意力容量有限，精度差 |

### MSA 的核心目标

1. **容量可扩展**：支持 lifetime-scale（100M+ token）
2. **高精度**：端到端训练，记忆保真度高
3. **计算高效**：近线性复杂度 O(L)
4. **防止灾难性遗忘**：记忆与推理解耦

---

## 核心技术

### 1. 稀疏注意力机制

#### 标准 dense attention 的问题
标准自注意力的复杂度是 O(L²)，当 L = 100M 时不可行。

#### MSA 的解决方案：Top-k Chunk 选择

```
文档 bank: D = {d₁, d₂, ..., dₙ}
每个文档分成固定长度的 chunk

1. 对每个 chunk 做 mean pooling 压缩：
   K̄ = φ(K), V̄ = φ(V), K̄ᴿ = φ(Kᴿ)

2. 给定查询 Q：
   - Router Q Projector 生成 Qᴿ
   - Qᴿ 与所有 chunk 的 K̄ᴿ 计算 cosine similarity
   - 取 Top-k 最相关的文档

3. 生成时只拼接选中的 K̄, V̄：
   Kctx = [{K̄ᵢ}_{i∈ℐ}; Kq]
   Vctx = [{V̄ᵢ}_{i∈ℐ}; Vq]
```

#### 分层应用
MSA 只在**后半层**应用稀疏路由。前半层保留独立文档处理，不做记忆检索。

> 原因：浅层的 hidden states 还没捕获高层语义抽象，路由效率低。

---

### 2. Document-wise RoPE

#### 训练-推理长度不匹配问题
- 训练：短上下文（e.g., 64K tokens）
- 推理：极长上下文（e.g., 100M tokens）

标准全局位置编码会导致位置索引大幅偏移，训练时学的位置语义无法泛化。

#### 解决方案：每个文档独立编号

- 每个文档的位置 ID 从 0 开始独立计算
- 不受总文档数影响
- 模型可以有效外推到任意规模的 memory bank

#### 全局 RoPE 用于活跃上下文
- 查询和后续生成的位置 ID 偏移 k（Top-k 文档数量）
- 保持因果依赖，确保生成连贯性

---

### 3. 三阶段推理流程

```
┌──────────────────────────────────────────────────────────────┐
│  Stage 1: Global Memory Encoding (离线)                      │
│  语料库 → 前向传播 → 压缩的 (K̄, V̄, K̄ᴿ) → Memory Bank      │
└──────────────────────────────────────────────────────────────┘
                           ↓
┌──────────────────────────────────────────────────────────────┐
│  Stage 2: Routing & Context Assembly (在线)                  │
│  查询 Q → Router Q Projector → Qᴿ                          │
│  Qᴿ 与 K̄ᴿ 匹配 → Top-k 文档 → 加载对应 K̄, V̄              │
└──────────────────────────────────────────────────────────────┘
                           ↓
┌──────────────────────────────────────────────────────────────┐
│  Stage 3: Sparse Generation (在线)                           │
│  拼接的稀疏上下文 → 自回归解码 → 答案                        │
└──────────────────────────────────────────────────────────────┘
```

---

### 4. Memory Interleave（多跳推理）

#### 问题
单次检索无法处理多跳问题（如"谁的父亲出生于 X？"）。

#### 解决方案：迭代式检索-生成

```
1. 根据问题生成相关文档 ID（结束于特殊分隔符）
2. 加载对应文档原文，拼接到原始查询后面
3. 重复：生成新文档 ID → 加载文档 → 拼接
4. 直到模型认为够了 → 生成最终答案
```

**关键**：每轮生成的不是答案，而是**文档 ID**，文档原文是后续注入的。

---

## 训练方法

### 连续预训练（158.95B tokens）

#### 目标：Generative Retrieval
模型学习根据问题自回归生成相关文档的 unique ID。

#### 辅助损失 ℒaux
监督 Router 的 Top-k 选择决策：
```
ℒaux = -1/|P| × Σ log[exp(s⁺/τ) / (exp(s⁺/τ) + Σexp(s⁻/τ))]
```
其中 P 是正文档集，N 是负文档集，s 是相似度分数。

#### 两阶段优化
| 阶段 | Loss | Learning Rate | 目的 |
|------|------|---------------|------|
| Warm-up | ℒ = 0.1ℒLLM + ℒaux | 1e-4 | 快速学习路由策略 |
| Main | ℒ = ℒLLM + 0.1ℒaux | 6e-6 | 优先生成任务，保持路由能力 |

### 两阶段 SFT

| 阶段 | Context Length | 目的 |
|------|---------------|------|
| Stage 1 | 8K | 建立基础指令跟随和推理能力 |
| Stage 2 | 64K | 延长上下文，增强对长依赖的鲁棒性 |

---

## 实验结果

### QA 任务（9 项基准）

#### vs 同 backbone RAG

| 配置 | 平均分数 |
|------|---------|
| Qwen3-4B (基线) | 2.559 |
| Qwen3-4B + RAG (Rerank) | 2.946 |
| HippoRAG2 | 2.612 |
| **MSA (adaptive)** | **3.760** |

→ 超越标准 RAG **+16.0%**，RAG+rerank **+11.5%**，HippoRAG2 **+14.8%**

#### vs SOTA RAG Stacks

| 配置 | 平均分数 |
|------|---------|
| KaLMv2 + Qwen3-235B | 3.036 |
| KaLMv2 + Llama-3.3-70B | 3.161 |
| **MSA** | **3.760** |

→ 超越最强 RAG 配置 **+7.2%**

### NIAH 测试

| 模型 | @32K | @1M | 衰减 |
|------|------|-----|------|
| Qwen3-4B-Instruct | 98.77% | 24.69% | -74.08% |
| Qwen3-Next-80B-A3B | ~100% | 80.78% | ~19% |
| RL-MemoryAgent-14B | 98.42% | 92.66% | -5.76% |
| **MSA** | 98.77% | **94.84%** | **-3.93%** |

### 16K → 100M Token 扩展

- **MSA**：衰减 < 9%
- 其他模型在 1M 后急剧下降

---

## 消融实验

| 移除的组件 | 性能下降 | 最受影响的数据集 |
|-----------|---------|-----------------|
| Memory Interleave | -5.3% | HotpotQA (-19.2%) |
| 连续预训练 | -31.3% | HotpotQA (-43.1%) |
| 原始文档文本注入 | -37.1% | DuReader (-46.2%) |

**结论**：每个组件都至关重要，原始文本注入影响最大（对阅读理解任务）。

---

## 推理引擎：Memory Parallel

### 100M Token 的存储挑战

100M token 的 KV cache 理论需要 ~169GB（chunk=64, 8 heads, dim=128, 18 layers, BF16），超过 2×A800 的 160GB 总容量。

### 分层存储策略

| 存储位置 | 内容 | 容量 |
|---------|------|------|
| GPU VRAM | K̄ᴿ (路由键) | ~56GB |
| CPU DRAM | K̄, V̄ (内容 KV) | 主体 |

### 工作流程
1. GPU -resident 路由键用于低延迟 Top-k 选择
2. 选中后，CPU DRAM 中的内容 KV 异步加载到 GPU
3. 两者解耦，突破 VRAM 限制

---

## 与 OpenClaw 三级记忆的关联

| MSA 组件 | OpenClaw 三级记忆 | 层级对应 |
|---------|------------------|---------|
| Global Memory Encoding | Cold 层：离线建索引 | 🟣 Cold |
| Chunk-pooled K̄/V̄ | Warm 层：每日笔记/摘要 | 🟢 Warm |
| Top-k Selection | 手工向量检索/规则路由 | 🟢 Warm |
| Sparse Generation | Hot 层：当前对话上下文 | 🔵 Hot |
| Memory Interleave | 多轮对话/复杂工作流 | — |

### 本质区别

| 维度 | MSA | OpenClaw 三级记忆 |
|------|-----|-------------------|
| **实现层面** | 模型内部（注意力层） | 系统外部（文件/Context） |
| **记忆形式** | KV 潜状态 | 文本文件 |
| **容量规模** | 100M token | 受限于 Context Window |
| **路由机制** | 可学习（端到端） | 手工规则/向量检索 |
| **保真度** | 高（模型原生表示） | 中（需解析文本） |
| **多跳推理** | Memory Interleave（原生） | 手工工作流设计 |

### 互补关系

MSA 和三级记忆解决不同层次的问题：
- **MSA**：解决 LLM 模型的记忆容量限制
- **三级记忆**：解决 Agent 系统的上下文管理问题

可以结合使用：三级记忆负责文件层面的记忆管理，MSA 负责模型内部的长程记忆保持。

---

## 适用场景

✅ **多跳推理**（跨法规/合同/论文的证据链）  
✅ **长时程 Agent 记忆**（跨会话研究助手）  
✅ **超大但变化缓慢的知识库**  
✅ **长时程 Agent 工作流**（编码/研究 Agent）  
✅ **Digital Twins**（持久角色扮演）  
✅ **超长文本理解**（大语料库摘要）

## 不适用场景

❌ **动态数据**（知识库持续变化）  
❌ **需要审计追溯的场景**（法律/金融/医疗）  
❌ **多租户权限控制环境**  
❌ **简单任务**（小语料、低更新频率）  
❌ **资源受限环境**（需要高端 GPU）

---

## 关键引用

```bibtex
@misc{chen2026msamemorysparseattention,
  title={MSA: Memory Sparse Attention for Efficient End-to-End Memory Model Scaling to 100M Tokens},
  author={Yu Chen et al.},
  year={2026},
  eprint={2603.23516},
  archivePrefix={arXiv},
  primaryClass={cs.CL},
  url={https://arxiv.org/abs/2603.23516}
}
```

## 相关链接

- [arXiv 论文](https://arxiv.org/abs/2603.23516)
- [GitHub 代码](https://github.com/EverMind-AI/MSA)
- [HuggingFace 模型](https://huggingface.co/EverMind-AI/MSA-4B)
- [Benchmark 数据集](https://huggingface.co/datasets/EverMind-AI/MSA-RAG-BENCHMARKS)

---

## 🔙 返回

- [[index|Vault 首页]]
- [[2026-04-09|今日对话]]
