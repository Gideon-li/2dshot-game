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
	"Area_候诊凳C": "stool_c",
	"Area_候诊凳D": "stool_d",
	"Area_病人椅": "chair",
	"Area_脉枕": "pulse",
	"Area_香炉": "incense",
	"Area_花窗2": "window2",
	"Area_调剂台": "formula",
	"Area_针灸榻": "needle",
	"Area_阁楼": "loft",
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
var _xiaohe_idle_line: String = ""
var _revisit_idle_line: String = ""
var _revisit_taken: bool = false
var _last_mentor_shown: String = ""
## V137 UI chrome
var _chat_scroll: ScrollContainer
var _settings_root: Control
var _settings_toast: Label
var _day_top: Label
var _nav_strip: HBoxContainer


func _ready() -> void:
	AudioHub.enter_clinic()
	_ensure_loft_nodes()
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
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE):
		if GameFlow.settings_open:
			_set_settings_open(false)
			get_viewport().set_input_as_handled()
			return
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
	_ensure_loft_nodes()
	for n in ["CAM_HERO", "CAM_ASK", "CAM_PULSE", "CAM_FORMULA", "CAM_NEEDLE", "CAM_RESULT", "CAM_LOFT"]:
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
			if str(GameFlow.fsm_state) == "clinic_idle" and GameFlow.has_method("advance_clinic_day"):
				_do_next_day()
			else:
				_pick_at(2)
		"stool_a":
			_switch_camera("CAM_ASK")
			_pick_at(0)
		"stool_b":
			_switch_camera("CAM_ASK")
			_pick_at(1)
		"stool_c":
			_switch_camera("CAM_ASK")
			_pick_at(2)
		"stool_d":
			_switch_camera("CAM_ASK")
			_pick_at(3)
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
			_open_acu_body_map()
		"loft":
			_switch_camera("CAM_LOFT")
			if str(GameFlow.fsm_state) == "clinic_idle":
				_do_go_loft()


func _waiting_list() -> Array:
	## V134: hall shows ≤4 from weighted pool, not full 7 roster.
	if GameFlow.has_method("waiting_patients"):
		return GameFlow.waiting_patients()
	return CaseDB.patients


func _pick_at(index: int) -> void:
	var seats: Array = _waiting_list()
	if index < 0 or index >= seats.size():
		return
	_on_pick(str(seats[index].get("id", "")))


func _on_pick(pid: String) -> void:
	if pid == "" or GameFlow.is_seen(pid):
		return
	AudioHub.play_chime()
	_seat_patient(pid)
	GameFlow.start_patient(pid)
	_apply_portraits()


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
	var wait_homes := [Vector2(405, 290), Vector2(545, 290), Vector2(300, 340), Vector2(685, 290)]
	var seats: Array = _waiting_list()
	var max_seats := mini(seats.size(), wait_homes.size())
	# Hide any leftover PatientN beyond max 4 (never expand hall)
	for i in 8:
		var extra := chars.get_node_or_null("Patient%d" % i) as Node2D
		if extra and i >= max_seats:
			extra.visible = false
	for i in max_seats:
		var p: Dictionary = seats[i]
		var node := chars.get_node_or_null("Patient%d" % i) as Node2D
		if node == null:
			node = Node2D.new()
			node.name = "Patient%d" % i
			chars.add_child(node)
		node.visible = true
		node.position = wait_homes[i]
		node.set_meta("pid", str(p.get("id", "")))
		node.set_meta("home", wait_homes[i])
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
	_apply_portraits()
	_rebuild_waiting_hud()






func _rebuild_waiting_hud() -> void:
	var hud := get_node_or_null("UI/Hud")
	if hud == null:
		return
	var row := hud.find_child("Patients", true, false)
	if row == null:
		return
	for c in row.get_children():
		c.queue_free()
	var seats_hud: Array = _waiting_list()
	for i in seats_hud.size():
		var p: Dictionary = seats_hud[i]
		var pid := str(p.get("id", ""))
		var card := Button.new()
		card.name = pid
		card.custom_minimum_size = Vector2(170, 56) if seats_hud.size() >= 4 else Vector2(200, 56)
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

func _apply_portraits() -> void:
	## V137.1: per-seat single portraits; stop Patients composite sheet.
	## Feet at parent origin; waiting display height ~240–280; seated ~280–320.
	var chars := get_node_or_null("L5_characters")
	if chars == null:
		return
	# Always hide composite three-sheet (singles replace it).
	var sheet_root := chars.get_node_or_null("Patients") as Node2D
	if sheet_root:
		sheet_root.visible = false
	var sheet_art := chars.get_node_or_null("Patients/Art") as Sprite2D
	if sheet_art:
		sheet_art.visible = false
		sheet_art.texture = null
	# Jiang Wan apprentice — feet (1100, 720), display ~260.
	var ap := chars.get_node_or_null("Apprentice") as Node2D
	if ap:
		ap.position = Vector2(1100, 720)
		ap.y_sort_enabled = true
		ap.visible = true
	var ap_art := chars.get_node_or_null("Apprentice/Art") as Sprite2D
	if ap_art:
		var at: Texture2D = CharacterArt.load_portrait("apprentice_jiang")
		if at:
			_fit_portrait_sprite(ap_art, at, 260.0)
			ap_art.visible = true
		else:
			ap_art.texture = null
			ap_art.visible = false
	var seats_art: Array = _waiting_list()
	var chair := Vector2(1040, 590)
	var max_art := 4
	for i in max_art:
		var node := chars.get_node_or_null("Patient%d" % i) as Node2D
		if node == null:
			continue
		var spr := node.get_node_or_null("Portrait") as Sprite2D
		if spr == null:
			spr = Sprite2D.new()
			spr.name = "Portrait"
			spr.z_index = 5
			node.add_child(spr)
		var occupied := i < seats_art.size()
		if not occupied:
			spr.texture = null
			spr.visible = false
			node.visible = false
			continue
		var p: Dictionary = seats_art[i]
		var pid := str(p.get("id", ""))
		node.visible = true
		node.y_sort_enabled = true
		node.set_meta("pid", pid)
		var tex: Texture2D = CharacterArt.load_portrait(pid)
		if tex == null:
			spr.texture = null
			spr.visible = false
			continue
		var at_chair := node.position.distance_to(chair) < 48.0
		var target_h := 300.0 if at_chair else 260.0
		_fit_portrait_sprite(spr, tex, target_h)
		spr.visible = true
		spr.z_index = 5
		# Name card above head (text OK but not a substitute for portrait).
		var lb := node.get_node_or_null("Name") as Label
		if lb:
			lb.position = Vector2(-48, -target_h - 8)
			lb.size = Vector2(96, 22)
		_ensure_seat_hit(node, i)


