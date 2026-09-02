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
