# 青石诊案再扩（expand2）· 怎么跑

1. 读锁：`QINGSHI-EXPAND2-V135.md` + `qingshi_expand2.json` / `slice_logic.json → qingshi_expand2_rules`。
2. 候诊池共 10 案；同屏最多 4 席（A–D）。有 `town_permit` 后三新案权重 ×1.8；无 permit 可偶遇一次 `yangxu_weihan` 教学（血瘀/暑湿各 0.05）。
3. 合法 settle（rank≥clear）→ `play.seals[]` 写入案 id；UI 共 6 枚小印（V134 三 + V135 三）。
4. 冒烟：三新案各走一路合法方/针/食 → `qingshi_expand2_ok` + `SMOKE PASS`。
5. 对照误治：阳虚勿清泻（银花连翘 / 知母黄柏）；血瘀勿猛破/寒清堆；暑湿勿附姜纯燥或麻黄重发汗。
6. 穴：关元/命门/三阴交/曲池仅 `case_temp_open`；勿扩 `vol1_open_ids`。
