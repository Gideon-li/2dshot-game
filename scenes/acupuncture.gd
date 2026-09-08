extends Control
## V125 acupuncture intro: body-map picking + teach lock (hegu needle / zusanli moxa).

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

const SHOW_SIDE_LIST := false

var _selected: Array[String] = []
var _count: Label
var _need: Label
var _feedback: Label
var _mentor: Label
var _body: Control
var _btns: Dictionary = {}
var _list_root: Control
var _tech_panel: VBoxContainer
var _deqi_bar: ProgressBar
var _deqi_marker: ColorRect
var _moxa_glow: Control
var _ink_blob: Control
var _active_point: String = ""
var _deqi_tries: int = 0
var _deqi_phase: float = 0.0
var _deqi_running: bool = false
var _moxa_zhuang: int = 5
var _mode: String = "" # "" | "deqi" | "moxa"


func _ready() -> void:
	_build()
	GameFlow.locale_changed.connect(_refresh)
	if GameFlow.fsm_state != "needling" and GameFlow.current_patient_id != "":
		GameFlow.enter_needling()
	_refresh()


func _process(delta: float) -> void:
	if not _deqi_running or _deqi_bar == null:
		return
	_deqi_phase += delta * 1.35
	var t := 0.5 + 0.5 * sin(_deqi_phase)
	_deqi_bar.value = t * 100.0
	if _deqi_marker:
		var w := maxf(_deqi_bar.size.x - 12.0, 8.0)
		_deqi_marker.position.x = 6.0 + t * w - 6.0


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
	var back := UiKit.make_button("ACU_EXIT")
	if tr("ACU_EXIT") == "ACU_EXIT":
		back.text = tr("UI_BACK")
	back.pressed.connect(_leave)
	top.add_child(back)
	top.add_child(UiKit.ink_label(tr("ACU_TITLE"), 22))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(sp)
	top.add_child(UiKit.locale_bar())
	root.add_child(top)

	var hint := UiKit.ink_label(tr("ACU_BODY_HINT"), 14, UiKit.INK_MUTED)
	hint.name = "NeedleHint"
	root.add_child(hint)

	_mentor = UiKit.ink_label(tr("MENTOR_ACU_1"), 13, UiKit.SEAL)
	_mentor.name = "MentorAcu"
	root.add_child(_mentor)

	var teach := UiKit.ink_label(tr("ACU_TEACH_ONLY"), 13, UiKit.INK_MUTED)
	teach.name = "TeachOnly"
	root.add_child(teach)

	var mid := HBoxContainer.new()
	mid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(mid)

	_body = Control.new()
	_body.name = "BodyMap"
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.custom_minimum_size = Vector2(320, 480)
	_body.mouse_filter = Control.MOUSE_FILTER_STOP
	_body.gui_input.connect(_on_body_input)
	mid.add_child(_body)
	_draw_body()

	_list_root = VBoxContainer.new()
	_list_root.custom_minimum_size = Vector2(280, 0)
	_list_root.visible = SHOW_SIDE_LIST
	mid.add_child(_list_root)
	_list_root.add_child(UiKit.ink_label(tr("UI_ACUPOINT"), 16, UiKit.INK_MUTED))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list_root.add_child(scroll)
	var col := VBoxContainer.new()
	scroll.add_child(col)
	for p in CaseDB.pack.get("acupoints", []):
		var id := str(p["id"])
		var b := Button.new()
		b.text = CaseDB.named_point(p)
		b.set_meta("pid", id)
		UiKit.style_button(b, false)
		b.disabled = not GameFlow.acu_teach_unlocked(id)
		if b.disabled:
			b.modulate = Color(0.7, 0.7, 0.7, 0.55)
			b.tooltip_text = tr("ACU_TEACH_LOCK")
		else:
			b.pressed.connect(func() -> void: _begin_point(id, "center"))
		_btns[id] = b
		col.add_child(b)

	_tech_panel = VBoxContainer.new()
	_tech_panel.name = "TechPanel"
	_tech_panel.visible = false
	root.add_child(_tech_panel)

	_feedback = UiKit.ink_label("", 14, UiKit.SEAL)
	_feedback.name = "Feedback"
	root.add_child(_feedback)

	_count = UiKit.ink_label("", 16)
	root.add_child(_count)
	_need = UiKit.ink_label("", 14, UiKit.SEAL)
	_need.visible = false
	root.add_child(_need)

	var disc := UiKit.ink_label(tr("ACU_DISCLAIMER_HINT"), 12, UiKit.INK_MUTED)
	disc.name = "AcuDisclaimer"
	root.add_child(disc)
	var foot := UiKit.ink_label(tr("STORE_NOT_MEDICAL"), 11, UiKit.INK_MUTED)
	foot.name = "AcuFooter"
	root.add_child(foot)

	var bot := HBoxContainer.new()
	bot.alignment = BoxContainer.ALIGNMENT_END
	var submit := UiKit.make_button("ACU_SUBMIT", true)
	if tr("ACU_SUBMIT") == "ACU_SUBMIT":
		submit.text = tr("ACTION_SUBMIT")
	submit.custom_minimum_size = Vector2(160, 44)
	submit.pressed.connect(_submit)
	bot.add_child(submit)
	root.add_child(bot)


