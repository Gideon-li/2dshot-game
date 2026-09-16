# V135 青石诊案再扩 · 接口锁（expand2）

- **数量**：再 +3 案 +3 病人；旧 7 人保留（共 **10**）；候诊仍 `waiting.max_seats = 4`（A–D 轮换，无 WAIT_E）
- **案 / 人（锁）**：

  | 案 id | 角色 id | 人设（显示名由剧本定） | 立绘建议文件名 |
  | --- | --- | --- | --- |
  | `yangxu_weihan` | `char_danfu` | 老担夫 / 夜市摊主气质 | `ui/characters/han_danfu.png`（别名 `danfu.png` 可） |
  | `xueyu_qing` | `char_bashi` | 跌仆后镇民 / 车把式 | `ui/characters/ma_bashi.png`（别名 `bashi.png`） |
  | `shushi` | `char_jiaoli` | 夏日脚力 / 船工 | `ui/characters/xia_jiaoli.png`（别名 `jiaoli.png`） |

- **规则表**：`slice_logic.json` → `qingshi_expand2_rules`（slice **version 15**）；拆分 `logic/qingshi_expand2.json`
- **证印**：治成（rank ≥ `clear`）写入 `play.seals[]`；本档再亮 3 枚，与 V134 并列共 **6** 枚小印：`fengre_biao` / `shiji` / `pixu_shikun` / `yangxu_weihan` / `xueyu_qing` / `shushi`。不做十二印墙。
- **候诊权重**（量级同 V134）：
  - base：`yangxu_weihan 0.35` / `xueyu_qing 0.35` / `shushi 0.35`
  - 有 `town_permit`：× `with_town_permit_mult 1.8`
  - **无 permit**：锁 `yangxu_weihan_teach_once`（偶遇 1 次阳虚教学，weight≈0.25）；血瘀/暑湿无 permit 各 0.05
- **合法路径（开放解）**：
  1. **阳虚畏寒** `yangxu_weihan`：方 `fuzi+ganjiang+gancao`；`guizhi+ganjiang+dazao/shengjiang`；穴灸 `zusanli` / `guanyuan+zusanli` / `mingmen`（`case_temp_open`）；食姜枣；情志低；**误清泻** mistreat（金银花+连翘 / 知母+黄柏）
  2. **血瘀轻证** `xueyu_qing`：方 `danggui+chuanxiong+baishao`（±`gancao`）；穴 `hegu+sanyinjiao`（临时开）/ `neiguan+taichong`；食温润轻；情志罕主用；**猛破血**/寒清堆 mistreat
  3. **暑湿** `shushi`：方 `huangbai+zexie+fuling+bohe`（±`gancao`）；穴可少用 `zusanli` / `quchi`（临时开）；食轻清粥；**纯燥烈** mistreat（附子+干姜 / 麻黄）
- **新穴**：`guanyuan`（关元；偏灸；`warm_yang`/`tonify_qi`/`restore_yang`；`vol1_selectable:false`；`body_pos` 腹 UV≈{0.5,0.62}）
- **药**：未新增；血瘀靠现池当归川芎白芍；暑湿靠黄柏泽泻茯苓薄荷（未加藿香/红花）
- **穴临时开**：`yangxu_weihan` → `guanyuan`,`mingmen`；`xueyu_qing` → `sanyinjiao`；`shushi` → `quchi`；**不**永久扩 `vol1_open_ids`（仍 `hegu`/`zusanli`）
- **误治短注**：阳虚误清；血瘀猛破；暑湿纯燥
- **冒烟**：`qingshi_expand2_ok`（三新案各 ≥1 合法 settle）+ `SMOKE PASS`
- **SCRIPT**：十人表（旧 7 + 新 3）
- **不做**：阴虚燥咳 / 湿热下注 / 外伤肿痛 / 小儿惊啼；陈半仙、萨米尔、五方、十二墙、J/T、改 Steam
