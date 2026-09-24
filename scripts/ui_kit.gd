extends Node
## Ink-wash UI helpers. Paper, ink, CJK system font.

const PAPER := Color(0.93, 0.9, 0.82, 1)
const PAPER_DARK := Color(0.88, 0.84, 0.74, 1)
## V139 boot chrome: a step warmer than PAPER / PAPER_DARK (apricot, not cold gray).
const PAPER_WARM := Color(0.95, 0.88, 0.74, 1)
const PAPER_WARM_DEEP := Color(0.92, 0.84, 0.70, 1)
const INK := Color(0.16, 0.14, 0.12, 1)
const INK_MUTED := Color(0.35, 0.3, 0.24, 1)
const SEAL := Color(0.55, 0.18, 0.16, 1)
const WASH := Color(0.22, 0.2, 0.18, 0.12)
const LINE := Color(0.2, 0.18, 0.15, 0.55)
## Soft umber edge for boot chrome. Not hard black, not cold gray.
const LINE_SOFT := Color(0.45, 0.32, 0.18, 0.55)
## Shared soft corner. Callers that pass an explicit radius (clinic dock 4, etc.) stay put.
const RADIUS_SOFT := 14
const RADIUS_CARD := 16

var font: Font


func _ready() -> void:
	var sf := SystemFont.new()
	sf.font_names = PackedStringArray([
		"Noto Serif CJK SC",
		"Noto Sans CJK SC",
		"Noto Serif CJK JP",
		"Noto Sans CJK JP",
		"Noto Serif CJK TC",
	])
	font = sf


func loc_text(d: Variant, fallback: String = "") -> String:
	if typeof(d) == TYPE_STRING:
		return d
	if typeof(d) != TYPE_DICTIONARY:
		return fallback
	var dict: Dictionary = d
	var loc := TranslationServer.get_locale()
	if loc.begins_with("en"):
		return str(dict.get("en", dict.get("zh", fallback)))
	if loc.begins_with("ja"):
		return str(dict.get("ja", dict.get("zh", fallback)))
	return str(dict.get("zh", fallback))


func apply_font(ctrl: Control, size: int = 16) -> void:
	if font == null:
		return
	ctrl.add_theme_font_override("font", font)
	ctrl.add_theme_font_size_override("font_size", size)


func ink_label(text: String, size: int = 16, color: Color = INK, wrap: bool = true) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", color)
	apply_font(l, size)
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	else:
		l.autowrap_mode = TextServer.AUTOWRAP_OFF
	return l


func paper_style(bg: Color = PAPER, border: Color = LINE, radius: int = RADIUS_SOFT) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(1)
	s.set_corner_radius_all(radius)
	s.corner_detail = 12
	s.anti_aliasing = true
	s.anti_aliasing_size = 1.0
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	return s


func style_button(btn: Button, seal: bool = false) -> void:
	apply_font(btn, 16)
	var normal := paper_style(PAPER_WARM_DEEP if not seal else Color(0.55, 0.22, 0.16, 0.18), LINE_SOFT, RADIUS_SOFT)
	var hover := paper_style(Color(0.94, 0.85, 0.70, 1), Color(0.42, 0.28, 0.16, 0.75), RADIUS_SOFT)
	var pressed := paper_style(Color(0.86, 0.74, 0.58, 1), SEAL, RADIUS_SOFT)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("focus", hover)
	btn.add_theme_stylebox_override("disabled", paper_style(Color(0.90, 0.84, 0.72, 0.7), Color(0.55, 0.42, 0.30, 0.35), RADIUS_SOFT))
	btn.add_theme_color_override("font_color", SEAL if seal else INK)
	btn.add_theme_color_override("font_hover_color", SEAL)
	btn.add_theme_color_override("font_pressed_color", INK)
	btn.add_theme_color_override("font_disabled_color", INK_MUTED)


