extends Control

var _name_l: Label
var _id_l: Label
var _persona_l: Label
var _hint: Label
var _stage: Control
var _exam_btns: Dictionary = {}
var _qwen: QwenClient
var _chat: VBoxContainer
var _ask_edit: LineEdit
var _pulse_panel: Control
var _mentor_l: Label


func _ready() -> void:
	_qwen = QwenClient.new()
	add_child(_qwen)
	_qwen.replied.connect(_on_reply)
	_build()
	GameFlow.locale_changed.connect(_refresh)
	_refresh()
	if GameFlow.exam_focus != "":
		_show_exam(GameFlow.exam_focus)
	else:
		_fill_seated()


func _build() -> void:
	var paper := ColorRect.new()
	paper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	paper.color = UiKit.PAPER
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(paper)
	move_child(paper, 0)
	var chrome := get_node_or_null("HudChrome") as TextureRect
	if chrome == null:
		chrome = TextureRect.new()
		chrome.name = "HudChrome"
		chrome.texture = load("res://ui/ui-clinic.png") as Texture2D
		add_child(chrome)
	chrome.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	chrome.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	chrome.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	# Decoration only. Art may include a 师傅 figure — not a character, not clickable.
	chrome.mouse_filter = Control.MOUSE_FILTER_IGNORE
	move_child(chrome, 1)
	var wash := ColorRect.new()
	wash.set_anchors_preset(Control.PRESET_TOP_WIDE)
	wash.offset_bottom = 90
	wash.color = UiKit.WASH
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wash)
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 24
	root.offset_right = -24
	root.offset_top = 12
	root.offset_bottom = -12
	root.add_theme_constant_override("separation", 10)
	add_child(root)
	var top := HBoxContainer.new()
	var back := UiKit.make_button("UI_BACK")
	back.pressed.connect(func() -> void: GameFlow.go_clinic())
	top.add_child(back)
	var p := CaseDB.patient_by_id(GameFlow.current_patient_id)
	_name_l = UiKit.ink_label("", 22)
	top.add_child(_name_l)
	_id_l = UiKit.ink_label("", 16, UiKit.INK_MUTED)
	top.add_child(_id_l)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(sp)
	top.add_child(UiKit.locale_bar())
	root.add_child(top)
	_persona_l = UiKit.ink_label("", 14, UiKit.INK_MUTED)
	root.add_child(_persona_l)
	var exams := HBoxContainer.new()
	exams.add_theme_constant_override("separation", 8)
	root.add_child(exams)
	for pair in [["wang", "EXAM_LOOK"], ["wen_listen", "EXAM_LISTEN"], ["wen_ask", "EXAM_ASK"], ["qie", "EXAM_PULSE"]]:
		var b := UiKit.make_button(pair[1], false)
		b.custom_minimum_size = Vector2(88, 40)
		var eid: String = pair[0]
		b.pressed.connect(func() -> void: _show_exam(eid))
		_exam_btns[eid] = b
		exams.add_child(b)
	var treat_sp := Control.new()
	treat_sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	exams.add_child(treat_sp)
	var formula_b := UiKit.make_button("ACTION_PRESCRIBE", true)
	formula_b.pressed.connect(func() -> void: _try_treat("formula"))
	exams.add_child(formula_b)
	var needle_b := UiKit.make_button("ACTION_NEEDLE", true)
	needle_b.pressed.connect(func() -> void: _try_treat("needle"))
	exams.add_child(needle_b)
	_hint = UiKit.ink_label("", 14, UiKit.INK_MUTED)
	root.add_child(_hint)
	_mentor_l = UiKit.ink_label("", 14, UiKit.SEAL)
	_mentor_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mentor_l.visible = false
	root.add_child(_mentor_l)
	_stage = Panel.new()
	_stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_stage.add_theme_stylebox_override("panel", UiKit.paper_style(UiKit.PAPER_DARK, UiKit.LINE, 4))
	root.add_child(_stage)


func _refresh() -> void:
	var hud := CaseDB.hud_card(GameFlow.current_patient_id)
	_name_l.text = str(hud.get("name", ""))
	_id_l.text = CaseDB.hud_line(GameFlow.current_patient_id)
	if _persona_l:
		_persona_l.text = str(hud.get("personality", ""))
	_paint_exam_buttons()
	_refresh_mentor()
	if GameFlow.exam_focus == "":
		var opening := CaseDB.opening_line(GameFlow.current_patient_id)
		_hint.text = opening if opening != "" else tr("CLINIC_HINT")
	UiKit.refresh_i18n_buttons(self)
	for n in find_children("*", "Label", true, false):
		if n.has_meta("i18n_key"):
			n.text = tr(str(n.get_meta("i18n_key")))