func _fit_portrait_sprite(spr: Sprite2D, tex: Texture2D, target_h: float) -> void:
	## Feet at parent origin: centered=false, position=(-w/2,-h) in local pre-scale.
	spr.texture = tex
	spr.centered = false
	spr.offset = Vector2.ZERO
	var th := float(tex.get_height())
	var tw := float(tex.get_width())
	if th <= 1.0:
		return
	var s := target_h / th
	spr.scale = Vector2(s, s)
	# position is in parent space (not pre-multiplied by scale)
	spr.position = Vector2(-tw * s * 0.5, -th * s)


func _ensure_seat_hit(node: Node2D, seat_index: int) -> void:
	## Click portrait / stool proxy → same open-consult path as Area stool.
	var hit := node.get_node_or_null("Hit") as Area2D
	if hit == null:
		hit = Area2D.new()
		hit.name = "Hit"
		hit.input_pickable = true
		hit.monitoring = true
		hit.monitorable = true
		hit.position = Vector2(0, -90)
		var cs := CollisionShape2D.new()
		cs.name = "Collision"
		var circ := CircleShape2D.new()
		circ.radius = 90.0
		cs.shape = circ
		hit.add_child(cs)
		node.add_child(hit)
		hit.input_event.connect(_on_seat_hit_input.bind(seat_index))
	hit.set_meta("seat_index", seat_index)


