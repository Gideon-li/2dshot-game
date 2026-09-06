extends Node
## V121 identify + forage. Backed by CaseDB.forage_* + Save play.herb_inventory.

signal inventory_changed
signal identified_changed

const GARDEN_SCENE := "res://scenes/garden.tscn"
const CLINIC_SCENE := "res://scenes/clinic.tscn"

const EXTRA_NAMES := {
	"rougui": {"zh": "肉桂", "en": "Cassia bark", "ja": "肉桂"},
	"huangqi": {"zh": "黄芪", "en": "Astragalus", "ja": "黄耆"},
	"banxia": {"zh": "半夏", "en": "Pinellia", "ja": "半夏"},
	"chishao": {"zh": "赤芍", "en": "Red peony", "ja": "赤芍"},
	"huangqin": {"zh": "黄芩", "en": "Scutellaria", "ja": "黄芩"},
	"chuanxiong": {"zh": "川芎", "en": "Chuanxiong", "ja": "川芎"},
	"cangzhu": {"zh": "苍术", "en": "Cangzhu", "ja": "蒼朮"},
	"shengdi": {"zh": "生地", "en": "Raw rehmannia", "ja": "生地"},
}

const SHAPE_META := {
	"mahuang": {"shape": "stem", "color": Color(0.28, 0.42, 0.28)},
	"guizhi": {"shape": "twig", "color": Color(0.55, 0.28, 0.16)},
	"gancao": {"shape": "root", "color": Color(0.72, 0.58, 0.32)},
	"shengjiang": {"shape": "rhizome", "color": Color(0.86, 0.78, 0.42)},
	"baishao": {"shape": "bloom", "color": Color(0.92, 0.78, 0.82)},
	"chaihu": {"shape": "blade", "color": Color(0.42, 0.48, 0.28)},
	"danggui": {"shape": "root", "color": Color(0.62, 0.36, 0.28)},
	"baizhu": {"shape": "knob", "color": Color(0.78, 0.68, 0.48)},
	"fuling": {"shape": "lump", "color": Color(0.9, 0.88, 0.82)},
	"bohe": {"shape": "leaf", "color": Color(0.32, 0.58, 0.42)},
	"shudi": {"shape": "tuber", "color": Color(0.22, 0.14, 0.12)},
	"shanyao": {"shape": "tuber", "color": Color(0.94, 0.9, 0.78)},
}


func _ready() -> void:
	_ensure_play_fields()


func _ensure_play_fields() -> void:
	if typeof(Save.data.get("play")) != TYPE_DICTIONARY:
		Save.data["play"] = {}
	var play: Dictionary = Save.data["play"]
	if typeof(play.get("herb_inventory")) != TYPE_DICTIONARY:
		play["herb_inventory"] = {}
	if typeof(play.get("herb_stock")) != TYPE_DICTIONARY:
		play["herb_stock"] = play["herb_inventory"]
	if typeof(play.get("herbs_identified")) != TYPE_ARRAY:
		play["herbs_identified"] = []
	if typeof(play.get("identified_herbs")) != TYPE_ARRAY:
		play["identified_herbs"] = play["herbs_identified"]
	if typeof(play.get("time_slots")) != TYPE_DICTIONARY:
		play["time_slots"] = {"morning": 1, "afternoon": 1, "evening": 1}
	Save.data["play"] = play


func _play() -> Dictionary:
	_ensure_play_fields()
	return Save.data["play"] as Dictionary


func _loc() -> String:
	if GameFlow:
		return GameFlow.loc()
	return "zh"


func forage_enabled_ids() -> PackedStringArray:
	var out := PackedStringArray()
	# Prefer CaseDB forage pack (logic/forage_herbs.json).
	if CaseDB and CaseDB.forage_by_id.size() > 0:
		for hid in CaseDB.forage_herb_ids():
			out.append(str(hid))
		return out
	# Fallback: slice_logic herbs[].forage.enabled
	for h in CaseDB.pack.get("herbs", []):
		if typeof(h) != TYPE_DICTIONARY:
			continue
		var f: Variant = h.get("forage", {})
		if typeof(f) == TYPE_DICTIONARY and bool((f as Dictionary).get("enabled", false)):
			out.append(str(h.get("id", "")))
	return out


func is_forage_enabled(herb_id: String) -> bool:
	return herb_id in forage_enabled_ids() or CaseDB.forage_by_id.has(herb_id)


func forage_pack(herb_id: String) -> Dictionary:
	if CaseDB.forage_by_id.has(herb_id):
		return CaseDB.forage_entry(herb_id)
	var h: Dictionary = CaseDB.herb(herb_id)
	var f: Variant = h.get("forage", {})
	if typeof(f) == TYPE_DICTIONARY:
		return f as Dictionary
	return {}


