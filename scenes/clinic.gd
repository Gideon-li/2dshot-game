extends Node2D
## SCENE-SLICE hung on this one room. No second map. GameFlow play loop overlays.

const WORLD := Vector2(2560, 1440)
const HERB_SNAP := 40.0
const BED_RECT := Rect2(320, 820, 420, 160)
const FORMULA_RECT := Rect2(1720, 780, 400, 180)
const TABLE_CENTER := Vector2(1920, 870)
const DRAWER_CELL := Vector2(72, 56)
const HERO_DEADZONE := 200.0
const WALK_SPEED := 240.0

const HOTSPOTS := {
	"Area_南门": "door",
	"Area_候诊凳A": "stool_a",
	"Area_候诊凳B": "stool_b",
	"Area_病人椅": "chair",
	"Area_脉枕": "pulse",
	"Area_香炉": "incense",
	"Area_花窗2": "window2",
	"Area_调剂台": "formula",
	"Area_针灸榻": "needle",
}

const ACU_NORM := {
	"fengchi": Vector2(0.50, 0.10), "dazhui": Vector2(0.50, 0.18), "qimen": Vector2(0.28, 0.32),
	"neiguan": Vector2(0.16, 0.38), "lieque": Vector2(0.14, 0.42), "hegu": Vector2(0.08, 0.46),
	"quchi": Vector2(0.20, 0.34), "shenshu": Vector2(0.50, 0.44), "mingmen": Vector2(0.50, 0.50),
	"zusanli": Vector2(0.38, 0.72), "yanglingquan": Vector2(0.62, 0.70), "sanyinjiao": Vector2(0.38, 0.82),
	"taixi": Vector2(0.36, 0.90), "zhaohai": Vector2(0.64, 0.90), "taichong": Vector2(0.38, 0.97),
	"yongquan": Vector2(0.62, 0.97),
}

const BLOCKS := [
	Rect2(0, 1080, 2560, 360),
	Rect2(1680, 520, 720, 640),
	Rect2(920, 590, 340, 100),
	Rect2(240, 780, 480, 200),
	Rect2(1720, 780, 400, 180),
	Rect2(0, 0, 2560, 40),
	Rect2(0, 0, 40, 1440),
	Rect2(2520, 0, 40, 1440),
	Rect2(640, 1080, 1280, 80),
]

var _cam_name := "CAM_HERO"
var _hover := ""
var _drag_herb := ""
var _drag_vis: Node2D
var _overlay: Node
var _hint: Label
var _title: Label
var _foot: Label
var _stage_path := ""
var _qwen: QwenClient
var _pending_q := ""
var _dock: Panel
var _chat: VBoxContainer
var _ask_edit: LineEdit


func _ready() -> void:
	AudioHub.enter_clinic()
	_wire_areas()
	_build_drawers()
	_build_acupoints()
	_label_patients()
	_build_hud()
	_switch_camera("CAM_HERO")
	_qwen = QwenClient.new()
	add_child(_qwen)
	_qwen.replied.connect(_on_qwen)
	GameFlow.locale_changed.connect(_refresh)
	GameFlow.fsm_changed.connect(_on_fsm)
	if GameFlow.has_signal("fanwei_locked") and not GameFlow.fanwei_locked.is_connected(_on_fanwei_locked):
		GameFlow.fanwei_locked.connect(_on_fanwei_locked)
	if GameFlow.has_signal("settled") and not GameFlow.settled.is_connected(_on_settled):
		GameFlow.settled.connect(_on_settled)
	_refresh()
	_rebuild_dock()


func _process(delta: float) -> void:
	_walk(delta)
	if _cam_name == "CAM_HERO":
		_follow_hero()
	_tick_drag()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if _drag_herb == "":
			_nudge_apprentice(get_global_mouse_position())


func _walk(delta: float) -> void:
	var ap := get_node_or_null("L5_characters/Apprentice") as Node2D
	if ap == null:
		return
	var axis := Vector2(Input.get_axis("ui_left", "ui_right"), Input.get_axis("ui_up", "ui_down"))
	if axis.length() < 0.1:
		return
	var nxt := ap.position + axis.normalized() * WALK_SPEED * delta
	if _walkable(nxt):
		ap.position = nxt


