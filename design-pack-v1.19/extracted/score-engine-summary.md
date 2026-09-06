# tcm_score_engine.py API 摘要

来源：`计分引擎/说明.txt` + `tcm_score_engine.py`（对应文档 17 / v1.12）

说明：规则向量引擎，**不是**神经网络。一期语料：88 味、15 方/穴组、14 证、21 维功效 + 温度。主公式 `M = 0.45*C + 0.20*B + 0.25*A' + 0.10*U`；上线后覆盖分再乘节气 J、地域 T（见 16/22/23），反畏由 18 册硬锁，本脚本不扣。

## 数据常量

| 名 | 含义 |
| --- | --- |
| `FUNCS` | 21 维功效名列表 |
| `ROLE_W` | 君臣佐使权重：君 1.0 / 臣 0.60 / 佐 0.35 / 使 0.20 / 平 0.45 |
| `HERBS` | 药材 dict：`name -> {temp, f:{功效:权重}}` |
| `POINTS` | 穴位 dict（同结构） |
| `FORMULAS` | 成方/穴组：`id -> {items:[(name,role)], B, kind?, ...}` |
| `SYNDROMES` | 证型：`id -> {need, temp, B_ok?}` |

## 公开函数

| 函数 | 输入 | 输出 |
| --- | --- | --- |
| `v_from_f(fdict)` | 功效 dict | 21 维向量 list[float] |
| `add_v(a, b, w=1.0)` | 两向量 + 权重 | 加权求和向量 |
| `norm(v)` | 向量 | L2 归一化向量 |
| `dot(a, b)` | 两向量 | 点积 float |
| `lookup_item(name)` | 药/穴名 | `(item_dict, "herb"|"acu")`；未知抛 KeyError |
| `supply_of(items, mods=None)` | `items: list[(name, role)]`；`mods: {name: ('add'|'del'|'keep', extra_w)}` | `(S, t, used)`：供给向量、温度标量、实际用药名列表 |
| `demand_of(syn_id)` | 证型 id | `(R, tR)`：需求向量与温度 |
| `cover_score(S, tS, R, tR)` | 供给/需求向量与温度 | 主覆盖分 C（0～100，含温度对齐） |
| `add_minus_score(syn_id, formula_id, mods)` | 证、方、加减 mods | `(A_raw, notes)`：A∈[-20,20]，加减说明列表 |
| `structure_score(items, mods, kind="herb")` | 组成 + 加减；kind=`herb`/`acu` | 结构分 U（0～100） |
| **`evaluate(syn_id, formula_id, mods=None, use_B=True)`** | 证型 id、方/穴组 id、加减 mods、是否用成方基准 B | **主入口**，见下表 |
| `main()` | 无 | 跑 25 例金标准对照，打印 SUMMARY；写 validation JSON（脚本内路径可能需改） |

### `evaluate` 返回 dict

| 键 | 含义 |
| --- | --- |
| `syndrome` / `formula` / `mods` | 回显输入 |
| `cover` | C 主覆盖 |
| `B` | 成方基准（B_ok 内用预设；否则约 0.12×预设） |
| `A_raw` / `A` | 加减原始分 / 映射到 0～100 |
| `struct` | U 结构分 |
| `M` | 对证总分 |
| `notes` | 加减文字说明 |
| `used` | 实际用到的药/穴名 |
| `pass` | `M >= 55` |

## CLI

```bash
python3 tcm_score_engine.py
```

回归门槛（说明.txt）：正例均分约 73.2，反例约 41.8，差 31.4；扩容后同 25 例 M 波动超 3 分应回滚向量。
