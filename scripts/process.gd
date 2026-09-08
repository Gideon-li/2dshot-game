extends Node
## V124/V128 processing yard: wash / stir-fry / sun-dry → raw|processed stock. Autoload Process.

signal inventory_changed
signal quality_changed

const PROCESS_SCENE := "res://scenes/process.tscn"
const CLINIC_SCENE := "res://scenes/clinic.tscn"
const SCRIPT_PATH := "res://patients/process_script.json"

var _script: Dictionary = {}


func _ready() -> void:
	_load_script()
	_ensure_play_fields()


func _load_script() -> void:
	if not FileAccess.file_exists(SCRIPT_PATH):
		_script = {}
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SCRIPT_PATH))
	_script = parsed if typeof(parsed) == TYPE_DICTIONARY else {}


func process_script() -> Dictionary:
	if _script.is_empty():
		_load_script()
	return _script


func _ensure_play_fields() -> void:
	if typeof(Save.data.get("play")) != TYPE_DICTIONARY:
		Save.data["play"] = {}
	var play: Dictionary = Save.data["play"]
	if typeof(play.get("herb_stock")) != TYPE_DICTIONARY:
		play["herb_stock"] = {}
	if typeof(play.get("herb_inventory")) != TYPE_DICTIONARY:
		play["herb_inventory"] = {}
	if typeof(play.get("process_quality")) != TYPE_DICTIONARY:
		play["process_quality"] = {}
	if typeof(play.get("herb_items")) != TYPE_ARRAY:
		play["herb_items"] = []
	if typeof(play.get("time_slots")) != TYPE_DICTIONARY:
		play["time_slots"] = {"morning": 1, "afternoon": 1, "evening": 1}
	elif not (play["time_slots"] as Dictionary).has("evening"):
		(play["time_slots"] as Dictionary)["evening"] = 1
	_migrate_stock_shape(play)
	Save.data["play"] = play


func _play() -> Dictionary:
	_ensure_play_fields()
	return Save.data["play"] as Dictionary


func _migrate_stock_shape(play: Dictionary) -> void:
	var stock: Dictionary = play.get("herb_stock", {}) if typeof(play.get("herb_stock", {})) == TYPE_DICTIONARY else {}
	var inv: Dictionary = play.get("herb_inventory", {}) if typeof(play.get("herb_inventory", {})) == TYPE_DICTIONARY else {}
	# Merge legacy int inventory into stock first.
	for k in inv.keys():
		if not stock.has(k):
			stock[k] = inv[k]
	var out := {}
	for hid in stock.keys():
		var v: Variant = stock[hid]
		if typeof(v) == TYPE_DICTIONARY:
			out[hid] = {
				"raw": int((v as Dictionary).get("raw", 0)),
				"processed": int((v as Dictionary).get("processed", 0)),
			}
		else:
			var n := int(v)
			if needs_process(str(hid)):
				out[hid] = {"raw": n, "processed": 0}
			else:
				out[hid] = {"raw": 0, "processed": n}
	play["herb_stock"] = out
	# Keep flat herb_inventory as total for legacy readers.
	var flat := {}
	for hid2 in out.keys():
		var row: Dictionary = out[hid2]
		flat[hid2] = int(row.get("raw", 0)) + int(row.get("processed", 0))
	play["herb_inventory"] = flat


func process_pack(herb_id: String) -> Dictionary:
	if CaseDB and CaseDB.has_method("process_entry"):
		var pe: Dictionary = CaseDB.process_entry(herb_id)
		if not pe.is_empty():
			return pe
	var h: Dictionary = CaseDB.herb(herb_id) if CaseDB else {}
	var p: Variant = h.get("process", {})
	if typeof(p) == TYPE_DICTIONARY and not (p as Dictionary).is_empty():
		return p as Dictionary
	# Script table fallback (patients/process_script.json v2).
	for row in process_script().get("herbs", []):
		if typeof(row) != TYPE_DICTIONARY:
			continue
		if str((row as Dictionary).get("id", "")) == herb_id:
			return row as Dictionary
	return {}


