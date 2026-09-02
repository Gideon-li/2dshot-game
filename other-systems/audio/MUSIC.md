# 杏林墨问 · 配乐方向（切片）

负责：游戏音乐  
雨声底：`rain-clinic.ogg`（已有，CC0，默认 0.32）  
引擎：Godot 4，总线分 Ambient / Music / SFX

## 一句

声音要像宣纸。雨是底，古琴是墨点，切脉时旋律让开。

不是中医教材 BGM，也不是史诗国风。近邻是《Strange Horticulture》店内雨 + 极简旋律，和《Potion Craft》的小房间混响（不要大殿尾音）。乐器换成古琴、箫，材料换成木头、宣纸、瓷碗、针。

## 气质

- 留白：一个乐句之间要能听见雨和抽屉。
- 室内：短混响，像坐堂，不像山水 MV。
- 手做：药是拖进去的，针是点上去的，音效也要是材料，不是菜单哔一声。
- 不要：二胡哭腔、大编制、歌词主题曲、按病人切整首 BGM、现场音乐会录音（版权不清，跟雨声那条一样拒）。

## 分层（医馆常驻）

| 层 | 何时 | 音量关系 |
| --- | --- | --- |
| Ambient 雨 | 进医馆就播，免责画面更低或静 | 底，已有 |
| Music 薄床 | 坐堂后极低音量进来；切诊时再降或静 | 永远低于雨 |
| SFX | 点、拖、入药、扎针、脉 | 可盖过旋律，不可盖过语音/问诊字 |

薄床：五声、慢、可循环 60s+。古琴散音 + 偶发箫，不要 100BPM 古筝loop。许可证只要 CC0（或可商用且能进 Steam 致谢）。

## 跟玩法走，不跟曲名走

四诊任意顺序。音乐不要报「现在是问诊关」。只做干湿和疏密：

- 望 / 闻：几乎只有雨。
- 问：床保持，不加鼓点。
- 切：旋律让位。脉象音就是这一刻的主题。Steam 截图要能「看见」脉，耳机里也要能听出三种：
  - 浮紧：浅、短、绷在表层
  - 弦：直、长、一下一下顶着手
  - 细数：细、密、跳得快
- 开方：药柜抽、药入瓷碗、研磨。可有极轻古琴应一声。
- 针灸：针入是短而准的金属+皮肉，不要夸张。
- 结算：五种短音，像一笔墨，不要 fanfare。对应 未效 / 小效 / 见效 / 显效 / 向愈。误治走未效/小效的更干、更滞的一笔。

三案只换颜色，不换整轨（切片锁死）：

- 风寒：更干、更紧
- 肝郁：多留空拍，像叹气
- 阴虚：更薄、更高、细

用总线 EQ / 少量 stem，不要切歌。

## 切片要交的文件

1. 保留 `rain-clinic.ogg`
2. `clinic-bed.ogg`：一张可循环薄床，CC0，默认约 0.12–0.18
3. SFX：`ui-paper` `drawer` `herb-drop` `needle` `pulse-fu` `pulse-xian` `pulse-xi`
4. 结算：`settle-0` … `settle-4`（未效→向愈）
5. Godot：Ambient / Music / SFX 三总线；设置里可关环境音（已有）并加音乐开关；切诊场景 Music duck 到几乎听不见

## 明确不做（本期）

- 标题曲、歌词、角色主题
- 按病人切换整首 BGM
- 穿越朝代包、药圃野外、经营层
- 语音旁白
- 非 CC0 的现场古琴/箫音乐会录音

## 参考（听气质，不搬曲）

- 《Strange Horticulture》店内：雨 + 极简、能挂几小时
- 《Potion Craft》：室内、手作、小空间
- 场景参考：`scene-slice/refs/ref-courtyard-window.jpg`（暗室内看院子，格子窗）

## 致谢