func _nudge_apprentice(world: Vector2) -> void:
	var ap := get_node_or_null("L5_characters/Apprentice") as Node2D
	if ap == null or not _walkable(world):
		return
	var tw := create_tween()
	tw.tween_property(ap, "position", world, clampf(ap.position.distance_to(world) / WALK_SPEED, 0.15, 1.2))


func _walkable(p: Vector2) -> bool:
	if p.x < 48.0 or p.y < 48.0 or p.x > WORLD.x - 48.0 or p.y > WORLD.y - 48.0:
		return false
	for r in BLOCKS:
		if r.has_point(p):
			return false
	return true


func _follow_hero() -> void:
	var cam := get_node_or_null("CAM_HERO") as Camera2D
	var ap := get_node_or_null("L5_characters/Apprentice") as Node2D
	if cam == null or ap == null or not cam.enabled:
		return
	if ap.position.distance_to(cam.position) <= HERO_DEADZONE:
		return
	var half := Vector2(960, 540)
	var target := ap.position
	target.x = clampf(target.x, half.x, WORLD.x - half.x)
	target.y = clampf(target.y, half.y, WORLD.y - half.y)
	cam.position = cam.position.lerp(target, 0.08)


func _switch_camera(cam_name: String) -> void:
	_cam_name = cam_name
	for n in ["CAM_HERO", "CAM_ASK", "CAM_PULSE", "CAM_FORMULA", "CAM_NEEDLE", "CAM_RESULT"]:
		var cam := get_node_or_null(n) as Camera2D
		if cam == null:
			continue
		if n == "CAM_PULSE":
			cam.rotation = 0.0
			cam.ignore_rotation = true
		if n == cam_name:
			cam.enabled = true
			cam.make_current()
		else:
			cam.enabled = false


func _wire_areas() -> void:
	var host := get_node_or_null("Areas")
	if host == null:
		return
	for area in host.get_children():
		if not (area is Area2D):
			continue
		var kind := str(HOTSPOTS.get(area.name, ""))
		area.set_meta("hotspot", kind)
		area.input_pickable = true
		if not area.input_event.is_connected(_on_hotspot_input):
			area.input_event.connect(_on_hotspot_input.bind(area))
		if not area.mouse_entered.is_connected(_on_hotspot_enter):
			area.mouse_entered.connect(_on_hotspot_enter.bind(area))
			area.mouse_exited.connect(_on_hotspot_exit.bind(area))


func _on_hotspot_enter(area: Area2D) -> void:
	_hover = str(area.get_meta("hotspot", area.name))
	_paint_hint()


func _on_hotspot_exit(area: Area2D) -> void:
	if _hover == str(area.get_meta("hotspot", area.name)):
		_hover = ""
		_paint_hint()


func _on_hotspot_input(_vp: Node, event: InputEvent, _shape: int, area: Area2D) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if str(area.get_meta("hotspot", "")) == "drawer":
		return
	_handle_hotspot(str(area.get_meta("hotspot", "")))
	get_viewport().set_input_as_handled()


func _handle_hotspot(kind: String) -> void:
	match kind:
		"door":
			_switch_camera("CAM_HERO")
			_pick_at(2)
		"stool_a":
			_switch_camera("CAM_ASK")
			_pick_at(0)
		"stool_b":
			_switch_camera("CAM_ASK")
			_pick_at(1)
		"chair":
			_switch_camera("CAM_ASK")
			if GameFlow.current_patient_id != "":
				GameFlow.do_exam("wen_ask")
				_rebuild_dock()
		"pulse":
			# Camera + four-exam notify only. No encyclopedia. No pulse-wave art.
			_switch_camera("CAM_PULSE")
			if has_node("CAM_PULSE"):
				$CAM_PULSE.rotation = 0.0
				$CAM_PULSE.ignore_rotation = true
			if GameFlow.current_patient_id != "":
				GameFlow.do_exam("qie")
			_rebuild_dock()
		"incense":
			if GameFlow.current_patient_id != "":
				GameFlow.do_exam("wen_listen")
			_rebuild_dock()
		"window2":
			if GameFlow.current_patient_id != "":
				GameFlow.do_exam("wang")
			_rebuild_dock()
		"formula":
			_switch_camera("CAM_FORMULA")
			if GameFlow.current_patient_id != "":
				GameFlow.enter_formula()
			_rebuild_dock()
		"needle":
			AudioHub.play_one("needle")
			_switch_camera("CAM_NEEDLE")
			if GameFlow.current_patient_id != "":
				GameFlow.enter_needling()
			_rebuild_dock()


