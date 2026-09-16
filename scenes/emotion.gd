extends Control
## V132 emotion counsel — listen → 1–2 cards → optional close → settle path=emotion.

var _beat: String = "listen"
var _listen_id: String = ""
var _listen_match: String = ""
var _close_id: String = ""
var _status: Label
var _body: VBoxContainer
var _script: Dictionary = {}
var _card_btns: Dictionary = {}
var _listen_btns: Dictionary = {}
var _close_btns: Dictionary = {}


func _ready() -> void:
	if AudioHub:
		AudioHub.enter_clinic()
	_script = _load_script()
	_build()
	GameFlow.locale_changed.connect(_on_locale)
	_refresh_body()


func _on_locale() -> void:
	_refresh_body()


func _load_script() -> Dictionary:
	var path := "res://patients/emotion_script.json"
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var data = JSON.parse_string(f.get_as_text())
	return data if typeof(data) == TYPE_DICTIONARY else {}


func _soft_tex(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	var res = ResourceLoader.load(path)
	if res is Texture2D:
		return res
	# Fallback: decode via Image (handles odd imports / mislabeled files)
	var abs_path := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(path):
		var img := Image.new()
		var err := img.load(abs_path)
		if err == OK:
			return ImageTexture.create_from_image(img)
	return null


func _icon(cid: String) -> Texture2D:
	return _soft_tex("res://ui/emotion/icons/%s.png" % cid)


func _loc_dict(d: Variant, fallback: String = "") -> String:
	if typeof(d) != TYPE_DICTIONARY:
		return str(d) if str(d) != "" else fallback
	var loc := "zh"
	if GameFlow and GameFlow.has_method("loc"):
		loc = GameFlow.loc()
	for k in [loc, "zh", "en", "ja"]:
		var v := str(d.get(k, "")).strip_edges()
		if v != "":
			return v
	return fallback


func _tr_or(key: String, zh_fallback: String) -> String:
	var t := tr(key)
	if t == key or t == "":
		return zh_fallback
	return t


func _build() -> void:
	var paper := ColorRect.new()
	paper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	paper.color = UiKit.PAPER
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(paper)
	var bg := _soft_tex("res://ui/emotion/counsel-ui.png")
	if bg:
		var art := TextureRect.new()
		art.texture = bg
		art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art.modulate = Color(1, 1, 1, 0.32)
		add_child(art)
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 20
	root.offset_right = -20
	root.offset_top = 12
	root.offset_bottom = -12
	root.add_theme_constant_override("separation", 8)
	add_child(root)
	var top := HBoxContainer.new()
	var back := UiKit.make_button("EMOTION_EXIT", false)
	if back.text == "EMOTION_EXIT":
		back.text = "回处治"
	back.pressed.connect(func() -> void:
		GameFlow.open_treatment()
		get_tree().change_scene_to_file("res://scenes/clinic.tscn")
	)
	top.add_child(back)
	top.add_child(UiKit.ink_label(_tr_or("EMOTION_TITLE", "情志疏导"), 22))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(sp)
	# Portrait (清荷)
	var pid := GameFlow.current_patient_id if GameFlow else ""
	if pid == "":
		pid = "char_clerk"
	var por: Texture2D = null
	if ClassDB.class_exists("CharacterArt") or true:
		por = CharacterArt.load_portrait(pid)
	if por:
		var pv := TextureRect.new()
		pv.texture = por
		pv.custom_minimum_size = Vector2(48, 64)
		pv.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pv.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		pv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		top.add_child(pv)
	top.add_child(UiKit.locale_bar())
	root.add_child(top)
	root.add_child(UiKit.ink_label(_tr_or("EMOTION_SUBTITLE", "听、映、缓。不是说教开药。"), 13, UiKit.INK_MUTED))
	root.add_child(UiKit.ink_label(_tr_or("EMOTION_HINT", "情志也是病。先贴着她的话走。"), 13, UiKit.INK_MUTED))
	var mentor := tr("MENTOR_EMOTION_1")
	var mwho := "苏问舟"
	if CaseDB and CaseDB.has_method("mentor_name"):
		var mn: String = CaseDB.mentor_name()
		if mn != "":
			mwho = mn
	if mentor == "MENTOR_EMOTION_1" or mentor == "":
		mentor = "先听完。再动口。"
	root.add_child(UiKit.ink_label("%s：%s" % [mwho, mentor], 13, UiKit.SEAL))
	# Qinghe line from official emotion_script.json (prefer i18n key)
	var qh := tr("COUNSEL_QINGHE_2")
	if qh == "COUNSEL_QINGHE_2" or qh == "":
		qh = _qinghe_line(1, "案上墨未干，她却说睡不实。")
	root.add_child(UiKit.ink_label(qh, 13, UiKit.INK_MUTED))
	_body = VBoxContainer.new()
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", 8)
	root.add_child(_body)
	_status = UiKit.ink_label(_tr_or("EMOTION_SETTLE_HINT", "疏、缓、温。不是心理处方。"), 13, UiKit.INK_MUTED)
	root.add_child(_status)
	var bot := HBoxContainer.new()
	bot.alignment = BoxContainer.ALIGNMENT_END
	var prev := UiKit.make_button("EMOTION_BACK_BEAT", false)
	if prev.text == "EMOTION_BACK_BEAT":
		prev.text = "上一步"
	prev.pressed.connect(_prev_beat)
	bot.add_child(prev)
	var next := UiKit.make_button("COUNSEL_SUBMIT", true)
	if next.text == "COUNSEL_SUBMIT":
		next.text = "进病程"
	next.custom_minimum_size = Vector2(160, 44)
	next.name = "NextBtn"
	next.pressed.connect(_next_or_submit)
	bot.add_child(next)
	root.add_child(bot)
	var foot := tr("BOOT_DISCLAIMER_FOOTER")
	if foot == "BOOT_DISCLAIMER_FOOTER":
		foot = tr("DISCLAIMER")
	root.add_child(UiKit.ink_label(foot if foot != "DISCLAIMER" else "文化体验，不能替代医疗。", 11, UiKit.INK_MUTED))



func _qinghe_line(idx: int, fallback: String) -> String:
	var block: Variant = _script.get("qinghe_lines", {})
	if typeof(block) != TYPE_DICTIONARY:
		return fallback
	var loc := "zh"
	if GameFlow and GameFlow.has_method("loc"):
		loc = GameFlow.loc()
	for k in [loc, "zh", "en", "ja"]:
		var arr: Variant = block.get(k, [])
		if typeof(arr) == TYPE_ARRAY and arr.size() > idx:
			var s := str(arr[idx]).strip_edges()
			if s != "":
				return s
	return fallback


func _listen_options() -> Array:
	var arr: Variant = _script.get("listen_options", [])
	if typeof(arr) == TYPE_ARRAY and not arr.is_empty():
		return arr
	# Fallback from i18n keys
	return [
		{"id": "listen_desk_night", "anchor_match": true, "label_key": "COUNSEL_LISTEN_1"},
		{"id": "listen_flank", "anchor_match": false, "label_key": "COUNSEL_LISTEN_2"},
		{"id": "listen_cheer_up", "anchor_match": false, "kind": "bad", "label_key": "COUNSEL_LISTEN_3"},
	]


func _close_cues() -> Array:
	var arr: Variant = _script.get("close_cues", [])
	if typeof(arr) == TYPE_ARRAY and not arr.is_empty():
		return arr
	return [
		{"id": "sleep_early", "label_key": "COUNSEL_CLOSE_SLEEP"},
		{"id": "walk_corridor", "label_key": "COUNSEL_CLOSE_WALK"},
		{"id": "no_rush_work", "label_key": "COUNSEL_CLOSE_WIND"},
	]


func _card_pool() -> Array:
	var rules: Dictionary = CaseDB.pack.get("emotion_counsel_rules", {}) if CaseDB else {}
	var beats: Array = rules.get("beats", [])
	for b in beats:
		if typeof(b) == TYPE_DICTIONARY and str(b.get("id", "")) == "cards":
			var pool: Variant = b.get("pool", [])
			if typeof(pool) == TYPE_ARRAY and not pool.is_empty():
				return pool
	var cards: Array = []
	for row in CaseDB.pack.get("counsel_cards", []) if CaseDB else []:
		if typeof(row) == TYPE_DICTIONARY:
			cards.append(str(row.get("id", "")))
	if cards.is_empty():
		return ["walk_ease", "less_desk", "vent_rest", "warm_calm", "no_scold", "no_harsh_tonify"]
	return cards


func _refresh_body() -> void:
	for c in _body.get_children():
		c.queue_free()
	_card_btns.clear()
	_listen_btns.clear()
	_close_btns.clear()
	match _beat:
		"listen":
			_fill_listen()
		"cards":
			_fill_cards()
		"close":
			_fill_close()
	var next := find_child("NextBtn", true, false) as Button
	if next:
		match _beat:
			"listen":
				next.text = _tr_or("COUNSEL_BEAT_CARDS", "下一步·疏导卡")
			"cards":
				next.text = _tr_or("COUNSEL_BEAT_CLOSE", "下一步·收束")
			_:
				next.text = _tr_or("COUNSEL_SUBMIT", "进病程")


func _fill_listen() -> void:
	_body.add_child(UiKit.ink_label(_tr_or("COUNSEL_BEAT_LISTEN", "倾听"), 16, UiKit.INK_MUTED))
	_body.add_child(UiKit.ink_label(_tr_or("COUNSEL_BEAT_LISTEN_HINT", "选更贴的那句复述。不点破证型名。"), 13, UiKit.INK_MUTED))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	_body.add_child(col)
	for row in _listen_options():
		if typeof(row) != TYPE_DICTIONARY:
			continue
		var lid := str(row.get("id", ""))
		var key := str(row.get("label_key", ""))
		var lab := tr(key) if key != "" else ""
		if lab == key or lab == "":
			lab = _loc_dict(row.get("label", {}), lid)
		var b := Button.new()
		b.text = lab
		b.custom_minimum_size = Vector2(0, 48)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UiKit.style_button(b, lid == _listen_id)
		b.pressed.connect(_make_pick_listen(lid, row))
		col.add_child(b)
		_listen_btns[lid] = b


func _make_pick_listen(lid: String, row: Dictionary) -> Callable:
	return func() -> void:
		_listen_id = lid
		if bool(row.get("anchor_match", false)):
			_listen_match = "anchor"
		else:
			_listen_match = ""
		if AudioHub:
			AudioHub.play_one("ui-paper")
		var fb_key := str(row.get("feedback_key", ""))
		if fb_key != "":
			var fb := tr(fb_key)
			if fb != fb_key:
				_status.text = fb
		for idk in _listen_btns.keys():
			UiKit.style_button(_listen_btns[idk], str(idk) == _listen_id)


func _fill_cards() -> void:
	_body.add_child(UiKit.ink_label(_tr_or("COUNSEL_BEAT_CARDS", "疏导卡"), 16, UiKit.INK_MUTED))
	_body.add_child(UiKit.ink_label(_tr_or("COUNSEL_BEAT_CARDS_HINT", "选 1～2 张。听、缓，不要镇坠。"), 13, UiKit.INK_MUTED))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	_body.add_child(grid)
	for cid in _card_pool():
		cid = str(cid)
		if cid == "":
			continue
		var b := Button.new()
		b.custom_minimum_size = Vector2(150, 78)
		var selected := cid in GameFlow.counsel_tray
		UiKit.style_button(b, selected)
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 6)
		hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var tex := _icon(cid)
		if tex:
			var trc := TextureRect.new()
			trc.texture = tex
			trc.custom_minimum_size = Vector2(40, 40)
			trc.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			trc.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			trc.mouse_filter = Control.MOUSE_FILTER_IGNORE
			hb.add_child(trc)
		var name := CaseDB.counsel_name(cid) if CaseDB and CaseDB.has_method("counsel_name") else cid
		var lab := UiKit.ink_label(name, 13)
		lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hb.add_child(lab)
		b.add_child(hb)
		b.pressed.connect(_make_toggle_card(cid))
		grid.add_child(b)
		_card_btns[cid] = b
	var count := UiKit.ink_label("%s · %d/2" % [_tr_or("COUNSEL_BEAT_CARDS", "疏导卡"), GameFlow.counsel_tray.size()], 14)
	count.name = "CardCount"
	_body.add_child(count)


