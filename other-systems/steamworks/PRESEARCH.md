# Steamworks 预研（切片只读，不接排行榜）

查询日期：2026-09-02。引擎按设计默认 Godot 4。

## 结论

| 能力 | 能否做 | 切片 |
| --- | --- | --- |
| 成就 | 能。Steamworks 后台建好并 **Publish** 后，GodotSteam `setAchievement` + `storeStats` | 本期不接代码。只预留 API 名 |
| 排行榜 | 能。`findLeaderboard` / `uploadLeaderboardScore` | **不上**。积分先写本地存档 `scores` |
| 语言 | 能。`getCurrentGameLanguage()`，schinese/english/japanese 映射到 zh/en/ja | 切片用键值表；若 Steam 已初始化，可用它设默认语言 |
| 云存档 | 能（Remote Storage / Steam Cloud） | 不上 |
| Coming Soon | 不需要构建里已接 Steamworks | 切片可录即可准备商店页 |

## 接入建议（给开发负责人，二期再装）

- 插件：[GodotSteam GDExtension 4.4+](https://godotengine.org/asset-library/asset/2445)（Gramps，MIT，2026-08-22 登记；GodotSteam 4.22 / Steamworks SDK 1.65）
- 文档：https://godotsteam.com/tutorials/initializing/ 与 https://godotsteam.com/tutorials/stats_achievements/
- 源码：https://codeberg.org/godotsteam/godotsteam
- 初始化：`Steam.steamInitEx()`。SDK 1.61 起成就/统计在客户端启动时自动同步，不必 `requestCurrentStats`
- 无 Steam 客户端（本地开发）：初始化失败则跳过，游戏仍可玩
- App ID：等 Steam 合作伙伴后台有号再写进项目设置 `Steam > Initialization`。不要把假 App ID 提交进仓库当正式值

## 预留成就 API 名（不要在切片里 set）

后台建表可以并行，**代码不要调用**。

- `PULSE_ONCE` 第一次把到脉
- `FORMULA_ONCE` 第一次开方下手
- `NEEDLE_ONCE` 第一次扎针下手
- `THREE_PATIENTS` 看完切片 3 个病人

排行榜预留名（二期）：`EFFICACY`（只上传疗效总分，不上传诊断名）。切片不要 `findLeaderboard`。

## 商店免责

启动画面与 Steam 页面都要有 not medical advice。文案用 i18n 的 `STORE_NOT_MEDICAL` / `BOOT_DISCLAIMER_*`。
