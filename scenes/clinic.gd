extends Node2D
## One-room ink clinic (SCENE-SLICE). Not a second map. Play loop stays GameFlow.

const WORLD := Vector2(2560, 1440)
const HERB_SNAP := 40.0
const BED_RECT := Rect2(320, 820, 420, 160)
const FORMULA_RECT := Rect2(1720, 780, 400, 180)
const DRAWER_ORIGIN := Vector2(1752, 680)
const DRAWER_CELL := Vector2(72, 56)
const DRAWER_COLS := 8
const DRAWER_ROWS := 6
const HERO_DEADZONE := 200.0
const WALK_SPEED := 260.0

const ACU_NORM := {
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

var _cam_name := "CAM_HERO"
var _click_target := Vector2.INF
var _drag_herb := ""
var _drag_from := Vector2.ZERO
var _hover := ""
var _hint: Label
var _title: Label
var _foot: Label

@onready var _apprentice: CharacterBody2D = $World/YSort/Apprentice
@onready var _ysort: Node2D = $World/YSort
@onready var _drawers: Node2D = $World/Interact/Drawers
@onready var _formula_area: Area2D = $World/Interact/AreaFormula
@onready var _hud: CanvasLayer = $HUD


func _ready() -> void:
	AudioHub.enter_clinic()
	_paint_apprentice()
	_spawn_patients()
	_spawn_drawers()
	_spawn_bed_points()
	_build_hud()
	_wire_hotspots()
	_switch_camera("CAM_HERO")
	GameFlow.locale_changed.connect(_refresh)
	_refresh()


func _physics_process(delta: float) -> void:
	if _apprentice == null:
		return
	var axis := Vector2(Input.get_axis("ui_left", "ui_right"), Input.get_axis("ui_up", "ui_down"))
	if axis.length() > 0.1:
		_click_target = Vector2.INF
		_apprentice.velocity = axis.normalized() * WALK_SPEED
	elif _click_target != Vector2.INF:
		var to := _click_target - _apprentice.global_position
		if to.length() < 12.0:
			_click_target = Vector2.INF
			_apprentice.velocity = Vector2.ZERO
		else:
			_apprentice.velocity = to.normalized() * WALK_SPEED
	else:
		_apprentice.velocity = Vector2.ZERO
	_apprentice.move_and_slide()
	if _cam_name == "CAM_HERO":
		_follow_hero(delta)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var world := get_global_mouse_position()
		if event.pressed:
			if _drag_herb == "":
				_click_target = world
		else:
			if _drag_herb != "":
				_drop_herb(world)
	elif event is InputEventMouseMotion and _drag_herb != "":
		queue_redraw()


func _draw() -> void:
	if _drag_herb == "":
		return
	var p := get_global_mouse_position()
	draw_circle(p, 10.0, Color(0.45, 0.28, 0.18, 0.85))
	draw_circle(p, HERB_SNAP, Color(0.45, 0.28, 0.18, 0.12))


func _follow_hero(_delta: float) -> void:
	var cam := get_node_or_null("CAM_HERO") as Camera2D
	if cam == null or _apprentice == null:
		return
	var delta_pos := _apprentice.global_position - cam.global_position
	if delta_pos.length() > HERO_DEADZONE:
		cam.global_position = cam.global_position.lerp(_apprentice.global_position, 0.08)
	var half := Vector2(960, 540)
	cam.position.x = clampf(cam.position.x, half.x, WORLD.x - half.x)
	cam.position.y = clampf(cam.position.y, half.y, WORLD.y - half.y)


func _switch_camera(cam_name: String) -> void:
	_cam_name = cam_name
	for n in ["CAM_HERO", "CAM_ASK", "CAM_PULSE", "CAM_FORMULA", "CAM_NEEDLE", "CAM_RESULT"]:
		var cam := get_node_or_null(n) as Camera2D
		if cam == null:
			continue
		if n == cam_name:
			cam.enabled = true
			cam.make_current()
		else:
			cam.enabled = false


func _wire_hotspots() -> void:
	for area in $World/Interact.get_children():
		if area is Area2D:
			_hook_area(area)
	if has_node("World/BedRect/Hit"):
		_hook_area($World/BedRect/Hit)


func _hook_area(area: Area2D) -> void:
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


func _on_hotspot_input(_viewport: Node, event: InputEvent, _shape_idx: int, area: Area2D) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var kind := str(area.get_meta("hotspot", ""))
	if kind == "drawer":
		_on_drawer(area)
		get_viewport().set_input_as_handled()
		return
	if kind == "acupoint":
		_on_bed_point(area)
		get_viewport().set_input_as_handled()
		return
	_handle_hotspot(kind)
	get_viewport().set_input_as_handled()


func _handle_hotspot(kind: String) -> void:
	match kind:
		"door":
			_switch_camera("CAM_HERO")
			_pick_patient_at(2)
		"stool_a":
			_switch_camera("CAM_ASK")
			_pick_patient_at(0)
		"stool_b":
			_switch_camera("CAM_ASK")
			_pick_patient_at(1)
		"chair":
			_switch_camera("CAM_ASK")
			if GameFlow.current_patient_id != "":
				GameFlow.mark_exam("wen_ask")
		"pulse":
			# Camera + four-exam notify only. No encyclopedia. No pulse-wave art.
			_switch_camera("CAM_PULSE")
			if GameFlow.current_patient_id != "":
				GameFlow.mark_exam("qie")
		"incense":
			if GameFlow.current_patient_id != "":
				GameFlow.mark_exam("wen_listen")
		"window2":
			if GameFlow.current_patient_id != "":
				GameFlow.mark_exam("wang")
		"formula":
			_switch_camera("CAM_FORMULA")
			if GameFlow.current_patient_id != "":
				GameFlow.open_formula()
		"needle":
			AudioHub.play_one("needle")
			_switch_camera("CAM_NEEDLE")
			if GameFlow.current_patient_id != "":
				GameFlow.open_needling()


func _pick_patient_at(index: int) -> void:
	if index < 0 or index >= CaseDB.patients.size():
		return
	var pid := str(CaseDB.patients[index].get("id", ""))
	_on_pick(pid)


func _on_pick(pid: String) -> void:
	if pid == "" or GameFlow.is_seen(pid):
		return
	AudioHub.play_one("ui-paper")
	_seat_patient(pid)
	GameFlow.start_patient(pid)


func _on_drawer(area: Area2D) -> void:
	AudioHub.play_one("drawer")
	var closed: Vector2 = area.get_meta("closed_pos", area.position)
	var open_pos := closed + Vector2(0, 28)
	var tw := create_tween()
	tw.tween_property(area, "position", open_pos, 0.12)
	var hid := str(area.get_meta("herb_id", ""))
	if hid != "":
		_drag_herb = hid
		_drag_from = area.global_position
		queue_redraw()


func _drop_herb(world: Vector2) -> void:
	var hid := _drag_herb
	_drag_herb = ""
	queue_redraw()
	if hid == "":
		return
	var table := FORMULA_RECT.grow(HERB_SNAP)
	var near_center := world.distance_to(_formula_area.global_position) <= HERB_SNAP
	if table.has_point(world) or near_center:
		AudioHub.play_one("herb-drop")
		_switch_camera("CAM_FORMULA")


func _on_bed_point(_area: Area2D) -> void:
	AudioHub.play_one("needle")
	_switch_camera("CAM_NEEDLE")
	# Points live in BED_RECT. Treatment path stays GameFlow.open_needling.


func _paint_apprentice() -> void:
	if _apprentice == null:
		return
	_apprentice.y_sort_enabled = true
	var body := Polygon2D.new()
	body.name = "Ink"
	body.color = Color(0.28, 0.26, 0.22, 0.92)
	body.polygon = PackedVector2Array([
		Vector2(-22, 0), Vector2(22, 0), Vector2(16, -70), Vector2(18, -150),
		Vector2(8, -210), Vector2(0, -280), Vector2(-8, -210), Vector2(-18, -150),
		Vector2(-16, -70),
	])
	_apprentice.add_child(body)


func _spawn_patients() -> void:
	var feet := [
		Vector2(405, 290),
		Vector2(545, 290),
		Vector2(220, 360),
	]
	var tints := [
		Color(0.55, 0.5, 0.46, 1),
		Color(0.34, 0.3, 0.28, 1),
		Color(0.62, 0.5, 0.46, 1),
	]
	for i in CaseDB.patients.size():
		var p: Dictionary = CaseDB.patients[i]
		var n := Node2D.new()
		n.name = "Patient_%s" % str(p.get("id", i))
		n.position = feet[i % feet.size()]
		n.y_sort_enabled = true
		n.set_meta("pid", str(p.get("id", "")))
		n.set_meta("home", n.position)
		var sil := Polygon2D.new()
		sil.color = tints[i % tints.size()]
		sil.polygon = PackedVector2Array([
			Vector2(-24, 0), Vector2(24, 0), Vector2(18, -60), Vector2(14, -140),
			Vector2(6, -200), Vector2(0, -250), Vector2(-6, -200), Vector2(-14, -140),
			Vector2(-18, -60),
		])
		n.add_child(sil)
		var lb := Label.new()
		lb.name = "Name"
		lb.position = Vector2(-48, -278)
		lb.size = Vector2(96, 24)
		lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lb.add_theme_color_override("font_color", UiKit.INK)
		UiKit.apply_font(lb, 13)
		lb.text = UiKit.loc_text(p.get("name", {}), str(p.get("id", "")))
		n.add_child(lb)
		_ysort.add_child(n)


func _seat_patient(pid: String) -> void:
	var chair := Vector2(1040, 590)
	for n in _ysort.get_children():
		if str(n.get_meta("pid", "")) == pid:
			var tw := create_tween()
			tw.tween_property(n, "position", chair, 0.35)


func _spawn_drawers() -> void:
	var herbs: Array = CaseDB.pack.get("herbs", [])
	var shape := RectangleShape2D.new()
	shape.size = DRAWER_CELL
	for row in DRAWER_ROWS:
		for col in DRAWER_COLS:
			var idx := row * DRAWER_COLS + col
			var area := Area2D.new()
			area.name = "Drawer_%d_%d" % [col, row]
			area.position = DRAWER_ORIGIN + Vector2(col * DRAWER_CELL.x + DRAWER_CELL.x * 0.5, row * DRAWER_CELL.y + DRAWER_CELL.y * 0.5)
			area.input_pickable = true
			area.collision_layer = 2
			area.collision_mask = 0
			area.set_meta("hotspot", "drawer")
			area.set_meta("closed_pos", area.position)
			var hid := ""
			if idx < herbs.size() and typeof(herbs[idx]) == TYPE_DICTIONARY:
				hid = str(herbs[idx].get("id", ""))
			area.set_meta("herb_id", hid)
			var colshape := CollisionShape2D.new()
			colshape.shape = shape
			area.add_child(colshape)
			var face := Polygon2D.new()
			var hw := DRAWER_CELL.x * 0.5 - 3.0
			var hh := DRAWER_CELL.y * 0.5 - 3.0
			face.polygon = PackedVector2Array([Vector2(-hw, -hh), Vector2(hw, -hh), Vector2(hw, hh), Vector2(-hw, hh)])
			face.color = Color(0.22, 0.18, 0.14, 0.55)
			area.add_child(face)
			if hid != "":
				var lb := Label.new()
				lb.position = Vector2(-30, -10)
				lb.size = Vector2(60, 18)
				lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				lb.add_theme_color_override("font_color", Color(0.93, 0.9, 0.82, 0.95))
				UiKit.apply_font(lb, 10)
				lb.text = CaseDB.herb_name(hid)
				lb.mouse_filter = Control.MOUSE_FILTER_IGNORE
				area.add_child(lb)
			_drawers.add_child(area)
			_hook_area(area)


func _spawn_bed_points() -> void:
	var bed := get_node_or_null("World/BedRect") as Node2D
	if bed == null:
		return
	var shape := CircleShape2D.new()
	shape.radius = 11.0
	for pid in CaseDB.pack.get("acupoints", []):
		if typeof(pid) != TYPE_DICTIONARY:
			continue
		var id := str(pid.get("id", ""))
		var uv: Vector2 = ACU_NORM.get(id, Vector2(0.5, 0.5))
		var area := Area2D.new()
		area.name = "Pt_%s" % id
		area.position = Vector2(uv.x * BED_RECT.size.x, uv.y * BED_RECT.size.y)
		area.input_pickable = true
		area.collision_layer = 2
		area.collision_mask = 0
		area.set_meta("hotspot", "acupoint")
		area.set_meta("point_id", id)
		var col := CollisionShape2D.new()
		col.shape = shape
		area.add_child(col)
		var dot := Polygon2D.new()
		dot.color = Color(0.93, 0.9, 0.82, 0.9)
		dot.polygon = PackedVector2Array([
			Vector2(-6, 0), Vector2(0, -6), Vector2(6, 0), Vector2(0, 6),
		])
		area.add_child(dot)
		bed.add_child(area)
		_hook_area(area)


func _build_hud() -> void:
	var root := Control.new()
	root.name = "Play"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.add_child(root)
	var top := HBoxContainer.new()
	top.position = Vector2(24, 12)
	top.size = Vector2(1232, 40)
	top.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(top)
	_title = UiKit.ink_label(tr("GAME_TITLE"), 22)
	top.add_child(_title)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(sp)
	top.add_child(UiKit.locale_bar())
	var row := HBoxContainer.new()
	row.name = "Patients"
	row.position = Vector2(24, 56)
	row.size = Vector2(900, 72)
	row.add_theme_constant_override("separation", 10)
	row.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(row)
	for i in CaseDB.patients.size():
		var p: Dictionary = CaseDB.patients[i]
		var pid := str(p.get("id", ""))
		var card := Button.new()
		card.name = pid
		card.custom_minimum_size = Vector2(200, 64)
		card.set_meta("pid", pid)
		UiKit.style_button(card, false)
		card.pressed.connect(_on_pick.bind(pid))
		var inner := VBoxContainer.new()
		inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		inner.offset_left = 8
		inner.offset_right = -8
		inner.offset_top = 6
		inner.offset_bottom = -6
		card.add_child(inner)
		var nm := UiKit.ink_label(UiKit.loc_text(p.get("name", {}), pid), 16)
		nm.set_meta("name_label", true)
		inner.add_child(nm)
		var idn := UiKit.ink_label(UiKit.loc_text(p.get("identity", {}), ""), 12, UiKit.INK_MUTED)
		idn.set_meta("id_label", true)
		inner.add_child(idn)
		row.add_child(card)
	_hint = UiKit.ink_label(tr("CLINIC_HINT"), 14, UiKit.INK_MUTED)
	_hint.name = "ClinicHint"
	_hint.position = Vector2(24, 132)
	_hint.size = Vector2(900, 28)
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_hint)
	_foot = UiKit.ink_label(tr("BOOT_DISCLAIMER_FOOTER"), 13, UiKit.INK_MUTED)
	_foot.name = "ClinicFoot"
	_foot.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_foot.anchor_top = 1.0
	_foot.anchor_bottom = 1.0
	_foot.offset_top = -28
	_foot.offset_bottom = -8
	_foot.offset_left = 24
	_foot.offset_right = -24
	_foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_foot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_foot)


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
	for n in _ysort.get_children():
		var pid := str(n.get_meta("pid", ""))
		if pid == "":
			continue
		var p := CaseDB.patient_by_id(pid)
		var lb := n.get_node_or_null("Name") as Label
		if lb:
			lb.text = UiKit.loc_text(p.get("name", {}), pid)
		n.modulate = Color(0.55, 0.55, 0.55, 0.7) if GameFlow.is_seen(pid) else Color.WHITE
	var row := _hud.find_child("Patients", true, false)
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
				if GameFlow.is_seen(pid):
					n.text = "%s · %s" % [idn, tr("UI_SEEN")]
				else:
					n.text = idn
		(card as Button).disabled = GameFlow.is_seen(pid)

