extends Node
## V129 night-read loft: spend night slot 1 → unlock theory nodes. Autoload Codex.

signal page_unlocked(page_id: String, theory_id: String)
signal entered_loft
signal left_loft

const LOFT_SCENE := "res://scenes/loft.tscn"
const CLINIC_SCENE := "res://scenes/clinic.tscn"
const SCRIPT_PATH := "res://patients/codex_script.json"

var _script: Dictionary = {}
## True after a successful night spend this session enter (for UI tip).
var last_enter_was_review: bool = false
var last_tip: String = ""


func _ready() -> void:
	_load_script()
	_ensure_play_fields()


func _load_script() -> void:
	if not FileAccess.file_exists(SCRIPT_PATH):
		_script = {}
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SCRIPT_PATH))
	_script = parsed if typeof(parsed) == TYPE_DICTIONARY else {}


func codex_script() -> Dictionary:
	if _script.is_empty():
		_load_script()
	return _script


func _ensure_play_fields() -> void:
	if typeof(Save.data.get("play")) != TYPE_DICTIONARY:
		Save.data["play"] = {}
	var play: Dictionary = Save.data["play"]
	if typeof(play.get("time_slots")) != TYPE_DICTIONARY:
		play["time_slots"] = {"morning": 1, "afternoon": 1, "evening": 1, "night": 1}
	else:
		var slots: Dictionary = play["time_slots"]
		if not slots.has("night"):
			slots["night"] = 1
		if not slots.has("evening"):
			slots["evening"] = 1
		play["time_slots"] = slots
	if typeof(play.get("codex_unlocked")) != TYPE_ARRAY:
		play["codex_unlocked"] = []
	if typeof(play.get("theory_nodes")) != TYPE_ARRAY:
		play["theory_nodes"] = []
	Save.data["play"] = play


func _play() -> Dictionary:
	_ensure_play_fields()
	return Save.data["play"] as Dictionary


func _loc() -> String:
	return str(Save.data.get("locale", "zh"))


func loc_text(d: Variant, fallback: String = "") -> String:
	if typeof(d) == TYPE_DICTIONARY:
		var L := _loc()
		var s := str((d as Dictionary).get(L, (d as Dictionary).get("zh", ""))).strip_edges()
		if s != "":
			return s
	return fallback


func pages() -> Array:
	var out: Array = []
	for row in codex_script().get("pages", []):
		if typeof(row) == TYPE_DICTIONARY:
			out.append(row)
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("order", 0)) < int(b.get("order", 0))
	)
	return out


func page_by_id(page_id: String) -> Dictionary:
	for row in pages():
		if str((row as Dictionary).get("id", "")) == page_id:
			return row as Dictionary
	return {}


func page_title(page: Dictionary) -> String:
	var key := str(page.get("title_key", ""))
	if key != "":
		var t := tr(key)
		if t != key and t != "":
			return t
	return loc_text(page.get("title", {}), str(page.get("id", "")))


func page_body(page: Dictionary) -> String:
	var key := str(page.get("body_key", ""))
	if key != "":
		var t := tr(key)
		if t != key and t != "":
			return t
	return loc_text(page.get("body", {}), "")


func tenq_quote() -> String:
	var page := page_by_id("tenq_song")
	var key := str(page.get("quote_key", "CODEX_PAGE_TENQ_QUOTE"))
	var t := tr(key)
	if t != key and t != "":
		return t
	return loc_text(page.get("quote", {}), "一问寒热二问汗……")


func unlocked_pages() -> Array:
	var play := _play()
	var arr: Variant = play.get("codex_unlocked", [])
	return arr if typeof(arr) == TYPE_ARRAY else []


func theory_nodes() -> Array:
	var play := _play()
	var arr: Variant = play.get("theory_nodes", [])
	return arr if typeof(arr) == TYPE_ARRAY else []


func is_page_unlocked(page_id: String) -> bool:
	return page_id in unlocked_pages()


