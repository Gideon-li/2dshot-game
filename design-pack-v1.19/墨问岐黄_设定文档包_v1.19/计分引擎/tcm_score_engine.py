# -*- coding: utf-8 -*-
"""Phase-1 TCM scoring engine for 墨问岐黄.
Validates formula/syndrome fit using textbook correspondences, not hospital records.
"""
from __future__ import annotations
import json
from math import sqrt

FUNCS = [
    "解表", "清热", "泻下", "祛湿", "化痰", "理气", "活血", "止血",
    "补气", "补血", "补阴", "补阳", "安神", "平肝", "收涩", "温里",
    "消食", "利水", "止咳", "疏风", "发汗",
]
ROLE_W = {"君": 1.0, "臣": 0.60, "佐": 0.35, "使": 0.20, "平": 0.45}

# temp: 寒-2 凉-1 平0 温1 热2
HERBS = {
    "桂枝": {"temp": 1, "f": {"解表": 0.8, "温里": 0.4, "理气": 0.2}},
    "白芍": {"temp": -1, "f": {"补血": 0.7, "平肝": 0.4, "收涩": 0.3}},
    "生姜": {"temp": 1, "f": {"解表": 0.5, "温里": 0.6, "止咳": 0.2}},
    "大枣": {"temp": 0, "f": {"补气": 0.5, "补血": 0.3}},
    "甘草": {"temp": 0, "f": {"补气": 0.5, "止咳": 0.2, "清热": 0.1}},
    "麻黄": {"temp": 1, "f": {"解表": 1.0, "止咳": 0.5, "利水": 0.3, "发汗": 0.9}},
    "杏仁": {"temp": 0, "f": {"止咳": 0.8, "理气": 0.2}},
    "薄荷": {"temp": -1, "f": {"解表": 0.6, "疏风": 0.5, "理气": 0.3}},
    "柴胡": {"temp": -1, "f": {"疏风": 0.4, "理气": 0.8, "清热": 0.2}},
    "当归": {"temp": 1, "f": {"补血": 0.9, "活血": 0.4}},
    "白术": {"temp": 1, "f": {"补气": 0.7, "祛湿": 0.5}},
    "茯苓": {"temp": 0, "f": {"利水": 0.7, "祛湿": 0.5, "安神": 0.3}},
    "熟地黄": {"temp": 1, "f": {"补血": 0.8, "补阴": 0.7}},
    "生地黄": {"temp": -1, "f": {"清热": 0.6, "补阴": 0.5, "止血": 0.3}},
    "山茱萸": {"temp": 1, "f": {"补阴": 0.4, "收涩": 0.7, "补阳": 0.2}},
    "山药": {"temp": 0, "f": {"补气": 0.6, "补阴": 0.3, "收涩": 0.3}},
    "泽泻": {"temp": -1, "f": {"利水": 0.8, "清热": 0.2}},
    "牡丹皮": {"temp": -1, "f": {"清热": 0.6, "活血": 0.4}},
    "人参": {"temp": 1, "f": {"补气": 1.0, "补阳": 0.2}},
    "黄芪": {"temp": 1, "f": {"补气": 0.9, "利水": 0.2}},
    "党参": {"temp": 0, "f": {"补气": 0.7}},
    "陈皮": {"temp": 1, "f": {"理气": 0.7, "化痰": 0.4}},
    "半夏": {"temp": 1, "f": {"化痰": 0.9, "理气": 0.3}},
    "黄连": {"temp": -2, "f": {"清热": 1.0, "祛湿": 0.3}},
    "黄芩": {"temp": -1, "f": {"清热": 0.8, "祛湿": 0.3}},
    "石膏": {"temp": -2, "f": {"清热": 1.0}},
    "知母": {"temp": -2, "f": {"清热": 0.7, "补阴": 0.4}},
    "粳米": {"temp": 0, "f": {"补气": 0.3}},
    "酸枣仁": {"temp": 0, "f": {"安神": 1.0, "补血": 0.2}},
    "远志": {"temp": 0, "f": {"安神": 0.7, "化痰": 0.3}},
    "川芎": {"temp": 1, "f": {"活血": 0.8, "理气": 0.4, "疏风": 0.3}},
    "香附": {"temp": 0, "f": {"理气": 0.9}},
    "厚朴": {"temp": 1, "f": {"理气": 0.5, "化痰": 0.4, "祛湿": 0.4}},
    "苍术": {"temp": 1, "f": {"祛湿": 0.8, "理气": 0.2}},
    "薏苡仁": {"temp": -1, "f": {"祛湿": 0.6, "利水": 0.5}},
    "附子": {"temp": 2, "f": {"温里": 1.0, "补阳": 0.8}},
    "干姜": {"temp": 2, "f": {"温里": 0.9}},
    "肉桂": {"temp": 2, "f": {"温里": 0.8, "补阳": 0.4}},
    "麦冬": {"temp": -1, "f": {"补阴": 0.8, "清热": 0.3}},
    "五味子": {"temp": 1, "f": {"收涩": 0.8, "补阴": 0.3, "安神": 0.3}},
    "枸杞子": {"temp": 0, "f": {"补阴": 0.6, "补血": 0.3}},
    "杜仲": {"temp": 1, "f": {"补阳": 0.6}},
    "牛膝": {"temp": 0, "f": {"活血": 0.6, "补阳": 0.2, "利水": 0.2}},
    "桃仁": {"temp": 0, "f": {"活血": 0.8, "泻下": 0.2}},
    "红花": {"temp": 1, "f": {"活血": 0.9}},
    "延胡索": {"temp": 1, "f": {"活血": 0.6, "理气": 0.5}},
    "山楂": {"temp": 1, "f": {"消食": 0.8, "活血": 0.2}},
    "神曲": {"temp": 1, "f": {"消食": 0.8}},
    "莱菔子": {"temp": 0, "f": {"消食": 0.6, "化痰": 0.4}},
    "紫苏": {"temp": 1, "f": {"解表": 0.6, "理气": 0.4}},
    "防风": {"temp": 1, "f": {"解表": 0.6, "疏风": 0.7}},
    "荆芥": {"temp": 1, "f": {"解表": 0.7, "疏风": 0.5}},
    "葛根": {"temp": 0, "f": {"解表": 0.6, "清热": 0.2}},
    "连翘": {"temp": -1, "f": {"清热": 0.7, "疏风": 0.3}},
    "金银花": {"temp": -1, "f": {"清热": 0.8}},
    "板蓝根": {"temp": -2, "f": {"清热": 0.8}},
    "鱼腥草": {"temp": -1, "f": {"清热": 0.6, "止咳": 0.3}},
    "桔梗": {"temp": 0, "f": {"止咳": 0.5, "化痰": 0.4}},
    "款冬花": {"temp": 1, "f": {"止咳": 0.7}},
    "桑白皮": {"temp": -1, "f": {"止咳": 0.5, "利水": 0.3}},
    "瓜蒌": {"temp": -1, "f": {"化痰": 0.6, "理气": 0.3}},
    "竹茹": {"temp": -1, "f": {"化痰": 0.5, "清热": 0.4}},
    "枳实": {"temp": -1, "f": {"理气": 0.7, "消食": 0.3}},
    "木香": {"temp": 1, "f": {"理气": 0.8}},
    "砂仁": {"temp": 1, "f": {"理气": 0.5, "祛湿": 0.3, "温里": 0.2}},
    "藿香": {"temp": 1, "f": {"祛湿": 0.6, "解表": 0.3, "理气": 0.3}},
    "佩兰": {"temp": 0, "f": {"祛湿": 0.6}},
    "茵陈": {"temp": -1, "f": {"祛湿": 0.7, "清热": 0.4}},
    "车前子": {"temp": -1, "f": {"利水": 0.7}},
    "猪苓": {"temp": 0, "f": {"利水": 0.7}},
    "大黄": {"temp": -2, "f": {"泻下": 1.0, "清热": 0.5, "活血": 0.3}},
    "芒硝": {"temp": -2, "f": {"泻下": 0.9}},
    "火麻仁": {"temp": 0, "f": {"泻下": 0.5, "补阴": 0.2}},
    "何首乌": {"temp": 0, "f": {"补血": 0.6, "补阴": 0.3}},
    "阿胶": {"temp": 0, "f": {"补血": 0.8, "止血": 0.4}},
    "龙眼肉": {"temp": 1, "f": {"补血": 0.5, "安神": 0.4}},
    "柏子仁": {"temp": 0, "f": {"安神": 0.7, "补阴": 0.2}},
    "龙骨": {"temp": 0, "f": {"安神": 0.6, "收涩": 0.4, "平肝": 0.3}},
    "牡蛎": {"temp": -1, "f": {"安神": 0.4, "平肝": 0.5, "收涩": 0.3}},
    "钩藤": {"temp": -1, "f": {"平肝": 0.8, "疏风": 0.3}},
    "天麻": {"temp": 0, "f": {"平肝": 0.8}},
    "石决明": {"temp": -1, "f": {"平肝": 0.7}},
    "吴茱萸": {"temp": 2, "f": {"温里": 0.8, "理气": 0.3}},
    "小茴香": {"temp": 1, "f": {"温里": 0.5, "理气": 0.4}},
    "艾叶": {"temp": 1, "f": {"温里": 0.5, "止血": 0.4}},
    "三七": {"temp": 1, "f": {"止血": 0.7, "活血": 0.5}},
    "白及": {"temp": -1, "f": {"止血": 0.8}},
    "地榆": {"temp": -1, "f": {"止血": 0.6, "清热": 0.3}},
}