func _pick_at(index: int) -> void:
	if index < 0 or index >= CaseDB.patients.size():
		return
	_on_pick(str(CaseDB.patients[index].get("id", "")))


func _on_pick(pid: String) -> void:
	if pid == "" or GameFlow.is_seen(pid):
		return
	AudioHub.play_chime()
	_seat_patient(pid)
	GameFlow.start_patient(pid)


func _seat_patient(pid: String) -> void:
	var chair := Vector2(1040, 590)
	var chars := get_node_or_null("L5_characters")
	if chars == null:
		return
	for n in chars.get_children():
		if str(n.get_meta("pid", "")) == pid:
			var tw := create_tween()
			tw.tween_property(n, "position", chair, 0.35)


func _label_patients() -> void:
	var chars := get_node_or_null("L5_characters")
	if chars == null:
		return
	for i in CaseDB.patients.size():
		var p: Dictionary = CaseDB.patients[i]
		var node := chars.get_node_or_null("Patient%d" % i) as Node2D
		if node == null:
			continue
		node.set_meta("pid", str(p.get("id", "")))
		node.set_meta("home", node.position)
		node.y_sort_enabled = true
		if node.get_node_or_null("Name") == null:
			var lb := Label.new()
			lb.name = "Name"
			lb.position = Vector2(-48, -40)
			lb.size = Vector2(96, 22)
			lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lb.add_theme_color_override("font_color", UiKit.INK)
			UiKit.apply_font(lb, 13)
			lb.mouse_filter = Control.MOUSE_FILTER_IGNORE
			node.add_child(lb)


func _build_drawers() -> void:
	var host := get_node_or_null("L3_furniture/Cabinet/Drawers") as Node2D
	if host == null:
		return
	for c in host.get_children():
		c.queue_free()
	var herbs: Array = CaseDB.pack.get("herbs", [])
	var origin := Vector2(-288, -460)
	for row in 6:
		for col in 8:
			var idx := row * 8 + col
			var cell := Node2D.new()
			cell.name = "Drawer_%d_%d" % [col, row]
			cell.position = origin + Vector2((col + 0.5) * DRAWER_CELL.x, (row + 0.5) * DRAWER_CELL.y)
			cell.set_meta("closed_pos", cell.position)
			var hw := DRAWER_CELL.x * 0.5 - 2.0
			var hh := DRAWER_CELL.y * 0.5 - 2.0
			var fill := Polygon2D.new()
			fill.color = Color(0.18, 0.16, 0.15, 0.72).lightened(0.05 if (col + row) % 2 == 0 else 0.0)
			fill.polygon = PackedVector2Array([
				Vector2(-hw, -hh), Vector2(hw, -hh), Vector2(hw, hh), Vector2(-hw, hh),
			])
			cell.add_child(fill)
			var hid := ""
			if idx < herbs.size() and typeof(herbs[idx]) == TYPE_DICTIONARY:
				hid = str(herbs[idx].get("id", ""))
			if hid != "":
				var lb := Label.new()
				lb.text = CaseDB.herb_name(hid)
				lb.position = Vector2(-hw + 2, -8)
				lb.size = Vector2(DRAWER_CELL.x - 6, 16)
				lb.add_theme_font_size_override("font_size", 10)
				lb.add_theme_color_override("font_color", Color(0.96, 0.94, 0.89, 1))
				lb.mouse_filter = Control.MOUSE_FILTER_IGNORE
				lb.clip_text = true
				cell.add_child(lb)
			var area := Area2D.new()
			area.input_pickable = true
			area.set_meta("hotspot", "drawer")
			area.set_meta("herb_id", hid)
			var cs := CollisionShape2D.new()
			var rs := RectangleShape2D.new()
			rs.size = DRAWER_CELL - Vector2(4, 4)
			cs.shape = rs
			area.add_child(cs)
			area.input_event.connect(_on_drawer_input.bind(hid, cell))
			cell.add_child(area)
			host.add_child(cell)


