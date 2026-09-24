extends Node2D
## Lightweight waiting portrait proof — no clinic.gd (avoids headless hang).

const LAYER_SCALE := Vector2(1.666667, 1.40625)
const HOMES := [Vector2(405, 290), Vector2(545, 290), Vector2(300, 340), Vector2(685, 290)]

func _ready() -> void:
	TranslationServer.set_locale("zh")
	GameFlow.settings_open = false
	GameFlow.fsm_state = "clinic_idle"
	if GameFlow.has_method("refresh_waiting_seats"):
		GameFlow.refresh_waiting_seats(true)
	_build_world()
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.35).timeout
	# Shot A: waiting-focused (stools clearly readable)
	var cam := $CAM as Camera2D
	cam.position = Vector2(500, 250)
	cam.zoom = Vector2(1.0, 1.0)
	cam.make_current()
	await get_tree().process_frame
	await get_tree().create_timer(0.2).timeout
	var img: Image = get_viewport().get_texture().get_image()
	var p1 := "res://ui/waiting/v137_1_waiting_portraits.png"
	print("waiting_saved=", img.save_png(p1) == OK, " path=", p1, " wh=", img.get_width(), "x", img.get_height())
	# Shot B: CAM_HERO-like wide (overlay framing family)
	cam.position = Vector2(720, 420)
	cam.zoom = Vector2(0.75, 0.75)
	await get_tree().process_frame
	await get_tree().create_timer(0.2).timeout
	var img2: Image = get_viewport().get_texture().get_image()
	var p2 := "res://ui/waiting/v137_1_waiting_cam_hero.png"
	print("waiting_wide_saved=", img2.save_png(p2) == OK, " path=", p2)
	print("portrait_visible_count=", _count_vis())
	get_tree().quit(0 if _count_vis() >= 1 else 1)


func _build_world() -> void:
	for pair in [
		["L0", "res://ui/layers/L0-paper.png"],
		["L1", "res://ui/layers/L1-arch.png"],
		["L2", "res://ui/layers/L2-yard.png"],
		["L3", "res://ui/layers/L3-furniture.png"],
		["L4", "res://ui/layers/L4-props.png"],
	]:
		var n := Node2D.new()
		n.name = pair[0]
		var art := Sprite2D.new()
		art.centered = false
		art.position = Vector2.ZERO
		art.scale = LAYER_SCALE
		if ResourceLoader.exists(pair[1]):
			art.texture = load(pair[1]) as Texture2D
		n.add_child(art)
		add_child(n)
	var chars := Node2D.new()
	chars.name = "L5_characters"
	chars.y_sort_enabled = true
	chars.z_index = 5
	add_child(chars)
	# Hide composite: do not load L5-patients sheet
	var seats: Array = GameFlow.waiting_patients() if GameFlow.has_method("waiting_patients") else []
	if seats.is_empty():
		seats = [
			{"id": "char_porter"}, {"id": "char_clerk"},
			{"id": "char_copyist"}, {"id": "char_xiuniang"},
		]
	for i in mini(seats.size(), 4):
		var pid := str(seats[i].get("id", ""))
		var node := Node2D.new()
		node.name = "Patient%d" % i
		node.position = HOMES[i]
		node.y_sort_enabled = true
		node.set_meta("pid", pid)
		var spr := Sprite2D.new()
		spr.name = "Portrait"
		spr.z_index = 5
		var tex: Texture2D = CharacterArt.load_portrait(pid)
		if tex:
			_fit(spr, tex, 260.0)
			spr.visible = true
		node.add_child(spr)
		chars.add_child(node)
		print("seat", i, " pid=", pid, " pos=", node.position, " has_tex=", tex != null)
	# Jiang Wan
	var ap := Node2D.new()
	ap.name = "Apprentice"
	ap.position = Vector2(1100, 720)
	ap.y_sort_enabled = true
	var ap_art := Sprite2D.new()
	ap_art.name = "Art"
	var at: Texture2D = CharacterArt.load_portrait("apprentice_jiang")
	if at:
		_fit(ap_art, at, 260.0)
	ap.add_child(ap_art)
	chars.add_child(ap)
	# Soft HUD cards (top) — text OK, not substitute
	var hud := CanvasLayer.new()
	hud.layer = 10
	add_child(hud)
	var row := HBoxContainer.new()
	row.position = Vector2(24, 12)
	row.add_theme_constant_override("separation", 8)
	hud.add_child(row)
	for i in mini(seats.size(), 4):
		var p: Dictionary = seats[i]
		var card := Panel.new()
		card.custom_minimum_size = Vector2(170, 56)
		card.add_theme_stylebox_override("panel", UiKit.paper_style())
		var inner := VBoxContainer.new()
		inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		inner.offset_left = 8
		inner.offset_right = -8
		inner.offset_top = 4
		inner.offset_bottom = -4
		card.add_child(inner)
		inner.add_child(UiKit.ink_label(UiKit.loc_text(p.get("name", {}), str(p.get("id", ""))), 15))
		inner.add_child(UiKit.ink_label(UiKit.loc_text(p.get("identity", {}), ""), 12, UiKit.INK_MUTED))
		row.add_child(card)
	var title := UiKit.ink_label(UiKit.store_title_text(), 18, UiKit.INK, false)
	title.position = Vector2(24, 76)
	hud.add_child(title)
	var cam := Camera2D.new()
	cam.name = "CAM"
	cam.position = Vector2(1280, 780)
	cam.zoom = Vector2(0.666667, 0.666667)
	add_child(cam)


func _fit(spr: Sprite2D, tex: Texture2D, target_h: float) -> void:
	spr.texture = tex
	spr.centered = false
	spr.offset = Vector2.ZERO
	var th := float(tex.get_height())
	var tw := float(tex.get_width())
	var s := target_h / th
	spr.scale = Vector2(s, s)
	# position is in parent space (not pre-multiplied by scale)
	spr.position = Vector2(-tw * s * 0.5, -th * s)


func _count_vis() -> int:
	var n := 0
	var chars := get_node_or_null("L5_characters")
	if chars == null:
		return 0
	for i in 4:
		var pn := chars.get_node_or_null("Patient%d" % i) as Node2D
		if pn == null:
			continue
		var spr := pn.get_node_or_null("Portrait") as Sprite2D
		if spr and spr.visible and spr.texture != null:
			n += 1
	return n