func _on_seat_hit_input(_vp: Node, event: InputEvent, _shape: int, seat_index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_switch_camera("CAM_ASK")
		_pick_at(seat_index)


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



func _open_acu_body_map() -> void:
	## V125: body-map intro overlay (no second world map).
	_switch_camera("CAM_NEEDLE")
	if GameFlow.current_patient_id == "":
		return
	if GameFlow.fsm_state != "needling":
		GameFlow.enter_needling()
	var host := get_node_or_null("UI/Hud") as Control
	if host == null:
		host = get_node_or_null("UI") as Control
	if host == null:
		return
	var existing := host.get_node_or_null("AcuOverlay")
	if existing:
		return
	var acu = load("res://scenes/acupuncture.tscn").instantiate()
	acu.name = "AcuOverlay"
	acu.set_meta("embedded", true)
	acu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	acu.z_index = 40
	host.add_child(acu)
	_rebuild_dock()


func _close_acu_body_map() -> void:
	var host := get_node_or_null("UI/Hud")
	if host == null:
		host = get_node_or_null("UI")
	if host == null:
		return
	var existing := host.get_node_or_null("AcuOverlay")
	if existing:
		existing.queue_free()


func _on_point_input(_vp: Node, event: InputEvent, _shape: int, pid: String) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	AudioHub.play_one("needle")
	# Bed dots are entry cues; teach lock + technique live on the body-map overlay.
	if not GameFlow.acu_teach_unlocked(pid):
		if _hint:
			_hint.text = tr("ACU_TEACH_LOCK")
		_open_acu_body_map()
		return
	_open_acu_body_map()


func _on_fsm(state: String) -> void:
	match state:
		"clinic_idle":
			_switch_camera("CAM_HERO")
		"patient_selected", "examining", "treatment_choice", "revisit_consult":
			if GameFlow.exam_focus == "qie":
				_switch_camera("CAM_PULSE")
			elif _cam_name == "CAM_HERO":
				_switch_camera("CAM_ASK")
			if state == "revisit_consult" and GameFlow.current_patient_id != "":
				_seat_patient(GameFlow.current_patient_id)
				_apply_portraits()
		"formula_crafting":
			_switch_camera("CAM_FORMULA")
		"food_crafting":
			_switch_camera("CAM_ASK")
		"needling":
			_switch_camera("CAM_NEEDLE")
		"settling":
			_switch_camera("CAM_RESULT")
	_rebuild_dock()
	_refresh()
	_sync_revisit_badge()


func _on_settled(_result: Dictionary) -> void:
	_close_acu_body_map()
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
		_dock.offset_top = -260
		_dock.offset_right = 640
		_dock.offset_bottom = -36
		_dock.mouse_filter = Control.MOUSE_FILTER_STOP
		_dock.add_theme_stylebox_override("panel", UiKit.paper_style(UiKit.PAPER, UiKit.LINE, 4))
		hud.add_child(_dock)
	for c in _dock.get_children():
		c.queue_free()
	_chat = null
	_chat_scroll = null
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
		if DemoDay:
			DemoDay.ensure()
		var day_n := GameFlow.play_day() if GameFlow.has_method("play_day") else 1
		var day_lab := tr("DAY_PLAQUE")
		if day_lab == "DAY_PLAQUE" or day_lab == "":
			day_lab = "第 %d 日" % day_n
		else:
			day_lab = day_lab.replace("{n}", str(day_n))
		var day_row := HBoxContainer.new()
		day_row.add_theme_constant_override("separation", 8)
		var plaque_path := "res://ui/demo/day-plaque.png"
		if ResourceLoader.exists(plaque_path):
			var plaque_res = ResourceLoader.load(plaque_path)
			if plaque_res is Texture2D:
				var dp := TextureRect.new()
				dp.texture = plaque_res
				dp.custom_minimum_size = Vector2(36, 28)
				dp.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				dp.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				dp.mouse_filter = Control.MOUSE_FILTER_IGNORE
				day_row.add_child(dp)
		day_row.add_child(UiKit.ink_label(day_lab, 14, UiKit.SEAL))
		col.add_child(day_row)
		var slot_row := HBoxContainer.new()
		slot_row.add_theme_constant_override("separation", 10)
		for sid in ["morning", "afternoon", "evening", "night"]:
			var rem := DemoDay.slot_remaining(sid) if DemoDay else 1
			var lab_key := "SLOT_MORNING"
			match sid:
				"afternoon":
					lab_key = "SLOT_AFTERNOON"
				"evening":
					lab_key = "SLOT_DUSK"
				"night":
					lab_key = "SLOT_NIGHT"
			var sname := tr(lab_key)
			slot_row.add_child(UiKit.ink_label("%s%s" % [sname, ("·" if rem > 0 else "×")], 12, UiKit.SEAL if rem > 0 else UiKit.INK_MUTED))
		col.add_child(slot_row)
		col.add_child(UiKit.ink_label(tr("CLINIC_HINT"), 14, UiKit.INK_MUTED))
		if DemoDay and DemoDay.guide_enabled():
			var guide_box := VBoxContainer.new()
			guide_box.add_theme_constant_override("separation", 2)
			var gtitle := HBoxContainer.new()
			gtitle.add_child(UiKit.ink_label(tr("DEMO_GUIDE_TITLE"), 13, UiKit.SEAL))
			var dismiss := UiKit.make_button("DEMO_GUIDE_DISMISS", false)
			dismiss.pressed.connect(func() -> void:
				DemoDay.set_guide_dismissed(true)
				_rebuild_dock()
			)
			gtitle.add_child(dismiss)
			guide_box.add_child(gtitle)
			guide_box.add_child(UiKit.ink_label(tr("DEMO_GUIDE_HINT"), 11, UiKit.INK_MUTED))
			for sid2 in ["morning_consult", "afternoon_forage", "evening_process", "night_codex", "next_day_revisit"]:
				var done: bool = DemoDay.is_step_done(sid2) or (sid2 == "morning_consult" and DemoDay.is_step_done("treat"))
				var line := HBoxContainer.new()
				line.add_theme_constant_override("separation", 4)
				var check_res = null
				if done and ResourceLoader.exists("res://ui/demo/demo-check.png"):
					check_res = ResourceLoader.load("res://ui/demo/demo-check.png")
				if done and check_res is Texture2D:
					var ck := TextureRect.new()
					ck.texture = check_res
					ck.custom_minimum_size = Vector2(16, 16)
					ck.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
					ck.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
					ck.mouse_filter = Control.MOUSE_FILTER_IGNORE
					line.add_child(ck)
				else:
					line.add_child(UiKit.ink_label("✓" if done else "○", 12, UiKit.SEAL if done else UiKit.INK_MUTED))
				line.add_child(UiKit.ink_label(DemoDay.step_label(sid2), 12, UiKit.INK if done else UiKit.INK_MUTED))
				guide_box.add_child(line)
			col.add_child(guide_box)
		elif DemoDay and bool(DemoDay.guide().get("dismissed", false)):
			var show_b := UiKit.make_button("DEMO_GUIDE_SHOW", false)
			show_b.pressed.connect(func() -> void:
				DemoDay.set_guide_dismissed(false)
				_rebuild_dock()
			)
			col.add_child(show_b)
		var next_b := UiKit.make_button("NEXT_DAY", true)
		if next_b.text == "NEXT_DAY" or next_b.text == "":
			next_b.text = "次日开馆"
		next_b.pressed.connect(func() -> void: _do_next_day())
		col.add_child(next_b)
		var garden_b := UiKit.make_button("GARDEN_OPEN", true)
		var g_act: Dictionary = DemoDay.can_act("go_garden") if DemoDay else {"ok": true}
		garden_b.disabled = not bool(g_act.get("ok", true))
		if garden_b.disabled:
			garden_b.tooltip_text = tr(str(g_act.get("reason_key", "SLOT_EXHAUSTED_AFTERNOON")))
		garden_b.pressed.connect(func() -> void:
			if DemoDay and not bool(DemoDay.can_act("go_garden").get("ok", false)):
				return
			GameFlow.go_garden()
		)
		col.add_child(garden_b)
		var process_b := UiKit.make_button("PROCESS_OPEN", true)
		if process_b.text == "PROCESS_OPEN" or process_b.text == "":
			process_b.text = "去炮制院"
		var p_act: Dictionary = DemoDay.can_act("go_process") if DemoDay else {"ok": true}
		process_b.disabled = not bool(p_act.get("ok", true))
		if process_b.disabled:
			process_b.tooltip_text = tr(str(p_act.get("reason_key", "SLOT_EXHAUSTED_DUSK")))
		process_b.pressed.connect(func() -> void:
			if DemoDay and not bool(DemoDay.can_act("go_process").get("ok", false)):
				return
			GameFlow.go_process()
		)
		col.add_child(process_b)
		var loft_b := UiKit.make_button("NIGHT_READ_ENTER", true)
		if loft_b.text == "NIGHT_READ_ENTER" or loft_b.text == "":
			loft_b.text = "上阁楼"
		var l_act: Dictionary = DemoDay.can_act("go_loft") if DemoDay else {"ok": true}
		loft_b.disabled = not bool(l_act.get("ok", true))
		if loft_b.disabled:
			loft_b.tooltip_text = tr(str(l_act.get("reason_key", "SLOT_EXHAUSTED_NIGHT")))
			var rest_b := UiKit.make_button("EARLY_REST_TO_NIGHT", false)
			if rest_b.text.begins_with("EARLY_REST"):
				rest_b.text = "提前歇息进夜"
			rest_b.pressed.connect(func() -> void:
				if GameFlow.has_method("rest_into_night"):
					GameFlow.rest_into_night()
				_rebuild_dock()
			)
			col.add_child(rest_b)
		loft_b.pressed.connect(func() -> void: _do_go_loft())
		col.add_child(loft_b)
		# V136 optional 青石证印 wall entry
		var seal_b := UiKit.make_button("SEAL_WALL_TITLE", false)
		if seal_b.text == "SEAL_WALL_TITLE" or seal_b.text == "":
			seal_b.text = "青石证印"
		seal_b.pressed.connect(func() -> void: _show_seal_wall())
		col.add_child(seal_b)
		if not CaseDB.pharmacy_kid_is_clickable():
			if _xiaohe_idle_line == "":
				_xiaohe_idle_line = CaseDB.pharmacy_kid_line("waiting")
			if _xiaohe_idle_line != "":
				var xname := tr("XIAOHE_NAME")
				if xname == "" or xname == "XIAOHE_NAME":
					xname = "小荷"
				if has_method("_chrome_row"):
					col.add_child(_chrome_row("res://ui/chrome/xiahe-badge.png", "%s：%s" % [xname, _xiaohe_idle_line], UiKit.INK_MUTED))
				else:
					var bubble := UiKit.ink_label("%s：%s" % [xname, _xiaohe_idle_line], 13, UiKit.INK_MUTED)
					bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
					col.add_child(bubble)
		if not _revisit_taken:
			_revisit_taken = true
			if GameFlow.has_method("consume_revisit_line"):
				_revisit_idle_line = GameFlow.consume_revisit_line()
			elif GameFlow.has_method("pending_followup_line"):
				_revisit_idle_line = GameFlow.pending_followup_line()
		if _revisit_idle_line != "":
			col.add_child(UiKit.ink_label("%s：%s" % [tr("FOLLOWUP_TITLE"), _revisit_idle_line], 13, UiKit.SEAL))

	if st == "revisit_consult":
		_fill_revisit_dock(col)
	elif st in ["patient_selected", "examining", "treatment_choice"]:
		_fill_exam_dock(col)
	elif st == "formula_crafting":
		_fill_formula_dock(col)
	elif st == "food_crafting":
		_fill_food_dock(col)
	elif st == "needling":
		_fill_needle_dock(col)
	elif st == "settling":
		_fill_score_dock(col)


func _clue_lines(exam_id: String) -> PackedStringArray:
	if GameFlow.has_method("exam_clues"):
		return GameFlow.exam_clues(exam_id)
	return PackedStringArray()




func _show_seal_wall() -> void:
	## Optional V136 seal wall overlay (nine expand seals + count hint). Soft-load texture.
	var hud := get_node_or_null("UI/Hud") as Control
	if hud == null:
		return
	var existing := hud.get_node_or_null("SealWallOverlay")
	if existing:
		existing.queue_free()
		return
	var overlay := Panel.new()
	overlay.name = "SealWallOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	overlay.custom_minimum_size = Vector2(420, 480)
	overlay.offset_left = -210
	overlay.offset_right = 210
	overlay.offset_top = -240
	overlay.offset_bottom = 240
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_theme_stylebox_override("panel", UiKit.paper_style(UiKit.PAPER, UiKit.LINE, 6))
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 12
	v.offset_right = -12
	v.offset_top = 10
	v.offset_bottom = -10
	v.add_theme_constant_override("separation", 8)
	overlay.add_child(v)
	v.add_child(UiKit.ink_label(tr("SEAL_WALL_TITLE"), 18, UiKit.SEAL))
	var n := 0
	if GameFlow.has_method("get_seals"):
		n = GameFlow.get_seals().size()
	var hint := tr("SEAL_COUNT_HINT")
	if hint == "SEAL_COUNT_HINT" or hint == "":
		hint = "已亮 %d / 9 枚青石证印。不设小儿格。" % n
	else:
		hint = hint.replace("{n}", str(n))
	v.add_child(UiKit.ink_label(hint, 13, UiKit.INK_MUTED))
	var wall: Texture2D = CharacterArt.load_seal_wall() if CharacterArt else null
	if wall:
		var trc := TextureRect.new()
		trc.texture = wall
		trc.custom_minimum_size = Vector2(360, 360)
		trc.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		trc.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		trc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(trc)
	# Tiny grid of earned seals
	var grid := HFlowContainer.new()
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	v.add_child(grid)
	var wall_ids: Array = []
	if CaseDB.has_method("qingshi_expand3_rules"):
		var seals_cfg: Dictionary = CaseDB.qingshi_expand3_rules().get("seals", {})
		var ids_v: Variant = seals_cfg.get("seal_wall_ids", [])
		if typeof(ids_v) == TYPE_ARRAY:
			for x in ids_v:
				wall_ids.append(str(x))
	if wall_ids.is_empty():
		wall_ids = ["fengre_biao", "shiji", "pixu_shikun", "yangxu_weihan", "xueyu_qing", "shushi", "yinxu_zaoke", "shire_xiazhu", "waishang_zhongtong"]
	var earned: Array = GameFlow.get_seals() if GameFlow.has_method("get_seals") else []
	for cid in wall_ids:
		var cell := TextureRect.new()
		cell.custom_minimum_size = Vector2(36, 36)
		cell.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		cell.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var tex: Texture2D = CharacterArt.load_seal(str(cid))
		if tex and str(cid) in earned:
			cell.texture = tex
			cell.modulate = Color(1, 1, 1, 1)
		elif tex:
			cell.texture = tex
			cell.modulate = Color(1, 1, 1, 0.22)
		cell.tooltip_text = tr("SEAL_%s" % str(cid).to_upper())
		grid.add_child(cell)
	var close_b := UiKit.make_button("ACTION_BACK", false)
	if close_b.text.begins_with("ACTION_"):
		close_b.text = "收起"
	close_b.pressed.connect(func() -> void:
		if is_instance_valid(overlay):
			overlay.queue_free()
	)
	v.add_child(close_b)
	hud.add_child(overlay)


func _chrome_row(tex_path: String, text: String, color: Color) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(tex_path):
		var tr := TextureRect.new()
		tr.texture = load(tex_path)
		tr.custom_minimum_size = Vector2(28, 28)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(tr)
	var lab := UiKit.ink_label(text, 13, color)
	lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(lab)
	return row



func _sync_revisit_badge() -> void:
	## Small 复诊章 on seated patient Portrait during revisit_consult.
	var chars := get_node_or_null("L5_characters")
	if chars == null:
		return
	for i in range(3):
		var node := chars.get_node_or_null("Patient%d" % i) as Node2D
		if node == null:
			continue
		var badge := node.get_node_or_null("RevisitBadge") as Sprite2D
		var show := GameFlow.is_revisit_visit and str(GameFlow.fsm_state) == "revisit_consult" and str(node.get_meta("pid", "")) == GameFlow.current_patient_id
		if show:
			if badge == null:
				badge = Sprite2D.new()
				badge.name = "RevisitBadge"
				badge.z_index = 20
				badge.centered = true
				badge.position = Vector2(48, -90)
				badge.scale = Vector2(0.22, 0.22)
				if ResourceLoader.exists("res://ui/chrome/revisit-badge.png"):
					badge.texture = load("res://ui/chrome/revisit-badge.png")
				node.add_child(badge)
			badge.visible = true
		elif badge:
			badge.visible = false



func _ensure_loft_nodes() -> void:
	## V129: CAM_LOFT + loft hotspot (clinic corner entry).
	if not has_node("CAM_LOFT"):
		var cam := Camera2D.new()
		cam.name = "CAM_LOFT"
		cam.position = Vector2(420, 360)
		cam.zoom = Vector2(1.15, 1.15)
		cam.enabled = false
		add_child(cam)
	var areas := get_node_or_null("Areas")
	if areas and not areas.has_node("Area_阁楼"):
		var area := Area2D.new()
		area.name = "Area_阁楼"
		area.position = Vector2(360, 520)
		var cs := CollisionShape2D.new()
		var circ := CircleShape2D.new()
		circ.radius = 70.0
		cs.shape = circ
		area.add_child(cs)
		areas.add_child(area)


func _do_go_loft() -> void:
	if str(GameFlow.fsm_state) != "clinic_idle":
		return
	var r: Dictionary = {}
	if GameFlow.has_method("go_loft"):
		r = GameFlow.go_loft()
	elif Codex:
		r = Codex.try_go_loft()
	if not bool(r.get("ok", false)):
		_rebuild_dock()


func _do_rest_into_night() -> void:
	if str(GameFlow.fsm_state) != "clinic_idle":
		return
	if GameFlow.has_method("rest_into_night"):
		GameFlow.rest_into_night()
	elif Codex:
		Codex.rest_into_night()


func _do_next_day() -> void:
	if str(GameFlow.fsm_state) != "clinic_idle":
		return
	if ResourceLoader.exists("res://other-systems/audio/open-day.ogg"):
		AudioHub.play_one("open-day")
	else:
		AudioHub.play_chime()
	_revisit_idle_line = ""
	_revisit_taken = false
	var pulled: Dictionary = {}
	if GameFlow.has_method("advance_clinic_day"):
		pulled = GameFlow.advance_clinic_day()
	if not pulled.is_empty() and GameFlow.current_patient_id != "":
		_seat_patient(GameFlow.current_patient_id)
		_apply_portraits()
	_rebuild_dock()
	_refresh()
	_sync_revisit_badge()


func _revisit_flavor_color(kind: String) -> Color:
	## Light course tint — aligns with revisit-flavor-chrome (good/slow/over/mis).
	match kind:
		"good":
			return Color(0.22, 0.55, 0.38, 1)
		"slow":
			return Color(0.55, 0.42, 0.22, 1)
		"over":
			return Color(0.78, 0.35, 0.32, 1)
		_:
			return Color(0.35, 0.45, 0.55, 1)


func _fill_revisit_dock(col: VBoxContainer) -> void:
	var hud := CaseDB.hud_card(GameFlow.current_patient_id)
	var badge := tr("REVISIT_BADGE")
	if badge == "REVISIT_BADGE" or badge == "":
		badge = "复诊"
	var fk := "good"
	if typeof(GameFlow.active_revisit) == TYPE_DICTIONARY:
		fk = str(GameFlow.active_revisit.get("flavor_kind", "good"))
	var title := "%s · %s" % [str(hud.get("name", GameFlow.current_patient_id)), badge]
	col.add_child(_chrome_row("res://ui/chrome/revisit-badge.png", title, _revisit_flavor_color(fk)))
	var flavor_lab := tr("REVISIT_FLAVOR_%s" % fk.to_upper())
	if flavor_lab.begins_with("REVISIT_FLAVOR_"):
		match fk:
			"good":
				flavor_lab = "向愈"
			"slow":
				flavor_lab = "迁延"
			"over":
				flavor_lab = "过治不适"
			_:
				flavor_lab = "好像没对上"
	var course := tr("REVISIT_COURSE")
	if course == "REVISIT_COURSE" or course == "":
		course = "病程"
	col.add_child(UiKit.ink_label("%s：%s" % [course, flavor_lab], 12, _revisit_flavor_color(fk)))
	var chief := ""
	if GameFlow.has_method("revisit_chief_line"):
		chief = GameFlow.revisit_chief_line()
	if chief == "" and typeof(GameFlow.active_revisit) == TYPE_DICTIONARY:
		chief = CaseDB.revisit_chief_complaint(GameFlow.current_patient_id, fk)
	if chief != "":
		col.add_child(UiKit.ink_label(chief, 14))
	else:
		col.add_child(UiKit.ink_label(tr("REVISIT_STUB"), 14, UiKit.INK_MUTED))
	var hint := tr("REVISIT_HINT")
	if hint != "" and hint != "REVISIT_HINT":
		col.add_child(UiKit.ink_label(hint, 12, UiKit.INK_MUTED))
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
		_open_acu_body_map()
	)
	row.add_child(nb)
	var food_b := UiKit.make_button("ACTION_FOOD", true)
	if food_b.text == "ACTION_FOOD" or food_b.text == "":
		food_b.text = "食疗"
	food_b.pressed.connect(func() -> void:
		if GameFlow.has_method("open_food"):
			GameFlow.open_food()
		elif GameFlow.has_method("enter_food"):
			GameFlow.enter_food()
			get_tree().change_scene_to_file("res://scenes/food.tscn")
	)
	row.add_child(food_b)
	var emo_b := UiKit.make_button("ACTION_EMOTION", true)
	if emo_b.text == "ACTION_EMOTION" or emo_b.text == "":
		emo_b.text = "情志"
	emo_b.pressed.connect(func() -> void:
		if GameFlow.has_method("open_emotion"):
			GameFlow.open_emotion()
		elif GameFlow.has_method("enter_emotion"):
			GameFlow.enter_emotion()
			get_tree().change_scene_to_file("res://scenes/emotion.tscn")
	)
	row.add_child(emo_b)
	var ob := UiKit.make_button("REVISIT_OBSERVE", true)
	if ob.text == "REVISIT_OBSERVE" or ob.text == "":
		ob.text = "观察勿药"
	ob.pressed.connect(func() -> void:
		if GameFlow.has_method("settle_observe"):
			GameFlow.settle_observe()
	)
	row.add_child(ob)


