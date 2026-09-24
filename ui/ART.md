# 切片美术（Q 版可爱水墨）

画风锁：头身比偏圆、表情清楚、淡彩。不是写意文人，不是工笔，不是像素。

| 文件 | 内容 |
| --- | --- |
| `apprentice.png` | 江晚，浅墨学徒袍 |
| `patients-three.png` | 左赵阿福短褐；中沈清荷青灰书办；右周婆婆深褐白发 |
| `formula-tray.png` | 药拖进盘 |
| `ui-clinic.png` | 望闻问切基础 HUD |
| `layers/CAM_PULSE-empty.png` | Steam 前三空镜 |
| `layers/pulse-overlay.png` | 浮紧 / 弦 / 细数 |
| `layers/CAM_HERO.png` | 商店第 1 张 |

HUD 不挂诊断名。建筑分层 L1–L4 下一轮洗萌态。

## V124 炮制

见 `process/PROCESS.md`：院背景、火候/洗涮 UI、杏仁等 raw→processed 图标。


## V126 角色立绘

单人透明底（优先运行时）：见 `characters/README.md`

| 文件 | 角色 |
| --- | --- |
| `characters/jiang_wan.png` | 江晚（学徒锚点；禁止林晚） |
| `characters/zhao_afu.png` | 赵阿福 |
| `characters/shen_qinghe.png` | 沈清荷 |
| `characters/zhou_popo.png` | 周婆婆 |

旧 `apprentice.png` / `patients-three.png` 可作备用与商店构图。

V126.1 画风统一：四立绘同套 2D 明快 Q 平涂（婆婆去 3D；江晚收浅墨学徒袍）。

## V127 复诊

见 `chrome/REVISIT.md`：复诊角标 + 病程色差（good/slow/over/mis）+ 次日开馆牌；不新立绘。

## V128 晒药

见 `process/PROCESS.md`：晒架 `CAM_DRY`、翻晒 UI、工位高亮、mudanpi 生制图标。

## V129 夜读

见 `loft/CODEX.md`：阁楼背景、医典封面/宣纸页、解锁印「识」。

## V130 食疗

见 `food/FOOD.md`：膳盏 UI、ACTION_FOOD、六食材图标、劝说小卡。

## V131 Demo 引导

见 `demo/DEMO-UI.md`：引导条、勾选小印、Day 小牌。

## V132 情志

见 `emotion/EMOTION.md`：疏导 UI、ACTION_EMOTION、六卡图标；复用清荷立绘。

## V133 周绣娘

`characters/zhou_xiuniang.png`（齐 V126.1 平涂）；可选 `props/aiye_pa.png` 艾叶帕。

## V134 青石扩容

三立绘：//；证印 。

## V135 青石再扩

立绘 han_danfu / ma_bashi / xia_jiaoli；证印 yangxu_weihan / xueyu_qing / shushi。

## V136 青石再扩3

立绘 qiu_tanfu / he_tianhan / lu_mujiang（alias tanfu/tianhan/mujiang）；
证印 yinxu_zaoke / shire_xiazhu / waishang_zhongtong；
旧四案印 fenghan_biao / ganyu_qizhi / yinxu_neire / xuexu_ganyu；
九宫印墙 seal_wall_9.png + seal_wall_frame.png。
湿热克制、外伤无血腥。

## V137 诊室 UI 壳

`chrome/settings_gear.png`（+64）+ `chrome/settings_panel.png`；见 `chrome/SETTINGS.md`。少新大图，不抢 V136 立绘/证印。

## V137.1 启动页 · 候诊立绘

`boot/boot_hero.png` + `boot/boot_sign.png`（墨问岐黄店招）；候诊立绘复用 `characters/` 现有池，见 `boot/BOOT.md`。

## V139 布局对照补图

诊室清晰小件：`clinic/props/`（yaohu / maizhen / xianglu，256+128）；见 `clinic/props/README.md`。
江晚坐姿：`characters/jiang_wan_sit.png`（520×700；病患先复用站姿）。
启动暖纸圆角片：`boot/boot_panel_disclaimer.png` + `boot_btn_plate.png` + `boot_check_plate.png`（不做新 CG）；见 `boot/BOOT.md`。
