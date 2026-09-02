# Steam Coming Soon 素材清单（切片可录即挂）

切片已无头冒烟通过。Demo = 本切片。发售页至少提前 2 周。不要把 Qwen/大模型写进卖点。不要挂 Education；Medical Sim 不要放第一。主标签：Simulation / Puzzle / Casual / 2D。

## 商店第一句（锁死）

| 语言 | 句 |
| --- | --- |
| 中 | 病人不交全症状。望、闻、问、切，都要你亲手做。 |
| EN | The patient never hands you a complete chart. Look, listen, ask, then feel the pulse. |
| 日 | 患者は症状をすべて話さない。望・聞・問・切は、あなたがやる動詞だ。 |

键：`STORE_TAGLINE`（`other-systems/i18n/ui.csv`）。英日不要写成「学中医」。

## 免责（启动 + 商店都要）

文化体验，不能替代就医。`STORE_NOT_MEDICAL` / `BOOT_DISCLAIMER_*`。不要写可学习行医、不要写具体药方当医嘱。

## 图（构图锚点在 scene-slice/SCENE-SLICE.md）

| 顺序 | 镜头 | 资产 | 必有 |
| --- | --- | --- | --- |
| 胶囊 / 第 1 | CAM_HERO | `ui/layers/CAM_HERO.png` | 厅堂+脉枕，禁止空山水 |
| 第 2 | CAM_ASK | 问诊截图（`ui/store/` 已有） | 病人在说话，不报病名 |
| 第 3 **前三必有脉象** | CAM_PULSE | `ui/layers/CAM_PULSE-empty.png` + `pulse-overlay.png` | 枕面+窗光+脉纹 |
| 第 4 | CAM_FORMULA 和/或 CAM_NEEDLE | `ui/store/` 已有 | 同一栋里拖药或点穴 |
| 第 5 | CAM_RESULT | `ui/store/` 已有 | 空坐堂，分数 UI |

## 预告

60 秒无解说试玩：进馆 → 问诊 → 诊脉画面 → 下手配药或扎针。雨+薄床，切诊 duck 旋律。

## 定价（页上可先不写死）

目标 ¥58 / $14.99 / ¥1,700。若页上仍是薄切片，降到 ¥42 / $9.99。

## 还缺（录屏前）

- 用 Godot 编辑器或导出包跑一遍手操，录 CAM_ASK / FORMULA / NEEDLE / RESULT
- 胶囊按 CAM_HERO 裁
- 商店页中英日三套短描述（第一句用上表，不要展开成教材）


Updated paths: ui/store CAM_ASK FORMULA NEEDLE RESULT.
