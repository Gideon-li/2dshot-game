# L3_desk_front（V139.1）

自 `L3-furniture.png` 裁切诊桌前立面/桌沿，透明底。权威：`scene-slice/CLINIC-CONSULT-V139.md` §2。

## 资源

| 文件 | 说明 |
| --- | --- |
| `L3_desk_front.png` | **主交**：1536×1024，仅桌沿条不透明；与 L3 同纹理空间 |
| `L3_desk_front_strip.png` | 紧裁条（同像素）；挂载时用下方 offset |
| `../ui/clinic/L3_desk_front_apron.png` | 可选：更高处的诊桌前立面（中段遮挡更强）；正式锁仍以主交为准 |

药壶/脉枕/香炉已验收，不重做。不重绘整馆。

## 世界对齐

- 像素盒约 **世界 x∈[920,1480] · y∈[1060,1180]**（纹理约 `(552,760)–(889,840)`）
- **Y-sort 原点（世界）= (1220, 1160)**；排序键 **Y=1160**；**z_index ≈ 4**
- 映射：纹理 (0,0)→世界 (0,0)，(1536,1024)→(2560,1440)；scale `(1.666667, 1.40625)`

## 角色挂 tscn（推荐）

同 L3 Art 的 scale；**节点 position 必须落到排序原点**，勿照抄 Art 的 `(1280,720)`（否则排序键变成 720）。

```
Sprite2D L3_desk_front
  texture = res://scene-slice/layers/L3_desk_front.png   # 或 ui/layers/ 镜像
  centered = false
  scale = Vector2(1.666667, 1.40625)
  position = Vector2(1220, 1160)          # Y-sort 键
  offset = Vector2(-732.0, -824.8889)     # 使纹理 (0,0) 仍对齐世界 (0,0)
  z_index = 4
  y_sort_enabled = true
```

紧裁条 `L3_desk_front_strip.png` 等价挂法：

```
  texture = .../L3_desk_front_strip.png
  position = Vector2(1220, 1160)
  offset = Vector2(-180.0, -64.8889)      # strip 纹理左上 ≈ 世界 (920, 1068.8)
  scale / centered / z / y_sort 同上
```

须与人物进**同一 YSort 父节点**（或父级 `y_sort_enabled` 能与本节点比较）。

## 排序语义

- 脚底 `Y < 1160`（江晚 1080）→ 画在桌沿后  
- 脚底 `Y > 1160`（坐诊 / A–D）→ 画在桌沿前  

镜位仍 `CAM_HERO (1280,780)`。
