extends Node
## V139 proof (visual fix): boot + idle aisle composition + clear open-consult pair.

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
	var img_boot: Image = get_viewport().get_texture().get_image()
	print("boot_saved=", img_boot.save_png("res://ui/boot/v139_boot.png") == OK)
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
	if clinic.has_method("set_process"):
		clinic.set_process(false)
	await get_tree().process_frame
	await get_tree().create_timer(0.5).timeout
	if clinic.has_method("_apply_portraits"):
		clinic.call("_apply_portraits")
	_pin_hero(cam, clinic)
	await get_tree().process_frame
	await get_tree().create_timer(0.25).timeout
	var img_idle: Image = get_viewport().get_texture().get_image()
	print("idle_saved=", img_idle.save_png("res://ui/waiting/v139_idle.png") == OK)

	var chars := clinic.get_node_or_null("L5_characters")
	var vis := 0
	var work := Rect2(880, 520, 440, 300)
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
					pn3.position = Vector2(1280, 1240)
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
				pn4.position = Vector2(1280, 1240)
				pn4.visible = true
	if clinic.has_method("_rebuild_dock"):
		clinic.call("_rebuild_dock")
	# Consult accept: CAM_ASK midshot so patient@590 + JW@670 behind desk read as a pair
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
	var img_consult: Image = get_viewport().get_texture().get_image()
	print("consult_saved=", img_consult.save_png("res://ui/consult/v139_consult.png") == OK)
	if chars:
		var ap2 := chars.get_node_or_null("Apprentice") as Node2D
		print("consult_apprentice=", ap2.position if ap2 else Vector2.ZERO)
		for i2 in 4:
			var pn2 := chars.get_node_or_null("Patient%d" % i2) as Node2D
			if pn2 and pn2.visible:
				print("consult_seat", i2, " pos=", pn2.position, " pid=", pn2.get_meta("pid", ""))
	print("cam_pos=", cam.position if cam else Vector2.ZERO, " zoom=", cam.zoom if cam else Vector2.ZERO)
	get_tree().quit(0 if vis >= 3 and clear_n >= 3 else 1)


func _pin_hero(cam: Camera2D, clinic: Node) -> void:
	if cam == null:
		return
	cam.position = Vector2(1280, 820)
	cam.zoom = Vector2(0.48, 0.48)  ## show right-aisle floor + chair + cabinet
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
