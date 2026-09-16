extends Control
## V130 food therapy — 1–3 cards + optional lifestyle_cue → settle path=food.

var _bowl_flow: HFlowContainer
var _count: Label
var _status: Label
var _cue: String = ""
var _show_combo: bool = true
var _cue_btns: Dictionary = {}


func _ready() -> void:
	if AudioHub:
		AudioHub.enter_clinic()
	_build()
	GameFlow.locale_changed.connect(_refresh)
	_refresh()


func _icon(fid: String) -> Texture2D:
	var path := "res://ui/food/icons/%s.png" % fid
	if ResourceLoader.exists(path):
		return load(path)
	return null


func _build() -> void:
	var paper := ColorRect.new()
	paper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	paper.color = UiKit.PAPER
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(paper)
	if ResourceLoader.exists("res://ui/food/food-tray-ui.png"):
		var art := TextureRect.new()
		art.texture = load("res://ui/food/food-tray-ui.png")
		art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art.modulate = Color(1, 1, 1, 0.35)
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
	var back := UiKit.make_button("FOOD_EXIT", false)
	if back.text == "FOOD_EXIT":
		back.text = "回处治"
	back.pressed.connect(func() -> void:
		GameFlow.open_treatment()
		get_tree().change_scene_to_file("res://scenes/clinic.tscn")
	)
	top.add_child(back)
	top.add_child(UiKit.ink_label(tr("FOOD_TITLE"), 22))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(sp)
	top.add_child(UiKit.locale_bar())
	root.add_child(top)
	root.add_child(UiKit.ink_label(tr("FOOD_SUBTITLE"), 13, UiKit.INK_MUTED))
	root.add_child(UiKit.ink_label(tr("FOOD_HINT"), 13, UiKit.INK_MUTED))
	root.add_child(UiKit.ink_label(tr("FOOD_STOCK_TEACH"), 12, UiKit.INK_MUTED))
	var mentor := tr("MENTOR_FOOD")
	var mwho := "苏问舟"
	if CaseDB and CaseDB.has_method("mentor_name"):
		var mn: String = CaseDB.mentor_name()
		if mn != "":
			mwho = mn
	if mentor != "MENTOR_FOOD" and mentor != "":
		root.add_child(UiKit.ink_label("%s：%s" % [mwho, mentor], 13, UiKit.SEAL))
	else:
		root.add_child(UiKit.ink_label("%s：先养胃气。" % mwho, 13, UiKit.SEAL))
	var mid := HBoxContainer.new()
	mid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mid.add_theme_constant_override("separation", 16)
	root.add_child(mid)
	# Pool
	var pool := VBoxContainer.new()
	pool.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.add_child(pool)
	pool.add_child(UiKit.ink_label(tr("FOOD_ENTER"), 16, UiKit.INK_MUTED))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	pool.add_child(grid)
	for row in CaseDB.pack.get("food_items", []):
		if typeof(row) != TYPE_DICTIONARY:
			continue
		var fid := str(row.get("id", ""))
		var b := Button.new()
		b.custom_minimum_size = Vector2(140, 72)
		UiKit.style_button(b, false)
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 6)
		hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var tex := _icon(fid)
		if tex:
			var trc := TextureRect.new()
			trc.texture = tex
			trc.custom_minimum_size = Vector2(40, 40)
			trc.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			trc.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			trc.mouse_filter = Control.MOUSE_FILTER_IGNORE
			hb.add_child(trc)
		var lab := UiKit.ink_label(CaseDB.food_name(fid), 13)
		lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hb.add_child(lab)
		b.add_child(hb)
		b.pressed.connect(_make_add(fid))
		grid.add_child(b)
	# Bowl
	var bowl_wrap := VBoxContainer.new()
	bowl_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.add_child(bowl_wrap)
	bowl_wrap.add_child(UiKit.ink_label(tr("FOOD_BOWL"), 16, UiKit.INK_MUTED))
	var bowl := Panel.new()
	bowl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bowl.custom_minimum_size = Vector2(0, 200)
	bowl.add_theme_stylebox_override("panel", UiKit.paper_style(Color(0.86, 0.80, 0.68, 0.2), UiKit.SEAL, 16))
	bowl_wrap.add_child(bowl)
	_bowl_flow = HFlowContainer.new()
	_bowl_flow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bowl_flow.offset_left = 16
	_bowl_flow.offset_right = -16
	_bowl_flow.offset_top = 16
	_bowl_flow.offset_bottom = -16
	_bowl_flow.add_theme_constant_override("h_separation", 8)
	_bowl_flow.add_theme_constant_override("v_separation", 8)
	bowl.add_child(_bowl_flow)
	_count = UiKit.ink_label("", 14)
	bowl_wrap.add_child(_count)
	# Combo hints
	var combo_row := HBoxContainer.new()
	root.add_child(combo_row)
	var toggle := UiKit.make_button("FOOD_COMBO_TOGGLE", false)
	toggle.pressed.connect(func() -> void:
		_show_combo = not _show_combo
		_refresh()
	)
	combo_row.add_child(toggle)
	var combo_box := VBoxContainer.new()
	combo_box.name = "ComboBox"
	root.add_child(combo_box)
	# Lifestyle cues
	root.add_child(UiKit.ink_label(tr("FOOD_CUE_TITLE"), 14, UiKit.INK_MUTED))
	var cues := HFlowContainer.new()
	cues.add_theme_constant_override("h_separation", 8)
	cues.add_theme_constant_override("v_separation", 6)
	root.add_child(cues)
	var skip := UiKit.make_button("FOOD_CUE_SKIP", false)
	skip.pressed.connect(func() -> void:
		_cue = ""
		GameFlow.set_lifestyle_cue("")
		_refresh()
	)
	cues.add_child(skip)
	_cue_btns[""] = skip
	for cue_id in ["less_worry", "rest_wind", "no_late_lunch"]:
		var key := "FOOD_CUE_" + cue_id.to_upper()
		var cb := UiKit.make_button(key, true)
		if cb.text == key:
			match cue_id:
				"less_worry":
					cb.text = "少思虑"
				"rest_wind":
					cb.text = "避风歇息"
				_:
					cb.text = "勿过午不食硬扛"
		cb.pressed.connect(_make_cue(cue_id))
		cues.add_child(cb)
		_cue_btns[cue_id] = cb
	_status = UiKit.ink_label(tr("FOOD_SETTLE_HINT"), 13, UiKit.INK_MUTED)
	root.add_child(_status)
	var bot := HBoxContainer.new()
	bot.alignment = BoxContainer.ALIGNMENT_END
	var submit := UiKit.make_button("FOOD_SUBMIT", true)
	if submit.text == "FOOD_SUBMIT":
		submit.text = "进病程"
	submit.custom_minimum_size = Vector2(160, 44)
	submit.pressed.connect(_submit)
	bot.add_child(submit)
	root.add_child(bot)
	root.add_child(UiKit.ink_label(tr("BOOT_DISCLAIMER_FOOTER") if tr("BOOT_DISCLAIMER_FOOTER") != "BOOT_DISCLAIMER_FOOTER" else tr("DISCLAIMER"), 11, UiKit.INK_MUTED))