POINTS = {
    "合谷": {"temp": 0, "f": {"解表": 0.6, "疏风": 0.5, "理气": 0.4}, "prefer": "针"},
    "太冲": {"temp": 0, "f": {"平肝": 0.8, "理气": 0.7}, "prefer": "针"},
    "足三里": {"temp": 1, "f": {"补气": 0.7, "消食": 0.3, "祛湿": 0.2}, "prefer": "灸"},
    "神门": {"temp": 0, "f": {"安神": 0.9}, "prefer": "针"},
    "内关": {"temp": 0, "f": {"安神": 0.5, "理气": 0.5}, "prefer": "针"},
    "三阴交": {"temp": 0, "f": {"补血": 0.5, "祛湿": 0.3, "补阴": 0.3}, "prefer": "灸"},
    "关元": {"temp": 1, "f": {"补阳": 0.6, "补气": 0.4}, "prefer": "灸"},
    "气海": {"temp": 1, "f": {"补气": 0.6}, "prefer": "灸"},
    "曲池": {"temp": -1, "f": {"清热": 0.6, "解表": 0.3}, "prefer": "针"},
    "风池": {"temp": 0, "f": {"疏风": 0.7, "平肝": 0.3}, "prefer": "针"},
    "太溪": {"temp": 0, "f": {"补阴": 0.7}, "prefer": "针"},
    "百会": {"temp": 0, "f": {"补气": 0.4, "平肝": 0.3, "安神": 0.3}, "prefer": "灸"},
}

