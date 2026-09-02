extends Node
## Ink-wash UI helpers. Paper, ink, CJK system font.

const PAPER := Color(0.93, 0.9, 0.82, 1)
const PAPER_DARK := Color(0.88, 0.84, 0.74, 1)
const INK := Color(0.16, 0.14, 0.12, 1)
const INK_MUTED := Color(0.35, 0.3, 0.24, 1)
const SEAL := Color(0.55, 0.18, 0.16, 1)
const WASH := Color(0.22, 0.2, 0.18, 0.12)
const LINE := Color(0.2, 0.18, 0.15, 0.55)

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


func ink_label(text: String, size: int = 16, color: Color = INK) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", color)
	apply_font(l, size)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


func paper_style(bg: Color = PAPER, border: Color = LINE, radius: int = 4) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(1)
	s.set_corner_radius_all(radius)
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	return s


func style_button(btn: Button, seal: bool = false) -> void:
	apply_font(btn, 16)
	var normal := paper_style(PAPER_DARK if not seal else Color(0.55, 0.18, 0.16, 0.12), LINE)
	var hover := paper_style(Color(0.84, 0.8, 0.7, 1), INK)
	var pressed := paper_style(Color(0.78, 0.72, 0.62, 1), SEAL)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("focus", hover)
	btn.add_theme_stylebox_override("disabled", paper_style(Color(0.86, 0.82, 0.74, 0.7), Color(0.5, 0.46, 0.4, 0.4)))
	btn.add_theme_color_override("font_color", SEAL if seal else INK)
	btn.add_theme_color_override("font_hover_color", SEAL)
	btn.add_theme_color_override("font_pressed_color", INK)
	btn.add_theme_color_override("font_disabled_color", INK_MUTED)


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
