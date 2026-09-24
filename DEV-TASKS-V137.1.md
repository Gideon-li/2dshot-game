# 《墨问岐黄》开发任务 V137.1（启动页正式化 · 候诊立绘可见）

日期：2026-09-24  
下发：全局统筹 → 开发负责人 → 小组  
前置：V137 壳已合 main（`e8bc1ec`：设置/去叠/滚底/NavStrip）  
缺口：扩范围 E/F 未进本提交；Haopeng 手操仍见素纸启动页、诊室几乎看不到凳上立绘。

## 目标

1. **启动页正式化** — 墨问岐黄店招感；语言进设置；勿整页调试素纸。  
2. **候诊立绘必须看得见** — 凳上 Q 版立绘一眼可认，文字牌不能替代。

## 范围（锁死）

### A. 启动页（对照 `incoming/boot-plain-haopeng-20260924.png`）

- `application/config/name` + `STORE_TITLE`/`GAME_TITLE` → **墨问岐黄**（DEBUG 角标可留）。  
- 免责声明 + 进入医馆保留；语言三钮改为设置齿轮（与诊室同一套 overlay 或精简版）。  
- 轻量主视觉（纸纹/剪影/店招）即可；**不做**完整 CG 片头。

### B. 候诊立绘（对照 `incoming/clinic-overlay-day2-haopeng-20260924.png`）

- `_apply_portraits`：A–D 凳显示对应 `ui/characters/*.png`，脚底对齐 `PORTRAIT-LAYOUT.md`；缩放足够大（显示高约 280～320 或候诊略小但仍一眼可认）。  
- z 序高于底图；不被顶栏/对话整块盖死。  
- 点凳/立绘/牌均可开诊。江晚学徒锚点确认可见。  
- **不做**整张 Q 版医馆重绘。

### C. 冒烟

- 扩展或新增：`ui_boot_portrait_ok`（启动标题键正确；idle 时 ≥1 席 Portrait.visible 且有 texture）。  
- `ui_chrome_ok` / 既有 smoke 不回退。

## 完成标准

启动页一帧 + 诊室空闲同机位能看见凳上立绘 + commit。secrets 不进库。

## 回我

启动/立绘对照截 + 冒烟标签 + commit。
