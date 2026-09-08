# V128 · 炮制互动短音（wash / fry / sun-dry）

依据：炮制工位切片（洗 / 炒 / 晒）；**只补三声 one-shot**，不做整曲 BGM / 大主题。  
锁：不按病人切整首 BGM；切诊 duck；雨/薄床/既有 SFX（含 `chime`、`forage-*`、`moxa`、`needle`）**不动**；**不新作 M 轨**。

> **V124 占位已由本切片正式音取代**：洗不再复用 `ui-ink` / `forage-pull`；炒不再复用 `ui-ink` / `herb-drop`。见下表。

## 新文件

| 文件 | 时长约 | 听感 |
| --- | --- | --- |
| `wash.ogg` | 0.3–0.6s（本文件 ~0.45s） | 盆中短涮/轻水声：软、室内；**非**卡通泼溅 |
| `fry.ogg` | 0.4–0.8s（本文件 ~0.58s） | 干砂/药干炒沙沙（锅铲轻搅）；**无**油爆、**无**恐怖尖叫滋滋 |
| `sun-dry.ogg` | 0.45–0.9s（本文件 ~0.72s） | 晒药：布面/竹席轻窸窣 + 极轻空气感风铃残响；院内静；**非**病人进门响铃、**非**户外风暴 |

许可：**杏林墨问 original**（本目录合成）。Ogg Vorbis 44.1 kHz stereo。峰值约 −12～−6 dBTP。

## 挂接提示（开发负责人）

总线与场景仍由开发挂；本轮只补资源。建议与现有 `AudioHub.play_one` 一致：

| 时机 | 调用 | 备注 |
| --- | --- | --- |
| 洗水命中（wash hit） | `play_one("wash")` | 取代 V124 占位 `ui-ink` |
| 炒药 tick / 确认 | `play_one("fry")` | 取代 V124 占位；干沙沙，勿油爆 |
| 翻晒 / 晒干进度动作 | `play_one("sun-dry")` | 布席轻动；勿用病人 `chime` |
| 出锅 / 炮制完成 | 仍可 `play_one("stamp-ok")` | 与既有完成落印一致 |
| Ambient / Music | 雨 / 薄床 / duck | **不变**；无新 M-tracks |

## 不做 / 不动

- 无 per-patient BGM；无新 M-tracks；无炮制主题曲
- `rain-clinic.ogg` / `clinic-bed.ogg` / `chime.ogg` / `forage-*` / `moxa` / `needle` / 既有 duck **不变**
- 不要写实油爆、惨叫、户外大风、响亮铜铃盖过病人进门铃