func _draw_body() -> void:
	# V125 art: prefer ui/acu/body-front.png; fallback silhouette parts.
	var bg_path := "res://ui/acu/body-front.png"
	if ResourceLoader.exists(bg_path):
		var art := TextureRect.new()
		art.name = "BodyArt"
		art.texture = load(bg_path)
		art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_body.add_child(art)
	else:
		var cx := 0.5
		_add_part(Rect2(cx - 0.06, 0.02, 0.12, 0.10), Color(0.28, 0.24, 0.2, 0.7))
		_add_part(Rect2(cx - 0.09, 0.13, 0.18, 0.34), Color(0.32, 0.28, 0.22, 0.55))
		_add_part(Rect2(0.22, 0.16, 0.16, 0.08), Color(0.3, 0.26, 0.22, 0.5))
		_add_part(Rect2(0.62, 0.16, 0.16, 0.08), Color(0.3, 0.26, 0.22, 0.5))
		_add_part(Rect2(0.14, 0.22, 0.10, 0.22), Color(0.3, 0.26, 0.22, 0.45))
		_add_part(Rect2(0.12, 0.42, 0.10, 0.08), Color(0.3, 0.26, 0.22, 0.45))
		_add_part(Rect2(cx - 0.09, 0.48, 0.07, 0.42), Color(0.3, 0.26, 0.22, 0.5))
		_add_part(Rect2(cx + 0.02, 0.48, 0.07, 0.42), Color(0.3, 0.26, 0.22, 0.5))

	_ink_blob = TextureRect.new() if ResourceLoader.exists("res://ui/acu/deqi-ink-halo.png") else ColorRect.new()
	_ink_blob.name = "DeqiInk"
	_ink_blob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ink_blob.visible = false
	if _ink_blob is TextureRect:
		(_ink_blob as TextureRect).texture = load("res://ui/acu/deqi-ink-halo.png")
		(_ink_blob as TextureRect).expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		(_ink_blob as TextureRect).stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	else:
		(_ink_blob as ColorRect).color = Color(0.12, 0.12, 0.14, 0.0)
	_body.add_child(_ink_blob)

	_moxa_glow = TextureRect.new() if ResourceLoader.exists("res://ui/acu/moxa-glow.png") else ColorRect.new()
	_moxa_glow.name = "MoxaGlow"
	_moxa_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_moxa_glow.visible = false
	if _moxa_glow is TextureRect:
		(_moxa_glow as TextureRect).texture = load("res://ui/acu/moxa-glow.png")
		(_moxa_glow as TextureRect).expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		(_moxa_glow as TextureRect).stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	else:
		(_moxa_glow as ColorRect).color = Color(0.85, 0.35, 0.2, 0.0)
	_body.add_child(_moxa_glow)

	for id in POINT_POS.keys():
		var dot := ColorRect.new()
		dot.name = "pt_" + id
		dot.custom_minimum_size = Vector2(14, 14)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dot.set_meta("pid", id)
		_body.add_child(dot)
		_btns[id + "_dot"] = dot
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
		elif c is ColorRect and str(c.name).begins_with("pt_"):
			var id := str(c.name).substr(3)
			var u: Vector2 = POINT_POS.get(id, Vector2(0.5, 0.5))
			c.position = Vector2(u.x * sz.x - 7.0, u.y * sz.y - 7.0)
			c.size = Vector2(14, 14)
	_paint()


