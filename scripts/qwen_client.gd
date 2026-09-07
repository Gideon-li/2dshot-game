class_name QwenClient
extends Node
## Multi-provider patient ask (V122). Alias: InquiryLLM extends this.
## local = llama-server OpenAI-compat; remote = Helix DEV; offline = templates.
## Shipping auto → local then offline (≤2s). Never silently remote. Never logs secrets.

signal replied(text: String, from_api: bool)

const TIMEOUT_SEC := 2.0
const DEFAULT_MODEL := "qwen3.8-flash"
const DEFAULT_REMOTE_MODEL := "qwen3.8-flash"
const DEFAULT_LOCAL_MODEL := "qwen3-4b-instruct-q4_k_m"
const DEFAULT_LOCAL_BASE := "http://127.0.0.1:8080/v1"
const DEFAULT_ENDPOINT := "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions"
const DEFAULT_REMOTE_ENDPOINT := "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions"
const MODEL_USER_PATH := "user://models/qwen3-4b-instruct-q4_k_m.gguf"

var last_status: String = ""
var last_provider: String = ""

var _http: HTTPRequest
var _busy := false
var _pending_character: Dictionary = {}
var _pending_case: Dictionary = {}
var _pending_question: String = ""
var _attempt_provider: String = ""


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
	var provider := resolve_provider()
	_attempt_provider = provider
	last_provider = provider
	if provider == "offline":
		_finish_offline()
		return
	if _http == null:
		_http = HTTPRequest.new()
		_http.timeout = TIMEOUT_SEC
		add_child(_http)
		_http.request_completed.connect(_on_http)
	_busy = true
	var endpoint := ""
	var model := ""
	var key := ""
	if provider == "local":
		endpoint = _normalize_chat_url(_local_base_url())
		model = _local_model()
		key = _local_api_key()
	else:
		key = _read_api_key()
		if key.is_empty():
			_busy = false
			_finish_offline()
			return
		endpoint = _read_remote_endpoint()
		model = _read_remote_model()
	var body := {
		"model": model,
		"temperature": 0.9,
		"max_tokens": 180,
		"messages": [
			{"role": "system", "content": make_system_prompt(character, case_data)},
			{"role": "user", "content": question},
		],
	}
	if provider == "remote":
		body["enable_thinking"] = false
	var headers := PackedStringArray(["Content-Type: application/json"])
	if key != "":
		headers.append("Authorization: Bearer " + key)
	_http.timeout = TIMEOUT_SEC
	var err := _http.request(endpoint, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_busy = false
		_finish_offline()


func resolve_provider() -> String:
	var pref := _cfg_provider()
	if pref == "offline":
		return "offline"
	if pref == "local":
		return "local"
	if pref == "remote":
		return "remote" if allow_remote() else "offline"
	# auto: try local (fast fail → offline). Never silent remote on player builds.
	return "local"


func allow_remote() -> bool:
	if OS.has_feature("player_build") and not OS.has_feature("editor"):
		return false
	if str(_llm_cfg().get("allow_remote", "")).to_lower() in ["1", "true", "yes"]:
		return true
	if OS.get_environment("MOWEN_ALLOW_REMOTE").strip_edges().to_lower() in ["1", "true", "yes"]:
		return true
	var bag := _read_secrets_bag()
	if str(bag.get("MOWEN_ALLOW_REMOTE", "")).strip_edges().to_lower() in ["1", "true", "yes"]:
		return true
	if OS.has_feature("editor") and not _read_api_key().is_empty():
		return true
	return false


func model_file_present() -> bool:
	return FileAccess.file_exists(MODEL_USER_PATH)


func status_i18n_key() -> String:
	if last_status == "LOCAL_OK":
		return "LLM_STATUS_LOCAL_OK"
	if last_status == "API_OK":
		return "LLM_STATUS_REMOTE_DEV"
	if last_status == "OFFLINE_FALLBACK":
		return "LLM_STATUS_OFFLINE"
	if model_file_present():
		return "LLM_MODEL_READY"
	return "LLM_MODEL_MISSING"


func provider_i18n_key(provider: String = "") -> String:
	var p := provider if provider != "" else resolve_provider()
	if p == "local":
		return "LLM_PROVIDER_LOCAL"
	if p == "remote":
		return "LLM_PROVIDER_REMOTE"
	if p == "offline":
		return "LLM_PROVIDER_OFFLINE"
	return "LLM_PROVIDER_AUTO"



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


func _on_http(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_busy = false
	if result != HTTPRequest.RESULT_SUCCESS or code < 200 or code >= 300:
		_finish_offline()
		return
	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	if typeof(parsed) != TYPE_DICTIONARY:
		_finish_offline()
		return
	var choices: Variant = parsed.get("choices", [])
	if typeof(choices) != TYPE_ARRAY or (choices as Array).is_empty():
		_finish_offline()
		return
	var msg: Variant = (choices as Array)[0]
	if typeof(msg) != TYPE_DICTIONARY:
		_finish_offline()
		return
	var content: Variant = msg.get("message", {}).get("content", "")
	var text := str(content).strip_edges()
	if text.is_empty():
		_finish_offline()
		return
	text = strip_never_say(text, _pending_case)
	if _attempt_provider == "local":
		last_status = "LOCAL_OK"
	else:
		last_status = "API_OK"
	last_provider = _attempt_provider
	replied.emit(text, true)


func _finish_offline() -> void:
	_busy = false
	last_status = "OFFLINE_FALLBACK"
	last_provider = "offline"
	var text := template_reply(_pending_question, _pending_character, _pending_case)
	replied.emit(text, false)


func _cfg_provider() -> String:
	var env := OS.get_environment("MOWEN_LLM_PROVIDER").strip_edges().to_lower()
	if env in ["local", "remote", "offline", "auto"]:
		return env
	var p := str(_llm_cfg().get("provider", "auto")).strip_edges().to_lower()
	if p in ["local", "remote", "offline", "auto"]:
		return p
	return "auto"


func _local_base_url() -> String:
	var env := OS.get_environment("MOWEN_LOCAL_BASE_URL").strip_edges()
	if env != "":
		return env
	var u := str(_llm_cfg().get("local_base_url", DEFAULT_LOCAL_BASE)).strip_edges()
	return u if u != "" else DEFAULT_LOCAL_BASE


func _local_model() -> String:
	var env := OS.get_environment("MOWEN_LOCAL_MODEL").strip_edges()
	if env != "":
		return env
	var m := str(_llm_cfg().get("local_model", DEFAULT_LOCAL_MODEL)).strip_edges()
	return m if m != "" else DEFAULT_LOCAL_MODEL


func _local_api_key() -> String:
	var env := OS.get_environment("MOWEN_LOCAL_API_KEY").strip_edges()
	if env != "":
		return env
	var k := str(_llm_cfg().get("local_api_key", "local")).strip_edges()
	return k


func _llm_cfg() -> Dictionary:
	var out := {}
	var path := "user://llm.cfg"
	if not FileAccess.file_exists(path):
		return out
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return out
	var section := ""
	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if line.is_empty() or line.begins_with("#") or line.begins_with(";"):
			continue
		if line.begins_with("[") and line.ends_with("]"):
			section = line.substr(1, line.length() - 2).strip_edges().to_lower()
			continue
		if section != "" and section != "llm":
			continue
		var eq := line.find("=")
		if eq <= 0:
			continue
		out[line.substr(0, eq).strip_edges()] = line.substr(eq + 1).strip_edges()
	return out


func _read_api_key() -> String:
	for k in ["QWEN_API_KEY", "DASHSCOPE_API_KEY", "KEY"]:
		var env := OS.get_environment(k).strip_edges()
		if env != "":
			return env
	var bag := _read_secrets_bag()
	for k2 in ["QWEN_API_KEY", "DASHSCOPE_API_KEY", "KEY"]:
		var v := str(bag.get(k2, "")).strip_edges()
		if v != "":
			return v
	return ""


func _read_secrets_bag() -> Dictionary:
	var out := {}
	var paths: PackedStringArray = [
		ProjectSettings.globalize_path("res://secrets.env"),
		"user://secrets.env",
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
			out[k] = v
		break
	return out


func _read_remote_model() -> String:
	var bag := _read_secrets_bag()
	var m := str(bag.get("QWEN_MODEL", bag.get("MODEL", DEFAULT_REMOTE_MODEL))).strip_edges()
	return m if m != "" else DEFAULT_REMOTE_MODEL


func _read_model() -> String:
	return _read_remote_model()


func _read_remote_endpoint() -> String:
	var bag := _read_secrets_bag()
	var u := str(bag.get("QWEN_BASE_URL", bag.get("OPENAI_BASE_URL", ""))).strip_edges()
	if u == "":
		return DEFAULT_REMOTE_ENDPOINT
	return _normalize_chat_url(u)


func _read_endpoint() -> String:
	return _read_remote_endpoint()


func _normalize_chat_url(url: String) -> String:
	var u := url.strip_edges()
	if u.ends_with("/chat/completions"):
		return u
	if u.ends_with("/v1") or u.ends_with("/compatible-mode/v1"):
		return u + "/chat/completions"
	return u.rstrip("/") + "/chat/completions"
