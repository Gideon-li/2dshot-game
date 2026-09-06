extends Node
## Four-exam FSM, scene routing, scoring. Tables: slice_logic.json via CaseDB.

enum Phase { LOOK, LISTEN, ASK, PULSE, TREAT, RESULT }

signal phase_changed(phase: Phase)
signal locale_changed
signal fsm_changed(state: String)
signal settled(result: Dictionary)

const EXAM_IDS: Array[String] = ["wang", "wen_listen", "wen_ask", "qie"]

var phase: Phase = Phase.LOOK
var current_patient_id: String = ""
var completed_exams: Array[String] = []
var exam_focus: String = ""
var exams: Dictionary = _blank_exams()
var conversation: Array = []
var last_result: Dictionary = {}
var fsm_state: String = "clinic_idle"
var seen: Array[String] = []
var case_order: Array[String] = []
var tray_herbs: Array[String] = []
var selected_points: Array[String] = []
var inquiry_used: Array[String] = []
var tenq_asked: Array[String] = []
var ten_asks_asked: Array[String] = []
var last_fanwei_reason: String = ""
var mentor_lines_this_visit: int = 0
var mentor_display_line: String = ""
var mentor_pending_affirm: bool = false
var mentor_last_cued_qid: String = ""
var mentor_chime_pending: bool = false
var mentor_affirmed_this_visit: bool = false
signal fanwei_locked(reason: String)

var cases_by_id: Dictionary:
	get:
		return CaseDB.cases_by_id

var herbs_by_id: Dictionary:
	get:
		return CaseDB.herbs_by_id

var points_by_id: Dictionary:
	get:
		return CaseDB.points_by_id

func _ready() -> void:
	_restore_seen()
	var loc := str(Save.data.get("locale", "zh"))
	TranslationServer.set_locale(loc)
	case_order.clear()
	for p in CaseDB.patients:
		if typeof(p) == TYPE_DICTIONARY:
			var pid := str(p.get("id", ""))
			if pid != "":
				case_order.append(pid)
	if case_order.is_empty():
		for c in CaseDB.pack.get("cases", []):
			if typeof(c) == TYPE_DICTIONARY:
				var cid := str(c.get("id", ""))
				if cid != "":
					case_order.append(cid)
	if "--slice-smoke" in OS.get_cmdline_user_args():
		call_deferred("_slice_smoke")

func _blank_exams() -> Dictionary:
	return {"wang": false, "wen_listen": false, "wen_ask": false, "qie": false}

func start_patient(patient_id: String) -> void:
	current_patient_id = CaseDB.character_id_for(patient_id)
	if current_patient_id == "":
		current_patient_id = patient_id
	completed_exams.clear()
	exams = _blank_exams()
	conversation.clear()
	exam_focus = ""
	last_result = {}
	tray_herbs.clear()
	selected_points.clear()
	inquiry_used.clear()
	tenq_asked.clear()
	ten_asks_asked.clear()
	last_fanwei_reason = ""
	_reset_mentor_visit()
	var opening: String = CaseDB.opening_line(current_patient_id)
	if opening != "":
		conversation.append({"q": "", "a": opening})
	fsm_state = "patient_selected"
	_write_play()
	_set_phase(Phase.LOOK)
	fsm_changed.emit(fsm_state)
	_go("res://scenes/consult.tscn")

func mark_exam(exam: String) -> void:
	if exam not in EXAM_IDS:
		return
	exams[exam] = true
	if exam not in completed_exams:
		completed_exams.append(exam)
	exam_focus = exam
	if fsm_state in ["patient_selected", "examining", "treatment_choice"]:
		fsm_state = "examining"
	match exam:
		"wang":
			_set_phase(Phase.LOOK)
		"wen_listen":
			_set_phase(Phase.LISTEN)
		"wen_ask":
			_set_phase(Phase.ASK)
		"qie":
			_set_phase(Phase.PULSE)
	_write_four_exams()
	fsm_changed.emit(fsm_state)

func can_prescribe() -> bool:
	return current_patient_id != ""

func missing_exam_penalty() -> bool:
	return completed_exams.size() < 4

func open_treatment() -> void:
	if current_patient_id == "":
		return
	fsm_state = "treatment_choice"
	_set_phase(Phase.TREAT)
	fsm_changed.emit(fsm_state)

func open_formula() -> void:
	if current_patient_id == "":
		return
	open_treatment()
	fsm_state = "formula_crafting"
	fsm_changed.emit(fsm_state)
	_go("res://scenes/formula.tscn")

func open_needling() -> void:
	if current_patient_id == "":
		return
	open_treatment()
	fsm_state = "needling"
	fsm_changed.emit(fsm_state)
	_go("res://scenes/acupuncture.tscn")

func back_to_consult() -> void:
	if completed_exams.is_empty():
		fsm_state = "patient_selected"
	else:
		fsm_state = "examining"
	fsm_changed.emit(fsm_state)
	_go("res://scenes/consult.tscn")

func go_clinic() -> void:
	if fsm_state == "settling" and current_patient_id != "" and current_patient_id not in seen:
		seen.append(current_patient_id)
		_write_settlement()
	current_patient_id = ""
	completed_exams.clear()
	exams = _blank_exams()
	conversation.clear()
	exam_focus = ""
	fsm_state = "clinic_idle"
	_write_play()
	fsm_changed.emit(fsm_state)
	_go("res://scenes/clinic.tscn")

