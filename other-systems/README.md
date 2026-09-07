# 杏林墨问 · 其他要素（垂直切片第一份）

给开发组直接用。范围锁死：中英日键值、启动免责、本地存档、基础环境音、Steamworks 预研。没有排行榜、没有经营。古琴薄床与交互音改由「游戏音乐」补，见 `audio/MUSIC.md`。

| 目录 | 用什么 |
| --- | --- |
| `i18n/ui.csv` | Godot Translation |
| `disclaimer/BOOT.md` | 启动阻塞声明 |
| `save/schema.json` + `SPEC.md` | 本地 3 槽 JSON |
| `audio/rain-clinic.ogg` | 医馆雨循环，CC0 |
| `steamworks/PRESEARCH.md` | 成就能做、排行榜能做、切片都不接代码 |

接到 Godot 工程后：CSV 进 Localization，雨声挂医馆场景，免责做开机 Scene，存档按 `user://saves/`。

| `LLM-LOCAL.md` | V122 本地 llama-server / 模型路径 / 冒烟 |
| `i18n/LLM-SETTINGS-KEYS.md` | 问诊 provider 设置键 |

