extends Node
## slice_logic.json cases + patients/slice_characters.json cards.
## Join is bind_character_id / case_id only. No third case table.

var pack: Dictionary = {}
var characters: Dictionary = {}
var herbs_by_id: Dictionary = {}
var points_by_id: Dictionary = {}
var cases_by_id: Dictionary = {}
var patients: Array = []
var patients_by_id: Dictionary = {}
var apprentice: Dictionary = {}
var mentor: Dictionary = {}
var mentor_line_index: int = 0
var fanwei_pairs: Array = []
var fanwei_reasons: Dictionary = {}
var ten_asks: Array = []
var wenzhou_narration_keys: PackedStringArray = PackedStringArray()
var forage_pack: Dictionary = {}
var forage_by_id: Dictionary = {}
var forage_starter: PackedStringArray = PackedStringArray()


func _ready() -> void:
	pack = _load_json("res://logic/slice_logic.json")
	characters = _load_json("res://patients/slice_characters.json")
	apprentice = characters.get("apprentice", {})
	mentor = characters.get("mentor", {})  # clickable false → narration only
	patients = []
	for raw in characters.get("patients", []):
		if typeof(raw) == TYPE_DICTIONARY:
			patients.append(raw)
	if patients.is_empty():
		patients = _builtin_patients()
	patients.sort_custom(func(a, b): return int(a.get("seat", 0)) < int(b.get("seat", 0)))
	patients_by_id.clear()
	for p in patients:
		if typeof(p) == TYPE_DICTIONARY:
			var pid := str(p.get("id", ""))
			if pid != "":
				patients_by_id[pid] = p
	for h in pack.get("herbs", []):
		if typeof(h) == TYPE_DICTIONARY:
			herbs_by_id[str(h.get("id", ""))] = h
	for p in pack.get("acupoints", []):
		if typeof(p) == TYPE_DICTIONARY:
			points_by_id[str(p.get("id", ""))] = p
	for c in pack.get("cases", []):
		if typeof(c) == TYPE_DICTIONARY:
			cases_by_id[str(c.get("id", ""))] = c
	_load_fanwei_and_ten_asks()
	_apply_bind_join()
	_load_forage()



func _load_fanwei_and_ten_asks() -> void:
	var fw: Dictionary = _load_json("res://logic/fanwei_pairs.json")
	fanwei_pairs.clear()
	fanwei_reasons = fw.get("reason_short", {}) if typeof(fw.get("reason_short", {})) == TYPE_DICTIONARY else {}
	var pairs: Variant = fw.get("pairs", [])
	if typeof(pairs) == TYPE_ARRAY:
		for row in pairs:
			if typeof(row) != TYPE_DICTIONARY:
				continue
			var a := str(row.get("a", "")).strip_edges()
			var b := str(row.get("b", "")).strip_edges()
			if a == "" or b == "" or a == b:
				continue
			# Keep classic pairs even if one side is not in this slice cabinet (hook still valid).
			fanwei_pairs.append(row)
	# Prefer ten_questions.json (canonical); fall back to ten_asks.json stub.
	var tq: Dictionary = _load_json("res://logic/ten_questions.json")
	if tq.is_empty():
		tq = _load_json("res://logic/ten_asks.json")
	ten_asks.clear()
	var asks: Variant = tq.get("questions", tq.get("asks", []))
	if typeof(asks) == TYPE_ARRAY:
		for row in asks:
			if typeof(row) == TYPE_DICTIONARY:
				ten_asks.append(row)
	wenzhou_narration_keys = PackedStringArray()
	var cues: Variant = tq.get("mentor_cues", {})
	if typeof(cues) == TYPE_DICTIONARY:
		for k in cues.keys():
			wenzhou_narration_keys.append(str(k))
	var keys: Variant = tq.get("wenzhou_narration_keys", [])
	if typeof(keys) == TYPE_ARRAY:
		for k in keys:
			if str(k) not in wenzhou_narration_keys:
				wenzhou_narration_keys.append(str(k))


