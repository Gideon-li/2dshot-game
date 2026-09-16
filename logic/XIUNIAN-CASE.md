# 周绣娘案 · 怎么跑（开发）

锁见 `XIUNIAN-CASE-V133.md`。角色开发读 `slice_logic.json` 的 `cases[xuexu_ganyu]` + `xiuniang_case_rules`。

1. 候诊选 `char_xiuniang` → 案 `xuexu_ganyu`。
2. 表面：头沉、失眠、绣针做到一半停住；脉弦细。
3. 十问问「因」→ 忌日真句 → 写 `play.flags.xiuniang_death_day_told`；信任 `play.trust.xiuniang`。
4. 处治任一路：酸枣仁汤思路 / 神门+三阴交（案临时开）/ 情志两专属卡 / 枣莲粥。
5. settle rank≥clear 且忌日已吐 → `play.flags.town_permit` + 问舟旁白键。
6. 冒烟标签：`xiuniang_case_ok`。