func _make_add(fid: String) -> Callable:
	return func() -> void:
		if GameFlow.food_tray.size() >= 3:
			_status.text = tr("FOOD_BOWL_FULL")
			return
		if AudioHub:
			AudioHub.play_ui_ink()
		GameFlow.add_food(fid)
		_refresh()


func _make_cue(cid: String) -> Callable:
	return func() -> void:
		_cue = cid
		GameFlow.set_lifestyle_cue(cid)
		_refresh()


func _remove(fid: String) -> void:
	GameFlow.remove_food(fid)
	_refresh()


func _submit() -> void:
	if not GameFlow.can_confirm_food():
		_status.text = tr("FOOD_NEED_CARD")
		return
	if AudioHub:
		AudioHub.play_one("stamp-ok")
	GameFlow.confirm_food()
	# Stay on clinic score dock
	get_tree().change_scene_to_file("res://scenes/clinic.tscn")


func _refresh() -> void:
	for c in _bowl_flow.get_children():
		c.queue_free()
	if GameFlow.food_tray.is_empty():
		_bowl_flow.add_child(UiKit.ink_label(tr("FOOD_BOWL_EMPTY"), 14, UiKit.INK_MUTED))
	else:
		for fid in GameFlow.food_tray:
			var chip := Button.new()
			chip.text = CaseDB.food_name(str(fid))
			UiKit.style_button(chip, true)
			chip.pressed.connect(_make_remove(str(fid)))
			_bowl_flow.add_child(chip)
	_count.text = "%s · %d/3" % [tr("FOOD_BOWL"), GameFlow.food_tray.size()]
	_cue = GameFlow.lifestyle_cue
	for cid in _cue_btns.keys():
		var b: Button = _cue_btns[cid]
		UiKit.style_button(b, str(cid) == _cue or (cid == "" and _cue == ""))
	var combo := find_child("ComboBox", true, false) as VBoxContainer
	if combo:
		for c in combo.get_children():
			c.queue_free()
		if _show_combo:
			combo.add_child(UiKit.ink_label(tr("FOOD_COMBO_HINT_TITLE"), 12, UiKit.INK_MUTED))
			combo.add_child(UiKit.ink_label(tr("FOOD_COMBO_ZAOLIAN"), 12))
			combo.add_child(UiKit.ink_label(tr("FOOD_COMBO_JIANGZHOU"), 12))
			combo.add_child(UiKit.ink_label(tr("FOOD_COMBO_SHANZAO"), 12))


func _make_remove(fid: String) -> Callable:
	return func() -> void:
		_remove(fid)
