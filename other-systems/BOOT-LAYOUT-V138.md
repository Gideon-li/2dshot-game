# V138 · 启动页版式分区（boot layout）

日期：2026-09-24  
锁：`DEV-TASKS-V138.md` §A、`other-systems/UI-LAYOUT-V138.md` §A  
实现：`scenes/main.gd` `_build()`  
对照：`ui/boot/v137_1_boot.png` → `ui/boot/v138_boot.png`

## 问题（V137.1）

- 大号 Label「墨问岐黄」与 `boot_hero` 木牌店招重复抢视线。
- 朱红副标题「病人不交全症状」压在木牌正中书法上。
- 声明 Panel `SIZE_EXPAND_FILL` 上扩，吞掉店招下沿。
- 设置齿轮须保留（右上）。

## 纵向分区（1280×720）

| 区 | 内容 | 约定 |
| --- | --- | --- |
| **顶栏** | HBox：左小标题 + 右设置齿轮 | 小标题 `UiKit.store_title_text()`，约 17pt、`INK_MUTED`；齿轮 `UiKit.make_settings_gear_button()`（仍走 `res://ui/chrome/settings_gear_64.png` → `settings_gear.png`）。**勿**再挂 48pt 大标题。 |
| **店招净空** | `SignClearance` Control | `custom_minimum_size.y = 300`（对照 plaque ~y137–366；可 280–320 微调）。`boot_hero` 木牌完整可见；**不**再画第二套大号「墨问岐黄」。hero 有店招艺术时，艺术即店招。 |
| **副标题** | `_sub` ← `GAME_SUBTITLE` | 牌下居中，`SEAL`，约 19pt。其后 10px 小间距。 |
| **声明卡** | Panel：DiscTitle + body + checkbox (+ need) | **禁止**用会吞店招的 `SIZE_EXPAND_FILL`。固定/收缩带：`custom_minimum_size.y = 180`；正文 `ScrollContainer` 限高约 72。落在中下带。 |
| **CTA** | 「进入医馆」`START_CLINIC` | 在声明卡**下方**（卡外）。 |
| **页脚** | `BOOT_DISCLAIMER_FOOTER` | CTA 之下。 |

竖向读序：**店招 → 副标题 → 声明卡 → 进入医馆 → footer**。

## 保留不动

- 设置 overlay / Esc / `locale_changed` / 进诊室流程。
- `_setup_boot_bg()` hero 路径：`ui/chrome/boot_hero.png` → `ui/boot/boot_hero.png` → `L0-paper.png`。
- 免责键义：**不改** `BOOT_DISCLAIMER_*`、`STORE_NOT_MEDICAL`。
- 默认不叠 `boot_sign.png`（hero 已含店招）；仅当需澄清且隐藏文字大标题时才考虑单独店招图。

## 交图

- `ui/boot/v138_boot.png`（OpenGL3 / Xvfb 截取成功；像素核对：SEAL 副标题 y≈400+，不再落在牌心 y200–240）。

## 不做

诊室 idle（§B）、新 CG、改声明正文、改 clinic/立绘。
