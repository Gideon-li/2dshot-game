# V130 食疗入门 · 接口锁

- **path**：`food`（evaluate / settle；勿用 `diet` 作 path 名）
- **入口**：处治栏 `ACTION_FOOD`，与开方 / 针灸并列；不回退既有两路
- **膳盏**：拖 1～3 卡（第 4 张起拒绝/不加分）；教学库存 `play.food_stock`（或无限教学池），**不扣药柜 / herb_items**
- **切片 6 卡 id**（锁）：
  - `zhou_di` 粳米粥底
  - `hongzao` 红枣
  - `lianzi` 莲子
  - `shanyao` 山药
  - `shengjiang` 生姜
  - `bingtang` 冰糖（甘缓；痰湿扣稳）
- **慢愈示例**：`hongzao`+`lianzi`+`zhou_di` → 对应轻虚/气郁轻案可 `toward_heal` 或慢档等价
- **劝说（可选）**：3 选 1，`lifestyle_cue` ∈ `less_worry` | `rest_wind` | `no_late_lunch`；不选可交
- **向量**：偏温、补、缓；表实风寒单走食疗 → 准偏低、温尚可；禁真实营养医嘱文案
- **冒烟**：`food_therapy_ok` + `SMOKE PASS`
- **不做**：厨房经营、情志深度、LLM/secrets、改 Steam