func _apply_bind_join() -> void:
	## Fill case_id from bind_character_id if a card omitted it. Do not invent ids.
	for c in pack.get("cases", []):
		if typeof(c) != TYPE_DICTIONARY:
			continue
		var bind := str(c.get("bind_character_id", ""))
		if bind == "" or not patients_by_id.has(bind):
			continue
		var card: Dictionary = patients_by_id[bind]
		if str(card.get("case_id", "")) == "":
			card["case_id"] = str(c.get("id", ""))


func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed


func patient_by_id(pid: String) -> Dictionary:
	if pid == "":
		return {}
	if patients_by_id.has(pid):
		return patients_by_id[pid]
	var case_data: Dictionary = cases_by_id.get(pid, {})
	var bind := str(case_data.get("bind_character_id", ""))
	if bind != "" and patients_by_id.has(bind):
		return patients_by_id[bind]
	for p in patients:
		if str(p.get("case_id", "")) == pid:
			return p
	return {}


func case_for_patient(pid: String) -> Dictionary:
	var p := patient_by_id(pid)
	if not p.is_empty():
		var cid := str(p.get("case_id", ""))
		if cid != "" and cases_by_id.has(cid):
			return cases_by_id[cid]
		var pid_id := str(p.get("id", ""))
		for c in cases_by_id.values():
			if typeof(c) == TYPE_DICTIONARY and str(c.get("bind_character_id", "")) == pid_id:
				return c
	if cases_by_id.has(pid):
		return cases_by_id[pid]
	for c in cases_by_id.values():
		if typeof(c) == TYPE_DICTIONARY and str(c.get("bind_character_id", "")) == pid:
			return c
	return {}


func character_id_for(pid: String) -> String:
	var p := patient_by_id(pid)
	var cid := str(p.get("id", ""))
	return cid if cid != "" else pid


func inquiry_rules() -> Dictionary:
	return characters.get("inquiry_rules", {})


func inquiry_rules_lines() -> PackedStringArray:
	var block: Dictionary = inquiry_rules()
	var key := _loc_key()
	var arr: Variant = block.get(key, block.get("zh", []))
	var out := PackedStringArray()
	if typeof(arr) == TYPE_ARRAY:
		for x in arr:
			out.append(str(x))
	return out


func hud_card(pid: String) -> Dictionary:
	## Player-facing identity only. Never diagnosis / never_say / formula names.
	var p := patient_by_id(pid)
	return {
		"name": UiKit.loc_text(p.get("name", {}), ""),
		"identity": UiKit.loc_text(p.get("identity", {}), ""),
		"age": str(p.get("age", "")),
		"region": UiKit.loc_text(p.get("region", {}), ""),
		"personality": UiKit.loc_text(p.get("personality", {}), ""),
	}


func hud_line(pid: String) -> String:
	var h := hud_card(pid)
	var bits: PackedStringArray = []
	if str(h.get("identity", "")) != "":
		bits.append(str(h["identity"]))
	if str(h.get("age", "")) != "":
		bits.append(str(h["age"]))
	if str(h.get("region", "")) != "":
		bits.append(str(h["region"]))
	return " · ".join(bits)


func opening_line(pid: String) -> String:
	return UiKit.loc_text(patient_by_id(pid).get("opening", {}), "")


func apprentice_name() -> String:
	# Prefer display name / slice_name (江晚); legacy "name" key still works.
	var n := UiKit.loc_text(apprentice.get("name", {}), "")
	if n != "":
		return n
	return UiKit.loc_text(apprentice.get("slice_name", {}), "")


func mentor_name() -> String:
	return UiKit.loc_text(mentor.get("name", {}), "")


func mentor_is_clickable() -> bool:
	return bool(mentor.get("clickable", false))


