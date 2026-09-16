# V131 Demo 日环胶水 · 接口锁

- **目标**：串联已有环，不新开大玩法
- **推荐序（可跳）**：晨诊处治 → 午采 → 暮炮（洗/炒/晒任一）→ 夜读一页 → 次日 → 复诊
- **存档**：`play.demo_guide` = `{ enabled: bool(default true), steps_done: [], dismissed: bool }`
- **HUD**：`Day N` + `time_slots` 晨/午/暮/夜 亮灭与按钮灰亮同一真相
- **结算下一跳**：settle 后提示键（如 `DEMO_NEXT_GARDEN` / `PROCESS` / `LOFT`）
- **返回**：园/炮/阁/食疗/针 → 诊室 idle，不吞存档
- **冒烟**：`demo_day_ok`（端到端）+ 原环仍 `SMOKE PASS`
- **文档**：根目录或 `other-systems/` 写 `DEMO-DAY.md` 一页怎么玩
- **不做**：新病例、情志、Steamworks、改 LLM/secrets、J/T
