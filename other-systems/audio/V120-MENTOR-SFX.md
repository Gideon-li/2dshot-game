# V120 · 旁白轻音（按需，不新开整曲）

依据：`DEV-TASKS-V120.md` → 其他要素/音乐按需。  
锁：不按病人切整首 BGM；切诊 duck；雨/薄床不动；**不新作 M 轨**。

## 复用现有

| 时机 | 调用 | 文件 |
| --- | --- | --- |
| 苏问舟旁白冒出（缺问提醒） | `AudioHub.play_chime()` | chime.ogg |
| 补问后「这一问有了」类确认 | `AudioHub.play_one("stamp-ok")` 或轻 `ui-ink` | stamp-ok / ui-ink |
| 小荷 UI 口吻冒泡 | 同 `play_chime()` 或更轻 `ui-ink`（勿新曲） | chime / ui-ink |
| 回访/病程一句出现 | 轻 `ui-ink` 即可 | ui-ink.ogg |

同诊旁白 ≤2 句：每句冒出播一次即可，不要叠旋律。

## 不做

- 不为问舟/小荷写主题曲或新 BGM
- 不为旁白加语音（一期字幕，志里 VO 后置）
- 不改 rain / clinic-bed

## 挂接

角色开发在 `_refresh_mentor()` 从不可见→可见时打一声 `play_chime()`；确认句用 `stamp-ok`。音乐侧无新文件。