FORMULAS = {
    "桂枝汤": {"B": 72, "items": [("桂枝", "君"), ("白芍", "臣"), ("生姜", "佐"), ("大枣", "佐"), ("甘草", "使")]},
    "麻黄汤": {"B": 74, "items": [("麻黄", "君"), ("桂枝", "臣"), ("杏仁", "佐"), ("甘草", "使")]},
    "逍遥散": {"B": 73, "items": [("柴胡", "君"), ("当归", "臣"), ("白芍", "臣"), ("白术", "佐"), ("茯苓", "佐"), ("甘草", "使"), ("薄荷", "使")]},
    "四君子汤": {"B": 70, "items": [("人参", "君"), ("白术", "臣"), ("茯苓", "佐"), ("甘草", "使")]},
    "六味地黄丸": {"B": 74, "items": [("熟地黄", "君"), ("山茱萸", "臣"), ("山药", "臣"), ("泽泻", "佐"), ("牡丹皮", "佐"), ("茯苓", "佐")]},
    "白虎汤": {"B": 76, "items": [("石膏", "君"), ("知母", "臣"), ("粳米", "佐"), ("甘草", "使")]},
    "理中丸": {"B": 72, "items": [("人参", "君"), ("干姜", "臣"), ("白术", "佐"), ("甘草", "使")]},
    "四物汤": {"B": 70, "items": [("熟地黄", "君"), ("当归", "臣"), ("白芍", "臣"), ("川芎", "佐")]},
    "二陈汤": {"B": 68, "items": [("半夏", "君"), ("陈皮", "臣"), ("茯苓", "佐"), ("甘草", "使")]},
    "银翘散核心": {"B": 70, "items": [("金银花", "君"), ("连翘", "君"), ("薄荷", "臣"), ("桔梗", "佐"), ("甘草", "使")]},
    "保和丸核心": {"B": 68, "items": [("山楂", "君"), ("神曲", "臣"), ("莱菔子", "佐"), ("陈皮", "佐"), ("半夏", "佐"), ("茯苓", "佐")]},
    "四逆汤": {"B": 75, "items": [("附子", "君"), ("干姜", "臣"), ("甘草", "使")]},
    "酸枣仁汤核心": {"B": 69, "items": [("酸枣仁", "君"), ("茯苓", "臣"), ("甘草", "使")]},
    "四关": {"B": 70, "kind": "acu", "items": [("合谷", "君"), ("太冲", "君")]},
    "脾胃组": {"B": 68, "kind": "acu", "items": [("足三里", "君"), ("中脘".replace("中脘", "足三里"), "臣")]},
}

