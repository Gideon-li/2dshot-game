# V137E · 启动标题对齐 + 免责未改

日期：2026-09-24

## 标题对齐（GAME_TITLE ≡ STORE_TITLE ≡ config.name）

| 键 / 配置 | zh | en | ja |
| --- | --- | --- | --- |
| `GAME_TITLE`（旧） | 杏林墨问 | Xinglin Mowen | 杏林墨問 |
| `GAME_TITLE`（新） | 墨问岐黄 | Mo Wen Qi Huang | 墨問岐黄 |
| `STORE_TITLE` | 墨问岐黄 | Mo Wen Qi Huang | 墨問岐黄 |
| `application/config/name` | 墨问岐黄 | — | — |
| `config/name_localized` | — | Mo Wen Qi Huang | 墨問岐黄 |

触达文件：`other-systems/i18n/ui.csv`、`locale/xinglin.csv`、`other-systems/i18n/ui.json`、`project.godot`。

## 免责未改义

下列键文案**未改**：

- `BOOT_DISCLAIMER_TITLE`
- `BOOT_DISCLAIMER_BODY`
- `BOOT_DISCLAIMER_CHECK`
- `BOOT_DISCLAIMER_ACCEPT`
- `BOOT_DISCLAIMER_FOOTER`
- `STORE_NOT_MEDICAL`

## Boot 行为（摘要）

- 标题：`UiKit.store_title_text()`（STORE_TITLE → GAME_TITLE → 墨问岐黄）
- 语言进设置齿轮；轻量主视觉路径见 `other-systems/BOOT-HERO-V137.md`