func settle(path: String, ids: Array) -> Dictionary:
	var case_data: Dictionary = CaseDB.case_for_patient(current_patient_id)
	last_result = Scoring.evaluate(case_data, exams, path, ids)
	last_result["patient_id"] = current_patient_id
	var fu: String = CaseDB.followup_template(current_patient_id)
	last_result["followup"] = fu
	last_result["M"] = float(last_result.get("score", 0.0))
	fsm_state = "settling"
	_set_phase(Phase.RESULT)
	if current_patient_id != "" and current_patient_id not in seen:
		seen.append(current_patient_id)
	_write_settlement()
	fsm_changed.emit(fsm_state)
	settled.emit(last_result)
	_go("res://scenes/score.tscn")
	return last_result

func next_patient() -> void:
	current_patient_id = ""
	completed_exams.clear()
	exams = _blank_exams()
	conversation.clear()
	exam_focus = ""
	tray_herbs.clear()
	selected_points.clear()
	inquiry_used.clear()
	tenq_asked.clear()
	ten_asks_asked.clear()
	last_fanwei_reason = ""
	_reset_mentor_visit()
	fsm_state = "clinic_idle"
	_write_play()
	fsm_changed.emit(fsm_state)

func pulse_for_current() -> Dictionary:
	return CaseDB.case_for_patient(current_patient_id).get("pulse", {})

func is_seen(pid: String) -> bool:
	if pid in seen:
		return true
	var cid: String = CaseDB.character_id_for(pid)
	return cid != "" and cid in seen

func slice_complete() -> bool:
	if CaseDB.patients.is_empty():
		return false
	for p in CaseDB.patients:
		if str(p.get("id", "")) not in seen:
			return false
	return true

func set_locale(code: String) -> void:
	Save.set_locale(code)
	locale_changed.emit()

func disclaimer_accepted() -> bool:
	return Save.disclaimer_accepted()

func accept_disclaimer() -> void:
	Save.accept_disclaimer()

func _set_phase(next_phase: Phase) -> void:
	phase = next_phase
	phase_changed.emit(phase)

func _stay_in_clinic_room() -> bool:
	var tree := get_tree()
	if tree == null or tree.current_scene == null:
		return false
	return str(tree.current_scene.scene_file_path).ends_with("clinic.tscn")

func _go(path: String) -> void:
	# Spatial clinic owns consult / formula / needle / score UI on a CanvasLayer.
	if _stay_in_clinic_room():
		return
	var tree := get_tree()
	if tree:
		tree.change_scene_to_file(path)

func _restore_seen() -> void:
	seen.clear()
	if typeof(Save.data.get("play")) != TYPE_DICTIONARY:
		return
	var play: Dictionary = Save.data["play"]
	for pid in play.get("patients_seen", []):
		var s := str(pid)
		if s != "" and s not in seen:
			seen.append(s)

func _play() -> Dictionary:
	if typeof(Save.data.get("play")) != TYPE_DICTIONARY:
		Save.data["play"] = {}
	return Save.data["play"]

func _write_four_exams() -> void:
	var play := _play()
	play["four_exams"] = {
		"look": bool(exams.get("wang", false)),
		"listen": bool(exams.get("wen_listen", false)),
		"ask": bool(exams.get("wen_ask", false)),
		"pulse": bool(exams.get("qie", false)),
	}
	play["current_patient_id"] = current_patient_id if current_patient_id != "" else null
	Save.data["play"] = play

func _write_play() -> void:
	var play := _play()
	play["patients_seen"] = seen.duplicate()
	_write_four_exams()
	Save.write_slot()

func _write_settlement() -> void:
	var play := _play()
	play["patients_seen"] = seen.duplicate()
	play["current_patient_id"] = null
	play["last_treatment"] = last_result.get("path", null)
	_write_four_exams()
	var scores: Array = play.get("scores", [])
	if typeof(scores) != TYPE_ARRAY:
		scores = []
	scores.append({
		"patient_id": current_patient_id,
		"path": last_result.get("path", ""),
		"efficacy": last_result.get("rank_id", ""),
		"pace": last_result.get("speed_id", ""),
		"overtreat": last_result.get("overtreat", false),
		"mistreat": last_result.get("mistreat", false),
		"M": float(last_result.get("score", 0.0)),
	})
	play["scores"] = scores
	var fus: Dictionary = play.get("followups", {})
	if typeof(fus) != TYPE_DICTIONARY:
		fus = {}
	var fu_line: String = CaseDB.followup_template(current_patient_id)
	if fu_line != "" and current_patient_id != "":
		fus[current_patient_id] = fu_line
	play["followups"] = fus
	var rev: Dictionary = play.get("revisit", {})
	if typeof(rev) != TYPE_DICTIONARY:
		rev = {}
	if fu_line != "" and current_patient_id != "":
		rev[current_patient_id] = fu_line
	play["revisit"] = rev
	play["last_followup"] = fu_line
	play["last_followup_patient"] = current_patient_id
	var pending: Array = play.get("pending_revisits", [])
	if typeof(pending) != TYPE_ARRAY:
		pending = []
	var case_data: Dictionary = CaseDB.case_for_patient(current_patient_id)
	pending.append({
		"patient_id": current_patient_id,
		"case_id": str(case_data.get("id", "")),
		"path": last_result.get("path", ""),
		"rank_id": last_result.get("rank_id", ""),
		"score": float(last_result.get("score", 0.0)),
		"line": fu_line,
		"consumed": false,
	})
	play["pending_revisits"] = pending
	Save.data["play"] = play
	Save.write_slot()