func _fill_exam_dock(col: VBoxContainer) -> void:
	var hud := CaseDB.hud_card(GameFlow.current_patient_id)
	col.add_child(UiKit.ink_label(str(hud.get("name", "")), 16))
	var marks := []
	for eid in ["wang", "wen_listen", "wen_ask", "qie"]:
		marks.append("●" if GameFlow.exam_done(eid) else "○")
	col.add_child(UiKit.ink_label("望%s 闻%s 问%s 切%s" % marks, 13, UiKit.INK_MUTED))
	var mentor_line := ""
	if GameFlow.has_method("take_mentor_line"):
		mentor_line = GameFlow.take_mentor_line()
	else:
		mentor_line = CaseDB.mentor_cue_for_visit()
	if mentor_line != "" and not CaseDB.mentor_is_clickable():
		var who := CaseDB.mentor_name()
		if who == "":
			who = "苏问舟"
		col.add_child(_chrome_row("res://ui/chrome/mentor-bubbles.png", "%s：%s" % [who, mentor_line], UiKit.SEAL))
		if Codex and Codex.has_theory("theory.hanre_xushi"):
			var note := Codex.hanre_note()
			if note != "":
				col.add_child(UiKit.ink_label(note, 12, UiKit.INK_MUTED))
		if GameFlow.has_method("consume_mentor_chime") and GameFlow.consume_mentor_chime():
			if "这一问有了" in mentor_line:
				AudioHub.play_one("stamp-ok")
			else:
				AudioHub.play_chime()
		_last_mentor_shown = mentor_line
	var focus := str(GameFlow.exam_focus)
	if focus == "qie":
		# Text clues only. Art team owns 脉纹 on the pillow; no pulse.tscn / encyclopedia.
		var pulse_meta: Dictionary = GameFlow.pulse_for_current() if GameFlow.current_patient_id != "" else {}
		var pid_pulse := str(pulse_meta.get("id", ""))
		if Codex and Codex.has_theory("theory.pulse_names"):
			var std := Codex.pulse_standard_name(pid_pulse)
			if std != "":
				col.add_child(UiKit.ink_label("%s · %s" % [std, Codex.pulse_desc(pid_pulse)], 14, UiKit.SEAL))
			else:
				col.add_child(UiKit.ink_label(tr("THEORY_PULSE_NAMES"), 13, UiKit.SEAL))
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
		_open_acu_body_map()
	)
	row.add_child(nb)
	var food_b := UiKit.make_button("ACTION_FOOD", true)
	if food_b.text == "ACTION_FOOD" or food_b.text == "":
		food_b.text = "食疗"
	food_b.pressed.connect(func() -> void:
		if GameFlow.has_method("open_food"):
			GameFlow.open_food()
	)
	row.add_child(food_b)
	var emo_b := UiKit.make_button("ACTION_EMOTION", true)
	if emo_b.text == "ACTION_EMOTION" or emo_b.text == "":
		emo_b.text = "情志"
	emo_b.pressed.connect(func() -> void:
		if GameFlow.has_method("open_emotion"):
			GameFlow.open_emotion()
	)
	row.add_child(emo_b)