# fix 脾胃组
FORMULAS["脾胃组"] = {"B": 68, "kind": "acu", "items": [("足三里", "君"), ("三阴交", "臣")]}

SYNDROMES = {
    "风寒表虚": {"temp": 1, "need": {"解表": 1.0, "温里": 0.25, "发汗": 0.05}, "B_ok": ["桂枝汤"]},
    "风寒表实": {"temp": 1, "need": {"解表": 1.0, "止咳": 0.35, "发汗": 0.7}, "B_ok": ["麻黄汤"]},
    "风热犯表": {"temp": -1, "need": {"解表": 0.6, "清热": 0.8, "疏风": 0.4}, "B_ok": ["银翘散核心"]},
    "肝郁血虚": {"temp": 0, "need": {"理气": 0.9, "补血": 0.7, "平肝": 0.3}, "B_ok": ["逍遥散", "四关"]},
    "肝郁血虚失眠": {"temp": 0, "need": {"理气": 0.8, "补血": 0.6, "安神": 0.7}, "B_ok": ["逍遥散"]},
    "脾气虚": {"temp": 1, "need": {"补气": 1.0, "祛湿": 0.2}, "B_ok": ["四君子汤", "脾胃组"]},
    "肾阴虚": {"temp": -1, "need": {"补阴": 1.0, "清热": 0.2}, "B_ok": ["六味地黄丸"]},
    "气分热盛": {"temp": -2, "need": {"清热": 1.0}, "B_ok": ["白虎汤"]},
    "脾胃虚寒": {"temp": 2, "need": {"温里": 0.9, "补气": 0.6}, "B_ok": ["理中丸"]},
    "痰湿中阻": {"temp": 1, "need": {"化痰": 0.8, "祛湿": 0.5, "理气": 0.4}, "B_ok": ["二陈汤"]},
    "食积": {"temp": 0, "need": {"消食": 1.0, "理气": 0.3}, "B_ok": ["保和丸核心"]},
    "阳虚寒厥": {"temp": 2, "need": {"温里": 1.0, "补阳": 0.8}, "B_ok": ["四逆汤"]},
    "血虚": {"temp": 1, "need": {"补血": 1.0}, "B_ok": ["四物汤"]},
    "心神不宁": {"temp": 0, "need": {"安神": 1.0, "补血": 0.2}, "B_ok": ["酸枣仁汤核心"]},
}


def v_from_f(fdict):
    return [float(fdict.get(k, 0.0)) for k in FUNCS]


def add_v(a, b, w=1.0):
    return [x + w * y for x, y in zip(a, b)]


def norm(v):
    n = sqrt(sum(x * x for x in v)) or 1.0
    return [x / n for x in v]


def dot(a, b):
    return sum(x * y for x, y in zip(a, b))


def lookup_item(name):
    if name in HERBS:
        return HERBS[name], "herb"
    if name in POINTS:
        return POINTS[name], "acu"
    raise KeyError(name)