const MAGNET := 40.0
const DEADZONE := 200.0
const TABLE_CENTER := Vector2(1920, 870)
const BED_RECT := Rect2(320, 820, 420, 160)
const DRAWER_CELL := Vector2(72, 56)
const POINT_POS := {
	"fengchi": Vector2(0.50, 0.10), "dazhui": Vector2(0.50, 0.18), "qimen": Vector2(0.28, 0.32),
	"neiguan": Vector2(0.16, 0.38), "lieque": Vector2(0.14, 0.42), "hegu": Vector2(0.08, 0.46),
	"quchi": Vector2(0.20, 0.34), "shenshu": Vector2(0.50, 0.44), "mingmen": Vector2(0.50, 0.50),
	"zusanli": Vector2(0.38, 0.72), "yanglingquan": Vector2(0.62, 0.70), "sanyinjiao": Vector2(0.38, 0.82),
	"taixi": Vector2(0.36, 0.90), "zhaohai": Vector2(0.64, 0.90), "taichong": Vector2(0.38, 0.97),
	"yongquan": Vector2(0.62, 0.97),
}

var _drag_id: String = ""
var _drag_vis: Node2D
var _ask_panel: Panel
var _ask_log: Label
var _ask_input: LineEdit
var _settle: Panel
var _settle_rank: Label
var _settle_flavor: Label
var _point_areas: Dictionary = {}
var _tray_label: Label
var _confirm: Button