func _fill_ask_dock(col: VBoxContainer) -> void:
	var scroll := ScrollContainer.new()
	scroll.name = "ChatScroll"
	scroll.custom_minimum_size = Vector2(0, 70)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(scroll)
	_chat_scroll = scroll
	_chat = VBoxContainer.new()
	_chat.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_chat)
	for turn in GameFlow.conversation:
		if typeof(turn) != TYPE_DICTIONARY:
			continue
		var d: Dictionary = turn
		_append_chat(str(d.get("q", "")), str(d.get("a", "")))
	_scroll_chat_to_bottom()
	# 「十问」shortcut bar — song labels from ten_questions.json; no encyclopedia.
	col.add_child(UiKit.ink_label(tr("TENQ_BAR_TITLE"), 12, UiKit.INK_MUTED))
	if Codex and Codex.has_theory("theory.tenq_song"):
		var quote := Codex.tenq_quote()
		if quote != "":
			col.add_child(UiKit.ink_label(quote, 12, UiKit.SEAL))
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
	_scroll_chat_to_bottom()


func _scroll_chat_to_bottom() -> void:
	## Haopeng: always stick to latest line (force).
	if _chat_scroll == null or not is_instance_valid(_chat_scroll):
		return
	var scroll := _chat_scroll
	# Defer one frame so content min-size is known.
	scroll.set_deferred("scroll_vertical", 1 << 30)
	call_deferred("_force_chat_scroll_now")


