extends Control
## V129 阁楼夜读 — CAM_LOFT; 3 codex pages; insight unlocks theory nodes.

var _page_id: String = ""
var _status: Label
var _body: Label
var _title: Label
var _cam_l: Label
var _seal: Label
var _page_btns: Dictionary = {}
var _insight_btn: Button
var _footer: Label


func _ready() -> void:
	if AudioHub:
		AudioHub.enter_clinic()
		if ResourceLoader.exists("res://other-systems/audio/candle.ogg"):
			AudioHub.play_one("candle")
	_build()
	if GameFlow:
		GameFlow.locale_changed.connect(_refresh)
	_refresh()


func _build() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.22, 0.18, 0.16, 1)
	add_child(bg)
	var art_path := ""
	for cand in ["res://ui/loft/CAM_LOFT.png", "res://ui/loft/loft-bg.png", "res://ui/loft/LOFT_HERO.png", "res://scene-slice/loft/LOFT_HERO.png"]:
		if ResourceLoader.exists(cand):
			art_path = cand
			break
	if art_path != "":
		var art := TextureRect.new()
		art.texture = load(art_path)
		art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art.modulate = Color(1, 1, 1, 0.95)
		add_child(art)
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 28
	root.offset_right = -28
	root.offset_top = 16
	root.offset_bottom = -16
	root.add_theme_constant_override("separation", 8)
	add_child(root)
	var top := HBoxContainer.new()
	top.add_child(UiKit.ink_label(tr("NIGHT_READ_TITLE"), 22))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(sp)
	_cam_l = UiKit.ink_label("CAM_LOFT", 12, UiKit.INK_MUTED)
	top.add_child(_cam_l)
	top.add_child(UiKit.locale_bar())
	var back := UiKit.make_button("NIGHT_READ_EXIT", false)
	if back.text == "NIGHT_READ_EXIT" or back.text == "":
		back.text = "下楼回诊室"
	back.pressed.connect(func() -> void: Codex.leave_loft())
	top.add_child(back)
	root.add_child(top)
	var mentor := Codex.mentor_loft_line(0)
	if mentor != "":
		var who := "苏问舟"
		if CaseDB and CaseDB.has_method("mentor_name"):
			var n: String = CaseDB.mentor_name()
			if n != "":
				who = n
		root.add_child(UiKit.ink_label("%s：%s" % [who, mentor], 14, UiKit.SEAL))
	root.add_child(UiKit.ink_label(tr("NIGHT_READ_HINT"), 13, UiKit.INK_MUTED))
	if Codex.last_enter_was_review:
		root.add_child(UiKit.ink_label(tr("NIGHT_READ_REVIEW_HINT"), 12, UiKit.INK_MUTED))
	else:
		root.add_child(UiKit.ink_label(tr("NIGHT_READ_COST"), 12, UiKit.INK_MUTED))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	root.add_child(row)
	row.add_child(UiKit.ink_label(tr("CODEX_TITLE"), 16))
	_seal = UiKit.ink_label("", 14, UiKit.SEAL)
	row.add_child(_seal)
	if ResourceLoader.exists("res://ui/loft/unlock-shi.png"):
		var shi := TextureRect.new()
		shi.name = "SealShi"
		shi.texture = load("res://ui/loft/unlock-shi.png")
		shi.custom_minimum_size = Vector2(36, 36)
		shi.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		shi.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		shi.visible = false
		row.add_child(shi)
	var page_row := HFlowContainer.new()
	page_row.add_theme_constant_override("h_separation", 8)
	page_row.add_theme_constant_override("v_separation", 6)
	root.add_child(page_row)
	for page in Codex.pages():
		var pid := str(page.get("id", ""))
		var b := Button.new()
		b.text = Codex.page_title(page)
		UiKit.apply_font(b, 13)
		b.pressed.connect(_make_open(pid))
		page_row.add_child(b)
		_page_btns[pid] = b
	var paper := Panel.new()
	paper.size_flags_vertical = Control.SIZE_EXPAND_FILL
	paper.custom_minimum_size = Vector2(0, 280)
	paper.add_theme_stylebox_override("panel", UiKit.paper_style(UiKit.PAPER, UiKit.LINE, 6))
	root.add_child(paper)
	if ResourceLoader.exists("res://ui/loft/codex-page.png"):
		var page_art := TextureRect.new()
		page_art.texture = load("res://ui/loft/codex-page.png")
		page_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		page_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		page_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		page_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		page_art.modulate = Color(1, 1, 1, 0.35)
		paper.add_child(page_art)
	var paper_col := VBoxContainer.new()
	paper_col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	paper_col.offset_left = 18
	paper_col.offset_right = -18
	paper_col.offset_top = 14
	paper_col.offset_bottom = -14
	paper_col.add_theme_constant_override("separation", 10)
	paper.add_child(paper_col)
	_title = UiKit.ink_label(tr("CODEX_COVER"), 18)
	paper_col.add_child(_title)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	paper_col.add_child(scroll)
	_body = UiKit.ink_label(tr("CODEX_EMPTY"), 15)
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_body)
	_status = UiKit.ink_label("", 13, UiKit.INK_MUTED)
	paper_col.add_child(_status)
	var action := HBoxContainer.new()
	action.add_theme_constant_override("separation", 10)
	paper_col.add_child(action)
	_insight_btn = UiKit.make_button("CODEX_INSIGHT", true)
	if _insight_btn.text == "CODEX_INSIGHT" or _insight_btn.text == "":
		_insight_btn.text = "领悟"
	_insight_btn.pressed.connect(_on_insight)
	action.add_child(_insight_btn)
	_footer = UiKit.ink_label(tr("BOOT_DISCLAIMER_FOOTER"), 12, UiKit.INK_MUTED)
	if _footer.text == "BOOT_DISCLAIMER_FOOTER" or _footer.text == "":
		_footer.text = tr("DISCLAIMER")
	root.add_child(_footer)
	# Default open first unread, else first page.
	var open_id := ""
	for page2 in Codex.pages():
		var pid2 := str(page2.get("id", ""))
		if not Codex.is_page_unlocked(pid2):
			open_id = pid2
			break
	if open_id == "" and not Codex.pages().is_empty():
		open_id = str((Codex.pages()[0] as Dictionary).get("id", ""))
	if open_id != "":
		_open_page(open_id)


