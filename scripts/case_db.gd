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
var process_pack: Dictionary = {}
var process_by_id: Dictionary = {}
var qingshi_expand_script: Dictionary = {}
var qingshi_expand2_script: Dictionary = {}
var qingshi_expand3_script: Dictionary = {}


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
	_load_process()
	_load_qingshi_expand()
	_load_qingshi_expand2()
	_load_qingshi_expand3()



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


func revisit_chief_complaint(pid: String, flavor_kind: String) -> String:
	## Light revisit main-complaint template by flavor (no LLM).
	var kind := flavor_kind if flavor_kind in ["good", "slow", "over", "mis"] else "good"
	var case_data := case_for_patient(pid)
	var rev: Variant = case_data.get("revisit", {})
	if typeof(rev) == TYPE_DICTIONARY:
		var lines: Variant = rev.get("lines_fallback", {})
		if typeof(lines) == TYPE_DICTIONARY and lines.has(kind):
			return UiKit.loc_text(lines[kind], "")
	var p := patient_by_id(pid)
	var custom: Variant = p.get("revisit_lines", {})
	if typeof(custom) == TYPE_DICTIONARY and custom.has(kind):
		return UiKit.loc_text(custom[kind], "")
	# i18n stubs by flavor
	var key := "REVISIT_LINE_%s" % kind.to_upper()
	var trl := TranslationServer.translate(key)
	if str(trl) != key and str(trl).strip_edges() != "":
		return str(trl)
	return TranslationServer.translate("REVISIT_STUB")


func herb(id: String) -> Dictionary:
	return herbs_by_id.get(id, {})


func point(id: String) -> Dictionary:
	return points_by_id.get(id, {})


func herb_name(id: String) -> String:
	return UiKit.loc_text(herb(id), id)


func food_item(id: String) -> Dictionary:
	for row in pack.get("food_items", []):
		if typeof(row) == TYPE_DICTIONARY and str(row.get("id", "")) == id:
			return row
	return {}


func food_name(id: String) -> String:
	var item := food_item(id)
	if item.is_empty():
		return id
	var key := "FOOD_%s_NAME" % id.to_upper()
	var trn := TranslationServer.translate(key)
	if trn != key and trn != "":
		return trn
	var loc := GameFlow.loc() if GameFlow else "zh"
	for k in [loc, "zh", "en"]:
		if item.has(k) and str(item.get(k, "")).strip_edges() != "":
			return str(item.get(k))
		if typeof(item.get("name")) == TYPE_DICTIONARY and str(item["name"].get(k, "")) != "":
			return str(item["name"][k])
	return str(item.get("name", id))


func food_desc(id: String) -> String:
	var item := food_item(id)
	var key := "FOOD_%s_DESC" % id.to_upper()
	var trn := TranslationServer.translate(key)
	if trn != key and trn != "":
		return trn
	var loc := GameFlow.loc() if GameFlow else "zh"
	var d: Variant = item.get("desc", item.get("blurb", {}))
	if typeof(d) == TYPE_DICTIONARY:
		return str(d.get(loc, d.get("zh", "")))
	return str(d)


func lifestyle_cues() -> Array:
	var rules: Dictionary = pack.get("food_therapy_rules", {})
	var arr: Variant = rules.get("lifestyle_cues", [])
	return arr if typeof(arr) == TYPE_ARRAY else []


func counsel_card(id: String) -> Dictionary:
	for row in pack.get("counsel_cards", []):
		if typeof(row) == TYPE_DICTIONARY and str(row.get("id", "")) == id:
			return row
	return {}


func counsel_i18n_stem(id: String) -> String:
	## Card ids are short; some text keys use longer stems (V133).
	match id:
		"no_rush_embroider":
			return "NO_RUSH_EMBROIDERY"
		"leave_lamp_on":
			return "LAMP_COMPANY"
		_:
			return id.to_upper()


func counsel_name(id: String) -> String:
	var item := counsel_card(id)
	if item.is_empty():
		return id
	var key := "COUNSEL_%s_NAME" % counsel_i18n_stem(id)
	var trn := TranslationServer.translate(key)
	if trn != key and trn != "":
		return trn
	var loc := GameFlow.loc() if GameFlow else "zh"
	for k in [loc, "zh", "en"]:
		if item.has(k) and str(item.get(k, "")).strip_edges() != "":
			return str(item.get(k))
		if typeof(item.get("name")) == TYPE_DICTIONARY and str(item["name"].get(k, "")) != "":
			return str(item["name"][k])
	return str(item.get("name", id))