func has_theory(node_id: String) -> bool:
	if node_id in theory_nodes():
		return true
	# Also accept bare id without theory. prefix
	var bare := node_id
	if bare.begins_with("theory."):
		bare = bare.substr(7)
	for n in theory_nodes():
		var s := str(n)
		if s == node_id or s == bare or s.ends_with("." + bare):
			return true
	return false


func has_any_unlock() -> bool:
	return not unlocked_pages().is_empty() or not theory_nodes().is_empty()


func night_remaining() -> int:
	var slots: Dictionary = _play().get("time_slots", {})
	return int(slots.get("night", 1))


func is_night_spent() -> bool:
	return str(_play().get("time_slot", "")) == "night_spent" or night_remaining() <= 0


func can_enter_loft() -> bool:
	## First entry costs night; review re-entry free if already unlocked pages.
	if not is_night_spent():
		return true
	if has_any_unlock():
		return true
	return false


func try_go_loft(change_scene: bool = true) -> Dictionary:
	last_tip = ""
	last_enter_was_review = false
	if GameFlow and str(GameFlow.fsm_state) != "clinic_idle":
		last_tip = tr("NIGHT_READ_NO_NIGHT")
		return {"ok": false, "tip": last_tip, "reason": "busy"}
	if not is_night_spent():
		_spend_night()
		_enter_loft(change_scene)
		return {"ok": true, "review": false}
	if has_any_unlock():
		last_enter_was_review = true
		_enter_loft(change_scene)
		return {"ok": true, "review": true}
	last_tip = tr("NIGHT_READ_NO_NIGHT")
	if last_tip == "NIGHT_READ_NO_NIGHT" or last_tip == "":
		last_tip = "今夜的夜格用尽了。明日再来，或提前歇息进夜。"
	return {"ok": false, "tip": last_tip, "reason": "no_night"}


func rest_into_night() -> Dictionary:
	## Early rest / no-night path: refresh night via day+1 (or grant if never spent), then enter.
	if GameFlow and str(GameFlow.fsm_state) != "clinic_idle":
		return {"ok": false, "tip": last_tip, "reason": "busy"}
	var play := _play()
	# Mark evening spent as "resting early" if still available.
	if str(play.get("time_slot", "")) != "evening_spent" and str(play.get("time_slot", "")) != "night_spent":
		var slots: Dictionary = play.get("time_slots", {}) if typeof(play.get("time_slots", {})) == TYPE_DICTIONARY else {}
		slots["evening"] = maxi(0, int(slots.get("evening", 1)) - 1)
		play["time_slots"] = slots
	if is_night_spent() and not has_any_unlock():
		# Advance day to restore night slot, then enter.
		if GameFlow and GameFlow.has_method("advance_clinic_day"):
			GameFlow.advance_clinic_day()
		_ensure_play_fields()
		play = _play()
	# Ensure night available for this enter.
	if is_night_spent() and has_any_unlock():
		# Review path without spending again.
		last_enter_was_review = true
		_enter_loft()
		return {"ok": true, "review": true, "rest": true}
	if not is_night_spent():
		_spend_night()
	else:
		# After day advance, spend fresh night.
		_spend_night()
	_enter_loft()
	return {"ok": true, "review": false, "rest": true}


func go_loft() -> void:
	try_go_loft()


func _spend_night() -> void:
	var play := _play()
	if str(play.get("time_slot", "")) == "night_spent":
		return
	var slots: Dictionary = play.get("time_slots", {}) if typeof(play.get("time_slots", {})) == TYPE_DICTIONARY else {}
	slots["night"] = maxi(0, int(slots.get("night", 1)) - 1)
	play["time_slots"] = slots
	play["time_slot"] = "night_spent"
	Save.data["play"] = play
	Save.write_slot()


func _enter_loft(change_scene: bool = true) -> void:
	if GameFlow:
		GameFlow.fsm_state = "loft_reading"
		GameFlow.fsm_changed.emit("loft_reading")
	entered_loft.emit()
	if not change_scene:
		return
	var tree := get_tree()
	if tree:
		tree.change_scene_to_file(LOFT_SCENE)


