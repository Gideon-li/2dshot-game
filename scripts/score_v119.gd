class_name ScoreV119
extends RefCounted
## Slice scorer aligned to doc 17: M = 0.45*C* + 0.20*B + 0.25*A' + 0.10*U
## C* = C * J * T. Slice keeps J=T=1.0 until season/region tables land.

const W_C := 0.45
const W_B := 0.20
const W_A := 0.25
const W_U := 0.10


static func evaluate(case_data: Dictionary, exams: Dictionary, path: String, ids: Array, opts: Dictionary = {}) -> Dictionary:
	var J := float(opts.get("J", 1.0))
	var T := float(opts.get("T", 1.0))
	var C := _coverage(case_data, path, ids)
	var B := _formula_fit(case_data, path, ids)
	var A := _adjust(case_data, path, ids)
	var U := _structure(path, ids)
	var C_star := clampf(C * J * T, 0.0, 1.0)
	var M := W_C * C_star + W_B * B + W_A * A + W_U * U
	var process := _process_mult(exams, case_data)
	M *= process
	var mistreat := _mistreat(case_data, path, ids)
	if mistreat:
		M = minf(M, 0.34)
	M = clampf(M, 0.0, 1.0)
	return {
		"score": M,
		"C": C,
		"C_star": C_star,
		"B": B,
		"A": A,
		"U": U,
		"J": J,
		"T": T,
		"process_mult": process,
		"mistreat": mistreat,
		"rank_id": _rank_id(M),
		"path": path,
	}


static func _actions_of(case_data: Dictionary, path: String, ids: Array) -> Dictionary:
	var pack: Dictionary = {}
	# Prefer CaseDB tables when present
	if Engine.has_singleton("CaseDB") or true:
		pass
	var bag: Dictionary = {}
	if path == "formula":
		for h in CaseDB.pack.get("herbs", []):
			if typeof(h) == TYPE_DICTIONARY:
				bag[str(h.get("id", ""))] = h
	else:
		for p in CaseDB.pack.get("acupoints", CaseDB.pack.get("points", [])):
			if typeof(p) == TYPE_DICTIONARY:
				bag[str(p.get("id", ""))] = p
	var acts := {}
	for id in ids:
		var item: Dictionary = bag.get(str(id), {})
		for a in item.get("actions", []):
			acts[str(a)] = true
	return acts


static func _cover(have: Dictionary, need: Array) -> float:
	if need.is_empty():
		return 1.0
	var n := 0
	for a in need:
		if have.has(str(a)):
			n += 1
	return float(n) / float(need.size())


static func _coverage(case_data: Dictionary, path: String, ids: Array) -> float:
	var have := _actions_of(case_data, path, ids)
	var req: Array = case_data.get("required_actions", [])
	var pref: Array = case_data.get("preferred_actions", [])
	return clampf(0.7 * _cover(have, req) + 0.3 * _cover(have, pref), 0.0, 1.0)


static func _formula_fit(case_data: Dictionary, path: String, ids: Array) -> float:
	var key := "herbs" if path == "formula" else "points"
	var examples: Array = case_data.get("legal_formula_examples" if path == "formula" else "legal_point_examples", [])
	var have := {}
	for id in ids:
		have[str(id)] = true
	for ex in examples:
		if typeof(ex) != TYPE_DICTIONARY:
			continue
		var need: Array = ex.get(key, [])
		var ok := true
		var exset := {}
		for x in need:
			exset[str(x)] = true
			if not have.has(str(x)):
				ok = false
				break
		if ok and not exset.is_empty() and have.size() == exset.size():
			return 1.0
		if ok and not exset.is_empty():
			return 0.75
	return 0.35 if not ids.is_empty() else 0.0


static func _adjust(case_data: Dictionary, path: String, ids: Array) -> float:
	# Slice: prefer natures for formulas; count harmony for needles
	if path == "formula":
		var prefs: Array = case_data.get("preferred_natures", [])
		if prefs.is_empty() or ids.is_empty():
			return 0.5
		var ok := 0
		for hid in ids:
			var h: Dictionary = {}
			for row in CaseDB.pack.get("herbs", []):
				if typeof(row) == TYPE_DICTIONARY and str(row.get("id", "")) == str(hid):
					h = row
					break
			var nat := str(h.get("nature", ""))
			if nat in prefs or nat.replace("slightly_", "") in prefs:
				ok += 1
		return float(ok) / float(ids.size())
	var n := ids.size()
	return 1.0 if n >= 2 and n <= 5 else 0.4


static func _structure(path: String, ids: Array) -> float:
	if path == "formula":
		var n := ids.size()
		if n >= 3 and n <= 8:
			return 1.0
		if n >= 2:
			return 0.6
		return 0.2
	var m := ids.size()
	if m >= 2 and m <= 5:
		return 1.0
	return 0.4


static func _process_mult(exams: Dictionary, case_data: Dictionary) -> float:
	var flags := ["wang", "wen_listen", "wen_ask", "qie"]
	# accept look/listen/ask/pulse aliases
	var map := {
		"wang": ["wang", "look"],
		"wen_listen": ["wen_listen", "listen"],
		"wen_ask": ["wen_ask", "ask"],
		"qie": ["qie", "pulse"],
	}
	var miss := 0
	var miss_pri := 0
	var primary: Array = case_data.get("primary_exams", [])
	for e in flags:
		var done := false
		for k in map[e]:
			if bool(exams.get(k, false)):
				done = true
				break
		if not done:
			miss += 1
			if e in primary:
				miss_pri += 1
	return maxf(0.40, 1.0 - 0.12 * float(miss) - 0.08 * float(miss_pri))


static func _mistreat(case_data: Dictionary, path: String, ids: Array) -> bool:
	var have := _actions_of(case_data, path, ids)
	for a in case_data.get("forbidden_actions", []):
		if have.has(str(a)):
			return true
	return false


static func _rank_id(score: float) -> String:
	if score < 0.15:
		return "none"
	if score < 0.35:
		return "slight"
	if score < 0.55:
		return "work"
	if score < 0.75:
		return "clear"
	return "toward_heal"