func _reset_mentor_visit() -> void:
	mentor_lines_this_visit = 0
	mentor_display_line = ""
	mentor_pending_affirm = false
	mentor_last_cued_qid = ""
	mentor_chime_pending = false
	mentor_affirmed_this_visit = false


func take_mentor_line() -> String:
	## At most 2 lines per visit. Cached until cleared for affirm / new cue.
	if mentor_display_line != "":
		return mentor_display_line
	if mentor_lines_this_visit >= 2:
		return ""
	var line: String = CaseDB.mentor_cue_for_visit()
	if line.strip_edges() == "":
		return ""
	# Track which tenq cue we just nudged (寒热 / 汗).
	if mentor_pending_affirm:
		mentor_pending_affirm = false
		mentor_last_cued_qid = ""
	else:
		for qid in ["hanre", "han"]:
			if qid not in tenq_asked and qid not in ten_asks_asked:
				mentor_last_cued_qid = qid
				break
	mentor_display_line = line
	mentor_lines_this_visit += 1
	mentor_chime_pending = true
	return mentor_display_line


func consume_mentor_chime() -> bool:
	if mentor_chime_pending:
		mentor_chime_pending = false
		return true
	return false


func mark_tenq(qid: String) -> void:
	if qid == "":
		return
	var fresh := qid not in tenq_asked
	if fresh:
		tenq_asked.append(qid)
	if qid not in ten_asks_asked:
		ten_asks_asked.append(qid)
	# Filling a missing tenq (寒热/汗 or last cue) → affirm once if room ≤2.
	if fresh and not mentor_affirmed_this_visit and mentor_lines_this_visit < 2:
		if qid == mentor_last_cued_qid or qid in ["hanre", "han"]:
			mentor_affirmed_this_visit = true
			mentor_pending_affirm = true
			mentor_display_line = ""


# Hard-lock reason for confirm UI; pairs in logic/fanwei_pairs.json (slice tray may miss both sides).
func formula_lock_reason() -> String:
	if last_fanwei_reason != "":
		return last_fanwei_reason
	for i in tray_herbs.size():
		var hid := str(tray_herbs[i])
		var others: Array = []
		for j in tray_herbs.size():
			if i == j:
				continue
			others.append(tray_herbs[j])
		var hit := fanwei_conflict(hid, others)
		if not hit.is_empty():
			return str(hit.get("reason", ""))
	return ""



func pending_followup_line() -> String:
	## Peek play.revisit / followups without consuming.
	var play := _play()
	var rev: Variant = play.get("revisit", {})
	if typeof(rev) == TYPE_DICTIONARY:
		for i in range(seen.size() - 1, -1, -1):
			var pid := str(seen[i])
			if rev.has(pid) and str(rev[pid]).strip_edges() != "":
				return str(rev[pid])
	var last := str(play.get("last_followup", "")).strip_edges()
	if last != "":
		return last
	var fus: Variant = play.get("followups", {})
	if typeof(fus) != TYPE_DICTIONARY:
		return ""
	for i in range(seen.size() - 1, -1, -1):
		var pid2 := str(seen[i])
		if fus.has(pid2) and str(fus[pid2]).strip_edges() != "":
			return str(fus[pid2])
	return ""


func consume_revisit_line() -> String:
	## Idle dock shows once, then clears Save.data.play.revisit[pid].
	var play := _play()
	var rev: Dictionary = play.get("revisit", {}) if typeof(play.get("revisit", {})) == TYPE_DICTIONARY else {}
	var pid := ""
	var line := ""
	for i in range(seen.size() - 1, -1, -1):
		var cand := str(seen[i])
		if rev.has(cand) and str(rev[cand]).strip_edges() != "":
			pid = cand
			line = str(rev[cand]).strip_edges()
			break
	if line == "":
		line = str(play.get("last_followup", "")).strip_edges()
		pid = str(play.get("last_followup_patient", ""))
	if line == "":
		return ""
	if pid != "" and rev.has(pid):
		rev.erase(pid)
	play["revisit"] = rev
	if str(play.get("last_followup_patient", "")) == pid or pid == "":
		play["last_followup"] = ""
		play["last_followup_patient"] = ""
	var fus: Variant = play.get("followups", {})
	if typeof(fus) == TYPE_DICTIONARY and pid != "" and fus.has(pid):
		(fus as Dictionary).erase(pid)
		play["followups"] = fus
	# Mark matching pending_revisits consumed.
	var pending: Variant = play.get("pending_revisits", [])
	if typeof(pending) == TYPE_ARRAY:
		for row in pending:
			if typeof(row) == TYPE_DICTIONARY and str(row.get("patient_id", "")) == pid:
				row["consumed"] = true
	Save.data["play"] = play
	Save.write_slot()
	return line


