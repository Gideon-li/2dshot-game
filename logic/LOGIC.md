# 《墨问岐黄》切片逻辑（v1.19 对齐）

给角色开发直接读：`slice_logic.json`  
设定包：`design-pack-vnew/墨问岐黄_设定文档包_v1.19/`（16 / 17 / 18 / 19 / 15 + 计分引擎）  
工作名并用：墨问岐黄 / 杏林墨问。学徒默认 **江晚**（旧称林晚）。苏问舟旁白-only；小荷只留钩子。
熟练度本期只留接口。

不是题库。玩家看不到诊断名。治疗没有唯一解。脉象和药都是手操。反畏硬锁，不靠扣分了事。

## 疗效分（v1.19 简化）

```
C* = C × J × T
M  = 0.45·C* + 0.20·B + 0.25·A' + 0.10·U
M_final = M × process_mult   # 四诊缺项仍打折
score (UI) = M_final / 100
```

切片 **J = 1、T = 1**（字段留着，接 22/23 再用）。及格线 M≥55，良好 ≥70。

| 项 | 切片怎么算 |
| --- | --- |
| **C** | 仍用 `required_actions` / `preferred` / 药性（或穴位和谐）合成 0..1，再 ×100。完整 21 维余弦后置。 |
| **B** | 命中 `legal_*_examples` → ~72；纯自拟 0；乱贴方名 0.12×（切片无方名菜单则少见） |
| **A'** | 原始 −20..+20 映到 0..100。误治 / 过治走负向；**反畏不进 A** |
| **U** | 底分 80；味>14 / 穴>6 每多 1 扣 8。切片 3–8 味 / 2–5 穴通常不扣 |
| **process** | 缺诊：`max(0.40, 1 − 0.12×缺 − 0.08×缺主诊)` |

结果里请带上 `M,C,B,A_prime,U,J,T`（调试用，HUD 默认不展示）。

## 反畏硬锁（开方前）

表在 `incompat`。拖药进盘或点确认前调用：

`incompat.check_formula(herb_ids) → null | {kind, a, b, reason_short, …}`

命中则：药弹回、盏缘朱砂、浮层短因（≤40 字）。针灸不走反畏。十九畏破例切片关闭。全表可后置齐柜，**接口先挂上并能提示原因**。

## 十问快捷条

`ten_questions.items`：寒热 / 汗 / 头身 / 便 / 饮食 / 胸 / 聋 / 渴 / 旧病 / 因（+ 经带、小儿附槽）。

问诊面板左侧快捷条，点一下发短问（接 Qwen / 回退锚），**不弹百科**。各案 `ten_q_priority` 供问舟催问；苏问舟旁白键值归剧本。

## 四诊状态机

任意顺序。缺一仍可开方/扎针，评分打折。见 `fsm`。

## 三张病机表

| id | 内部名（勿上 HUD） | 引擎桶 | 脉 | 十问优先 |
| --- | --- | --- | --- | --- |
| `fenghan_biao` | 风寒束表 | 风寒表实 | 浮紧 | 寒热、汗、头身、因 |
| `ganyu_qizhi` | 肝郁气滞 | 肝郁血虚 | 弦 | 胸、饮食、旧病、因 |
| `yinxu_neire` | 阴虚内热 | 肾阴虚 | 细数 | 汗、渴、寒热、旧病 |

人物：赵阿福 / 沈清荷 / 周婆婆（`bind_character_id` 已填）。问诊咬 `inquiry_anchor`，禁止 `never_say`。

## 熟练度

`proficiency.enabled = false`。


## V120 收圆

### 问舟旁白接线
四诊旗 + 十问覆盖 → `mentor_cue_rules`。同诊 **≤2 句**。缺「寒热」「汗」优先催。补问后可出「这一问有了。」（`mentor.affirm_short`）。不报方、不报证。

API：`MentorCues.next(case, exams, asked_ten_q_ids, cues_emitted)`。

### 结算展示
与 `Scoring.evaluate()` 对齐。玩家可见：M（score）、rank、flavor、path、误治/过治旗；明细可展 C / C* / B / A' / U（J=T=1）。