func counsel_desc(id: String) -> String:
	var item := counsel_card(id)
	var key := "COUNSEL_%s_DESC" % counsel_i18n_stem(id)
	var trn := TranslationServer.translate(key)
	if trn != key and trn != "":
		return trn
	var loc := GameFlow.loc() if GameFlow else "zh"
	var d: Variant = item.get("desc", item.get("blurb", {}))
	if typeof(d) == TYPE_DICTIONARY:
		return str(d.get(loc, d.get("zh", "")))
	return str(d)




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



func _load_qingshi_expand() -> void:
	## Official V134 script pack: seals flash + case hints. Cards live in slice_characters.
	qingshi_expand_script = _load_json("res://patients/qingshi_expand_script.json")
	_ensure_qingshi_roster()


func _load_qingshi_expand2() -> void:
	## Official V135 expand2 script when present; else empty + roster fallback.
	qingshi_expand2_script = _load_json("res://patients/qingshi_expand2_script.json")
	_ensure_qingshi_expand2_roster()


func _ensure_qingshi_roster() -> void:
	## If slice JSON omitted the +3, pull minimal ids from official script + openings via i18n keys.
	var need := ["char_zoufan", "char_yanhou", "char_yaoqin"]
	var case_of := {"char_zoufan": "fengre_biao", "char_yanhou": "shiji", "char_yaoqin": "pixu_shikun"}
	var open_key := {"char_zoufan": "ZOUFAN_OPENING", "char_yanhou": "YANHOU_OPENING", "char_yaoqin": "YAOQIN_OPENING"}
	var name_key := {"char_zoufan": "CHAR_ZOUFAN_NAME", "char_yanhou": "CHAR_YANHOU_NAME", "char_yaoqin": "CHAR_YAOQIN_NAME"}
	var id_key := {"char_zoufan": "CHAR_ZOUFAN_TITLE", "char_yanhou": "CHAR_YANHOU_TITLE", "char_yaoqin": "CHAR_YAOQIN_TITLE"}
	var portraits := {"char_zoufan": "ui/characters/liu_heqing.png", "char_yanhou": "ui/characters/gu_yanyu.png", "char_yaoqin": "ui/characters/lin_ashen.png"}
	var seat_n := 4
	for pid in need:
		if patients_by_id.has(pid):
			continue
		var opening := tr(str(open_key.get(pid, "")))
		if opening == str(open_key.get(pid, "")) or opening == "":
			opening = ""
		var card := {
			"id": pid,
			"case_id": str(case_of.get(pid, "")),
			"seat": seat_n,
			"pool_only": true,
			"name": {"zh": tr(str(name_key.get(pid, ""))), "en": tr(str(name_key.get(pid, ""))), "ja": tr(str(name_key.get(pid, "")))},
			"identity": {"zh": tr(str(id_key.get(pid, ""))), "en": tr(str(id_key.get(pid, ""))), "ja": tr(str(id_key.get(pid, "")))},
			"opening": {"zh": opening, "en": opening, "ja": opening},
			"portrait_ref": str(portraits.get(pid, "")),
			"dodge": {
				"zh": "我不是来对那些名目的。问身上的感觉就好。",
				"en": "I did not come to match names. Ask what the body feels.",
				"ja": "呼び名を合わせに来たのではない。体の感覚を問うてくれ。"
			},
			"ask_wrappers": {
				"zh": ["……{sym}。", "小先生，{sym}。"],
				"en": ["…{sym}.", "Physician — {sym}."],
				"ja": ["……{sym}。", "小先生、{sym}。"],
			},
		}
		# Prefer portrait path from official script pack when present
		for row in qingshi_expand_script.get("characters", []):
			if typeof(row) == TYPE_DICTIONARY and str(row.get("id", "")) == pid:
				var por := str(row.get("portrait", ""))
				if por != "":
					card["portrait_ref"] = por
				var cid := str(row.get("case_id", ""))
				if cid != "":
					card["case_id"] = cid
		patients.append(card)
		patients_by_id[pid] = card
		seat_n += 1
	patients.sort_custom(func(a, b): return int(a.get("seat", 0)) < int(b.get("seat", 0)))


