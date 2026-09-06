extends Node
## Runtime Qwen ask. Reads secrets.env in-process; never logs key material.

signal reply_ready(text: String, from_api: bool)

const _KEY_NAMES := ["QWEN_API_KEY", "DASHSCOPE_API_KEY", "QWEN_KEY", "API_KEY", "KEY"]
const _MODEL_NAMES := ["QWEN_MODEL", "DASHSCOPE_MODEL", "MODEL"]
const _URL_NAMES := ["QWEN_BASE_URL", "DASHSCOPE_BASE_URL", "OPENAI_BASE_URL"]
const _DEFAULT_URL := "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions"
const _DEFAULT_MODEL := "qwen3.8-flash"

var _http: HTTPRequest
var _busy := false
var _history: Array = []
var _pending_q: String = ""

func _ready() -> void:
	_http = HTTPRequest.new()
	_http.timeout = 10.0
	_http.request_completed.connect(_on_http)
	add_child(_http)

func reset_session() -> void:
	_history.clear()
	_busy = false

func is_busy() -> bool:
	return _busy

func has_runtime_key() -> bool:
	return _read_key() != ""

func ask(player_text: String) -> void:
	if _busy:
		return
	var q := player_text.strip_edges()
	if q == "":
		q = "……"
	_pending_q = q
	if not has_runtime_key():
		_fallback()
		return
	_busy = true
	var key := _read_key()
	var model := _read_named(_MODEL_NAMES, _DEFAULT_MODEL)
	var url := _normalize_url(_read_named(_URL_NAMES, _DEFAULT_URL))
	var messages: Array = [{"role": "system", "content": GameFlow.inquiry_system_prompt()}]
	for turn in _history:
		messages.append(turn)
	messages.append({"role": "user", "content": q})
	_history.append({"role": "user", "content": q})
	var body := JSON.stringify({
		"model": model,
		"messages": messages,
		"temperature": 0.9,
		"max_tokens": 220,
	})
	var headers := PackedStringArray([
		"Content-Type: application/json",
		"Authorization: Bearer %s" % key,
	])
	var err := _http.request(url, headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		_busy = false
		_history.pop_back()
		_fallback()

func _fallback() -> void:
	_busy = false
	var character := CaseDB.patient_by_id(GameFlow.current_patient_id)
	var case_data := CaseDB.case_for_patient(GameFlow.current_patient_id)
	var line := QwenClient.template_reply(_pending_q, character, case_data)
	if not QwenClient.wants_diagnosis_name(_pending_q, case_data):
		GameFlow.consume_inquiry_anchor()
	_history.append({"role": "assistant", "content": line})
	reply_ready.emit(line, false)

func _on_http(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_busy = false
	if result != HTTPRequest.RESULT_SUCCESS or code < 200 or code >= 300:
		if not _history.is_empty() and str(_history[-1].get("role", "")) == "user":
			_history.pop_back()
		_fallback()
		return
	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	var text := _extract_text(parsed)
	if text == "" or _leaks_diagnosis(text):
		if not _history.is_empty() and str(_history[-1].get("role", "")) == "user":
			_history.pop_back()
		_fallback()
		return
	_history.append({"role": "assistant", "content": text})
	if _history.size() > 12:
		_history = _history.slice(_history.size() - 12)
	reply_ready.emit(text, true)

func _extract_text(parsed: Variant) -> String:
	if typeof(parsed) != TYPE_DICTIONARY:
		return ""
	var d: Dictionary = parsed
	var choices: Variant = d.get("choices", [])
	if typeof(choices) == TYPE_ARRAY and (choices as Array).size() > 0 and typeof((choices as Array)[0]) == TYPE_DICTIONARY:
		var msg: Variant = (choices as Array)[0].get("message", {})
		if typeof(msg) == TYPE_DICTIONARY:
			return str(msg.get("content", "")).strip_edges()
	return ""

func _leaks_diagnosis(text: String) -> bool:
	for w in GameFlow.never_say():
		if w != "" and text.find(w) >= 0:
			return true
	return false

func _read_key() -> String:
	for n in _KEY_NAMES:
		var env := OS.get_environment(n).strip_edges()
		if env != "":
			return env
	var bag := _load_secrets()
	for n in _KEY_NAMES:
		var v := str(bag.get(n, "")).strip_edges()
		if v != "":
			return v
	return ""

func _read_named(names: Array, fallback: String) -> String:
	for n in names:
		var env := OS.get_environment(str(n)).strip_edges()
		if env != "":
			return env
	var bag := _load_secrets()
	for n in names:
		var v := str(bag.get(n, "")).strip_edges()
		if v != "":
			return v
	return fallback

func _normalize_url(url: String) -> String:
	var u := url.strip_edges()
	if u.ends_with("/chat/completions"):
		return u
	if u.ends_with("/v1") or u.ends_with("/compatible-mode/v1"):
		return u + "/chat/completions"
	return u

func _load_secrets() -> Dictionary:
	var out := {}
	var paths := PackedStringArray([
		"res://secrets.env",
		"user://secrets.env",
		OS.get_executable_path().get_base_dir().path_join("secrets.env"),
	])
	for path in paths:
		if not FileAccess.file_exists(path):
			continue
		var f := FileAccess.open(path, FileAccess.READ)
		if f == null:
			continue
		while not f.eof_reached():
			var line := f.get_line().strip_edges()
			if line.begins_with("\uFEFF"):
				line = line.substr(1).strip_edges()
			if line == "" or line.begins_with("#"):
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
			out[k] = v
		break
	return out
