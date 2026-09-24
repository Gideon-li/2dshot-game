# 《墨问岐黄》切片剧本（v1.19）

工作名：墨问岐黄（旧称杏林墨问）。  
给角色开发直接读：`slice_characters.json`（v6 / V120）  
病机表仍以 `logic/slice_logic.json` 为准。

不是题库。病人不交全症状。HUD 上不出现诊断名。苏问舟、小荷本期 **不可点**。问舟只旁白；小荷只作 UI 口吻占位。

## 学徒、师父、药童

| id | 人 | 说明 |
| --- | --- | --- |
| `apprentice_jiang` | **江晚**（产品默认；可改名） | 16，坐堂学徒。切片不成长。浅墨，不抢病人。立绘/锚点一律江晚。 |
| `mentor_su` | **苏问舟** | 52，杏林小筑主人。`clickable: false`。只旁白/UI 键值，不进病人席、不做可点师傅 HUD。 |
| `pharmacy_kid_xiaohe` | **小荷** | 12，药童。`clickable: false`。切片只作 UI 口吻占位（候诊/药柜），不进病人席、不代诊。 |

**命名更正：** 产品默认学徒是 **江晚**，不是「林晚为主、可改名江晚」。旧稿「林晚」/`apprentice_lin` 只写在 JSON `legacy_ids` / note 里做兼容，不上屏、不进立绘需求。

苏问舟规则（见 JSON `mentor.rules` / `never_say`）：

- 旁白是 **疑问句**，不报方、不报证、不报标准诊断名。
- 只催没问到的十问 / 缺的望闻切；问全了就喝茶。
- 同一诊最多两句。补上后短肯定：「这一问有了。」

三案各 10 条问舟边界：`mentor.case_cues.<case_id>.lines`（中英日）。缺诊催句：`mentor.exam_missing_cues`。

## 十三张病人身份包

| id | 人 | 年龄 / 身份 / 地域 | 原型语气 | 本局病机（内部） | 求医动机 |
| --- | --- | --- | --- | --- | --- |
| `char_porter` | 赵阿福 | 34 / 码头脚夫 / 江南水乡 | 樵夫脚夫 | `fenghan_biao` | 夜里江风灌进来，明天还要扛货 |
| `char_clerk` | 沈清荷 | 27 / 县衙书办 / 江南县城 | 书生账房 | `ganyu_qizhi` | 案牍堆着，夜里睡不实，求一口气顺 |
| `char_copyist` | 周婆婆 | 61 / 抄经香铺老人 / 内陆小镇 | 老人 | `yinxu_neire` | 夜里抄经眼干喉干，想睡安一点好继续写 |
| `char_xiuniang` | **周绣娘** | 28 / 绣坊主事 / 青石镇 | 绣娘织妇 | `xuexu_ganyu` | 睡不好、头沉；活做到一半针停在手里 |
| `char_zoufan` | **刘禾青** | 17 / 镇口走贩 / 青石镇 | 走贩少年 | `fengre_biao` | 嗓子火、头热，货还要往镇里送 |
| `char_yanhou` | **顾宴余** | 42 / 宴后熟人 / 青石镇 | 市井熟人 | `shiji` | 席上吃猛了，脘胀嗳气不想动 |
| `char_yaoqin` | **林阿婶** | 48 / 药农亲友 / 青石镇外 | 药圃亲眷 | `pixu_shikun` | 困重纳差，求一口能吃的粥气 |
| `char_danfu` | **韩担夫** | 55 / 老担夫·夜市摊 / 青石镇 | 担夫摊主 | `yangxu_weihan` | 天不冷也蜷，手脚凉，想偎炉 |
| `char_bashi` | **马把式** | 38 / 车把式 / 青石镇 | 跌仆镇民 | `xueyu_qing` | 跌处刺痛固定、色暗 |
| `char_jiaoli` | **夏脚力** | 29 / 夏日脚力·船工 / 青石码头 | 奔走脚力 | `shushi` | 身热汗粘，困痞 |
| `char_tanfu` | **秋炭妇** | 46 / 秋日卖炭·抄书 / 青石镇 | 卖炭妇 | `yinxu_zaoke` | 干咳少痰咽干，秋风更咳 |
| `char_tianhan` | **何田汉** | 40 / 田埂劳作 / 青石镇外 | 田作镇民 | `shire_xiazhu` | 下边困热发沉（文案克制） |
| `char_mujiang` | **陆木匠** | 35 / 木匠·码头碰伤 / 青石镇 | 跌仆木匠 | `waishang_zhongtong` | 碰处青肿胀痛（无血腥） |