func needs_process(herb_id: String) -> bool:
	return bool(process_pack(herb_id).get("needs_process", false))


func process_method(herb_id: String) -> String:
	var m := str(process_pack(herb_id).get("process_method", "")).strip_edges().to_lower()
	match m:
		"fry", "stir", "chao":
			return "stir_fry"
		"sun", "dry", "sun_dry":
			return "sun_dry"
		_:
			return m


func teaching_herb_ids() -> PackedStringArray:
	var out := PackedStringArray()
	var rules: Dictionary = CaseDB.pack.get("process_rules", {}) if CaseDB else {}
	var arr: Variant = rules.get("teaching_herbs", ["xingren", "baishao"])
	if typeof(arr) == TYPE_ARRAY:
		for x in arr:
			out.append(str(x))
	if out.is_empty():
		out.append("xingren")
		out.append("baishao")
	return out


func optional_warning_herb() -> String:
	var rules: Dictionary = CaseDB.pack.get("process_rules", {}) if CaseDB else {}
	return str(rules.get("optional_warning_herb", "fuzi"))


func raw_count(herb_id: String) -> int:
	return int(_entry(herb_id).get("raw", 0))


func processed_count(herb_id: String) -> int:
	return int(_entry(herb_id).get("processed", 0))


func stock_total(herb_id: String) -> int:
	var e := _entry(herb_id)
	return int(e.get("raw", 0)) + int(e.get("processed", 0))


func _entry(herb_id: String) -> Dictionary:
	var play := _play()
	var stock: Dictionary = play.get("herb_stock", {})
	var v: Variant = stock.get(herb_id, {})
	if typeof(v) == TYPE_DICTIONARY:
		return v as Dictionary
	if typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT:
		if needs_process(herb_id):
			return {"raw": int(v), "processed": 0}
		return {"raw": 0, "processed": int(v)}
	return {"raw": 0, "processed": 0}


func _write_entry(herb_id: String, raw: int, processed: int) -> void:
	var play := _play()
	var stock: Dictionary = play.get("herb_stock", {}) if typeof(play.get("herb_stock", {})) == TYPE_DICTIONARY else {}
	stock[herb_id] = {"raw": maxi(0, raw), "processed": maxi(0, processed)}
	play["herb_stock"] = stock
	var inv: Dictionary = play.get("herb_inventory", {}) if typeof(play.get("herb_inventory", {})) == TYPE_DICTIONARY else {}
	inv[herb_id] = maxi(0, raw) + maxi(0, processed)
	play["herb_inventory"] = inv
	_sync_herb_items(play, herb_id, raw, processed)
	Save.data["play"] = play
	Save.write_slot()
	inventory_changed.emit()


func _sync_herb_items(play: Dictionary, herb_id: String, raw: int, processed: int) -> void:
	var items: Array = []
	var old: Variant = play.get("herb_items", [])
	if typeof(old) == TYPE_ARRAY:
		for row in old:
			if typeof(row) == TYPE_DICTIONARY and str((row as Dictionary).get("herb_id", "")) != herb_id:
				items.append(row)
	var q := quality_of(herb_id)
	if raw > 0:
		items.append({"herb_id": herb_id, "count": raw, "state": "raw", "quality": null})
	if processed > 0:
		items.append({"herb_id": herb_id, "count": processed, "state": "processed", "quality": q if q != "" else "ok"})
	play["herb_items"] = items


func quality_of(herb_id: String) -> String:
	var play := _play()
	var qmap: Variant = play.get("process_quality", {})
	if typeof(qmap) != TYPE_DICTIONARY:
		return ""
	return str((qmap as Dictionary).get(herb_id, ""))


