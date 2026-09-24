# 《墨问岐黄》V126 · 座位 / 对话位框（单人立绘）

日期：2026-09-08  
依据：`DEV-TASKS-V126.md`、`ui/characters/README.md`  
画风：明快 Q 版。立绘文件归美工；本包只锁**挂载框与脚底规则**。  
**不改大地图**；诊室六机 / 药圃 / 炮制院 / 体图 UV 不动。

立绘路径（运行时优先）：

| id | 文件 |
| --- | --- |
| `apprentice_jiang` | `ui/characters/jiang_wan.png` |
| `char_porter` | `ui/characters/zhao_afu.png` |
| `char_clerk` | `ui/characters/shen_qinghe.png` |
| `char_copyist` | `ui/characters/zhou_popo.png` |

缺图回退 `ui/apprentice.png` / `ui/patients-three.png`（角色开发）。禁止林晚。

参考示意：`scene-slice/portrait/PORTRAIT_LAYOUT.png`（副本 `ui/portrait/`）。

---

## 1. 立绘规格假设（与美工对齐）

- 透明底 PNG；高约 **640 px**（512～768 可，系列统一）。
- **脚底在图内底部中心**：画布底边 = 鞋底触地点，左右居中。头顶到顶边留 ≤8% 空，不要大块透明头上空间导致「浮空」。
- 肩宽约占画布宽 55～70%；阿福可略宽，清荷/江晚略窄，但**脚底规则相同**。

---

## 2. 诊室世界坐标（Node2D，脚底 = `position`）

Y-sort 原点在脚底。Sprite 用 `centered=false` 或 offset 把脚钉在 (0,0)：

推荐：`sprite.position = Vector2(-w/2, -h)`（脚在父节点原点），`scale` 使显示高约 **280～320 px**（与 SCENE-SLICE 角色身高一致）。

| 锚点 | 世界 position | 用途 |
| --- | --- | --- |
| 病人椅座位 | **(1040, 590)** | `_seat_patient` 已锁；坐诊脚底（V139 保持） |
| 候诊凳 A / B | **(400, 400)** / **(540, 400)** | 候诊；V139 微调离作业区 |
| 候诊旁位 C | **(280, 430)** | Patient2 home（V139） |
| 候诊凳 D | **(680, 410)** | Patient3 / WAIT_D（V139） |
| 江晚学徒锚点 | **(1035, 770)** | **PhysicianChair / 诊桌后**；V139 改；禁踩脉枕 |
| 病人椅家具 | (1040, 590) | `PatientChair`；立绘脚应落在椅面视觉触点略上 0～12 px 可微调 |

> **V139：** 上表 A–D / 江晚已按 `CLINIC-CONSULT-V139.md` 覆盖 V126–V138 旧格；坐诊未改。

名字标签：脚底上方 `Vector2(-48, -display_h - 8)`，高 22，勿压四诊 HUD（诊室 HUD 在 `UI/Hud`，不在 L5）。

**换单人图时**：拆掉 `L5_characters/Patients` 合图依赖；`Patient0/1/2` 各挂一张 Texture；座位仍 tween 到 (1040, 590)。

---

## 3. 问诊 HUD 对话位框（不挡四诊按钮）

`consult.gd` 结构（勿改玩法）：

1. 顶栏：返回 / 姓名  
2. **四诊按钮行** `exams`：望闻问切 + 开方/针灸（约高 40，在 stage **之上**）  
3. 提示 / 问舟条  
4. **`_stage`** 展开区：立绘 + 对话/检查内容  

### 锁死：立绘只进 `_stage`，永不盖住 `exams` 行

建议 `_stage` 内布局（1920 设计宽、左右 padding 24）：

```
_stage (满宽，四诊行下方)
┌──────────────┬────────────────────────────┐
│ PORTRAIT     │  对话 / 望闻问切内容         │
│ 框            │                             │
│ 宽 280～320  │  剩余宽度                    │
│ 高随 stage   │                             │
│ 脚底贴框底   │                             │
└──────────────┴────────────────────────────┘
```

| 控件 | 锚点建议 | 说明 |
| --- | --- | --- |
| `PortraitFrame` | 左：offset_left=16, offset_top=12, offset_bottom=-12；宽 **300** | `TextureRect`，`STRETCH_KEEP_ASPECT_COVERED` **禁止**（会裁脚）；用 **KEEP_ASPECT_CENTERED** 或按高缩放后 **底对齐** |
| 底对齐算法 | `scale = min(frame_w/tex_w, frame_h/tex_h)`；`pos.y = frame_h - tex_h*scale`；`pos.x = (frame_w - tex_w*scale)/2` | **脚在框底** |
| 内容列 | 右：offset_left=320 | 聊天、十问、脉图；不与立绘重叠 |
| 安全区 | stage 顶 ≥ 8 px | 与四诊行分离；立绘顶不得画进 exams |

