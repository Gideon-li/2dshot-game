# V137 诊室 UI 壳 · 接口锁

对照：`incoming/ui-overlap-haopeng-20260924.png`

## 锁死三件事
1. **去叠层**：候诊 A–D 牌不得压标题/旁白；「去药圃/去炮制院」进统一导航，与语言解耦。
2. **设置**：常驻一枚设置（齿轮/「设置」）；内含语言中英日（`Save.set_locale`/`GameFlow.set_locale`）+ 存读档；去掉诊室常驻三语言大钮。
3. **对话滚底**：追加行后 Scroll 贴底（默认强制）；换病人也贴底。

## 冒烟
`ui_chrome_ok`：开设置→切 locale→写档；追加 ≥3 行后 scroll 在底。不回退 `SMOKE PASS`/`demo_day_ok`。

## 不做
抢 V136 立绘/证印、改病机、LLM/secrets、整套换皮。

## 逻辑侧（V137）

- **病机 / cases / seals / 候诊权重：不动。**
- **设置开闭**：会话态即可，建议 `GameFlow`/`clinic` 本地 `settings_open: bool`（Esc / 二次点齿轮关）；**不**写入 `play.*` 长档，不进 `slice_logic` 案表。
- locale / 存读档继续走既有 `Save.set_locale` / `GameFlow.set_locale` 与 slot API；逻辑不新开病机接口。
- 冒烟 `ui_chrome_ok` 由角色侧挂；逻辑无额外 evaluate 路径。

## 其他要素交付（V137）

- 键表：`i18n/SETTINGS-SAVE-KEYS.md`（新建 `SETTINGS_CLOSE` / `SETTINGS_SECTION_SAVE` / `SETTINGS_HINT` / `SAVE_LOADED` / `SAVE_SLOT_HINT` / `SAVE_SLOT_DAY` / `CHAT_NEW_MSG` / `DEBUG_PANEL`；复用既有 SETTINGS_*/SAVE_*/LANG_*；免责未改）。
- Save 薄 API：`Save.apply_slot(n)`、`Save.save_to_slot(n=-1)`（见 `scripts/save.gd`；接线说明 `save/SPEC.md` · V137）。
- 角色冒烟清单：`UI-CHROME-SMOKE-V137.md`。