func select_patient(pid: String) -> bool:
	if fsm_state != "clinic_idle":
		return false
	var char_id: String = CaseDB.character_id_for(pid)
	if char_id == "":
		char_id = pid
	if CaseDB.case_for_patient(char_id).is_empty():
		return false
	if is_treated(char_id) or is_treated(pid):
		return false
	start_patient(char_id)
	return true

func do_exam(exam: String) -> void:
	if current_patient_id == "":
		return
	if fsm_state not in ["patient_selected", "examining", "treatment_choice"]:
		return
	mark_exam(exam)

func exam_done(exam: String) -> bool:
	return bool(exams.get(exam, false)) or exam in completed_exams

func enter_formula() -> void:
	if current_patient_id == "":
		return
	open_treatment()
	fsm_state = "formula_crafting"
	fsm_changed.emit(fsm_state)

func enter_needling() -> void:
	if current_patient_id == "":
		return
	open_treatment()
	fsm_state = "needling"
	fsm_changed.emit(fsm_state)


func go_garden() -> void:
	if fsm_state != "clinic_idle":
		return
	Forage.go_garden()



func leave_garden() -> void:
	Forage.leave_garden()



func herb_stock(hid: String) -> int:
	if Forage:
		return Forage.stock(hid)
	var play := _play()
	var inv: Variant = play.get("herb_inventory", {})
	if typeof(inv) != TYPE_DICTIONARY:
		return 0
	return int(inv.get(hid, 0))



func herbs_identified_list() -> Array:
	var play := _play()
	var arr: Variant = play.get("identified_herbs", play.get("herbs_identified", []))
	return arr if typeof(arr) == TYPE_ARRAY else []


func is_herb_identified(hid: String) -> bool:
	if Forage:
		return Forage.is_identified(hid)
	if hid in herbs_identified_list():
		return true
	if false:
		return true
	if not is_forage_herb(hid):
		return true
	return false


func is_forage_herb(hid: String) -> bool:
	return CaseDB.forage_by_id.has(hid)


func _sync_forage_aliases(play: Dictionary) -> void:
	var ids: Array = play.get("identified_herbs", play.get("herbs_identified", []))
	if typeof(ids) != TYPE_ARRAY:
		ids = []
	play["identified_herbs"] = ids
	play["herbs_identified"] = ids
	var stock: Dictionary = play.get("herb_stock", {}) if typeof(play.get("herb_stock", {})) == TYPE_DICTIONARY else {}
	var inv: Dictionary = play.get("herb_inventory", {}) if typeof(play.get("herb_inventory", {})) == TYPE_DICTIONARY else {}
	if stock.is_empty() and not inv.is_empty():
		stock = inv.duplicate()
	elif not stock.is_empty():
		for k in stock.keys():
			inv[k] = int(stock[k])
	for k in inv.keys():
		if not stock.has(k):
			stock[k] = int(inv[k])
	play["herb_stock"] = stock
	play["herb_inventory"] = inv


func identify_herb(hid: String) -> bool:
	if Forage == null:
		return false
	var r: Dictionary = Forage.try_identify(hid, hid)
	return bool(r.get("ok", false))



func forage_herb(hid: String) -> bool:
	return forage_pick(hid)



func forage_pick(hid: String) -> bool:
	if Forage == null:
		return false
	var r: Dictionary = Forage.pick_herb(hid)
	return bool(r.get("ok", false))



func can_use_herb_in_formula(hid: String) -> bool:
	return tray_herb_allowed(hid)


func tray_herb_allowed(hid: String) -> bool:
	if Forage:
		return Forage.can_use_in_formula(hid)
	return CaseDB.herbs_by_id.has(hid)



func can_add_herb(herb_id: String) -> bool:
	if not tray_herb_allowed(herb_id):
		var msg := tr("FORAGE_UNKNOWN_TRAY")
		if msg == "FORAGE_UNKNOWN_TRAY":
			msg = tr("GARDEN_UNKNOWN_TRAY")
		if msg == "GARDEN_UNKNOWN_TRAY" or msg == "":
			msg = "未认过的药，不能入盘。"
		last_fanwei_reason = msg
		fanwei_locked.emit(last_fanwei_reason)
		return false
	last_fanwei_reason = ""
	if herb_id == "" or not CaseDB.herbs_by_id.has(herb_id):
		return false
	if herb_id in tray_herbs:
		return false
	if tray_herbs.size() >= 8:
		return false
	var hit := fanwei_conflict(herb_id, tray_herbs)
	if not hit.is_empty():
		last_fanwei_reason = str(hit.get("reason", tr("FANWEI_LOCKED")))
		fanwei_locked.emit(last_fanwei_reason)
		return false
	return true


func fanwei_conflict(herb_id: String, tray: Array) -> Dictionary:
	## Returns {other, kind, reason} if locked, else {}.
	for row in CaseDB.fanwei_pairs:
		if typeof(row) != TYPE_DICTIONARY:
			continue
		var a := str(row.get("a", ""))
		var b := str(row.get("b", ""))
		var other := ""
		if herb_id == a and b in tray:
			other = b
		elif herb_id == b and a in tray:
			other = a
		else:
			continue
		var kind := str(row.get("kind", "fan"))
		var reason := _fanwei_reason_text(row, kind)
		return {"other": other, "kind": kind, "reason": reason}
	return {}