func _make_open(pid: String) -> Callable:
	return func() -> void:
		_open_page(pid)


func _open_page(pid: String) -> void:
	_page_id = pid
	if AudioHub:
		if ResourceLoader.exists("res://other-systems/audio/page-flip.ogg"):
			AudioHub.play_one("page-flip")
		else:
			AudioHub.play_ui_ink()
	_refresh()


func _on_insight() -> void:
	if _page_id == "":
		return
	var r: Dictionary = Codex.unlock_page(_page_id)
	if not bool(r.get("ok", false)):
		return
	if AudioHub:
		if ResourceLoader.exists("res://other-systems/audio/stamp-ok.ogg"):
			AudioHub.play_one("stamp-ok")
		else:
			AudioHub.play_chime()
	var theory := str(r.get("theory", ""))
	var name_key := ""
	match theory:
		"theory.hanre_xushi":
			name_key = "THEORY_HANRE_XUSHI"
		"theory.tenq_song":
			name_key = "THEORY_TENQ_SONG"
		"theory.pulse_names":
			name_key = "THEORY_PULSE_NAMES"
	var nm := tr(name_key) if name_key != "" else theory
	if nm == name_key:
		nm = theory
	var msg := tr("CODEX_INSIGHT_OK")
	if msg == "CODEX_INSIGHT_OK" or msg == "":
		msg = "记下了。"
	var unlock_msg := tr("THEORY_UNLOCKED")
	if unlock_msg == "THEORY_UNLOCKED" or unlock_msg == "":
		unlock_msg = "节点已开：{name}"
	_status.text = "%s  %s" % [msg, unlock_msg.replace("{name}", nm)]
	_refresh_page_buttons()
	_show_seal(true)
	_insight_btn.text = tr("NIGHT_READ_REVIEW") if Codex.is_page_unlocked(_page_id) else tr("CODEX_INSIGHT")


func _show_seal(on: bool) -> void:
	var shi := get_node_or_null("SealShi")
	# SealShi is nested under dynamic tree; search
	if shi == null:
		shi = find_child("SealShi", true, false)
	if shi:
		shi.visible = on
	if on:
		_seal.text = "「%s」" % tr("CODEX_SEAL")
		if _seal.text.find("CODEX_SEAL") >= 0:
			_seal.text = "「识」"
	else:
		_seal.text = ""


func _refresh_page_buttons() -> void:
	for pid in _page_btns.keys():
		var b: Button = _page_btns[pid]
		var page := Codex.page_by_id(str(pid))
		var mark := "✓ " if Codex.is_page_unlocked(str(pid)) else ""
		b.text = mark + Codex.page_title(page)


func _refresh() -> void:
	_cam_l.text = "CAM_LOFT"
	_footer.text = tr("BOOT_DISCLAIMER_FOOTER")
	if _footer.text == "BOOT_DISCLAIMER_FOOTER" or _footer.text == "":
		_footer.text = tr("DISCLAIMER")
	_refresh_page_buttons()
	if _page_id == "":
		_title.text = tr("CODEX_COVER")
		_body.text = tr("CODEX_EMPTY")
		_insight_btn.disabled = true
		return
	var page := Codex.page_by_id(_page_id)
	_title.text = Codex.page_title(page)
	_body.text = Codex.page_body(page)
	_insight_btn.disabled = false
	if Codex.is_page_unlocked(_page_id):
		_insight_btn.text = tr("NIGHT_READ_REVIEW")
		if _insight_btn.text == "NIGHT_READ_REVIEW":
			_insight_btn.text = "复习（不耗夜格）"
		_show_seal(true)
		_status.text = tr("CODEX_UNLOCKED")
	else:
		_insight_btn.text = tr("CODEX_INSIGHT")
		if _insight_btn.text == "CODEX_INSIGHT":
			_insight_btn.text = "领悟"
		_show_seal(false)
		_status.text = tr("CODEX_LOCKED")
