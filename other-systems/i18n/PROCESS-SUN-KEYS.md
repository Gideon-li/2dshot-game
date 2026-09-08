# V128 晒药 / 炮制打磨键

在 V124 `PROCESS_*` 上补全晒工位。

| 组 | 键 |
| --- | --- |
| 翻晒 | `PROCESS_SUN_FLIP` / `FLIP_HINT` / `FLIP_NEED` / `PROGRESS` |
| 结果 | `PROCESS_SUN_HINT`（已改为主动翻晒）/ `DONE` / `OK` / `OKAY` / `WEAK` / `OVER` / `RETRY` / `LOCKED` |
| 教学药 | `PROCESS_MUDANPI_HINT` / `PROCESS_MUDANPI_NAME` |
| 打磨 | `PROCESS_WASH_RETRY` / `PROCESS_FRY_RETRY` / `PROCESS_RETRY` / `PROCESS_STATION_ACTIVE` / `PROCESS_STATION_SUN_READY` |
| 旁白 | `MENTOR_PROCESS_SUN` / `XIAOHE_PROCESS_SUN` |
| 已有 | `PROCESS_STATION_SUN`、`PROCESS_QUALITY_*`、`PROCESS_DONE_HINT` |

免责：`STORE_NOT_MEDICAL` / `BOOT_DISCLAIMER_*` **不改**。

音效：`other-systems/audio/sun-dry.ogg`（翻晒/布面轻声）；见 `audio/V128-SUN-SFX.md`。
