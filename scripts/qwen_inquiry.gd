extends Node
## Session ask wrapper over QwenClient (local/remote/offline). Never logs key material.

signal reply_ready(text: String, from_api: bool)

var _llm: QwenClient
var _history: Array = []
var _pending_q: String = ""
var _busy := false


func _ready() -> void:
	_llm = QwenClient.new()
	add_child(_llm)
	_llm.replied.connect(_on_replied)


func reset_session() -> void:
	_history.clear()
	_busy = false


func is_busy() -> bool:
	return _busy or (_llm != null and _llm.is_busy())


func has_runtime_key() -> bool:
	return _llm != null and not _llm._read_api_key().is_empty()


func last_status() -> String:
	return _llm.last_status if _llm else ""


func ask(player_text: String) -> void:
	if is_busy():
		return
	var q := player_text.strip_edges()
	if q == "":
		q = "……"
	_pending_q = q
	_busy = true
	_history.append({"role": "user", "content": q})
	var character := CaseDB.patient_by_id(GameFlow.current_patient_id)
	var case_data := CaseDB.case_for_patient(GameFlow.current_patient_id)
	_llm.ask(q, character, case_data)


func _on_replied(text: String, from_api: bool) -> void:
	_busy = false
	if not from_api:
		if not QwenClient.wants_diagnosis_name(_pending_q, CaseDB.case_for_patient(GameFlow.current_patient_id)):
			GameFlow.consume_inquiry_anchor()
	_history.append({"role": "assistant", "content": text})
	if _history.size() > 12:
		_history = _history.slice(_history.size() - 12)
	reply_ready.emit(text, from_api)