func mentor_case_cue(case_id: String = "") -> String:
	## Non-clickable 苏问舟 line from mentor.case_cues. Never diagnosis names.
	if case_id == "":
		case_id = str(case_for_patient(GameFlow.current_patient_id).get("id", ""))
	var block: Variant = mentor.get("case_cues", {}).get(case_id, {})
	if typeof(block) != TYPE_DICTIONARY:
		return ""
	var lines_v: Variant = block.get("lines", {})
	if typeof(lines_v) != TYPE_DICTIONARY:
		return ""
	var arr: Variant = lines_v.get(_loc_key(), lines_v.get("zh", []))
	if typeof(arr) != TYPE_ARRAY or (arr as Array).is_empty():
		return ""
	var lines: Array = arr
	var i := mentor_line_index % lines.size()
	mentor_line_index += 1
	return str(lines[i])


func mentor_exam_missing_cue(exam_id: String) -> String:
	var block: Variant = mentor.get("exam_missing_cues", {}).get(exam_id, {})
	if typeof(block) != TYPE_DICTIONARY:
		return ""
	var arr: Variant = block.get(_loc_key(), block.get("zh", []))
	if typeof(arr) != TYPE_ARRAY or (arr as Array).is_empty():
		return ""
	var lines: Array = arr
	return str(lines[randi() % lines.size()])


func mentor_affirm_line() -> String:
	var arr: Variant = mentor.get("affirm_short", {}).get(_loc_key(), mentor.get("affirm_short", {}).get("zh", []))
	if typeof(arr) == TYPE_ARRAY and not (arr as Array).is_empty():
		return str((arr as Array)[0])
	for key in ["MENTOR_AFFIRM", "MENTOR_SU_AFFIRM"]:
		var t := tr(key)
		if t != "" and t != key:
			return t
	return "这一问有了。"


func _song_to_tenq_id(song: String) -> String:
	var map := {
		"寒热": "hanre", "汗": "han", "头身": "toushen", "便": "bian",
		"饮食": "yinshi", "胸": "xiong", "聋": "ermu", "渴": "ke",
		"旧病": "jiubing", "因": "yin",
	}
	return str(map.get(song, song))


func mentor_tenq_missing_cue(qid: String, case_id: String = "") -> String:
	## Prefer case_cues when ask is in priority_ten_ask; else locale. Never diagnosis names.
	if case_id == "":
		case_id = str(case_for_patient(GameFlow.current_patient_id).get("id", ""))
	var block: Variant = mentor.get("case_cues", {}).get(case_id, {})
	if typeof(block) == TYPE_DICTIONARY:
		var pri: Variant = block.get("priority_ten_ask", [])
		var hit := false
		if typeof(pri) == TYPE_ARRAY:
			for song in pri:
				if _song_to_tenq_id(str(song)) == qid:
					hit = true
					break
		if hit:
			var lines_v: Variant = block.get("lines", {})
			if typeof(lines_v) == TYPE_DICTIONARY:
				var arr: Variant = lines_v.get(_loc_key(), lines_v.get("zh", []))
				if typeof(arr) == TYPE_ARRAY and not (arr as Array).is_empty():
					return str((arr as Array)[0])
	var key := ""
	match qid:
		"hanre":
			key = "MENTOR_TENQ_COLD"
		"han":
			key = "MENTOR_TENQ_SWEAT"
		_:
			key = ""
	if key != "":
		var t := tr(key)
		if t != "" and t != key:
			return t
	match qid:
		"hanre":
			return "他添衣还是减衣，你问了？"
		"han":
			return "出汗了没有——这一句能挡掉一半胡开。"
	return ""


func _tenq_was_asked(qid: String) -> bool:
	if typeof(GameFlow.tenq_asked) == TYPE_ARRAY and qid in GameFlow.tenq_asked:
		return true
	if typeof(GameFlow.ten_asks_asked) == TYPE_ARRAY and qid in GameFlow.ten_asks_asked:
		return true
	return false