func _on_body_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if _mode != "":
		return
	var sz := _body.size
	if sz.x < 8.0 or sz.y < 8.0:
		return
	var local: Vector2 = event.position
	var norm := Vector2(local.x / sz.x, local.y / sz.y)
	_try_pick(norm)


func _try_pick(norm: Vector2) -> void:
	var best_id := ""
	var best_d := 999.0
	var best_zone := "miss"
	for id in POINT_POS.keys():
		var pos: Vector2 = POINT_POS[id]
		var zone := GameFlow.acu_hit_zone_at(pos, norm, str(id))
		if zone == "miss":
			continue
		var d := norm.distance_to(pos)
		if d < best_d:
			best_d = d
			best_id = str(id)
			best_zone = zone
	if best_id == "":
		_set_feedback(tr("ACU_MISS_JING"))
		return
	if not GameFlow.acu_teach_unlocked(best_id):
		_set_feedback(tr("ACU_TEACH_LOCK"))
		_paint()
		return
	_begin_point(best_id, best_zone)


func _begin_point(id: String, zone: String) -> void:
	if id in GameFlow.acu_practiced:
		_set_feedback(tr("ACU_COUNT").format({"n": GameFlow.acu_practiced.size()}))
		_paint()
		return
	if GameFlow.acu_practiced.size() >= 3:
		_set_feedback(tr("ACU_COUNT_HINT"))
		return
	GameFlow.acu_mark_known(id)
	if zone == "center":
		_set_feedback(tr("ACU_HIT_CENTER"))
	else:
		_set_feedback(tr("ACU_MISS_NEAR"))
	_active_point = id
	var method := GameFlow.acu_point_method(id)
	if method == "moxa":
		_open_moxa(id)
	else:
		AudioHub.play_one("needle")
		_open_deqi(id)
	_paint()


func _clear_tech() -> void:
	_deqi_running = false
	_mode = ""
	_active_point = ""
	for c in _tech_panel.get_children():
		c.queue_free()
	_tech_panel.visible = false
	_deqi_bar = null
	_deqi_marker = null


func _open_deqi(id: String) -> void:
	_clear_tech()
	_mode = "deqi"
	_deqi_tries = 0
	_deqi_phase = 0.0
	_tech_panel.visible = true
	_tech_panel.add_child(UiKit.ink_label(tr("ACU_HEGU_NAME") if id == "hegu" else CaseDB.point_name(id), 16))
	_tech_panel.add_child(UiKit.ink_label(tr("ACU_DEQI_HINT"), 13, UiKit.INK_MUTED))
	var wrap := Control.new()
	wrap.custom_minimum_size = Vector2(0, 28)
	_deqi_bar = ProgressBar.new()
	_deqi_bar.min_value = 0
	_deqi_bar.max_value = 100
	_deqi_bar.value = 50
	_deqi_bar.show_percentage = false
	_deqi_bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wrap.add_child(_deqi_bar)
	# Sweet zone marks (even / ping)
	var z0 := ColorRect.new()
	z0.color = Color(0.2, 0.55, 0.3, 0.35)
	z0.mouse_filter = Control.MOUSE_FILTER_IGNORE
	z0.set_anchors_preset(Control.PRESET_FULL_RECT)
	z0.anchor_left = 0.38
	z0.anchor_right = 0.62
	wrap.add_child(z0)
	_deqi_marker = ColorRect.new()
	_deqi_marker.color = UiKit.SEAL
	_deqi_marker.size = Vector2(12, 22)
	_deqi_marker.position = Vector2(0, 3)
	_deqi_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(_deqi_marker)
	_tech_panel.add_child(wrap)
	var row := HBoxContainer.new()
	var tap := UiKit.make_button("ACU_DEQI", true)
	tap.pressed.connect(_tap_deqi)
	row.add_child(tap)
	var cancel := UiKit.make_button("UI_BACK")
	cancel.pressed.connect(_clear_tech)
	row.add_child(cancel)
	_tech_panel.add_child(row)
	_deqi_running = true
	_mentor.text = tr("MENTOR_ACU_2")


