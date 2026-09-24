extends Node

func _ready() -> void:
	var code: int = await GameFlow.run_slice_smoke()
	get_tree().quit(code)