func mentor_cue_for_visit() -> String:
	## V120: pending affirm → missing 寒热/汗 → 缺望/闻/问/切 → else silent (喝茶).
	if GameFlow.mentor_pending_affirm:
		return mentor_affirm_line()
	var case_id := str(case_for_patient(GameFlow.current_patient_id).get("id", ""))
	for qid in ["hanre", "han"]:
		if not _tenq_was_asked(qid):
			var tenq_cue := mentor_tenq_missing_cue(qid, case_id)
			if tenq_cue != "":
				return tenq_cue
	var exams_incomplete := false
	if typeof(GameFlow.exams) == TYPE_DICTIONARY:
		for exam in ["wen_ask", "qie", "wang", "wen_listen"]:
			if not bool(GameFlow.exams.get(exam, false)):
				exams_incomplete = true
				var m := mentor_exam_missing_cue(exam)
				if m != "":
					return m
	if not exams_incomplete and _tenq_was_asked("hanre") and _tenq_was_asked("han"):
		return ""
	return mentor_case_cue(case_id)


func pharmacy_kid() -> Dictionary:
	var kid: Variant = characters.get("pharmacy_kid", {})
	return kid if typeof(kid) == TYPE_DICTIONARY else {}


func pharmacy_kid_is_clickable() -> bool:
	## Slice: always false (UI voice only, no 代诊).
	return bool(pharmacy_kid().get("clickable", false))


func pharmacy_kid_line(kind: String = "waiting") -> String:
	## UI voice only. Not clickable, never 代诊.
	var kid := pharmacy_kid()
	var ui: Variant = kid.get("ui_lines", {})
	if typeof(ui) != TYPE_DICTIONARY:
		return ""
	var block: Variant = ui.get(kind, {})
	if typeof(block) != TYPE_DICTIONARY:
		return ""
	var arr: Variant = block.get(_loc_key(), block.get("zh", []))
	if typeof(arr) != TYPE_ARRAY or (arr as Array).is_empty():
		return ""
	var lines: Array = arr
	var line := str(lines[randi() % lines.size()])
	var waiting_n := 0
	for p in patients:
		if typeof(p) == TYPE_DICTIONARY and not GameFlow.is_seen(str(p.get("id", ""))):
			waiting_n += 1
	return line.replace("{n}", str(maxi(waiting_n, 1)))


func followup_template(pid: String) -> String:
	var p := patient_by_id(pid)
	if p.is_empty():
		return ""
	var fu: Variant = p.get("followup", {})
	if typeof(fu) == TYPE_DICTIONARY:
		return UiKit.loc_text(fu, "")
	return str(fu)


func herb(id: String) -> Dictionary:
	return herbs_by_id.get(id, {})


func point(id: String) -> Dictionary:
	return points_by_id.get(id, {})


func herb_name(id: String) -> String:
	return UiKit.loc_text(herb(id), id)


func point_name(id: String) -> String:
	var p := point(id)
	if p.is_empty():
		return id
	return UiKit.loc_text(p, id)


func named_herb(h: Dictionary) -> String:
	return UiKit.loc_text(h, str(h.get("id", "")))


func named_point(p: Dictionary) -> String:
	return UiKit.loc_text(p, str(p.get("id", "")))


func _loc_key() -> String:
	var loc := TranslationServer.get_locale()
	if loc.begins_with("en"):
		return "en"
	if loc.begins_with("ja"):
		return "ja"
	return "zh"


