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

## 病机表（切片）

| id | 内部名（勿上 HUD） | 引擎桶 | 脉 | 十问优先 |
| --- | --- | --- | --- | --- |
| `fenghan_biao` | 风寒束表 | 风寒表实 | 浮紧 | 寒热、汗、头身、因 |
| `ganyu_qizhi` | 肝郁气滞 | 肝郁血虚 | 弦 | 胸、饮食、旧病、因 |
| `yinxu_neire` | 阴虚内热 | 肾阴虚 | 细数 | 汗、渴、寒热、旧病 |
| `xuexu_ganyu` | 血虚肝郁（绣架压胸） | 血虚肝郁 | 弦细 | 因、胸、汗、旧病 |
| `fengre_biao` | 风热束表 | 风热表证 | 浮数 | 寒热、汗、头身、渴 |
| `shiji` | 食积 | 食积气滞 | 滑 | 饮食、胸、便、因 |
| `pixu_shikun` | 脾虚湿困 | 脾虚湿困 | 濡 | 饮食、头身、便、汗 |

人物：赵阿福 / 沈清荷 / 周婆婆 / 周绣娘 / **走贩** / **宴后熟人** / **药农亲友**（`bind_character_id` 已填）。问诊咬 `inquiry_anchor`，禁止 `never_say`。V133 / V134 细则见下节。

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


## V128 晒药

- `sun_dry` **正式可玩**（不再 placeholder）；`slice_playable_methods` = wash / stir_fry / sun_dry。
- 教学药：**牡丹皮 `mudanpi`** — `needs_process` + `sun_dry`；生不可入盏。
- 玩法：翻晒主动 ≥1 + 日照进度；品质 `ok` / `ok_ish`。
- 工位 `STATION_DRY` / `CAM_DRY`。暮格、托盘拦截、十八反、LLM 不改。
- 冒烟：`process_sun_ok`。锁见 `PROCESS-SUN-V128.md`。


## V129 夜读医典

见 `CODEX-NIGHT-V129.md` + `codex_night.json` / `codex_night_rules`。

| 页 | 节点 | 解锁后可见 |
| --- | --- | --- |
| 寒热虚实 | `theory.hanre_xushi` | 结算/旁白四字直觉（非诊断名） |
| 十问歌残句 | `theory.tenq_song` | 十问旁原典一句 |
| 脉语弦 | `theory.pulse_names` | 脉象标准名（未解锁只用描写） |

- 进阁楼耗 **夜格 1**；复习已读不扣。
- 存档：`play.codex_unlocked[]`、`play.theory_nodes[]`。
- 冒烟：`codex_night_ok`。不改 LLM/炮制/针灸。


## V130 食疗入门

见 `FOOD-THERAPY-V130.md` + `food_therapy.json`。

- path=`food`；处治 `ACTION_FOOD`；膳盏 1～3 卡。
- 六卡：`zhou_di` / `hongzao` / `lianzi` / `shanyao` / `shengjiang` / `bingtang`。
- 教学库存 `play.food_stock`，不污染药柜。
- 劝说可选：`less_worry` | `rest_wind` | `no_late_lunch`（温分小加）。
- 慢愈示例：枣莲粥 → 气郁/轻虚可向愈慢档；风寒单走食疗准偏低。
- `evaluate(..., path="food")`；冒烟 `food_therapy_ok`。


## V131 Demo 日环胶水

见 `DEMO-DAY-V131.md` + `demo_day.json` / `demo_day_rules`；怎么玩：`DEMO-DAY.md`。

- `play.time_slots` 晨午暮夜 = 按钮灰亮 **唯一真相**（`DemoDay.can_act`）。
- `play.demo_guide`：`enabled` / `steps_done` / `dismissed`；六步可跳序。
- 结算下一跳键：`DEMO_NEXT_GARDEN|PROCESS|LOFT|DAY`。
- 冒烟：`demo_day_ok`（诊→治→采→炮→夜读→次日复诊）。


## V132 情志疏导入门

见 `EMOTION-COUNSEL-V132.md` + `emotion_counsel.json`。