func _on_drawer_input(_vp: Node, event: InputEvent, _shape: int, hid: String, cell: Node2D) -> void:
	if hid == "":
		return
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	AudioHub.play_one("drawer")
	var closed: Vector2 = cell.get_meta("closed_pos", cell.position)
	cell.position = closed + Vector2(0, 28)
	get_tree().create_timer(0.28).timeout.connect(func() -> void:
		if is_instance_valid(cell):
			cell.position = closed
	)
	_drag_herb = hid
	if _drag_vis:
		_drag_vis.queue_free()
	_drag_vis = Node2D.new()
	var vis := Polygon2D.new()
	vis.color = Color(0.4, 0.32, 0.24, 0.9)
	vis.polygon = PackedVector2Array([
		Vector2(-28, -14), Vector2(28, -14), Vector2(28, 14), Vector2(-28, 14),
	])
	_drag_vis.add_child(vis)
	add_child(_drag_vis)
	_drag_vis.global_position = cell.global_position
	_switch_camera("CAM_FORMULA")
	get_viewport().set_input_as_handled()


func _tick_drag() -> void:
	if _drag_herb == "" or _drag_vis == null:
		return
	var mp := get_global_mouse_position()
	if mp.distance_to(TABLE_CENTER) <= HERB_SNAP:
		_drag_vis.global_position = _drag_vis.global_position.lerp(TABLE_CENTER, 0.45)
	else:
		_drag_vis.global_position = mp
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		return
	var hid := _drag_herb
	_drag_herb = ""
	_drag_vis.queue_free()
	_drag_vis = null
	var near := mp.distance_to(TABLE_CENTER) <= HERB_SNAP or FORMULA_RECT.grow(HERB_SNAP).has_point(mp)
	if not near:
		return
	if GameFlow.current_patient_id != "" and GameFlow.fsm_state != "formula_crafting":
		if GameFlow.has_method("enter_formula"):
			GameFlow.enter_formula()
		else:
			GameFlow.open_formula()
	var added := false
	if GameFlow.has_method("add_herb_to_tray"):
		added = GameFlow.add_herb_to_tray(hid)
		if not added and GameFlow.last_fanwei_reason != "":
			AudioHub.play_one("ui-paper")
		elif added:
			AudioHub.play_one("herb-drop")
		else:
			AudioHub.play_one("herb-drop")
	else:
		AudioHub.play_one("herb-drop")
	_rebuild_dock()


func _build_acupoints() -> void:
	var bed := get_node_or_null("L3_furniture/NeedleBed") as Node2D
	if bed == null:
		return
	var old := bed.get_node_or_null("Acupoints")
	if old:
		old.queue_free()
	var root := Node2D.new()
	root.name = "Acupoints"
	bed.add_child(root)
	var shape := CircleShape2D.new()
	shape.radius = 11.0
	for raw in CaseDB.pack.get("acupoints", []):
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var id := str(raw.get("id", ""))
		var uv: Vector2 = ACU_NORM.get(id, Vector2(0.5, 0.5))
		var world := Vector2(BED_RECT.position.x + uv.x * BED_RECT.size.x, BED_RECT.position.y + uv.y * BED_RECT.size.y)
		world.x = clampf(world.x, BED_RECT.position.x + 12.0, BED_RECT.end.x - 12.0)
		world.y = clampf(world.y, BED_RECT.position.y + 12.0, BED_RECT.end.y - 12.0)
		var pt := Area2D.new()
		pt.name = "Pt_%s" % id
		pt.position = world - bed.position
		pt.input_pickable = true
		pt.set_meta("hotspot", "acupoint")
		pt.set_meta("point_id", id)
		var cs := CollisionShape2D.new()
		cs.shape = shape
		pt.add_child(cs)
		var vis := Polygon2D.new()
		vis.color = Color(0.96, 0.94, 0.89, 0.95)
		vis.polygon = PackedVector2Array([
			Vector2(-6, 0), Vector2(0, -6), Vector2(6, 0), Vector2(0, 6),
		])
		pt.add_child(vis)
		pt.input_event.connect(_on_point_input.bind(id))
		root.add_child(pt)


