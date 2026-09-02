class_name Scoring
extends RefCounted
## Efficacy scoring from logic/slice_logic.json. No unique correct answer.


static func evaluate(case_data: Dictionary, exams_done: Dictionary, path: String, ids: Array) -> Dictionary:
	var scoring: Dictionary = CaseDB.pack.get("scoring", {})
	var process_mult := _process_mult(case_data, exams_done, scoring)
	var actions := {}
	var natures: Array = []
	var zheng := 0
	var onset_vals: Array = []
	var over_action_hits := 0
	var over_treat_actions: Array = case_data.get("over_treat_actions", [])
	for raw in ids:
		var id := str(raw)
		var item: Dictionary
		if path == "formula":
			item = CaseDB.herb(id)
			natures.append(str(item.get("nature", "neutral")))
			zheng += int(item.get("zheng_cost", 0))
			onset_vals.append(_onset_num(str(item.get("onset", "medium"))))
		else:
			item = CaseDB.point(id)
		if item.is_empty():
			continue
		var hit_over := false
		for a in item.get("actions", []):
			actions[str(a)] = true
			if str(a) in over_treat_actions:
				hit_over = true
		if hit_over:
			over_action_hits += 1
	var pattern := 0.0
	if path == "formula":
		pattern = _formula_pattern(case_data, scoring, actions, natures, ids)
	else:
		pattern = _acu_pattern(case_data, scoring, actions, ids)
		onset_vals.append(_acu_onset_num(case_data, ids))
	var mistreat := false
	for a in case_data.get("forbidden_actions", []):
		if actions.has(str(a)):
			mistreat = true
			break
	var overtreat := false
	if path == "formula":
		if zheng > int(case_data.get("over_treat_zheng_cost", 99)):
			overtreat = true
		if ids.size() > int(scoring.get("overtreat", {}).get("if_herb_count_gt", 8)):
			overtreat = true
	else:
		if ids.size() > int(scoring.get("overtreat", {}).get("if_point_count_gt", 5)):
			overtreat = true
	if over_action_hits >= int(scoring.get("overtreat", {}).get("if_over_treat_action_count_gte", 3)):
		overtreat = true
	var speed := _speed(case_data, scoring, onset_vals)
	var mis_pen := float(scoring.get("mistreat", {}).get("penalty", 0.35)) if mistreat else 0.0
	var over_pen := float(scoring.get("overtreat", {}).get("penalty", 0.12)) if overtreat else 0.0
	var score := pattern * process_mult - mis_pen - over_pen + float(speed.get("mod", 0.0))
	score = clampf(score, 0.0, 1.0)
	var rank := _rank(scoring, score)
	if mistreat:
		var cap := _rank_by_id(scoring, "slight")
		if float(rank.get("min", 0.0)) > float(cap.get("min", 0.15)):
			rank = cap
			score = minf(score, float(cap.get("max", 0.35)) - 0.001)
	var flavor_kind := "good"
	if mistreat:
		flavor_kind = "mis"
	elif overtreat:
		flavor_kind = "over"
	elif str(speed.get("id", "")) == "slow":
		flavor_kind = "slow"
	var flavor: Dictionary = case_data.get("settlement_flavor", {}).get(flavor_kind, {})
	var missing := false
	for e in ["wang", "wen_listen", "wen_ask", "qie"]:
		if not bool(exams_done.get(e, false)):
			missing = true
	return {
		"score": score,
		"rank_id": str(rank.get("id", "none")),
		"rank_key": _rank_key(str(rank.get("id", "none"))),
		"pattern": pattern,
		"process_mult": process_mult,
		"mistreat": mistreat,
		"overtreat": overtreat,
		"speed_id": str(speed.get("id", "none")),
		"speed_key": str(speed.get("key", "SPEED_STEADY")),
		"flavor": flavor,
		"missing_exams": missing,
		"path": path,
		"ids": ids.duplicate(),
	}


static func _process_mult(case_data: Dictionary, exams_done: Dictionary, scoring: Dictionary) -> float:
	var cfg: Dictionary = scoring.get("process", {})
	var missing := 0
	var missing_primary := 0
	var primary: Array = case_data.get("primary_exams", [])
	for e in ["wang", "wen_listen", "wen_ask", "qie"]:
		if not bool(exams_done.get(e, false)):
			missing += 1
			if e in primary:
				missing_primary += 1
	var m := 1.0 - float(cfg.get("missing_exam_penalty", 0.12)) * missing \
			- float(cfg.get("missing_primary_exam_extra", 0.08)) * missing_primary
	return maxf(float(cfg.get("min_multiplier", 0.4)), m)


static func _formula_pattern(case_data: Dictionary, scoring: Dictionary, actions: Dictionary, natures: Array, ids: Array) -> float:
	var cfg: Dictionary = scoring.get("pattern_match", {}).get("formula_path", {})
	var req := _cover(actions, case_data.get("required_actions", []))
	var pref := _cover(actions, case_data.get("preferred_actions", []))
	var nat := _nature_score(case_data, natures)
	var pattern: float = req * float(cfg.get("required_cover_weight", 0.55)) \
			+ pref * float(cfg.get("preferred_cover_weight", 0.25)) \
			+ nat * float(cfg.get("nature_weight", 0.2))
	if _matches_example(ids, case_data.get("legal_formula_examples", []), "herbs"):
		pattern = minf(1.0, pattern + float(cfg.get("legal_example_bonus", 0.08)))
	return clampf(pattern, 0.0, 1.0)