func _ensure_qingshi_expand2_roster() -> void:
	## V135 +3: prefer slice_characters / official expand2 script; else minimal i18n fallback.
	var need := ["char_danfu", "char_bashi", "char_jiaoli"]
	var case_of := {"char_danfu": "yangxu_weihan", "char_bashi": "xueyu_qing", "char_jiaoli": "shushi"}
	var open_key := {"char_danfu": "DANFU_OPENING", "char_bashi": "BASHI_OPENING", "char_jiaoli": "JIAOLI_OPENING"}
	var name_key := {"char_danfu": "CHAR_DANFU_NAME", "char_bashi": "CHAR_BASHI_NAME", "char_jiaoli": "CHAR_JIAOLI_NAME"}
	var id_key := {"char_danfu": "CHAR_DANFU_TITLE", "char_bashi": "CHAR_BASHI_TITLE", "char_jiaoli": "CHAR_JIAOLI_TITLE"}
	var portraits := {
		"char_danfu": "ui/characters/han_danfu.png",
		"char_bashi": "ui/characters/ma_bashi.png",
		"char_jiaoli": "ui/characters/xia_jiaoli.png",
	}
	var seat_n := 7
	for pid in need:
		if patients_by_id.has(pid):
			# Still overlay portrait/case from official script when present
			for row in qingshi_expand2_script.get("characters", []):
				if typeof(row) == TYPE_DICTIONARY and str(row.get("id", "")) == pid:
					var card_exist: Dictionary = patients_by_id[pid]
					var por := str(row.get("portrait", ""))
					if por != "":
						card_exist["portrait_ref"] = por
					var cid := str(row.get("case_id", ""))
					if cid != "":
						card_exist["case_id"] = cid
			continue
		var opening := tr(str(open_key.get(pid, "")))
		if opening == str(open_key.get(pid, "")) or opening == "":
			opening = ""
		var card := {
			"id": pid,
			"case_id": str(case_of.get(pid, "")),
			"seat": seat_n,
			"pool_only": true,
			"name": {"zh": tr(str(name_key.get(pid, ""))), "en": tr(str(name_key.get(pid, ""))), "ja": tr(str(name_key.get(pid, "")))},
			"identity": {"zh": tr(str(id_key.get(pid, ""))), "en": tr(str(id_key.get(pid, ""))), "ja": tr(str(id_key.get(pid, "")))},
			"opening": {"zh": opening, "en": opening, "ja": opening},
			"portrait_ref": str(portraits.get(pid, "")),
			"dodge": {
				"zh": "我不是来对那些名目的。问身上的感觉就好。",
				"en": "I did not come to match names. Ask what the body feels.",
				"ja": "呼び名を合わせに来たのではない。体の感覚を問うてくれ。"
			},
			"ask_wrappers": {
				"zh": ["……{sym}。", "小先生，{sym}。"],
				"en": ["…{sym}.", "Physician — {sym}."],
				"ja": ["……{sym}。", "小先生、{sym}。"],
			},
		}
		for row in qingshi_expand2_script.get("characters", []):
			if typeof(row) == TYPE_DICTIONARY and str(row.get("id", "")) == pid:
				var por2 := str(row.get("portrait", ""))
				if por2 != "":
					card["portrait_ref"] = por2
				var cid2 := str(row.get("case_id", ""))
				if cid2 != "":
					card["case_id"] = cid2
		patients.append(card)
		patients_by_id[pid] = card
		seat_n += 1
	patients.sort_custom(func(a, b): return int(a.get("seat", 0)) < int(b.get("seat", 0)))


func _load_qingshi_expand3() -> void:
	## Official V136 expand3 script when present; else empty + roster fallback (ids stable).
	qingshi_expand3_script = _load_json("res://patients/qingshi_expand3_script.json")
	_ensure_qingshi_expand3_roster()
	_ensure_expand3_herbs()


func _ensure_expand3_herbs() -> void:
	## Wire maidong / yiyiren into herbs_by_id if logic lists them but pack missed a row.
	var rules := qingshi_expand3_rules()
	var rows: Variant = rules.get("new_herbs", [])
	if typeof(rows) != TYPE_ARRAY:
		return
	for row in rows:
		if typeof(row) != TYPE_DICTIONARY:
			continue
		var hid := str(row.get("id", "")).strip_edges()
		if hid == "" or herbs_by_id.has(hid):
			continue
		# Minimal stub so formula tray / smoke can resolve id; prefer pack herbs when present.
		herbs_by_id[hid] = {
			"id": hid,
			"zh": hid,
			"en": hid,
			"ja": hid,
			"forage": bool(row.get("forage", false)),
			"note": str(row.get("note", "")),
		}