func spots() -> PackedStringArray:
	## Prefer spot ids actually stored on herb entries (CaseDB may remap spot_* → SPOT_*).
	var out := PackedStringArray()
	var seen := {}
	for hid in forage_enabled_ids():
		var f: Dictionary = forage_pack(hid)
		var spot := str(f.get("spot_id", f.get("scene_spot", "")))
		if spot != "" and not seen.has(spot):
			seen[spot] = true
			out.append(spot)
	if not out.is_empty():
		return out
	var pack_spots: Variant = CaseDB.forage_pack.get("spots", [])
	if typeof(pack_spots) == TYPE_ARRAY:
		for s in pack_spots:
			if typeof(s) == TYPE_DICTIONARY:
				var sid := str((s as Dictionary).get("id", ""))
				if sid != "" and not seen.has(sid):
					seen[sid] = true
					out.append(sid)
	return out


func spot_label(spot: String) -> String:
	if CaseDB.has_method("_forage_spot_label_dict"):
		var d: Dictionary = CaseDB._forage_spot_label_dict(spot)
		var s := UiKit.loc_text(d, "")
		if s != "" and s != spot:
			return s
	var pack_spots: Variant = CaseDB.forage_pack.get("spots", [])
	if typeof(pack_spots) == TYPE_ARRAY:
		for s in pack_spots:
			if typeof(s) != TYPE_DICTIONARY:
				continue
			var sid := str((s as Dictionary).get("id", ""))
			if sid == spot:
				return UiKit.loc_text(s, spot)
			# legacy map
			var map := {"spot_trellis": "SPOT_A", "spot_bed": "SPOT_B", "spot_ditch": "SPOT_C"}
			if str(map.get(sid, "")) == spot:
				return UiKit.loc_text(s, spot)
	for hid in forage_enabled_ids():
		var f: Dictionary = forage_pack(hid)
		if str(f.get("spot_id", f.get("scene_spot", ""))) == spot:
			return UiKit.loc_text(f.get("spot_label", {}), spot)
	match spot:
		"SPOT_A", "spot_trellis":
			return UiKit.loc_text({"zh": "棚架边", "en": "By the trellis", "ja": "棚のそば"}, spot)
		"SPOT_B", "spot_bed":
			return UiKit.loc_text({"zh": "畦心", "en": "Bed center", "ja": "畝の中央"}, spot)
		"SPOT_C", "spot_ditch":
			return UiKit.loc_text({"zh": "水沟旁", "en": "By the ditch", "ja": "溝のそば"}, spot)
		_:
			return spot


func herbs_at_spot(spot: String) -> PackedStringArray:
	var out := PackedStringArray()
	for hid in forage_enabled_ids():
		var f: Dictionary = forage_pack(hid)
		var sid := str(f.get("spot_id", f.get("scene_spot", "")))
		if sid == spot:
			out.append(hid)
	return out


func herb_display_name(herb_id: String) -> String:
	if CaseDB.herbs_by_id.has(herb_id):
		return CaseDB.herb_name(herb_id)
	if EXTRA_NAMES.has(herb_id):
		return UiKit.loc_text(EXTRA_NAMES[herb_id], herb_id)
	var e: Dictionary = CaseDB.forage_entry(herb_id)
	if not e.is_empty():
		return UiKit.loc_text(e, herb_id)
	return herb_id


func clues_for(herb_id: String, count: int = 2) -> PackedStringArray:
	var out := PackedStringArray()
	if CaseDB.has_method("forage_clues"):
		for line in CaseDB.forage_clues(herb_id):
			out.append(str(line))
			if out.size() >= count:
				return out
	var f: Dictionary = forage_pack(herb_id)
	var clues: Variant = f.get("clues", [])
	if typeof(clues) == TYPE_ARRAY:
		for c in clues:
			if typeof(c) == TYPE_DICTIONARY:
				out.append(UiKit.loc_text(c, ""))
			elif typeof(c) == TYPE_STRING:
				out.append(str(c))
			if out.size() >= count:
				break
	return out


func identify_options(herb_id: String) -> PackedStringArray:
	var out := PackedStringArray()
	if CaseDB.has_method("forage_identify_options"):
		for o in CaseDB.forage_identify_options(herb_id):
			out.append(str(o))
		if not out.is_empty():
			return out
	var f: Dictionary = forage_pack(herb_id)
	var opts: Variant = f.get("identify_options", [])
	if typeof(opts) == TYPE_ARRAY:
		for o in opts:
			out.append(str(o))
	if out.is_empty():
		out.append(herb_id)
	return out


func correct_id(herb_id: String) -> String:
	var f: Dictionary = forage_pack(herb_id)
	var c := str(f.get("identify_correct", herb_id))
	return c if c != "" else herb_id


func shape_meta(herb_id: String) -> Dictionary:
	if SHAPE_META.has(herb_id):
		return SHAPE_META[herb_id]
	if CaseDB.has_method("forage_swatch"):
		return {"shape": "leaf", "color": CaseDB.forage_swatch(herb_id)}
	return {"shape": "leaf", "color": Color(0.5, 0.55, 0.4)}


