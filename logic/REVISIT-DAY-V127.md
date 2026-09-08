# V127 复诊日循环 · 负责人锁

## 日时钟
- `play.day: int`（默认 1）
- 入口：诊室空闲「次日开馆」→ `day += 1`，再 FIFO 拉 1 个到期复诊

## pending_revisits 记录
结算写入：
- `patient_id`, `case_id`, `rank_id`, `flavor_kind` ∈ good|slow|over|mis
- `treated_at_day`, `due_day = treated_at_day + 1`
- `consumed: false`

开馆：取最早 `consumed=false && due_day <= play.day` 一条入座复诊；结束后 `consumed=true`。

## 复诊态
`revisit_consult`：立绘+「复诊」角标；轻量主诉模板（不接 LLM）；可开方/针或「观察勿药」。

## 冒烟
`revisit_day_ok`：settle → day+1 → pending 入座 → consume