雨：Ylmir《Rain (loopable)》OpenGameArt，CC0。  
薄床与 SFX：杏林墨问 original（本目录合成，Steam 可进包）。明细见下方 SOURCES。禁止无来源资源进包。

## 开发负责人锁定（2026-09-02）

- 保留 `rain-clinic.ogg`，不换底，环境音默认不超过 0.32
- 只收 CC0 或能进 Steam 致谢的可商用；现场音乐会录音继续不要
- 新文件放本目录：`clinic-bed.ogg` + SFX/结算
- 切诊时 Music 总线 duck（Godot 侧接）；不要按病人切整首 BGM
- 总线和进场景由开发负责人挂；薄床和 SFX 备齐后回他

## SOURCES

全部新文件为 **杏林墨问 original**（Python 合成：Karplus-Strong / 加性五声古琴、气声箫、噪声+模态拟音），按原作进 Steam 致谢「杏林墨问 original」。未采用 OpenGameArt 忙乱 pentatonic loop、Kenney 塑料 UI 点击，以及北京戏楼现场琴箫录音（版权/气质都不合）。`rain-clinic.ogg` 未改、未重编码。

锁：雨默认不超过 0.32；不按病人切整首 BGM；切诊 Music duck 在 Godot 侧。

| 文件 | 许可 | 来源 | 是什么 |
| --- | --- | --- | --- |
| rain-clinic.ogg | CC0 | https://opengameart.org/content/rain-loopable （Ylmir《Rain (loopable)》第 3 条） | 医馆雨循环（已有，未改动） |
| clinic-bed.ogg | original（杏林墨问 original） | 本目录合成，无外部采样 | 72s 可无缝循环薄床：D 宫五声、散音古琴 + 偶发箫、大量留白，峰值约 -14 dBTP，建议 Music 0.12–0.18 |
| ui-paper.ogg | original（杏林墨问 original） | 本目录合成 | 宣纸/卡片轻点（UI 点击） |
| drawer.ogg | original（杏林墨问 original） | 本目录合成 | 药柜木抽屉抽出 + 到位轻碰 |
| herb-drop.ogg | original（杏林墨问 original） | 本目录合成 | 干药/小瓷碗落入配方盘 |
| needle.ogg | original（杏林墨问 original） | 本目录合成 | 短而准的针入：金属瞬态 + 软组织，非卡通刺击 |
| pulse-fu.ogg | original（杏林墨问 original） | 本目录合成 | 浮紧脉循环，1.1 Hz，浅、短、表层绷紧 |
| pulse-xian.ogg | original（杏林墨问 original） | 本目录合成 | 弦脉循环，0.85 Hz，直、长、顶手 |
| pulse-xi.ogg | original（杏林墨问 original） | 本目录合成 | 细数脉循环，1.6 Hz，细、密、更弱 |
| settle-0.ogg | original（杏林墨问 original） | 本目录合成 | 结算墨笔·未效（干、滞） |
| settle-1.ogg | original（杏林墨问 original） | 本目录合成 | 结算墨笔·小效 |
| settle-2.ogg | original（杏林墨问 original） | 本目录合成 | 结算墨笔·见效 |
| settle-3.ogg | original（杏林墨问 original） | 本目录合成 | 结算墨笔·显效 |
| settle-4.ogg | original（杏林墨问 original） | 本目录合成 | 结算墨笔·向愈（更暖、更开） |

## Godot 挂接（2026-09-02）

`scripts/audio_hub.gd` autoload `AudioHub`。总线 Ambient / Music / SFX。

- `enter_clinic()`：雨 0.32 + `clinic-bed` 0.15（存档 `audio.music` 上限 0.18）
- 切诊：`play_pulse_id` duck Music 到 0.02，循环 fu_jin / xian / xi_shu；`stop_pulse()` 恢复
- SFX：`play_one("ui-paper"|"drawer"|"herb-drop"|"needle")`
- 结算：`play_settle(rank_id)` → none/slight/work/clear/toward_heal 对 settle-0…4
- 启动免责：`mute_boot()`