func _make_toggle_card(cid: String) -> Callable:
	return func() -> void:
		if cid in GameFlow.counsel_tray:
			GameFlow.remove_counsel(cid)
		else:
			if GameFlow.counsel_tray.size() >= 2:
				_status.text = _tr_or("COUNSEL_CARD_MAX", "最多两张。")
				return
			if AudioHub:
				AudioHub.play_one("tea")
			GameFlow.add_counsel(cid)
		_refresh_body()


func _fill_close() -> void:
	_body.add_child(UiKit.ink_label(_tr_or("COUNSEL_BEAT_CLOSE", "收束"), 16, UiKit.INK_MUTED))
	_body.add_child(UiKit.ink_label(_tr_or("COUNSEL_BEAT_CLOSE_HINT", "一句起居约定（可选）。"), 13, UiKit.INK_MUTED))
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 8)
	flow.add_theme_constant_override("v_separation", 6)
	_body.add_child(flow)
	var skip := UiKit.make_button("COUNSEL_CLOSE_SKIP", _close_id == "")
	if skip.text == "COUNSEL_CLOSE_SKIP":
		skip.text = "不另约定"
	skip.pressed.connect(func() -> void:
		_close_id = ""
		GameFlow.set_counsel_close("")
		_refresh_body()
	)
	flow.add_child(skip)
	_close_btns[""] = skip
	for row in _close_cues():
		if typeof(row) != TYPE_DICTIONARY:
			continue
		var cid := str(row.get("id", ""))
		var key := str(row.get("label_key", ""))
		var lab := tr(key) if key != "" else ""
		if lab == key or lab == "":
			lab = _loc_dict(row.get("label", {}), cid)
		var b := UiKit.make_button(key if key != "" else cid, cid == _close_id)
		b.text = lab
		b.pressed.connect(_make_pick_close(cid))
		flow.add_child(b)
		_close_btns[cid] = b
	# Selected cards summary
	var names: Array[String] = []
	for cid in GameFlow.counsel_tray:
		names.append(CaseDB.counsel_name(str(cid)) if CaseDB and CaseDB.has_method("counsel_name") else str(cid))
	_body.add_child(UiKit.ink_label(" · ".join(names) if not names.is_empty() else "", 13, UiKit.INK_MUTED))


