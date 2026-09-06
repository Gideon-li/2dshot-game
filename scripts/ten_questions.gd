class_name TenQuestions
extends RefCounted

const PATH := "res://logic/ten_questions.json"

static func load_pack() -> Dictionary:
	var txt := FileAccess.get_file_as_string(PATH)
	var parsed: Variant = JSON.parse_string(txt)
	if typeof(parsed) == TYPE_DICTIONARY:
		return parsed
	return {}


static func button_ids() -> PackedStringArray:
	var out := PackedStringArray()
	var pack := load_pack()
	for q in pack.get("questions", []):
		if typeof(q) == TYPE_DICTIONARY:
			out.append(str(q.get("id", "")))
	return out


static func prompt_for(id: String, locale: String = "zh") -> String:
	var pack := load_pack()
	for q in pack.get("questions", []):
		if typeof(q) == TYPE_DICTIONARY and str(q.get("id", "")) == id:
			if q.has(locale) and str(q[locale]) != "":
				return str(q[locale])
			return str(q.get("zh", ""))
	return ""


static func mentor_cue(missing_flag: String) -> String:
	# Prefer patients/slice_characters.json mentor.exam_missing_cues via CaseDB.
	if Engine.get_main_loop() != null and Engine.get_main_loop().root != null:
		var db = Engine.get_main_loop().root.get_node_or_null("/root/CaseDB")
		if db != null and db.has_method("mentor_exam_missing_cue"):
			var from_card: String = db.mentor_exam_missing_cue(missing_flag)
			if from_card != "":
				return from_card
	var pack := load_pack()
	var cues: Dictionary = pack.get("mentor_cues", {})
	var arr: Array = cues.get(missing_flag, [])
	if arr.is_empty():
		return ""
	return str(arr[randi() % arr.size()])
