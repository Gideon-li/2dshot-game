# 《墨问岐黄》开发任务 V128（晒药工位 + 炮制打磨）

日期：2026-09-08  
下发：全局统筹 → 开发负责人 → 小组  
前置：V127 已验收；V124 洗/炒可玩，`STATION_DRY` 多为进度条占位；`process_rules.sun_dry.slice = optional_placeholder`  
依据：设定炮制院「炉、晒、洗」；晴可晒药；教学须炮制才能入盏

## 目标

1. **晒药工位真正可玩**：不再是灰按钮/纯占位。  
2. **炮制院打磨**：洗/炒/晒三工位手感、镜头、旁白、音效齐一套，进出院清楚。

接环不变：采药 → 黄昏炮制院 → raw→processed → 托盘；未炮制须炮制药仍拦截。

## 范围（锁死）

### A. 晒药（主交付）

- 启用 `STATION_DRY` / `sun_dry`：列入 `slice_playable_methods`。
- **教学药（锁 1 味）**：优先 **牡丹皮 `mudanpi`**（白名单内；切片「薄片摊晒」）。若逻辑更顺可用大枣 `dazao`，但任务书默认牡丹皮。
  - `needs_process: true`，`process_method: sun_dry`
  - 生品不可入盏；晒妥 → processed 可入盏
- 玩法（轻量，用手做）：
  - 摊片/翻面 2～3 次点击或短拖 + 日照进度；可保留 ProgressBar，但必须有 **至少一次主动操作**（翻晒），不是纯挂机看条。
  - 品质两档 `ok` / `ok_ish`（翻少/过曝 → ok_ish）。
  - 小荷一句或苏问舟一句（晒药）。
- 美术：晒架特写或 `CAM_DRY`；生/制图标差分（`mudanpi_raw` / `mudanpi_processed`）；可用户外廊背景 `yard-bg-outdoor`。
- 剧本：`process_script` 补牡丹皮晒教学句（中英日）。

### B. 炮制打磨（同切片）

- 三工位按钮态一致（晒不再 disabled 灰死）；当前工位高亮。
- `CAM_WASH` / `CAM_FRY` / `CAM_DRY` 切入时微推或换背景，出小游戏回 `CAM_PROCESS`。
- 洗/炒：补失败可重试提示、妥/勉强结算反馈与晒同套。
- 音效：晒（布面/风铃轻）1 条；洗/炒若缺补齐。
- i18n：晒相关键补全（`PROCESS_STATION_SUN` 已有则补 DONE/FLIP/HINT）。
- **不改** 暮格 −1、托盘拦截、十八反、LLM、secrets。

## 完成标准

1. 能选晒工位，对牡丹皮（或锁定的那味）完成翻晒→processed→可入盏。
2. 未晒的该味仍不可入盏。
3. 洗/炒/晒三路手操流畅；冒烟：`SMOKE PASS` + `process_sun_ok`（晒一轮入盏）。
4. 推 main。

## 分工

### 开发负责人
- 转发；定教学药 id（默认 mudanpi）；验收三工位；推送。

### 游戏逻辑设计
- `sun_dry` 正式化；牡丹皮 process 字段；品质；`slice_playable_methods` 含 sun_dry。
- 更新 `LOGIC.md` / `process_rules` 去掉 placeholder 标记。

### 剧本设计
- 牡丹皮晒教学/成败/小荷或问舟句（中英日）。

### 游戏美工设计
- 晒架/翻晒 UI；牡丹皮生制图标；工位高亮；可选户外晒场一角。

### 游戏场景设计
- `STATION_DRY` 热区可点；`CAM_DRY`；与洗炒并列不挡门。

### 游戏角色开发
- 翻晒小游戏；三相机；冒烟；图标挂载。

### 其他要素
- i18n / 晒音效。

## 不做

天气系统深度、五方晒场、半日挂机自动完成、新毒理、改 Steam、J/T。

## 回我

手操或截图：晒牡丹皮 → 入盏 + commit。
