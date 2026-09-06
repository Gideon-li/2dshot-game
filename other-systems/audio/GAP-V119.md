# GAP-V119 · 05 音乐与音效志 vs 切片音频

依据：`05 音乐与音效志 v1.1` + `DEV-TASKS-V119.md`  
范围：切片只补交互；M00–M21 全作曲目后置；12 脉层只保留切片三脉。

## 志事件 → 文件

| 志事件 | 文件 | 状态 |
| --- | --- | --- |
| UI 印泥轻捺 | ui-ink.ogg | 本轮补 |
| 翻页/问诊纸 | ui-paper.ogg | 已有 |
| 开抽屉 | drawer.ogg | 已有 |
| 倒药入盏 | herb-drop.ogg | 已有 |
| 混药错误闷响 | herb-wrong.ogg | 本轮补 |
| 毫针刺入 | needle.ogg | 已有 |
| 落印成功 | stamp-ok.ogg | 本轮补 |
| 墨洇失当 | ink-bleed.ogg | 本轮补 |
| 特殊病人风铃 | chime.ogg | 本轮补 |
| 捣药/艾灸/地图/铜钱/赛事 | — | 全作后置 |
| M01 杏林昼薄床 | clinic-bed.ogg | 已有 |
| 雨环境 | rain-clinic.ogg | 已有 |
| M04 三指（切片三脉） | pulse-fu/xian/xi | 已有 |
| 结算五档 | settle-0…4 | 已有 |
| M00/M02/五方/人物主题等 | — | 全作后置 |

## 挂接提示（开发负责人）

- 通用 UI / 点病人：`play_one("ui-ink")`（问诊翻页可继续 `ui-paper`）
- 病人进门提示：`play_one("chime")`
- 反畏 / 混药软失败：`play_one("herb-wrong")`
- 结算成功可加一记 `stamp-ok`；失败可加 `ink-bleed`（或继续只用 settle-0…4）
- 切诊 duck、不按病人切 BGM：保持现状
- 雨/薄床文件未改
