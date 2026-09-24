# V137 设置 / 存读档键

设置面板与存读档文案。语气：短、诊室墨迹感、无剧透。

## 新建（V137）

| key | zh | en | ja |
|-----|----|----|----|
| `SETTINGS_CLOSE` | 关闭 | Close | 閉じる |
| `SETTINGS_SECTION_SAVE` | 存读档 | Save & Load | セーブ／ロード |
| `SETTINGS_HINT` | 再点设置或 Esc 可关。 | Tap Settings or Esc to close. | 設定をもう一度、または Esc で閉じる。 |
| `SAVE_LOADED` | 已读入。 | Loaded. | 読み込んだ。 |
| `SAVE_SLOT_HINT` | 选档后保存或读档。 | Pick a slot, then save or load. | スロットを選んでセーブ／ロード。 |
| `SAVE_SLOT_DAY` | 第 {n} 日 | Day {n} | 第 {n} 日 |
| `CHAT_NEW_MSG` | 有新消息 | New messages | 新しいメッセージ |
| `DEBUG_PANEL` | 调试 | Debug | デバッグ |

- `SAVE_SLOT_DAY`：档位 meta 行用，`{n}` 为日数占位。
- `CHAT_NEW_MSG`：玩家上翻时可选提示；默认 chrome 仍强制滚底。

## 复用（勿重复建键）

- 设置壳：`SETTINGS_TITLE`、`SETTINGS_LANGUAGE`、`SETTINGS_VOLUME_*`、`SETTINGS_LLM_*`
- 语言：`LANG_ZH` / `LANG_EN` / `LANG_JA`
- 存读档：`SAVE_SAVE`、`SAVE_LOAD`、`SAVE_SLOT`、`SAVE_EMPTY`、`SAVE_OVERWRITE`、`SAVE_SAVED`
- 导航：`GARDEN_OPEN`、`PROCESS_ENTER`
- 顶栏正式名：优先 `STORE_TITLE`（墨问岐黄）；**勿改** `GAME_TITLE`

## 免责未改

`BOOT_DISCLAIMER_*`、`STORE_NOT_MEDICAL` **不动**。

源：`other-systems/i18n/ui.csv` ↔ `locale/xinglin.csv`（已同步）；`ui.json` 由 ui.csv 重建。
