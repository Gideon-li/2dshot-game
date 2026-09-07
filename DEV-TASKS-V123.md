# 《墨问岐黄》V123 — Steam Coming Soon 素材包

日期：2026-09-07  
下发：全局统筹 → 开发负责人 → 相关组  
依据：`STEAM-COMING-SOON.md`、`STEAM-MARKET-RESEARCH.md`、现行可玩切片（V122 已验收）

## 目标

整理一包 **能直接贴进 Steam Coming Soon / 愿望单页** 的素材，不申请上架、不接 Steamworks 发售。

输出目录：`/workspace/xinglin-mowen/steam-coming-soon/`（并推 main）

## 锁死文案

### 商店第一句
| 语言 | 句 |
| --- | --- |
| 中 | 病人不交全症状。望、闻、问、切，都要你亲手做。 |
| EN | The patient never hands you a complete chart. Look, listen, ask, then feel the pulse. |
| 日 | 患者は症状をすべて話さない。望・聞・問・切は、あなたがやる動詞だ。 |

### 短描述（各语言 1 短段，非教材）
- 点出：Q 版中式医馆、四诊手做、开方/针灸多合法路径、药圃认采、可离线问诊回复。
- **不要**写大模型/Qwen/Helix；**不要**写成学中医题库；**不要**挂 Education 话术。

### 免责（商店页 + 启动一致）
文化体验，不能替代就医。

### 标签建议（写进 README，不操作后台）
主：Simulation / Puzzle / Casual / 2D。Medical Sim 勿第一。

### 定价备忘（页上可先不写）
目标 ¥58 / $14.99 / ¥1,700；薄则 ¥42 / $9.99。

## 图件（Steam 常用尺寸）

| 文件 | 尺寸 | 来源/要求 |
| --- | --- | --- |
| `capsule_main.png` | 616×353 | 自 CAM_HERO 裁，厅堂+脉枕，禁空山水 |
| `capsule_small.png` | 231×87 | 同上缩略 |
| `header_library.png` | 460×215 | 库头图 |
| `screenshot_01_hero.png` | ≥1280×720 | 诊室主画面（江晚） |
| `screenshot_02_ask.png` | ≥1280×720 | 问诊，不露诊断名 |
| `screenshot_03_pulse.png` | ≥1280×720 | **前三必有脉象** |
| `screenshot_04_formula_or_needle.png` | ≥1280×720 | 开方或扎针 |
| `screenshot_05_result_or_garden.png` | ≥1280×720 | 疗效结算或药圃认采 |
| `pulse_close.png` | 可选 | 切脉近景加强 |

现有资产：`ui/layers/CAM_HERO.png`、`CAM_PULSE*`、`ui/store/CAM_*`、药圃图。按 **墨问岐黄 / 江晚 / 明快 Q 版** 校对；旧「林晚」「杏林墨问」字样不得出现在商店图。

## 预告（尽量）

`trailer_60s.mp4` 或分镜+录屏草稿：进馆 → 问诊 → 诊脉 → 开方/扎针（可无配音）。做不出完整成片则交分镜+现有片段说明「待录」。

## 完成标准

1. `steam-coming-soon/README.md`：上表文案 + 标签 + 定价备忘 + 文件清单。
2. 胶囊 + 至少 5 张截图按尺寸导出；脉象在前三张内。
3. 中英日短描述各一份（md 或 csv）。
4. 推 main；secrets 不进库。
5. **不**创建 Steam 应用、不填伙伴后台（只交素材包）。

## 分工

- **开发负责人**：目录结构、尺寸验收、推送、拦卖点违规。
- **美工**：胶囊裁切/合成、截图挑片与微调、禁旧人设字样。
- **角色开发**：必要时重抓运行时截图（1280×720+）。
- **剧本 / 其他要素**：中英日短描述与免责定稿；核对 i18n `STORE_*`。
- **场景**：仅当截图缺构图时补一刀。
- **音乐**：预告若录，沿用切诊 duck；无则跳过。

## 不做

正式上架、Steamworks 成就对接、付费页、情缘/穿越卖点。

## 回我

`steam-coming-soon/` 路径 + commit + 胶囊缩略预览图。