每人含：`personality` / `voice` / `motive` / `taboos` / `conceal` / `opening` / `ask_wrappers` / `dodge` / `pathogenesis_notes`。

### V133 周绣娘要点

- 表面头痛失眠；**忌日真句**需问到因/情志类才给（胸口如压绣架）；永不主动报证型名。
- 信任 `play.trust.xiuniang`：夸绣/不问女儿私 → 升；当着「女儿」追问私 → 降。
- 合法开放解：酸枣仁汤思路 / 神门·三阴交 / 情志起居（忌日前勿急绣、留灯勿独熬）/ 枣莲粥慢温；抓住郁或血虚一面并护胃即可。
- 达标 settle → `play.flags.town_permit` + 问舟旁白；**不做**出镇旅行、情缘、女儿高热同诊。
- i18n：`other-systems/i18n/XIUNIANG-KEYS.md`。

### V134 青石扩容（+3）

| 案 id | 角色 id | 人 | 教学 |
| --- | --- | --- | --- |
| `fengre_biao` | `char_zoufan` | 刘禾青 | 与阿福风寒对照；勿大补 |
| `shiji` | `char_yanhou` | 顾宴余 | 问饮食；勿峻下；勿上陆衡抢案 |
| `pixu_shikun` | `char_yaoqin` | 林阿婶 | 困重纳差；健脾化湿 / 粥养 |

- 证印：`play.seals[]` 亮对应三枚；不做十二印墙。
- 候诊最多四席轮换；`town_permit` 后新案权重升高；无 permit 也可偶遇食积教学。
- i18n：`other-systems/i18n/QINGSHI-EXPAND-KEYS.md`。

### V135 青石再扩（+3 → 共 10 人 / 6 印）

| 案 id | 角色 id | 人 | 教学 |
| --- | --- | --- | --- |
| `yangxu_weihan` | `char_danfu` | 韩担夫 | 畏寒肢冷；勿清泻；灸关元/足三里类可案开 |
| `xueyu_qing` | `char_bashi` | 马把式 | 刺痛固定；轻活血；勿猛破血 |
| `shushi` | `char_jiaoli` | 夏脚力 | 暑湿困痞；清暑化湿；勿纯燥烈 |

- 证印共 6 枚（V134 三 + 本档三）；不做十二墙。
- 无 permit：偶遇阳虚教学 1 次；血瘀/暑湿权重极低。
- i18n：`other-systems/i18n/QINGSHI-EXPAND2-KEYS.md`；锁：`logic/QINGSHI-EXPAND2-V135.md`。

### V136 青石再扩（+3 → 共 13 人 / 9 印 · 除小儿）

| 案 id | 角色 id | 人 | 教学 |
| --- | --- | --- | --- |
| `yinxu_zaoke` | `char_tanfu` | 秋炭妇 | 肺燥咳；≠周婆婆内热；勿苦寒过剂 |
| `shire_xiazhu` | `char_tianhan` | 何田汉 | 湿热下重；文案克制无暴露；勿纯温补 |
| `waishang_zhongtong` | `char_mujiang` | 陆木匠 | 局部青肿轻证；无血腥；勿猛破 |

- 证印 9 枚（含旧四案风寒/气郁/阴虚内热/血虚肝郁 + expand 六类中本档三新）；阴虚内热与燥咳分两印；**不设小儿格**。
- 无 permit：偶遇燥咳教学 1 次。
- i18n：`QINGSHI-EXPAND3-KEYS.md`；锁：`logic/QINGSHI-EXPAND3-V136.md`。




## 问诊边界（病人 + 本地模型 / 远程开发 / 离线回退）

1. **不得主动报诊断名。** 禁止说各案 `never_say`。追问病名走 `dodge`。
2. **每次措辞不同，咬住症状。** 只从 `inquiry_anchor` 取 1–2 条，用生活词说。
3. **人设改说法，不改病机。** 阿福：江风扛货；清荷：案牍叹气；婆婆：抄经香火。
4. **求医动机是人设，不是题干。**
5. **开场用 `opening`。** 不交症状清单。
6. **苏问舟不替病人说话，也不报答案。**

