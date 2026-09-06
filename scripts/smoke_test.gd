extends Node
## Headless checks: cases load, both treatment paths score, local ask replies work.
## Does not print secrets or key material.


func _ready() -> void:
	var fails: PackedStringArray = []
	if CaseDB.patients.size() != 3:
		fails.append("expected 3 patients, got %d" % CaseDB.patients.size())
	if CaseDB.cases_by_id.size() != 3:
		fails.append("expected 3 cases")
	if CaseDB.herbs_by_id.size() < 20:
		fails.append("herb tray too small")
	var exams_all := {"wang": true, "wen_listen": true, "wen_ask": true, "qie": true}
	var exams_none := {"wang": false, "wen_listen": false, "wen_ask": false, "qie": false}
	var paths := [
		["char_porter", "formula", ["mahuang", "guizhi", "xingren", "gancao"]],
		["char_porter", "acupuncture", ["fengchi", "hegu", "lieque"]],
		["char_clerk", "formula", ["chaihu", "baishao", "danggui", "baizhu", "fuling", "bohe", "gancao"]],
		["char_clerk", "acupuncture", ["taichong", "qimen", "neiguan"]],
		["char_copyist", "formula", ["shudi", "shanyao", "shanzhuyu", "mudanpi", "zexie", "fuling"]],
		["char_copyist", "acupuncture", ["taixi", "sanyinjiao", "shenshu"]],
	]
	for row in paths:
		var pid := str(row[0])
		var path := str(row[1])
		var ids: Array = row[2]
		var case_data := CaseDB.case_for_patient(pid)
		var r: Dictionary = Scoring.evaluate(case_data, exams_all, path, ids)
		print("score %s %s rank=%s score=%.2f mistreat=%s" % [
			pid, path, str(r.get("rank_id", "")), float(r.get("score", 0.0)), str(r.get("mistreat", false))
		])
		if bool(r.get("mistreat", false)):
			fails.append("%s %s should not mistreat legal path" % [pid, path])
		if float(r.get("score", 0.0)) < 0.55:
			fails.append("%s %s legal path too weak (%.2f)" % [pid, path, float(r.get("score", 0.0))])
		var r2: Dictionary = Scoring.evaluate(case_data, exams_none, path, ids)
		if float(r2.get("process_mult", 1.0)) >= float(r.get("process_mult", 1.0)):
			fails.append("%s missing-exam process should discount" % pid)

	var tq := TenQuestions.load_pack()
	var tq_n := 0
	for q in tq.get("questions", []):
		if typeof(q) == TYPE_DICTIONARY:
			tq_n += 1
	print("ten_questions_count=", tq_n)
	if tq_n != 10:
		fails.append("TenQuestions.load_pack expected 10, got %d" % tq_n)
	var sample: Dictionary = Scoring.evaluate(
		CaseDB.case_for_patient("char_porter"),
		exams_all,
		"formula",
		["mahuang", "guizhi", "xingren", "gancao"]
	)
	for k in ["C_star", "B", "A_prime", "U", "J", "T"]:
		if not sample.has(k):
			fails.append("Scoring.evaluate missing key " + k)
	if abs(float(sample.get("J", -1.0)) - 1.0) > 0.001 or abs(float(sample.get("T", -1.0)) - 1.0) > 0.001:
		fails.append("J/T should default to 1.0")
	print("score_components C_star=%.2f B=%.2f A_prime=%.2f U=%.2f J=%.1f T=%.1f" % [
		float(sample.get("C_star", 0.0)), float(sample.get("B", 0.0)),
		float(sample.get("A_prime", sample.get("A", 0.0))), float(sample.get("U", 0.0)),
		float(sample.get("J", 0.0)), float(sample.get("T", 0.0))
	])

	var mis: Dictionary = Scoring.evaluate(
		CaseDB.case_for_patient("char_porter"),
		exams_all,
		"formula",
		["jinyinhua", "lianqiao", "gancao"]
	)
	if not bool(mis.get("mistreat", false)):
		fails.append("cold herbs on wind-cold should mistreat")
	var q := QwenClient.new()
	add_child(q)
	var porter := CaseDB.patient_by_id("char_porter")
	var c1 := CaseDB.case_for_patient("char_porter")
	var local_a: String = q._template_reply("夜里睡得怎么样？", porter, c1)
	var local_b: String = q._template_reply("风寒束表是不是？", porter, c1)
	print("local_reply_len=", local_a.length(), " dodge_len=", local_b.length())
	if local_a.strip_edges().is_empty():
		fails.append("template reply empty")
	if local_b.find("风寒") >= 0:
		fails.append("template leaked diagnosis name")
	var key_on := not q._read_api_key().is_empty()
	print("api_key_present=", key_on)
	if fails.is_empty():
		print("SMOKE PASS")
		get_tree().quit(0)
	else:
		for f in fails:
			print("FAIL: ", f)
		print("SMOKE FAIL")
		get_tree().quit(1)