func _tap_deqi() -> void:
	if _mode != "deqi" or _active_point == "":
		return
	var v := _deqi_bar.value if _deqi_bar else 0.0
	var ok := v >= 38.0 and v <= 62.0
	if ok:
		GameFlow.acu_complete_deqi(_active_point, true)
		AudioHub.play_one("deqi")
		_flash_ink(_active_point)
		_set_feedback(tr("ACU_DEQI_OK"))
		if _active_point not in _selected:
			_selected.append(_active_point)
		_clear_tech()
		_paint()
		return
	_deqi_tries += 1
	if _deqi_tries >= 2:
		GameFlow.acu_complete_deqi(_active_point, false)
		_set_feedback(tr("ACU_DEQI_FAIL"))
		_clear_tech()
		_paint()
		return
	_set_feedback(tr("ACU_DEQI_FAIL") + " " + tr("ACU_RETRY"))


func _open_moxa(id: String) -> void:
	_clear_tech()
	_mode = "moxa"
	_moxa_zhuang = 5
	_tech_panel.visible = true
	_tech_panel.add_child(UiKit.ink_label(tr("ACU_ZUSANLI_NAME") if id == "zusanli" else CaseDB.point_name(id), 16))
	_tech_panel.add_child(UiKit.ink_label(tr("ACU_MOXA_HINT"), 13, UiKit.INK_MUTED))
	_tech_panel.add_child(UiKit.ink_label(tr("ACU_MOXA_DEFAULT"), 12, UiKit.INK_MUTED))
	var row := HBoxContainer.new()
	for z in [3, 5, 7]:
		var zi: int = int(z)
		var key := "ACU_MOXA_ZHUANG_%d" % zi
		var b := UiKit.make_button(key, zi == 5)
		b.pressed.connect(_make_zhuang_handler(zi))
		row.add_child(b)
	_tech_panel.add_child(row)
	var row2 := HBoxContainer.new()
	var ok := UiKit.make_button("ACU_MOXA_OK", true)
	ok.pressed.connect(_confirm_moxa)
	row2.add_child(ok)
	var cancel := UiKit.make_button("UI_BACK")
	cancel.pressed.connect(_clear_tech)
	row2.add_child(cancel)
	_tech_panel.add_child(row2)
	_mentor.text = tr("MENTOR_ACU_3")



func _make_zhuang_handler(zi: int) -> Callable:
	return func() -> void:
		_moxa_zhuang = zi
		_set_feedback(tr("ACU_MOXA_ZHUANG") + " · %d" % zi)


func _confirm_moxa() -> void:
	if _mode != "moxa" or _active_point == "":
		return
	if GameFlow.acu_complete_moxa(_active_point, _moxa_zhuang):
		AudioHub.play_one("moxa")
		_flash_moxa(_active_point)
		_set_feedback(tr("ACU_MOXA_OK"))
		if _active_point not in _selected:
			_selected.append(_active_point)
	_clear_tech()
	_paint()


func _flash_ink(id: String) -> void:
	if _ink_blob == null:
		return
	var sz := _body.size
	var u: Vector2 = POINT_POS.get(id, Vector2(0.5, 0.5))
	_ink_blob.visible = true
	_ink_blob.position = Vector2(u.x * sz.x - 28.0, u.y * sz.y - 28.0)
	_ink_blob.size = Vector2(56, 56)
	if _ink_blob is ColorRect:
		(_ink_blob as ColorRect).color = Color(0.12, 0.12, 0.16, 0.55)
		var tw := create_tween()
		tw.tween_property(_ink_blob, "color:a", 0.0, 0.85)
	else:
		_ink_blob.modulate = Color(1, 1, 1, 0.95)
		var tw2 := create_tween()
		tw2.tween_property(_ink_blob, "modulate:a", 0.0, 0.85)


