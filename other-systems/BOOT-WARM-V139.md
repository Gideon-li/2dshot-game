# V139 · 启动页温馨圆角（boot warm chrome）

日期：2026-09-24  
锁：`DEV-TASKS-V139.md` §C、`other-systems/UI-LAYOUT-V139.md` §C  
实现：`scripts/ui_kit.gd`、`scenes/main.gd`（设置面板在 `UiKit.build_settings_body`）  
版式仍锁：`other-systems/BOOT-LAYOUT-V138.md`（分区数字不改）

## 问题（V138）

声明卡、勾选、「进入医馆」、设置齿轮偏硬直角，纸边偏冷、偏黑。Haopeng：温馨，少菱角。

## 圆角与颜色

| 控件 | 半径 | 填充 | 边 |
| --- | --- | --- | --- |
| `DisclaimerCard` | `RADIUS_CARD` **16** | `PAPER_WARM` `(0.95, 0.88, 0.74)` | `LINE_SOFT` 暖赭、半透明，不是硬黑 |
| 「进入医馆」/ 设置齿轮 / `style_button` | `RADIUS_SOFT` **14** | 非印：`PAPER_WARM_DEEP` `(0.92, 0.84, 0.70)`；印钮（进入医馆）仍是朱红薄罩，略提高不透明度以便圆角可读 | `LINE_SOFT`；悬停边为暖褐，不再用近黑 `INK` |
| 「我已阅读」`UiKit.style_check` | 芯片 **12** | 暖纸半透明底（勾选/悬停略深） | `LINE_SOFT`；图标调制暖墨 / 悬停 `SEAL` |
| 设置 overlay `SettingsPanel` | **14** | `PAPER_WARM` | `LINE_SOFT` |

`paper_style` 默认半径从 4 提到 `RADIUS_SOFT`（14），并打开抗锯齿、`corner_detail = 12`，角更软。内容边距未改，不推动分区。

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

`ui/boot/v139_boot.png` **本切片未交**。仓库里没有 `tools/godot43`。另起的 Godot 4.3 + OpenGL3（llvmpipe）在创建上下文后卡住，没有写出 png。角色侧在立绘合入后，沿 `_cap_boot_only.gd` 的 OpenGL3 + 显示路径，把输出改到 `res://ui/boot/v139_boot.png` 再拍（1280×720，locale `zh`，设置关）。

建议合入说明：启动壳只动圆角与暖纸；V138 分区与免责文案保持；截图在角色帧齐了之后打 `ui/boot/v139_boot.png`。

## 不做

诊室 idle、立绘、病机、LLM、新 CG、整页换皮、改声明正文。