func is_identified(herb_id: String) -> bool:
	if herb_id in CaseDB.forage_starter_known():
		return true
	if not is_forage_enabled(herb_id):
		return true
	var play: Dictionary = _play()
	var arr: Array = play.get("identified_herbs", play.get("herbs_identified", []))
	if typeof(arr) != TYPE_ARRAY:
		return false
	return herb_id in arr


func stock(herb_id: String) -> int:
	var play: Dictionary = _play()
	var inv: Variant = play.get("herb_stock", play.get("herb_inventory", {}))
	if typeof(inv) != TYPE_DICTIONARY:
		return 0
	return int((inv as Dictionary).get(herb_id, 0))


func mark_identified(herb_id: String) -> void:
	var play: Dictionary = _play()
	var arr: Array = play.get("identified_herbs", [])
	if typeof(arr) != TYPE_ARRAY:
		arr = []
	if herb_id not in arr:
		arr.append(herb_id)
	play["identified_herbs"] = arr
	play["herbs_identified"] = arr
	Save.data["play"] = play
	Save.write_slot()
	identified_changed.emit()


func add_stock(herb_id: String, n: int) -> void:
	if n <= 0:
		return
	var play: Dictionary = _play()
	var inv: Dictionary = play.get("herb_stock", {}) if typeof(play.get("herb_stock", {})) == TYPE_DICTIONARY else {}
	inv[herb_id] = int(inv.get(herb_id, 0)) + n
	play["herb_stock"] = inv
	play["herb_inventory"] = inv.duplicate()
	Save.data["play"] = play
	Save.write_slot()
	inventory_changed.emit()


func try_identify(spot_herb_id: String, chosen_id: String) -> Dictionary:
	var correct := correct_id(spot_herb_id)
	if chosen_id == correct or chosen_id == spot_herb_id:
		mark_identified(spot_herb_id)
		var ok_fb: String = CaseDB.forage_success_line() if CaseDB.has_method("forage_success_line") else tr("FORAGE_OK")
		return {"ok": true, "feedback": ok_fb}
	var bad_fb: String = CaseDB.forage_wrong(spot_herb_id) if CaseDB.has_method("forage_wrong") else tr("FORAGE_WRONG")
	return {"ok": false, "feedback": bad_fb}


func pick_herb(herb_id: String) -> Dictionary:
	if not is_identified(herb_id):
		return {"ok": false, "reason": "not_identified", "added": 0}
	var yld: int = 1
	if CaseDB.has_method("forage_yield"):
		yld = CaseDB.forage_yield(herb_id)
	else:
		var f: Dictionary = forage_pack(herb_id)
		var y: Variant = f.get("yield", 1)
		if typeof(y) == TYPE_DICTIONARY:
			yld = int((y as Dictionary).get("min", 1))
		else:
			yld = maxi(1, int(y))
	add_stock(herb_id, yld)
	return {"ok": true, "added": yld}


func can_use_in_formula(herb_id: String) -> bool:
	if herb_id == "" or not CaseDB.herbs_by_id.has(herb_id):
		return false
	if herb_id in CaseDB.forage_starter_known():
		return true
	if not is_forage_enabled(herb_id):
		return true
	return is_identified(herb_id) and stock(herb_id) > 0


func go_garden() -> void:
	var play: Dictionary = _play()
	if str(play.get("time_slot", "")) != "afternoon_spent":
		var slots: Dictionary = play.get("time_slots", {}) if typeof(play.get("time_slots", {})) == TYPE_DICTIONARY else {}
		slots["afternoon"] = maxi(0, int(slots.get("afternoon", 1)) - 1)
		play["time_slots"] = slots
		play["time_slot"] = "afternoon_spent"
		Save.data["play"] = play
		Save.write_slot()
	if GameFlow:
		GameFlow.fsm_state = "foraging"
		GameFlow.fsm_changed.emit("foraging")
	var tree := get_tree()
	if tree:
		tree.change_scene_to_file(GARDEN_SCENE)


func leave_garden() -> void:
	if GameFlow:
		GameFlow.fsm_state = "clinic_idle"
		GameFlow.fsm_changed.emit("clinic_idle")
	var tree := get_tree()
	if tree:
		tree.change_scene_to_file(CLINIC_SCENE)


func agui_hint() -> String:
	if CaseDB.has_method("agui_hint"):
		var s: String = CaseDB.agui_hint()
		if s != "":
			return s
	return tr("AGUI_HINT_1")


func mentor_forage_line() -> String:
	if CaseDB.has_method("mentor_forage_line"):
		var s: String = CaseDB.mentor_forage_line()
		if s != "":
			return s
	return tr("MENTOR_FORAGE")
