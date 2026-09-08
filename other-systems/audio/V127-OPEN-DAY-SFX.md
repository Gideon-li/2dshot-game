# V127 · 次日开馆互动短音（next-day clinic open）

依据：复诊日时钟 / `NEXT-DAY-LAYOUT` / `DEV-TASKS-V127`；**只补一声 one-shot**，不做整曲 BGM / 大主题。  
锁：不按病人切整首 BGM；切诊 duck；雨/薄床/既有 SFX（含 `chime`）**不动**；**不新作 M 轨**。

## 新文件

| 文件 | 时长约 | 听感 |
| --- | --- | --- |
| `open-day.ogg` | 0.5–1.2s（本文件 ~0.85s） | 软木门闩（开馆门闩）：轻触木 thrud + 短摩擦滑闩 + 落扣一记；可选极远、稀疏的晨钟残响一缕。室内静；**非**庙堂大编制、**非**警报、**非**响锣 |

许可：**杏林墨问 original**（本目录合成）。Ogg Vorbis 44.1 kHz stereo。峰值约 −12～−6 dBTP。

## 挂接提示（开发负责人）

总线与场景仍由开发挂；本轮只补资源。建议与现有 `AudioHub.play_one` 一致：

| 时机 | 调用 | 备注 |
| --- | --- | --- |
| 次日开馆按钮 / `Area_次日开馆`（hotspot `"next_day"`） | `play_one("open-day")` | 诊室空闲点「次日开馆 / 过一日」时播一声 |
| 特殊病人进门 | `play_one("chime")` 或 `play_chime()` | **仍用**既有 `chime.ogg`；本轮不改 |
| Ambient / Music | 雨 / 薄床 / duck | **不变**；无新 M-tracks |
| 床 / 雨 / 既有互动 | `clinic-bed` / `rain-clinic` / drawer·herb·needle·… | **不动** |

## 不做 / 不动

- 无 per-patient BGM；无新 M-tracks；无开馆主题曲
- `rain-clinic.ogg` / `clinic-bed.ogg` / `chime.ogg` / 既有 duck **不变**
- 不改 drawer、pulse-*、settle-*、forage-*、deqi、moxa 等既有 SFX
- 不要庙堂锣鼓、警报、响亮铜锣、户外大钟齐奏