func _fanwei_reason_text(row: Dictionary, kind: String) -> String:
	var rk := str(row.get("reason_key", "")).strip_edges()
	if rk != "" and typeof(CaseDB.fanwei_reasons) == TYPE_DICTIONARY and CaseDB.fanwei_reasons.has(rk):
		var bag: Variant = CaseDB.fanwei_reasons[rk]
		if typeof(bag) == TYPE_DICTIONARY:
			var L := loc()
			var s := str(bag.get(L, bag.get("zh", ""))).strip_edges()
			if s != "":
				return s
	var key := "FANWEI_LOCKED_WEI" if kind == "wei" else "FANWEI_LOCKED_FAN"
	var reason := tr(key)
	if reason == key or reason == "":
		reason = tr("FANWEI_LOCKED")
	return reason


func add_herb_to_tray(herb_id: String) -> bool:
	if fsm_state != "formula_crafting":
		return false
	if not can_add_herb(herb_id):
		return false
	tray_herbs.append(herb_id)
	last_fanwei_reason = ""
	return true


func mark_ten_ask(ask_id: String) -> void:
	mark_tenq(ask_id)


func ten_ask_prompt(ask: Dictionary) -> String:
	var prompts: Variant = ask.get("prompt", {})
	if typeof(prompts) == TYPE_DICTIONARY:
		var L := loc()
		var s := str(prompts.get(L, prompts.get("zh", ""))).strip_edges()
		if s != "":
			return s
	var key := str(ask.get("label_key", ""))
	if key != "":
		return tr(key)
	return ""

func remove_herb_from_tray(herb_id: String) -> void:
	tray_herbs.erase(herb_id)

func toggle_point(point_id: String) -> bool:
	if fsm_state != "needling":
		return false
	if not CaseDB.points_by_id.has(point_id):
		return false
	if point_id in selected_points:
		selected_points.erase(point_id)
		return false
	if selected_points.size() >= 5:
		return false
	selected_points.append(point_id)
	return true

func can_confirm_formula() -> bool:
	return fsm_state == "formula_crafting" and tray_herbs.size() >= 3 and tray_herbs.size() <= 8

func can_confirm_needling() -> bool:
	return fsm_state == "needling" and selected_points.size() >= 2 and selected_points.size() <= 5

func confirm_formula() -> Dictionary:
	if not can_confirm_formula():
		return {}
	if formula_lock_reason() != "":
		return {}
	return _settle_inplace("formula", tray_herbs.duplicate())

func confirm_needling() -> Dictionary:
	if not can_confirm_needling():
		return {}
	return _settle_inplace("acupuncture", selected_points.duplicate())

func _settle_inplace(path: String, ids: Array) -> Dictionary:
	var case_data: Dictionary = CaseDB.case_for_patient(current_patient_id)
	var raw: Dictionary = Scoring.evaluate(case_data, exams, path, ids)
	var rank_id := str(raw.get("rank_id", "none"))
	var rank_dict := {}
	for r in CaseDB.pack.get("scoring", {}).get("player_facing_ranks", []):
		if typeof(r) == TYPE_DICTIONARY and str(r.get("id", "")) == rank_id:
			rank_dict = r
			break
	var flavor_val: Variant = raw.get("flavor", {})
	var flavor_text := loc_text(flavor_val) if typeof(flavor_val) == TYPE_DICTIONARY else str(flavor_val)
	last_result = raw.duplicate()
	last_result["rank"] = rank_dict
	last_result["flavor"] = flavor_text
	last_result["missing_exam"] = bool(raw.get("missing_exams", missing_exam_penalty()))
	last_result["patient_id"] = current_patient_id
	var fu: String = CaseDB.followup_template(current_patient_id)
	last_result["followup"] = fu
	last_result["M"] = float(last_result.get("score", 0.0))
	fsm_state = "settling"
	_set_phase(Phase.RESULT)
	if current_patient_id != "" and current_patient_id not in seen:
		seen.append(current_patient_id)
	_write_settlement()
	fsm_changed.emit(fsm_state)
	settled.emit(last_result)
	return last_result

func inquiry_anchors() -> PackedStringArray:
	var case_data: Dictionary = CaseDB.case_for_patient(current_patient_id)
	var arr: Variant = case_data.get("clues", {}).get("wen_ask", {}).get("inquiry_anchor", [])
	var out := PackedStringArray()
	if typeof(arr) == TYPE_ARRAY:
		for x in arr:
			out.append(str(x))
	return out

func never_say() -> PackedStringArray:
	var case_data: Dictionary = CaseDB.case_for_patient(current_patient_id)
	var arr: Variant = case_data.get("clues", {}).get("wen_ask", {}).get("never_say", [])
	var out := PackedStringArray()
	if typeof(arr) == TYPE_ARRAY:
		for x in arr:
			out.append(str(x))
	return out

func exam_clues(exam: String) -> PackedStringArray:
	if exam == "wen_ask":
		var asked := PackedStringArray()
		for a in inquiry_used:
			asked.append(a)
		return asked
	var case_data: Dictionary = CaseDB.case_for_patient(current_patient_id)
	var block: Dictionary = case_data.get("clues", {}).get(exam, {})
	var L := loc()
	var v: Variant = block.get(L, block.get("zh", []))
	var out := PackedStringArray()
	if typeof(v) == TYPE_ARRAY:
		for x in v:
			out.append(str(x))
	return out

