# V125 · 针灸入门互动短音（acupuncture intro）

依据：针灸入门切片；**只补两声 one-shot**，不做整曲 BGM / 大主题。  
锁：不按病人切整首 BGM；切诊 duck；雨/薄床/既有 SFX（含 `needle`）**不动**；**不新作 M 轨**。

## 新文件

| 文件 | 时长约 | 听感 |
| --- | --- | --- |
| `deqi.ogg` | 0.35–0.8s（本文件 ~0.58s） | 得气成功：软暖 bloom / 墨晕共鸣（指下静响）；**非**金属叮、警报、心跳闷鼓 |
| `moxa.ogg` | 0.4–0.9s（本文件 ~0.68s） | 艾灸点燃/壮确认：绒絮轻捉 + 一点松香暖意（志：绒燃极轻，成功再加一点松香）；室内静；**非**篝火噼啪 |

许可：**杏林墨问 original**（本目录合成）。Ogg Vorbis 44.1 kHz stereo。峰值约 −12～−6 dBTP。

## 挂接提示（开发负责人）

总线与场景仍由开发挂；本轮只补资源。建议与现有 `AudioHub.play_one` 一致：

| 时机 | 调用 | 备注 |
| --- | --- | --- |
| 毫针刺入 | `play_one("needle")` | **仍用**既有 `needle.ogg`；本轮不改 |
| 得气成功 | `play_one("deqi")` | 得气确认一记；接在刺入之后或叠短距 |
| 艾灸点燃 / 壮确认 | `play_one("moxa")` | 绒燃极轻确认 |
| 未中经 / 重试 | 可选轻 `play_one("ui-ink")` 或 **静默** | **不要**错误哔声 / 警报 |
| Ambient / Music | 雨 / 薄床 / duck | **不变**；无新 M-tracks |

## 不做 / 不动

- 无 per-patient BGM；无新 M-tracks；无针灸主题曲
- `rain-clinic.ogg` / `clinic-bed.ogg` / `needle.ogg` / 既有 duck **不变**
- 不改 drawer、pulse-*、settle-*、chime、forage-* 等既有 SFX
- 不要金属 ding、警报、心跳 thump、篝火 crackle