func set_quality(herb_id: String, grade: String) -> void:
	if grade not in ["ok", "ok_ish"]:
		grade = "ok_ish"
	var play := _play()
	var qmap: Dictionary = play.get("process_quality", {}) if typeof(play.get("process_quality", {})) == TYPE_DICTIONARY else {}
	qmap[herb_id] = grade
	play["process_quality"] = qmap
	Save.data["play"] = play
	Save.write_slot()
	quality_changed.emit()


func add_raw(herb_id: String, n: int = 1) -> void:
	if n <= 0:
		return
	var e := _entry(herb_id)
	_write_entry(herb_id, int(e.get("raw", 0)) + n, int(e.get("processed", 0)))


func add_processed(herb_id: String, n: int = 1, grade: String = "ok") -> void:
	if n <= 0:
		return
	var e := _entry(herb_id)
	_write_entry(herb_id, int(e.get("raw", 0)), int(e.get("processed", 0)) + n)
	set_quality(herb_id, grade)


func add_stock(herb_id: String, n: int = 1) -> void:
	## Forage / cabinet intake: needs_process → raw, else processed-ready.
	if needs_process(herb_id):
		add_raw(herb_id, n)
	else:
		add_processed(herb_id, n, "ok")


func ensure_teaching_raw(herb_id: String = "") -> void:
	## Cabinet drawers seed raw teaching stock so wash/fry is playable without forage.
	var ids: PackedStringArray = PackedStringArray()
	if herb_id != "":
		ids.append(herb_id)
	else:
		ids = teaching_herb_ids()
		var opt := optional_warning_herb()
		if opt != "" and opt not in ids:
			ids.append(opt)
	for hid in ids:
		if not needs_process(str(hid)):
			continue
		if raw_count(str(hid)) <= 0 and processed_count(str(hid)) <= 0:
			add_raw(str(hid), 1)


func consume_raw_to_processed(herb_id: String, grade: String = "ok") -> Dictionary:
	ensure_teaching_raw(herb_id)
	var e := _entry(herb_id)
	var raw := int(e.get("raw", 0))
	var proc := int(e.get("processed", 0))
	if raw <= 0:
		return {"ok": false, "reason": "no_raw"}
	_write_entry(herb_id, raw - 1, proc + 1)
	set_quality(herb_id, grade)
	return {"ok": true, "quality": grade, "herb_id": herb_id}


func can_use_in_formula(herb_id: String) -> bool:
	if herb_id == "" or not CaseDB.herbs_by_id.has(herb_id):
		return false
	if needs_process(herb_id) and processed_count(herb_id) <= 0:
		return false
	if Forage:
		if herb_id in CaseDB.forage_starter_known():
			return true
		if Forage.is_forage_enabled(herb_id):
			return Forage.is_identified(herb_id) and Forage.stock(herb_id) > 0
	return true


func block_reason(herb_id: String) -> String:
	if not needs_process(herb_id):
		return ""
	if processed_count(herb_id) > 0:
		return ""
	var msg := tr("PROCESS_BLOCK_RAW")
	if msg == "PROCESS_BLOCK_RAW" or msg == "":
		msg = tr("PROCESS_NEED_FIRST")
	if msg == "PROCESS_NEED_FIRST" or msg == "":
		msg = "这味须先炮制，生的不能入盏。"
	return msg


func go_process() -> void:
	if GameFlow and str(GameFlow.fsm_state) != "clinic_idle":
		return
	var play := _play()
	if str(play.get("time_slot", "")) != "evening_spent":
		var slots: Dictionary = play.get("time_slots", {}) if typeof(play.get("time_slots", {})) == TYPE_DICTIONARY else {}
		slots["evening"] = maxi(0, int(slots.get("evening", 1)) - 1)
		play["time_slots"] = slots
		play["time_slot"] = "evening_spent"
		Save.data["play"] = play
		Save.write_slot()
	ensure_teaching_raw()
	if GameFlow:
		GameFlow.fsm_state = "processing"
		GameFlow.fsm_changed.emit("processing")
	var tree := get_tree()
	if tree:
		tree.change_scene_to_file(PROCESS_SCENE)


