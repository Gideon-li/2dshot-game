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
| 病人椅座位 | **(1040, 590)** | `_seat_patient` 已锁；三病人坐诊脚底 |
| 候诊凳 A / B | (405, 290) / (545, 290) | 候诊；可只显示小头或缩小 0.85 |
| 候诊旁位 | (300, 340) | Patient2 home |
| 江晚学徒锚点 | **(1100, 720)** | 医师椅侧；不抢病人椅 (1040,590) |
| 病人椅家具 | (1040, 590) | `PatientChair`；立绘脚应落在椅面视觉触点略上 0～12 px 可微调 |

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
| 江晚 | 锚点 (1100, 720)，显示高略小（约 260 px），偏桌北 | 默认**不**占 PortraitFrame；最多角落小头像 64²（选做） |
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
