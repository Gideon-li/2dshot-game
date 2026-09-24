# V136 · 候诊轮换确认（无改坐标）

日期：2026-09-18  
角色：场景设计（确认）  
依据：`DEV-TASKS-V136.md`、`logic/QINGSHI-EXPAND3-V136.md`、`WAITING-ROTATE-V134.md` / `V135.md`  
前置：V134/V135 轮换已验收。

**结论：场景侧无新坐标、无 WAIT_E、不新开地图。** 座位真相源仍为 V133/V134。

参考图沿用：`scene-slice/waiting/WAITING_ROTATE_V134.png`。

---

## 0. 一句话

池扩约 **13** 人；同屏仍 **A–D**（`waiting.max_seats = 4`）轮换；多出的人 offscreen / 日班表。

---

## 1. 座位（与 V133–V135 **完全不变**）

| 槽 | 脚底 | 热区 rect | 状态 |
| --- | --- | --- | --- |
| A | (405, 290) | (360, 220, 90, 70) | UNCHANGED |
| B | (545, 290) | (500, 220, 90, 70) | UNCHANGED |
| C | (300, 340) | (255, 270, 90, 70) | UNCHANGED |
| D | (685, 290) | (640, 220, 90, 70) | UNCHANGED |
| 坐诊 | (1040, 590) | — | UNCHANGED |

轮换 / 补位 / 换贴图：照 `WAITING-ROTATE-V134.md` §3。

---

## 2. 池约 13 ids

旧 10（至 V135）保留。本档 +3：

| 案 id | 角色 id | 立绘建议 |
| --- | --- | --- |
| `yinxu_zaoke` | `char_tanfu` | `ui/characters/qiu_tanfu.png`（≠周婆婆 `yinxu_neire`） |
| `shire_xiazhu` | `char_tianhan` | `ui/characters/he_tianhan.png`（文案克制） |
| `waishang_zhongtong` | `char_mujiang` | `ui/characters/lu_mujiang.png`（无血腥） |

冒烟：`qingshi_expand3_ok`。证印展示归 UI（九宫/列表）；场景不摆十二印墙、不设小儿格。

---

## 3. 明确不做

WAIT_E、改 A–D/坐诊、新大地图、改六机与处治热区、血腥外伤空间。

---

## 4. 交接

场景 = **确认**；角色开发继续 `wait_slots[4]` + 池扩到 13。