func _on_point_input(_vp: Node, event: InputEvent, _shape: int, pid: String) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	AudioHub.play_one("needle")
	_switch_camera("CAM_NEEDLE")
	if GameFlow.current_patient_id != "" and GameFlow.fsm_state != "needling":
		if GameFlow.has_method("enter_needling"):
			GameFlow.enter_needling()
		else:
			GameFlow.open_needling()
	if GameFlow.has_method("toggle_point"):
		GameFlow.toggle_point(pid)
	_rebuild_dock()


func _on_fsm(state: String) -> void:
	match state:
		"clinic_idle":
			_switch_camera("CAM_HERO")
		"patient_selected", "examining", "treatment_choice":
			if GameFlow.exam_focus == "qie":
				_switch_camera("CAM_PULSE")
			elif _cam_name == "CAM_HERO":
				_switch_camera("CAM_ASK")
		"formula_crafting":
			_switch_camera("CAM_FORMULA")
		"needling":
			_switch_camera("CAM_NEEDLE")
		"settling":
			_switch_camera("CAM_RESULT")
	_rebuild_dock()
	_refresh()


func _on_settled(_result: Dictionary) -> void:
	_switch_camera("CAM_RESULT")
	_rebuild_dock()


func _stage(_path: String) -> void:
	# Play stays on this map. Compact dock only — never a second clinic scene.
	pass


func _clear_stage() -> void:
	_overlay = null
	_stage_path = ""
	if _dock and is_instance_valid(_dock):
		for c in _dock.get_children():
			c.queue_free()


func _rebuild_dock() -> void:
	var hud := get_node_or_null("UI/Hud") as Control
	if hud == null:
		return
	if _dock == null or not is_instance_valid(_dock):
		_dock = Panel.new()
		_dock.name = "PlayDock"
		_dock.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
		_dock.anchor_top = 1.0
		_dock.anchor_bottom = 1.0
		_dock.anchor_left = 0.0
		_dock.anchor_right = 0.0
		_dock.offset_left = 16
		_dock.offset_top = -210
		_dock.offset_right = 640
		_dock.offset_bottom = -36
		_dock.mouse_filter = Control.MOUSE_FILTER_STOP
		_dock.add_theme_stylebox_override("panel", UiKit.paper_style(UiKit.PAPER, UiKit.LINE, 4))
		hud.add_child(_dock)
	for c in _dock.get_children():
		c.queue_free()
	_chat = null
	_ask_edit = null
	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.offset_left = 12
	col.offset_right = -12
	col.offset_top = 8
	col.offset_bottom = -8
	col.add_theme_constant_override("separation", 6)
	_dock.add_child(col)
	var st := str(GameFlow.fsm_state)
	if st == "clinic_idle":
		col.add_child(UiKit.ink_label(tr("CLINIC_HINT"), 14, UiKit.INK_MUTED))
		_dock.visible = GameFlow.current_patient_id != ""
		return
	_dock.visible = true
	if st in ["patient_selected", "examining", "treatment_choice"]:
		_fill_exam_dock(col)
	elif st == "formula_crafting":
		_fill_formula_dock(col)
	elif st == "needling":
		_fill_needle_dock(col)
	elif st == "settling":
		_fill_score_dock(col)


func _clue_lines(exam_id: String) -> PackedStringArray:
	if GameFlow.has_method("exam_clues"):
		return GameFlow.exam_clues(exam_id)
	return PackedStringArray()


