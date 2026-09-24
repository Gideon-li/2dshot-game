extends Node
## V139 proof: boot rounded + idle consult composition + open-consult pair.

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
	await get_tree().create_timer(0.45).timeout
	var img_boot: Image = get_viewport().get_texture().get_image()
	var p_boot := "res://ui/boot/v139_boot.png"
	print("boot_saved=", img_boot.save_png(p_boot) == OK, " path=", p_boot, " wh=", img_boot.get_width(), "x", img_boot.get_height())
	boot.queue_free()
	await get_tree().process_frame

	# --- Clinic idle ---
	GameFlow.fsm_state = "clinic_idle"
	if GameFlow.has_method("refresh_waiting_seats"):
		GameFlow.refresh_waiting_seats(true)
	var clinic_ps: PackedScene = load("res://scenes/clinic.tscn") as PackedScene
	var clinic: Node = clinic_ps.instantiate()
	add_child(clinic)
	await get_tree().process_frame
	await get_tree().process_frame
	if clinic.has_method("_sync_v139_anchors"):
		clinic.call("_sync_v139_anchors")
	if clinic.has_method("_apply_clinic_props_v139"):
		clinic.call("_apply_clinic_props_v139")
	if clinic.has_method("_label_patients"):
		clinic.call("_label_patients")
	if clinic.has_method("_pin_cam_hero_home"):
		clinic.call("_pin_cam_hero_home")
	var cam := clinic.get_node_or_null("CAM_HERO") as Camera2D
	if cam:
		cam.position = Vector2(1280, 780)
		cam.zoom = Vector2(0.52, 0.52)
		cam.position_smoothing_enabled = false
		cam.drag_horizontal_enabled = false
		cam.drag_vertical_enabled = false
		cam.make_current()
		cam.enabled = true
	if clinic.get("_cam_name") != null:
		clinic.set("_cam_name", "CAM_HERO")
	if clinic.has_method("set_process"):
		clinic.set_process(false)
	await get_tree().process_frame
	await get_tree().create_timer(0.55).timeout
	if clinic.has_method("_apply_portraits"):
		clinic.call("_apply_portraits")
	if cam:
		cam.position = Vector2(1280, 780)
		cam.zoom = Vector2(0.52, 0.52)
		cam.make_current()
	await get_tree().process_frame
	await get_tree().create_timer(0.25).timeout
	var img_idle: Image = get_viewport().get_texture().get_image()
	var p_idle := "res://ui/waiting/v139_idle.png"
	print("idle_saved=", img_idle.save_png(p_idle) == OK, " path=", p_idle)

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
				print("seat", i, " pid=", pn.get_meta("pid", ""), " pos=", pn.position)
		var ap := chars.get_node_or_null("Apprentice") as Node2D
		if ap:
			print("apprentice_pos=", ap.position)
	print("portrait_visible_count=", vis, " clear_of_work=", clear_n)
	var l4 := clinic.get_node_or_null("L4_props_interact")
	if l4:
		for c in l4.get_children():
			print("prop=", c.name, " vis=", c.visible, " pos=", c.get("position") if c is Node2D else "?")

	# --- Open consult pair (manual seat — avoid start_patient scene churn) ---
	var seats: Array = []
	if GameFlow.has_method("waiting_patients"):
		seats = GameFlow.waiting_patients()
	var pick_pid := ""
	if seats.size() > 0:
		pick_pid = str(seats[0].get("id", ""))
	if pick_pid != "":
		GameFlow.current_patient_id = pick_pid
		GameFlow.fsm_state = "asking"
		if chars:
			for i3 in 4:
				var pn3 := chars.get_node_or_null("Patient%d" % i3) as Node2D
				if pn3 and str(pn3.get_meta("pid", "")) == pick_pid:
					pn3.position = Vector2(1040, 590)
	await get_tree().process_frame
	await get_tree().create_timer(0.35).timeout
	if clinic.has_method("_apply_portraits"):
		clinic.call("_apply_portraits")
	if clinic.has_method("_rebuild_dock"):
		clinic.call("_rebuild_dock")
	for n in ["CAM_ASK", "CAM_PULSE", "CAM_FORMULA", "CAM_NEEDLE", "CAM_RESULT", "CAM_LOFT"]:
		var other := clinic.get_node_or_null(n) as Camera2D
		if other:
			other.enabled = false
	if cam:
		cam.position = Vector2(1280, 780)
		cam.zoom = Vector2(0.52, 0.52)
		cam.enabled = true
		cam.make_current()
	if clinic.get("_cam_name") != null:
		clinic.set("_cam_name", "CAM_HERO")
	await get_tree().process_frame
	await get_tree().create_timer(0.35).timeout
	var img_consult: Image = get_viewport().get_texture().get_image()
	var p_consult := "res://ui/consult/v139_consult.png"
	print("consult_saved=", img_consult.save_png(p_consult) == OK, " path=", p_consult)
	if chars:
		var ap2 := chars.get_node_or_null("Apprentice") as Node2D
		print("consult_apprentice=", ap2.position if ap2 else Vector2.ZERO)
		for i2 in 4:
			var pn2 := chars.get_node_or_null("Patient%d" % i2) as Node2D
			if pn2 and pn2.visible:
				print("consult_seat", i2, " pos=", pn2.position, " pid=", pn2.get_meta("pid", ""))
	print("cam_pos=", cam.position if cam else Vector2.ZERO, " zoom=", cam.zoom if cam else Vector2.ZERO)
	var ok := vis >= 3 and clear_n >= 3
	get_tree().quit(0 if ok else 1)
