# V121 · 采药互动短音（foraging）

依据：采药交互切片；**只补两声 one-shot**，不做整曲 BGM。  
锁：不按病人切整首 BGM；切诊 duck；雨/薄床/既有 SFX **不动**；**不新作 M 轨**。

## 新文件

| 文件 | 时长约 | 听感 |
| --- | --- | --- |
| `forage-pull.ogg` | 0.25–0.55s | 软茎折 + 轻土砂；有机，非卡通猛拔、非金属 |
| `forage-bag.ogg` | 0.25–0.5s | 布袋轻窸 + 植株轻落；比 `herb-drop`（瓷盏）更轻更闷 |

许可：**杏林墨问 original**（本目录合成）。Ogg Vorbis 44.1 kHz stereo。

## 挂接提示（开发负责人）

总线与场景仍由开发挂；本轮只补资源。建议与现有 `AudioHub.play_one` 一致：

| 时机 | 调用 | 备注 |
| --- | --- | --- |
| 辨认成功（可选） | `play_one("ui-ink")` | 复用印泥轻捺；**不新开**辨认专用音 |
| 拔起植株 | `play_one("forage-pull")` | 从土/草拔出时 |
| 入背包 / 布袋 | `play_one("forage-bag")` | 放进 inventory/pouch |
| 入配方盏 / 瓷盘 | 仍用 `play_one("herb-drop")` | **不要**改用 forage-bag |

## 不做 / 不动

- 无 per-patient BGM；无新 M-tracks
- `rain-clinic.ogg` / `clinic-bed.ogg` / 既有 duck **不变**
- 不改 drawer、needle、pulse-*、settle-*、chime 等既有 SFX