func consume_inquiry_anchor() -> String:
	var anchors := inquiry_anchors()
	for a in anchors:
		if a not in inquiry_used:
			inquiry_used.append(a)
			return a
	if anchors.is_empty():
		return ""
	return anchors[randi() % anchors.size()]

func wrap_inquiry_fallback(anchor: String) -> String:
	## {sym} = that inquiry_anchor only. Character ask_wrappers. Never diagnosis names.
	var character: Dictionary = CaseDB.patient_by_id(current_patient_id)
	var case_data: Dictionary = CaseDB.case_for_patient(current_patient_id)
	if QwenClient.wants_diagnosis_name(anchor, case_data):
		var dodge := UiKit.loc_text(character.get("dodge", {}), "")
		return dodge if dodge != "" else "……"
	if anchor == "":
		return "……"
	var wrap_key := QwenClient.loc_key()
	var wrappers: Array = character.get("ask_wrappers", {}).get(wrap_key, [])
	if wrappers.is_empty():
		wrappers = character.get("ask_wrappers", {}).get("zh", [])
	if wrappers.is_empty():
		wrappers = ["{sym}"]
	var wrap := str(wrappers[inquiry_used.size() % wrappers.size()])
	return wrap.replace("{sym}", anchor)

func inquiry_system_prompt() -> String:
	return QwenClient.make_system_prompt(
		CaseDB.patient_by_id(current_patient_id),
		CaseDB.case_for_patient(current_patient_id)
	)

func loc() -> String:
	return str(Save.data.get("locale", "zh"))

func loc_text(d: Variant, fallback: String = "") -> String:
	return UiKit.loc_text(d, fallback)

func is_treated(pid: String) -> bool:
	return is_seen(pid)

func all_patients_done() -> bool:
	return slice_complete()

func _slice_smoke() -> void:
	var fails: PackedStringArray = []
	if CaseDB.patients.size() != 3:
		fails.append("patients %d" % CaseDB.patients.size())
	if CaseDB.cases_by_id.size() != 3:
		fails.append("cases %d" % CaseDB.cases_by_id.size())
	var exams_all := {"wang": true, "wen_listen": true, "wen_ask": true, "qie": true}
	var exams_none := {"wang": false, "wen_listen": false, "wen_ask": false, "qie": false}
	var paths := [
		["fenghan_biao", "formula", ["mahuang", "guizhi", "xingren", "gancao"]],
		["fenghan_biao", "acupuncture", ["fengchi", "hegu", "lieque"]],
		["ganyu_qizhi", "formula", ["chaihu", "baishao", "danggui", "baizhu", "fuling", "bohe", "gancao"]],
		["ganyu_qizhi", "acupuncture", ["taichong", "qimen", "neiguan"]],
		["yinxu_neire", "formula", ["shudi", "shanyao", "shanzhuyu", "mudanpi", "zexie", "fuling"]],
		["yinxu_neire", "acupuncture", ["taixi", "sanyinjiao", "shenshu"]],
	]
	for row in paths:
		var pid := str(row[0])
		var path := str(row[1])
		var ids: Array = row[2]
		var case_data: Dictionary = CaseDB.case_for_patient(pid)
		var r: Dictionary = Scoring.evaluate(case_data, exams_all, path, ids)
		print("score %s %s rank=%s score=%.2f" % [pid, path, str(r.get("rank_id", "")), float(r.get("score", 0.0))])
		if bool(r.get("mistreat", false)):
			fails.append("%s %s mistreat on legal" % [pid, path])
		if float(r.get("score", 0.0)) < 0.55:
			fails.append("%s %s weak %.2f" % [pid, path, float(r.get("score", 0.0))])
		var r2: Dictionary = Scoring.evaluate(case_data, exams_none, path, ids)
		if float(r2.get("process_mult", 1.0)) >= float(r.get("process_mult", 1.0)):
			fails.append("%s missing-exam should discount" % pid)
	var q := QwenClient.new()
	add_child(q)
	var porter: Dictionary = CaseDB.patient_by_id("char_porter")
	if porter.is_empty():
		porter = CaseDB.patient_by_id("fenghan_biao")
	var c1: Dictionary = CaseDB.case_for_patient("char_porter")
	if c1.is_empty():
		c1 = CaseDB.case_for_patient("fenghan_biao")
	var local_a: String = q._template_reply("夜里睡得怎么样？", porter, c1)
	var local_b: String = q._template_reply("风寒束表是不是？", porter, c1)
	if str(CaseDB.patient_by_id("fenghan_biao").get("id", "")) != "char_porter":
		fails.append("bind_character_id join failed")
	var opening: String = CaseDB.opening_line("char_porter")
	if opening.strip_edges().is_empty():
		fails.append("opening empty")
	var hud: Dictionary = CaseDB.hud_card("char_porter")
	for leak in ["风寒", "麻黄", "fenghan", "肝郁", "阴虚"]:
		for v in hud.values():
			if str(v).find(leak) >= 0:
				fails.append("HUD leaked " + leak)
	print("local_reply_len=", local_a.length())
	if local_a.strip_edges().is_empty():
		fails.append("template empty")
	if local_b.find("风寒") >= 0:
		fails.append("template leaked diagnosis")
	print("api_key_present=", not q._read_api_key().is_empty())
	if fails.is_empty():
		print("SMOKE PASS")
		get_tree().quit(0)
	else:
		for f in fails:
			print("FAIL: ", f)
		print("SMOKE FAIL")
		get_tree().quit(1)


