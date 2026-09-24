# V139 · 启动页温馨圆角（boot warm chrome）

日期：2026-09-24  
锁：`DEV-TASKS-V139.md` §C、`other-systems/UI-LAYOUT-V139.md` §C  
实现：`scripts/ui_kit.gd`、`scenes/main.gd`（设置面板在 `UiKit.build_settings_body`）  
版式仍锁：`other-systems/BOOT-LAYOUT-V138.md`（分区数字不改）

## 问题（V138）

声明卡、勾选、「进入医馆」、设置齿轮偏硬直角，纸边偏冷、偏黑。Haopeng：温馨，少菱角。

## 画片（优先于纯 StyleBox）

美工板已核，用九宫格 `StyleBoxTexture` 当底，不再在画片下再铺一层直角纸盒。角用贴图边距留住，中间拉伸。

| 控件 | 贴图 | 挂法 |
| --- | --- | --- |
| `DisclaimerCard` | `ui/boot/boot_panel_disclaimer.png` | `UiKit.panel_or_plate` → Panel `panel` |
| 「进入医馆」 | `ui/boot/boot_btn_plate.png` | `style_button(..., BOOT_BTN_PLATE)`，先设 220×44 再切片，角不撑出按钮 |
| 设置齿轮 | 同一张按钮板 | `make_settings_gear_button`。40×40 时把切片边距收到控件内；贴图缺失才退回暖纸 |
| 「我已阅读」 | `ui/boot/boot_check_plate.png` | `style_check` 的各状态底。文案键不动 |

贴图缺失时才退回下面的暖纸 `StyleBoxFlat`（声明卡半径 16，按钮/设置面板 14，勾选芯片 12，边 `LINE_SOFT`）。有画片时以画片为准，不再用扁平面的半径去压角。

三张画片已在库内，并带与 `boot_hero.png.import` 相同的 Godot 纹理 sidecar：

- `ui/boot/boot_panel_disclaimer.png`
- `ui/boot/boot_btn_plate.png`
- `ui/boot/boot_check_plate.png`

新检出会直接走九宫格，不再退回扁平方盒。暖纸 `StyleBoxFlat` 只在对应 png 被拿掉时才用。分区数字不改。

## 圆角与颜色（无画片时的退路）

| 控件 | 半径 | 填充 | 边 |
| --- | --- | --- | --- |
| `DisclaimerCard` | `RADIUS_CARD` **16** | `PAPER_WARM` `(0.95, 0.88, 0.74)` | `LINE_SOFT` 暖赭、半透明，不是硬黑 |
| 「进入医馆」/ 设置齿轮 / `style_button` | `RADIUS_SOFT` **14** | 非印：`PAPER_WARM_DEEP` `(0.92, 0.84, 0.70)`；印钮（进入医馆）仍是朱红薄罩 | `LINE_SOFT`；悬停边为暖褐，不再用近黑 `INK` |
| 「我已阅读」`UiKit.style_check` | 芯片 **12** | 暖纸半透明底 | `LINE_SOFT`；图标调制暖墨 / 悬停 `SEAL` |
| 设置 overlay `SettingsPanel` | **14** | `PAPER_WARM` | `LINE_SOFT`（没有单独的设置画片） |

`paper_style` 默认半径 `RADIUS_SOFT`（14），抗锯齿、`corner_detail = 12`。内容边距不推动 V138 分区。

对照：方盘 / 药碗早已用半径 16（`formula.gd` / `food.gd`）。启动壳向那一档靠，而不是新画风。

## 仍沿用 V138（未改）

| 区 | 仍是 |
| --- | --- |
| 顶栏 | 小标题约 17pt `INK_MUTED` + 右上齿轮 |
| 店招净空 | `SignClearance` **y = 300** |
| 副标题 | 牌下居中 `GAME_SUBTITLE` / `SEAL`，其后 10px |
| 声明卡 | 固定带 `custom_minimum_size.y = 180`；正文 Scroll 约 72；**无** `SIZE_EXPAND_FILL` 吞店招 |
| CTA | 「进入医馆」在卡**外**下方 |
| 页脚 | `BOOT_DISCLAIMER_FOOTER` |

免责键义未改：`BOOT_DISCLAIMER_*`、`STORE_NOT_MEDICAL`（csv / 译文未动）。英雄图路径未改。

## 共享 UiKit（锚点不动）

`style_button` 与 `build_settings_body` 是全工程共用。诊室候诊名牌、各场景按钮会一起变圆、略暖；诊室设置弹层与启动页是同一块面板。

**没有改** `clinic.gd` / 立绘锚点 / 病机 / LLM。诊室里写死半径的纸片仍是原值（对话坞 4、顶栏芯片 4、问诊台 4 等）。

## 交图

`ui/boot/v139_boot.png` **留给角色侧在立绘合入后拍**，本切片不挡。沿 `_cap_boot_only.gd` 的 OpenGL3 + 显示路径，输出改到 `res://ui/boot/v139_boot.png`（1280×720，locale `zh`，设置关）。画片已在 `ui/boot/`，截图里应看到声明卡 / 进馆钮 / 勾选的圆角板，而不是纯扁平方盒。

建议合入说明：启动壳优先挂三张九宫格画片，没有文件才退回暖纸圆角；V138 分区与免责文案保持；`v139_boot.png` 等角色帧齐了再拍。

## 不做

诊室 idle、立绘、病机、LLM、新 CG、整页换皮、改声明正文。