func _flash_moxa(id: String) -> void:
	if _moxa_glow == null:
		return
	var sz := _body.size
	var u: Vector2 = POINT_POS.get(id, Vector2(0.5, 0.5))
	_moxa_glow.visible = true
	_moxa_glow.position = Vector2(u.x * sz.x - 32.0, u.y * sz.y - 32.0)
	_moxa_glow.size = Vector2(64, 64)
	if _moxa_glow is ColorRect:
		(_moxa_glow as ColorRect).color = Color(0.9, 0.4, 0.18, 0.6)
		var tw := create_tween()
		tw.tween_property(_moxa_glow, "color:a", 0.15, 0.9)
	else:
		_moxa_glow.modulate = Color(1, 1, 1, 0.95)
		var tw2 := create_tween()
		tw2.tween_property(_moxa_glow, "modulate:a", 0.2, 0.9)


func _set_feedback(s: String) -> void:
	if _feedback:
		_feedback.text = s


func _paint() -> void:
	for p in CaseDB.pack.get("acupoints", []):
		var id := str(p["id"])
		var unlocked := GameFlow.acu_teach_unlocked(id)
		if _btns.has(id):
			var b: Button = _btns[id]
			b.disabled = not unlocked
			b.text = CaseDB.named_point(p)
			if id in GameFlow.acu_practiced:
				b.modulate = Color(0.85, 0.55, 0.45, 1)
			elif unlocked:
				b.modulate = Color.WHITE
			else:
				b.modulate = Color(0.7, 0.7, 0.7, 0.55)
		if _btns.has(id + "_dot"):
			var d: ColorRect = _btns[id + "_dot"]
			if not unlocked:
				d.color = Color(0.55, 0.52, 0.48, 0.45)
			elif id in GameFlow.acu_practiced:
				d.color = UiKit.SEAL
			elif id in GameFlow.acu_known:
				d.color = Color(0.45, 0.55, 0.35, 0.95)
			else:
				d.color = Color(0.93, 0.9, 0.82, 1)
	var n := GameFlow.acu_practiced.size()
	_count.text = tr("ACU_COUNT").format({"n": n}) + "  ·  " + tr("ACU_COUNT_HINT")
	_selected.clear()
	for pid in GameFlow.acu_practiced:
		_selected.append(str(pid))


func _refresh() -> void:
	var h := find_child("NeedleHint", true, false) as Label
	if h:
		h.text = tr("ACU_BODY_HINT")
	var t := find_child("TeachOnly", true, false) as Label
	if t:
		t.text = tr("ACU_TEACH_ONLY")
	var d := find_child("AcuDisclaimer", true, false) as Label
	if d:
		d.text = tr("ACU_DISCLAIMER_HINT")
	var f := find_child("AcuFooter", true, false) as Label
	if f:
		f.text = tr("STORE_NOT_MEDICAL")
	if _mentor:
		_mentor.text = tr("MENTOR_ACU_1")
	_need.text = tr("ACU_NEED_POINT")
	_paint()
	UiKit.refresh_i18n_buttons(self)


func _leave() -> void:
	_clear_tech()
	if bool(get_meta("embedded", false)):
		queue_free()
		return
	GameFlow.back_to_consult()


func _submit() -> void:
	if not GameFlow.acu_can_submit(GameFlow.acu_practiced):
		_need.visible = true
		_need.text = tr("ACU_NEED_POINT") if GameFlow.acu_practiced.is_empty() else tr("ACU_DEQI_NEED")
		return
	_need.visible = false
	var ids: Array = []
	for p in GameFlow.acu_practiced:
		ids.append(str(p))
	GameFlow.settle("acupuncture", ids)
	if bool(get_meta("embedded", false)):
		queue_free()
