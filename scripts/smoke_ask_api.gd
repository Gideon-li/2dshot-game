extends Node
## Headless Helix ask smoke as 赵阿福. Prints only API_OK / API_FALLBACK.
## Never prints secrets, response body, or key material.

func _ready() -> void:
	var q := QwenClient.new()
	add_child(q)
	var has_key := not q._read_api_key().is_empty()
	print("has_key=", has_key)
	var porter := CaseDB.patient_by_id("char_porter")
	if porter.is_empty():
		porter = CaseDB.patient_by_id("fenghan_biao")
	var case_data := CaseDB.case_for_patient("char_porter")
	if case_data.is_empty():
		case_data = CaseDB.case_for_patient("fenghan_biao")
	var done := false
	q.replied.connect(func(text: String, from_api: bool) -> void:
		done = true
		# Do not print reply body (may echo prompts); only status token.
		if from_api and str(text).strip_edges() != "":
			print("API_OK")
			get_tree().quit(0)
		else:
			print("API_FALLBACK")
			get_tree().quit(0)
	)
	q.ask("夜里睡得怎么样？", porter, case_data)
	# Safety timeout
	await get_tree().create_timer(12.0).timeout
	if not done:
		print("API_FALLBACK")
		get_tree().quit(0)
