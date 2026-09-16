# V134 青石镇诊案扩容 · 接口锁

- **数量**：正好 +3 案 +3 病人；旧四人保留（共 7）
- **案 / 人（锁）**：

  | 案 id | 角色 id | 人设 |
  | --- | --- | --- |
  | `fengre_biao` | `char_zoufan` | 镇口走贩少年 |
  | `shiji` | `char_yanhou` | 宴后熟人（勿上陆衡抢案） |
  | `pixu_shikun` | `char_yaoqin` | 药农亲友市井 |

- **规则表**：`slice_logic.json` → `qingshi_expand_rules`（version **14**）；拆分 `logic/qingshi_expand.json`
- **证印**：治成（rank ≥ `clear`）写入 `play.seals[]`（案类 id）；UI 闪 `seal.fengre_biao` / `seal.shiji` / `seal.pixu_shikun`；本档只亮这 3 枚；不做十二印墙
- **候诊权重**：
  - `waiting.max_seats = 4`（A–D；溢出轮换进池）
  - `pool_includes_old_four: true`
  - base：`fengre_biao 0.35` / `shiji 0.4` / `pixu_shikun 0.35`
  - 有 `town_permit`：× `with_town_permit_mult 1.8`
  - 无 permit：`shiji_teach_once` + `shiji_weight 0.25`；风热/脾虚各 0.05
- **合法路径（开放解）**：
  1. **风热** `fengre_biao`：方 `jinyinhua+lianqiao+bohe+gancao`（±`xingren`）；穴 `quchi+hegu`（`case_temp_open`）/ `hegu+fengchi`；食轻清；情志罕用
  2. **食积** `shiji`：方 `baizhu+fuling+shengjiang+zhiqiao+shanzha`（`digest_food`）；穴 `zusanli` / `zusanli+neiguan`；食稀粥节食；情志低
  3. **脾虚湿困** `pixu_shikun`：方 `baizhu+fuling+shanyao+gancao`（±`zexie`）；穴灸 `zusanli` / `zusanli+sanyinjiao`（临时开）/ `+hegu`；食 `zhou_di+shanyao+hongzao`
- **新药**：`shanzha`（山楂；`digest_food`+`move_qi`+`open_chest`；`forage:false`）
- **穴临时开**：`acu_intro_rules.case_temp_open.fengre_biao` → `quchi`,`hegu`；`pixu_shikun` → `sanyinjiao`；**不**永久扩 `vol1_open_ids`
- **风热/风寒误叉**：
  - 风热当风寒用 `mahuang`/`guizhi` → mistreat + 稳罚；回访「热更重/咽更疼」
  - 风寒当风热用 `jinyinhua`/`lianqiao` → 旧案 `common_mistreat` 保持
- **冒烟**：`qingshi_expand_ok`（三案各 ≥1 合法 settle）+ `SMOKE PASS`
- **不做**：十二满编、陈半仙、萨米尔、小儿、五方、情缘、改 Steam、J/T
