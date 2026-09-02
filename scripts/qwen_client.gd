class_name QwenClient
extends Node
## Runtime ask-path. Key from secrets.env on disk. Never logs the value.
## Timeouts / missing key / HTTP errors fall back to local symptom templates.

const MODEL := "qwen3.8-flash"
const ENDPOINT := "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions"
const TIMEOUT_SEC := 8.0

signal replied(text: String, from_api: bool)

var _http: HTTPRequest
var _busy := false
var _pending_character: Dictionary = {}
var _pending_case: Dictionary = {}
var _pending_question: String = ""


func _ready() -> void:
	_http = HTTPRequest.new()
	_http.timeout = TIMEOUT_SEC
	add_child(_http)
	_http.request_completed.connect(_on_http)


func is_busy() -> bool:
	return _busy


func ask(question: String, character: Dictionary, case_data: Dictionary) -> void:
	_pending_character = character
	_pending_case = case_data
	_pending_question = question
	if _busy:
		return
	var key := _read_api_key()
	if key.is_empty():
		_finish(template_reply(question, character, case_data), false)
		return
	_busy = true
	var body := {
		"model": MODEL,
		"temperature": 0.9,
		"max_tokens": 180,
		"enable_thinking": false,
		"messages": [
			{"role": "system", "content": make_system_prompt(character, case_data)},
			{"role": "user", "content": question},
		],
	}
	var headers := PackedStringArray([
		"Content-Type: application/json",
		"Authorization: Bearer " + key,
	])
	var err := _http.request(ENDPOINT, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_busy = false
		_finish(template_reply(question, character, case_data), false)


func _on_http(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_busy = false
	var fallback := template_reply(_pending_question, _pending_character, _pending_case)
	if result != HTTPRequest.RESULT_SUCCESS or code < 200 or code >= 300:
		_finish(fallback, false)
		return
	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	if typeof(parsed) != TYPE_DICTIONARY:
		_finish(fallback, false)
		return
	var choices: Variant = parsed.get("choices", [])
	if typeof(choices) != TYPE_ARRAY or (choices as Array).is_empty():
		_finish(fallback, false)
		return
	var msg: Variant = (choices as Array)[0]
	if typeof(msg) != TYPE_DICTIONARY:
		_finish(fallback, false)
		return
	var content: Variant = msg.get("message", {}).get("content", "")
	var text := str(content).strip_edges()
	if text.is_empty():
		_finish(fallback, false)
		return
	text = strip_never_say(text, _pending_case)
	_finish(text, true)


func _finish(text: String, from_api: bool) -> void:
	replied.emit(text, from_api)


static func loc_key() -> String:
	var loc := TranslationServer.get_locale()
	if loc.begins_with("en"):
		return "en"
	if loc.begins_with("ja"):
		return "ja"
	return "zh"


static func make_system_prompt(character: Dictionary, case_data: Dictionary) -> String:
	var loc := TranslationServer.get_locale()
	var lang := "Chinese"
	if loc.begins_with("en"):
		lang = "English"
	elif loc.begins_with("ja"):
		lang = "Japanese"
	var key := loc_key()
	var anchors: Array = case_data.get("clues", {}).get("wen_ask", {}).get("inquiry_anchor", [])
	var never: Array = case_data.get("clues", {}).get("wen_ask", {}).get("never_say", [])
	var notes: Dictionary = character.get("pathogenesis_notes", {})
	var lived: Variant = notes.get("lived", {})
	var lived_arr: Array = []
	if typeof(lived) == TYPE_DICTIONARY:
		lived_arr = lived.get(key, lived.get("zh", []))
	var talk: String = UiKit.loc_text(notes.get("how_they_talk_about_it", {}), "")
	var lines: PackedStringArray = []
	lines.append("You are a patient in a historical Chinese clinic cultural game. You are not a doctor. This is not a quiz.")
	lines.append("Reply in %s. Stay in spoken first person. 1–3 short sentences." % lang)
	lines.append("Character card:")
	lines.append("- name: " + UiKit.loc_text(character.get("name", {}), ""))
	lines.append("- age: " + str(character.get("age", "")))
	lines.append("- identity: " + UiKit.loc_text(character.get("identity", {}), ""))
	lines.append("- region: " + UiKit.loc_text(character.get("region", {}), ""))
	lines.append("- personality: " + UiKit.loc_text(character.get("personality", {}), ""))
	lines.append("- why they came: " + UiKit.loc_text(character.get("motive", {}), ""))
	lines.append("Pathogenesis notes (INTERNAL, lived wording):")
	for a in lived_arr:
		lines.append("- " + str(a))
	if talk != "":
		lines.append("How they talk about it: " + talk)
	lines.append("Inquiry anchors (INTERNAL, bite these, do not dump them):")
	for a in anchors:
		lines.append("- " + str(a))
	var rules: PackedStringArray = CaseDB.inquiry_rules_lines() if CaseDB else PackedStringArray()
	if not rules.is_empty():
		lines.append("Inquiry rules:")
		for r in rules:
			lines.append("- " + r)
	lines.append("vary wording, do not volunteer diagnosis")
	lines.append("Never volunteer a complete chart. Only answer what was asked, with at most one extra lived detail.")
	lines.append("If the player hunts for a disease or formula name, dodge back to bodily feeling.")
	lines.append("Never say these words: " + ", ".join(PackedStringArray(never)))
	return "\n".join(lines)


static func wants_diagnosis_name(question: String, case_data: Dictionary) -> bool:
	var q := question
	var ql := q.to_lower()
	var never: Array = case_data.get("clues", {}).get("wen_ask", {}).get("never_say", [])
	for n in never:
		if str(n) != "" and q.find(str(n)) >= 0:
			return true
	for token in ["病名", "什么病", "什麼病", "诊断", "診斷", "证型", "證型", "方名", "什么方", "什麼方", "是不是风寒", "是不是肝郁", "是不是阴虚", "diagnosis", "disease name", "formula name", "pattern name", "what disease", "what formula", "病名", "診断", "処方名", "証名"]:
		if q.find(token) >= 0 or ql.find(token.to_lower()) >= 0:
			return true
	return false


static func template_reply(question: String, character: Dictionary, case_data: Dictionary) -> String:
	var ask: Dictionary = case_data.get("clues", {}).get("wen_ask", {})
	var anchors: Array = ask.get("inquiry_anchor", [])
	if wants_diagnosis_name(question, case_data):
		return UiKit.loc_text(character.get("dodge", {}), "")
	var picked := _pick_anchors(question, anchors)
	var wrap_key := loc_key()
	var wrappers: Array = character.get("ask_wrappers", {}).get(wrap_key, [])
	if wrappers.is_empty():
		wrappers = character.get("ask_wrappers", {}).get("zh", [])
	if wrappers.is_empty():
		wrappers = ["{sym}"]
	var wrap := str(wrappers[abs(hash(question + str(Time.get_ticks_msec() / 4000))) % wrappers.size()])
	# {sym} = inquiry_anchor only. Never diagnosis names.
	var sym := "，".join(PackedStringArray(picked)) if wrap_key == "zh" else "; ".join(PackedStringArray(picked))
	return wrap.replace("{sym}", sym)


static func _pick_anchors(question: String, anchors: Array) -> Array:
	if anchors.is_empty():
		return ["……"]
	var q := question
	var ql := q.to_lower()
	var scored: Array = []
	for a in anchors:
		var s := str(a)
		var score := 0
		for token in ["睡", "夜", "汗", "冷", "热", "熱", "吃", "饭", "胸", "胁", "風", "风", "喉", "干", "sleep", "sweat", "cold", "heat", "eat", "chest", "night", "throat"]:
			if q.find(token) >= 0 or ql.find(token) >= 0:
				if s.find(token) >= 0:
					score += 2
		scored.append([score, s])
	scored.sort_custom(func(a, b): return a[0] > b[0])
	var out: Array = []
	if int(scored[0][0]) > 0:
		out.append(scored[0][1])
		if scored.size() > 1 and int(scored[1][0]) > 0:
			out.append(scored[1][1])
		if out.size() > 2:
			out = out.slice(0, 2)
		return out
	var idx: int = abs(hash(question)) % anchors.size()
	out.append(str(anchors[idx]))
	return out


static func strip_never_say(text: String, case_data: Dictionary) -> String:
	var never: Array = case_data.get("clues", {}).get("wen_ask", {}).get("never_say", [])
	var out := text
	for n in never:
		out = out.replace(str(n), "……")
	return out


func _template_reply(question: String, character: Dictionary, case_data: Dictionary) -> String:
	return template_reply(question, character, case_data)


func _system_prompt(character: Dictionary, case_data: Dictionary) -> String:
	return make_system_prompt(character, case_data)


func _read_api_key() -> String:
	var paths: PackedStringArray = [
		ProjectSettings.globalize_path("res://secrets.env"),
		OS.get_executable_path().get_base_dir().path_join("secrets.env"),
	]
	for p in paths:
		if p.is_empty() or not FileAccess.file_exists(p):
			continue
		var f := FileAccess.open(p, FileAccess.READ)
		if f == null:
			continue
		while not f.eof_reached():
			var line := f.get_line().strip_edges()
			if line.is_empty() or line.begins_with("#"):
				continue
			if line.begins_with("export "):
				line = line.substr(7).strip_edges()
			var eq := line.find("=")
			if eq <= 0:
				continue
			var k := line.substr(0, eq).strip_edges()
			var v := line.substr(eq + 1).strip_edges()
			if (v.begins_with("\"") and v.ends_with("\"")) or (v.begins_with("'") and v.ends_with("'")):
				v = v.substr(1, v.length() - 2)
			if k == "KEY" or k == "QWEN_API_KEY" or k == "DASHSCOPE_API_KEY":
				return v
	return ""