四诊按钮最小尺寸现为 `Vector2(88, 40)` ×4 + 治疗钮——整行保留全宽可点，立绘**不准**用全屏 Overlay 盖顶栏。

CAM_ASK 构图：病人上半身可读即可；单人立绘在问诊里用半身裁切可选（从脚底向上取 70%），但文件仍是全身，裁切只在 UI。

---

## 4. 江晚 vs 病人

| | 诊室 | 问诊 |
| --- | --- | --- |
| 江晚 | 锚点 **(1035, 770)**（PhysicianChair / 诊桌后），显示高约 **240～260** | 默认**不**占 PortraitFrame；最多角落小头像 64²（选做） |
| 当前病人 | 座位 (1040, 590)，显示高 280～320 | PortraitFrame 主位，按 `current_patient_id` 换贴图 |

---

## 5. 明确不做

- 新大地图、改 BED_RECT / 穴位 UV / 炮制热区  
- 改四诊逻辑与按钮文案  
- 画立绘本体（美工）  
- 苏问舟可点师傅热区  

---

## 6. 交接

### 场景（本包）
- 座位坐标、脚底规则、问诊 PortraitFrame 与四诊避让。

### 美工
- 四张 PNG 脚底贴底；路径见 README。

### 角色开发
- 按 id `load`；Sprite/TextureRect 底对齐；缺图回退；冒烟 `portrait_swap_ok`。


## 7. V133 addendum · 候诊第 4 槽（周绣娘）

日期：2026-09-16  
**不改**上文 V126 核心表（坐诊椅、PortraitFrame、江晚锚点、A/B/旁位既有坐标）。

- 新候诊 home：`WAIT_D` / `Patient3` / `char_xiuniang`；V133 曾锁 **(685, 290)**，**V139 覆盖为 (680, 410)**（见 §10 / `CLINIC-CONSULT-V139.md`）。
- 坐诊仍 **(1040, 590)**；四人共用同一 PortraitFrame，按 id 换贴图。
- 案 id：`xuexu_ganyu`；冒烟：`xiuniang_case_ok`。
- 全表、避让、参考图：见 **`scene-slice/WAITING-SLOT4-V133.md`** 与 `scene-slice/waiting/WAITING_SLOT4.png`（镜像 `ui/waiting/`）。

---

## 8. V137 addendum · 候诊立绘可见

顶 HUD 名单牌不替代凳上立绘。A–D 脚底与热区**不改**；缺 C Area 与合图停用见 **`WAITING-VISIBLE-V137.md`**。

---

## 9. V138 addendum · 诊室 idle 机位

日期：2026-09-24  
idle 须出诊室底图机位 **`CAM_HERO (1280, 780)`**；禁素纸验收。全文见 **`scene-slice/CLINIC-IDLE-V138.md`** 与示意 `scene-slice/waiting/CLINIC_IDLE_V138.png`（镜 `ui/waiting/`）。  
**脚底：V138 曾锁死不改；V139（§10）已覆盖 A–D / 江晚。** 坐诊仍 (1040,590)。机位结论（HERO 中景）仍有效。

## 10. V139 addendum · 日常坐诊构图

日期：2026-09-24  
全文：`scene-slice/CLINIC-CONSULT-V139.md` · 示意 `scene-slice/waiting/CLINIC_CONSULT_V139.png`（镜 `ui/waiting/`）。  
Haopeng：主角**坐着问诊**，病患过来；禁柜顶站人、禁桌面漂浮、禁药壶半屏。

**本 addendum 脚底覆盖 V138 `CLINIC-IDLE` / 上文 §2 旧格（坐诊除外）。**

| 槽 | V139 脚底 | 热区中心 | vs 旧 |
| --- | --- | --- | --- |
| A | **(400, 400)** | (400, 365) r=90 | 原 (405,290) |
| B | **(540, 400)** | (540, 365) r=90 | 原 (545,290) |
| C | **(280, 430)** | (280, 395) r=90 | 原 (300,340) |
| D | **(680, 410)** | (680, 375) r=90 | 原 (685,290) |
| 坐诊 `_seat_patient` | **(1040, 590)** | (1040, 535) r=70 | **不变** |
| 江晚 | **(1035, 770)** | — | 原 (1100,720) → PhysicianChair |

- 机位：idle / 开诊 **`CAM_HERO (1280, 780)`**；药柜中景可读；不新造机。  
- 道具尺度（场景建议）：药壶 ≤220×260；脉枕 ≤160×48；香炉高 ≤56。  
- 立绘：优先复用；坐姿可补（美工）。

- 角色运行时：江晚脚底可在椅锚上 **Y+≤20**（现 `APPRENTICE_HOME+(0,18)`）以免坐姿读成压桌沿；候诊 A–D 严格锁表。Idle 可用软变焦 ≈0.52 入画，机位中心仍 `(1280,780)`。
