extends Node
func _ready() -> void:
	TranslationServer.set_locale("zh")
	var boot = load("res://scenes/main.tscn").instantiate()
	add_child(boot)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.3).timeout
	var img = get_viewport().get_texture().get_image()
	print("boot_ok=", img.save_png("res://ui/boot/v137_1_boot.png")==OK, " ", img.get_width(),"x",img.get_height())
	get_tree().quit(0)