func _fill_exam_dock(col: VBoxContainer) -> void:
	var hud := CaseDB.hud_card(GameFlow.current_patient_id)
	col.add_child(UiKit.ink_label(str(hud.get("name", "")), 16))
	var marks := []
	for eid in ["wang", "wen_listen", "wen_ask", "qie"]:
		marks.append("●" if GameFlow.exam_done(eid) else "○")
	col.add_child(UiKit.ink_label("望%s 闻%s 问%s 切%s" % marks, 13, UiKit.INK_MUTED))
	var focus := str(GameFlow.exam_focus)
	if focus == "qie":
		# Text clues only. Art team owns 脉纹 on the pillow; no pulse.tscn / encyclopedia.
		for line in _clue_lines("qie"):
			col.add_child(UiKit.ink_label("· " + line, 14))
		if _clue_lines("qie").is_empty():
			col.add_child(UiKit.ink_label(tr("CLUE_EMPTY"), 14, UiKit.INK_MUTED))
	elif focus == "wang" or focus == "wen_listen":
		for line in _clue_lines(focus):
			col.add_child(UiKit.ink_label("· " + line, 14))
	elif focus == "wen_ask" or focus == "":
		_fill_ask_dock(col)
	var row := HBoxContainer.new()
	col.add_child(row)
	var fb := UiKit.make_button("ACTION_PRESCRIBE", true)
	fb.pressed.connect(func() -> void:
		GameFlow.enter_formula()
		_switch_camera("CAM_FORMULA")
	)
	row.add_child(fb)
	var nb := UiKit.make_button("ACTION_NEEDLE", true)
	nb.pressed.connect(func() -> void:
		GameFlow.enter_needling()
		_switch_camera("CAM_NEEDLE")
	)
	row.add_child(nb)


func _fill_ask_dock(col: VBoxContainer) -> void:
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 70)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(scroll)
	_chat = VBoxContainer.new()
	_chat.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_chat)
	for turn in GameFlow.conversation:
		if typeof(turn) != TYPE_DICTIONARY:
			continue
		var d: Dictionary = turn
		_append_chat(str(d.get("q", "")), str(d.get("a", "")))
	# 「十问」shortcut bar — song labels from ten_questions.json; no encyclopedia.
	col.add_child(UiKit.ink_label(tr("TENQ_BAR_TITLE"), 12, UiKit.INK_MUTED))
	var tenq := HFlowContainer.new()
	tenq.add_theme_constant_override("h_separation", 4)
	tenq.add_theme_constant_override("v_separation", 4)
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
		UiKit.apply_font(b, 12)
		b.pressed.connect(_make_tenq_sender(qid))
		tenq.add_child(b)
	var row := HBoxContainer.new()
	col.add_child(row)
	_ask_edit = LineEdit.new()
	_ask_edit.placeholder_text = tr("UI_ASK_PLACEHOLDER")
	_ask_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiKit.apply_font(_ask_edit, 14)
	_ask_edit.text_submitted.connect(_send_ask)
	row.add_child(_ask_edit)
	var send := UiKit.make_button("UI_ASK_SEND", true)
	send.pressed.connect(func() -> void: _send_ask(_ask_edit.text if _ask_edit else ""))
	row.add_child(send)


func _make_tenq_sender(qid: String) -> Callable:
	return func() -> void:
		GameFlow.mark_tenq(qid)
		var prompt := TenQuestions.prompt_for(qid, GameFlow.loc())
		if prompt == "":
			prompt = TenQuestions.prompt_for(qid, "zh")
		_send_ask(prompt)


func _append_chat(q: String, a: String) -> void:
	if _chat == null:
		return
	if q != "":
		_chat.add_child(UiKit.ink_label("▸ " + q, 13, UiKit.SEAL))
	if a != "":
		_chat.add_child(UiKit.ink_label(a, 14, UiKit.INK))


func _send_ask(text: String) -> void:
	var q := text.strip_edges()
	if q.is_empty() or _qwen == null or _qwen.is_busy():
		return
	if _ask_edit:
		_ask_edit.text = ""
	AudioHub.play_ui_ink()
	GameFlow.do_exam("wen_ask")
	_append_chat(q, tr("ASK_THINKING"))
	_pending_q = q
	_qwen.ask(q, CaseDB.patient_by_id(GameFlow.current_patient_id), CaseDB.case_for_patient(GameFlow.current_patient_id))


func _on_qwen(text: String, _from_api: bool) -> void:
	GameFlow.conversation.append({"q": _pending_q, "a": text})
	_rebuild_dock()