func leave_process() -> void:
	if GameFlow:
		GameFlow.fsm_state = "clinic_idle"
		GameFlow.fsm_changed.emit("clinic_idle")
	var tree := get_tree()
	if tree:
		tree.change_scene_to_file(CLINIC_SCENE)


func mentor_line(arg = 0) -> String:
	if typeof(arg) == TYPE_STRING:
		var hid := str(arg)
		var teach := herb_teach_line(hid)
		if teach != "":
			return teach
		return block_reason(hid)
	var idx := int(arg)
	return _mentor_line_at(idx)


func _mentor_line_at(idx: int = 0) -> String:
	var bag: Variant = process_script().get("mentor_su", {})
	if typeof(bag) == TYPE_DICTIONARY:
		var lines_v: Variant = (bag as Dictionary).get("lines", {})
		if typeof(lines_v) == TYPE_DICTIONARY:
			var L := _loc()
			var arr: Variant = (lines_v as Dictionary).get(L, (lines_v as Dictionary).get("zh", []))
			if typeof(arr) == TYPE_ARRAY and (arr as Array).size() > 0:
				return str((arr as Array)[clampi(idx, 0, (arr as Array).size() - 1)])
	var keys: Array[String] = ["MENTOR_PROCESS_1", "MENTOR_PROCESS_2", "MENTOR_PROCESS_3"]
	var key: String = keys[clampi(idx, 0, keys.size() - 1)]
	var tt: String = tr(key)
	return tt if tt != key else "火候在人，不在炉。"


func xiaohe_line(idx: int = 0) -> String:
	var bag: Variant = process_script().get("xiaohe", {})
	if typeof(bag) == TYPE_DICTIONARY:
		var lines_v: Variant = (bag as Dictionary).get("lines", {})
		if typeof(lines_v) == TYPE_DICTIONARY:
			var L := _loc()
			var arr: Variant = (lines_v as Dictionary).get(L, (lines_v as Dictionary).get("zh", []))
			if typeof(arr) == TYPE_ARRAY and (arr as Array).size() > 0:
				return str((arr as Array)[clampi(idx, 0, (arr as Array).size() - 1)])
	var keys2: Array[String] = ["XIAOHE_PROCESS_1", "XIAOHE_PROCESS_2"]
	var key2: String = keys2[clampi(idx, 0, keys2.size() - 1)]
	var tt2: String = tr(key2)
	return tt2 if tt2 != key2 else "炉子烫！袖子卷起来。"


func herb_teach_line(herb_id: String) -> String:
	for row in process_script().get("herbs", []):
		if typeof(row) != TYPE_DICTIONARY:
			continue
		if str((row as Dictionary).get("id", "")) != herb_id:
			continue
		return UiKit.loc_text((row as Dictionary).get("teach", {}), "")
	match herb_id:
		"xingren":
			return tr("PROCESS_XINGREN_HINT")
		"mudanpi":
			var mh := tr("PROCESS_MUDANPI_HINT")
			return mh if mh != "PROCESS_MUDANPI_HINT" else "牡丹皮：薄片摊晒。生品不可入盏。"
		"fuzi":
			return tr("PROCESS_FUZI_HINT")
		_:
			return ""


func herb_warn_line(herb_id: String) -> String:
	var pack := process_pack(herb_id)
	var w: Variant = pack.get("warning", null)
	if typeof(w) == TYPE_DICTIONARY:
		var s := UiKit.loc_text(w, "")
		if s != "":
			return s
	for row in process_script().get("herbs", []):
		if typeof(row) != TYPE_DICTIONARY:
			continue
		if str((row as Dictionary).get("id", "")) != herb_id:
			continue
		return UiKit.loc_text((row as Dictionary).get("warn", {}), "")
	if herb_id == optional_warning_herb():
		var t := tr("PROCESS_WARN_TOXIC")
		return t if t != "PROCESS_WARN_TOXIC" else ""
	return ""