static func _acu_pattern(case_data: Dictionary, scoring: Dictionary, actions: Dictionary, ids: Array) -> float:
	var cfg: Dictionary = scoring.get("pattern_match", {}).get("acupuncture_path", {})
	var req := _cover(actions, case_data.get("required_actions", []))
	var pref := _cover(actions, case_data.get("preferred_actions", []))
	var n := ids.size()
	var harmony := 0.2
	if n >= 2 and n <= 5:
		harmony = 1.0
	elif n == 1 or n == 6:
		harmony = 0.5
	var pattern: float = req * float(cfg.get("required_cover_weight", 0.6)) \
			+ pref * float(cfg.get("preferred_cover_weight", 0.25)) \
			+ harmony * float(cfg.get("count_harmony_weight", 0.15))
	if _matches_example(ids, case_data.get("legal_point_examples", []), "points"):
		pattern = minf(1.0, pattern + float(cfg.get("legal_example_bonus", 0.08)))
	return clampf(pattern, 0.0, 1.0)


static func _cover(actions: Dictionary, wanted: Array) -> float:
	if wanted.is_empty():
		return 1.0
	var hit := 0
	for a in wanted:
		if actions.has(str(a)):
			hit += 1
	return float(hit) / float(wanted.size())


static func _nature_score(case_data: Dictionary, natures: Array) -> float:
	if natures.is_empty():
		return 0.0
	var preferred: Array = case_data.get("preferred_natures", [])
	var parents: Dictionary = CaseDB.pack.get("nature_parent", {})
	var hit := 0
	for n in natures:
		var ns := str(n)
		var parent := str(parents.get(ns, ns))
		var ok := false
		for p in preferred:
			var ps := str(p)
			var pparent := str(parents.get(ps, ps))
			if ns == ps or parent == ps or parent == pparent:
				ok = true
				break
		if ok:
			hit += 1
	return float(hit) / float(natures.size())


static func _matches_example(ids: Array, examples: Array, key: String) -> bool:
	var have := {}
	for id in ids:
		have[str(id)] = true
	for ex in examples:
		var want: Array = ex.get(key, [])
		if want.size() != have.size():
			continue
		var ok := true
		for w in want:
			if not have.has(str(w)):
				ok = false
				break
		if ok:
			return true
	return false


static func _onset_num(onset: String) -> float:
	match onset:
		"fast":
			return 2.0
		"slow":
			return 0.0
		_:
			return 1.0


static func _acu_onset_num(case_data: Dictionary, ids: Array) -> float:
	for ex in case_data.get("legal_point_examples", []):
		if _matches_example(ids, [ex], "points"):
			return _onset_num(str(ex.get("onset", "medium")))
	var fast := 0
	var slow := 0
	for id in ids:
		var item := CaseDB.point(str(id))
		for a in item.get("actions", []):
			var s := str(a)
			if s in ["release_exterior", "move_qi", "induce_sweat"]:
				fast += 1
			if s in ["nourish_yin", "nourish_blood", "tonify_kidney"]:
				slow += 1
	if fast > slow + 1:
		return 2.0
	if slow > fast + 1:
		return 0.0
	return 1.0


static func _speed(case_data: Dictionary, scoring: Dictionary, onset_vals: Array) -> Dictionary:
	var cfg: Dictionary = scoring.get("speed", {})
	var numeric: Dictionary = cfg.get("numeric", {})
	if onset_vals.is_empty():
		return {"id": "none", "key": "SPEED_SLOW", "mod": 0.15 * (float(numeric.get("none", 0.2)) - 0.7)}
	var mean := 0.0
	for v in onset_vals:
		mean += float(v)
	mean /= float(onset_vals.size())
	var treat := "medium"
	if mean >= 1.5:
		treat = "fast"
	elif mean <= 0.5:
		treat = "slow"
	var urgency := str(case_data.get("urgency", "medium"))
	var sid := "steady"
	if treat == "fast" and urgency in ["medium", "high"]:
		sid = "fast"
	elif treat == "slow" and urgency == "low":
		sid = "steady"
	elif treat == "fast" and urgency == "low":
		sid = "a_bit_rushed"
	elif treat == "slow" and urgency in ["medium", "high"]:
		sid = "slow"
	var key := "SPEED_STEADY"
	match sid:
		"fast":
			key = "SPEED_FAST"
		"a_bit_rushed":
			key = "SPEED_RUSHED"
		"slow":
			key = "SPEED_SLOW"
	var num := float(numeric.get(sid, 0.7))
	return {"id": sid, "key": key, "mod": float(cfg.get("mod_on_final", 0.15)) * (num - 0.7)}


static func _rank(scoring: Dictionary, score: float) -> Dictionary:
	for r in scoring.get("player_facing_ranks", []):
		if score >= float(r.get("min", 0.0)) and score < float(r.get("max", 1.0)):
			return r
	return {"id": "none", "min": 0.0, "max": 0.15}


static func _rank_by_id(scoring: Dictionary, rid: String) -> Dictionary:
	for r in scoring.get("player_facing_ranks", []):
		if str(r.get("id", "")) == rid:
			return r
	return {"id": "slight", "min": 0.15, "max": 0.35}


static func _rank_key(rid: String) -> String:
	match rid:
		"slight":
			return "SCORE_SLIGHT"
		"work":
			return "SCORE_WORK"
		"clear":
			return "SCORE_CLEAR"
		"toward_heal":
			return "SCORE_HEAL"
		_:
			return "SCORE_NONE"
