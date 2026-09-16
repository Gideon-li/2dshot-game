# V132 · 情志疏导 / emotion counsel 互动短音（tea）

依据：`DEV-TASKS-V132` / `EMOTION-COUNSEL-V132`；**只补一声 one-shot**（茶盏轻放），不做整曲 BGM / 大主题。  
锁：不按病人切整首 BGM；切诊 duck；雨/薄床/既有 SFX（含 `ui-paper`、`bowl`、`herb-drop`、`chime`）**不动**；**不新作 M 轨**。
> **勿挂 `tea-soft`**：其他要素占位已撤。挂接只认 `tea.ogg` / `play_one("tea")`。

> **翻纸不新作文件**：对话翻纸 / 疏导文案页 → 复用既有 `ui-paper.ogg`。**勿新作 page-flip**；勿改既有 `page-flip.ogg`（若有）。

> **异于 `bowl`**：`bowl` = 膳碗/瓷木碗轻放（食疗）；本轮 `tea` = 茶盏轻置木案（情志疏导）。二者语义分开，勿混挂。异于干药 `herb-drop`。

## 新文件

| 文件 | 时长约 | 听感 |
| --- | --- | --- |
| `tea.ogg` | 0.3–0.6s（本文件 ~0.48s） | 软置茶盏/瓷杯于木案 + 可选极轻液面 hush；室内静谧；**非**金属磕碰喜剧、**非**膳碗 `bowl`、**非**干药 `herb-drop` |

许可：**杏林墨问 original**（本目录合成）。Ogg Vorbis 44.1 kHz stereo。峰值约 −12～−6 dBTP。

## 挂接提示（开发负责人）

总线与场景仍由开发挂；本轮只补资源。建议与现有 `AudioHub.play_one` 一致：

| 时机 | 调用 | 备注 |
| --- | --- | --- |
| 茶盏/疏导卡轻放案上（情志） | `play_one("tea")` | **新文件**；茶盏语义 |
| 对话翻纸 / 疏导文案页 | `play_one("ui-paper")` | **复用**既有；本轮不新作翻页 |
| Ambient / Music | 雨 / 薄床 / duck | **不变**；无新 M-tracks；无情志大主题 |
| 雨 / 床 / 既有互动 | `rain-clinic` / `clinic-bed` / drawer·herb·bowl·… | **不动**（含 rain/bed/duck） |

## 不做 / 不动

- 无 per-patient BGM；无新 M-tracks；无情志主题曲 / 大主题
- `rain-clinic.ogg` / `clinic-bed.ogg` / `ui-paper.ogg` / `bowl.ogg` / `herb-drop.ogg` / `chime.ogg` / 既有 duck **不变**
- 不新作 page-flip / 翻纸文件；不改 forage / process / acu / food / codex 等既有 SFX
- 不要金属 clang、喜剧碰杯、膳碗重放、干药入盏、户外茶摊喧闹