func _make_pick_close(cid: String) -> Callable:
	return func() -> void:
		_close_id = cid
		GameFlow.set_counsel_close(cid)
		if AudioHub:
			AudioHub.play_one("ui-paper")
		_refresh_body()


func _prev_beat() -> void:
	match _beat:
		"cards":
			_beat = "listen"
		"close":
			_beat = "cards"
		_:
			GameFlow.open_treatment()
			get_tree().change_scene_to_file("res://scenes/clinic.tscn")
			return
	_refresh_body()


func _next_or_submit() -> void:
	match _beat:
		"listen":
			if _listen_id == "":
				_status.text = _tr_or("COUNSEL_BEAT_LISTEN_HINT", "请先选一句复述。")
				return
			_beat = "cards"
			_refresh_body()
		"cards":
			if not GameFlow.can_confirm_emotion_cards():
				_status.text = _tr_or("COUNSEL_CARD_NEED", "至少选一张疏导卡。")
				return
			_beat = "close"
			_refresh_body()
		_:
			_submit()


func _submit() -> void:
	if not GameFlow.can_confirm_emotion():
		_status.text = _tr_or("COUNSEL_CARD_NEED", "至少选一张疏导卡。")
		return
	if AudioHub:
		AudioHub.play_one("stamp-ok")
	GameFlow.confirm_emotion({
		"listen_id": _listen_id,
		"listen_match": _listen_match,
		"close_id": _close_id,
	})
	get_tree().change_scene_to_file("res://scenes/clinic.tscn")
