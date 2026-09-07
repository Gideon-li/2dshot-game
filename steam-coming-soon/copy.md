# 《墨问岐黄》Steam Coming Soon 文案定稿（V123）

给商店页直接粘贴。图件与胶囊由美工/角色开发出；本文件只锁定文案。

正式名：**墨问岐黄**。学徒默认 **江晚**。禁止出现「林晚」「杏林墨问」作商店主名。  
禁止卖点：大模型 / Qwen / Helix / AI 问诊。禁止教材/题库/Education 话术。

键值对照：`STORE_TAGLINE`、`STORE_NOT_MEDICAL`（`other-systems/i18n/ui.csv`）。

---

## 商店第一句（锁死）

| 语言 | 句 | 键 |
| --- | --- | --- |
| 中 | 病人不交全症状。望、闻、问、切，都要你亲手做。 | `STORE_TAGLINE` |
| EN | The patient never hands you a complete chart. Look, listen, ask, then feel the pulse. | `STORE_TAGLINE` |
| 日 | 患者は症状をすべて話さない。望・聞・問・切は、あなたがやる動詞だ。 | `STORE_TAGLINE` |

英日不要写成「学中医」。

---

## 短描述（各语言 1 短段）

### 中

明快 Q 版的中式医馆。病人不交全症状，望、闻、问、切都要亲手做。开方拖药或点穴扎针，多条路都能治，没有唯一答案。午后去后院药圃，看形色气味再认再采，采来的药能进托盘。问诊无网也能用本地回复。

### EN

A bright Q-style Chinese clinic. Patients never hand you a complete chart — look, listen, ask, and take the pulse yourself. Compound a formula or needle points; more than one path can heal. After noon, identify backyard herbs by shape, color, and scent, then pick them into the tray. Inquiry still works offline with local replies.

### 日

明るいQ版の中華医館。患者は症状をすべて渡さない。望・聞・問・切は手でやる。薬を組むか、穴を取るか、正しい道はひとつではない。午後は裏庭の薬圃で形・色・香りを見てから採り、盆に載せられる。問診はネットがなくても手元の返事で続けられる。

---

## 免责（商店页 + 启动一致）

| 语言 | 句 | 键 |
| --- | --- | --- |
| 中 | 文化体验，不能替代就医。 | `STORE_NOT_MEDICAL` |
| EN | A cultural experience. Not a substitute for medical care. | `STORE_NOT_MEDICAL` |
| 日 | 文化体験です。受診の代わりにはなりません。 | `STORE_NOT_MEDICAL` |

启动长文案仍用 `BOOT_DISCLAIMER_*`，不在此改。不要写可学习行医、不要把具体药方当医嘱。

> 注：`STORE_NOT_MEDICAL` 英日已与本表对齐。

---

## 标签建议（只写备忘，不操作后台）

主：Simulation / Puzzle / Casual / 2D。  
Medical Sim 勿第一。不要挂 Education。

## 定价备忘（页上可先不写）

目标 ¥58 / $14.99 / ¥1,700。若仍是薄切片：¥42 / $9.99。

---

## 粘贴块

### About this game / 简短介绍（中）

病人不交全症状。望、闻、问、切，都要你亲手做。

明快 Q 版的中式医馆。病人不交全症状，望、闻、问、切都要亲手做。开方拖药或点穴扎针，多条路都能治，没有唯一答案。午后去后院药圃，看形色气味再认再采，采来的药能进托盘。问诊无网也能用本地回复。

文化体验，不能替代就医。

### Short description (EN)

The patient never hands you a complete chart. Look, listen, ask, then feel the pulse.

A bright Q-style Chinese clinic. Patients never hand you a complete chart — look, listen, ask, and take the pulse yourself. Compound a formula or needle points; more than one path can heal. After noon, identify backyard herbs by shape, color, and scent, then pick them into the tray. Inquiry still works offline with local replies.

A cultural experience. Not a substitute for medical care.

### 短い紹介（日）

患者は症状をすべて話さない。望・聞・問・切は、あなたがやる動詞だ。

明るいQ版の中華医館。患者は症状をすべて渡さない。望・聞・問・切は手でやる。薬を組むか、穴を取るか、正しい道はひとつではない。午後は裏庭の薬圃で形・色・香りを見てから採り、盆に載せられる。問診はネットがなくても手元の返事で続けられる。

文化体験です。受診の代わりにはなりません。

---

## i18n 同步（其他要素 V123）

已写入 `other-systems/i18n/ui.csv` 与 `locale/xinglin.csv`：

- `STORE_TITLE` / `STORE_TAGLINE` / `STORE_SHORT_DESC` / `STORE_NOT_MEDICAL`
- `STORE_NOT_MEDICAL` 英日已与上表「不能替代就医」对齐
- 启动长文案 `BOOT_DISCLAIMER_BODY` 未改；页脚 `BOOT_DISCLAIMER_FOOTER` 与商店短免责同义
- **未**接 Steamworks

同目录 `store-copy.csv` 可直接给商店粘贴对照。
