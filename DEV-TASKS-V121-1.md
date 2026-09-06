# 《墨问岐黄》V121.1 — 缺味立绘对齐白名单

日期：2026-09-06  
下发：全局统筹 → 开发负责人  
前置：V121 已验收 `906a79b`

## 问题

- 药圃图集 `ui/forage/herb-icons-12.png` / `herb-clusters-12.png` 按 12 味排格。
- `logic/slice_logic.json` 里仍有多味 `forage: true`（杏仁、薄荷等），不在图集 → **色块兜底**。
- `forage_herbs.json` 指向不存在的 `res://ui/herbs/{id}.png`（目录甚至没有）。

白名单（唯一）：  
`guizhi, baishao, shengjiang, gancao, chaihu, danggui, baizhu, fuling, mahuang, dazao, mudanpi, shudi`  
（与 `scenes/garden.gd` 的 `ICON_ATLAS_ORDER` 一致）

## 目标

运行时 **只有这 12 味** 可认可采；开方托盘与药圃都显示图集立绘，不再对白名单掉色块。

## 完成标准

1. `Forage.forage_enabled_ids()`（或等价）恰好 12 个，等于上表。
2. 非白名单味：`forage` 关掉或不可进药圃。
3. 从 atlas 切出（或重导出）`ui/herbs/{id}.png` 共 12 张，托盘/药圃都读得到。
4. 手操或冒烟：白名单 12 味图标均非 ColorRect；任选非白名单味不会出现在药圃列表。
5. 推 main；secrets 不进库。

## 分工

- **逻辑**：白名单锁死；改 slice_logic / forage 启用列表。
- **美工**：确认 atlas 12 格与白名单一一对应；缺/糊的格重画；导出单张 `ui/herbs/`。
- **角色开发**：托盘与药圃统一读 atlas 或 `ui/herbs`；去掉白名单上的色块路径。
- **剧本**：白名单文案已齐则只核对 id，不扩味。

## 不做

不加第 13 味、不开五方、不改玩法。

回我：commit + 一张药圃截图证明无色块。
