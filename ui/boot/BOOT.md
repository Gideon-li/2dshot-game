# V137.1 启动页主视觉

对照：`incoming/boot-plain-haopeng-20260924.png`  
锁：`other-systems/UI-BOOT-PORTRAIT-V137.1.md`

| 文件 | 用途 |
| --- | --- |
| `boot_hero.png` | 启动轻量主视觉 1280×720（宣纸/店招/医馆剪影） |
| `boot_sign.png` | 「墨问岐黄」店招牌（可叠在 hero 或单独当标题图） |

标题正式名 **墨问岐黄**（勿主标题杏林墨问）。语言进设置齿轮；免责/进入医馆由角色挂。

## 候诊立绘

复用 `ui/characters/*.png`（含 V126–V136 全池 + 江晚）；本档不缺图。脚底对齐 `scene-slice/PORTRAIT-LAYOUT.md`。

引擎约定路径：`res://ui/chrome/boot_hero.png`（见 `other-systems/BOOT-HERO-V137.md`）；本目录为美工投递位。

## V138 版式注

- 副标题（`GAME_SUBTITLE`）放在 **店招木牌下方**，勿压牌心书法。
- **勿**再叠第二套大号「墨问岐黄」Label；`boot_hero` 木牌即店招。顶栏仅小字标题 + 设置齿轮。
- 声明卡与店招纵向分区，勿 EXPAND 吞牌。详见 `other-systems/BOOT-LAYOUT-V138.md`。
- 交图：`v138_boot.png`（对照 `v137_1_boot.png`）。