func style_check(box: CheckBox, size: int = 15) -> void:
	## Warm rounded chip behind a CheckBox. Does not touch the label string.
	apply_font(box, size)
	box.add_theme_color_override("font_color", INK)
	box.add_theme_color_override("font_hover_color", Color(0.32, 0.20, 0.14, 1))
	box.add_theme_color_override("font_pressed_color", INK)
	box.add_theme_color_override("font_hover_pressed_color", Color(0.32, 0.20, 0.14, 1))
	var warm_icon := Color(0.40, 0.26, 0.16, 1)
	box.add_theme_color_override("icon_normal_color", warm_icon)
	box.add_theme_color_override("icon_hover_color", SEAL)
	box.add_theme_color_override("icon_pressed_color", SEAL)
	box.add_theme_color_override("icon_hover_pressed_color", SEAL)
	box.add_theme_color_override("icon_focus_color", warm_icon)
	box.add_theme_color_override("icon_disabled_color", INK_MUTED)
	box.add_theme_constant_override("h_separation", 8)
	var fills := {
		"normal": Color(0.96, 0.90, 0.78, 0.72),
		"hover": Color(0.95, 0.86, 0.70, 0.92),
		"pressed": Color(0.95, 0.86, 0.70, 0.92),
		"hover_pressed": Color(0.95, 0.86, 0.70, 0.92),
		"focus": Color(0.95, 0.86, 0.70, 0.92),
		"disabled": Color(0.93, 0.88, 0.78, 0.45),
	}
	for state in fills:
		var chip := paper_style(fills[state], LINE_SOFT, 12)
		chip.content_margin_left = 6
		chip.content_margin_right = 8
		chip.content_margin_top = 2
		chip.content_margin_bottom = 2
		box.add_theme_stylebox_override(state, chip)


func make_button(key: String, seal: bool = false) -> Button:
	var b := Button.new()
	b.text = tr(key)
	b.set_meta("i18n_key", key)
	style_button(b, seal)
	return b


func refresh_i18n_buttons(root: Node) -> void:
	for n in root.find_children("*", "Button", true, false):
		var b := n as Button
		if b != null and b.has_meta("i18n_key"):
			b.text = tr(str(b.get_meta("i18n_key")))


func locale_bar() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var tag := ink_label(tr("SETTINGS_LANGUAGE"), 14, INK_MUTED)
	tag.set_meta("i18n_key", "SETTINGS_LANGUAGE")
	row.add_child(tag)
	for pair in [["zh", "LANG_ZH"], ["en", "LANG_EN"], ["ja", "LANG_JA"]]:
		var b := make_button(pair[1], false)
		b.pressed.connect(func() -> void:
			GameFlow.set_locale(pair[0])
		)
		row.add_child(b)
	return row


func nature_ink(nature: String) -> Color:
	match nature:
		"hot":
			return Color(0.5, 0.16, 0.14, 1)
		"warm":
			return Color(0.44, 0.28, 0.16, 1)
		"slightly_warm":
			return Color(0.4, 0.32, 0.2, 1)
		"neutral":
			return Color(0.3, 0.28, 0.24, 1)
		"cool":
			return Color(0.28, 0.32, 0.34, 1)
		"slightly_cold":
			return Color(0.24, 0.3, 0.38, 1)
		"cold":
			return Color(0.2, 0.28, 0.4, 1)
		_:
			return INK


## V137 settings chrome helpers (keys: SETTINGS-SAVE-KEYS.md)

func tr_or(key: String, fallback: String = "") -> String:
	var t := tr(key)
	if t == key or t == "":
		return fallback if fallback != "" else key
	return t


func store_title_text() -> String:
	return tr_or("STORE_TITLE", tr_or("GAME_TITLE", "墨问岐黄"))


func make_settings_gear_button() -> Button:
	var b := Button.new()
	b.name = "SettingsGear"
	b.set_meta("i18n_key", "SETTINGS_TITLE")
	b.tooltip_text = tr_or("SETTINGS_TITLE", "设置")
	b.focus_mode = Control.FOCUS_NONE
	var gear_path := "res://ui/chrome/settings_gear_64.png"
	if not ResourceLoader.exists(gear_path):
		gear_path = "res://ui/chrome/settings_gear.png"
	if ResourceLoader.exists(gear_path):
		b.text = ""
		b.icon = load(gear_path) as Texture2D
		b.expand_icon = true
		b.custom_minimum_size = Vector2(40, 40)
		b.add_theme_constant_override("icon_max_width", 32)
		style_button(b, false)
	else:
		b.text = tr_or("SETTINGS_TITLE", "设置")
		style_button(b, true)
	return b