func _paint_exam_buttons() -> void:
	for eid in _exam_btns.keys():
		var b: Button = _exam_btns[eid]
		if bool(GameFlow.exams.get(eid, false)):
			b.modulate = Color(0.92, 0.85, 0.7, 1)
		else:
			b.modulate = Color.WHITE


func _clear_stage() -> void:
	for c in _stage.get_children():
		c.queue_free()
	_chat = null
	_ask_edit = null
	_pulse_panel = null


func _fill_seated() -> void:
	## Sit-down: opening only. No symptom dump, no diagnosis names.
	_clear_stage()
	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.offset_left = 28
	col.offset_right = -28
	col.offset_top = 24
	col.offset_bottom = -24
	col.add_theme_constant_override("separation", 12)
	_stage.add_child(col)
	var opening := CaseDB.opening_line(GameFlow.current_patient_id)
	if opening == "":
		opening = tr("CLINIC_HINT")
	col.add_child(UiKit.ink_label(opening, 20))
	var hud := CaseDB.hud_card(GameFlow.current_patient_id)
	col.add_child(UiKit.ink_label(str(hud.get("personality", "")), 15, UiKit.INK_MUTED))
	var an := CaseDB.apprentice_name()
	if an != "":
		col.add_child(UiKit.ink_label(an, 13, UiKit.INK_MUTED))
	_refresh_mentor()



func _refresh_mentor() -> void:
	if _mentor_l == null:
		return
	# 苏问舟 narration only — never clickable.
	if CaseDB.mentor_is_clickable():
		_mentor_l.visible = false
		return
	var line := CaseDB.mentor_cue_for_visit()
	if line == "":
		_mentor_l.visible = false
		return
	var who := CaseDB.mentor_name()
	if who == "":
		who = "苏问舟"
	_mentor_l.text = "%s：%s" % [who, line]
	_mentor_l.visible = true


func _try_treat(path: String) -> void:
	_refresh_mentor()
	if path == "formula":
		GameFlow.open_formula()
	else:
		GameFlow.open_needling()


func _show_exam(eid: String) -> void:
	AudioHub.play_one("ui-paper")
	GameFlow.mark_exam(eid)
	_paint_exam_buttons()
	_refresh_mentor()
	_clear_stage()
	match eid:
		"wang":
			_hint.text = tr("HINT_LOOK")
			_fill_look()
		"wen_listen":
			_hint.text = tr("HINT_LISTEN")
			_fill_listen()
		"wen_ask":
			_hint.text = tr("HINT_ASK")
			_fill_ask()
		"qie":
			_hint.text = tr("HINT_PULSE")
			_fill_pulse()


func _clue_lines(exam_id: String) -> PackedStringArray:
	var case_data := CaseDB.case_for_patient(GameFlow.current_patient_id)
	var block: Dictionary = case_data.get("clues", {}).get(exam_id, {})
	var loc := TranslationServer.get_locale()
	var key := "zh"
	if loc.begins_with("en"):
		key = "en"
	elif loc.begins_with("ja"):
		key = "ja"
	var out := PackedStringArray()
	for line in block.get(key, block.get("zh", [])):
		out.append(str(line))
	return out


func _fill_look() -> void:
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 20
	row.offset_right = -20
	row.offset_top = 16
	row.offset_bottom = -16
	row.add_theme_constant_override("separation", 24)
	_stage.add_child(row)
	var p := CaseDB.patient_by_id(GameFlow.current_patient_id)
	var ink: Array = p.get("ink", [0.3, 0.28, 0.24])
	var face := VBoxContainer.new()
	face.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(face)
	face.add_child(UiKit.ink_label(tr("UI_FACE"), 16, UiKit.INK_MUTED))
	var fig := ColorRect.new()
	fig.custom_minimum_size = Vector2(0, 180)
	fig.color = Color(ink[0], ink[1], ink[2], 0.9)
	face.add_child(fig)
	var tongue := VBoxContainer.new()
	tongue.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(tongue)
	tongue.add_child(UiKit.ink_label(tr("UI_TONGUE"), 16, UiKit.INK_MUTED))
	var blob := ColorRect.new()
	blob.custom_minimum_size = Vector2(0, 120)
	var case_data := CaseDB.case_for_patient(GameFlow.current_patient_id)
	var cid := str(case_data.get("id", ""))
	if cid == "yinxu_neire":
		blob.color = Color(0.62, 0.28, 0.28, 0.9)
	elif cid == "fenghan_biao":
		blob.color = Color(0.78, 0.7, 0.68, 0.9)
	else:
		blob.color = Color(0.72, 0.5, 0.5, 0.85)
	tongue.add_child(blob)
	var clues := VBoxContainer.new()
	clues.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(clues)
	for line in _clue_lines("wang"):
		clues.add_child(UiKit.ink_label("· " + line, 18))


