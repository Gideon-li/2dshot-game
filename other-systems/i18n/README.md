# 中英日 UI 键值（切片）

Godot 4：把 `ui.csv` 导入为 Translation。第一列 `keys`，语言码 `zh` / `en` / `ja`。

- 文案全部走键值，场景里不要写死中文。
- 英日不要写成「学中医」。商店第一句用 `STORE_TAGLINE`。
- `{n}` 仅出现在 `SAVE_SLOT`，用 `tr("SAVE_SLOT").format({"n": i})` 或 String.format。
- 病人对白、病机、药名由剧本/逻辑提供，不在这份表里。问诊失败的本地回退也归剧本。
