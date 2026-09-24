extends Control

var _title: Label
var _sub: Label
var _body: Label
var _check: CheckBox
var _enter: Button
var _need: Label
var _footer: Label
var _settings_root: Control
var _settings_toast: Label
var _hero: TextureRect


func _ready() -> void:
	AudioHub.mute_boot()
	_build()
	GameFlow.locale_changed.connect(_refresh)
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE):
		if GameFlow.settings_open:
			_set_settings_open(false)
			get_viewport().set_input_as_handled()


func _build() -> void:
	_setup_boot_bg()
	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.offset_left = 80
	col.offset_right = -80
	col.offset_top = 48
	col.offset_bottom = -36
	col.add_theme_constant_override("separation", 16)
	add_child(col)
	# Top row: spacer + settings gear (language lives inside settings; no locale_bar).
	var top := HBoxContainer.new()
	top.alignment = BoxContainer.ALIGNMENT_END
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(sp)
	var gear := UiKit.make_settings_gear_button()
	gear.pressed.connect(func() -> void:
		_set_settings_open(not GameFlow.settings_open)
	)
	top.add_child(gear)
	col.add_child(top)
	_title = UiKit.ink_label("", 48)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_title)
	_sub = UiKit.ink_label("", 22, UiKit.SEAL)
	_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_sub)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 12)
	col.add_child(spacer)
	var card := Panel.new()
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", UiKit.paper_style(UiKit.PAPER_DARK, UiKit.LINE, 6))
	col.add_child(card)
	var inner := VBoxContainer.new()
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inner.offset_left = 24
	inner.offset_right = -24
	inner.offset_top = 20
	inner.offset_bottom = -20
	inner.add_theme_constant_override("separation", 12)
	card.add_child(inner)
	var dt := UiKit.ink_label("", 20, UiKit.SEAL)
	dt.name = "DiscTitle"
	inner.add_child(dt)
	_body = UiKit.ink_label("", 16, UiKit.INK)
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inner.add_child(_body)
	_check = CheckBox.new()
	UiKit.apply_font(_check, 16)
	_check.add_theme_color_override("font_color", UiKit.INK)
	if GameFlow.disclaimer_accepted():
		_check.button_pressed = true
	inner.add_child(_check)
	_need = UiKit.ink_label("", 14, UiKit.SEAL)
	_need.visible = false
	inner.add_child(_need)
	_enter = UiKit.make_button("START_CLINIC", true)
	_enter.custom_minimum_size = Vector2(220, 44)
	_enter.pressed.connect(_on_enter)
	var enter_wrap := HBoxContainer.new()
	enter_wrap.alignment = BoxContainer.ALIGNMENT_CENTER
	enter_wrap.add_child(_enter)
	col.add_child(enter_wrap)
	_footer = UiKit.ink_label("", 13, UiKit.INK_MUTED)
	_footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_footer)
	if has_node("Title"):
		$Title.visible = false
	if has_node("Disclaimer"):
		$Disclaimer.visible = false
	_ensure_settings_overlay()


func _setup_boot_bg() -> void:
	## Light hero: boot_hero.png if present; else L0-paper interim; ColorRect stays as soft base.
	var bg := $Bg as ColorRect
	if bg:
		bg.color = UiKit.PAPER
		bg.z_index = -2
	var hero_path := "res://ui/chrome/boot_hero.png"
	var hero_alt := "res://ui/boot/boot_hero.png"
	var paper_path := "res://ui/layers/L0-paper.png"
	var tex_path := ""
	if ResourceLoader.exists(hero_path):
		tex_path = hero_path
	elif ResourceLoader.exists(hero_alt):
		tex_path = hero_alt
	elif ResourceLoader.exists(paper_path):
		tex_path = paper_path
	if tex_path == "":
		return
	_hero = TextureRect.new()
	_hero.name = "BootHero"
	_hero.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hero.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_hero.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_hero.texture = load(tex_path) as Texture2D
	_hero.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hero.z_index = -1
	# Soft so UI card stays readable; boot_hero may be stronger later.
	if tex_path == paper_path:
		_hero.modulate = Color(1, 1, 1, 0.85)
	else:
		_hero.modulate = Color(1, 1, 1, 0.92)
	# Insert behind UI (after Bg ColorRect).
	add_child(_hero)
	move_child(_hero, 1 if bg else 0)


func _ensure_settings_overlay() -> void:
	if _settings_root != null and is_instance_valid(_settings_root):
		return
	_settings_root = Control.new()
	_settings_root.name = "SettingsOverlay"
	_settings_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_settings_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_settings_root.visible = false
	_settings_root.z_index = 80
	add_child(_settings_root)
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.12, 0.1, 0.08, 0.35)
	dim.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed:
			_set_settings_open(false)
	)
	_settings_root.add_child(dim)
	var on_saved := func(msg: String) -> void:
		_flash_settings_toast(msg)
	var on_loaded := func(msg: String) -> void:
		_flash_settings_toast(msg)
		_refresh()
	var on_close := func() -> void:
		_set_settings_open(false)
	var body := UiKit.build_settings_body(on_saved, on_loaded, on_close)
	body.set_anchors_preset(Control.PRESET_CENTER)
	body.anchor_left = 0.5
	body.anchor_top = 0.5
	body.anchor_right = 0.5
	body.anchor_bottom = 0.5
	body.offset_left = -180
	body.offset_top = -160
	body.offset_right = 180
	body.offset_bottom = 160
	_settings_root.add_child(body)
	_settings_toast = UiKit.ink_label("", 14, UiKit.SEAL)
	_settings_toast.name = "SettingsToast"
	_settings_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_settings_toast.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_settings_toast.anchor_top = 1.0
	_settings_toast.anchor_bottom = 1.0
	_settings_toast.offset_top = -36
	_settings_toast.offset_bottom = -12
	_settings_toast.offset_left = -160
	_settings_toast.offset_right = 160
	_settings_root.add_child(_settings_toast)


func _set_settings_open(open: bool) -> void:
	GameFlow.settings_open = open
	if _settings_root and is_instance_valid(_settings_root):
		_settings_root.visible = open


func _flash_settings_toast(msg: String) -> void:
	if _settings_toast == null:
		return
	_settings_toast.text = msg


func _refresh() -> void:
	_title.text = UiKit.store_title_text()
	_sub.text = tr("GAME_SUBTITLE")
	var dt := find_child("DiscTitle", true, false) as Label
	if dt:
		dt.text = tr("BOOT_DISCLAIMER_TITLE")
		UiKit.apply_font(dt, 20)
	_body.text = tr("BOOT_DISCLAIMER_BODY")
	_check.text = tr("BOOT_DISCLAIMER_CHECK")
	_enter.text = tr("START_CLINIC")
	_footer.text = tr("BOOT_DISCLAIMER_FOOTER")
	_need.text = tr("BOOT_NEED_CHECK")
	if _settings_root and is_instance_valid(_settings_root):
		_settings_root.visible = GameFlow.settings_open
	UiKit.refresh_i18n_buttons(self)
	var lang := find_children("*", "Label", true, false)
	for n in lang:
		if n.has_meta("i18n_key"):
			n.text = tr(str(n.get_meta("i18n_key")))


func _on_enter() -> void:
	if not _check.button_pressed:
		_need.visible = true
		return
	GameFlow.accept_disclaimer()
	get_tree().change_scene_to_file("res://scenes/clinic.tscn")