func _fill_listen() -> void:
	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.offset_left = 28
	col.offset_right = -28
	col.offset_top = 20
	col.offset_bottom = -20
	_stage.add_child(col)
	col.add_child(UiKit.ink_label(tr("UI_VOICE"), 16, UiKit.INK_MUTED))
	var rings := ColorRect.new()
	rings.custom_minimum_size = Vector2(0, 90)
	rings.color = Color(0.22, 0.2, 0.18, 0.18)
	col.add_child(rings)
	for line in _clue_lines("wen_listen"):
		col.add_child(UiKit.ink_label("· " + line, 18))


func _fill_ask() -> void:
	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.offset_left = 16
	col.offset_right = -16
	col.offset_top = 12
	col.offset_bottom = -12
	col.add_theme_constant_override("separation", 8)
	_stage.add_child(col)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(scroll)
	_chat = VBoxContainer.new()
	_chat.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_chat)
	for turn in GameFlow.conversation:
		_append_chat(str(turn.get("q", "")), str(turn.get("a", "")))
	col.add_child(UiKit.ink_label(tr("TENQ_BAR_TITLE"), 13, UiKit.INK_MUTED))
	var tenq := HFlowContainer.new()
	tenq.add_theme_constant_override("h_separation", 6)
	tenq.add_theme_constant_override("v_separation", 6)
	col.add_child(tenq)
	var pack := TenQuestions.load_pack()
	for raw in pack.get("questions", []):
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var q: Dictionary = raw
		var qid := str(q.get("id", ""))
		var song := str(q.get("song", qid))
		var b := Button.new()
		var asked := qid in GameFlow.tenq_asked
		b.text = ("✓" + song) if asked else song
		b.disabled = asked
		UiKit.apply_font(b, 13)
		b.pressed.connect(func() -> void:
			GameFlow.mark_tenq(qid)
			var prompt := TenQuestions.prompt_for(qid, GameFlow.loc())
			if prompt == "":
				prompt = TenQuestions.prompt_for(qid, "zh")
			_send_ask(prompt)
		)
		tenq.add_child(b)
	var row := HBoxContainer.new()
	col.add_child(row)
	_ask_edit = LineEdit.new()
	_ask_edit.placeholder_text = tr("UI_ASK_PLACEHOLDER")
	_ask_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiKit.apply_font(_ask_edit, 16)
	_ask_edit.add_theme_color_override("font_color", UiKit.INK)
	_ask_edit.text_submitted.connect(_send_ask)
	row.add_child(_ask_edit)
	var send := UiKit.make_button("UI_ASK_SEND", true)
	send.pressed.connect(func() -> void: _send_ask(_ask_edit.text))
	row.add_child(send)


func _append_chat(q: String, a: String) -> void:
	if _chat == null:
		return
	if q != "":
		var ql := UiKit.ink_label("▸ " + q, 15, UiKit.SEAL)
		_chat.add_child(ql)
	if a != "":
		var al := UiKit.ink_label(a, 16, UiKit.INK)
		_chat.add_child(al)


func _send_ask(text: String) -> void:
	var q := text.strip_edges()
	if q.is_empty() or _qwen.is_busy():
		return
	if _ask_edit:
		_ask_edit.text = ""
	_append_chat(q, tr("ASK_THINKING"))
	_qwen.ask(q, CaseDB.patient_by_id(GameFlow.current_patient_id), CaseDB.case_for_patient(GameFlow.current_patient_id))
	_pending_q = q


var _pending_q: String = ""


func _on_reply(text: String, _from_api: bool) -> void:
	GameFlow.conversation.append({"q": _pending_q, "a": text})
	if _chat:
		# rebuild last answer
		_clear_stage()
		_fill_ask()


func _fill_pulse() -> void:
	_pulse_panel = preload("res://scenes/pulse.tscn").instantiate()
	_pulse_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_stage.add_child(_pulse_panel)
	if _pulse_panel.has_method("apply_pulse"):
		_pulse_panel.apply_pulse(GameFlow.pulse_for_current())
