extends Control

var _title: Label
var _sub: Label
var _body: Label
var _check: CheckBox
var _enter: Button
var _need: Label
var _footer: Label


func _ready() -> void:
	AudioHub.mute_boot()
	_build()
	GameFlow.locale_changed.connect(_refresh)
	_refresh()


func _build() -> void:
	var bg := $Bg as ColorRect
	if bg:
		bg.color = UiKit.PAPER
	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.offset_left = 80
	col.offset_right = -80
	col.offset_top = 48
	col.offset_bottom = -36
	col.add_theme_constant_override("separation", 16)
	add_child(col)
	var top := HBoxContainer.new()
	top.alignment = BoxContainer.ALIGNMENT_END
	top.add_child(UiKit.locale_bar())
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


func _refresh() -> void:
	_title.text = tr("GAME_TITLE")
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