问诊锚（内部，与逻辑表一致）：

- 阿福：怕冷比发热明显、身酸、汗出不来、涕清、刚受了风
- 清荷：胸胁闷、叹口气好一点、吃不下、睡不实、心里不顺
- 婆婆：手足心热、盗汗、喉干、难睡、下午更烦

API / 本地模型失败或无网：`ask_wrappers` 套锚。`{sym}` 只填锚，不填诊断名。

**V122：** 问诊可在无网时使用本地回复（成品默认本地轻量模型；开发可用远程接口；任何后端失败走模板）。**不改** `inquiry_anchor` / `never_say`。

## 给其他组

- **角色开发**：病人仍读 `patients`；问舟旁白读 `mentor.case_cues` / `exam_missing_cues`；`mentor.clickable == false`；学徒 id `apprentice_jiang`。
- **其他要素**：i18n 占位键见 `mentor.i18n_keys_hint`（十问条、反畏锁定、苏问舟旁白）。
- **美工**：外形见各卡 `art_hint`；学徒立绘/锚点画 **江晚**，不要画回林晚；苏问舟本期可不进立绘热区；小荷不可点。

## V120 增补

- 问舟 `exam_missing_cues` / `case_cues`：**中英日每条皆疑问句**，不报诊断名/方名。
- 小荷 `ui_lines.waiting` / `cabinet` 各 ≥3 句短口吻（仍不可点、不代诊）。
- 回访：每人/每案一句，见 `patients[].followup` 与 `followup_by_case`（本地模板，不必接 LLM）。

## V121 认药 / 采药文案

路径：`patients/forage_script.json`

- 12 味生活观察线索（中英日，每味 3 条）：桂枝、麻黄、生姜、白芍、甘草、大枣、柴胡、当归、白术、茯苓、熟地、牡丹皮。
- 认错反馈：总表 `wrong_identify_feedback` + 每味 `wrong_feedback`。
- 阿桂含糊提示 3 句：`agui.hints`（门槛旁白，不可点）。
- 苏问舟可复用一句：`mentor_su_line`——「药还认不准，先别碰人……」
- 线索写形色气味触感，**不写标准诊断/方名**。

## V122 问诊后端说明（剧本侧）

问诊可在无网时使用本地回复。锚点与人设文案不改；角色开发按 provider（local / remote / offline）切换，offline 仍咬本文件问诊边界。

## V124 炮制文案

路径：`patients/process_script.json`（v2，对齐逻辑白芍炒）

- 教学锁：**杏仁洗** + **白芍炒** + **牡丹皮晒**（V128）；附子可选教学警告关；生姜炒为备用。
- 苏问舟 3 句 + 生药拦截句；小荷 2 句 + 晒架提示。
- 教学 / 警告 / 成败（妥·勉强·再试）中英日；页脚复用 `STORE_NOT_MEDICAL`。
- **不写**真实克数；**不写**可替代就医；附子警告须带文化游戏声明。

## V125 针灸入门文案（补交）

路径：`patients/acu_intro_script.json`

- 卷一锁：**合谷 hegu = 针 + 得气平**；**足三里 zusanli = 灸 + 壮数 3/5/7（默认 5）**。
- 苏问舟 3 句；教学/成败中英日；可选怕针一句。
- 声明复用 `STORE_NOT_MEDICAL`。**不写**现实进针操作。

## V127 复诊日循环文案

路径：`patients/revisit_script.json`（并写入 `slice_characters.json` → `revisit_lines`）

- 三案 × 4 flavor（`good|slow|over|mis`）复诊主诉，中英日；不报诊断名。
- 角标「复诊」、观察勿药收工句、可选问舟一句疑问旁白。
- **不接 LLM**；本地模板即可玩。

## V128 晒药（牡丹皮）

路径：`patients/process_script.json` v3

- 教学锁加 **牡丹皮 `mudanpi` = 晒**：薄片摊晒、翻面 2～3 次、日照条；生片不入盏。
- 教学/警告/妥·勉强·再试 + 翻面提示；小荷/问舟晒药短句（中英日）。
- 仍不写真实日照时数与克数。

## V129 夜读医典

路径：`patients/codex_script.json`（与 `scripts/codex.gd` 同 schema）

