# 目录约定（切片）

| 路径 | 谁填 | 做什么 |
| --- | --- | --- |
| `scenes/` | 开发负责人骨架 / 角色开发接玩法 | 启动、医馆、脉象、治疗 |
| `scripts/game_flow.gd` | 角色开发往上接 | 四诊阶段；缺诊可开方但评分打折 |
| `logic/` | 游戏逻辑设计 | 病机表、疗效评分 |
| `locale/` + `other-systems/i18n` | 其他要素 | 中英日键值 |
| `other-systems/disclaimer` | 其他要素 | 启动免责 |
| `other-systems/save` | 其他要素 | 存档 |
| `other-systems/audio` | 游戏音乐（雨声底由其他要素先放） | 配乐方向、薄床、交互音、脉象与结算 |
| `other-systems/steamworks` | 其他要素 | 只预研，不上排行榜 |
| `scene-slice/` | 游戏场景设计 | 水墨医馆空间 |
| `ui/` | 美工 / 其他要素 | 水墨 UI、方剂盘 |
| `patients/` | 剧本设计 | 人物卡，勿写诊断名 |

不要提交 `secrets.env`。
