# V129 夜读医典 · 负责人锁

## 入口 / 夜格
- 诊室 → 阁楼热区（CAM_LOFT）；耗 **夜格 1**（与暮格并列）
- 无夜格：提示明日再来，或允许「提前歇息进夜」进阁楼
- 已读页 **复习不扣夜格**

## 三页 → 节点
| 页 | 解锁 |
| --- | --- |
| 寒热虚实 | `theory.hanre_xushi` |
| 十问歌残句 | `theory.tenq_song` |
| 脉语弦/浮（切片锁弦） | `theory.pulse_names` |

写入 `play.codex_unlocked[]`（页 id）+ `play.theory_nodes[]`（或同集合）。

## 可见差异（至少一处）
- `tenq_song`：十问旁显原典一句
- `pulse_names`：脉象旁显标准脉名（未解锁仍用描写）

## 冒烟
`codex_night_ok`：进阁楼 → 领悟一页 → 存档含节点

不做：五分册、穿越、铜人、改 LLM/secrets/炮制针灸。