def supply_of(items, mods=None):
    """items: list of (name, role). mods: {name: ('add'| 'del'| 'keep', extra_w)}"""
    mods = mods or {}
    S = [0.0] * len(FUNCS)
    temps = []
    used = []
    for name, role in items:
        if mods.get(name, (None,))[0] == "del":
            continue
        item, _ = lookup_item(name)
        w = ROLE_W.get(role, 0.45)
        S = add_v(S, v_from_f(item["f"]), w)
        temps.append(item["temp"] * w)
        used.append(name)
    for name, spec in mods.items():
        if spec[0] != "add":
            continue
        item, _ = lookup_item(name)
        w = 0.40
        S = add_v(S, v_from_f(item["f"]), w)
        temps.append(item["temp"] * w)
        used.append(name)
    t = sum(temps) / (sum(abs(x) and 1 or 1 for x in temps) or 1)
    # better mean
    t = sum(temps) / (len(temps) or 1)
    return S, t, used


def demand_of(syn_id):
    syn = SYNDROMES[syn_id]
    return v_from_f(syn["need"]), syn["temp"]


def cover_score(S, tS, R, tR):
    c = max(0.0, dot(norm(S), norm(R))) * 100.0
    # temperature alignment: same sign or near 0
    dt = abs(tS - tR)
    tpen = max(0.0, 1.0 - dt / 4.0)
    return c * (0.7 + 0.3 * tpen)


def add_minus_score(syn_id, formula_id, mods):
    """A in [-20, 20] raw then later compressed."""
    syn = SYNDROMES[syn_id]
    need = syn["need"]
    A = 0.0
    notes = []
    base_names = {n for n, _ in FORMULAS[formula_id]["items"]}
    # deleted
    for name, spec in (mods or {}).items():
        if spec[0] == "del":
            item, _ = lookup_item(name)
            overlap = sum(min(item["f"].get(k, 0), need.get(k, 0)) for k in FUNCS)
            if overlap < 0.15:
                A += 6
                notes.append(f"减{name}（本案不需要）+6")
            else:
                A -= 14
                notes.append(f"减{name}（主需求相关）-14")
        if spec[0] == "add":
            item, _ = lookup_item(name)
            hit = sum(min(item["f"].get(k, 0), need.get(k, 0)) for k in FUNCS)
            # leftover need: 安神 etc
            extra = 0
            for k, nv in need.items():
                if item["f"].get(k, 0) > 0.4 and nv >= 0.5:
                    extra += 8 * item["f"][k]
            # reverse temp
            if item["temp"] * syn["temp"] < 0 and abs(item["temp"]) >= 2 and abs(syn["temp"]) >= 1:
                A -= 12
                notes.append(f"加{name}（寒热反向）-12")
            elif extra >= 4:
                A += min(12, extra)
                notes.append(f"加{name}（补未满足需求）+{min(12, extra):.0f}")
            elif hit < 0.1:
                A -= 4
                notes.append(f"加{name}（与证无关）-4")
            else:
                A += 2
                notes.append(f"加{name}（弱相关）+2")
    return max(-20.0, min(20.0, A)), notes


def structure_score(items, mods, kind="herb"):
    names = [n for n, _ in items if (mods or {}).get(n, (None,))[0] != "del"]
    extra = [n for n, spec in (mods or {}).items() if spec[0] == "add"]
    n = len(names) + len(extra)
    cap = 6 if kind == "acu" else 14
    s = 80.0
    if n > cap:
        s -= 8 * (n - cap)
    if any(r == "君" for _, r in items):
        s += 10
    return max(0.0, min(100.0, s))


