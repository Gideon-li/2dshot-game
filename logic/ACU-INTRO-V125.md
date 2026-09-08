# V125 针灸入门 · 负责人锁（2026-09-08）

## 体图坐标（归一化，相对体图 Control）
沿用 `scenes/acupuncture.gd` `POINT_POS`：
- `hegu` 合谷：`(0.08, 0.46)` — method=`needle`，`teach_vol1=true`
- `zusanli` 足三里：`(0.38, 0.72)` — method=`moxa`，`teach_vol1=true`

## 命中半径（归一化欧氏）
- 穴心 `center_r = 0.025` → 准高
- 经容 `jing_r = 0.055` → 小扣仍可进手法
- `> jing_r` → 出经，提示可重试（不计穴）

## 手法
- 合谷：针 + 得气节奏（切片仅 **平** 一档）；容区内踩中才得气；失败可再试 1 次；短墨晕
- 足三里：灸 + 壮数 3/5/7（默认 5）+ 红晕确认；无得气条

## 会话级识穴（不写长档）
`GameFlow` 本局：`acu_known: Array[String]`、`acu_practiced: Array[String]`  
点中穴心/经容记 known；得气或灸成功记 practiced。

## 结算 / 冒烟
- 仍 `settle("acupuncture", …)`；1～3 穴
- 冒烟键：`acu_intro_smoke_ok`（合谷得气 **或** 足三里灸 → 可提交）
- 侧栏穴位列表默认隐藏；教学锁灰显非 vol1 穴

## 不做
24 穴全开、铜人、补泻三档、情缘、改 Steam、改 LLM/secrets、J/T。
