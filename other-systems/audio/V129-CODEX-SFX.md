# V129 · 夜读医典 / 阁楼 loft codex 互动短音

依据：`DEV-TASKS-V129` / `CODEX-NIGHT-V129`；**只补一声 one-shot**（残烛灯花），不做整曲 BGM / 大主题。  
锁：不按病人切整首 BGM；切诊 duck；雨/薄床/既有 SFX（含 `ui-paper`、`ui-ink`、`moxa`、`chime`）**不动**；**不新作 M 轨**（M02 夜床仍后置）。

> **翻页不新作文件**：复用既有 `ui-paper.ogg`（宣纸/翻页）。**勿用 / 勿提交** `page-flip.ogg`。领悟确认可复用 `ui-ink` 或 `stamp-ok`。

## 新文件

| 文件 | 时长约 | 听感 |
| --- | --- | --- |
| `candle.ogg` | 0.35–0.75s（本文件 ~0.58s） | 残烛/灯花 one-shot：静蜡火微晃 + 极轻灯花软爆一记；室内阁楼；**非**篝火噼啪、**非**艾绒 `moxa`、**非**警报 |

许可：**杏林墨问 original**（本目录合成）。Ogg Vorbis 44.1 kHz stereo。峰值约 −12～−6 dBTP。

## 挂接提示（开发负责人）

总线与场景仍由开发挂；本轮只补资源。建议与现有 `AudioHub.play_one` 一致：

| 时机 | 调用 | 备注 |
| --- | --- | --- |
| 翻页 / 医典残页切换 | `play_one("ui-paper")` | **复用**既有 `ui-paper.ogg`；本轮不新作翻页文件 |
| 进阁楼 / 残烛氛围刺 / 页间 ambience sting | `play_one("candle")` | 新文件；进 loft 或翻页氛围点缀 |
| 领悟确认（「识」印） | `play_one("ui-ink")` 或 `play_one("stamp-ok")` | 印泥轻捺 / 朱砂落印；本轮不新作 |
| Ambient / Music | 雨 / 薄床 / duck | **不变**；无新 M-tracks；**M02 夜床仍后置** |
| 雨 / 床 / 既有互动 | `rain-clinic` / `clinic-bed` / drawer·herb·… | **不动**（含 rain/bed/duck） |

## 不做 / 不动

- 无 per-patient BGM；无新 M-tracks；无夜读主题曲；M02 night bed **仍 postponed**
- `rain-clinic.ogg` / `clinic-bed.ogg` / `ui-paper.ogg` / `ui-ink.ogg` / `chime.ogg` / `moxa.ogg` / 既有 duck **不变**
- 不新作 page-turn / `page-flip` 文件；不改 forage / process / acu / open-day 等既有 SFX
- 不要篝火 crackle、艾绒燃、警报、大殿尾音、户外风暴
