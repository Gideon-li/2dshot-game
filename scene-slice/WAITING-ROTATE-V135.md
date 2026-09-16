# V135 · 候诊轮换确认（无改坐标）

日期：2026-09-16  
角色：场景设计（确认）  
依据：`DEV-TASKS-V135.md`、`logic/QINGSHI-EXPAND2-V135.md`、`scene-slice/WAITING-ROTATE-V134.md`  
前置：V134 轮换策略已验收。

**结论：场景侧无新坐标、无 WAIT_E、不新开地图。** V134 文档与图仍为座位真相源。

参考：`scene-slice/waiting/WAITING_ROTATE_V134.png`（本档不另出新图）。

---

## 0. 一句话

池扩到约 **10** 人；大厅同屏仍 **A–D（`waiting.max_seats = 4`）** 轮换填席；多出的人留 offscreen 池 / 日班表。

---

## 1. 座位（与 V133/V134 **完全不变**）

| 槽 | 脚底 | 热区 rect | 状态 |
| --- | --- | --- | --- |
| A | (405, 290) | (360, 220, 90, 70) | UNCHANGED |
| B | (545, 290) | (500, 220, 90, 70) | UNCHANGED |
| C | (300, 340) | (255, 270, 90, 70) | UNCHANGED |
| D | (685, 290) | (640, 220, 90, 70) | UNCHANGED |
| 坐诊 | (1040, 590) | — | UNCHANGED |

轮换 / 补位 / 换贴图规则：照抄 `WAITING-ROTATE-V134.md` §3。可选「还有 N 人候诊」标签 ~(200, 180) 仍纯文案。

---

## 2. 池约 10 ids（逻辑已锁）

旧 7（V134）：`char_porter` / `char_clerk` / `char_copyist` / `char_xiuniang` / `char_zoufan` / `char_yanhou` / `char_yaoqin`

本档 +3：

| 案 id | 角色 id | 立绘建议 |
| --- | --- | --- |
| `yangxu_weihan` | `char_danfu` | `ui/characters/han_danfu.png` |
| `xueyu_qing` | `char_bashi` | `ui/characters/ma_bashi.png` |
| `shushi` | `char_jiaoli` | `ui/characters/xia_jiaoli.png` |

冒烟：`qingshi_expand2_ok`。证印本档再 +3（共 6 枚小印）——场景不摆十二印墙。

---

## 3. 明确不做

- WAIT_E / 第 5 凳 / 改 A–D 或坐诊坐标  
- 新大地图、改六机与处治热区  
- 十二印墙空间

---

## 4. 交接

### 场景
- 本包 = **确认**；坐标与轮换机制零改。详情见 V134。

### 角色开发
- `wait_slots[4]` 不变；池消费扩到 10；swap id 进 Patient0–3。
