extends Node
## V137.1 proof shots: boot frame + waiting portraits (CAM_HERO framing).

func _ready() -> void:
	TranslationServer.set_locale("zh")
	GameFlow.settings_open = false
	GameFlow.fsm_state = "clinic_idle"
	if GameFlow.has_method("refresh_waiting_seats"):
		GameFlow.refresh_waiting_seats(true)
	# --- Boot ---
	var boot_ps: PackedScene = load("res://scenes/main.tscn") as PackedScene
	var boot: Node = boot_ps.instantiate()
	add_child(boot)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.35).timeout
	var img_boot: Image = get_viewport().get_texture().get_image()
	var p_boot := "res://ui/boot/v137_1_boot.png"
	print("boot_saved=", img_boot.save_png(p_boot) == OK, " path=", p_boot, " wh=", img_boot.get_width(), "x", img_boot.get_height())
	boot.queue_free()
	await get_tree().process_frame
	# --- Clinic waiting (same CAM_HERO framing) ---
	var clinic_ps: PackedScene = load("res://scenes/clinic.tscn") as PackedScene
	var clinic: Node = clinic_ps.instantiate()
	add_child(clinic)
	await get_tree().process_frame
	await get_tree().process_frame
	if clinic.has_method("_label_patients"):
		clinic.call("_label_patients")
	if clinic.has_method("_switch_camera"):
		clinic.call("_switch_camera", "CAM_HERO")
	# Nudge camera toward waiting stools for clearer seat read (still same framing family).
	var cam := clinic.get_node_or_null("CAM_HERO") as Camera2D
	if cam:
		cam.position = Vector2(560, 420)
		cam.zoom = Vector2(0.85, 0.85)
		cam.make_current()
	await get_tree().process_frame
	await get_tree().create_timer(0.4).timeout
	var img_w: Image = get_viewport().get_texture().get_image()
	var p_wait := "res://ui/waiting/v137_1_waiting_portraits.png"
	print("waiting_saved=", img_w.save_png(p_wait) == OK, " path=", p_wait, " wh=", img_w.get_width(), "x", img_w.get_height())
	# Also dump a second shot at default CAM_HERO (overlay-aligned wide).
	if cam:
		cam.position = Vector2(1280, 780)
		cam.zoom = Vector2(0.666667, 0.666667)
	await get_tree().process_frame
	await get_tree().create_timer(0.25).timeout
	var img_w2: Image = get_viewport().get_texture().get_image()
	var p_wide := "res://ui/waiting/v137_1_waiting_cam_hero.png"
	print("waiting_wide_saved=", img_w2.save_png(p_wide) == OK, " path=", p_wide)
	# Count visible portraits for log
	var vis := 0
	var chars := clinic.get_node_or_null("L5_characters")
	if chars:
		for i in 4:
			var pn := chars.get_node_or_null("Patient%d" % i) as Node2D
			if pn == null:
				continue
			var spr := pn.get_node_or_null("Portrait") as Sprite2D
			if spr and spr.visible and spr.texture != null:
				vis += 1
				print("seat", i, " pid=", pn.get_meta("pid", ""), " pos=", pn.position, " tex=", spr.texture.resource_path if spr.texture else "")
	print("portrait_visible_count=", vis)
	get_tree().quit(0 if vis >= 1 else 1)