func _process(_dt: float) -> void:
	_follow_hero()
	_tick_drag()

func _follow_hero() -> void:
	var cam := get_node_or_null("CAM_HERO") as Camera2D
	var ap := get_node_or_null("L5_characters/Apprentice") as Node2D
	if cam == null or ap == null or not cam.enabled:
		return
	if ap.position.distance_to(cam.position) <= DEADZONE:
		return
	var vis := get_viewport_rect().size / cam.zoom
	var half := vis * 0.5
	var target := ap.position
	target.x = clampf(target.x, half.x, 2560.0 - half.x)
	target.y = clampf(target.y, half.y, 1440.0 - half.y)
	cam.position = cam.position.lerp(target, 0.08)

func _build_drawers() -> void:
	var host := get_node_or_null("L3_furniture/Cabinet/Drawers")
	if host == null:
		return
	for c in host.get_children():
		c.queue_free()
	var herbs: Array = []
	for hid in GameFlow.herbs_by_id.keys():
		herbs.append(str(hid))
	var origin := Vector2(-312, -560)
	for row in 6:
		for col in 8:
			var idx: int = row * 8 + col
			var cell := Node2D.new()
			cell.position = origin + Vector2((col + 0.5) * DRAWER_CELL.x, (row + 0.5) * DRAWER_CELL.y)
			var fill := Polygon2D.new()
			fill.color = Color(0.18, 0.16, 0.15, 0.85).lightened(0.06 if (col + row) % 2 == 0 else 0.0)
			var hw := DRAWER_CELL.x * 0.5 - 2.0
			var hh := DRAWER_CELL.y * 0.5 - 2.0
			fill.polygon = PackedVector2Array([-hw, -hh, hw, -hh, hw, hh, -hw, hh])
			cell.add_child(fill)
			var hid := str(herbs[idx]) if idx < herbs.size() else ""
			if hid != "":
				var herb: Dictionary = GameFlow.herbs_by_id[hid]
				var lb := Label.new()
				lb.text = GameFlow.loc_text(herb)
				lb.position = Vector2(-hw + 4, -8)
				lb.size = Vector2(DRAWER_CELL.x - 8, 16)
				lb.add_theme_font_size_override("font_size", 10)
				lb.add_theme_color_override("font_color", Color(0.96, 0.94, 0.89, 1))
				lb.mouse_filter = Control.MOUSE_FILTER_IGNORE
				lb.clip_text = true
				cell.add_child(lb)
				var dot := Polygon2D.new()
				var nat := str(herb.get("nature", "neutral"))
				if nat in ["hot", "warm", "slightly_warm"]:
					dot.color = Color(0.706, 0.29, 0.235, 1)
				elif nat in ["cold", "cool", "slightly_cold"]:
					dot.color = Color(0.478, 0.604, 0.659, 1)
				else:
					dot.color = Color(0.6, 0.57, 0.52, 1)
				dot.polygon = PackedVector2Array([-4, -4, 4, -4, 4, 4, -4, 4])
				dot.position = Vector2(-hw + 8, 8)
				cell.add_child(dot)
			var area := Area2D.new()
			area.input_pickable = true
			var cs := CollisionShape2D.new()
			var rs := RectangleShape2D.new()
			rs.size = DRAWER_CELL - Vector2(4, 4)
			cs.shape = rs
			area.add_child(cs)
			area.set_meta("herb_id", hid)
			area.input_event.connect(_on_drawer.bind(hid, cell))
			cell.add_child(area)
			host.add_child(cell)

