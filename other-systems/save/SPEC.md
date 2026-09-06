# 存档（切片）

本地 JSON，3 个槽。路径：Godot `user://saves/slot_{n}.json`。本期不做 Steam Cloud、不做跨设备。

## 何时写盘

- 勾选并接受免责
- 切语言或音量
- 看完一个病人并结算
- 玩家按存档

## 字段

见 `schema.json`。

- `patients_seen`: 已看完的病人 id，最多 3 个（切片）。
- `four_exams`: 当前病人的望闻问切是否做过。缺一仍可开方，评分打折，由逻辑读这个结构。
- `last_treatment`: `"formula"` 或 `"needle"` 或 `null`。
- `scores`: `{ "patient_id", "path", "efficacy", "pace", "overtreat", "mistreat" }`。积分榜先用这份本地数据。Steam 排行榜本期不上。

## 兼容

读档时若 `version` 小于当前，只填缺省，不要炸。熟练度/收学徒字段本期不要写进去。


## V120 增补

- `asked_ten_q_ids`: 当前病人已点的十问 id（`hanre` / `han` …）。
- `mentor_cues_emitted_this_visit`: 本诊问舟旁白已出句数，**上限 2**（含「这一问有了。」）。
- `pending_revisits[]`: 结算写入；下次进馆可读一句病程/回访（本地模板，不接 LLM）。字段见 `logic/slice_logic.json` → `revisit_save.record_shape`。
- `pharmacy_kid_proxy_enabled`: 小荷代诊开关，**默认 false**。切片不做代诊。
- `four_exams` 可用 `wang/wen_listen/wen_ask/qie`（与逻辑一致）；旧 look/listen/ask/pulse 仍可读。


## V121 增补

- `herb_inventory`: `{ herb_id: count }` 药圃采入。
- `herbs_identified`: 已辨认 id 列表；未在此列的药不能进方。
- `time_slots.afternoon`: 进药圃先耗 1；切片无大地图时辰系统时可只做此格。