def evaluate(syn_id, formula_id, mods=None, use_B=True):
    form = FORMULAS[formula_id]
    kind = form.get("kind", "herb")
    S, tS, used = supply_of(form["items"], mods)
    R, tR = demand_of(syn_id)
    cover = cover_score(S, tS, R, tR)
    B = form["B"] if use_B and formula_id in SYNDROMES[syn_id].get("B_ok", []) else (form["B"] * 0.15 if use_B else 0.0)
    if use_B and formula_id not in SYNDROMES[syn_id].get("B_ok", []):
        B = form["B"] * 0.12
    A_raw, notes = add_minus_score(syn_id, formula_id, mods)
    A = (A_raw + 20) / 40 * 100  # map [-20,20] -> [0,100]
    st = structure_score(form["items"], mods, kind)
    M = 0.45 * cover + 0.20 * B + 0.25 * A + 0.10 * st
    return {
        "syndrome": syn_id,
        "formula": formula_id,
        "mods": mods or {},
        "cover": round(cover, 1),
        "B": round(B, 1),
        "A_raw": round(A_raw, 1),
        "A": round(A, 1),
        "struct": round(st, 1),
        "M": round(M, 1),
        "notes": notes,
        "used": used,
        "pass": M >= 55,
    }


def main():
    cases = [
        ("正例", "风寒表虚", "桂枝汤", None),
        ("反例", "风热犯表", "桂枝汤", None),
        ("正例", "风寒表实", "麻黄汤", None),
        ("反例", "风寒表虚", "麻黄汤", None),
        ("正例", "肝郁血虚", "逍遥散", None),
        ("加减正", "肝郁血虚失眠", "逍遥散", {"酸枣仁": ("add",)}),
        ("加减负", "肝郁血虚", "逍遥散", {"黄连": ("add",)}),
        ("加减负堆", "肝郁血虚", "逍遥散", {"附子": ("add",)}),
        ("正例", "脾气虚", "四君子汤", None),
        ("反例", "气分热盛", "四君子汤", None),
        ("正例", "肾阴虚", "六味地黄丸", None),
        ("反例", "脾胃虚寒", "六味地黄丸", None),
        ("正例", "气分热盛", "白虎汤", None),
        ("反例", "脾胃虚寒", "白虎汤", None),
        ("正例", "脾胃虚寒", "理中丸", None),
        ("正例", "痰湿中阻", "二陈汤", None),
        ("正例", "食积", "保和丸核心", None),
        ("减药正", "气分热盛", "白虎汤", {"粳米": ("del",)}),
        ("正例", "阳虚寒厥", "四逆汤", None),
        ("反例", "气分热盛", "四逆汤", None),
        ("正例", "血虚", "四物汤", None),
        ("正例", "心神不宁", "酸枣仁汤核心", None),
        ("针正", "肝郁血虚", "四关", None),
        ("针正", "脾气虚", "脾胃组", None),
        ("自拟弱", "肝郁血虚", "四君子汤", {"柴胡": ("add",), "当归": ("add",)}),
    ]
    rows = []
    for tag, syn, form, mods in cases:
        ev = evaluate(syn, form, mods)
        ev["tag"] = tag
        rows.append(ev)
        print(f"{tag:6} {syn}/{form} M={ev['M']} cover={ev['cover']} B={ev['B']} A={ev['A_raw']} {ev['notes']}")

    pos = [r for r in rows if r["tag"].startswith("正") or r["tag"].startswith("加减正") or r["tag"].startswith("针")]
    neg = [r for r in rows if r["tag"].startswith("反") or r["tag"].startswith("加减负")]
    summary = {
        "n_herbs": len(HERBS),
        "n_formulas": len(FORMULAS),
        "n_points": len(POINTS),
        "n_syndromes": len(SYNDROMES),
        "n_cases": len(rows),
        "pos_mean_M": round(sum(r["M"] for r in pos) / len(pos), 1),
        "neg_mean_M": round(sum(r["M"] for r in neg) / len(neg), 1),
        "pos_pass": sum(1 for r in pos if r["pass"]),
        "pos_n": len(pos),
        "neg_fail": sum(1 for r in neg if not r["pass"]),
        "neg_n": len(neg),
        "sep": None,
    }
    summary["sep"] = round(summary["pos_mean_M"] - summary["neg_mean_M"], 1)
    print("SUMMARY", json.dumps(summary, ensure_ascii=False))
    out = {"summary": summary, "rows": rows}
    with open("/home/workdir/artifacts/tcm_score_validation.json", "w", encoding="utf-8") as f:
        json.dump(out, f, ensure_ascii=False, indent=2)
    return out

if __name__ == "__main__":
    main()
