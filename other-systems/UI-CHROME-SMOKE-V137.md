# V137 `ui_chrome_ok` · 角色侧清单

对照：`incoming/ui-overlap-haopeng-20260924.png` · 接口锁 `UI-CHROME-V137.md` · 键表 `i18n/SETTINGS-SAVE-KEYS.md` · Save `save/SPEC.md` V137。

## Checklist

1. **设置钮**：挂常驻设置（文案 `SETTINGS_TITLE`）；面板内含
   - 语言行（`LANG_ZH` / `LANG_EN` / `LANG_JA`，可用既有 `UiKit.locale_bar()` 或面板内三钮）
   - 3 档位 + 存 / 读（`SAVE_SLOT` / `SAVE_SAVE` / `SAVE_LOAD`；分区可用 `SETTINGS_SECTION_SAVE`；提示 `SAVE_SLOT_HINT` / `SETTINGS_HINT` / `SETTINGS_CLOSE`）
2. **去掉/隐藏**诊室常驻三语言大钮；语言只在设置内。
3. **接线**
   - 语言：`GameFlow.set_locale(code)`（或 `Save.set_locale`）
   - 存：`Save.save_to_slot(n)` / `Save.write_slot()` → toast `SAVE_SAVED`
   - 读：`Save.apply_slot(n)` → 刷新 HUD / `GameFlow.locale_changed.emit()` → toast `SAVE_LOADED`
4. **对话滚底**：`ScrollContainer` 追加后 `scroll_vertical = max`（强制贴底）；换病人同样贴底。上翻可选 `CHAT_NEW_MSG`；默认仍强制滚底。
5. **冒烟日志**：headless / 轻手操打印 `ui_chrome_ok`，当且仅当：
   - 设置已打开过
   - locale 切换过一次
   - `write_slot`（或 `save_to_slot`）成功一次
   - 追加 ≥3 行对话后 scroll 在底部
6. **顶栏标题**：主标题优先 `STORE_TITLE`（墨问岐黄）；`DEBUG_PANEL` / DEBUG 角标次要、不占主标题位。
7. **免责**：勿动 footer / `BOOT_DISCLAIMER_*` / `STORE_NOT_MEDICAL` 文案键。

## 不做

clinic 布局大改以外的病机 / LLM / secrets；不改免责句。
