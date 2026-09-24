# V136 青石诊案再扩 · 接口锁（expand3 · 除小儿）

- **数量**：再 +3 案 +3 病人；旧 10 人保留（共 **13**）；候诊仍 `waiting.max_seats = 4`（A–D，无 WAIT_E）
- **案 / 人（锁）**：

  | 案 id | 角色 id | 人设（显示名由剧本定） | 立绘建议 |
  | --- | --- | --- | --- |
  | `yinxu_zaoke` | `char_tanfu` | 秋日抄书 / 卖炭妇气质（肺燥咳；**≠**周婆婆 `yinxu_neire`） | `ui/characters/qiu_tanfu.png`（别名 `tanfu.png`） |
  | `shire_xiazhu` | `char_tianhan` | 田埂劳作 / 脚气困扰镇民（**文案克制**，无暴露） | `ui/characters/he_tianhan.png`（别名 `tianhan.png`） |
  | `waishang_zhongtong` | `char_mujiang` | 跌仆木匠 / 码头碰伤（轻证；**无血腥**） | `ui/characters/lu_mujiang.png`（别名 `mujiang.png`） |

- **规则表**：`slice_logic.json` → `qingshi_expand3_rules`（slice **version 16**）；拆分 `logic/qingshi_expand3.json`
- **证印 / 印墙（定稿）**：
  - 本档再亮 3 枚：`yinxu_zaoke` / `shire_xiazhu` / `waishang_zhongtong`（与 V134/135 共 **9** 枚 expand 小印）
  - **旧四案** settle≥clear 亦写入 `play.seals[]`：`fenghan_biao` / `ganyu_qizhi` / `yinxu_neire` / `xuexu_ganyu`
  - **阴虚内热与阴虚燥咳分两印**（勿合并）
  - UI：九宫或列表「青石证印」；`seal_wall_ids` 可列满 13；**不设小儿格**；不做血腥外伤印面
- **候诊权重**（量级同前）：
  - base：各新案 0.35；`town_permit` ×1.8
  - **无 permit**：锁 `yinxu_zaoke_teach_once`（偶遇 1 次燥咳教学 ≈0.25）；湿热/外伤无 permit 各 0.05
- **合法路径（开放解）**：
  1. **阴虚燥咳** `yinxu_zaoke`：方 `maidong+shudi+gancao` / `zhimu+shudi+maidong+gancao`；穴 `taixi` / `taixi+lieque`（`case_temp_open`）；食冰糖粥/莲粥；**≠**内热六味/知柏；误苦寒堆或麻黄 → mistreat
  2. **湿热下注** `shire_xiazhu`：方 `huangbai+zexie+fuling`（±`yiyiren`）；穴 `sanyinjiao` 临时开、`zusanli` 可选；食清淡；误附姜温补 → mistreat；文案克制
  3. **外伤肿痛** `waishang_zhongtong`：方 `danggui+chuanxiong+baishao`（±`gancao`）；穴 `hegu` / `neiguan` 轻（`case_temp_open` 空）；情志 `warm_calm`/`vent_rest` 辅；误寒清猛破 → mistreat；无血腥
- **新药**：`maidong`（润肺阴；不采）；`yiyiren`（清利可选；不采）
- **穴临时开**：`yinxu_zaoke` → `taixi`,`lieque`；`shire_xiazhu` → `sanyinjiao`；`waishang_zhongtong` → `[]`；**不**永久扩 `vol1_open_ids`（仍 `hegu`/`zusanli`）
- **误治短注**：燥咳当内热苦寒 / 湿热温补 / 外伤猛破
- **区分**：`distinguish_note.yinxu_zaoke_vs_yinxu_neire`
- **冒烟**：`qingshi_expand3_ok`（三新案各 ≥1 合法 settle）+ 既有 expand/expand2 不回退 + `SMOKE PASS`
- **SCRIPT**：十三人表（旧 10 + 新 3）
- **不做**：小儿惊啼、陈半仙、萨米尔、五方、情缘、血腥/暴露、J/T、改 Steam；案 id 禁止 `shire_xiaZhu` 错写