func _on_fanwei_locked(reason: String) -> void:
	AudioHub.play_herb_wrong()
	if _hint:
		_hint.text = reason
	_rebuild_dock()


func _fill_formula_dock(col: VBoxContainer) -> void:
	col.add_child(UiKit.ink_label(tr("FORMULA_HINT"), 13, UiKit.INK_MUTED))
	if GameFlow.last_fanwei_reason != "":
		col.add_child(UiKit.ink_label(GameFlow.last_fanwei_reason, 13, UiKit.SEAL))
	var names: Array[String] = []
	for hid in GameFlow.tray_herbs:
		names.append(CaseDB.herb_name(str(hid)))
	col.add_child(UiKit.ink_label(tr("TRAY_COUNT").replace("{n}", str(GameFlow.tray_herbs.size())) + "  " + "、".join(PackedStringArray(names)), 14))
	var row := HBoxContainer.new()
	col.add_child(row)
	var ok := UiKit.make_button("ACTION_PRESCRIBE", true)
	ok.disabled = not GameFlow.can_confirm_formula() or GameFlow.formula_lock_reason() != ""
	ok.pressed.connect(func() -> void:
		if GameFlow.formula_lock_reason() != "":
			return
		GameFlow.confirm_formula()
	)
	row.add_child(ok)
	var back := UiKit.make_button("TREAT_BACK")
	back.pressed.connect(func() -> void:
		GameFlow.open_treatment()
		_switch_camera("CAM_ASK")
		_rebuild_dock()
	)
	row.add_child(back)


func _fill_needle_dock(col: VBoxContainer) -> void:
	col.add_child(UiKit.ink_label(tr("TREAT_NEEDLE_HINT") if tr("TREAT_NEEDLE_HINT") != "TREAT_NEEDLE_HINT" else "点穴 2–5", 13, UiKit.INK_MUTED))
	var names: Array[String] = []
	for pid in GameFlow.selected_points:
		names.append(GameFlow.loc_text(GameFlow.points_by_id.get(str(pid), {}), str(pid)))
	col.add_child(UiKit.ink_label("、".join(PackedStringArray(names)) if names else "—", 14))
	var row := HBoxContainer.new()
	col.add_child(row)
	var ok := UiKit.make_button("ACTION_NEEDLE", true)
	ok.disabled = not GameFlow.can_confirm_needling()
	ok.pressed.connect(func() -> void: GameFlow.confirm_needling())
	row.add_child(ok)
	var back := UiKit.make_button("TREAT_BACK")
	back.pressed.connect(func() -> void:
		GameFlow.open_treatment()
		_switch_camera("CAM_ASK")
		_rebuild_dock()
	)
	row.add_child(back)


func _fill_score_dock(col: VBoxContainer) -> void:
	var r: Dictionary = GameFlow.last_result
	var rank := str(r.get("rank_id", ""))
	var rank_v: Variant = r.get("rank", null)
	if typeof(rank_v) == TYPE_DICTIONARY:
		rank = GameFlow.loc_text(rank_v, rank)
	col.add_child(UiKit.ink_label(rank, 18))
	col.add_child(UiKit.ink_label(str(r.get("flavor", "")), 14, UiKit.INK_MUTED))
	var nxt := UiKit.make_button("SLICE_DONE" if GameFlow.slice_complete() else "UI_BACK", true)
	nxt.pressed.connect(func() -> void:
		GameFlow.next_patient()
		_switch_camera("CAM_HERO")
		_rebuild_dock()
		_refresh()
	)
	col.add_child(nxt)


