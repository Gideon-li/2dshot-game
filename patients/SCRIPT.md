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

## 三张病人身份包

| id | 人 | 年龄 / 身份 / 地域 | 原型语气 | 本局病机（内部） | 求医动机 |
| --- | --- | --- | --- | --- | --- |
| `char_porter` | 赵阿福 | 34 / 码头脚夫 / 江南水乡 | 樵夫脚夫 | `fenghan_biao` | 夜里江风灌进来，明天还要扛货 |
| `char_clerk` | 沈清荷 | 27 / 县衙书办 / 江南县城 | 书生账房 | `ganyu_qizhi` | 案牍堆着，夜里睡不实，求一口气顺 |
| `char_copyist` | 周婆婆 | 61 / 抄经香铺老人 / 内陆小镇 | 老人 | `yinxu_neire` | 夜里抄经眼干喉干，想睡安一点好继续写 |

每人含：`personality` / `voice` / `motive` / `taboos` / `conceal` / `opening` / `ask_wrappers` / `dodge` / `pathogenesis_notes`。

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