- path=`emotion`；`ACTION_EMOTION`；教学锚沈清荷 / `ganyu_qizhi`。
- 三拍：listen → 1～2 张 `counsel_cards` → 可选 close。
- 六卡：`walk_ease` / `less_desk` / `vent_rest` / `warm_calm` / `no_scold` / `no_harsh_tonify`（后两张惩罚）。
- 离线选项树；`evaluate(path="emotion")`；冒烟 `emotion_counsel_ok`。


## V133 周绣娘 · 血虚肝郁案

见 `XIUNIAN-CASE-V133.md` + `xiuniang_case.json` / `xiuniang_case_rules`。

- 第四病人 `char_xiuniang`；案 **`xuexu_ganyu`**（勿用 shen_bushe）；内部名「血虚肝郁（绣架压胸）」不上 HUD。
- 新药：`suanzaoren` / `chuanxiong`（合法）；`longgu` / `muli`（仅 mistreat）。
- 新穴：`shenmen`（针、得气结构镜像合谷）；`sanyinjiao` 本案临时开。`acu_intro_rules.case_temp_open.xuexu_ganyu` → 两穴；**不**永久进 `vol1_open_ids`。
- 信任 `play.trust.xiuniang`；忌日旗 `play.flags.xiuniang_death_day_told`（十问 `yin`）；出镇 `play.flags.town_permit`（达标 settle）。
- 情志专属卡：`no_rush_embroider` / `leave_lamp_on`（亦写入 `emotion_counsel.json`）。
- 抓郁或血虚一面并护胃即可；误治峻清/重镇 → 回访头昏。
- 冒烟：`xiuniang_case_ok` + `SMOKE PASS`。怎么跑：`XIUNIAN-CASE.md`。


## V134 青石镇诊案扩容

见 `QINGSHI-EXPAND-V134.md` + `qingshi_expand.json` / `qingshi_expand_rules`。怎么跑：`QINGSHI-EXPAND.md`。

- +3 案 +3 人：`fengre_biao`/`char_zoufan`，`shiji`/`char_yanhou`，`pixu_shikun`/`char_yaoqin`；旧四人保留（共 7）。
- 新药：`shanzha`（`digest_food`；不采）。
- 穴：`acu_intro_rules.case_temp_open.fengre_biao` → `quchi`+`hegu`；`pixu_shikun` → `sanyinjiao`；**不**永久扩 `vol1_open_ids`。
- 证印：settle rank≥`clear` → `play.seals[]` 写案 id；本档只亮 3 枚 UI。
- 候诊：仍 4 席 A–D；有 `town_permit` 三新案权重 ×1.8；无 permit 可偶遇一次 `shiji` 教学。
- **风热/风寒误叉**：风热误用麻黄/桂枝 → mistreat + 稳罚、回访热更重/咽更疼；风寒误用金银花/连翘 → 旧案 `common_mistreat` 保持（表寒更闭）。
- 冒烟：`qingshi_expand_ok`（三案各 ≥1 合法 settle）+ `SMOKE PASS`。

## V135 青石诊案再扩（expand2）

见 `QINGSHI-EXPAND2-V135.md` + `qingshi_expand2.json` / `qingshi_expand2_rules`。怎么跑：`QINGSHI-EXPAND2.md`。

- +3 案 +3 人：`yangxu_weihan`/`char_danfu`，`xueyu_qing`/`char_bashi`，`shushi`/`char_jiaoli`；旧 7 保留（共 **10**）。
- 新穴：`guanyuan`（灸；温阳/补气/回阳；案临时开）。`case_temp_open`：阳虚→关元+命门；血瘀→三阴交；暑湿→曲池。**不**永久扩 `vol1_open_ids`。
- 证印：settle rank≥`clear` → `play.seals[]`；UI 闪键共 **6**（V134 三 + 本档三）。
- 候诊：仍 4 席；有 `town_permit` ×1.8；无 permit：`yangxu_weihan_teach_once` weight≈0.25；血瘀/暑湿各 0.05。
- **误治短注**：阳虚误清（银花连翘/知母黄柏）；血瘀猛破（寒清堆；破血重剂忌）；暑湿纯燥（附姜/麻黄）。
- 冒烟：`qingshi_expand2_ok`（三案各 ≥1 合法 settle）+ `SMOKE PASS`。