func _ensure_qingshi_expand3_roster() -> void:
	## V136 +3: prefer slice_characters / official expand3 script; else minimal i18n fallback.
	## Do not invent graphic 湿热/外伤 copy — openings come from TANFU_/TIANHAN_/MUJIANG_OPENING keys.
	var need := ["char_tanfu", "char_tianhan", "char_mujiang"]
	var case_of := {"char_tanfu": "yinxu_zaoke", "char_tianhan": "shire_xiazhu", "char_mujiang": "waishang_zhongtong"}
	var open_key := {"char_tanfu": "TANFU_OPENING", "char_tianhan": "TIANHAN_OPENING", "char_mujiang": "MUJIANG_OPENING"}
	var name_key := {"char_tanfu": "CHAR_TANFU_NAME", "char_tianhan": "CHAR_TIANHAN_NAME", "char_mujiang": "CHAR_MUJIANG_NAME"}
	var id_key := {"char_tanfu": "CHAR_TANFU_TITLE", "char_tianhan": "CHAR_TIANHAN_TITLE", "char_mujiang": "CHAR_MUJIANG_TITLE"}
	var portraits := {
		"char_tanfu": "ui/characters/qiu_tanfu.png",
		"char_tianhan": "ui/characters/he_tianhan.png",
		"char_mujiang": "ui/characters/lu_mujiang.png",
	}
	var seat_n := 10
	for pid in need:
		if patients_by_id.has(pid):
			for row in qingshi_expand3_script.get("characters", []):
				if typeof(row) == TYPE_DICTIONARY and str(row.get("id", "")) == pid:
					var card_exist: Dictionary = patients_by_id[pid]
					var por := str(row.get("portrait", ""))
					if por != "":
						card_exist["portrait_ref"] = por
					var cid := str(row.get("case_id", ""))
					if cid != "":
						card_exist["case_id"] = cid
			continue
		var opening := tr(str(open_key.get(pid, "")))
		if opening == str(open_key.get(pid, "")) or opening == "":
			opening = ""
		var nm := tr(str(name_key.get(pid, "")))
		if nm == str(name_key.get(pid, "")):
			nm = pid
		var title := tr(str(id_key.get(pid, "")))
		if title == str(id_key.get(pid, "")):
			title = ""
		var card := {
			"id": pid,
			"case_id": str(case_of.get(pid, "")),
			"seat": seat_n,
			"pool_only": true,
			"name": {"zh": nm, "en": nm, "ja": nm},
			"identity": {"zh": title, "en": title, "ja": title},
			"opening": {"zh": opening, "en": opening, "ja": opening},
			"portrait_ref": str(portraits.get(pid, "")),
			"dodge": {
				"zh": "我不是来对那些名目的。问身上的感觉就好。",
				"en": "I did not come to match names. Ask what the body feels.",
				"ja": "呼び名を合わせに来たのではない。体の感覚を問うてくれ。"
			},
			"ask_wrappers": {
				"zh": ["……{sym}。", "小先生，{sym}。"],
				"en": ["…{sym}.", "Physician — {sym}."],
				"ja": ["……{sym}。", "小先生、{sym}。"],
			},
		}
		for row in qingshi_expand3_script.get("characters", []):
			if typeof(row) == TYPE_DICTIONARY and str(row.get("id", "")) == pid:
				var por2 := str(row.get("portrait", ""))
				if por2 != "":
					card["portrait_ref"] = por2
				var cid2 := str(row.get("case_id", ""))
				if cid2 != "":
					card["case_id"] = cid2
		patients.append(card)
		patients_by_id[pid] = card
		seat_n += 1
	patients.sort_custom(func(a, b): return int(a.get("seat", 0)) < int(b.get("seat", 0)))


func qingshi_expand_rules() -> Dictionary:
	var rules: Dictionary = pack.get("qingshi_expand_rules", {})
	if rules.is_empty():
		var split: Dictionary = _load_json("res://logic/qingshi_expand.json")
		if not split.is_empty():
			return split
	return rules


func qingshi_expand2_rules() -> Dictionary:
	var rules: Dictionary = pack.get("qingshi_expand2_rules", {})
	if rules.is_empty():
		var split: Dictionary = _load_json("res://logic/qingshi_expand2.json")
		if not split.is_empty():
			return split
	return rules


func qingshi_expand3_rules() -> Dictionary:
	var rules: Dictionary = pack.get("qingshi_expand3_rules", {})
	if rules.is_empty():
		var split: Dictionary = _load_json("res://logic/qingshi_expand3.json")
		if not split.is_empty():
			return split
	return rules


