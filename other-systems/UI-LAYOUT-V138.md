# V138 界面布局 · 接口锁

前置：V137 `e8bc1ec` + V137.1 `dfe7b96`。对照：v137_1_boot / v137_1_waiting_portraits / cam_hero。
Haopeng：**立绘过关，布局不过关**。只调锚点/层级/分区，不重画立绘。

## A. 启动页
- 店招完整；副标题（病人不交全症状）**勿压木牌正中** → 牌下或牌侧。
- 声明卡 / 勾选 / 进入医馆纵向分区；声明勿整块吞店招。
- 顶栏小标题与设置对齐；勿两套大标题抢视线。
- 轻量 boot_hero 保留；不做新 CG。

## B. 诊室 idle
- **底图必须诊室场景**（药柜机位）；禁素纸验收截。
- 四人脚底 A–D 散开（PORTRAIT-LAYOUT）；禁挤团漂左上。
- 顶栏：游戏名+日牌+齿轮 → 下为候诊文字牌；旁白不压牌不压人。
- 江晚 (1100,720) **完整入画**。
- NavStrip 与对话/引导不互挡；1280×720 四角安全。
- 点凳/立绘/牌可开诊。

## C. 回归
- V137 设置/滚底/去叠不回退。

## D. 冒烟与交图
- `ui_layout_ok`（或扩 boot_portrait）：启动无叠字；idle 有诊室底图；≥3 席中心 x 间距合理；学徒全在视口。
- 交图：`ui/boot/v138_boot.png`、`ui/waiting/v138_idle.png`（全 HUD）。

## 逻辑侧（V138）

- **病机 / cases / seals / 候诊权重：不动。**
- 布局锚点与机位属 UI/原型；逻辑无新 evaluate 路径。
- 冒烟 `ui_layout_ok` 归角色侧。

## 其他要素·A（启动页挂壳）

- 版式说明：`other-systems/BOOT-LAYOUT-V138.md`（顶栏 / 店招净空≈300 / 副标题牌下 / 声明卡中下 / CTA）。
- 代码：`scenes/main.gd` `_build()` — 小标题+齿轮顶栏；`SignClearance` y=300；无第二套大号店招 Label；声明卡固定带（勿 EXPAND 吞店招）。
- 副标题键位注：`other-systems/i18n/BOOT-SUBTITLE-LAYOUT-V138.md`（文案不改义）。