func herb_done_line(herb_id: String) -> String:
	for row in process_script().get("herbs", []):
		if typeof(row) != TYPE_DICTIONARY:
			continue
		if str((row as Dictionary).get("id", "")) != herb_id:
			continue
		return UiKit.loc_text((row as Dictionary).get("done", {}), "")
	var t := tr("PROCESS_DONE_HINT")
	return t if t != "PROCESS_DONE_HINT" else "炮好了。回药房就能入托盘。"


func _loc() -> String:
	if GameFlow:
		return GameFlow.loc()
	return "zh"


func processable_ids() -> PackedStringArray:
	var out := PackedStringArray()
	var seen := {}
	for hid in teaching_herb_ids():
		seen[str(hid)] = true
		out.append(str(hid))
	var opt := optional_warning_herb()
	if opt != "" and not seen.has(opt):
		out.append(opt)
		seen[opt] = true
	if CaseDB:
		for hid in CaseDB.herbs_by_id.keys():
			if needs_process(str(hid)) and not seen.has(str(hid)):
				if raw_count(str(hid)) > 0 or processed_count(str(hid)) > 0:
					out.append(str(hid))
					seen[str(hid)] = true
	return out


func grant_raw(herb_id: String, n: int = 1) -> void:
	add_raw(herb_id, n)


func processed_stock(herb_id: String) -> int:
	return processed_count(herb_id)


func raw_stock(herb_id: String) -> int:
	return raw_count(herb_id)


func process_block_reason(herb_id: String) -> String:
	return block_reason(herb_id)


func mark_processed(herb_id: String, grade: String = "ok") -> bool:
	var e := _entry(herb_id)
	var raw := int(e.get("raw", 0))
	var proc := int(e.get("processed", 0))
	if raw > 0:
		_write_entry(herb_id, raw - 1, proc + 1)
		set_quality(herb_id, grade)
		return true
	if proc > 0:
		set_quality(herb_id, grade)
		return true
	_write_entry(herb_id, 0, proc + 1)
	set_quality(herb_id, grade)
	return true


func try_wash(herb_id: String, accuracy: float = 1.0) -> Dictionary:
	ensure_teaching_raw(herb_id)
	if raw_count(herb_id) <= 0:
		return {"ok": false, "reason": "no_raw", "method": "wash"}
	var grade := "ok" if accuracy >= 0.72 else "ok_ish"
	return {"ok": true, "quality": grade, "method": "wash", "herb_id": herb_id}


func try_stir(herb_id: String, accuracy: float = 1.0) -> Dictionary:
	ensure_teaching_raw(herb_id)
	if raw_count(herb_id) <= 0:
		return {"ok": false, "reason": "no_raw", "method": "stir_fry"}
	var grade := "ok" if accuracy >= 0.72 else "ok_ish"
	return {"ok": true, "quality": grade, "method": "stir_fry", "herb_id": herb_id}


func try_stir_fry(herb_id: String, accuracy: float = 1.0) -> Dictionary:
	return try_stir(herb_id, accuracy)


func try_sun(herb_id: String, accuracy: float = 1.0) -> Dictionary:
	return try_sun_dry(herb_id, accuracy)


func try_sun_dry(herb_id: String, accuracy: float = 1.0) -> Dictionary:
	ensure_teaching_raw(herb_id)
	if raw_count(herb_id) <= 0:
		return {"ok": false, "reason": "no_raw", "method": "sun_dry"}
	var grade := "ok" if accuracy >= 0.72 else "ok_ish"
	return {"ok": true, "quality": grade, "method": "sun_dry", "herb_id": herb_id}
