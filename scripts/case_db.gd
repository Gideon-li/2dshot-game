extends Node
## slice_logic.json cases + patients/slice_characters.json cards.
## Join is bind_character_id / case_id only. No third case table.

var pack: Dictionary = {}
var characters: Dictionary = {}
var herbs_by_id: Dictionary = {}
var points_by_id: Dictionary = {}
var cases_by_id: Dictionary = {}
var patients: Array = []
var patients_by_id: Dictionary = {}
var apprentice: Dictionary = {}


func _ready() -> void:
	pack = _load_json("res://logic/slice_logic.json")
	characters = _load_json("res://patients/slice_characters.json")
	apprentice = characters.get("apprentice", {})
	patients = []
	for raw in characters.get("patients", []):
		if typeof(raw) == TYPE_DICTIONARY:
			patients.append(raw)
	if patients.is_empty():
		patients = _builtin_patients()
	patients.sort_custom(func(a, b): return int(a.get("seat", 0)) < int(b.get("seat", 0)))
	patients_by_id.clear()
	for p in patients:
		if typeof(p) == TYPE_DICTIONARY:
			var pid := str(p.get("id", ""))
			if pid != "":
				patients_by_id[pid] = p
	for h in pack.get("herbs", []):
		if typeof(h) == TYPE_DICTIONARY:
			herbs_by_id[str(h.get("id", ""))] = h
	for p in pack.get("acupoints", []):
		if typeof(p) == TYPE_DICTIONARY:
			points_by_id[str(p.get("id", ""))] = p
	for c in pack.get("cases", []):
		if typeof(c) == TYPE_DICTIONARY:
			cases_by_id[str(c.get("id", ""))] = c
	_apply_bind_join()


func _apply_bind_join() -> void:
	## Fill case_id from bind_character_id if a card omitted it. Do not invent ids.
	for c in pack.get("cases", []):
		if typeof(c) != TYPE_DICTIONARY:
			continue
		var bind := str(c.get("bind_character_id", ""))
		if bind == "" or not patients_by_id.has(bind):
			continue
		var card: Dictionary = patients_by_id[bind]
		if str(card.get("case_id", "")) == "":
			card["case_id"] = str(c.get("id", ""))


func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed


func patient_by_id(pid: String) -> Dictionary:
	if pid == "":
		return {}
	if patients_by_id.has(pid):
		return patients_by_id[pid]
	var case_data: Dictionary = cases_by_id.get(pid, {})
	var bind := str(case_data.get("bind_character_id", ""))
	if bind != "" and patients_by_id.has(bind):
		return patients_by_id[bind]
	for p in patients:
		if str(p.get("case_id", "")) == pid:
			return p
	return {}


func case_for_patient(pid: String) -> Dictionary:
	var p := patient_by_id(pid)
	if not p.is_empty():
		var cid := str(p.get("case_id", ""))
		if cid != "" and cases_by_id.has(cid):
			return cases_by_id[cid]
		var pid_id := str(p.get("id", ""))
		for c in cases_by_id.values():
			if typeof(c) == TYPE_DICTIONARY and str(c.get("bind_character_id", "")) == pid_id:
				return c
	if cases_by_id.has(pid):
		return cases_by_id[pid]
	for c in cases_by_id.values():
		if typeof(c) == TYPE_DICTIONARY and str(c.get("bind_character_id", "")) == pid:
			return c
	return {}


func character_id_for(pid: String) -> String:
	var p := patient_by_id(pid)
	var cid := str(p.get("id", ""))
	return cid if cid != "" else pid


func inquiry_rules() -> Dictionary:
	return characters.get("inquiry_rules", {})


func inquiry_rules_lines() -> PackedStringArray:
	var block: Dictionary = inquiry_rules()
	var key := _loc_key()
	var arr: Variant = block.get(key, block.get("zh", []))
	var out := PackedStringArray()
	if typeof(arr) == TYPE_ARRAY:
		for x in arr:
			out.append(str(x))
	return out


func hud_card(pid: String) -> Dictionary:
	## Player-facing identity only. Never diagnosis / never_say / formula names.
	var p := patient_by_id(pid)
	return {
		"name": UiKit.loc_text(p.get("name", {}), ""),
		"identity": UiKit.loc_text(p.get("identity", {}), ""),
		"age": str(p.get("age", "")),
		"region": UiKit.loc_text(p.get("region", {}), ""),
		"personality": UiKit.loc_text(p.get("personality", {}), ""),
	}


func hud_line(pid: String) -> String:
	var h := hud_card(pid)
	var bits: PackedStringArray = []
	if str(h.get("identity", "")) != "":
		bits.append(str(h["identity"]))
	if str(h.get("age", "")) != "":
		bits.append(str(h["age"]))
	if str(h.get("region", "")) != "":
		bits.append(str(h["region"]))
	return " · ".join(bits)


func opening_line(pid: String) -> String:
	return UiKit.loc_text(patient_by_id(pid).get("opening", {}), "")


func apprentice_name() -> String:
	return UiKit.loc_text(apprentice.get("name", {}), "")


func herb(id: String) -> Dictionary:
	return herbs_by_id.get(id, {})


func point(id: String) -> Dictionary:
	return points_by_id.get(id, {})


func herb_name(id: String) -> String:
	return UiKit.loc_text(herb(id), id)


func point_name(id: String) -> String:
	var p := point(id)
	if p.is_empty():
		return id
	return UiKit.loc_text(p, id)


func named_herb(h: Dictionary) -> String:
	return UiKit.loc_text(h, str(h.get("id", "")))


func named_point(p: Dictionary) -> String:
	return UiKit.loc_text(p, str(p.get("id", "")))


