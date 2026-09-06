extends Control

var _plate: Panel
var _plate_flow: HFlowContainer
var _count: Label
var _need: Label
var _on_plate: Array[String] = []


func _ready() -> void:
	_build()
	GameFlow.locale_changed.connect(_refresh)
	_refresh()


func _build() -> void:
	var paper := ColorRect.new()
	paper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	paper.color = UiKit.PAPER
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(paper)
	move_child(paper, 0)
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 20
	root.offset_right = -20
	root.offset_top = 12
	root.offset_bottom = -12
	root.add_theme_constant_override("separation", 10)
	add_child(root)
	var top := HBoxContainer.new()
	var back := UiKit.make_button("UI_BACK")
	back.pressed.connect(func() -> void: GameFlow.back_to_consult())
	top.add_child(back)
	top.add_child(UiKit.ink_label(tr("ACTION_PRESCRIBE"), 22))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(sp)
	top.add_child(UiKit.locale_bar())
	root.add_child(top)
	var hint := UiKit.ink_label(tr("TREAT_FORMULA_HINT"), 14, UiKit.INK_MUTED)
	hint.name = "FormulaHint"
	root.add_child(hint)
	var mid := HBoxContainer.new()
	mid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mid.add_theme_constant_override("separation", 16)
	root.add_child(mid)
	var tray_wrap := VBoxContainer.new()
	tray_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tray_wrap.size_flags_stretch_ratio = 1.15
	mid.add_child(tray_wrap)
	tray_wrap.add_child(UiKit.ink_label(tr("UI_CABINET"), 16, UiKit.INK_MUTED))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tray_wrap.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	scroll.add_child(grid)
	for h in CaseDB.pack.get("herbs", []):
		var chip := HerbChip.new()
		chip.setup(str(h["id"]), false)
		chip.chip_clicked.connect(_add_herb)
		grid.add_child(chip)
	var plate_wrap := VBoxContainer.new()
	plate_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.add_child(plate_wrap)
	plate_wrap.add_child(UiKit.ink_label(tr("UI_FORMULA_TRAY"), 16, UiKit.INK_MUTED))
	_plate = PlateDrop.new()
	_plate.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_plate.add_theme_stylebox_override("panel", UiKit.paper_style(Color(0.82, 0.76, 0.64, 0.12), UiKit.SEAL, 16))
	_plate.herb_dropped.connect(_on_drop)
	plate_wrap.add_child(_plate)
	var tray_art := get_node_or_null("TrayArt") as TextureRect
	if tray_art == null:
		tray_art = TextureRect.new()
		tray_art.name = "TrayArt"
		tray_art.texture = load("res://ui/formula-tray.png") as Texture2D
	else:
		remove_child(tray_art)
	tray_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tray_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tray_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	tray_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_plate.add_child(tray_art)
	_plate.move_child(tray_art, 0)
	_plate_flow = HFlowContainer.new()
	_plate_flow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_plate_flow.offset_left = 24
	_plate_flow.offset_right = -24
	_plate_flow.offset_top = 24
	_plate_flow.offset_bottom = -24
	_plate_flow.add_theme_constant_override("h_separation", 8)
	_plate_flow.add_theme_constant_override("v_separation", 8)
	_plate_flow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_plate.add_child(_plate_flow)
	_count = UiKit.ink_label("", 16)
	root.add_child(_count)
	_need = UiKit.ink_label("", 14, UiKit.SEAL)
	_need.visible = false
	root.add_child(_need)
	var bot := HBoxContainer.new()
	bot.alignment = BoxContainer.ALIGNMENT_END
	var submit := UiKit.make_button("ACTION_SUBMIT", true)
	submit.custom_minimum_size = Vector2(160, 44)
	submit.pressed.connect(_submit)
	bot.add_child(submit)
	root.add_child(bot)


func _refresh() -> void:
	var h := find_child("FormulaHint", true, false) as Label
	if h:
		h.text = tr("TREAT_FORMULA_HINT")
	_count.text = tr("FORMULA_COUNT").format({"n": _on_plate.size()})
	_need.text = tr("FORMULA_NEED")
	UiKit.refresh_i18n_buttons(self)


func _add_herb(id: String) -> void:
	if id in _on_plate:
		return
	if _on_plate.size() >= 8:
		return
	# Keep GameFlow tray in sync for fanwei lock when using standalone formula scene.
	if GameFlow.fsm_state != "formula_crafting":
		GameFlow.enter_formula()
	# Mirror plate into GameFlow so can_add_herb sees current tray.
	GameFlow.tray_herbs = _on_plate.duplicate()
	if not GameFlow.can_add_herb(id):
		AudioHub.play_herb_wrong()
		_need.visible = true
		_need.text = GameFlow.last_fanwei_reason if GameFlow.last_fanwei_reason != "" else tr("FANWEI_LOCKED")
		return
	_on_plate.append(id)
	if id not in GameFlow.tray_herbs:
		GameFlow.tray_herbs.append(id)
	AudioHub.play_one("herb-drop")
	_rebuild_plate()


func _on_drop(data: Dictionary) -> void:
	if bool(data.get("from_plate", false)):
		_remove_herb(str(data.get("herb_id", "")))
		return
	_add_herb(str(data.get("herb_id", "")))


func _remove_herb(id: String) -> void:
	_on_plate.erase(id)
	_rebuild_plate()


func _rebuild_plate() -> void:
	for c in _plate_flow.get_children():
		c.queue_free()
	for id in _on_plate:
		var chip := HerbChip.new()
		chip.setup(id, true)
		chip.chip_clicked.connect(_remove_herb)
		_plate_flow.add_child(chip)
	_refresh()
	_need.visible = false


func _submit() -> void:
	if _on_plate.size() < 3 or _on_plate.size() > 8:
		_need.visible = true
		return
	# Incompat lock stub (GameFlow.formula_lock_reason); empty until fanwei pairs land.
	if GameFlow.formula_lock_reason() != "":
		_need.visible = true
		_need.text = GameFlow.formula_lock_reason()
		return
	GameFlow.settle("formula", _on_plate.duplicate())


class PlateDrop extends Panel:
	signal herb_dropped(data: Dictionary)

	func _can_drop_data(_at: Vector2, data: Variant) -> bool:
		return typeof(data) == TYPE_DICTIONARY and data.has("herb_id")

	func _drop_data(_at: Vector2, data: Variant) -> void:
		herb_dropped.emit(data)