func seal_flash_line(case_id: String) -> String:
	# Prefer expand3 → expand2 → V134 script, then i18n SEAL_* / SEAL_FLASH.
	for script_pack in [qingshi_expand3_script, qingshi_expand2_script, qingshi_expand_script]:
		if typeof(script_pack) != TYPE_DICTIONARY or script_pack.is_empty():
			continue
		var seals: Dictionary = script_pack.get("seals", {}) if typeof(script_pack.get("seals", {})) == TYPE_DICTIONARY else {}
		var flash: Variant = seals.get("flash_lines", {})
		if typeof(flash) == TYPE_DICTIONARY and flash.has(case_id):
			return UiKit.loc_text(flash[case_id], "")
		var items: Variant = seals.get("items", [])
		if typeof(items) == TYPE_ARRAY:
			for row in items:
				if typeof(row) == TYPE_DICTIONARY and str(row.get("case_id", "")) == case_id:
					var nm := UiKit.loc_text(row.get("name", {}), str(row.get("name_key", case_id)))
					var tmpl := UiKit.loc_text(seals.get("flash_template", {}), "")
					if tmpl != "" and tmpl.find("{name}") >= 0:
						return tmpl.replace("{name}", nm)
					var key := "SEAL_FLASH"
					var t := tr(key)
					if t != key and t != "":
						return t.replace("{name}", nm)
					return nm
	var key2 := "SEAL_%s" % case_id.to_upper()
	var nm2 := tr(key2)
	if nm2 == key2:
		nm2 = case_id
	var flash_tr := tr("SEAL_FLASH")
	if flash_tr != "SEAL_FLASH" and flash_tr != "":
		return flash_tr.replace("{name}", nm2)
	return nm2


func waiting_max_seats() -> int:
	for rules_x in [qingshi_expand3_rules(), qingshi_expand2_rules(), qingshi_expand_rules()]:
		var waiting_x: Dictionary = rules_x.get("waiting", {}) if typeof(rules_x.get("waiting", {})) == TYPE_DICTIONARY else {}
		if waiting_x.has("max_seats"):
			return int(waiting_x.get("max_seats", CharacterArt.WAITING_MAX_SEATS))
	return CharacterArt.WAITING_MAX_SEATS


func waiting_pool_ids() -> PackedStringArray:
	## Full roster (old four + V134/V135/V136 threes = 13). Hall shows ≤ max seats.
	var out := PackedStringArray()
	# Prefer PATIENT_ORDER when present in CaseDB
	for pid in CharacterArt.PATIENT_ORDER:
		if patients_by_id.has(pid) and pid not in out:
			out.append(pid)
	for p in patients:
		var pid := str(p.get("id", ""))
		if pid != "" and pid not in out:
			out.append(pid)
	for rules in [qingshi_expand_rules(), qingshi_expand2_rules(), qingshi_expand3_rules()]:
		var chars: Variant = rules.get("characters", [])
		if typeof(chars) == TYPE_ARRAY:
			for c in chars:
				var cid := str(c)
				if patients_by_id.has(cid) and cid not in out:
					out.append(cid)
	return out


func waiting_weight_for(pid: String, has_town_permit: bool, shiji_teach_seen: bool, yangxu_teach_seen: bool = true, zaoke_teach_seen: bool = true) -> float:
	var case_data := case_for_patient(pid)
	var case_id := str(case_data.get("id", ""))
	var rules := qingshi_expand_rules()
	var rules2 := qingshi_expand2_rules()
	var rules3 := qingshi_expand3_rules()
	var waiting: Dictionary = rules.get("waiting", {}) if typeof(rules.get("waiting", {})) == TYPE_DICTIONARY else {}
	var waiting2: Dictionary = rules2.get("waiting", {}) if typeof(rules2.get("waiting", {})) == TYPE_DICTIONARY else {}
	var waiting3: Dictionary = rules3.get("waiting", {}) if typeof(rules3.get("waiting", {})) == TYPE_DICTIONARY else {}
	var weights: Dictionary = waiting.get("weights", {}) if typeof(waiting.get("weights", {})) == TYPE_DICTIONARY else {}
	var weights2: Dictionary = waiting2.get("weights", {}) if typeof(waiting2.get("weights", {})) == TYPE_DICTIONARY else {}
	var weights3: Dictionary = waiting3.get("weights", {}) if typeof(waiting3.get("weights", {})) == TYPE_DICTIONARY else {}
	var base: Dictionary = weights.get("base", {}) if typeof(weights.get("base", {})) == TYPE_DICTIONARY else {}
	var base2: Dictionary = weights2.get("base", {}) if typeof(weights2.get("base", {})) == TYPE_DICTIONARY else {}
	var base3: Dictionary = weights3.get("base", {}) if typeof(weights3.get("base", {})) == TYPE_DICTIONARY else {}
	var without: Dictionary = weights.get("without_permit", {}) if typeof(weights.get("without_permit", {})) == TYPE_DICTIONARY else {}
	var without2: Dictionary = weights2.get("without_permit", {}) if typeof(weights2.get("without_permit", {})) == TYPE_DICTIONARY else {}
	var without3: Dictionary = weights3.get("without_permit", {}) if typeof(weights3.get("without_permit", {})) == TYPE_DICTIONARY else {}
	var mult := float(weights3.get("with_town_permit_mult", weights2.get("with_town_permit_mult", weights.get("with_town_permit_mult", 1.8))))
	# Old four: steady base so hall stays populated
	if pid in CharacterArt.OLD_FOUR:
		return 1.0
	var w := float(base3.get(case_id, base2.get(case_id, base.get(case_id, 0.2))))
	if has_town_permit:
		return w * mult
	# without permit: low weights; shiji / yangxu / zaoke teach-once boosts
	if case_id == "shiji":
		w = float(without.get("shiji_weight", 0.25))
		if bool(without.get("shiji_teach_once", true)) and not shiji_teach_seen:
			w = maxf(w, 0.55)
	elif case_id == "yangxu_weihan":
		w = float(without2.get("yangxu_weihan_weight", 0.25))
		if bool(without2.get("yangxu_weihan_teach_once", true)) and not yangxu_teach_seen:
			w = maxf(w, 0.55)
	elif case_id == "yinxu_zaoke":
		w = float(without3.get("yinxu_zaoke_weight", 0.25))
		if bool(without3.get("yinxu_zaoke_teach_once", true)) and not zaoke_teach_seen:
			w = maxf(w, 0.55)
	elif case_id in ["fengre_biao", "pixu_shikun"]:
		w = float(without.get(case_id, 0.05))
	elif case_id in ["xueyu_qing", "shushi"]:
		w = float(without2.get(case_id, 0.05))
	elif case_id in ["shire_xiazhu", "waishang_zhongtong"]:
		w = float(without3.get(case_id, 0.05))
	return w