func force_scroll_bottom(scroll: ScrollContainer) -> void:
	if scroll == null or not is_instance_valid(scroll):
		return
	var bar := scroll.get_v_scroll_bar()
	if bar:
		# Godot Range: usable top is max_value - page.
		var limit := int(maxf(0.0, bar.max_value - bar.page))
		scroll.scroll_vertical = limit
	else:
		scroll.scroll_vertical = 1 << 30


func build_settings_body(on_saved: Callable = Callable(), on_loaded: Callable = Callable(), on_close: Callable = Callable()) -> Control:
	## Returns a paper panel with language + 3 slots save/load. Session chrome only.
	var root := Panel.new()
	root.name = "SettingsPanel"
	root.custom_minimum_size = Vector2(360, 320)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_theme_stylebox_override("panel", paper_style(PAPER_WARM, LINE_SOFT, RADIUS_SOFT))
	# settings_panel.png is a text mock — do not layer under live controls (double glyphs).
	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.offset_left = 16
	col.offset_right = -16
	col.offset_top = 12
	col.offset_bottom = -12
	col.add_theme_constant_override("separation", 8)
	root.add_child(col)
	var head := HBoxContainer.new()
	head.add_child(ink_label(tr_or("SETTINGS_TITLE", "设置"), 18, SEAL, false))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(sp)
	var close_b := make_button("SETTINGS_CLOSE", false)
	if close_b.text == "SETTINGS_CLOSE":
		close_b.text = tr_or("SETTINGS_CLOSE", "关闭")
	close_b.pressed.connect(func() -> void:
		if on_close.is_valid():
			on_close.call()
	)
	head.add_child(close_b)
	col.add_child(head)
	col.add_child(ink_label(tr_or("SETTINGS_HINT", ""), 12, INK_MUTED))
	col.add_child(ink_label(tr_or("SETTINGS_LANGUAGE", "语言"), 14, INK_MUTED))
	var lang_row := HBoxContainer.new()
	lang_row.add_theme_constant_override("separation", 8)
	col.add_child(lang_row)
	for pair in [["zh", "LANG_ZH"], ["en", "LANG_EN"], ["ja", "LANG_JA"]]:
		var lb := make_button(pair[1], false)
		lb.pressed.connect(func() -> void:
			GameFlow.set_locale(pair[0])
		)
		lang_row.add_child(lb)
	col.add_child(ink_label(tr_or("SETTINGS_SECTION_SAVE", "存读档"), 14, INK_MUTED))
	col.add_child(ink_label(tr_or("SAVE_SLOT_HINT", ""), 12, INK_MUTED))
	var slot_state := {"n": Save.active_slot}
	var slot_row := HBoxContainer.new()
	slot_row.add_theme_constant_override("separation", 6)
	col.add_child(slot_row)
	var slot_btns: Array = []
	var pick_slot := func(n: int) -> void:
		slot_state["n"] = n
		for x in slot_btns:
			style_button(x as Button, int((x as Button).get_meta("slot_i")) == int(slot_state["n"]))
	for i in Save.SLOT_COUNT:
		var lab := tr_or("SAVE_SLOT", "档位 {n}").replace("{n}", str(i + 1))
		var sb := Button.new()
		sb.text = lab
		sb.set_meta("slot_i", i)
		style_button(sb, i == Save.active_slot)
		sb.pressed.connect(pick_slot.bind(i))
		slot_btns.append(sb)
		slot_row.add_child(sb)
	var io_row := HBoxContainer.new()
	io_row.add_theme_constant_override("separation", 8)
	col.add_child(io_row)
	var save_b := make_button("SAVE_SAVE", true)
	if save_b.text == "SAVE_SAVE":
		save_b.text = tr_or("SAVE_SAVE", "存档")
	save_b.pressed.connect(func() -> void:
		var n: int = int(slot_state["n"])
		Save.save_to_slot(n)
		if on_saved.is_valid():
			on_saved.call(tr_or("SAVE_SAVED", "已记下。"))
	)
	io_row.add_child(save_b)
	var load_b := make_button("SAVE_LOAD", false)
	if load_b.text == "SAVE_LOAD":
		load_b.text = tr_or("SAVE_LOAD", "读档")
	load_b.pressed.connect(func() -> void:
		var n: int = int(slot_state["n"])
		Save.apply_slot(n)
		GameFlow.locale_changed.emit()
		if on_loaded.is_valid():
			on_loaded.call(tr_or("SAVE_LOADED", "已读入。"))
	)
	io_row.add_child(load_b)
	return root
