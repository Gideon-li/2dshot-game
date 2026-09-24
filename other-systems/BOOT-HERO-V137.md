# V137E · 启动页轻量主视觉路径约定

对照：`incoming/boot-plain-haopeng-20260924.png`  
任务：`DEV-TASKS-V137.md` §E / `DEV-TASKS-V137.1.md` A

## 资源路径

| 用途 | 路径 | 说明 |
| --- | --- | --- |
| **Canonical 轻量主视觉** | `res://ui/chrome/boot_hero.png` | 推荐约 1280×720 或 960×540；水墨纸纹 / 医馆剪影 / 店招；**轻量**，不做完整 CG 片头。美工亦可先落在 `res://ui/boot/boot_hero.png`（见 `ui/boot/BOOT.md`），引擎以 chrome 路径为准 |
| **Interim fallback** | `res://ui/layers/L0-paper.png` | `boot_hero.png` 缺失时，启动页用 TextureRect 拉伸纸纹，避免整页纯调试灰底 |

引擎侧（`scenes/main.gd`）：优先 `ui/chrome/boot_hero.png`，其次 `ui/boot/boot_hero.png`，再回退 `L0-paper.png`；再否则仅保留 `Bg` ColorRect（`UiKit.PAPER`）。

## 工程名 + i18n

- `GAME_TITLE` / `STORE_TITLE` / `application/config/name` → **墨问岐黄**
  - en: Mo Wen Qi Huang
  - ja: 墨問岐黄
- `config/name_localized` 与上同。
- 源：`other-systems/i18n/ui.csv` ↔ `locale/xinglin.csv`；`ui.json` 已对齐。

## 启动页 chrome

- **设置齿轮**（`UiKit.make_settings_gear_button`）右上；语言中/英/日仅在设置 overlay（`UiKit.build_settings_body`）。
- **不再**常驻三颗语言大钮（`locale_bar` 已从 boot 顶栏移除）。
- 会话态：`GameFlow.settings_open`；dimmer 点击 / Esc 关闭。
- 声明勾选 + 进入医馆流程不变。

## 免责键（不改义）

未改：`BOOT_DISCLAIMER_*`、`STORE_NOT_MEDICAL`。

详见：`other-systems/i18n/BOOT-TITLE-V137E.md`
