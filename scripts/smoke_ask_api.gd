extends Node
## Headless inquiry provider smoke. Prints API_OK / LOCAL_OK / OFFLINE_FALLBACK.
## Never prints secrets, response body, or key material.

func _ready() -> void:
	var q := QwenClient.new()
	add_child(q)
	print("provider_pref=", q._cfg_provider())
	print("resolved=", q.resolve_provider())
	print("allow_remote=", q.allow_remote())
	print("model_present=", q.model_file_present())
	print("has_key=", not q._read_api_key().is_empty())
	var porter := CaseDB.patient_by_id("char_porter")
	if porter.is_empty():
		porter = CaseDB.patient_by_id("fenghan_biao")
	var case_data := CaseDB.case_for_patient("char_porter")
	if case_data.is_empty():
		case_data = CaseDB.case_for_patient("fenghan_biao")
	var done := false
	q.replied.connect(func(text: String, from_api: bool) -> void:
		done = true
		var status := q.last_status
		if status == "":
			status = "API_OK" if from_api else "OFFLINE_FALLBACK"
		print(status)
		get_tree().quit(0)
	)
	q.ask("夜里睡得怎么样？", porter, case_data)
	await get_tree().create_timer(12.0).timeout
	if not done:
		print("OFFLINE_FALLBACK")
		get_tree().quit(0)
