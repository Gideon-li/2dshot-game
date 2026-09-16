# V134 · 候诊同屏策略（轮换，不扩位）

日期：2026-09-16  
角色：场景设计（候诊同屏）  
依据：`DEV-TASKS-V134.md`、`logic/QINGSHI-EXPAND-V134.md`、`scene-slice/WAITING-SLOT4-V133.md`  
前置：V133 已锁四席 A–D；本包**只定轮换规则**，不改座位坐标、不新开地图。

参考示意：`scene-slice/waiting/WAITING_ROTATE_V134.png`（镜像 `ui/waiting/WAITING_ROTATE_V134.png`）。

---

## 0. 一句话策略

**轮换，不扩位**：候诊池扩到 **7** 人，但大厅同屏候诊席仍 strictly **A–D（最多 4）**；多出的人留在 offscreen 池 / 日班表 UI，绝不加第 5 凳、不挤爆、不新开大地图。

---

## 1. 锁死座位（与 V133 **完全不变**）

| 槽 | 锚点名 | 脚底 position | 热区 rect (x, y, w, h) | 圆热区 | 状态 |
| --- | --- | --- | --- | --- | --- |
| A | WAIT_A / Patient0 home | **(405, 290)** | (360, 220, 90, 70) | r=90 @ foot | **UNCHANGED** |
| B | WAIT_B / Patient1 home | **(545, 290)** | (500, 220, 90, 70) | r=90 @ foot | **UNCHANGED** |
| C | WAIT_C / Patient2 home | **(300, 340)** | (255, 270, 90, 70) | r=90 @ foot | **UNCHANGED** |
| D | WAIT_D / Patient3 home | **(685, 290)** | (640, 220, 90, 70) | r=90 @ foot | **UNCHANGED** |
| — | 病人椅 / 坐诊 | **(1040, 590)** | — | — | **UNCHANGED**（共用） |

- `wait_slots[4]` = 固定世界 home；**永不**绑定第 5 个 `Node2D` home 进大厅。
- 诊室六相机 / 治疗站 / BED / 食疗 / 情志 / 阁楼入口：**本包零改动**。

---

## 2. 候诊池 7 ids（逻辑已锁）

| # | 案 id | 角色 id | 备注 |
| --- | --- | --- | --- |
| 1 | （既有）风寒等 | `char_porter` | 旧四人 · 阿福 |
| 2 | （既有） | `char_clerk` | 旧四人 · 清荷 |
| 3 | （既有） | `char_copyist` | 旧四人 · 抄书婆 |
| 4 | `xuexu_ganyu` | `char_xiuniang` | 旧四人 · 绣娘（V133） |
| 5 | `fengre_biao` | `char_zoufan` | **V134 新** · 走贩少年 |
| 6 | `shiji` | `char_yanhou` | **V134 新** · 宴后熟人 |
| 7 | `pixu_shikun` | `char_yaoqin` | **V134 新** · 药农亲友 |

冒烟：`qingshi_expand_ok`（三新案各至少一路合法 settle）+ `SMOKE PASS`。

权重 / permit：见 `logic/QINGSHI-EXPAND-V134.md`（有 `town_permit` 时三新案权重升高；无 permit 也可偶遇 `shiji` 教学）。场景不改权重数，只消费「谁进 A–D」。

---

## 3. 轮换 / 填充规则（给角色开发）

1. **固定槽位**：大厅仅 `Patient0`…`Patient3` 四节点，home 永远钉在上表 A–D。  
2. **每日早晨（或 settle 后）**：从加权池取 **≤4** 人填入空槽；池内剩余 **不**生成大厅 Sprite。  
3. **叫号上坐诊椅**：该槽位病人 tween → `(1040, 590)` 后，该槽可：  
   - 从 offscreen 池 **补一人**（换贴图 / 换 id 到该 `PatientN`），或  
   - **留空**（visible=false），直到下次早晨 refill。  
4. **轮换表现（本切片）**：在 `Patient0–3` 上 **swap texture/id**；可不做从地图外 tween 入场（fade / pop 即可）。  
5. **日班表 / roster UI**（若已有）：可列满 7 人「今日可接」；场景只保证大厅同屏 ≤4 可点 Sprite。  
6. **禁止**：为第 5 人新建 `WAIT_E` / `Patient4` home；禁止把 pool 人叠在走道或南门当可点 NPC。

伪代码意向（非强制 API）：

```
wait_slots = [A, B, C, D]  # 世界 home 锁死
pool = weighted_draw(7_cases)  # 逻辑侧
visible = pool[:4]
for i, char_id in enumerate(visible):
    Patient[i].home = wait_slots[i]
    Patient[i].bind(char_id)  # 换贴图
# pool[4:] 仅存在于 offscreen / roster，无 Node2D home
```

---

## 4. 可选 · 候诊人数标签（非第 5 人）

| 项 | 建议 |
| --- | --- |
| 文案 | `还有 N 人候诊`（N = max(0, pool_remaining)） |
| 形态 | **Label only** — 不是可点人 Sprite，无 Area2D |
| 位置 | 南门附近、不挡 HUD/门热区，建议约 **(200, 180)**（可微调 ±20） |
| 显隐 | N=0 时隐藏或显示「候诊已满席/暂无排队」按产品择一 |

证印 UI 归美工/逻辑：场景仅注明若已有阁楼或结算闪印位可复用；**不设计十二印墙**。

---

## 5. 明确不做

- 第 5 候诊凳 / `WAIT_E` / `Patient4` 大厅 home  
- 新大地图、overworld 排队长廊、出镇旅行空间  
- 移动 A–D 或坐诊椅 (1040, 590)  
- 改诊室六相机、治疗站、穴位 UV  
- 十二证印墙美术排版（本档只亮 3 枚小印，逻辑/UI 负责）  
- 陈半仙 / 萨米尔 / 小儿案场景位

---

## 6. 交接

### 场景（本包）
- 策略：**轮换不扩位**；A–D 坐标表重申不变；7 人池 → 同屏 4；可选人数 Label @ ~(200,180)；参考图。

### 角色开发
- `wait_slots[4]` 固定；晨/settle 填 ≤4；叫号后 refill 或留空；`Patient0–3` 换 id/贴图；勿绑第 5 home；冒烟 `qingshi_expand_ok`。

### 美工
- 三新立绘进既有四节点换贴；人数 Label 字号跟 HUD；证印小图标归证印 UI，不扩大厅座位。

### 逻辑 / 剧本
- 案向量与权重已由 `QINGSHI-EXPAND-V134.md` 锁；本包不改向量。
