extends Node
## Headless local OpenAI-compat ask. Prints LOCAL_OK / OFFLINE_FALLBACK only.
## Never prints secrets or reply body.

func _ready() -> void:
	OS.set_environment("MOWEN_LLM_PROVIDER", "local")
	if OS.get_environment("MOWEN_LOCAL_BASE_URL").strip_edges() == "":
		OS.set_environment("MOWEN_LOCAL_BASE_URL", "http://127.0.0.1:8765/v1")
	var q := QwenClient.new()
	add_child(q)
	await get_tree().process_frame
	var porter := CaseDB.patient_by_id("char_porter")
	if porter.is_empty():
		porter = CaseDB.patient_by_id("fenghan_biao")
	var case_data := CaseDB.case_for_patient("char_porter")
	if case_data.is_empty():
		case_data = CaseDB.case_for_patient("fenghan_biao")
	var done := false
	q.replied.connect(func(text: String, from_api: bool) -> void:
		done = true
		if from_api and str(text).strip_edges() != "" and q.last_status == "LOCAL_OK":
			print("LOCAL_OK")
			get_tree().quit(0)
		else:
			print("OFFLINE_FALLBACK")
			get_tree().quit(0)
	)
	q.ask("夜里睡得怎么样？", porter, case_data)
	await get_tree().create_timer(4.0).timeout
	if not done:
		print("OFFLINE_FALLBACK")
		get_tree().quit(0)
