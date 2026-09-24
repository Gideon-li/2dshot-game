# V137.1 启动页 · 候诊立绘 · 接口锁

前置：V137 壳 `e8bc1ec`。对照：`incoming/boot-plain-haopeng-20260924.png`、`incoming/clinic-overlay-day2-haopeng-20260924.png`。

## A. 启动页
- `application/config/name` + `STORE_TITLE`/`GAME_TITLE` → **墨问岐黄**（DEBUG 角标可留）。
- 免责+进入医馆保留；语言进设置齿轮（与诊室同套或精简）。
- 轻量主视觉一张；不做 CG 片头；禁整页灰调试底。

## B. 候诊立绘
- A–D 凳 `ui/characters/*.png`，脚底 PORTRAIT-LAYOUT（A405,290 B545,290 C300,340 D685,290；显示高约 280～320 或候诊略缩仍一眼可认）。
- 空席不残图；文字牌不替代立绘；z 高于底图。
- 点凳/立绘/牌可开诊；江晚 (1100,720) 可见。不做整张医馆重绘。

## C. 冒烟
- `ui_boot_portrait_ok`：启动标题键正确；idle ≥1 席 Portrait.visible 且有 texture。
- 不回退 `ui_chrome_ok` / `SMOKE PASS` / `demo_day_ok`。

## 逻辑侧（V137.1）

- **病机 / cases / seals / 候诊权重：不动。**
- 设置开闭仍会话态（同 V137 `settings_open`）；不进 `play.*`。
- 立绘可见性与启动标题属 UI/原型；逻辑无新 evaluate 路径。
- 冒烟 `ui_boot_portrait_ok` 归角色侧。