func _force_chat_scroll_now() -> void:
	if _chat_scroll == null or not is_instance_valid(_chat_scroll):
		return
	UiKit.force_scroll_bottom(_chat_scroll)


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
	var kid := CaseDB.pharmacy_kid_line("cabinet")
	var xname := tr("XIAOHE_NAME")
	if xname == "" or xname == "XIAOHE_NAME":
		xname = "小荷"
	var alert := tr("XIAOHE_FANWEI_ALERT")
	if alert == "XIAOHE_FANWEI_ALERT":
		alert = kid
	if _hint:
		if kid != "":
			_hint.text = "%s  %s：%s" % [reason, xname, kid]
		else:
			_hint.text = reason
	_rebuild_dock()



func _fill_food_dock(col: VBoxContainer) -> void:
	col.add_child(UiKit.ink_label(tr("FOOD_HINT"), 13, UiKit.INK_MUTED))
	var names: Array[String] = []
	for fid in GameFlow.food_tray:
		names.append(CaseDB.food_name(str(fid)))
	col.add_child(UiKit.ink_label(("、".join(PackedStringArray(names)) if names else tr("FOOD_BOWL_EMPTY")) + (" · %s" % GameFlow.lifestyle_cue if GameFlow.lifestyle_cue != "" else ""), 14))
	var row := HBoxContainer.new()
	col.add_child(row)
	var open_b := UiKit.make_button("FOOD_ENTER", true)
	open_b.pressed.connect(func() -> void:
		if GameFlow.has_method("open_food"):
			GameFlow.open_food()
		else:
			get_tree().change_scene_to_file("res://scenes/food.tscn")
	)
	row.add_child(open_b)
	var ok := UiKit.make_button("FOOD_SUBMIT", true)
	ok.disabled = not GameFlow.can_confirm_food()
	ok.pressed.connect(func() -> void: GameFlow.confirm_food())
	row.add_child(ok)
	var back := UiKit.make_button("TREAT_BACK")
	back.pressed.connect(func() -> void:
		GameFlow.open_treatment()
		_switch_camera("CAM_ASK")
		_rebuild_dock()
	)
	row.add_child(back)


