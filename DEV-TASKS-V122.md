# 《墨问岐黄》V122 — 问诊 LLM：开发走接口，成品走本地轻量模型

日期：2026-09-07  
下发：全局统筹 → 开发负责人 → 相关组  
依据：Haopeng 决定 — 最终版本用免费本地模型，避免玩家因网络卡顿/死机；开发机显卡不够时可用远程接口顶替。

## 产品锁死

| 阶段 | 后端 |
| --- | --- |
| **玩家成品（Steam）** | 本地轻量模型，默认 **Qwen3-4B Instruct · Q4_K_M（≈2.5GB）** 或同级（≤4B、可 CPU/核显跑） |
| **开发/联调** | 可继续用 OpenAI 兼容远程接口（现有 Helix / `secrets.env`） |
| **任何后端失败** | 现有本地症状模板回退（必须保留，且要快） |

禁止把远程 API 当成玩家默认路径。禁止把 key 打进安装包或仓库。

## 目标

把问诊调用收成 **可切换 Provider**：

1. `remote` — HTTP OpenAI-compatible（现在的 `qwen_client` / Helix）
2. `local` — 本机推理（推荐：llama.cpp server 或 Ollama，OpenAI 兼容 `localhost`；或 Godot 可维护的 sidecar）
3. `offline` — 模板回退

设置里（或 `user://llm.cfg`）可选：`provider=local|remote|auto`。  
`auto`：优先 local，模型缺失再提示下载/回退 offline，**不要默默打远程**（玩家机）。开发构建可编译开关允许 remote。

## 完成标准

1. 文档写清：推荐模型名、体积、许可、放置路径（如 `user://models/qwen3-4b-instruct-q4_k_m.gguf`）、首次启动如何获取（外链下载，不强制随包 2.5GB，除非 Haopeng 后来说要内置）。
2. 代码：`InquiryLLM`（或现有 client）只暴露 `ask(case, messages) -> reply`；remote/local 共用 OpenAI chat schema，便于本地 server 对齐。
3. 本地路径冒烟：在开发机起一个 localhost 兼容服务（可用假 server 或文档步骤）时，`provider=local` 能通；关掉服务时 ≤2s 进 offline，不卡死主线程。
4. `provider=remote` 仍读 `secrets.env`，仅开发用；Steam 导出预设默认 `local`/`auto`。
5. 冒烟脚本区分 `API_OK` / `LOCAL_OK` / `OFFLINE_FALLBACK`；主 smoke 不依赖外网。
6. 推 main；secrets 不进库。

## 分工

### 开发负责人
- 定 sidecar 方案（优先：官方 llama.cpp `llama-server` OpenAI 兼容；次选 Ollama）。
- 转发本任务；验收切换与超时；更新 README / STEAM 相关说明一句「对话可离线」。

### 游戏角色开发
- 重构 `qwen_client.gd` / `qwen_inquiry.gd` 为多 provider。
- 主线程不阻塞：超时、取消、排队。
- 玩家包默认不读远程 key。

### 游戏逻辑设计
- 病例卡 prompt 与 provider 无关；offline 模板覆盖率自检。

### 其他要素
- 设置页：模型状态（已安装/缺失）、provider 显示；免责不变。
- i18n：本地模型缺失提示（中英日）。

### 剧本
- 不改文案锚点；可补一句「问诊可在无网时使用本地回复」。

## 明确不做（本期）

- 不上 7B/14B 默认模型
- 不训练/微调
- 不删 Helix 开发通路
- 不把 2.5GB 模型强行 commit 进 git

## 回我

架构短说明（选了哪套 local runtime）+ commit + 一次 `LOCAL_OK` 或文档化的本地启动步骤。