func _on_drawer(_vp: Node, event: InputEvent, _shape: int, hid: String, cell: Node2D) -> void:
	if hid == "":
		return
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if GameFlow.fsm_state != "formula_crafting" and GameFlow.current_patient_id != "":
		if GameFlow.has_method("enter_formula"):
			GameFlow.enter_formula()
		_use_cam("CAM_FORMULA")
	_drag_id = hid
	if _drag_vis:
		_drag_vis.queue_free()
	_drag_vis = Node2D.new()
	var vis := Polygon2D.new()
	vis.color = Color(0.4, 0.32, 0.24, 0.9)
	vis.polygon = PackedVector2Array([-28, -14, 28, -14, 28, 14, -28, 14])
	_drag_vis.add_child(vis)
	add_child(_drag_vis)
	_drag_vis.global_position = cell.global_position
	cell.position.y += 28.0
	get_tree().create_timer(0.3).timeout.connect(func():
		if is_instance_valid(cell):
			cell.position.y -= 28.0
	)

func _tick_drag() -> void:
	if _drag_id == "" or _drag_vis == null:
		return
	var mp := get_global_mouse_position()
	if mp.distance_to(TABLE_CENTER) < MAGNET:
		_drag_vis.global_position = _drag_vis.global_position.lerp(TABLE_CENTER, 0.4)
	else:
		_drag_vis.global_position = mp
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		return
	var hid := _drag_id
	_drag_id = ""
	_drag_vis.queue_free()
	_drag_vis = null
	if mp.distance_to(TABLE_CENTER) <= MAGNET or mp.distance_to(TABLE_CENTER) < 110.0:
		if GameFlow.fsm_state != "formula_crafting" and GameFlow.has_method("enter_formula"):
			GameFlow.enter_formula()
		if GameFlow.has_method("add_herb_to_tray"):
			GameFlow.add_herb_to_tray(hid)
		_refresh_tray()

