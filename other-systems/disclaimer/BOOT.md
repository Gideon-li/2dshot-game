# 启动免责声明（切片必做）

阻塞启动。未勾选「我已阅读」不能进医馆。接受后写入存档 `disclaimer_accepted`，下次可跳过正文、仍在角落留 `BOOT_DISCLAIMER_FOOTER`。

## 画面（建议）

宣纸底、墨色标题、无脉象图（脉象留给进馆后的前三张截图）。商店页同一句话用 `STORE_NOT_MEDICAL`。

## 文案键

- `BOOT_DISCLAIMER_TITLE`
- `BOOT_DISCLAIMER_BODY`
- `BOOT_DISCLAIMER_CHECK`
- `BOOT_DISCLAIMER_ACCEPT`
- `BOOT_DISCLAIMER_FOOTER`

中英日已在 `../i18n/ui.csv`。不要另写一套。

## 不要写进声明的

- 具体药方、穴位当真实医嘱
- Qwen / 大模型
- 「本游戏可学习行医」