func pick_waiting_seats(has_town_permit: bool, shiji_teach_seen: bool, exclude: Array = [], rng: RandomNumberGenerator = null, yangxu_teach_seen: bool = true, zaoke_teach_seen: bool = true) -> PackedStringArray:
	## Weighted sample without replacement, size ≤ waiting_max_seats().
	var max_n := waiting_max_seats()
	var pool := waiting_pool_ids()
	var candidates: Array = []
	var ws: Array = []
	for pid in pool:
		if str(pid) in exclude:
			continue
		var w := waiting_weight_for(str(pid), has_town_permit, shiji_teach_seen, yangxu_teach_seen, zaoke_teach_seen)
		if w <= 0.0:
			continue
		candidates.append(str(pid))
		ws.append(w)
	var picked := PackedStringArray()
	if candidates.is_empty():
		return picked
	var R := rng if rng != null else RandomNumberGenerator.new()
	if rng == null:
		R.randomize()
	while picked.size() < max_n and not candidates.is_empty():
		var total := 0.0
		for w in ws:
			total += float(w)
		if total <= 0.0:
			break
		var roll := R.randf() * total
		var acc := 0.0
		var idx := 0
		for i in candidates.size():
			acc += float(ws[i])
			if roll <= acc:
				idx = i
				break
		picked.append(str(candidates[idx]))
		candidates.remove_at(idx)
		ws.remove_at(idx)
	# Guarantee shiji teach-once appears if no permit and not yet seen
	if not has_town_permit and not shiji_teach_seen and "char_yanhou" not in picked and patients_by_id.has("char_yanhou"):
		if picked.size() >= max_n:
			picked[picked.size() - 1] = "char_yanhou"
		else:
			picked.append("char_yanhou")
	# Guarantee yangxu teach-once (V135) if no permit and not yet seen
	if not has_town_permit and not yangxu_teach_seen and "char_danfu" not in picked and patients_by_id.has("char_danfu"):
		if picked.size() >= max_n:
			# Prefer not to overwrite shiji teach seat when both pending
			var replace_i := picked.size() - 1
			if picked[replace_i] == "char_yanhou" and picked.size() >= 2:
				replace_i = picked.size() - 2
			picked[replace_i] = "char_danfu"
		else:
			picked.append("char_danfu")
	# Guarantee zaoke teach-once (V136) if no permit and not yet seen
	if not has_town_permit and not zaoke_teach_seen and "char_tanfu" not in picked and patients_by_id.has("char_tanfu"):
		if picked.size() >= max_n:
			var replace_z := picked.size() - 1
			# Prefer not to overwrite other teach seats
			while replace_z >= 0 and picked[replace_z] in ["char_yanhou", "char_danfu"]:
				replace_z -= 1
			if replace_z < 0:
				replace_z = picked.size() - 1
			picked[replace_z] = "char_tanfu"
		else:
			picked.append("char_tanfu")
	return picked


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
		{
			"id": "char_xiuniang",
			"case_id": "xuexu_ganyu",
			"age": 28,
			"seat": 3,
			"name": {"zh": "周绣娘", "en": "Zhou Xiuniang", "ja": "周繡娘"},
			"identity": {"zh": "绣坊主事", "en": "Embroidery workshop keeper", "ja": "繡坊の主事"},
			"region": {"zh": "青石镇", "en": "Qingshi town", "ja": "青石鎮"},
			"personality": {"zh": "要强、轻声、先说别人。", "en": "Strong-willed, soft-spoken; speaks of others first.", "ja": "気丈、声は細い。まず他人の話。"},
			"opening": {"zh": "睡不好。头也沉。做活做到一半，针会停在手里。", "en": "Sleep won't hold. The head feels heavy. Mid-stitch, the needle stops in my hand.", "ja": "眠れない。頭も重い。仕事の途中で、針が手の中で止まる。"},
			"dodge": {"zh": "那些名目我不会。你问睡得着吗、胸口沉不沉、针停不停，我还能答。", "en": "I don't know those book names. Ask sleep, chest heaviness, whether the needle stops.", "ja": "呼び名は知らん。眠れるか、胸が沈むか、針が止まるかなら答える。"},
			"death_day_line": {"zh": "……亡夫忌日近了。胸口像压着绣架。", "en": "…My late husband's memorial day is near. The chest feels like an embroidery frame pressing down.", "ja": "……亡き夫の忌日が近い。胸が繡架に圧されるよう。"},
			"dodge_daughter": {"zh": "……女儿的事，莫问。她还小。", "en": "…Don't ask about my daughter. She's still young.", "ja": "……娘のことは聞かないで。まだ小さい。"},
			"ask_wrappers": {
				"zh": ["……{sym}。说了也轻。", "就这些——{sym}。", "针停在手里的时候，{sym}。"],
				"en": ["…{sym}. Softly said.", "Just that — {sym}.", "When the needle stops, {sym}."],
				"ja": ["……{sym}。声は細い。", "そのくらい——{sym}。", "針が止まると、{sym}。"],
			},
			"ink": [0.32, 0.28, 0.34],
		},

		{
			"id": "char_zoufan",
			"case_id": "fengre_biao",
			"age": 17,
			"seat": 4,
			"pool_only": true,
			"name": {"zh": "刘禾青", "en": "Liu Heqing", "ja": "劉禾青"},
			"identity": {"zh": "镇口走贩", "en": "Town-gate peddler", "ja": "鎮口の走販"},
			"opening": {"zh": "嗓子火辣辣的。头也热。货还要往镇里送。", "en": "Throat burns. Head feels hot. Still got to haul goods into town.", "ja": "喉が熱い。頭も熱い。荷はまだ鎮へ運ぶ。"},
			"dodge": {"zh": "我不是来对那些名目的。你问嗓子火不火、头热不热——我再说。", "en": "I did not come to match names. Ask throat fire and hot head.", "ja": "呼び名を合わせに来たのではない。喉と頭の熱さなら答える。"},
			"ask_wrappers": {"zh": ["……{sym}。货还堆着。", "小先生，{sym}。"], "en": ["…{sym}. Goods still piled.", "Doc — {sym}."], "ja": ["……{sym}。荷がまだある。", "小先生、{sym}。"]},
			"ink": [0.42, 0.22, 0.28],
			"portrait_ref": "ui/characters/liu_heqing.png",
		},
		{
			"id": "char_yanhou",
			"case_id": "shiji",
			"age": 42,
			"seat": 5,
			"pool_only": true,
			"name": {"zh": "顾宴余", "en": "Gu Yanyu", "ja": "顧宴余"},
			"identity": {"zh": "宴后熟人", "en": "Banquet acquaintance", "ja": "宴のあとの知人"},
			"opening": {"zh": "昨晚席上吃猛了。脘胀、嗳气，不想动。", "en": "Ate too hard at last night's table. Epigastrium full, belching, no urge to move.", "ja": "昨夜の席で食べ過ぎた。脘が張り、噯気。動きたくない。"},
			"dodge": {"zh": "我不是来对那些名目的。你问昨夕吃了什么、胀在哪——我再说。", "en": "I did not come to match names. Ask what last evening held.", "ja": "呼び名を合わせに来たのではない。昨夕の食事なら答える。"},
			"ask_wrappers": {"zh": ["……{sym}。席上劝得凶。", "小先生，{sym}。"], "en": ["…{sym}. The toasts were fierce.", "Doc — {sym}."], "ja": ["……{sym}。席の勧がきつかった。", "小先生、{sym}。"]},
			"ink": [0.3, 0.34, 0.26],
			"portrait_ref": "ui/characters/gu_yanyu.png",
		},
		{
			"id": "char_yaoqin",
			"case_id": "pixu_shikun",
			"age": 48,
			"seat": 6,
			"pool_only": true,
			"name": {"zh": "林阿婶", "en": "Aunt Lin", "ja": "林のおば"},
			"identity": {"zh": "药农亲友", "en": "Herb farmer's kin", "ja": "薬農の親類"},
			"opening": {"zh": "身子困重，吃不下。苔腻那味，阿桂也闻过。", "en": "Body feels heavy and dull; can't eat much. That greasy-coating feel — A'gui smelled it too.", "ja": "体が重く困る。食べられない。膩苔の匂い、阿桂も嗅いだ。"},
			"dodge": {"zh": "我不是来对那些名目的。你问困不困、吃得下吗——我再说。", "en": "I did not come to match names. Ask heaviness and appetite.", "ja": "呼び名を合わせに来たのではない。困と食欲なら答える。"},
			"ask_wrappers": {"zh": ["……{sym}。阿桂也这么说。", "小先生，{sym}。"], "en": ["…{sym}. A'gui said so too.", "Physician — {sym}."], "ja": ["……{sym}。阿桂もそう言う。", "小先生、{sym}。"]},
			"ink": [0.26, 0.36, 0.3],
			"portrait_ref": "ui/characters/lin_ashen.png",
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




func forage_clues(hid: String) -> PackedStringArray:
	var out := PackedStringArray()
	var e := forage_entry(hid)
	var block: Variant = e.get("clues", [])
	var L := _loc_key()
	if typeof(block) == TYPE_ARRAY:
		for item in block:
			if typeof(item) == TYPE_DICTIONARY:
				var s := str(item.get(L, item.get("zh", ""))).strip_edges()
				if s != "":
					out.append(s)
			elif typeof(item) == TYPE_STRING:
				out.append(str(item))
		return out
	if typeof(block) == TYPE_DICTIONARY:
		var arr: Variant = block.get(L, block.get("zh", []))
		if typeof(arr) == TYPE_ARRAY:
			for x in arr:
				out.append(str(x))
	return out


func forage_identify_options(hid: String) -> Array:
	var e := forage_entry(hid)
	var opts: Variant = e.get("identify_options", [])
	if typeof(opts) == TYPE_ARRAY and not (opts as Array).is_empty():
		return opts
	return [hid]


func agui_hint() -> String:
	var tips: Variant = forage_pack.get("agui_tips", [])
	if typeof(tips) == TYPE_ARRAY and not (tips as Array).is_empty():
		var item = tips[randi() % tips.size()]
		if typeof(item) == TYPE_DICTIONARY:
			return UiKit.loc_text(item, "")
		return str(item)
	var ag: Variant = forage_pack.get("agui", {})
	if typeof(ag) == TYPE_DICTIONARY:
		var hints: Variant = ag.get("hints", {})
		if typeof(hints) == TYPE_DICTIONARY:
			var arr: Variant = hints.get(_loc_key(), hints.get("zh", []))
			if typeof(arr) == TYPE_ARRAY and not (arr as Array).is_empty():
				return str(arr[randi() % arr.size()])
	return ""

func mentor_forage_line() -> String:
	var line: Variant = forage_pack.get("mentor_line", forage_pack.get("mentor_su_line", {}))
	if typeof(line) == TYPE_DICTIONARY:
		return UiKit.loc_text(line, "")
	return str(line)


func _load_process() -> void:
	## Thin pack: logic/process_herbs.json → process_by_id.
	process_pack = _load_json("res://logic/process_herbs.json")
	process_by_id.clear()
	var rows: Variant = process_pack.get("herbs", [])
	if typeof(rows) != TYPE_ARRAY:
		return
	for row in rows:
		if typeof(row) != TYPE_DICTIONARY:
			continue
		var hid := str((row as Dictionary).get("id", "")).strip_edges()
		if hid == "":
			continue
		var entry: Dictionary = (row as Dictionary).duplicate(true)
		process_by_id[hid] = entry
		# Mirror process block onto slice herb when present.
		if herbs_by_id.has(hid):
			var h: Dictionary = herbs_by_id[hid]
			var block: Dictionary = {
				"needs_process": bool(entry.get("needs_process", false)),
				"process_method": str(entry.get("process_method", "")),
			}
			for k in ["mentor_lines", "xiaohe_lines", "warning", "block_reason"]:
				if entry.has(k):
					block[k] = entry[k]
			h["process"] = block
			herbs_by_id[hid] = h


func process_entry(hid: String) -> Dictionary:
	if process_by_id.has(hid):
		return process_by_id[hid] as Dictionary
	if herbs_by_id.has(hid):
		var p: Variant = (herbs_by_id[hid] as Dictionary).get("process", {})
		if typeof(p) == TYPE_DICTIONARY:
			return p as Dictionary
	return {}


func process_needs(hid: String) -> bool:
	var e: Dictionary = process_entry(hid)
	return bool(e.get("needs_process", false))