func _build_acupoints() -> void:
	var bed := get_node_or_null("L3_furniture/NeedleBed")
	if bed == null:
		return
	var old := bed.get_node_or_null("Acupoints")
	if old:
		old.queue_free()
	var root := Node2D.new()
	root.name = "Acupoints"
	bed.add_child(root)
	_point_areas.clear()
	for pid in GameFlow.points_by_id.keys():
		var u: Vector2 = POINT_POS.get(str(pid), Vector2(0.5, 0.5))
		var world := Vector2(BED_RECT.position.x + u.x * BED_RECT.size.x, BED_RECT.position.y + u.y * BED_RECT.size.y)
		world.x = clampf(world.x, BED_RECT.position.x + 12.0, BED_RECT.end.x - 12.0)
		world.y = clampf(world.y, BED_RECT.position.y + 12.0, BED_RECT.end.y - 12.0)
		var pt := Area2D.new()
		pt.position = world - bed.position
		pt.input_pickable = true
		var cs := CollisionShape2D.new()
		var circ := CircleShape2D.new()
		circ.radius = 14.0
		cs.shape = circ
		pt.add_child(cs)
		var vis := Polygon2D.new()
		vis.name = "Dot"
		vis.color = Color(0.96, 0.94, 0.89, 1)
		vis.polygon = PackedVector2Array([-8, -8, 8, -8, 8, 8, -8, 8])
		pt.add_child(vis)
		pt.input_event.connect(_on_point.bind(str(pid)))
		root.add_child(pt)
		_point_areas[str(pid)] = pt

