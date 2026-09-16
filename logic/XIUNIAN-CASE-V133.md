# V133 周绣娘情志主线案 · 接口锁

- **角色**：`char_xiuniang`（周绣娘）；立绘齐 V126.1 平涂
- **案 id（锁）**：`xuexu_ganyu`（郁 + 血虚 / 绣架压胸；**勿用** `shen_bushe`）
- **信任**：`play.trust.xiuniang` ∈ [0,1]（init 0.35）；追问女儿隐私 → 降；夸绣 / 不问破 / 忌日解锁 → 升
- **出镇**：达标 settle（忌日已吐真 + rank≥clear）后 `play.flags.town_permit=true` + `mentor.town_permit`；**不出五方地图**
- **忌日真句**：十问问到 `yin`（因；可选情志）才给；`play.flags.xiuniang_death_day_told`；`never_volunteer`；永不报证型名
- **合法路径（开放解）**：
  1. 方：酸枣仁汤思路 — `suanzaoren`+`zhimu`+`fuling`+`chuanxiong`+`gancao`（向量近似即可）
  2. 针：本案临时开 `shenmen` + `sanyinjiao`（`acu_intro_rules.case_temp_open`；不写死进 `vol1_open_ids`）
  3. 情志：`no_rush_embroider` / `leave_lamp_on`（+ 共享池）
  4. 食：枣莲粥 `hongzao`+`lianzi`+`zhou_di` 慢愈线
- **误治**：`jinyinhua`+`lianqiao` 峻清 / `longgu`+`muli` 重镇 / `mahuang` → 快高稳低 + 回访头昏
- **规则表**：`slice_logic.json` → `xiuniang_case_rules`；拆分 `logic/xiuniang_case.json`
- **冒烟**：`xiuniang_case_ok`（忌日 unlocked + ≥1 合法 settle）+ `SMOKE PASS`
- **不做**：情缘、女儿高热同诊、经带强制、陈半仙、出镇旅行
