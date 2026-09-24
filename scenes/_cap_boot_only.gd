extends Node
## V138 boot proof shot → ui/boot/v138_boot.png
## Run (needs display / OpenGL, not dummy headless):
##   DISPLAY=:7 godot43 --path . --window-size 1280,720 --rendering-driver opengl3 --audio-driver Dummy res://scenes/_cap_boot_only.tscn
func _ready() -> void:
	print("cap_boot: start")
	TranslationServer.set_locale("zh")
	GameFlow.settings_open = false
	var boot = load("res://scenes/main.tscn").instantiate()
	add_child(boot)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.4).timeout
	var img = get_viewport().get_texture().get_image()
	var path := "res://ui/boot/v138_boot.png"
	var ok := img != null and img.save_png(path) == OK
	print("boot_ok=", ok, " ", (img.get_width() if img else 0), "x", (img.get_height() if img else 0), " path=", path)
	get_tree().quit(0 if ok else 1)