func _on_point(_vp: Node, event: InputEvent, _shape: int, pid: String) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var pt: Area2D = _point_areas.get(pid)
	if pt and not BED_RECT.has_point(pt.global_position):
		return
	if GameFlow.fsm_state != "needling" and GameFlow.has_method("enter_needling"):
		GameFlow.enter_needling()
		_use_cam("CAM_NEEDLE")
	if GameFlow.has_method("toggle_point"):
		GameFlow.toggle_point(pid)
	var vis := pt.get_node_or_null("Dot") as Polygon2D if pt else null
	if vis:
		vis.color = Color(0.55, 0.18, 0.16, 1) if pid in GameFlow.selected_points else Color(0.96, 0.94, 0.89, 1)

func _build_play_panels() -> void:
	var hud := _host()
	_ask_panel = Panel.new()
	_ask_panel.visible = false
	_ask_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_ask_panel.anchor_left = 1.0
	_ask_panel.anchor_right = 1.0
	_ask_panel.offset_left = -380
	_ask_panel.offset_right = -16
	_ask_panel.offset_top = 72
	_ask_panel.offset_bottom = 272
	hud.add_child(_ask_panel)
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.93, 0.89, 0.8, 0.96)
	_ask_panel.add_child(bg)
	_ask_log = Label.new()
	_ask_log.position = Vector2(12, 12)
	_ask_log.size = Vector2(336, 120)
	_ask_log.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ask_panel.add_child(_ask_log)
	_ask_input = LineEdit.new()
	_ask_input.position = Vector2(12, 140)
	_ask_input.size = Vector2(240, 32)
	_ask_input.placeholder_text = tr("ASK_PROMPT")
	_ask_input.text_submitted.connect(func(_x): _send_ask())
	_ask_panel.add_child(_ask_input)
	var send := Button.new()
	send.text = tr("ASK_SEND")
	send.position = Vector2(256, 140)
	send.pressed.connect(_send_ask)
	_ask_panel.add_child(send)
	_settle = Panel.new()
	_settle.visible = false
	_settle.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_settle.offset_left = -260
	_settle.offset_right = 260
	_settle.offset_top = 70
	_settle.offset_bottom = 320
	hud.add_child(_settle)
	var sbg := ColorRect.new()
	sbg.set_anchors_preset(Control.PRESET_FULL_RECT)
	sbg.color = Color(0.93, 0.89, 0.8, 0.97)
	_settle.add_child(sbg)
	_settle_rank = Label.new()
	_settle_rank.position = Vector2(20, 24)
	_settle_rank.size = Vector2(480, 40)
	_settle_rank.add_theme_font_size_override("font_size", 28)
	_settle.add_child(_settle_rank)
	_settle_flavor = Label.new()
	_settle_flavor.position = Vector2(20, 72)
	_settle_flavor.size = Vector2(480, 90)
	_settle_flavor.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_settle.add_child(_settle_flavor)
	var nxt := Button.new()
	nxt.text = tr("ACTION_NEXT_PATIENT")
	nxt.position = Vector2(160, 200)
	nxt.custom_minimum_size = Vector2(200, 36)
	nxt.pressed.connect(_on_next)
	_settle.add_child(nxt)
	_tray_label = Label.new()
	_tray_label.position = Vector2(24, 620)
	_tray_label.size = Vector2(500, 24)
	_tray_label.add_theme_font_size_override("font_size", 13)
	hud.add_child(_tray_label)
	_confirm = Button.new()
	_confirm.text = tr("ACTION_SUBMIT")
	_confirm.position = Vector2(24, 652)
	_confirm.custom_minimum_size = Vector2(120, 36)
	_confirm.pressed.connect(_on_submit)
	hud.add_child(_confirm)