func _builtin_patients() -> Array:
	## Last-resort cards if JSON missing. Same ids as slice_characters.json.
	return [
		{
			"id": "char_porter",
			"case_id": "fenghan_biao",
			"age": 34,
			"seat": 0,
			"name": {"zh": "赵阿福", "en": "Zhao Afu", "ja": "趙阿福"},
			"identity": {"zh": "码头脚夫", "en": "Wharf porter", "ja": "波止場の担ぎ手"},
			"region": {"zh": "江南水乡", "en": "Jiangnan canals", "ja": "江南の水郷"},
			"personality": {"zh": "爽快、怕麻烦、话少。", "en": "Blunt, hates fuss, few words.", "ja": "気さく、面倒嫌い、寡黙。"},
			"opening": {"zh": "师傅，我站着说就行。夜里江上风大，今早扛了两趟就不对劲。", "en": "Doc, I can stand. Wind off the river last night — two loads this morning and I was off.", "ja": "先生、立ったままでいい。夜の川風が強くて、今朝二往復したらおかしくなった。"},
			"dodge": {"zh": "那些医书上的叫法我不会。你问身上冷不冷、出不出汗、鼻涕什么色，我还能答。", "en": "I don't know the book names. Ask if I'm cold, if I sweat, what color the snot is — I can answer that.", "ja": "医書の呼び名は知らん。寒いか、汗は出るか、鼻水の色なら答えられる。"},
			"ask_wrappers": {
				"zh": ["怎么说呢，{sym}。别的我也不懂。", "就那点子事——{sym}。", "不瞒你，{sym}。问太细我答不上。"],
				"en": ["How to put it… {sym}. That's all I know.", "Just that — {sym}.", "I'll be straight: {sym}."],
				"ja": ["何というか、{sym}。ほかは分からん。", "そのくらいだ——{sym}。", "正直に言うと、{sym}。"],
			},
			"ink": [0.42, 0.36, 0.3],
		},
		{
			"id": "char_clerk",
			"case_id": "ganyu_qizhi",
			"age": 27,
			"seat": 1,
			"name": {"zh": "沈清荷", "en": "Shen Qinghe", "ja": "沈清荷"},
			"identity": {"zh": "县衙书办", "en": "Yamen clerk", "ja": "県衙の書記"},
			"region": {"zh": "江南县城", "en": "A Jiangnan county seat", "ja": "江南の県城"},
			"personality": {"zh": "体面、含蓄。说话前先叹气。", "en": "Composed, reserved. Sighs first.", "ja": "体裁を気にし、含蓄がある。"},
			"opening": {"zh": "……坐一下就走。不是什么大病，只是近来写字写不下去。", "en": "…I won't stay long. Nothing grave. Lately the writing will not go.", "ja": "……少しだけ。大病ではない。このごろ字が書けない。"},
			"dodge": {"zh": "我不是来对那些名目的。你问胸口闷不闷、叹完气松不松、夜里醒几次，我再说。", "en": "I did not come to match names. Ask if the chest is tight, if a sigh helps, how often I wake — then I will answer.", "ja": "呼び名を合わせに来たのではない。胸が悶えるか、溜息で楽か、夜に何度起きるかなら答える。"},
			"ask_wrappers": {
				"zh": ["……{sym}。说了也像没说。", "近来{sym}。其余不必记。", "叹口气吧。{sym}。"],
				"en": ["…{sym}. Saying it barely helps.", "Lately {sym}.", "A long breath. {sym}."],
				"ja": ["……{sym}。言っても言わないようだ。", "このごろ{sym}。", "溜息が先に出る。{sym}。"],
			},
			"ink": [0.28, 0.3, 0.34],
		},
		{
			"id": "char_copyist",
			"case_id": "yinxu_neire",
			"age": 61,
			"seat": 2,
			"name": {"zh": "周婆婆", "en": "Granny Zhou", "ja": "周ばあさん"},
			"identity": {"zh": "抄经香铺老人", "en": "Incense-shop copyist", "ja": "香舗の写経の老女"},
			"region": {"zh": "内陆小镇", "en": "An inland market town", "ja": "内陸の町"},
			"personality": {"zh": "软声、客气，怕添麻烦。", "en": "Soft-spoken, polite, hates to impose.", "ja": "声が柔らかく、遠慮深い。"},
			"opening": {"zh": "劳您了。人老了，夜里总不安生。坐一坐就走，不耽误你们看别人。", "en": "Sorry to trouble you. At my age the nights will not sit still. A short sit, then I go.", "ja": "お手数を。年のせいか、夜が落ち着かない。少し座ったら帰ります。"},
			"dodge": {"zh": "那些方书上的名字，我叫不上来。您问夜里出不出汗、嘴里干不干、手脚心里热不热就好。", "en": "I cannot name what the books name. Ask about night sweat, a dry mouth, heat in the palms and soles.", "ja": "方書の名は言えません。夜の汗、口の渇き、手足の裏の熱さを問うてください。"},
			"ask_wrappers": {
				"zh": ["劳您问。{sym}。", "人老了，{sym}。不值得大惊小怪。", "说出来不好意思……{sym}。"],
				"en": ["Kind of you to ask. {sym}.", "At my age, {sym}. Nothing to make a fuss of.", "It's a little embarrassing… {sym}."],
				"ja": ["お尋ねくださり。{sym}。", "年のせいか、{sym}。大層なことではない。", "言いづらいのですが……{sym}。"],
			},
			"ink": [0.38, 0.26, 0.24],
		},
	]