func _loc_key() -> String:
	var loc := TranslationServer.get_locale()
	if loc.begins_with("en"):
		return "en"
	if loc.begins_with("ja"):
		return "ja"
	return "zh"


func _builtin_patients() -> Array:
	## Last-resort cards if JSON missing. Same ids as slice_characters.json.
	return [
		{
			"id": "char_porter",
			"case_id": "fenghan_biao",
			"age": 34,
			"seat": 0,
			"name": {"zh": "赵阿福", "en": "Zhao Afu", "ja": "趙阿福"},
			"identity": {"zh": "码头脚夫", "en": "Wharf porter", "ja": "波止場の担ぎ手"},
			"region": {"zh": "江南水乡", "en": "Jiangnan canals", "ja": "江南の水郷"},
			"personality": {"zh": "爽快、怕麻烦、话少。", "en": "Blunt, hates fuss, few words.", "ja": "気さく、面倒嫌い、寡黙。"},
			"opening": {"zh": "师傅，我站着说就行。夜里江上风大，今早扛了两趟就不对劲。", "en": "Doc, I can stand. Wind off the river last night — two loads this morning and I was off.", "ja": "先生、立ったままでいい。夜の川風が強くて、今朝二往復したらおかしくなった。"},
			"dodge": {"zh": "那些医书上的叫法我不会。你问身上冷不冷、出不出汗、鼻涕什么色，我还能答。", "en": "I don't know the book names. Ask if I'm cold, if I sweat, what color the snot is — I can answer that.", "ja": "医書の呼び名は知らん。寒いか、汗は出るか、鼻水の色なら答えられる。"},
			"ask_wrappers": {
				"zh": ["怎么说呢，{sym}。别的我也不懂。", "就那点子事——{sym}。", "不瞒你，{sym}。问太细我答不上。"],
				"en": ["How to put it… {sym}. That's all I know.", "Just that — {sym}.", "I'll be straight: {sym}."],
				"ja": ["何というか、{sym}。ほかは分からん。", "そのくらいだ——{sym}。", "正直に言うと、{sym}。"],
			},
			"ink": [0.42, 0.36, 0.3],
		},
		{
			"id": "char_clerk",
			"case_id": "ganyu_qizhi",
			"age": 27,
			"seat": 1,
			"name": {"zh": "沈清荷", "en": "Shen Qinghe", "ja": "沈清荷"},
			"identity": {"zh": "县衙书办", "en": "Yamen clerk", "ja": "県衙の書記"},
			"region": {"zh": "江南县城", "en": "A Jiangnan county seat", "ja": "江南の県城"},
			"personality": {"zh": "体面、含蓄。说话前先叹气。", "en": "Composed, reserved. Sighs first.", "ja": "体裁を気にし、含蓄がある。"},
			"opening": {"zh": "……坐一下就走。不是什么大病，只是近来写字写不下去。", "en": "…I won't stay long. Nothing grave. Lately the writing will not go.", "ja": "……少しだけ。大病ではない。このごろ字が書けない。"},
			"dodge": {"zh": "我不是来对那些名目的。你问胸口闷不闷、叹完气松不松、夜里醒几次，我再说。", "en": "I did not come to match names. Ask if the chest is tight, if a sigh helps, how often I wake — then I will answer.", "ja": "呼び名を合わせに来たのではない。胸が悶えるか、溜息で楽か、夜に何度起きるかなら答える。"},
			"ask_wrappers": {
				"zh": ["……{sym}。说了也像没说。", "近来{sym}。其余不必记。", "叹口气吧。{sym}。"],
				"en": ["…{sym}. Saying it barely helps.", "Lately {sym}.", "A long breath. {sym}."],
				"ja": ["……{sym}。言っても言わないようだ。", "このごろ{sym}。", "溜息が先に出る。{sym}。"],
			},
			"ink": [0.28, 0.3, 0.34],
		},
		{
			"id": "char_copyist",
			"case_id": "yinxu_neire",
			"age": 61,
			"seat": 2,
			"name": {"zh": "周婆婆", "en": "Granny Zhou", "ja": "周ばあさん"},
			"identity": {"zh": "抄经香铺老人", "en": "Incense-shop copyist", "ja": "香舗の写経の老女"},
			"region": {"zh": "内陆小镇", "en": "An inland market town", "ja": "内陸の町"},
			"personality": {"zh": "软声、客气，怕添麻烦。", "en": "Soft-spoken, polite, hates to impose.", "ja": "声が柔らかく、遠慮深い。"},
			"opening": {"zh": "劳您了。人老了，夜里总不安生。坐一坐就走，不耽误你们看别人。", "en": "Sorry to trouble you. At my age the nights will not sit still. A short sit, then I go.", "ja": "お手数を。年のせいか、夜が落ち着かない。少し座ったら帰ります。"},
			"dodge": {"zh": "那些方书上的名字，我叫不上来。您问夜里出不出汗、嘴里干不干、手脚心里热不热就好。", "en": "I cannot name what the books name. Ask about night sweat, a dry mouth, heat in the palms and soles.", "ja": "方書の名は言えません。夜の汗、口の渇き、手足の裏の熱さを問うてください。"},
			"ask_wrappers": {
				"zh": ["劳您问。{sym}。", "人老了，{sym}。不值得大惊小怪。", "说出来不好意思……{sym}。"],
				"en": ["Kind of you to ask. {sym}.", "At my age, {sym}. Nothing to make a fuss of.", "It's a little embarrassing… {sym}."],
				"ja": ["お尋ねくださり。{sym}。", "年のせいか、{sym}。大層なことではない。", "言いづらいのですが……{sym}。"],
			},
			"ink": [0.38, 0.26, 0.24],
		},
	]