func _fill_formula_dock(col: VBoxContainer) -> void:
	col.add_child(UiKit.ink_label(tr("FORMULA_HINT"), 13, UiKit.INK_MUTED))
	if GameFlow.has_method("take_mentor_line"):
		var mline := GameFlow.take_mentor_line()
		if mline != "" and not CaseDB.mentor_is_clickable():
			var mwho := CaseDB.mentor_name()
			if mwho == "":
				mwho = "苏问舟"
			col.add_child(UiKit.ink_label("%s：%s" % [mwho, mline], 12, UiKit.SEAL))
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
	col.add_child(UiKit.ink_label(tr("ACU_BODY_HINT"), 13, UiKit.INK_MUTED))
	col.add_child(UiKit.ink_label(tr("ACU_TEACH_ONLY"), 12, UiKit.INK_MUTED))
	var names: Array[String] = []
	for pid in GameFlow.acu_practiced:
		names.append(GameFlow.loc_text(GameFlow.points_by_id.get(str(pid), {}), str(pid)))
	if names.is_empty():
		for pid in GameFlow.selected_points:
			names.append(GameFlow.loc_text(GameFlow.points_by_id.get(str(pid), {}), str(pid)))
	col.add_child(UiKit.ink_label("、".join(PackedStringArray(names)) if names else "—", 14))
	var row := HBoxContainer.new()
	col.add_child(row)
	var map_btn := UiKit.make_button("ACU_ENTER", true)
	map_btn.pressed.connect(func() -> void: _open_acu_body_map())
	row.add_child(map_btn)
	var ok := UiKit.make_button("ACU_SUBMIT", true)
	ok.disabled = not GameFlow.can_confirm_needling()
	ok.pressed.connect(func() -> void:
		_close_acu_body_map()
		GameFlow.confirm_needling()
	)
	row.add_child(ok)
	var back := UiKit.make_button("TREAT_BACK")
	back.pressed.connect(func() -> void:
		_close_acu_body_map()
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
	var flav: Variant = r.get("flavor", "")
	var flav_s := GameFlow.loc_text(flav, "") if typeof(flav) == TYPE_DICTIONARY else str(flav)
	col.add_child(UiKit.ink_label(flav_s, 14, UiKit.INK_MUTED))
	# Explicit M  xx
	var m_raw := float(r.get("M", r.get("score", 0.0)))
	var m_pct := int(round(m_raw * 100.0)) if m_raw <= 1.0001 else int(round(m_raw))
	col.add_child(UiKit.ink_label("M  %d" % m_pct, 15, UiKit.SEAL))
	var chips := Scoring.axis_chips(r)
	if chips != "":
		col.add_child(UiKit.ink_label(chips, 12, UiKit.INK_MUTED))
	var lab_c := tr("SCORE_C_STAR")
	if lab_c == "SCORE_C_STAR":
		lab_c = "覆盖 C*"
	var lab_b := tr("SCORE_B_DIM")
	if lab_b == "SCORE_B_DIM":
		lab_b = "方证 B"
	var lab_a := tr("SCORE_A_PRIME")
	if lab_a == "SCORE_A_PRIME":
		lab_a = "加减 A'"
	var lab_u := tr("SCORE_U_DIM")
	if lab_u == "SCORE_U_DIM":
		lab_u = "结构 U"
	var comps := "%s %.2f · %s %.2f · %s %.2f · %s %.2f" % [
		lab_c, float(r.get("C_star", 0.0)),
		lab_b, float(r.get("B", 0.0)),
		lab_a, float(r.get("A_prime", r.get("A", 0.0))),
		lab_u, float(r.get("U", 0.0)),
	]
	col.add_child(UiKit.ink_label(comps, 12, UiKit.INK_MUTED))
	var fu := str(r.get("followup", "")).strip_edges()
	if fu == "" and GameFlow.has_method("pending_followup_line"):
		fu = GameFlow.pending_followup_line()
	if fu == "" and GameFlow.current_patient_id != "":
		fu = CaseDB.followup_template(GameFlow.current_patient_id)
	if fu != "":
		col.add_child(UiKit.ink_label("%s：%s" % [tr("FOLLOWUP_TITLE"), fu], 13, UiKit.SEAL))
		var seal_line := str(GameFlow.last_result.get("seal_flash", "")).strip_edges()
		var seal_id := str(GameFlow.last_result.get("seal_id", "")).strip_edges()
		if seal_line == "" and seal_id != "" and CaseDB.has_method("seal_flash_line"):
			seal_line = CaseDB.seal_flash_line(seal_id)
		if seal_line != "":
			col.add_child(UiKit.ink_label(seal_line, 14, UiKit.SEAL))
	if DemoDay:
		var hop := DemoDay.next_hop_text()
		if hop != "":
			col.add_child(UiKit.ink_label(hop, 13, UiKit.SEAL))
	var nxt := UiKit.make_button("SLICE_DONE" if GameFlow.slice_complete() else "UI_BACK", true)
	nxt.pressed.connect(func() -> void:
		_xiaohe_idle_line = ""
		_revisit_idle_line = ""
		_revisit_taken = false
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
	# Top bar: title + day — waiting cards sit below so they never cover title/narration.
	var top := HBoxContainer.new()
	top.name = "TopBar"
	top.position = Vector2(24, 8)
	top.size = Vector2(1232, 40)
	top.mouse_filter = Control.MOUSE_FILTER_STOP
	top.add_theme_constant_override("separation", 12)
	bar.add_child(top)
	_title = UiKit.ink_label(UiKit.store_title_text(), 20, UiKit.INK, false)
	_title.name = "GameTitle"
	top.add_child(_title)
	var day_n := GameFlow.play_day() if GameFlow.has_method("play_day") else 1
	var day_lab := tr("DAY_PLAQUE")
	if day_lab == "DAY_PLAQUE" or day_lab == "":
		day_lab = UiKit.tr_or("SAVE_SLOT_DAY", "第 {n} 日").replace("{n}", str(day_n))
	else:
		day_lab = day_lab.replace("{n}", str(day_n))
	_day_top = UiKit.ink_label(day_lab, 14, UiKit.SEAL, false)
	_day_top.name = "DayTop"
	top.add_child(_day_top)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(sp)
	# Single settings gear (language / save / load live inside the panel).
	var gear := UiKit.make_settings_gear_button()
	gear.pressed.connect(func() -> void:
		_set_settings_open(not GameFlow.settings_open)
	)
	top.add_child(gear)
	# Waiting A–D cards: dedicated strip under title (no overlap with title or bottom dock).
	var row := HBoxContainer.new()
	row.name = "Patients"
	row.position = Vector2(24, 56)
	row.size = Vector2(900, 64)
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_STOP
	bar.add_child(row)
	var seats_hud: Array = _waiting_list()
	for i in seats_hud.size():
		var p: Dictionary = seats_hud[i]
		var pid := str(p.get("id", ""))
		var card := Button.new()
		card.name = pid
		card.custom_minimum_size = Vector2(170, 56) if seats_hud.size() >= 4 else Vector2(200, 56)
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
	_hint.position = Vector2(24, 128)
	_hint.size = Vector2(900, 24)
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(_hint)
	# Unified nav strip (decoupled from language): garden + process.
	_nav_strip = HBoxContainer.new()
	_nav_strip.name = "NavStrip"
	_nav_strip.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_nav_strip.anchor_left = 1.0
	_nav_strip.anchor_top = 1.0
	_nav_strip.anchor_right = 1.0
	_nav_strip.anchor_bottom = 1.0
	_nav_strip.offset_left = -320
	_nav_strip.offset_top = -70
	_nav_strip.offset_right = -24
	_nav_strip.offset_bottom = -28
	_nav_strip.add_theme_constant_override("separation", 8)
	_nav_strip.mouse_filter = Control.MOUSE_FILTER_STOP
	bar.add_child(_nav_strip)
	var garden_hud := UiKit.make_button("GARDEN_OPEN", false)
	garden_hud.name = "GardenOpen"
	garden_hud.pressed.connect(func() -> void:
		if str(GameFlow.fsm_state) == "clinic_idle":
			GameFlow.go_garden()
	)
	_nav_strip.add_child(garden_hud)
	var process_hud := UiKit.make_button("PROCESS_ENTER", false)
	if process_hud.text == "PROCESS_ENTER" or process_hud.text == "":
		process_hud.text = UiKit.tr_or("PROCESS_OPEN", UiKit.tr_or("PROCESS_ENTER", "去炮制院"))
		process_hud.set_meta("i18n_key", "PROCESS_ENTER")
	process_hud.name = "ProcessOpen"
	process_hud.pressed.connect(func() -> void:
		if str(GameFlow.fsm_state) == "clinic_idle":
			GameFlow.go_process()
	)
	_nav_strip.add_child(process_hud)
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
	_ensure_settings_overlay(hud)


func _ensure_settings_overlay(hud: Control) -> void:
	if _settings_root != null and is_instance_valid(_settings_root):
		return
	_settings_root = Control.new()
	_settings_root.name = "SettingsOverlay"
	_settings_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_settings_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_settings_root.visible = false
	_settings_root.z_index = 80
	hud.add_child(_settings_root)
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
		_rebuild_dock()
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



func _paint_hint() -> void:
	if _hint == null:
		return
	if GameFlow.slice_complete():
		_hint.text = tr("DONE_ALL")
		return
	match _hover:
		"pulse":
			_hint.text = tr("HINT_PULSE")
		"loft":
			var ht := tr("NIGHT_READ_ENTER")
			_hint.text = ht if ht != "NIGHT_READ_ENTER" else "上阁楼"
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
		"door":
			var nd := tr("NEXT_DAY")
			_hint.text = nd if nd != "NEXT_DAY" else "次日开馆"
		_:
			if str(GameFlow.fsm_state) == "clinic_idle":
				var fu2 := GameFlow.pending_followup_line() if GameFlow.has_method("pending_followup_line") else ""
				if fu2 != "":
					_hint.text = "%s：%s" % [tr("FOLLOWUP_TITLE"), fu2]
				elif _xiaohe_idle_line != "":
					_hint.text = "%s：%s" % [tr("XIAOHE_NAME"), _xiaohe_idle_line]
				else:
					_hint.text = tr("CLINIC_HINT")
			else:
				_hint.text = tr("CLINIC_HINT")


func _refresh() -> void:
	if str(GameFlow.fsm_state) == "clinic_idle" and GameFlow.has_method("refresh_waiting_seats"):
		# Keep seats; only force rebuild labels/portraits from current waiting_seat_ids
		pass
	if _title:
		_title.text = UiKit.store_title_text()
	if _day_top:
		var day_n2 := GameFlow.play_day() if GameFlow.has_method("play_day") else 1
		var day_lab2 := tr("DAY_PLAQUE")
		if day_lab2 == "DAY_PLAQUE" or day_lab2 == "":
			day_lab2 = UiKit.tr_or("SAVE_SLOT_DAY", "第 {n} 日").replace("{n}", str(day_n2))
		else:
			day_lab2 = day_lab2.replace("{n}", str(day_n2))
		_day_top.text = day_lab2
	if _settings_root and is_instance_valid(_settings_root):
		_settings_root.visible = GameFlow.settings_open
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
				var badge := tr("REVISIT_BADGE")
				if badge == "REVISIT_BADGE":
					badge = "复诊"
				var is_rev := bool(GameFlow.is_revisit_visit) and str(GameFlow.current_patient_id) == pid
				if is_rev:
					n.text = "%s · %s" % [idn, badge]
				elif GameFlow.is_seen(pid):
					n.text = "%s · %s" % [idn, tr("UI_SEEN")]
				else:
					n.text = idn
		var is_rev_card := bool(GameFlow.is_revisit_visit) and str(GameFlow.current_patient_id) == pid
		(card as Button).disabled = GameFlow.is_seen(pid) and not is_rev_card
