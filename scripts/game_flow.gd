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
	var opening := CaseDB.opening_line(current_patient_id)
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
	var case_data := CaseDB.case_for_patient(current_patient_id)
	last_result = Scoring.evaluate(case_data, exams, path, ids)
	fsm_state = "settling"
	_set_phase(Phase.RESULT)
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
	fsm_state = "clinic_idle"
	_write_play()
	fsm_changed.emit(fsm_state)

func pulse_for_current() -> Dictionary:
	return CaseDB.case_for_patient(current_patient_id).get("pulse", {})

func is_seen(pid: String) -> bool:
	if pid in seen:
		return true
	var cid := CaseDB.character_id_for(pid)
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
	})
	play["scores"] = scores
	Save.data["play"] = play
	Save.write_slot()



func select_patient(pid: String) -> bool:
	if fsm_state != "clinic_idle":
		return false
	var char_id := CaseDB.character_id_for(pid)
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

func add_herb_to_tray(herb_id: String) -> bool:
	if fsm_state != "formula_crafting":
		return false
	if not CaseDB.herbs_by_id.has(herb_id):
		return false
	if herb_id in tray_herbs:
		return false
	if tray_herbs.size() >= 8:
		return false
	tray_herbs.append(herb_id)
	return true

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
	return _settle_inplace("formula", tray_herbs.duplicate())

func confirm_needling() -> Dictionary:
	if not can_confirm_needling():
		return {}
	return _settle_inplace("acupuncture", selected_points.duplicate())

func _settle_inplace(path: String, ids: Array) -> Dictionary:
	var case_data := CaseDB.case_for_patient(current_patient_id)
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
	fsm_state = "settling"
	_set_phase(Phase.RESULT)
	if current_patient_id != "" and current_patient_id not in seen:
		seen.append(current_patient_id)
	_write_settlement()
	fsm_changed.emit(fsm_state)
	settled.emit(last_result)
	return last_result

func inquiry_anchors() -> PackedStringArray:
	var case_data := CaseDB.case_for_patient(current_patient_id)
	var arr: Variant = case_data.get("clues", {}).get("wen_ask", {}).get("inquiry_anchor", [])
	var out := PackedStringArray()
	if typeof(arr) == TYPE_ARRAY:
		for x in arr:
			out.append(str(x))
	return out

func never_say() -> PackedStringArray:
	var case_data := CaseDB.case_for_patient(current_patient_id)
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
	var case_data := CaseDB.case_for_patient(current_patient_id)
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
	var character := CaseDB.patient_by_id(current_patient_id)
	var case_data := CaseDB.case_for_patient(current_patient_id)
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
		var case_data := CaseDB.case_for_patient(pid)
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
	var porter := CaseDB.patient_by_id("char_porter")
	if porter.is_empty():
		porter = CaseDB.patient_by_id("fenghan_biao")
	var c1 := CaseDB.case_for_patient("char_porter")
	if c1.is_empty():
		c1 = CaseDB.case_for_patient("fenghan_biao")
	var local_a: String = q._template_reply("夜里睡得怎么样？", porter, c1)
	var local_b: String = q._template_reply("风寒束表是不是？", porter, c1)
	if str(CaseDB.patient_by_id("fenghan_biao").get("id", "")) != "char_porter":
		fails.append("bind_character_id join failed")
	var opening := CaseDB.opening_line("char_porter")
	if opening.strip_edges().is_empty():
		fails.append("opening empty")
	var hud := CaseDB.hud_card("char_porter")
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
		var case_data := CaseDB.case_for_patient(pid)
		var r: Dictionary = Scoring.evaluate(case_data, exams_all, path, ids)
		print("score %s %s rank=%s score=%.2f" % [pid, path, str(r.get("rank_id", "")), float(r.get("score", 0.0))])
		if bool(r.get("mistreat", false)):
			fails.append("%s %s legal path mistreat" % [pid, path])
		if float(r.get("score", 0.0)) < 0.55:
			fails.append("%s %s legal path too weak (%.2f)" % [pid, path, float(r.get("score", 0.0))])
		var r2: Dictionary = Scoring.evaluate(case_data, exams_none, path, ids)
		if float(r2.get("process_mult", 1.0)) >= float(r.get("process_mult", 1.0)):
			fails.append("%s missing-exam should discount" % pid)
	if fails.is_empty():
		print("SMOKE PASS")
		return 0
	for f in fails:
		print("FAIL: ", f)
	print("SMOKE FAIL")
	return 1