func _build_hud() -> void:
	var hud := get_node_or_null("UI/Hud") as Control
	if hud == null:
		return
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bar := Control.new()
	bar.name = "Chrome"
	bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(bar)
	var top := HBoxContainer.new()
	top.position = Vector2(24, 10)
	top.size = Vector2(1232, 36)
	top.mouse_filter = Control.MOUSE_FILTER_STOP
	bar.add_child(top)
	_title = UiKit.ink_label(tr("GAME_TITLE"), 20)
	top.add_child(_title)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(sp)
	top.add_child(UiKit.locale_bar())
	var row := HBoxContainer.new()
	row.name = "Patients"
	row.position = Vector2(24, 50)
	row.size = Vector2(920, 64)
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_STOP
	bar.add_child(row)
	for i in CaseDB.patients.size():
		var p: Dictionary = CaseDB.patients[i]
		var pid := str(p.get("id", ""))
		var card := Button.new()
		card.name = pid
		card.custom_minimum_size = Vector2(200, 56)
		card.set_meta("pid", pid)
		UiKit.style_button(card, false)
		card.pressed.connect(_on_pick.bind(pid))
		var inner := VBoxContainer.new()
		inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		inner.offset_left = 8
		inner.offset_right = -8
		inner.offset_top = 4
		inner.offset_bottom = -4
		card.add_child(inner)
		var nm := UiKit.ink_label(UiKit.loc_text(p.get("name", {}), pid), 15)
		nm.set_meta("name_label", true)
		inner.add_child(nm)
		var idn := UiKit.ink_label(UiKit.loc_text(p.get("identity", {}), ""), 12, UiKit.INK_MUTED)
		idn.set_meta("id_label", true)
		inner.add_child(idn)
		row.add_child(card)
	_hint = UiKit.ink_label(tr("CLINIC_HINT"), 14, UiKit.INK_MUTED)
	_hint.name = "ClinicHint"
	_hint.position = Vector2(24, 118)
	_hint.size = Vector2(900, 24)
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(_hint)
	_foot = UiKit.ink_label(tr("BOOT_DISCLAIMER_FOOTER"), 13, UiKit.INK_MUTED)
	_foot.name = "ClinicFoot"
	_foot.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_foot.anchor_top = 1.0
	_foot.anchor_bottom = 1.0
	_foot.offset_top = -26
	_foot.offset_bottom = -6
	_foot.offset_left = 24
	_foot.offset_right = -24
	_foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_foot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(_foot)


func _paint_hint() -> void:
	if _hint == null:
		return
	if GameFlow.slice_complete():
		_hint.text = tr("DONE_ALL")
		return
	match _hover:
		"pulse":
			_hint.text = tr("HINT_PULSE")
		"window2":
			_hint.text = tr("HINT_LOOK")
		"incense":
			_hint.text = tr("HINT_LISTEN")
		"chair":
			_hint.text = tr("HINT_ASK")
		"formula", "drawer":
			_hint.text = tr("TREAT_FORMULA_HINT")
		"needle", "acupoint":
			_hint.text = tr("TREAT_NEEDLE_HINT")
		_:
			_hint.text = tr("CLINIC_HINT")


func _refresh() -> void:
	if _title:
		_title.text = tr("GAME_TITLE")
	if _foot:
		_foot.text = tr("BOOT_DISCLAIMER_FOOTER")
	_paint_hint()
	UiKit.refresh_i18n_buttons(self)
	var chars := get_node_or_null("L5_characters")
	if chars:
		for n in chars.get_children():
			var pid := str(n.get_meta("pid", ""))
			if pid == "":
				continue
			var p := CaseDB.patient_by_id(pid)
			var lb := n.get_node_or_null("Name") as Label
			if lb:
				lb.text = UiKit.loc_text(p.get("name", {}), pid)
			n.modulate = Color(0.6, 0.6, 0.6, 0.75) if GameFlow.is_seen(pid) else Color.WHITE
	var hud := get_node_or_null("UI/Hud")
	if hud == null:
		return
	var row := hud.find_child("Patients", true, false)
	if row == null:
		return
	for card in row.get_children():
		if not (card is Button):
			continue
		var pid := str(card.get_meta("pid", ""))
		var p := CaseDB.patient_by_id(pid)
		for n in card.find_children("*", "Label", true, false):
			if n.has_meta("name_label"):
				n.text = UiKit.loc_text(p.get("name", {}), pid)
			elif n.has_meta("id_label"):
				var idn := UiKit.loc_text(p.get("identity", {}), "")
				n.text = "%s · %s" % [idn, tr("UI_SEEN")] if GameFlow.is_seen(pid) else idn
		(card as Button).disabled = GameFlow.is_seen(pid)