func _load_forage() -> void:
	## Load logic/forage_herbs.json (script text already merged). Cap 12.
	forage_pack = _load_json("res://logic/forage_herbs.json")
	if forage_pack.is_empty():
		forage_pack = _load_json("res://patients/forage_script.json")
	forage_by_id.clear()
	forage_starter = PackedStringArray()
	var known: Variant = forage_pack.get("starter_known", [])
	if typeof(known) == TYPE_ARRAY:
		for k in known:
			var kid := str(k)
			if kid != "" and kid not in forage_starter:
				forage_starter.append(kid)
	var rows: Variant = forage_pack.get("herbs", [])
	if typeof(rows) != TYPE_ARRAY:
		return
	for row in rows:
		if typeof(row) != TYPE_DICTIONARY:
			continue
		var hid := str(row.get("id", "")).strip_edges()
		if hid == "":
			continue
		if forage_by_id.size() >= 12:
			break
		var entry: Dictionary = (row as Dictionary).duplicate(true)
		entry["enabled"] = bool(entry.get("enabled", true))
		var spot := str(entry.get("scene_spot", entry.get("spot_id", "")))
		if spot == "":
			spot = "SPOT_A"
		# Accept legacy spot_* aliases
		if spot.begins_with("spot_"):
			var map := {"spot_trellis": "SPOT_A", "spot_bed": "SPOT_B", "spot_ditch": "SPOT_C"}
			spot = str(map.get(spot, "SPOT_A"))
		entry["scene_spot"] = spot
		entry["spot_id"] = spot
		if not entry.has("identify_correct") or str(entry.get("identify_correct", "")) == "":
			entry["identify_correct"] = hid
		forage_by_id[hid] = entry
		# Mirror forage block onto slice herb row when present (tray / Forage helpers).
		if herbs_by_id.has(hid):
			var h: Dictionary = herbs_by_id[hid]
			var block: Dictionary = {
				"enabled": true,
				"scene_spot": spot,
				"spot_id": spot,
				"spot_label": _forage_spot_label_dict(spot),
				"clues": entry.get("clues", []),
				"identify_options": entry.get("identify_options", [hid]),
				"identify_correct": hid,
				"yield": entry.get("yield", 1),
			}
			h["forage"] = block


func _forage_spot_label_dict(spot: String) -> Dictionary:
	for s in forage_pack.get("spots", []):
		if typeof(s) == TYPE_DICTIONARY and str(s.get("id", "")) == spot:
			return {"zh": str(s.get("zh", spot)), "en": str(s.get("en", spot)), "ja": str(s.get("ja", spot))}
	return {"zh": spot, "en": spot, "ja": spot}


func forage_starter_known() -> PackedStringArray:
	return forage_starter


func forage_herb_ids() -> PackedStringArray:
	var out := PackedStringArray()
	for k in forage_by_id.keys():
		out.append(str(k))
	return out


func forage_entry(hid: String) -> Dictionary:
	if forage_by_id.has(hid):
		return forage_by_id[hid]
	return {}


func forage_yield(hid: String) -> int:
	var e := forage_entry(hid)
	var y: Variant = e.get("yield", 1)
	if typeof(y) == TYPE_DICTIONARY:
		return maxi(1, int(y.get("min", 1)))
	return maxi(1, int(y))


func mentor_forage_line() -> String:
	var line: Variant = forage_pack.get("mentor_line", forage_pack.get("mentor_su_line", {}))
	if typeof(line) == TYPE_DICTIONARY:
		return UiKit.loc_text(line, "")
	return str(line)
