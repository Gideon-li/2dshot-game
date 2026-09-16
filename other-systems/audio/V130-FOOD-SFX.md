# V130 · 食疗 / 膳方互动短音（bowl）

依据：食疗卡入碗切片；**只补一声 one-shot**（摆碗/入盏），不做整曲 BGM / 大主题。  
锁：不按病人切整首 BGM；切诊 duck；雨/薄床/既有 SFX（含 `herb-drop`、`chime`、炮制三声）**不动**；**不新作 M 轨**。
> **勿挂 `bowl-clink`**：其他要素曾交过同名占位；已撤。挂接只认 `bowl.ogg` / `play_one("bowl")`。

> **配方托盘倒药仍用 `herb-drop`**：`herb-drop` = 干药入配方盏/托盘；本轮 `bowl` = 膳碗/瓷木碗轻放（可带极轻箸点）。二者语义分开，勿混挂。

## 新文件

| 文件 | 时长约 | 听感 |
| --- | --- | --- |
| `bowl.ogg` | 0.3–0.65s（本文件 ~0.52s） | 软置瓷/木碗于案 + 可选极轻箸点；室内家常；**非**金属磕碰、**非**厨房喜剧、**非**干药入盏 `herb-drop` |

许可：**杏林墨问 original**（本目录合成）。Ogg Vorbis 44.1 kHz stereo。峰值约 −12～−6 dBTP。

## 挂接提示（开发负责人）

总线与场景仍由开发挂；本轮只补资源。建议与现有 `AudioHub.play_one` 一致：

| 时机 | 调用 | 备注 |
| --- | --- | --- |
| 食疗卡入碗 / 摆碗 / 入盏（膳） | `play_one("bowl")` | **新文件**；餐碗语义 |
| 配方托盘倒药 / 入配方盏 | `play_one("herb-drop")` | **既有**；干药入盏，勿改挂为 bowl |
| Ambient / Music | 雨 / 薄床 / duck | **不变**；无新 M-tracks；无食疗大主题 |
| 雨 / 床 / 既有互动 | `rain-clinic` / `clinic-bed` / drawer·herb·… | **不动**（含 rain/bed/duck） |

## 不做 / 不动

- 无 per-patient BGM；无新 M-tracks；无食疗主题曲 / 大主题
- `rain-clinic.ogg` / `clinic-bed.ogg` / `herb-drop.ogg` / 既有 duck **不变**
- 不要金属 clang、油锅爆响、卡通厨房喜剧、写实摔碗