### 回访钩子
结算写入存档 `play.pending_revisits[]`；下次进馆读一句（各案 `revisit`，剧本可覆写）。不接 LLM。

### 小荷
`pharmacy_kid_rules.proxy_diagnosis.enabled = false`。只做候诊/药柜 UI 口吻，不代诊。


## V121 认药 · 采药

`herbs[].forage`（**最多 12 味** `enabled:true`，白名单对齐 `patients/forage_script.json`）：麻黄/桂枝/生姜/白芍/甘草/大枣/柴胡/当归/白术/茯苓/熟地/牡丹皮。`scene_spot`、`clues`、`identify_options`、`yield`。bohe/山药不在切片可采。

规则见 `forage_rules`：

1. 进药圃耗 **1 午后格**（`play.time_slots.afternoon`）。
2. 先认后采；认错可再试，不 Game Over。
3. 成功 → `play.herbs_identified` + `play.herb_inventory[id] += yield`。
4. **未识别 / 无库存** 不能拖进方（`Forage.can_use_in_formula`）。
5. 冒烟：采桂枝+白芍+生姜+甘草 → 阿福风寒路径仍可向愈。

线索文案剧本可覆写；逻辑已给可跑草稿。阿桂含糊提示 ≥3 句归剧本。


## V122 问诊 prompt / offline

- 病例卡 system prompt **与 provider 无关**（remote / local / offline 共用字段）。约定：`logic/inquiry_prompt_contract.json`。
- 只用人物卡 + `inquiry_anchor` / `never_say` + `inquiry_rules`；不把 endpoint、key、provider 写进 prompt。
- offline：`ask_wrappers` 套 `{sym}`=锚点；追问病名走 `dodge`。
- 覆盖自检：`python3 logic/check_offline_templates.py` → `logic/offline_coverage_report.json`（须 PASS）。


## V124 炮制

`herbs[].process`：`needs_process` / `process_method` / `raw_id`→`processed_id`（切片同 id + `state`）。

教学味：**杏仁洗**、**白芍炒**；附子可选教学关（毒性警告，治病不强制）。

规则见 `process_rules`：

1. 进炮制院耗 **1 暮格**。
2. 品质两档：`ok` / `ok_ish`（过火欠火不 Game Over）。
3. `needs_process` 且 `state!=processed` → **不可入盏**（`Process.can_use_in_formula`）。
4. **炮制不解锁十八反**（制附子仍反半夏）。


## V125 针灸入门短环

`acupoints[]` 增补：`method`（needle/moxa/both）、`teach_vol1`、`tolerance`（`center_r=0.025` / `jing_r=0.055`）。

体图取穴（非纯菜单）。坐标沿用 `scenes/acupuncture.gd` `POINT_POS`：

| id | 法 | 体图 UV | 小环 |
| --- | --- | --- | --- |
| `hegu` 合谷 | 针 | (0.08, 0.46) | 得气节奏（切片仅「平」）；失败可再试 1 |
| `zusanli` 足三里 | 灸 | (0.38, 0.72) | 壮数 3/5/7（默认 5）+ 红晕 |

命中（归一化欧氏）：穴心准高；经容小扣可进手法；出经可重试。卷一其余穴灰显不可选。侧栏列表默认隐藏。

会话级：`GameFlow.acu_known` / `acu_practiced`（不写长档）。结算仍 `settle("acupuncture", …)`，1～3 穴；开方路径不动。

冒烟：`acu_intro_smoke_ok`（合谷得气 **或** 足三里灸 → 可提交）+ `SMOKE PASS`。


## V127 复诊日循环

见 `REVISIT-DAY-V127.md` + `revisit_day_rules`。

- `play.day`；诊室「次日开馆」→ day+1，FIFO 拉 1 个 `due_day<=day` 的 pending。
- 结算写 `pending_revisits`：`due_day = treated_at_day + 1`，`flavor_kind` ∈ good|slow|over|mis。
- 态 `revisit_consult`：复诊角标 + 模板主诉（**不接 LLM**）；可开方/针或 **观察勿药**。
- 观察勿药：向愈档小稳分；结束后 `consumed=true`。
- 复诊再治：`evaluate` × 0.85。
- 冒烟：`revisit_day_ok`。
