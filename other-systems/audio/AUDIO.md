# 基础环境音（切片）

## 气质

医馆雨天。远、薄、宣纸一样留白。不要旋律压过脉象和拖药。默认环境音 0.32，设置里可关。

## 切片落地

- 文件：`rain-clinic.ogg`（循环）
- 来源：Ylmir《Rain (loopable)》第 3 条，OpenGameArt，**CC0**
- 页：https://opengameart.org/content/rain-loopable
- 时长：45 秒，44.1 kHz stereo Vorbis
- Godot：`AudioStreamPlayer`，`stream.loop = true`，进医馆后播，启动免责画面可先静音或更低

## 明确不做（本期）

- 古琴/笛旋律层（现场音乐会录音版权不清，不塞）
- 配乐主题、UI 点击音库、脉象专用音效
- 按病人切换 BGM

需要点击/结算短音时，用引擎方波占位即可，不进资源包。
