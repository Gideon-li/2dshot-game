# 问诊本地模型（V122）

成品（Steam）默认 **本地轻量模型**，开发机可用远程 OpenAI 兼容接口（Helix / `secrets.env`）。任意失败 ≤2s 回退症状模板，不卡主线程。玩家包 **不会默默打远程**。

## 推荐模型

| 项 | 值 |
| --- | --- |
| 名称 | **Qwen3-4B Instruct · Q4_K_M**（或同级 ≤4B） |
| 体积 | ≈ **2.5GB** |
| 许可 | 遵循 Alibaba Qwen 模型许可证（商用前自行核对） |
| 放置路径 | `user://models/qwen3-4b-instruct-q4_k_m.gguf`（Godot 用户目录下的 `models/`） |
| 获取 | **外链下载** GGUF，勿 commit 进 git / 勿打进默认安装包 |

下载后放到上述路径。缺失时 UI 用 `LLM_MISSING_*` 提示；可继续用离线模板玩。

## 本地 runtime（锁定）

优先：**llama.cpp `llama-server`**，OpenAI 兼容 HTTP。

```bash
# 例：模型已放到 Godot user://models/ 对应的真实目录
llama-server \
  -m /path/to/qwen3-4b-instruct-q4_k_m.gguf \
  --port 8080 \
  --host 127.0.0.1
# 聊天接口：http://127.0.0.1:8080/v1/chat/completions
```

次选：Ollama（同样走 OpenAI 兼容 base URL，改 `user://llm.cfg` 的 `local_base_url`）。

## 配置 `user://llm.cfg`

```ini
[llm]
provider=auto
local_base_url=http://127.0.0.1:8080/v1
local_model=qwen3-4b-instruct-q4_k_m
# 仅开发机：允许 provider=remote 读 secrets.env
# allow_remote=true
```

| provider | 行为 |
| --- | --- |
| `auto`（默认） | 优先 local；失败/超时 → offline。**不**默默 remote |
| `local` | 只打本机 llama-server |
| `remote` | 开发用 Helix；需 `allow_remote=true` 或 `MOWEN_ALLOW_REMOTE=1` |
| `offline` | 直接症状模板 |

环境变量覆盖：`MOWEN_LLM_PROVIDER`、`MOWEN_LOCAL_BASE_URL`、`MOWEN_LOCAL_MODEL`。

Steam / `player_build` 导出默认 `auto`/`local`，排除 `secrets.env`。

## 冒烟

```bash
# 主冒烟：不依赖外网，应见 OFFLINE_FALLBACK 且 SMOKE PASS
./run_godot.sh --headless res://scenes/smoke.tscn

# 问诊 provider 冒烟（默认会走 local→超时→OFFLINE_FALLBACK，或 remote）
./run_godot.sh --headless res://scenes/smoke_ask_api.tscn

# LOCAL_OK 演示（假 server，无需真模型）
MOWEN_FAKE_PORT=18080 python3 scripts/fake_llama_server.py &
MOWEN_LLM_PROVIDER=local MOWEN_LOCAL_BASE_URL=http://127.0.0.1:18080/v1 ./run_godot.sh --headless res://scenes/smoke_ask_api.tscn
```

标签：`API_OK` / `LOCAL_OK` / `OFFLINE_FALLBACK`。

## 代码入口

`InquiryLLM.ask(question, character, case_data)`（`scripts/inquiry_llm.gd`）。  
`QwenClient` 为兼容别名。remote/local 共用 OpenAI chat schema。

i18n：`LLM_*` / `SETTINGS_LLM_*`（见 `other-systems/i18n/LLM-SETTINGS-KEYS.md`）。