- 三页短 id：`hanre_xushi` / `tenq_song` / `pulse_names`（字段 `theory` → `theory.*`）；正文优先 i18n `*_key`。
- 问舟：`mentor_su.loft_lines`（中英日）。页脚复用 `STORE_NOT_MEDICAL` / `BOOT_DISCLAIMER_*`。
- 不写方药医嘱、不报诊断名。

## V130 食疗入门

路径：`patients/food_script.json`（与 i18n `FOOD_*` / `MENTOR_FOOD_*` 对齐）

- 6 卡：`zhou_di` / `hongzao` / `lianzi` / `shanyao` / `shengjiang` / `bingtang`（名+短描述，中英日 + `*_key`）
- 3 劝说：`less_worry` / `rest_wind` / `no_late_lunch`（标签+句）
- 结算口味：`FOOD_SETTLE_*`；问舟主句 `MENTOR_FOOD_1`「先养胃气」
- 声明复用 `STORE_NOT_MEDICAL`。不写替代就医、不写疗效承诺。

## V131 Demo 日环引导

路径：`patients/demo_script.json`（与 i18n `DEMO_*` 对齐）

- 6 步：晨诊处治 / 午后药圃 / 黄昏炮制 / 夜读医典 / 次日开馆 / 复诊收工（中英日 + `DEMO_STEP_*`）
- 结算下一跳：`DEMO_NEXT_GARDEN|PROCESS|LOFT|NEXT_DAY|REVISIT|REST`
- 不问诊剧透证型；声明复用。

## V132 情志疏导入门

路径：`patients/emotion_script.json`（逻辑 `options_ref`；与 i18n `COUNSEL_*` / `EMOTION_*` 对齐）

- 三拍：倾听 3 选 1（`listen_desk_night`=`anchor`，`listen_flank`=`off`，`listen_cheer_up`=`bad`）→ 6 卡 → 可选收束
- 6 卡 id：`walk_ease` / `less_desk` / `vent_rest` / `warm_calm` / `no_scold` / `no_harsh_tonify`
- 清荷 `COUNSEL_QINGHE_1..3`；问舟主句 `MENTOR_EMOTION_1`
- 不写替代就医、不点破证型名、不做情缘；周绣娘已为第四病人（V133），女儿高热案仍不做。

剧本交付：
- `patients/slice_characters.json` v8 → `char_xiuniang`（opening/wrappers/dodge/忌日真句/mentor/复诊）
- `patients/xiuniang_script.json` → 忌日/出镇旁白/专属卡索引
- `patients/emotion_script.json` → `no_rush_embroider` / `leave_lamp_on`（键映射 COUNSEL_NO_RUSH_EMBROIDERY_* / COUNSEL_LAMP_COMPANY_*）
- `patients/revisit_script.json` → `xuexu_ganyu` 四 flavor

## V134 青石诊案扩容

剧本交付：
- `slice_characters.json` v9 → `char_zoufan`/`fengre_biao`、`char_yanhou`/`shiji`、`char_yaoqin`/`pixu_shikun`
- `qingshi_expand_script.json` → 证印闪句 SEAL_* + 案提示
- `revisit_script.json` → 三案四 flavor
- 对话不报证型名；证印为类目标记（SEAL_HINT）。不做陈半仙/萨米尔/小儿。

## V135 再补三类青石证印

十人表：旧 7 + `char_danfu`/`yangxu_weihan`（韩担夫）、`char_bashi`/`xueyu_qing`（马把式）、`char_jiaoli`/`shushi`（夏脚力）。

剧本交付：
- `slice_characters.json` v10
- `qingshi_expand2_script.json` → 三新证印闪句
- `revisit_script.json` → 三案四 flavor
- 对话不报证型名；seals 共 6 枚。不做阴虚燥咳/湿热下注/外伤/小儿/陈半仙/萨米尔。

## V136 补齐剩余青石证印（除小儿）

十三人表：旧 10 + `char_tanfu`/`yinxu_zaoke`（秋炭妇）、`char_tianhan`/`shire_xiazhu`（何田汉）、`char_mujiang`/`waishang_zhongtong`（陆木匠）。

- 燥咳 ≠ 周婆婆阴虚内热（分印）。
- 湿热文案克制、无暴露；外伤只青肿、无血腥。
- 交付：`slice_characters.json` v11、`qingshi_expand3_script.json`、`revisit_script.json` 三案四 flavor。
