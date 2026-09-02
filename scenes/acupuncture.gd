extends Control

const POINT_POS := {
	"fengchi": Vector2(0.50, 0.10),
	"dazhui": Vector2(0.50, 0.18),
	"qimen": Vector2(0.28, 0.32),
	"neiguan": Vector2(0.16, 0.38),
	"lieque": Vector2(0.14, 0.42),
	"hegu": Vector2(0.08, 0.46),
	"quchi": Vector2(0.20, 0.34),
	"shenshu": Vector2(0.50, 0.44),
	"mingmen": Vector2(0.50, 0.50),
	"zusanli": Vector2(0.38, 0.72),
	"yanglingquan": Vector2(0.62, 0.70),
	"sanyinjiao": Vector2(0.38, 0.82),
	"taixi": Vector2(0.36, 0.90),
	"zhaohai": Vector2(0.64, 0.90),
	"taichong": Vector2(0.38, 0.97),
	"yongquan": Vector2(0.62, 0.97),
}

var _selected: Array[String] = []
var _count: Label
var _need: Label
var _body: Control
var _btns: Dictionary = {}


func _ready() -> void:
	_build()
	GameFlow.locale_changed.connect(_refresh)
	_refresh()


func _build() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = UiKit.PAPER
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 20
	root.offset_right = -20
	root.offset_top = 12
	root.offset_bottom = -12
	add_child(root)
	var top := HBoxContainer.new()
	var back := UiKit.make_button("UI_BACK")
	back.pressed.connect(func() -> void: GameFlow.back_to_consult())
	top.add_child(back)
	top.add_child(UiKit.ink_label(tr("ACTION_NEEDLE"), 22))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(sp)
	top.add_child(UiKit.locale_bar())
	root.add_child(top)
	var hint := UiKit.ink_label(tr("TREAT_NEEDLE_HINT"), 14, UiKit.INK_MUTED)
	hint.name = "NeedleHint"
	root.add_child(hint)
	var mid := HBoxContainer.new()
	mid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(mid)
	_body = Control.new()
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.custom_minimum_size = Vector2(320, 480)
	mid.add_child(_body)
	_draw_body()
	var list := VBoxContainer.new()
	list.custom_minimum_size = Vector2(280, 0)
	mid.add_child(list)
	list.add_child(UiKit.ink_label(tr("UI_ACUPOINT"), 16, UiKit.INK_MUTED))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list.add_child(scroll)
	var col := VBoxContainer.new()
	scroll.add_child(col)
	for p in CaseDB.pack.get("acupoints", []):
		var id := str(p["id"])
		var b := Button.new()
		b.text = CaseDB.named_point(p)
		b.set_meta("pid", id)
		UiKit.style_button(b, false)
		b.pressed.connect(func() -> void: _toggle(id))
		_btns[id] = b
		col.add_child(b)
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


func _draw_body() -> void:
	# Ink silhouette: head, torso, arms, legs as ColorRects.
	var cx := 0.5
	_add_part(Rect2(cx - 0.06, 0.02, 0.12, 0.10), Color(0.28, 0.24, 0.2, 0.7)) # head
	_add_part(Rect2(cx - 0.09, 0.13, 0.18, 0.34), Color(0.32, 0.28, 0.22, 0.55)) # torso
	_add_part(Rect2(0.22, 0.16, 0.16, 0.08), Color(0.3, 0.26, 0.22, 0.5)) # L arm
	_add_part(Rect2(0.62, 0.16, 0.16, 0.08), Color(0.3, 0.26, 0.22, 0.5)) # R arm
	_add_part(Rect2(0.14, 0.22, 0.10, 0.22), Color(0.3, 0.26, 0.22, 0.45))
	_add_part(Rect2(0.12, 0.42, 0.10, 0.08), Color(0.3, 0.26, 0.22, 0.45)) # hand
	_add_part(Rect2(cx - 0.09, 0.48, 0.07, 0.42), Color(0.3, 0.26, 0.22, 0.5))
	_add_part(Rect2(cx + 0.02, 0.48, 0.07, 0.42), Color(0.3, 0.26, 0.22, 0.5))
	for id in POINT_POS.keys():
		var b := Button.new()
		b.name = "pt_" + id
		b.custom_minimum_size = Vector2(22, 22)
		b.text = ""
		b.tooltip_text = CaseDB.point_name(id)
		UiKit.style_button(b, false)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.93, 0.9, 0.82, 1)
		sb.border_color = UiKit.INK
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(11)
		b.add_theme_stylebox_override("normal", sb)
		var pid := str(id)
		b.pressed.connect(func() -> void: _toggle(pid))
		_body.add_child(b)
		_btns[id + "_dot"] = b
	_body.resized.connect(_layout_dots)
	call_deferred("_layout_dots")


func _add_part(norm: Rect2, color: Color) -> void:
	var r := ColorRect.new()
	r.color = color
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.set_meta("norm", norm)
	_body.add_child(r)


func _layout_dots() -> void:
	var sz := _body.size
	if sz.x < 8.0:
		return
	for c in _body.get_children():
		if c is ColorRect and c.has_meta("norm"):
			var n: Rect2 = c.get_meta("norm")
			c.position = Vector2(n.position.x * sz.x, n.position.y * sz.y)
			c.size = Vector2(n.size.x * sz.x, n.size.y * sz.y)
		elif c is Button and str(c.name).begins_with("pt_"):
			var id := str(c.name).substr(3)
			var u: Vector2 = POINT_POS.get(id, Vector2(0.5, 0.5))
			c.position = Vector2(u.x * sz.x - 11.0, u.y * sz.y - 11.0)


func _toggle(id: String) -> void:
	if id in _selected:
		_selected.erase(id)
	else:
		if _selected.size() >= 5:
			return
		_selected.append(id)
		AudioHub.play_one("needle")
	_paint()
	_need.visible = false


func _paint() -> void:
	for p in CaseDB.pack.get("acupoints", []):
		var id := str(p["id"])
		if _btns.has(id):
			var b: Button = _btns[id]
			b.modulate = Color(0.85, 0.55, 0.45, 1) if id in _selected else Color.WHITE
			b.text = CaseDB.named_point(p)
		if _btns.has(id + "_dot"):
			var d: Button = _btns[id + "_dot"]
			var sb := StyleBoxFlat.new()
			sb.set_corner_radius_all(11)
			sb.set_border_width_all(2)
			if id in _selected:
				sb.bg_color = UiKit.SEAL
				sb.border_color = UiKit.INK
			else:
				sb.bg_color = UiKit.PAPER
				sb.border_color = UiKit.INK
			d.add_theme_stylebox_override("normal", sb)
			d.add_theme_stylebox_override("hover", sb)
			d.add_theme_stylebox_override("pressed", sb)
	_count.text = tr("NEEDLE_COUNT").format({"n": _selected.size()})


func _refresh() -> void:
	var h := find_child("NeedleHint", true, false) as Label
	if h:
		h.text = tr("TREAT_NEEDLE_HINT")
	_need.text = tr("NEEDLE_NEED")
	_paint()
	UiKit.refresh_i18n_buttons(self)


func _submit() -> void:
	if _selected.size() < 2 or _selected.size() > 5:
		_need.visible = true
		return
	GameFlow.settle("acupuncture", _selected.duplicate())
