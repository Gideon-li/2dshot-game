extends Node
## V139.1 proof: boot + idle right-aisle feet + clear open-consult pair (隔桌对坐).

func _grab_png(path: String) -> bool:
	RenderingServer.force_draw()
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var tex := get_viewport().get_texture()
	if tex == null:
		printerr("grab_fail tex null path=", path)
		return false
	var img: Image = tex.get_image()
	if img == null:
		printerr("grab_fail img null path=", path)
		return false
	var ok := img.save_png(path) == OK
	print("saved=", ok, " path=", path, " wh=", img.get_width(), "x", img.get_height())
	return ok


func _ready() -> void:
	TranslationServer.set_locale("zh")
	GameFlow.settings_open = false
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://ui/consult"))
	# --- Boot ---
	var boot_ps: PackedScene = load("res://scenes/main.tscn") as PackedScene
	var boot: Node = boot_ps.instantiate()
	add_child(boot)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.4).timeout
	var boot_ok := await _grab_png("res://ui/boot/v139_boot.png")
	print("boot_saved=", boot_ok)
	boot.queue_free()
	await get_tree().process_frame

	# --- Clinic idle ---
	GameFlow.fsm_state = "clinic_idle"
	GameFlow.current_patient_id = ""
	if GameFlow.has_method("refresh_waiting_seats"):
		GameFlow.refresh_waiting_seats(true)
	var clinic_ps: PackedScene = load("res://scenes/clinic.tscn") as PackedScene
	var clinic: Node = clinic_ps.instantiate()
	add_child(clinic)
	await get_tree().process_frame
	await get_tree().process_frame
	for m in ["_sync_v139_anchors", "_apply_clinic_props_v139", "_label_patients", "_pin_cam_hero_home", "_apply_portraits"]:
		if clinic.has_method(m):
			clinic.call(m)
	var cam := clinic.get_node_or_null("CAM_HERO") as Camera2D
	_pin_hero(cam, clinic)
	for dn in ["L3_desk_front", "L3_desk_front_apron"]:
		var desk_n := clinic.get_node_or_null("L5_characters/%s" % dn) as Sprite2D
		if desk_n:
			print(dn, "_pos=", desk_n.position, " offset=", desk_n.offset, " tex=", desk_n.texture != null, " parent=", desk_n.get_parent().name)
		else:
			print(dn, "_MISSING")
	if clinic.has_method("set_process"):
		clinic.set_process(false)
	await get_tree().process_frame
	await get_tree().create_timer(0.5).timeout
	if clinic.has_method("_apply_portraits"):
		clinic.call("_apply_portraits")
	_pin_hero(cam, clinic)
	await get_tree().process_frame
	await get_tree().create_timer(0.25).timeout
	var idle_ok := await _grab_png("res://ui/waiting/v139_idle.png")
	print("idle_saved=", idle_ok)

	var chars := clinic.get_node_or_null("L5_characters")
	var vis := 0
	var work := Rect2(900, 960, 600, 240)
	var clear_n := 0
	if chars:
		for i in 4:
			var pn := chars.get_node_or_null("Patient%d" % i) as Node2D
			if pn == null:
				continue
			var spr := pn.get_node_or_null("Portrait") as Sprite2D
			if spr and spr.visible and spr.texture != null:
				vis += 1
				if not work.has_point(pn.position):
					clear_n += 1
				print("seat", i, " pos=", pn.position, " pid=", pn.get_meta("pid", ""))
		var ap := chars.get_node_or_null("Apprentice") as Node2D
		if ap:
			print("apprentice_pos=", ap.position)
	print("portrait_visible_count=", vis, " clear_of_work=", clear_n)
	var l4 := clinic.get_node_or_null("L4_props_interact")
	if l4:
		for c in l4.get_children():
			print("prop=", c.name, " vis=", c.visible, " pos=", c.get("position") if c is Node2D else "?")

	# --- Open consult: seat ONE patient, hide other waiting for clear pair ---
	var seats: Array = GameFlow.waiting_patients() if GameFlow.has_method("waiting_patients") else []
	var pick_pid := str(seats[0].get("id", "")) if seats.size() > 0 else ""
	if pick_pid != "":
		GameFlow.current_patient_id = pick_pid
		GameFlow.fsm_state = "asking"
		if chars:
			for i3 in 4:
				var pn3 := chars.get_node_or_null("Patient%d" % i3) as Node2D
				if pn3 == null:
					continue
				if str(pn3.get_meta("pid", "")) == pick_pid:
					pn3.position = Vector2(1280, 1280)
					pn3.visible = true
				else:
					# Keep away / hide so pair reads clearly in accept shot
					pn3.visible = false
	await get_tree().process_frame
	await get_tree().create_timer(0.3).timeout
	if clinic.has_method("_apply_portraits"):
		clinic.call("_apply_portraits")
	# Re-hide others after portraits (apply may re-show)
	if chars and pick_pid != "":
		for i4 in 4:
			var pn4 := chars.get_node_or_null("Patient%d" % i4) as Node2D
			if pn4 and str(pn4.get_meta("pid", "")) != pick_pid:
				pn4.visible = false
			elif pn4 and str(pn4.get_meta("pid", "")) == pick_pid:
				pn4.position = Vector2(1280, 1280)
				pn4.visible = true
	if clinic.has_method("_rebuild_dock"):
		clinic.call("_rebuild_dock")
	# Clear bulky HUD for accept shot (pair readability); keep world props/characters.
	var ui := clinic.get_node_or_null("UI")
	if ui:
		ui.visible = false
	# Consult accept: optional CAM_ASK push-in — pair at (1220,1080)/(1280,1280)
	var ask := clinic.get_node_or_null("CAM_ASK") as Camera2D
	for n in ["CAM_HERO", "CAM_PULSE", "CAM_FORMULA", "CAM_NEEDLE", "CAM_RESULT", "CAM_LOFT"]:
		var o := clinic.get_node_or_null(n) as Camera2D
		if o:
			o.enabled = false
	if ask:
		ask.position = Vector2(1260, 1140)
		ask.zoom = Vector2(0.62, 0.62)
		ask.enabled = true
		ask.make_current()
		cam = ask
	elif cam:
		cam.position = Vector2(1260, 1140)
		cam.zoom = Vector2(0.62, 0.62)
		cam.enabled = true
		cam.make_current()
	if clinic.get("_cam_name") != null:
		clinic.set("_cam_name", "CAM_ASK")
	await get_tree().process_frame
	await get_tree().create_timer(0.4).timeout
	var consult_ok := await _grab_png("res://ui/consult/v139_consult.png")
	print("consult_saved=", consult_ok)
	if chars:
		var ap2 := chars.get_node_or_null("Apprentice") as Node2D
		print("consult_apprentice=", ap2.position if ap2 else Vector2.ZERO)
		for i2 in 4:
			var pn2 := chars.get_node_or_null("Patient%d" % i2) as Node2D
			if pn2 and pn2.visible:
				print("consult_seat", i2, " pos=", pn2.position, " pid=", pn2.get_meta("pid", ""))
	print("cam_pos=", cam.position if cam else Vector2.ZERO, " zoom=", cam.zoom if cam else Vector2.ZERO)
	get_tree().quit(0 if vis >= 3 and clear_n >= 3 and boot_ok and idle_ok and consult_ok else 1)


func _pin_hero(cam: Camera2D, clinic: Node) -> void:
	if cam == null:
		return
	# V139.1 idle default: CAM_HERO (1280,780) zoom≈0.67
	cam.position = Vector2(1280, 780)
	cam.zoom = Vector2(0.666667, 0.666667)
	cam.position_smoothing_enabled = false
	cam.drag_horizontal_enabled = false
	cam.drag_vertical_enabled = false
	cam.enabled = true
	cam.make_current()
	if clinic.get("_cam_name") != null:
		clinic.set("_cam_name", "CAM_HERO")
	_disable_other_cams(clinic)


func _disable_other_cams(clinic: Node) -> void:
	for n in ["CAM_ASK", "CAM_PULSE", "CAM_FORMULA", "CAM_NEEDLE", "CAM_RESULT", "CAM_LOFT"]:
		var other := clinic.get_node_or_null(n) as Camera2D
		if other:
			other.enabled = false