func _show_ask() -> void:
	if _ask_panel:
		_ask_panel.visible = true
		_ask_log.text = tr("ASK_PLACEHOLDER")

func _send_ask() -> void:
	if GameFlow.current_patient_id == "":
		return
	if not GameFlow.exam_done("wen_ask"):
		GameFlow.do_exam("wen_ask")
	var q := _ask_input.text.strip_edges() if _ask_input else "……"
	if q == "":
		q = "……"
	if _ask_input:
		_ask_input.text = ""
	if _ask_log:
		_ask_log.text = GameFlow.wrap_inquiry_fallback(GameFlow.consume_inquiry_anchor())

func _on_submit() -> void:
	if GameFlow.fsm_state == "formula_crafting":
		GameFlow.confirm_formula()
	elif GameFlow.fsm_state == "needling":
		GameFlow.confirm_needling()

func _on_settled(result: Dictionary) -> void:
	_use_cam("CAM_RESULT")
	if _ask_panel:
		_ask_panel.visible = false
	if _settle:
		_settle.visible = true
	var rank: Variant = result.get("rank", {})
	if typeof(rank) == TYPE_DICTIONARY:
		_settle_rank.text = GameFlow.loc_text(rank)
	else:
		_settle_rank.text = tr(str(result.get("rank_key", "SCORE_NONE")))
	var flav: Variant = result.get("flavor", "")
	_settle_flavor.text = GameFlow.loc_text(flav) if typeof(flav) == TYPE_DICTIONARY else str(flav)

func _on_next() -> void:
	if _settle:
		_settle.visible = false
	GameFlow.next_patient()
	_use_cam("CAM_HERO")
	if has_node("CAM_HERO"):
		$CAM_HERO.position = Vector2(1280, 780)
	_refresh()

func _refresh_tray() -> void:
	if _tray_label == null:
		return
	_tray_label.visible = GameFlow.fsm_state == "formula_crafting"
	_tray_label.text = tr("TRAY_COUNT").format({"n": GameFlow.tray_herbs.size()})
	if _confirm:
		if GameFlow.fsm_state == "formula_crafting":
			_confirm.disabled = not GameFlow.can_confirm_formula()
		elif GameFlow.fsm_state == "needling":
			_confirm.disabled = not GameFlow.can_confirm_needling()
		else:
			_confirm.disabled = true