func leave_loft() -> void:
	if GameFlow:
		GameFlow.fsm_state = "clinic_idle"
		GameFlow.fsm_changed.emit("clinic_idle")
	left_loft.emit()
	var tree := get_tree()
	if tree:
		tree.change_scene_to_file(CLINIC_SCENE)


func unlock_page(page_id: String) -> Dictionary:
	## Read → 领悟. Writes play.codex_unlocked + play.theory_nodes. Review of unlocked = no-op save.
	var page := page_by_id(page_id)
	if page.is_empty():
		return {"ok": false, "reason": "unknown_page"}
	var theory_id := str(page.get("theory", "theory." + page_id))
	var play := _play()
	var unlocked: Array = play.get("codex_unlocked", []) if typeof(play.get("codex_unlocked", [])) == TYPE_ARRAY else []
	var nodes: Array = play.get("theory_nodes", []) if typeof(play.get("theory_nodes", [])) == TYPE_ARRAY else []
	var fresh := page_id not in unlocked
	if fresh:
		unlocked.append(page_id)
	if theory_id not in nodes:
		nodes.append(theory_id)
	play["codex_unlocked"] = unlocked
	play["theory_nodes"] = nodes
	Save.data["play"] = play
	Save.write_slot()
	if fresh:
		page_unlocked.emit(page_id, theory_id)
	return {"ok": true, "fresh": fresh, "page_id": page_id, "theory": theory_id, "review": not fresh}


func mentor_loft_line(idx: int = 0) -> String:
	var bag: Variant = codex_script().get("mentor_su", {})
	if typeof(bag) == TYPE_DICTIONARY:
		var lines_v: Variant = (bag as Dictionary).get("loft_lines", {})
		if typeof(lines_v) == TYPE_DICTIONARY:
			var L := _loc()
			var arr: Variant = (lines_v as Dictionary).get(L, (lines_v as Dictionary).get("zh", []))
			if typeof(arr) == TYPE_ARRAY and (arr as Array).size() > 0:
				return str((arr as Array)[clampi(idx, 0, (arr as Array).size() - 1)])
	var key := "MENTOR_LOFT_1" if idx <= 0 else "MENTOR_LOFT_2"
	var tt := tr(key)
	return tt if tt != key else "阁楼的字，认一个是一个。"


func pulse_standard_name(pulse_id: String) -> String:
	## Only when theory.pulse_names unlocked.
	if not has_theory("theory.pulse_names"):
		return ""
	match pulse_id:
		"xian":
			var t := tr("PULSE_NAME_XIAN")
			return t if t != "PULSE_NAME_XIAN" else "弦"
		"fu", "fu_jin":
			var t2 := tr("PULSE_NAME_FU")
			return t2 if t2 != "PULSE_NAME_FU" else "浮"
		_:
			return ""


func pulse_desc(pulse_id: String) -> String:
	match pulse_id:
		"xian":
			var t := tr("PULSE_DESC_XIAN")
			return t if t != "PULSE_DESC_XIAN" else "如按琴弦"
		"fu", "fu_jin":
			var t2 := tr("PULSE_DESC_FU")
			return t2 if t2 != "PULSE_DESC_FU" else "如木浮水"
		_:
			return ""


func hanre_note() -> String:
	if not has_theory("theory.hanre_xushi"):
		return ""
	var t := tr("THEORY_HANRE_XUSHI_NOTE")
	return t if t != "THEORY_HANRE_XUSHI_NOTE" else "寒热虚实，先辨门户。"


func reset_night_for_new_day(play: Dictionary) -> void:
	## Called from GameFlow.advance_clinic_day.
	var slots: Dictionary = play.get("time_slots", {}) if typeof(play.get("time_slots", {})) == TYPE_DICTIONARY else {}
	slots["morning"] = 1
	slots["afternoon"] = 1
	slots["evening"] = 1
	slots["night"] = 1
	play["time_slots"] = slots
	play["time_slot"] = "morning"