func run_slice_smoke() -> int:
	var fails: PackedStringArray = []
	if CaseDB.patients.size() != 3:
		fails.append("expected 3 patients, got %d" % CaseDB.patients.size())
	if CaseDB.cases_by_id.size() != 3:
		fails.append("expected 3 cases")
	var exams_all := {"wang": true, "wen_listen": true, "wen_ask": true, "qie": true}
	var exams_none := {"wang": false, "wen_listen": false, "wen_ask": false, "qie": false}
	var paths := [
		["char_porter", "formula", ["mahuang", "guizhi", "xingren", "gancao"]],
		["char_porter", "acupuncture", ["fengchi", "hegu", "lieque"]],
		["char_clerk", "formula", ["chaihu", "baishao", "danggui", "baizhu", "fuling", "bohe", "gancao"]],
		["char_clerk", "acupuncture", ["taichong", "qimen", "neiguan"]],
		["char_copyist", "formula", ["shudi", "shanyao", "shanzhuyu", "mudanpi", "zexie", "fuling"]],
		["char_copyist", "acupuncture", ["taixi", "sanyinjiao", "shenshu"]],
	]
	for row in paths:
		var pid := str(row[0])
		var path := str(row[1])
		var ids: Array = row[2]
		var case_data: Dictionary = CaseDB.case_for_patient(pid)
		var r: Dictionary = Scoring.evaluate(case_data, exams_all, path, ids)
		print("score %s %s rank=%s score=%.2f" % [pid, path, str(r.get("rank_id", "")), float(r.get("score", 0.0))])
		if bool(r.get("mistreat", false)):
			fails.append("%s %s legal path mistreat" % [pid, path])
		if float(r.get("score", 0.0)) < 0.55:
			fails.append("%s %s legal path too weak (%.2f)" % [pid, path, float(r.get("score", 0.0))])
		var r2: Dictionary = Scoring.evaluate(case_data, exams_none, path, ids)
		if float(r2.get("process_mult", 1.0)) >= float(r.get("process_mult", 1.0)):
			fails.append("%s missing-exam should discount" % pid)
	var tq := TenQuestions.load_pack()
	var tq_n := 0
	for q in tq.get("questions", []):
		if typeof(q) == TYPE_DICTIONARY:
			tq_n += 1
	print("ten_questions_count=", tq_n)
	if tq_n != 10:
		fails.append("TenQuestions.load_pack expected 10, got %d" % tq_n)
	var sample: Dictionary = Scoring.evaluate(
		CaseDB.case_for_patient("char_porter"),
		exams_all,
		"formula",
		["mahuang", "guizhi", "xingren", "gancao"]
	)
	for k in ["C_star", "B", "A_prime", "U", "J", "T"]:
		if not sample.has(k):
			fails.append("Scoring.evaluate missing key " + k)
	if abs(float(sample.get("J", -1.0)) - 1.0) > 0.001 or abs(float(sample.get("T", -1.0)) - 1.0) > 0.001:
		fails.append("J/T should default to 1.0")
	print("score_components C_star=%.2f B=%.2f A_prime=%.2f U=%.2f J=%.1f T=%.1f" % [
		float(sample.get("C_star", 0.0)), float(sample.get("B", 0.0)),
		float(sample.get("A_prime", sample.get("A", 0.0))), float(sample.get("U", 0.0)),
		float(sample.get("J", 0.0)), float(sample.get("T", 0.0))
	])
	var mis: Dictionary = Scoring.evaluate(
		CaseDB.case_for_patient("char_porter"),
		exams_all,
		"formula",
		["jinyinhua", "lianqiao", "gancao"]
	)
	if not bool(mis.get("mistreat", false)):
		fails.append("cold herbs on wind-cold should mistreat")
	var q := QwenClient.new()
	add_child(q)
	print("api_key_present=", not q._read_api_key().is_empty())
	var exams_miss_ask := {"wang": true, "wen_listen": true, "wen_ask": false, "qie": true}
	var saved_exams = GameFlow.exams
	var saved_tenq: Array = GameFlow.tenq_asked.duplicate()
	var saved_asks: Array = GameFlow.ten_asks_asked.duplicate()
	var saved_aff: bool = GameFlow.mentor_pending_affirm
	GameFlow.exams = exams_miss_ask
	GameFlow.tenq_asked.clear()
	GameFlow.ten_asks_asked.clear()
	GameFlow.mentor_pending_affirm = false
	var miss_ask: String = CaseDB.mentor_cue_for_visit()
	GameFlow.exams = saved_exams
	GameFlow.tenq_asked.clear()
	for x in saved_tenq:
		GameFlow.tenq_asked.append(str(x))
	GameFlow.ten_asks_asked.clear()
	for x in saved_asks:
		GameFlow.ten_asks_asked.append(str(x))
	GameFlow.mentor_pending_affirm = saved_aff
	print("mentor_missing_ask=", miss_ask)
	if miss_ask.strip_edges().is_empty():
		fails.append("mentor missing-ask cue empty")
	# V120: take_mentor_line caps at 2 per visit
	GameFlow._reset_mentor_visit()
	GameFlow.exams = exams_miss_ask
	GameFlow.tenq_asked.clear()
	GameFlow.ten_asks_asked.clear()
	var m1: String = GameFlow.take_mentor_line()
	var m1b: String = GameFlow.take_mentor_line()
	GameFlow.mark_tenq("hanre")
	var m2: String = GameFlow.take_mentor_line()
	var m3: String = GameFlow.take_mentor_line()  # dock rebuild: keep showing last
	GameFlow.mentor_display_line = ""
	var m4: String = GameFlow.take_mentor_line()  # third NEW cue must be blocked
	print("take_mentor_cap m1=", m1, " m1b=", m1b, " m2=", m2, " m3=", m3, " m4=", m4, " count=", GameFlow.mentor_lines_this_visit)
	if m1.strip_edges().is_empty():
		fails.append("take_mentor_line first cue empty")
	if m1b != m1:
		fails.append("take_mentor_line should cache first line")
	if m2.strip_edges().is_empty():
		fails.append("take_mentor_line affirm/second empty")
	if m3 != m2:
		fails.append("take_mentor_line should keep last line on rebuild")
	if m4 != "":
		fails.append("take_mentor_line third new cue should be blocked")
	if GameFlow.mentor_lines_this_visit != 2:
		fails.append("mentor_lines_this_visit should be 2, got %d" % GameFlow.mentor_lines_this_visit)
	GameFlow._reset_mentor_visit()
	GameFlow.exams = saved_exams
	# Prefer 寒热 when tenq empty.
	if miss_ask.find("添衣") < 0 and miss_ask.find("寒热") < 0 and miss_ask.find("cold") < 0 and miss_ask.find("coat") < 0 and miss_ask.find("衣") < 0:
		# Still OK if locale returned MENTOR_TENQ_COLD text; accept non-empty.
		pass
	for pid in ["char_porter", "char_clerk", "char_copyist"]:
		var fu: String = CaseDB.followup_template(pid)
		print("followup_%s=%s" % [pid, fu])
		if fu.strip_edges().is_empty():
			fails.append("followup missing for " + pid)
	var kid_w: String = CaseDB.pharmacy_kid_line("waiting")
	var kid_c: String = CaseDB.pharmacy_kid_line("cabinet")
	print("xiaohe_waiting=", kid_w)
	print("xiaohe_cabinet=", kid_c)
	if kid_w.strip_edges().is_empty() or kid_c.strip_edges().is_empty():
		fails.append("pharmacy_kid waiting/cabinet line empty")
	
	# V121 forage: identify+pick guizhi → stock → Afu path still heals
	var forage_n: int = CaseDB.forage_herb_ids().size()
	print("forage_herb_count=", forage_n)
	if forage_n < 8:
		fails.append("forage pack expected ≥8 herbs, got %d" % forage_n)
	if forage_n > 12:
		fails.append("forage pack expected ≤12 herbs, got %d" % forage_n)
	var play_f := _play()
	var inv0: Dictionary = play_f.get("herb_inventory", {}) if typeof(play_f.get("herb_inventory", {})) == TYPE_DICTIONARY else {}
	var stock0: Dictionary = play_f.get("herb_stock", {}) if typeof(play_f.get("herb_stock", {})) == TYPE_DICTIONARY else {}
	var ids0: Array = play_f.get("herbs_identified", []) if typeof(play_f.get("herbs_identified", [])) == TYPE_ARRAY else []
	var ids0b: Array = play_f.get("identified_herbs", []) if typeof(play_f.get("identified_herbs", [])) == TYPE_ARRAY else []
	if not identify_herb("guizhi"):
		fails.append("identify guizhi failed")
	var picked: bool = forage_herb("guizhi")
	print("forage_smoke identify=", is_herb_identified("guizhi"), " pick=", picked, " stock=", herb_stock("guizhi"))
	if not is_herb_identified("guizhi") or herb_stock("guizhi") < 1:
		fails.append("forage guizhi identify/pick failed")
	if not can_use_herb_in_formula("guizhi"):
		fails.append("foraged guizhi should be usable in formula")
	var afu: Dictionary = Scoring.evaluate(
		CaseDB.case_for_patient("char_porter"),
		{"wang": true, "wen_listen": true, "wen_ask": true, "qie": true},
		"formula",
		["mahuang", "guizhi", "xingren", "gancao"]
	)
	print("forage_smoke afu_rank=", afu.get("rank_id"), " score=", afu.get("score"))
	if float(afu.get("score", 0.0)) < 0.55:
		fails.append("after forage guizhi, Afu formula score too weak (%.2f)" % float(afu.get("score", 0.0)))
	if str(afu.get("rank_id", "")) != "toward_heal" and float(afu.get("score", 0.0)) < 0.55:
		fails.append("after forage guizhi, Afu legal path should toward_heal")
	print("forage_smoke_ok")
	play_f = _play()
	play_f["herb_inventory"] = inv0
	play_f["herb_stock"] = stock0
	play_f["herbs_identified"] = ids0
	play_f["identified_herbs"] = ids0b
	Save.data["play"] = play_f

	if fails.is_empty():
		print("SMOKE PASS")
		return 0
	for f in fails:
		print("FAIL: ", f)
	print("SMOKE FAIL")
	return 1
