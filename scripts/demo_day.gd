extends Node
## V131 Demo day glue: time_slots single truth + checklist + next_hop.

const GUIDE_DEFAULT := {"enabled": true, "steps_done": [], "dismissed": false}
const STEP_IDS := [
	"morning_consult", "treat", "afternoon_forage",
	"evening_process", "night_codex", "next_day_revisit"
]

var last_next_hop_key: String = ""


func _play() -> Dictionary:
	if Save == null:
		return {}
	if typeof(Save.data.get("play", null)) != TYPE_DICTIONARY:
		Save.data["play"] = {}
	return Save.data["play"]


func ensure() -> Dictionary:
	var play := _play()
	if typeof(play.get("time_slots")) != TYPE_DICTIONARY:
		play["time_slots"] = {"morning": 1, "afternoon": 1, "evening": 1, "night": 1}
	else:
		var slots: Dictionary = play["time_slots"]
		for k in ["morning", "afternoon", "evening", "night"]:
			if not slots.has(k):
				slots[k] = 1
		play["time_slots"] = slots
	var g: Variant = play.get("demo_guide", null)
	if typeof(g) != TYPE_DICTIONARY:
		play["demo_guide"] = GUIDE_DEFAULT.duplicate(true)
	else:
		var gd: Dictionary = g
		if not gd.has("enabled"):
			gd["enabled"] = true
		if typeof(gd.get("steps_done")) != TYPE_ARRAY:
			gd["steps_done"] = []
		if not gd.has("dismissed"):
			gd["dismissed"] = false
		play["demo_guide"] = gd
	Save.data["play"] = play
	return play


func guide() -> Dictionary:
	ensure()
	return (_play().get("demo_guide", GUIDE_DEFAULT) as Dictionary).duplicate(true)


func guide_enabled() -> bool:
	var g := guide()
	return bool(g.get("enabled", true)) and not bool(g.get("dismissed", false))


func set_guide_dismissed(v: bool) -> void:
	var play := ensure()
	var g: Dictionary = play["demo_guide"]
	g["dismissed"] = v
	play["demo_guide"] = g
	Save.data["play"] = play
	Save.write_slot()


func slot_remaining(slot: String) -> int:
	ensure()
	var slots: Dictionary = _play().get("time_slots", {})
	return int(slots.get(slot, 0))


func can_act(action_id: String) -> Dictionary:
	## Single truth for HUD button enable.
	ensure()
	var play := _play()
	var slots: Dictionary = play.get("time_slots", {})
	match action_id:
		"morning_consult", "next_day_open":
			return {"ok": true, "slot": "", "reason_key": ""}
		"go_garden":
			if int(slots.get("afternoon", 0)) > 0:
				return {"ok": true, "slot": "afternoon", "reason_key": ""}
			return {"ok": false, "slot": "afternoon", "reason_key": "SLOT_EXHAUSTED_AFTERNOON"}
		"go_process":
			if int(slots.get("evening", 0)) > 0:
				return {"ok": true, "slot": "evening", "reason_key": ""}
			return {"ok": false, "slot": "evening", "reason_key": "SLOT_EXHAUSTED_DUSK"}
		"go_loft":
			# Review already-unlocked pages is free (Codex handles); entering first read needs night.
			if int(slots.get("night", 0)) > 0:
				return {"ok": true, "slot": "night", "reason_key": ""}
			if Codex and Codex.has_method("has_any_unlock") and Codex.has_any_unlock():
				return {"ok": true, "slot": "night", "reason_key": "", "review": true}
			return {"ok": false, "slot": "night", "reason_key": "SLOT_EXHAUSTED_NIGHT"}
		_:
			return {"ok": true, "slot": "", "reason_key": ""}


func mark_step_done(step_id: String) -> void:
	if step_id == "" or step_id not in STEP_IDS:
		return
	var play := ensure()
	var g: Dictionary = play["demo_guide"]
	var done: Array = g.get("steps_done", []) if typeof(g.get("steps_done")) == TYPE_ARRAY else []
	if step_id in done:
		return
	done.append(step_id)
	g["steps_done"] = done
	play["demo_guide"] = g
	Save.data["play"] = play
	Save.write_slot()


func is_step_done(step_id: String) -> bool:
	return step_id in guide().get("steps_done", [])


func reset_day_segment_steps() -> void:
	## After next-day open: clear day-segment steps but keep guide enabled flag.
	var play := ensure()
	var g: Dictionary = play["demo_guide"]
	g["steps_done"] = []
	play["demo_guide"] = g
	Save.data["play"] = play


func refill_slots_for_new_day(play: Dictionary) -> void:
	play["time_slots"] = {"morning": 1, "afternoon": 1, "evening": 1, "night": 1}


func on_settle(path: String) -> void:
	mark_step_done("morning_consult")
	mark_step_done("treat")
	last_next_hop_key = "DEMO_NEXT_GARDEN"
	if path == "food":
		last_next_hop_key = "DEMO_NEXT_GARDEN"
	# Prefer pending revisit hint if any due tomorrow
	if GameFlow and GameFlow.has_method("peek_due_revisit"):
		pass
	Save.write_slot()


func on_forage() -> void:
	mark_step_done("afternoon_forage")
	last_next_hop_key = "DEMO_NEXT_PROCESS"


func on_process() -> void:
	mark_step_done("evening_process")
	last_next_hop_key = "DEMO_NEXT_LOFT"


func on_codex() -> void:
	mark_step_done("night_codex")
	last_next_hop_key = "DEMO_NEXT_NEXT_DAY"


func on_next_day() -> void:
	mark_step_done("next_day_revisit")
	last_next_hop_key = "DEMO_DONE"
	reset_day_segment_steps()
	# keep next_day_revisit marked after reset? Spec says clear day segment — re-mark revisit after pull
	mark_step_done("next_day_revisit")


func next_hop_text() -> String:
	var key := last_next_hop_key
	if key == "":
		key = "DEMO_NEXT_GARDEN"
	var t := TranslationServer.translate(key)
	if t == key or t == "":
		match key:
			"DEMO_NEXT_PROCESS":
				return "暮可进炮制院。"
			"DEMO_NEXT_LOFT":
				return "夜可上阁楼夜读。"
			"DEMO_NEXT_NEXT_DAY":
				return "今日事了，可次日开馆。"
			"DEMO_DONE":
				return "今日引导已走完。"
			_:
				return "可去药圃采药。"
	return t


func step_label(step_id: String) -> String:
	var keys := {
		"morning_consult": "DEMO_STEP_1",
		"treat": "DEMO_STEP_1",
		"afternoon_forage": "DEMO_STEP_2",
		"evening_process": "DEMO_STEP_3",
		"night_codex": "DEMO_STEP_4",
		"next_day_revisit": "DEMO_STEP_5",
	}
	# Use 6 UI steps mapping: merge morning+treat as step1
	var key := str(keys.get(step_id, "DEMO_GUIDE_TITLE"))
	var t := TranslationServer.translate(key)
	return t if t != key else step_id
